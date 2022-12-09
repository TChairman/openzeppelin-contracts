// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC4626.sol";
import "../../../interfaces/IERC20.sol";
import "../../../utils/math/Math.sol";
/**
 * @dev Extension of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extenision proviedes basic balance sheet accounting functions that are required
 * for many real-world implementations of ERC4626 vaults, including:
 * - totalEquity()
 * - totalLiabilities() and
 * - totalNAV()
 * 
 * This implementation redefines the share price functions to be in terms of totalEquity() instead of totalAssets()
 *
 * CAUTION: see ERC4626.sol to learn about the donation attack and potential mitigations
 *
 */
abstract contract ERC4626Acounting is ERC4626 {
    using Math for uint256;
    
    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + totalNAV();
    }

     // total asset value of outside investments
    function totalNAV() public virtual view returns (uint256) {
        return 0;
    }

    // total liabilities, e.g. accrued fees, or loans to the vault
    function totalLiabilities() public view virtual returns (uint256) {
        return 0;
    }

    // total equity value of the shareholders
    function totalEquity() public view virtual returns (uint256) {
        uint256 assets = totalAssets();
        uint256 liabilities = totalLiabilities();
        return (liabilities > assets) ? 0 : assets - liabilities;
    }
    
    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction. Usees totalEquity() instead of totalAssets().
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual override returns (uint256) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, totalEquity(), rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction. Usees totalEquity() instead of totalAssets().
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual override returns (uint256) {
        uint256 supply = totalSupply();
        return
            (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalEquity(), supply, rounding);
    }

}

// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPolicyManager {
    // setters
    func setIsPublic(_fund: felt, _isPublic: felt) {
    }
    func setAllowedDepositor(_fund: felt, _depositor: felt) {
    }
    func setAllowedAssetToReedem(_fund: felt, _asset: felt) {
    }

    // getters
    func isPublic(fund: felt) -> (is_public: felt) {
    }

    func isAllowedDepositor(fund: felt, depositor: felt) -> (is_allowed_depositor: felt) {
    }

    func allowedDepositors(fund: felt) -> (allowedDepositor_len: felt, allowedDepositor: felt*) {
    }

    func isAllowedAssetToReedem(fund: felt, asset: felt) -> (is_allowed_asset_to_reedem: felt) {
    }

    func allowedAssetsToReedem(fund: felt) -> (
        allowed_assets_to_reedem_len: felt, allowed_assets_to_reedem: felt*
    ) {
    }
}

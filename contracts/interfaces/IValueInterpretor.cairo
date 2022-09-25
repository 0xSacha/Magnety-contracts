// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IValueInterpretor {
    // Setters

    func addDerivative(derivative: felt, price_feed: felt) {
    }

    func addExternalPosition(external_position: felt, price_feed: felt) {
    }

    // Getters

    func calculAssetValue(baseAsset: felt, amount: Uint256, denomination_asset: felt) -> (
        asset_value: Uint256
    ) {
    }

    func derivativePriceFeed(derivative: felt) -> (price_feed: felt) {
    }

    func isSupportedDerivativeAsset(derivative: felt) -> (is_supported_derivative_asset: felt) {
    }

    func externalPositionPriceFeed(external_position: felt) -> (
        external_position_to_price_feed: felt
    ) {
    }

    func isSupportedExternalPosition(external_position: felt) -> (
        is_supported_external_position: felt
    ) {
    }
}

# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IValueInterpretor:

    #Setters

    func addDerivative(derivative: felt, price_feed: felt):
    end

    func addExternalPosition(external_position: felt, price_feed: felt):
    end

    #Getters

    func calculAssetValue(baseAsset : felt, amount: Uint256, denomination_asset : felt) -> (asset_value : Uint256):
    end

    func derivativePriceFeed(derivative : felt) -> (price_feed : felt):
    end

    func isSupportedDerivativeAsset(derivative : felt) -> (is_supported_derivative_asset : felt):
    end

    func externalPositionPriceFeed(external_position : felt) -> (external_position_to_price_feed : felt):
    end

    func isSupportedExternalPosition(external_position : felt) -> (is_supported_external_position : felt):
    end


end

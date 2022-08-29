# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IOraclePriceFeedMixin:
    func addPrimitive(_asset: felt, _key:felt):
    end

    func calcAssetValueBmToDeno(_baseAsset: felt, _amount:Uint256, _denominationAsset: felt) -> (res:Uint256):
    end
    
    func checkIsSupportedPrimitiveAsset(_asset: felt) -> (res:felt):
    end
end

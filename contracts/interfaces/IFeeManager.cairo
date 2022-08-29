# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

struct FeeConfig:
    member NONE : felt
    member ENTRANCE_FEE : felt
    member ENTRANCE_FEE_ENABLED : felt
    member EXIT_FEE : felt
    member EXIT_FEE_ENABLED : felt
    member PERFORMANCE_FEE : felt
    member PERFORMANCE_FEE_ENABLED : felt
    member MANAGEMENT_FEE : felt
    member MANAGEMENT_FEE_ENABLED : felt
end

@contract_interface
namespace IFeeManager:
    
    func setFeeConfig(vault : felt, key : felt, value : felt):
    end
    func getFeeConfig(vault : felt, key : felt) -> (value : felt):
    end
end

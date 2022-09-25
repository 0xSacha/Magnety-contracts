// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

struct FeeConfig {
    NONE: felt,
    ENTRANCE_FEE: felt,
    ENTRANCE_FEE_ENABLED: felt,
    EXIT_FEE: felt,
    EXIT_FEE_ENABLED: felt,
    PERFORMANCE_FEE: felt,
    PERFORMANCE_FEE_ENABLED: felt,
    MANAGEMENT_FEE: felt,
    MANAGEMENT_FEE_ENABLED: felt,
}

@contract_interface
namespace IFeeManager {
    func setFeeConfig(vault: felt, key: felt, value: felt) {
    }
    func getFeeConfig(vault: felt, key: felt) -> (value: felt) {
    }
}

# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

@contract_interface
namespace IPreLogic:
    func runPreLogic(_vault: felt, _callData_len:felt, _callData:felt*):
    end
end
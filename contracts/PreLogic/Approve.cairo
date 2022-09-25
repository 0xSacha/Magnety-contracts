// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IIntegrationManager import IIntegrationManager
from starkware.cairo.common.math import assert_not_zero

@storage_var
func vaultFactory() -> (res: felt) {
}

// @external
// func approve{
//         syscall_ptr : felt*,
//         pedersen_ptr : HashBuiltin*,
//         range_check_ptr
//     }(spender: felt, amount: Uint256) -> (success: felt):
//     ERC20.approve(spender, amount)
//     return (TRUE)
// end

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _vaultFactory: felt
) {
    vaultFactory.write(_vaultFactory);
    return ();
}

@external
func runPreLogic{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _vault: felt, _callData_len: felt, _callData: felt*
) {
    let spender_: felt = [_callData];
    let (VF_: felt) = vaultFactory.read();
    let (IM_: felt) = IVaultFactory.getIntegrationManager(VF_);
    let (isAllowedSpender_: felt) = IIntegrationManager.isIntegratedContract(IM_, spender_);
    with_attr error_message("approve: Spender contract not integrated to Magnety") {
        assert_not_zero(isAllowedSpender_);
    }
    return ();
}

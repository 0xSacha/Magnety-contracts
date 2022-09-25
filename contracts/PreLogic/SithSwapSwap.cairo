// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IIntegrationManager import IIntegrationManager

from starkware.cairo.common.math import assert_not_zero

// func swapExactTokensForTokensSupportingFeeOnTransferTokens(
//         amount_in : Uint256, amount_out_min : Uint256, routes_len : felt, routes : Route*,
//         to : felt, deadline : felt):
//     end

@storage_var
func vaultFactory() -> (res: felt) {
}

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
    let routes_len: felt = [_callData + 4];
    let incomingAsset_: felt = [_callData + 4 + 2 * routes_len];
    let (VF_: felt) = vaultFactory.read();
    let (IM_: felt) = IVaultFactory.getIntegrationManager(VF_);
    let (isAllowedAsset_: felt) = IIntegrationManager.isAvailableAsset(IM_, incomingAsset_);
    with_attr error_message("swapExactTokensForTokensFromAlphaRoad: incoming Asset not tracked") {
        assert_not_zero(isAllowedAsset_);
    }
    let (to_: felt) = [_callData + 4 + 3 * routes_len + 1];
    let (fund_: felt) = get_caller_address();
    let isFundReceiver: felt = to_ - fund_;
    with_attr error_message("addLiquidityFromSith: the fund has to be the receiver") {
        assert isFundReceiver = 0;
    }
    return ();
}

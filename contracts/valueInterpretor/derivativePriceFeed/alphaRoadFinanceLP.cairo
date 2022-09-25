%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.PreLogic.interfaces.IARFPool import IARFPool
from contracts.PreLogic.interfaces.IARFSwapController import IARFSwapController
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from contracts.interfaces.IVaultFactory import IVaultFactory
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

@storage_var
func IARFSwapControllerContract() -> (res: felt) {
}

@storage_var
func vaultFactory() -> (res: felt) {
}

func onlyOwner{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
    let (vaultFactory_) = vaultFactory.read();
    let (caller_) = get_caller_address();
    let (owner_) = IVaultFactory.getOwner(vaultFactory_);
    with_attr error_message("onlyVaultFactory: only callable by the owner") {
        assert owner_ = caller_;
    }
    return ();
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _vaultFactory: felt
) {
    vaultFactory.write(_vaultFactory);
    return ();
}

//
// Getter
//

@view
func calcUnderlyingValues{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _derivative: felt, _amount: Uint256
) -> (
    underlyingsAssets_len: felt,
    underlyingsAssets: felt*,
    underlyingsAmount_len: felt,
    underlyingsAmount: Uint256*,
) {
    alloc_locals;
    let (IARFSwapController_: felt) = IARFSwapControllerContract.read();
    with_attr error_message("calcUnderlyingValues: IARFSwapController address not found") {
        assert_not_zero(IARFSwapController_);
    }
    let (isPoolExist_: felt) = IARFPool.name(_derivative);
    with_attr error_message("calcUnderlyingValues: can't find pool from LPtoken") {
        assert_not_zero(isPoolExist_);
    }
    let (underlyingsAssets_: felt*) = alloc();
    let (underlyingsAmount_: Uint256*) = alloc();
    let (totalSupply_: Uint256) = IARFPool.totalSupply(_derivative);
    let (underlyingsAssets0_: felt) = IARFPool.getToken0(_derivative);
    assert [underlyingsAssets_] = underlyingsAssets0_;
    let (underlyingsAssets1_: felt) = IARFPool.getToken1(_derivative);
    assert [underlyingsAssets_ + 1] = underlyingsAssets1_;
    let (reserveToken0_: Uint256, reserveToken1_: Uint256) = IARFPool.getReserves(_derivative);
    let (amountToken0_: Uint256, amountToken1_: Uint256) = IARFSwapController.removeLiquidityQuote(
        IARFSwapController_, _amount, reserveToken0_, reserveToken1_, totalSupply_
    );
    assert [underlyingsAmount_] = amountToken0_;
    assert [underlyingsAmount_ + 2] = amountToken1_;
    return (
        underlyingsAssets_len=2,
        underlyingsAssets=underlyingsAssets_,
        underlyingsAmount_len=2,
        underlyingsAmount=underlyingsAmount_,
    );
}

@view
func getIARFSwapController{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    res: felt
) {
    let (res_: felt) = IARFSwapControllerContract.read();
    return (res=res_);
}

//
// External
//
@external
func setIARFSwapController{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _IARFSwapController: felt
) {
    onlyOwner();
    IARFSwapControllerContract.write(_IARFSwapController);
    return ();
}

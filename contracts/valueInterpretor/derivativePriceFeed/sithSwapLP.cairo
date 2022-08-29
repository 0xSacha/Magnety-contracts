%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.ISithSwap import ISithSwapV1Pair
from contracts.interfaces.ISithSwap import ISithSwapV1Router01
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from interfaces.IVaultFactory import IVaultFactory

@storage_var
func sithSwapRouter() -> (res: felt):
end


@storage_var
func vaultFactory() -> (res: felt):
end


func onlyOwner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    let (owner_) = IVaultFactory.getOwner(vaultFactory_)
    with_attr error_message("onlyVaultFactory: only callable by the owner"):
        assert owner_ = caller_
    end
    return ()
end


@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _vaultFactory: felt,
    ):
    vaultFactory.write(_vaultFactory)
    return ()
end



#
#Getter
#

@view
func calcUnderlyingValues{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_derivative: felt, _amount: Uint256) -> ( underlyingsAssets_len:felt, underlyingsAssets:felt*, underlyingsAmount_len:felt, underlyingsAmount:Uint256* ):
    alloc_locals
    let(sithSwapRouter_:felt) = sithSwapRouter.read()
    with_attr error_message("calcUnderlyingValues: sithSwapRouter address not found"):
        assert_not_zero(sithSwapRouter_)
    end

    let (underlyingsAssets_ : felt*) = alloc()
    let (underlyingsAmount_ : Uint256*) = alloc()
    
    let (underlyingsAssets0_:felt) = ISithSwapV1Pair.getToken0(_derivative)
    assert [underlyingsAssets_] = underlyingsAssets0_
    let (underlyingsAssets1_:felt) = ISithSwapV1Pair.getToken1(_derivative)
    assert [underlyingsAssets_ + 1] = underlyingsAssets1_
    let (amountToken0_:Uint256, amountToken1_:Uint256) = ISithSwapV1Router01.quoteRemoveLiquidity(underlyingsAssets0_, underlyingsAssets1_, ,_amount)
    assert [underlyingsAmount_] = amountToken0_
    assert [underlyingsAmount_+2] = amountToken1_
    return (underlyingsAssets_len=2, underlyingsAssets=underlyingsAssets_, underlyingsAmount_len=2, underlyingsAmount=underlyingsAmount_)
end


@view
func getSithSwapRouter{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (res:felt):
    let(res_:felt) = sithSwapRouter.read()
    return(res=res_)
end


#
#External
#
@external
func setSithSwapRouter{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _sithSwapRouter: felt,
    ):
    onlyOwner()
    sithSwapRouter.write(_sithSwapRouter)
    return()
end
 

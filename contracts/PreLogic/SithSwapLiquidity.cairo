%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IIntegrationManager import IIntegrationManager

from contracts.interfaces.ISithSwap import ISithSwapV1Router01
from starkware.cairo.common.math import assert_not_zero

@storage_var
func sithSwapRouter() -> (res : felt):
end

@storage_var
func vaultFactory() -> (res : felt):
end

    # func addLiquidity(token_a : felt, token_b : felt, stable_state : felt, amount_a_desired : Uint256, 
    #     amount_b_desired : Uint256,amount_a_min : Uint256, amount_b_min : Uint256, to : felt, deadline : felt)->(
    #     amount_a : Uint256, amount_b : Uint256, liquidity : Uint256):
    # end


@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _vaultFactory:felt,
        _sithSwapRouter: felt,
    ):
    sithSwapRouter.write(_IARFPoolFactory)
    vaultFactory.write(_vaultFactory)
    return ()
end

@external
func runPreLogic{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr 
    }(_vault:felt, _callData_len:felt, _callData:felt*):
    let (sithSwapRouter_:felt) = sithSwapRouter.read()
    let token0_:felt = [_callData]
    let token1_:felt = [_callData + 1]
    let stableState_:felt = [_callData + 2]
    let (incomingAsset_:felt) = ISithSwapV1Router01.pairFor(sithSwapRouter_, token0_, token1_, stableState_)
    let (VF_:felt) = vaultFactory.read()
    let (IM_:felt) = IVaultFactory.getIntegrationManager(VF_)
    let (isAllowedAsset_:felt) = IIntegrationManager.checkIsAssetAvailable(IM_, incomingAsset_)
    with_attr error_message("addLiquidityFromSith: incoming LP Asset not available on agnety"):
        assert_not_zero(isAllowedAsset_)
    end
    let (to_:felt) = [_callData + 11]
    let (fund_:felt) = get_caller_address()
    let isFundReceiver:felt = to_ - fund_
    with_attr error_message("addLiquidityFromSith: the fund has to be the receiver"):
        assert isFundReceiver = 0 
    end
    return()
end



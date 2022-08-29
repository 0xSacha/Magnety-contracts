# Declare this file as a StarkNet contract.
%lang starknet
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_le
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)
from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_mul_low, uint256_pow
from starkware.cairo.common.uint256 import Uint256, uint256_lt
from starkware.cairo.common.alloc import alloc

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IEmpiricOracle import IEmpiricOracle
from contracts.interfaces.IVaultFactory import IVaultFactory


@storage_var
func vaultFactory() -> (res: felt):
end


@storage_var
func isSupportedPrimitiveAsset(asset:felt) -> (res: felt):
end

@storage_var
func keyFromAsset(asset:felt) -> (res:felt):
end


func onlyOwner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    let (owner_) = IVaultFactory.getOwner(vaultFactory_)
    with_attr error_message("onlyOwner: only callable by the owner"):
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
# Getters
#

@view
@external
func checkIsSupportedPrimitiveAsset{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _asset: felt,
    ) -> (res:felt):
    let(res:felt) = isSupportedPrimitiveAsset.read(_asset)
    return(res=res)
end

@view
func calcAssetValueBmToDeno{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _baseAsset: felt,
        _amount: Uint256,
        _denominationAsset:felt,
    ) -> (res:Uint256):
    alloc_locals

    let (denominationAssetKey_:felt) = keyFromAsset.read(_denominationAsset)
    let (baseAssetAggregatorKey_:felt) = keyFromAsset.read(_baseAsset)
    let (vaultFactory_:felt) = vaultFactory.read()
    let (empiricOracle_:felt) = IVaultFactory.getOracle(vaultFactory_)

    let (denominationAssetRateFelt_:felt, decimalsDenominationAssetRate:felt,_,_) = IEmpiricOracle.get_value(empiricOracle_, denominationAssetKey_, 0)
    let (baseAssetRateFelt_:felt, decimalsBaseAssetRate:felt,_,_) = IEmpiricOracle.get_value(empiricOracle_, baseAssetAggregatorKey_, 0)

    let (denominationAssetRate__:Uint256) = felt_to_uint256(denominationAssetRateFelt_)    
    let (baseAssetRate__:Uint256) = felt_to_uint256(baseAssetRateFelt_)

    let (decimalsDenominationAssetRateUint256_:Uint256) = felt_to_uint256(decimalsDenominationAssetRate)
    let (decimalsBaseAssetRateUint256_:Uint256) = felt_to_uint256(decimalsBaseAssetRate)
    let (denoLowerThanBase_) = uint256_lt(decimalsDenominationAssetRateUint256_, decimalsBaseAssetRateUint256_)
    let (baseLowerThanDeno_) = uint256_lt(decimalsBaseAssetRateUint256_, decimalsDenominationAssetRateUint256_)


    ### security step to make sure the rate are given with the same decimal (always 18 for now but we never know)
    if denoLowerThanBase_ == 1:
         let decimalDiff_ = decimalsBaseAssetRate - decimalsDenominationAssetRate
         let (toMultiply:Uint256) = uint256_pow(Uint256(10,0),decimalDiff_)
         let (denominationAssetRate___) = uint256_mul_low(toMultiply, denominationAssetRate__)
         tempvar denominationAssetRate_ = denominationAssetRate___
         tempvar  baseAssetRate_ = baseAssetRate__
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        if baseLowerThanDeno_ == 1:
         let decimalDiff_ = decimalsDenominationAssetRate - decimalsBaseAssetRate
         let (toMultiply:Uint256) = uint256_pow(Uint256(10,0),decimalDiff_)
         let (baseAssetRate___:Uint256) =  uint256_mul_low(toMultiply,baseAssetRate__)
         tempvar denominationAssetRate_ = denominationAssetRate__
         tempvar  baseAssetRate_ = baseAssetRate___
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr

    else:
        tempvar  denominationAssetRate_ = denominationAssetRate__
        tempvar  baseAssetRate_ = baseAssetRate__
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
end
    end

    let baseAssetRate = baseAssetRate_
    let denominationAssetRate = denominationAssetRate_

    

    ### get asset decimals
    let (baseAssetDecimals:felt) = IERC20.decimals(_baseAsset)
    let (denominationAssetDecimals:felt) = IERC20.decimals(_denominationAsset)
    let (decimalsBaseAssetPow:Uint256) = uint256_pow(Uint256(10,0),baseAssetDecimals)
    let (decimalsDenominationAssetPow:Uint256) = uint256_pow(Uint256(10,0),denominationAssetDecimals)


    let(step_1:Uint256) = uint256_mul_low(baseAssetRate, _amount)
    let(step_2:Uint256) = uint256_div(step_1, denominationAssetRate)
    let(step_3:Uint256) = uint256_mul_low(step_2, decimalsDenominationAssetPow)
    let(step_4:Uint256) = uint256_div(step_3, decimalsBaseAssetPow)
    return (res=step_4)
end

#
#Setters
#

@external
func addPrimitive{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _asset: felt,
        _key: felt,
    ):
    onlyOwner()
    isSupportedPrimitiveAsset.write(_asset, 1)
    keyFromAsset.write(_asset, _key)
    let (vaultFactory_:felt) = vaultFactory.read()
    let (oracle_:felt) = IVaultFactory.getOracle(vaultFactory_)
    let (test_:felt, _,_,_) = IEmpiricOracle.get_value(oracle_, _key, 0)
    with_attr error_message("addPrimitive: asset not supported by Empiric"):
        assert_not_zero(test_)
    end
    return()
end


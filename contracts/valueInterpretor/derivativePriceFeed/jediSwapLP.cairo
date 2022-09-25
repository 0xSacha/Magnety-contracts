%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from contracts.PreLogic.interfaces.IJediSwapPair import IJediSwapPair, IJediSwapPairERC20

from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_mul_low

const PRECISION = 10000;

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
    let (token0_: felt) = IJediSwapPair.token0(_derivative);
    let (token1_: felt) = IJediSwapPair.token1(_derivative);
    let (totalSupply_: Uint256) = IJediSwapPairERC20.totalSupply(_derivative);
    let (amountMul_: Uint256) = uint256_mul_low(_amount, Uint256(PRECISION, 0));
    let (poolAllocation_: Uint256) = uint256_div(amountMul_, _amount);
    let (reserveToken0_: Uint256, reserveToken1_: Uint256, _) = IJediSwapPair.get_reserves(
        _derivative
    );
    let (underlyingAmount0Mul_: Uint256) = uint256_mul_low(poolAllocation_, reserveToken0_);
    let (underlyingAmount1Mul_: Uint256) = uint256_mul_low(poolAllocation_, reserveToken1_);
    let (precision_uint256_: Uint256) = felt_to_uint256(PRECISION);
    let (underlyingAmount0_: Uint256) = uint256_div(underlyingAmount0Mul_, precision_uint256_);
    let (underlyingAmount1_: Uint256) = uint256_div(underlyingAmount1Mul_, precision_uint256_);
    let (underlyingsAssets_: felt*) = alloc();
    let (underlyingsAmount_: Uint256*) = alloc();
    assert [underlyingsAssets_] = token0_;
    assert [underlyingsAssets_ + 1] = token1_;
    assert [underlyingsAmount_] = underlyingAmount0_;
    assert [underlyingsAmount_ + 2] = underlyingAmount1_;
    return (
        underlyingsAssets_len=2,
        underlyingsAssets=underlyingsAssets_,
        underlyingsAmount_len=2,
        underlyingsAmount=underlyingsAmount_,
    );
}

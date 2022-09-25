from starkware.cairo.common.math import split_felt, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import uint256_unsigned_div_rem, uint256_mul
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

func get_max{range_check_ptr}(op1, op2) -> (result: felt) {
    let le = is_le(op1, op2);
    if (le == 1) {
        return (op2,);
    } else {
        return (op1,);
    }
}

func floor_div{range_check_ptr}(a, b) -> (res: felt) {
    let (q, _) = unsigned_div_rem(a, b);
    return (q,);
}

func ceil_div{range_check_ptr}(a, b) -> (res: felt) {
    let (q, r) = unsigned_div_rem(a, b);
    if (r == 0) {
        return (q,);
    } else {
        return (q + 1,);
    }
}

func update_msize{range_check_ptr}(msize, offset, size) -> (result: felt) {
    // Update MSIZE on memory access from 'offset' to 'offset +
    // size', according to the rules specified in the yellow paper.
    if (size == 0) {
        return (msize,);
    }

    let (result) = get_max(msize, offset + size);
    return (result,);
}

func round_down_to_multiple{range_check_ptr}(x, div) -> (y: felt) {
    let (r) = floor_div(x, div);
    return (r * div,);
}

func round_up_to_multiple{range_check_ptr}(x, div) -> (y: felt) {
    let (r) = ceil_div(x, div);
    return (r * div,);
}

func felt_to_uint256{range_check_ptr}(x) -> (x_: Uint256) {
    let split = split_felt(x);
    return (Uint256(low=split.low, high=split.high),);
}

func uint256_to_address_felt(x: Uint256) -> (address: felt) {
    return (x.low + x.high * 2 ** 128,);
}
// Todo - This should be updated to precise float div function
func uint256_div{range_check_ptr}(x: Uint256, y: Uint256) -> (res: Uint256) {
    let (res, _rem) = uint256_unsigned_div_rem(x, y);
    return (res=res);
}

func uint256_mul_low{range_check_ptr}(x: Uint256, y: Uint256) -> (res: Uint256) {
    let (res: Uint256, high: Uint256) = uint256_mul(x, y);
    return (res=res);
}

func uint256_percent{pedersen_ptr: HashBuiltin*, range_check_ptr}(x: Uint256, percent: Uint256) -> (
    res: Uint256
) {
    let (mul, _high) = uint256_mul(x, percent);
    assert _high.low = 0;
    assert _high.high = 0;

    let (res) = uint256_div(mul, Uint256(10 ** 2, 0));

    return (res=res);
}

func uint256_permillion{pedersen_ptr: HashBuiltin*, range_check_ptr}(
    x: Uint256, permillion: Uint256
) -> (res: Uint256) {
    let (mul, _high) = uint256_mul(x, permillion);
    assert _high.low = 0;
    assert _high.high = 0;
    let (res) = uint256_div(mul, Uint256(10 ** 6, 0));
    return (res=res);
}

func uint256_pow{pedersen_ptr: HashBuiltin*, range_check_ptr}(x: Uint256, pow: felt) -> (
    res: Uint256
) {
    if (pow == 0) {
        return (Uint256(1, 0),);
    }

    let (prev_res) = uint256_pow(x, pow - 1);
    let (res) = uint256_mul_low(x, prev_res);
    return (res=res);
}

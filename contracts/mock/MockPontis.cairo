// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

struct Entry {
    key: felt,
    value: felt,
    timestamp: felt,
    publisher: felt,
}

@storage_var
func price(key: felt) -> (value: felt) {
}

@view
func get_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(key: felt) -> (
    value: felt, last_updated_timestamp: felt
) {
    alloc_locals;
    let (value) = price.read(key);

    return (value=value, last_updated_timestamp=0);
}

@external
func set_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    key: felt, value: felt
) {
    price.write(key, value);
    return ();
}

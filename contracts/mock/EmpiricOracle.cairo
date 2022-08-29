%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc



@storage_var
func key_to_value(key: felt) -> (res : felt):
end

@storage_var
func key_to_decimals(key: felt) -> (res : felt):
end

@external
func set_value{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(key : felt, value : felt, decimals : felt):
    key_to_value.write(key,value)
    key_to_decimals.write(key, decimals)
    return ()
end

#
# Oracle Implementation Controller Functions
#

@view
func get_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    key : felt, aggregation_mode : felt
) -> (value : felt, decimals : felt, last_updated_timestamp : felt, num_sources_aggregated : felt):
    let last_updated_timestamp = 0
    let num_sources_aggregated = 0
    let (value) = key_to_value.read(key)
    let (decimals) = key_to_decimals.read(key)
    return (value, decimals, last_updated_timestamp, num_sources_aggregated)
end

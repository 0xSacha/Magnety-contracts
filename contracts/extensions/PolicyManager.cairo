%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import alloc
struct MaxMin {
    max: Uint256,
    min: Uint256,
}

struct integration {
    contract: felt,
    selector: felt,
}

// # STORAGE

@storage_var
func vault_factory() -> (vault_factory: felt) {
}

@storage_var
func is_public(vault: felt) -> (is_public: felt) {
}

@storage_var
func id_to_allowed_depositor(vault: felt, id: felt) -> (id_to_allowed_depositor: felt) {
}

@storage_var
func allowed_depositor_to_id(vault: felt, depositor: felt) -> (allowed_depositor_to_id: felt) {
}

@storage_var
func allowed_depositors_length(vault: felt) -> (allowed_depositors_length: felt) {
}

@storage_var
func is_allowed_depositor(vault: felt, depositor: felt) -> (is_allowed_depositor: felt) {
}

@storage_var
func id_to_allowed_asset_to_reedem(vault: felt, id: felt) -> (allowed_asset_to_reedem: felt) {
}

@storage_var
func allowed_asset_to_reedem_to_id(vault: felt, id: felt) -> (id: felt) {
}

@storage_var
func allowed_assets_to_reedem_length(vault: felt) -> (allowed_asset_to_reedem_length: felt) {
}

@storage_var
func is_allowed_asset_to_reedem(vault: felt, depositor: felt) -> (
    is_allowed_asset_to_reedem: felt
) {
}

//
// Modifiers
//

func only_vault_factory{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
    let (vault_factory_) = vault_factory.read();
    let (caller_) = get_caller_address();
    with_attr error_message("only_vault_factory: only callable by the vaultFactory") {
        assert (vault_factory_ - caller_) = 0;
    }
    return ();
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    vault_factory_address: felt
) {
    vault_factory.write(vault_factory_address);
    return ();
}

@view
func isPublic{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(fund: felt) -> (
    is_public: felt
) {
    let (is_public_) = is_public.read(fund);
    return (is_public_,);
}

@view
func isAllowedDepositor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fund: felt, depositor: felt
) -> (is_allowed_depositor: felt) {
    let (is_allowed_depositor_) = is_allowed_depositor.read(fund, depositor);
    return (is_allowed_depositor_,);
}

@view
func allowedDepositors{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fund: felt
) -> (allowedDepositor_len: felt, allowedDepositor: felt*) {
    alloc_locals;
    let (allowed_depositors_len: felt) = allowed_depositors_length.read(fund);
    let (local allowed_depositors: felt*) = alloc();
    complete_allowed_depositors_tab(fund, allowed_depositors_len, allowed_depositors, 0);
    return (allowed_depositors_len, allowed_depositors);
}

@view
func isAllowedAssetToReedem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fund: felt, asset: felt
) -> (is_allowed_asset_to_reedem: felt) {
    let (is_allowed_asset_to_reedem_) = is_allowed_asset_to_reedem.read(fund, asset);
    return (is_allowed_asset_to_reedem_,);
}

@view
func allowedAssetsToReedem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fund: felt
) -> (allowed_assets_to_reedem_len: felt, allowed_assets_to_reedem: felt*) {
    alloc_locals;
    let (allowed_assets_to_reedem_len: felt) = allowed_assets_to_reedem_length.read(fund);
    let (local allowed_assets_to_reedem: felt*) = alloc();
    complete_allowed_assets_to_reedem_tab(
        fund, allowed_assets_to_reedem_len, allowed_assets_to_reedem, 0
    );
    return (allowed_assets_to_reedem_len, allowed_assets_to_reedem);
}

// Setters

@external
func setAllowedDepositor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fund: felt, depositor: felt
) {
    only_vault_factory();
    let (is_allowed_depositor_: felt) = is_allowed_depositor.read(fund, depositor);
    if (is_allowed_depositor_ == 1) {
        return ();
    } else {
        is_allowed_depositor.write(fund, depositor, 1);
        let (allowed_depositors_len: felt) = allowed_depositors_length.read(fund);
        id_to_allowed_depositor.write(fund, allowed_depositors_len, depositor);
        allowed_depositor_to_id.write(fund, depositor, allowed_depositors_len);
        allowed_depositors_length.write(fund, allowed_depositors_len + 1);
        return ();
    }
}

@external
func setAllowedAssetToReedem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fund: felt, asset: felt
) {
    only_vault_factory();
    let (is_allowed_asset_to_reedem_: felt) = is_allowed_asset_to_reedem.read(fund, asset);
    if (is_allowed_asset_to_reedem_ == 1) {
        return ();
    } else {
        is_allowed_asset_to_reedem.write(fund, asset, 1);
        let (allowed_assets_to_reedem_len: felt) = allowed_assets_to_reedem_length.read(fund);
        id_to_allowed_asset_to_reedem.write(fund, allowed_assets_to_reedem_len, asset);
        allowed_asset_to_reedem_to_id.write(fund, asset, allowed_assets_to_reedem_len);
        allowed_assets_to_reedem_length.write(fund, allowed_assets_to_reedem_len + 1);
        return ();
    }
}

@external
func setIsPublic{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fund: felt, is_public_bool: felt
) {
    only_vault_factory();
    is_public.write(fund, is_public_bool);
    return ();
}

// # INTERALS - HELPERS

func complete_allowed_depositors_tab{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(fund: felt, allowed_depositors_len: felt, allowed_depositors: felt*, index: felt) -> () {
    if (allowed_depositors_len == 0) {
        return ();
    }
    let (depositor_: felt) = id_to_allowed_depositor.read(fund, index);
    assert allowed_depositors[index] = depositor_;
    return complete_allowed_depositors_tab(
        fund=fund,
        allowed_depositors_len=allowed_depositors_len - 1,
        allowed_depositors=allowed_depositors,
        index=index + 1,
    );
}

func complete_allowed_assets_to_reedem_tab{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(fund: felt, allowed_assets_to_reedem_len: felt, allowed_assets_to_reedem: felt*, index: felt) -> (
    ) {
    if (allowed_assets_to_reedem_len == 0) {
        return ();
    }
    let (asset_: felt) = id_to_allowed_asset_to_reedem.read(fund, index);
    assert allowed_assets_to_reedem[index] = asset_;
    return complete_allowed_assets_to_reedem_tab(
        fund=fund,
        allowed_assets_to_reedem_len=allowed_assets_to_reedem_len - 1,
        allowed_assets_to_reedem=allowed_assets_to_reedem,
        index=index + 1,
    );
}

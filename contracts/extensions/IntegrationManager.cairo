// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc

from contracts.interfaces.IIntegrationManager import IIntegrationManager

struct Integration {
    contract: felt,
    selector: felt,
}

@storage_var
func vault_factory() -> (res: felt) {
}

// # Integration

@storage_var
func available_integrations_length() -> (available_integrations_length: felt) {
}

@storage_var
func id_to_available_integration(id: felt) -> (integration: Integration) {
}

@storage_var
func is_available_integration(integration: Integration) -> (is_available_integration: felt) {
}

@storage_var
func integration_to_prelogic(integration: Integration) -> (prelogic: felt) {
}

@storage_var
func integration_required_fund_level(integration: Integration) -> (res: felt) {
}

@storage_var
func is_integrated_contract(contract: felt) -> (res: felt) {
}

// # Asset

@storage_var
func available_assets_length() -> (available_assets_length: felt) {
}

@storage_var
func id_to_available_asset(id: felt) -> (available_asset: felt) {
}

@storage_var
func is_available_asset(assetAddress: felt) -> (is_asset_available: felt) {
}

// # Shares

@storage_var
func available_shares_length() -> (res: felt) {
}

@storage_var
func id_to_available_share(id: felt) -> (res: felt) {
}

@storage_var
func is_available_share(assetAddress: felt) -> (res: felt) {
}

// # External Position

@storage_var
func available_external_positions_length() -> (res: felt) {
}

@storage_var
func id_to_available_external_position(id: felt) -> (external_position: felt) {
}

@storage_var
func is_available_external_position(externalPositionAddress: felt) -> (res: felt) {
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

//
// Getters
//

@view
func isAvailableShare{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    share: felt
) -> (is_vailable_share: felt) {
    let (is_vailable_share_) = is_available_share.read(share);
    return (is_vailable_share_,);
}

@view
func isAvailableAsset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    asset: felt
) -> (is_available_asset: felt) {
    let (is_available_asset_) = is_available_asset.read(asset);
    return (is_available_asset_,);
}

@view
func isAvailableExternalPosition{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    external_position: felt
) -> (is_available_external_position: felt) {
    let (is_available_external_position_) = is_available_external_position.read(external_position);
    return (is_available_external_position_,);
}

@view
func isAvailableIntegration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract: felt, selector: felt
) -> (is_available_integration: felt) {
    let (is_available_integration_) = is_available_integration.read(
        Integration(contract, selector)
    );
    return (is_available_integration_,);
}

@view
func isIntegratedContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract: felt
) -> (is_integrated_contract: felt) {
    let (is_integrated_contract_) = is_integrated_contract.read(contract);
    return (is_integrated_contract_,);
}

@view
func prelogicContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract: felt, selector: felt
) -> (prelogic: felt) {
    let (prelogic_) = integration_to_prelogic.read(Integration(contract, selector));
    return (prelogic_,);
}

@view
func integrationRequiredFundLevel{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract: felt, selector: felt
) -> (integration_required_fund_level: felt) {
    let (integration_required_fund_level_) = integration_required_fund_level.read(
        Integration(contract, selector)
    );
    return (integration_required_fund_level_,);
}

@view
func availableAssets{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    available_assets_len: felt, available_assets: felt*
) {
    alloc_locals;
    let (available_assets_len: felt) = available_assets_length.read();
    let (local available_assets: felt*) = alloc();
    complete_available_assets_tab(available_assets_len, available_assets);
    return (available_assets_len, available_assets);
}

@view
func availableExternalPositions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (available_external_positions_len: felt, available_external_positions: felt*) {
    alloc_locals;
    let (available_external_positions_len: felt) = available_external_positions_length.read();
    let (local available_external_positions: felt*) = alloc();
    complete_available_external_positions_tab(
        available_external_positions_len, available_external_positions
    );
    return (available_external_positions_len, available_external_positions);
}

@view
func availableIntegrations{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    available_integrations_len: felt, available_integrations: Integration*
) {
    alloc_locals;
    let (available_integrations_len: felt) = available_integrations_length.read();
    let (local available_integrations: Integration*) = alloc();
    complete_available_integrations_tab(available_integrations_len, available_integrations);
    return (available_integrations_len, available_integrations);
}

@view
func availableShares{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    share_available_len: felt, share_available: felt*
) {
    alloc_locals;
    let (available_shares_len: felt) = available_shares_length.read();
    let (local available_shares: felt*) = alloc();
    complete_available_shares_tab(available_shares_len, available_shares);
    return (available_shares_len, available_shares);
}

//
// Setters
//

@external
func setAvailableAsset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    asset: felt
) {
    only_vault_factory();
    let (is_available_asset_: felt) = is_available_asset.read(asset);
    if (is_available_asset_ == 1) {
        return ();
    } else {
        is_available_asset.write(asset, 1);
        let (available_assets_lenght_: felt) = available_assets_length.read();
        id_to_available_asset.write(available_assets_lenght_, asset);
        available_assets_length.write(available_assets_lenght_ + 1);
        return ();
    }
}

@external
func setAvailableShare{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    share: felt
) {
    only_vault_factory();
    let (is_available_share_: felt) = is_available_share.read(share);
    if (is_available_share_ == 1) {
        return ();
    } else {
        is_available_share.write(share, 1);
        let (available_shares_length_: felt) = available_shares_length.read();
        id_to_available_share.write(available_shares_length_, share);
        available_shares_length.write(available_shares_length_ + 1);
        return ();
    }
}

@external
func setAvailableExternalPosition{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    externalPosition: felt
) {
    only_vault_factory();
    let (is_available_external_position_: felt) = is_available_external_position.read(
        externalPosition
    );
    if (is_available_external_position_ == 1) {
        return ();
    } else {
        is_available_external_position.write(externalPosition, 1);
        let (available_external_positions_length_: felt) = available_external_positions_length.read(
            );
        id_to_available_external_position.write(
            available_external_positions_length_, externalPosition
        );
        available_external_positions_length.write(available_external_positions_length_ + 1);
        return ();
    }
}

@external
func setAvailableIntegration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract: felt, selector: felt, integration: felt, level: felt
) {
    only_vault_factory();
    let (is_available_integration_: felt) = is_available_integration.read(
        Integration(contract, selector)
    );
    if (is_available_integration_ == 1) {
        return ();
    } else {
        is_integrated_contract.write(contract, 1);
        is_available_integration.write(Integration(contract, selector), 1);
        integration_to_prelogic.write(Integration(contract, selector), integration);
        let (available_integrations_length_: felt) = available_integrations_length.read();
        id_to_available_integration.write(
            available_integrations_length_, Integration(contract, selector)
        );
        available_integrations_length.write(available_integrations_length_ + 1);
        integration_required_fund_level.write(Integration(contract, selector), level);
        return ();
    }
}

// # internal

func complete_available_shares_tab{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    available_shares_len: felt, available_shares: felt*
) -> () {
    if (available_shares_len == 0) {
        return ();
    }
    let (share_available_: felt) = id_to_available_share.read(available_shares_len - 1);
    assert available_shares[available_shares_len] = share_available_;
    return complete_available_shares_tab(
        available_shares_len=available_shares_len - 1, available_shares=available_shares
    );
}

// # Internal
func complete_available_assets_tab{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    available_assets_len: felt, available_assets: felt*
) -> () {
    if (available_assets_len == 0) {
        return ();
    }
    let (asset_: felt) = id_to_available_asset.read(available_assets_len - 1);
    assert available_assets[0] = asset_;
    return complete_available_assets_tab(
        available_assets_len=available_assets_len - 1, available_assets=available_assets + 1
    );
}

func complete_available_external_positions_tab{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(available_external_positions_len: felt, available_external_positions: felt*) -> () {
    if (available_external_positions_len == 0) {
        return ();
    }
    let (external_position_: felt) = id_to_available_external_position.read(
        available_external_positions_len - 1
    );
    assert available_external_positions[0] = external_position_;
    return complete_available_external_positions_tab(
        available_external_positions_len=available_external_positions_len - 1,
        available_external_positions=available_external_positions + 1,
    );
}

func complete_available_integrations_tab{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(available_integrations_len: felt, available_integrations: Integration*) -> () {
    if (available_integrations_len == 0) {
        return ();
    }
    let (integration_: Integration) = id_to_available_integration.read(
        available_integrations_len - 1
    );
    assert available_integrations[0] = integration_;
    return complete_available_integrations_tab(
        available_integrations_len=available_integrations_len - 1,
        available_integrations=available_integrations + Integration.SIZE,
    );
}

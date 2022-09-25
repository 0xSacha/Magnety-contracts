// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

struct Integration {
    contract: felt,
    selector: felt,
}

@contract_interface
namespace IIntegrationManager {
    // Setters
    func setAvailableAsset(_asset: felt) {
    }

    func setAvailableExternalPosition(_asset: felt) {
    }

    func setAvailableIntegration(
        _contract: felt, _selector: felt, _integration: felt, _level: felt
    ) {
    }

    // #Getters

    func isIntegratedContract(contract: felt) -> (is_integrated_contract: felt) {
    }

    func isAvailableAsset(asset: felt) -> (res: felt) {
    }

    func isAvailableIntegration(contract: felt, selector: felt) -> (res: felt) {
    }

    func isAvailableExternalPosition(external_position: felt) -> (
        is_available_external_position: felt
    ) {
    }

    func isAvailableShare(_share: felt) -> (res: felt) {
    }

    func prelogicContract(contract: felt, selector: felt) -> (prelogic: felt) {
    }

    func integrationRequiredFundLevel(contract: felt, selector: felt) -> (
        integration_required_fund_level: felt
    ) {
    }

    func availableAssets() -> (available_assets_len: felt, available_assets: felt*) {
    }

    func availableExternalPositions() -> (
        available_external_positions_len: felt, available_external_positions: felt*
    ) {
    }

    func availableShares() -> (share_available_len: felt, share_available: felt*) {
    }

    func availableIntegrations() -> (
        available_integrations_len: felt, available_integrations: Integration*
    ) {
    }
}

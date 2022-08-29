# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

struct Integration:
    member contract : felt
    member selector : felt
end



@contract_interface
namespace IIntegrationManager:


    #Setters 
    func setAvailableAsset(_asset: felt):
    end

    func setAvailableExternalPosition(_asset: felt):
    end

    func setAvailableIntegration(_contract: felt, _selector: felt, _integration:felt, _level:felt):
    end

 
    ##Getters

    func isIntegratedContract(contract: felt) -> (is_integrated_contract: felt):
    end


    func isAvailableAsset(asset: felt) -> (res: felt):
    end

    func isAvailableIntegration(contract: felt, selector:felt) -> (res: felt): 
    end

    func isAvailableExternalPosition(external_position: felt) -> (is_available_external_position: felt): 
    end

    func isAvailableShare(_share: felt) -> (res: felt): 
    end


    func prelogicContract(contract: felt, selector:felt) -> (prelogic: felt): 
    end

    func integrationRequiredFundLevel(contract: felt, selector:felt) -> (integration_required_fund_level: felt): 
    end


    func availableAssets() -> (available_assets_len : felt, available_assets :felt*): 
    end

    func availableExternalPositions() -> (available_external_positions_len : felt, available_external_positions :felt*): 
    end

    func availableShares() -> (share_available_len: felt, share_available:felt*): 
    end

    func availableIntegrations() -> (available_integrations_len:felt, available_integrations: Integration*): 
    end
end

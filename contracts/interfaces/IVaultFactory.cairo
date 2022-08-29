%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct Integration:
    member contract : felt
    member selector : felt
    member integration: felt
end
#
@contract_interface
namespace IVaultFactory:

    func getOwner() -> (res : felt):
    end

    func getOracle() -> (res : felt):
    end

    func getFeeManager() -> (res : felt):
    end

    func getPolicyManager() -> (res : felt):
    end

    func getIntegrationManager() -> (res : felt):
    end

    func getPrimitivePriceFeed() -> (res : felt):
    end

    func getValueInterpretor() -> (res : felt):
    end

    func getDaoTreasury() -> (res : felt):
    end

    func getStackingVault() -> (res : felt):
    end

    func getDaoTreasuryFee() -> (res : felt):
    end

    func getStackingVaultFee() -> (res : felt):
    end

    func getMaxFundLevel() -> (res : felt):
    end

    func getStackingDispute() -> (res : felt):
    end

    func getGuaranteeRatio() -> (res : felt):
    end

    func getExitTimestamp() -> (res : felt):
    end

    func getCloseFundRequest(fund: felt) -> (res : felt):
    end

    func getManagerGuaranteeRatio(account: felt) -> (res : felt):
    end

    

    ##Business


    func initializeFund(
    fund: felt,
    fundLevel: felt,
    fundName:felt,
    fundSymbol:felt,
    denominationAsset:felt,
    amount: Uint256,
    shareAmount: Uint256,
    feeConfig_len: felt,
    feeConfig: felt*,
    isPublic:felt,
    ):
    end

    func addAllowedDepositors(_fund:felt, _depositors_len:felt, _depositors:felt*):
    end

    func addGlobalAllowedIntegrations(allowed_integrations_len:felt, allowed_integrations:Integration*):
    end

    func addGlobalAllowedExternalPositions(externalPositionList_len:felt, externalPositionList:felt*):
    end

    func addGlobalAllowedAssets(assetList_len:felt, assetList:felt*):
    end


    func setFeeManager(fee_manager:felt):
    end

    func setPolicyManager(policy_manager:felt):
    end

    func setIntegrationManager(integration_manager:felt):
    end

    func setValueInterpretor(value_interpretor:felt):
    end

    func setOrcale(oracle:felt):
    end

    func setPrimitivePriceFeed(primitive_price_feed:felt):
    end

    func setApprovePrelogic(approve_prelogic:felt):
    end

    func setSharePriceFeed(share_price_feed:felt):
    end

    func setStackingVault(stacking_vault:felt):
    end

    func setDaoTreasury(dao_treasury:felt):
    end

    func setStackingVaultFee(stacking_vault_fee:felt):
    end

    func setDaoTreasuryFee(dao_treasury_fee:felt):
    end

    func setMaxFundLevel(max_fund_level:felt):
    end

    func setStackingDispute(stacking_dispute:felt):
    end

    func SetGuaranteeRatio(guarantee_ratio:felt):
    end

    func setExitTimestamp(exit_timestamp:felt):
    end

end

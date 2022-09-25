%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct Integration {
    contract: felt,
    selector: felt,
    integration: felt,
}
//
@contract_interface
namespace IVaultFactory {
    func getOwner() -> (res: felt) {
    }

    func getOracle() -> (res: felt) {
    }

    func getFeeManager() -> (res: felt) {
    }

    func getPolicyManager() -> (res: felt) {
    }

    func getIntegrationManager() -> (res: felt) {
    }

    func getPrimitivePriceFeed() -> (res: felt) {
    }

    func getValueInterpretor() -> (res: felt) {
    }

    func getDaoTreasury() -> (res: felt) {
    }

    func getStackingVault() -> (res: felt) {
    }

    func getDaoTreasuryFee() -> (res: felt) {
    }

    func getStackingVaultFee() -> (res: felt) {
    }

    func getMaxFundLevel() -> (res: felt) {
    }

    func getStackingDispute() -> (res: felt) {
    }

    func getGuaranteeRatio() -> (res: felt) {
    }

    func getExitTimestamp() -> (res: felt) {
    }

    func getCloseFundRequest(fund: felt) -> (res: felt) {
    }

    func getManagerGuaranteeRatio(account: felt) -> (res: felt) {
    }

    // #Business

    func initializeFund(
        fund: felt,
        fundLevel: felt,
        fundName: felt,
        fundSymbol: felt,
        denominationAsset: felt,
        amount: Uint256,
        shareAmount: Uint256,
        feeConfig_len: felt,
        feeConfig: felt*,
        isPublic: felt,
    ) {
    }

    func addAllowedDepositors(_fund: felt, _depositors_len: felt, _depositors: felt*) {
    }

    func addGlobalAllowedIntegrations(
        allowed_integrations_len: felt, allowed_integrations: Integration*
    ) {
    }

    func addGlobalAllowedExternalPositions(
        externalPositionList_len: felt, externalPositionList: felt*
    ) {
    }

    func addGlobalAllowedAssets(assetList_len: felt, assetList: felt*) {
    }

    func setFeeManager(fee_manager: felt) {
    }

    func setPolicyManager(policy_manager: felt) {
    }

    func setIntegrationManager(integration_manager: felt) {
    }

    func setValueInterpretor(value_interpretor: felt) {
    }

    func setOrcale(oracle: felt) {
    }

    func setPrimitivePriceFeed(primitive_price_feed: felt) {
    }

    func setApprovePrelogic(approve_prelogic: felt) {
    }

    func setSharePriceFeed(share_price_feed: felt) {
    }

    func setStackingVault(stacking_vault: felt) {
    }

    func setDaoTreasury(dao_treasury: felt) {
    }

    func setStackingVaultFee(stacking_vault_fee: felt) {
    }

    func setDaoTreasuryFee(dao_treasury_fee: felt) {
    }

    func setMaxFundLevel(max_fund_level: felt) {
    }

    func setStackingDispute(stacking_dispute: felt) {
    }

    func SetGuaranteeRatio(guarantee_ratio: felt) {
    }

    func setExitTimestamp(exit_timestamp: felt) {
    }
}

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.uint256 import Uint256

struct AccountCallArray {
    to: felt,
    selector: felt,
    data_offset: felt,
    data_len: felt,
}

struct AssetInfo {
    address: felt,
    amount: Uint256,
    valueInDeno: Uint256,
}

struct ShareWithdraw {
    address: felt,
    id: Uint256,
}

@contract_interface
namespace IFuccount {
    // Setters
    func activater(
        name: felt,
        symbol: felt,
        level: felt,
        denomination_asset: felt,
        manager: felt,
        shares_amount: Uint256,
        share_price_purchased: Uint256,
    ) {
    }

    func close() {
    }

    // Account getters

    func get_public_key() -> (res: felt) {
    }

    func get_nonce() -> (res: felt) {
    }

    func is_valid_signature(hash: felt, signature_len: felt, signature: felt*) -> (is_valid: felt) {
    }

    func supports_interface(interfaceId: felt) -> (success: felt) {
    }

    // Fund getters

    func manager() -> (res: felt) {
    }

    func denominationAsset() -> (res: felt) {
    }

    func assetBalance(_asset: felt) -> (res: Uint256) {
    }

    func notNulAssets() -> (not_nul_assets_len: felt, not_nul_assets: AssetInfo*) {
    }

    func notNulShares() -> (not_nul_shares_len: felt, not_nul_shares: felt*) {
    }

    func notNulPositions() -> (not_nul_positions_len: felt, not_nul_positions: felt*) {
    }

    func sharePrice() -> (share_price: Uint256) {
    }

    func liquidGav() -> (liquid_gav: Uint256) {
    }

    func notLiquidGav() -> (not_liquid_gav: Uint256) {
    }

    func gav() -> (gav: Uint256) {
    }

    func shareToDeno(id: Uint256, amount: Uint256) -> (
        denominationAsset: felt, amount_len: felt, amount: Uint256*
    ) {
    }

    func previewReedem(
        id: Uint256,
        amount: Uint256,
        assets_len: felt,
        assets: felt*,
        shares_len: felt,
        shares: ShareWithdraw*,
    ) -> (
        assetCallerAmount_len: felt,
        assetCallerAmount: Uint256*,
        assetManagerAmount_len: felt,
        assetManagerAmount: Uint256*,
        assetStackingVaultAmount_len: felt,
        assetStackingVaultAmount: Uint256*,
        assetDaoTreasuryAmount_len: felt,
        assetDaoTreasuryAmount: Uint256*,
        shareCallerAmount_len: felt,
        shareCallerAmount: Uint256*,
        shareManagerAmount_len: felt,
        shareManagerAmount: Uint256*,
        shareStackingVaultAmount_len: felt,
        shareStackingVaultAmount: Uint256*,
        shareDaoTreasuryAmount_len: felt,
        shareDaoTreasuryAmount: Uint256*,
    ) {
    }

    func previewDeposit(_amount: Uint256) -> (
        shareAmount: Uint256,
        fundAmount: Uint256,
        managerAmount: Uint256,
        treasuryAmount: Uint256,
        stackingVaultAmount: Uint256,
    ) {
    }

    // ERC1155-like getters

    func name() -> (res: felt) {
    }

    func symbol() -> (res: felt) {
    }

    func totalId() -> (res: Uint256) {
    }

    func sharesTotalSupply() -> (res: Uint256) {
    }

    func balanceOf(account: felt, id: Uint256) -> (balance: Uint256) {
    }

    func balanceOfBatch(accounts_len: felt, accounts: felt*, ids_len: felt, ids: Uint256*) -> (
        balances_len: felt, balances: Uint256*
    ) {
    }

    func isApprovedForAll(account: felt, operator: felt) -> (isApproved: felt) {
    }

    func ownerShares(account: felt) -> (
        assetId_len: felt, assetId: Uint256*, assetAmount_len: felt, assetAmount: Uint256*
    ) {
    }

    func sharePricePurchased(tokenId: Uint256) -> (res: Uint256) {
    }

    func mintedBlockTimestamp(tokenId: Uint256) -> (res: felt) {
    }

    // # Business

    // Account

    func __execute__(
        call_array_len: felt,
        call_array: AccountCallArray*,
        calldata_len: felt,
        calldata: felt*,
        nonce: felt,
    ) -> (response_len: felt, response: felt*) {
    }

    func daoExecute(
        call_array_len: felt,
        call_array: AccountCallArray*,
        calldata_len: felt,
        calldata: felt*,
        nonce: felt,
    ) -> (response_len: felt, response: felt*) {
    }

    // Fund

    func deposit(_amount: Uint256) {
    }

    func reedem(
        id: Uint256,
        amount: Uint256,
        assets_len: felt,
        assets: felt*,
        shares_len: felt,
        shares: ShareWithdraw*,
    ) {
    }

    // Shares

    func setApprovalForAll(operator: felt, approved: felt) {
    }

    func safeTransferFrom(from_: felt, to: felt, id: Uint256, amount: Uint256) {
    }

    func safeBatchTransferFrom(
        from_: felt, to: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*
    ) {
    }

    func burn(from_: felt, id: Uint256, amount: Uint256) {
    }

    func burnBatch(
        from_: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*
    ) {
    }
}

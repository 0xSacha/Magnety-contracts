// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.2.1 (account/presets/Account.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from contracts.FuccountLib import (
    FuccountLib,
    AccountCallArray,
    AssetInfo,
    PositionInfo,
    ShareWithdraw,
    ShareInfo,
)
from starkware.cairo.common.uint256 import Uint256

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    public_key: felt, vaultFactory: felt
) {
    FuccountLib.initializer(public_key, vaultFactory);
    return ();
}

//
// Getters
//

// Account

@view
func get_public_key{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: felt
) {
    let (res) = FuccountLib.get_public_key();
    return (res=res);
}

@view
func get_nonce{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = FuccountLib.get_nonce();
    return (res=res);
}

@view
func supports_interface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = FuccountLib.supports_interface(interfaceId);
    return (success,);
}

// fund

@view
func manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res: felt) = FuccountLib.get_manager_account();
    return (res,);
}
@view
func denominationAsset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: felt
) {
    let (res: felt) = FuccountLib.get_denomination_asset();
    return (res=res);
}

@view
func assetBalance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _asset: felt
) -> (res: Uint256) {
    let (assetBalance_: Uint256) = FuccountLib.get_asset_balance(_asset);
    return (assetBalance_,);
}

@view
func notNulAssets{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    notNulAssets_len: felt, notNulAssets: AssetInfo*
) {
    let (notNulAssets_len: felt, notNulAssets: AssetInfo*) = FuccountLib.get_not_nul_assets();
    return (notNulAssets_len, notNulAssets);
}

func notNulShares{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    notNulShares_len: felt, notNulShares: ShareInfo*
) {
    return FuccountLib.get_not_nul_shares();
}

@view
func notNulPositions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    notNulPositions_len: felt, notNulPositions: felt*
) {
    let (
        notNulPositions_len: felt, notNulPositions: AssetInfo*
    ) = FuccountLib.get_not_nul_positions();
    return (notNulPositions_len, notNulPositions);
}

@view
func shareToDeno{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id: Uint256, amount: Uint256
) -> (denominationAsset: felt, amount_len: felt, amount: Uint256*) {
    return FuccountLib.share_to_deno(id, amount);
}

@view
func sharePrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    price: Uint256
) {
    let (price: Uint256) = FuccountLib.get_share_price();
    return (price=price);
}

@view
func liquidGav{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    gav: Uint256
) {
    let (gav) = FuccountLib.calcul_liquid_gav();
    return (gav=gav);
}

@view
func notLiquidGav{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    gav: Uint256
) {
    let (gav) = FuccountLib.calcul_not_liquid_gav();
    return (gav=gav);
}

@view
func gav{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (gav: Uint256) {
    let (gav) = FuccountLib.calcul_gav();
    return (gav=gav);
}

@view
func previewReedem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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
    return FuccountLib.preview_reedem(id, amount, assets_len, assets, shares_len, shares);
}

func previewDeposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _amount: Uint256
) -> (
    shareAmount: Uint256,
    fundAmount: Uint256,
    managerAmount: Uint256,
    treasuryAmount: Uint256,
    stackingVaultAmount: Uint256,
) {
    return FuccountLib.preview_deposit(_amount);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (name_) = FuccountLib.get_name();
    return (name_,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (symbol_) = FuccountLib.get_symbol();
    return (symbol_,);
}

@view
func totalId{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (res: Uint256) {
    let (totalSupply_: Uint256) = FuccountLib.get_total_id();
    return (totalSupply_,);
}

@view
func sharesTotalSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    res: Uint256
) {
    let (sharesTotalSupply_: Uint256) = FuccountLib.get_shares_total_supply();
    return (sharesTotalSupply_,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, id: Uint256
) -> (balance: Uint256) {
    let (balance: Uint256) = FuccountLib.balance_of(account, id);
    return (balance,);
}

@view
func ownerShares{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (assetId_len: felt, assetId: Uint256*, assetAmount_len: felt, assetAmount: Uint256*) {
    let (
        assetId_len: felt, assetId: Uint256*, assetAmount_len: felt, assetAmount: Uint256*
    ) = FuccountLib.owner_shares(account);
    return (assetId_len, assetId, assetAmount_len, assetAmount);
}

@view
func sharePricePurchased{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (res: Uint256) {
    let (sharePricePurchased_: Uint256) = FuccountLib.get_share_price_purchased(tokenId);
    return (sharePricePurchased_,);
}

@view
func mintedBlockTimestamp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (res: felt) {
    let (mintedTimesTamp_: felt) = FuccountLib.get_minted_block_timestamp(tokenId);
    return (mintedTimesTamp_,);
}

@view
func balanceOfBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    accounts_len: felt, accounts: felt*, ids_len: felt, ids: Uint256*
) -> (balances_len: felt, balances: Uint256*) {
    let (balances_len, balances) = FuccountLib.balance_of_batch(
        accounts_len, accounts, ids_len, ids
    );
    return (balances_len, balances);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt, operator: felt
) -> (isApproved: felt) {
    let (is_approved) = FuccountLib.is_approved_for_all(account, operator);
    return (is_approved,);
}

//
// Setters
//

@external
func activater{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fundName: felt,
    fundSymbol: felt,
    fundLevel: felt,
    denominationAsset: felt,
    managerAccount: felt,
    shareAmount: Uint256,
    sharePrice: Uint256,
) {
    FuccountLib.activater(
        fundName, fundSymbol, denominationAsset, managerAccount, shareAmount, sharePrice
    );
    FuccountLib.set_fund_level(fundLevel);
    return ();
}

@external
func close{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    FuccountLib.close();
    return ();
}

@external
func set_public_key{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_public_key: felt
) {
    FuccountLib.set_public_key(new_public_key);
    return ();
}

//
// Business logic
//

// Account

@view
func is_valid_signature{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}(hash: felt, signature_len: felt, signature: felt*) -> (is_valid: felt) {
    let (is_valid) = FuccountLib.is_valid_signature(hash, signature_len, signature);
    return (is_valid=is_valid);
}

@external
func __execute__{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr: SignatureBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
}(
    call_array_len: felt,
    call_array: AccountCallArray*,
    calldata_len: felt,
    calldata: felt*,
    nonce: felt,
) -> (response_len: felt, response: felt*) {
    let (response_len, response) = FuccountLib.execute(
        call_array_len, call_array, calldata_len, calldata, nonce
    );
    return (response_len=response_len, response=response);
}

@external
func daoExecute{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr: SignatureBuiltin*,
    bitwise_ptr: BitwiseBuiltin*,
}(
    call_array_len: felt,
    call_array: AccountCallArray*,
    calldata_len: felt,
    calldata: felt*,
    nonce: felt,
) -> (response_len: felt, response: felt*) {
    let (response_len, response) = FuccountLib.dao_execute(
        call_array_len, call_array, calldata_len, calldata, nonce
    );
    return (response_len=response_len, response=response);
}

// Fund

@external
func deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256) {
    FuccountLib.deposit(_amount);
    return ();
}

@external
func reedem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id: Uint256,
    amount: Uint256,
    assets_len: felt,
    assets: felt*,
    shares_len: felt,
    shares: ShareWithdraw*,
) {
    FuccountLib.reedem(id, amount, assets_len, assets, shares_len, shares);
    return ();
}

// Shares

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    FuccountLib.set_approval_for_all(operator, approved);
    return ();
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, id: Uint256, amount: Uint256
) {
    FuccountLib.safe_transfer_from(from_, to, id, amount);
    return ();
}

@external
func safeBatchTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*
) {
    FuccountLib.safe_batch_transfer_from(from_, to, ids_len, ids, amounts_len, amounts);
    return ();
}

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, id: Uint256, amount: Uint256
) {
    FuccountLib.burn(from_, id, amount);
    return ();
}

@external
func burnBatch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*
) {
    FuccountLib.burn_batch(from_, ids_len, ids, amounts_len, amounts);
    return ();
}

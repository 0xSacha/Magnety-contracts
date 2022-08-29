%lang starknet


from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import (get_block_timestamp, get_contract_address, get_caller_address, call_contract, get_tx_info)
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.cairo_secp.signature import verify_eth_signature_uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le,
    unsigned_div_rem,
    split_felt,
)

from openzeppelin.introspection.IERC165 import IERC165
from openzeppelin.introspection.ERC165 import ERC165
from contracts.interfaces.IERC1155Receiver import IERC1155_Receiver
from openzeppelin.security.safemath import SafeUint256
from openzeppelin.security.reentrancyguard import ReentrancyGuard

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_add,
    uint256_mul,
    uint256_eq
)
from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_pow, uint256_mul_low

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IFeeManager import FeeConfig, IFeeManager
from contracts.interfaces.IPolicyManager import IPolicyManager
from contracts.interfaces.IFuccount import IFuccount
from contracts.interfaces.IStackingDispute import IStackingDispute
from contracts.interfaces.IPreLogic import IPreLogic
from contracts.interfaces.IIntegrationManager import IIntegrationManager
from contracts.interfaces.IValueInterpretor import IValueInterpretor


const IERC1155_ID = 0xd9b67a26
const IERC1155_METADATA_ID = 0x0e89341c
const IERC1155_RECEIVER_ID = 0x4e2312e0
const ON_ERC1155_RECEIVED_SELECTOR = 0xf23a6e61
const ON_ERC1155_BATCH_RECEIVED_SELECTOR = 0xbc197c81
const IACCOUNT_ID = 0xf10dbd44
const POW18 = 1000000000000000000
const PRECISION = 1000000
const SECOND_YEAR = 31536000

#
# Structs
#

struct AssetInfo:
    member address : felt
    member amount : Uint256
    member valueInDeno : Uint256
end

struct ShareInfo:
    member address : felt
    member amount : Uint256
    member id : Uint256
    member valueInDeno : Uint256
end

struct ShareWithdraw:
    member address : felt
    member id : Uint256
end

struct PositionInfo:
    member address : felt
    member valueInDeno : Uint256
end

struct Call:
    member to: felt
    member selector: felt
    member calldata_len: felt
    member calldata: felt*
end

# Tmp struct introduced while we wait for Cairo
# to support passing `[AccountCall]` to __execute__
struct AccountCallArray:
    member to: felt
    member selector: felt
    member data_offset: felt
    member data_len: felt
end


#
# Events
#

@event
func transfer_single(
    operator: felt,
    from_: felt,
    to: felt,
    id: Uint256,
    value: Uint256
):
end

@event
func transfer_batch(
    operator: felt,
    from_: felt,
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    values_len: felt,
    values: Uint256*
):
end

@event
func approval_for_all(account: felt, operator: felt, approved: felt):
end

#
# Storage
#

@storage_var
func ERC1155_balances(id: Uint256, account: felt) -> (balance: Uint256):
end

@storage_var
func ERC1155_operator_approvals(account: felt, operator: felt) -> (approved: felt):
end

@storage_var
func total_id() -> (res: Uint256):
end

@storage_var
func share_price_purchased(token_id: Uint256) -> (res: Uint256):
end

@storage_var
func minted_block_timestamp(token_id: Uint256) -> (res: felt):
end

@storage_var
func shares_total_supply() -> (res: Uint256):
end

@storage_var
func name() -> (res: felt):
end

@storage_var
func symbol() -> (res: felt):
end

@storage_var
func vault_factory() -> (res : felt):
end

@storage_var
func manager_account() -> (res : felt):
end

@storage_var
func denomination_asset() -> (res : felt):
end

@storage_var
func account_current_nonce() -> (res: felt):
end

@storage_var
func account_public_key() -> (res: felt):
end

@storage_var
func fund_level() -> (res: felt):
end

@storage_var
func isFundRevoked() -> (res: felt):
end

@storage_var
func isFundClosed() -> (res: felt):
end




namespace FuccountLib:

    #
    # Constructor
    #

    func initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _public_key: felt,
        _vault_factory: felt,
    ):
        with_attr error_message("constructor: cannot set the vault_factory to the zero address"):
        assert_not_zero(_vault_factory)
        end
        vault_factory.write(_vault_factory)
        account_public_key.write(_public_key)
        ERC165.register_interface(IACCOUNT_ID)
        ERC165.register_interface(IERC1155_ID)
        ERC165.register_interface(IERC1155_METADATA_ID)
        return ()
    end

    func activater{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            _name: felt,
            _symbol: felt,
            _denomination_asset: felt,
            _manager_account:felt,
            _shareAmount:Uint256,
            _sharePrice:Uint256,
        ):
        only_vault_factory()
        name.write(_name)
        symbol.write(_symbol)
        denomination_asset.write(_denomination_asset)
        manager_account.write(_manager_account)
        mint(_manager_account, _shareAmount, _sharePrice)
        return ()
    end
    
    #
    # Guards
    #

    func assert_only_self{syscall_ptr : felt*}():
        let (self) = get_contract_address()
        let (caller) = get_caller_address()

        with_attr error_message("Fund: caller is not this account"):
            assert self = caller
        end
        return ()
    end

    func only_vault_factory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vault_factory_) = vault_factory.read()
    let (caller_) = get_caller_address()
    with_attr error_message("Fund: only callable by the vault_factory"):
        assert (vault_factory_ - caller_) = 0
    end
    return ()
    end


    #
    # Getters
    #


    func balance_of{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(account: felt, id: Uint256) -> (balance: Uint256):
        with_attr error_message("ERC1155: balance query for the zero address"):
            assert_not_zero(account)
        end
        let (balance) = ERC1155_balances.read(id, account)
        return (balance)
    end

    func balance_of_batch{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            accounts_len: felt,
            accounts: felt*,
            ids_len: felt,
            ids: Uint256*
        ) -> (
            batch_balances_len: felt,
            batch_balances: Uint256*
        ):
        alloc_locals
        # Check args are equal length arrays
        with_attr error_message("ERC1155: accounts and ids length mismatch"):
            assert ids_len = accounts_len
        end
        # Allocate memory
        let (local batch_balances: Uint256*) = alloc()
        let len = accounts_len
        # Call iterator
        balance_of_batch_iter(len, accounts, ids, batch_balances)
        let batch_balances_len = len
        return (batch_balances_len, batch_balances)
    end

    func is_approved_for_all{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(account: felt, operator: felt) -> (approved: felt):
        let (approved) = ERC1155_operator_approvals.read(account, operator)
        return (approved)
    end

    func get_share_price_purchased{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (res: Uint256):
    let (share_price_purchased_: Uint256) = share_price_purchased.read(tokenId)
    return (share_price_purchased_)
    end

    func get_minted_block_timestamp{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (res: felt):
    let (minted_block_timestamp_: felt) = minted_block_timestamp.read(tokenId)
    return (minted_block_timestamp_)
    end

    func supports_interface{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    return ERC165.supports_interface(interfaceId)
    end

    func get_shares_total_supply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (totalSupply: Uint256):
    let (totalSupply: Uint256) = shares_total_supply.read()
    return (totalSupply)
    end

    func get_total_id{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (res: Uint256):
    let (total_id_: Uint256) = total_id.read()
    return (total_id_)
    end


func owner_shares{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*):
    alloc_locals
    let (total_id_:Uint256) = total_id.read()
    let (local assetId : Uint256*) = alloc()
    let (local assetAmount : Uint256*) = alloc()
    let (tabSize_:felt) = _complete_multi_share_tab(total_id_, 0, assetId, 0, assetAmount, account)    
    return (tabSize_, assetId, tabSize_, assetAmount)
end


func get_name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (name_) = name.read()
    return (name_)
end

func get_symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (symbol_) = symbol.read()
    return (symbol_)
end




func get_vault_factory{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = vault_factory.read()
    return (res) 
end

func get_manager_account{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = manager_account.read()
    return (res) 
end

func get_denomination_asset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = denomination_asset.read()
    return (res=res)
end


func get_asset_balance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_asset: felt) -> (assetBalance_: Uint256):
    let (account_:felt) = get_contract_address()
    let (assetBalance_:Uint256) = IERC20.balanceOf(contract_address=_asset, account=account_)
    return (assetBalance_)
end

func get_share_balance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_share: felt, _id: Uint256) -> (shareBalance_: Uint256):
    let (account_:felt) = get_contract_address()
    let (shareBalance_:Uint256) = IFuccount.balanceOf(account_, _share, _id)
    return (shareBalance_)
end


func get_not_nul_assets{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulAssets_len:felt, notNulAssets: AssetInfo*):
    alloc_locals
    let (IM_:felt) = _get_integration_manager()
    let (availableAssets_len: felt, availableAssets:felt*) = IIntegrationManager.availableAssets(IM_)
    let (local notNulAssets : AssetInfo*) = alloc()
    let (notNulAssets_len:felt) = _complete_non_nul_asset_tab(availableAssets_len, availableAssets, 0, notNulAssets)    
    return(notNulAssets_len, notNulAssets)
end


func get_not_nul_shares{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulShares_len:felt, notNulShares: ShareInfo*):
    alloc_locals
    let (IM_:felt) = _get_integration_manager()
    let (selfAddress) = get_contract_address()
    let (denomination_asset_) = get_denomination_asset()
    let (availableAShares_len: felt, availableShares:felt*) = IIntegrationManager.availableShares(IM_)
    let (local notNulShares : ShareInfo*) = alloc()
    let (notNulShares_len:felt) = _complete_non_nul_shares_tab(availableAShares_len, availableShares, 0, notNulShares, selfAddress, denomination_asset_)    
    return(notNulShares_len, notNulShares)
end

func get_not_nul_positions{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulPositions_len:felt, notNulPositition: felt*):
    alloc_locals
    let (IM_:felt) = _get_integration_manager()
    let (availableExternalPositions_len: felt, availableExternalPositions:felt*) = IIntegrationManager.availableExternalPositions(IM_)
    let (local notNulExternalPositions : PositionInfo*) = alloc()
    let (notNulExternalPositions_len:felt) = _complete_non_nul_position_tab(availableExternalPositions_len, availableExternalPositions, 0, notNulExternalPositions)    
    return(notNulExternalPositions_len, notNulExternalPositions)
end



func get_share_price{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
     res : Uint256
):
    alloc_locals
    let (gav) = calcul_gav()
    #shares have 18 decimals
    let (gavPow18_:Uint256,_) = uint256_mul(gav, Uint256(POW18,0))
    let (total_supply) = shares_total_supply.read()
    let (price : Uint256) = uint256_div(gavPow18_, total_supply)
    return (res=price)
end


func get_asset_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _asset: felt, _amount: Uint256, _denomination_asset: felt
) -> (res: Uint256):
    let (valueInterpretor_:felt) = _get_value_interpretor()
    let (value_:Uint256) = IValueInterpretor.calculAssetValue(valueInterpretor_, _asset, _amount, _denomination_asset)
    return (res=value_)
end

func getShareValue{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _share: felt, _id: Uint256, _amount: Uint256, _denomination_asset: felt
) -> (res: Uint256):
    let (valueInterpretor_:felt) = _get_value_interpretor()
    let (value_:Uint256) = IValueInterpretor.calculAssetValue(valueInterpretor_, _share, Uint256(_amount.low, _id.low), _denomination_asset)
    return (res=value_)
end



func calcul_liquid_gav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : Uint256
):
    alloc_locals
    let (assets_len: felt, assets: AssetInfo*) = get_not_nul_assets()
    let (gavAsset_) = __calcul_gav_asset(assets_len, assets)
    let (shares_len:felt, shares: ShareInfo*) = get_not_nul_shares()
    let (gavShare_) = __calcul_gav_share(shares_len, shares)
    let (gav,_) = uint256_add(gavAsset_, gavShare_)
    return (res=gav)
end

func calcul_not_liquid_gav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : Uint256
):
    alloc_locals
    let (externalPosition_len: felt, externalPosition: PositionInfo*) = get_not_nul_positions()
    let (gav) = __calcul_gav_position(externalPosition_len, externalPosition)
    return (res=gav)
end

func calcul_gav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : Uint256
):
    alloc_locals
    let (gav1_) = calcul_liquid_gav()
    let (gav2_) = calcul_not_liquid_gav()
    let (gav, _) = uint256_add(gav1_, gav2_)
    return (res=gav)
end


func is_free_reedem{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount: Uint256) -> (is_free_reedem: felt):
    alloc_locals
    let (policyManager_:felt) = _get_policy_manager()
    let (contractAddress_:felt) = get_contract_address()
    let (allowedAssetToReedem_len: felt, allowedAssetToReedem:felt*) = IPolicyManager.allowedAssetsToReedem(policyManager_, contractAddress_)
    if allowedAssetToReedem_len == 0:
    return (1)
    else:
    let (denomination_asset_)= denomination_asset.read()
    let (valueInDeno_:Uint256) = _sum_value_in_deno(allowedAssetToReedem_len, allowedAssetToReedem, denomination_asset_)
    let (sharePrice_) = get_share_price()
    let (shareValueInDenoTemp_:Uint256) = SafeUint256.mul(sharePrice_, amount)
    let (shareValueInDeno_:Uint256,_) = SafeUint256.div_rem(shareValueInDenoTemp_, Uint256(POW18,0))
    let (is_free_reedem:felt) = uint256_le(valueInDeno_, shareValueInDeno_)
    return(is_free_reedem)
    end
end

func is_available_reedem{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount: Uint256) -> (is_available_reedem: felt):
    alloc_locals
    let (liquidGav_) = calcul_liquid_gav()
    let (sharePrice_) = get_share_price()
    let (shareValueInDenoTemp_:Uint256) = SafeUint256.mul(sharePrice_, amount)
    let (shareValueInDeno_:Uint256,_) = SafeUint256.div_rem(shareValueInDenoTemp_, Uint256(POW18,0))
    let (is_available_reedem) = uint256_le(shareValueInDeno_, liquidGav_)
    return(is_available_reedem)
end


func share_to_deno{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : Uint256, amount : Uint256) -> (denominationAsset: felt, amount_len: felt, amount:Uint256*):
    alloc_locals

    let (denominationAsset_:felt) = denomination_asset.read()
    let (sharePrice_) = get_share_price()
    let (sharesValuePow_:Uint256,_) = uint256_mul(sharePrice_, amount)
    let (sharesValue_:Uint256) = uint256_div(sharesValuePow_, Uint256(POW18,0))

    #calculate the performance 
    let(previous_share_price_:Uint256) = share_price_purchased.read(id)
    let(has_performed_) = uint256_le(previous_share_price_, sharePrice_)
    if has_performed_ == 1 :
        let(diff_:Uint256) = SafeUint256.sub_le(sharePrice_, previous_share_price_)
        let(diffPermillion_:Uint256,diffperc_h_) = uint256_mul(diff_, Uint256(PRECISION,0))
        let(perfF_:Uint256)=uint256_div(diffPermillion_, sharePrice_)
        tempvar perf_ = perfF_
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar perf_ = Uint256(0,0)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    let performancePermillion_ = perf_

    #calculate the duration

    let (mintedBlockTimesTamp_:felt) =  get_minted_block_timestamp(id)
    let (currentTimesTamp_:felt) = get_block_timestamp()
    let diff = currentTimesTamp_ - mintedBlockTimesTamp_
    let diff_precision = diff * PRECISION
    let (durationPermillion_,_) = unsigned_div_rem(diff_precision, SECOND_YEAR)


    let (fund_:felt) = get_caller_address()
    let (local assetCallerAmount : Uint256*) = alloc()
    let (local assetManagerAmount : Uint256*) = alloc()
    let (local assetStackingVaultAmount : Uint256*) = alloc()
    let (local assetDaoTreasuryAmount : Uint256*) = alloc()
    let (local assetAmounts : Uint256*) = alloc()
    assert assetAmounts[0] = sharesValue_
    _reedem_tab(1,  assetAmounts, performancePermillion_, durationPermillion_, fund_, 0, assetCallerAmount, assetManagerAmount, assetStackingVaultAmount, assetDaoTreasuryAmount)
    return(denominationAsset_,1,assetCallerAmount)
    end

        

func preview_reedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : Uint256,
    amount : Uint256,
    assets_len : felt,
    assets : felt*,
    shares_len : felt,
    shares : ShareWithdraw*,
) -> (assetCallerAmount_len: felt,assetCallerAmount:Uint256*, assetManagerAmount_len: felt,assetManagerAmount:Uint256*,assetStackingVaultAmount_len: felt, assetStackingVaultAmount:Uint256*, assetDaoTreasuryAmount_len: felt,assetDaoTreasuryAmount:Uint256*, shareCallerAmount_len: felt, shareCallerAmount:Uint256*, shareManagerAmount_len: felt, shareManagerAmount:Uint256*, shareStackingVaultAmount_len: felt, shareStackingVaultAmount:Uint256*, shareDaoTreasuryAmount_len: felt, shareDaoTreasuryAmount:Uint256*):
    alloc_locals
    let (is_available_reedem_) = is_available_reedem(amount)
    with_attr error_message("preview_reedem: Not enought liquid positions"):
            assert is_available_reedem_ = 1
    end

    let (isFreeReedem_:felt) = is_free_reedem(amount)
    let (fund_:felt) = get_contract_address()
    if isFreeReedem_ == 0:
        with_attr error_message("preview_reedem: Only allowed assets can be reedem"):
            assert shares_len = 0
        end
        let (policyManager_:felt) = _get_policy_manager()
        _assert_allowed_asset_to_reedem(assets_len, assets, policyManager_, fund_)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr
    tempvar range_check_ptr = range_check_ptr
    end
    let (denomination_asset_:felt) = denomination_asset.read()
    let (sharePrice_) = get_share_price()
    let (sharesValuePow_:Uint256,_) = uint256_mul(sharePrice_, amount)
    let (sharesValue_:Uint256) = uint256_div(sharesValuePow_, Uint256(POW18,0))

    #calculate the performance 
    let(previous_share_price_:Uint256) = share_price_purchased.read(id)
    let(has_performed_) = uint256_le(previous_share_price_, sharePrice_)
    if has_performed_ == 1 :
        let(diff_:Uint256) = SafeUint256.sub_le(sharePrice_, previous_share_price_)
        let(diffPermillion_:Uint256,diffperc_h_) = uint256_mul(diff_, Uint256(PRECISION,0))
        let(perfF_:Uint256)=uint256_div(diffPermillion_, sharePrice_)
        tempvar perf_ = perfF_
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar perf_ = Uint256(0,0)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    let performancePermillion_ = perf_

    #calculate the duration

    let (minted_block_timestamp_:felt) = get_minted_block_timestamp(id)
    let (currentTimesTamp_:felt) = get_block_timestamp()
    let diff = currentTimesTamp_ - minted_block_timestamp_
    let diff_precision = diff * PRECISION
    let (durationPermillion_,_) = unsigned_div_rem(diff_precision, SECOND_YEAR)

    let (local assetCallerAmount : Uint256*) = alloc()
    let (local assetManagerAmount : Uint256*) = alloc()
    let (local assetStackingVaultAmount : Uint256*) = alloc()
    let (local assetDaoTreasuryAmount : Uint256*) = alloc()
    let (local shareCallerAmount : Uint256*) = alloc()
    let (local shareManagerAmount : Uint256*) = alloc()
    let (local shareStackingVaultAmount : Uint256*) = alloc()
    let (local shareDaoTreasuryAmount : Uint256*) = alloc()

    let (local assetAmounts : Uint256*) = alloc()
    let (local shareAmounts : Uint256*) = alloc()

    let (remainingValue_: Uint256, len: felt) = _calc_amount_of_each_asset(sharesValue_, assets_len, assets, 0,assetAmounts , denomination_asset_)
    let (isRemaingValueNul_: felt) = uint256_eq(remainingValue_, Uint256(0,0))
    if isRemaingValueNul_ == 0:
        let (remainingValue2_: Uint256, len2: felt) = _calc_amount_of_each_share(remainingValue_, shares_len, shares, 0, shareAmounts , denomination_asset_)
        let (isRemaingValue2Nul_: felt) = uint256_eq(remainingValue2_, Uint256(0,0))
        with_attr error_message("preview_reedem: Choose more Assets/Shares to reedem"):
            assert isRemaingValue2Nul_ = 1
        end
        _reedem_tab(len,  assetAmounts, performancePermillion_, durationPermillion_, fund_, 0, assetCallerAmount, assetManagerAmount, assetStackingVaultAmount, assetDaoTreasuryAmount)
        _reedem_tab(len2, shareAmounts, performancePermillion_, durationPermillion_, fund_, 0, shareCallerAmount, shareManagerAmount, shareStackingVaultAmount, shareDaoTreasuryAmount)
        return(len,assetCallerAmount, len,assetManagerAmount,len, assetStackingVaultAmount, len,assetDaoTreasuryAmount, len2, shareCallerAmount, len2, shareManagerAmount, len2, shareStackingVaultAmount, len2, shareDaoTreasuryAmount)
    else:
    _reedem_tab(len,  assetAmounts, performancePermillion_, durationPermillion_, fund_, 0, assetCallerAmount, assetManagerAmount, assetStackingVaultAmount, assetDaoTreasuryAmount)
    return(len,assetCallerAmount, len,assetManagerAmount,len, assetStackingVaultAmount, len,assetDaoTreasuryAmount, 0, shareCallerAmount, 0, shareManagerAmount, 0, shareStackingVaultAmount, 0, shareDaoTreasuryAmount)
    end
end
func mint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        to: felt, 
        sharesAmount: Uint256, 
        _sharePricePurchased:Uint256,
    ):
    let (totalId_) = total_id.read()
    share_price_purchased.write(totalId_, _sharePricePurchased)
    let (currentTimesTamp_:felt) = get_block_timestamp()
    minted_block_timestamp.write(totalId_, currentTimesTamp_)
    let (currentTotalSupply_) = shares_total_supply.read()
    let (newTotalSupply_,_) = uint256_add(currentTotalSupply_, sharesAmount )
    shares_total_supply.write(newTotalSupply_)
    let (newTotalId_,_) = uint256_add(totalId_, Uint256(1,0) )
    total_id.write(newTotalId_)
    _mint(to, totalId_, sharesAmount)
    return ()
end



    func _assert_allowed_asset_to_reedem{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(asset_len:felt, asset: felt*, policyManager: felt, contractAddress: felt):
        if asset_len == 0:
            return()
        end
        let (isAllowedAssetToReedem_) = IPolicyManager.isAllowedAssetToReedem(policyManager, contractAddress, asset[0])
        with_attr error_message("_assert_allowed_asset_to_reedem:  Only allowed assets can be reedem"):
            assert isAllowedAssetToReedem_ = 1
        end
        return _assert_allowed_asset_to_reedem(asset_len - 1, asset + 1, policyManager, contractAddress)
    end


    func get_public_key{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (res: felt):
        let (res) = account_public_key.read()
        return (res=res)
    end

    func get_nonce{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (res: felt):
        let (res) = account_current_nonce.read()
        return (res=res)
    end

    func get_fund_level{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (res: felt):
        let (res) = fund_level.read()
        return (res=res)
    end


    #
    # Externals
    #


func preview_deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_amount: Uint256
) -> (shareAmount: Uint256, fundAmount: Uint256, managerAmount: Uint256, treasuryAmount: Uint256, stackingVaultAmount: Uint256):
    alloc_locals
    let (fund_:felt) = get_contract_address()
    let (denomination_asset_:felt) = denomination_asset.read()
    let (caller_ : felt) = get_caller_address()
    let (fee, fee_assset_manager, fee_treasury, fee_stacking_vault) = _get_fee(fund_, FeeConfig.ENTRANCE_FEE, _amount)
    let (sharePrice_) = get_share_price()
    let (fundAmount_) = uint256_sub(_amount, fee)
    let (amountWithoutFeesPow_,_) = uint256_mul(fundAmount_, Uint256(10**18,0))
    let (shareAmount_) = uint256_div(amountWithoutFeesPow_, sharePrice_)
    return (shareAmount_, fundAmount_, fee_assset_manager, fee_treasury, fee_stacking_vault)
end



    #
    # Externals
    #



    func revoke{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        alloc_locals
        let (vaultFactory_:felt) = vault_factory.read()
        let (stackingDispute_:felt) = IVaultFactory.getStackingDispute()
        let (caller_ : felt) = get_caller_address()
        with_attr error_message("revoke: not allowed caller"):
            assert caller_ = stackingDispute_
        end
        isFundRevoked.write(1)
        return ()
    end

    func revoke_result{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(isReportAccepted: felt):
        alloc_locals
        let (vaultFactory_:felt) = vault_factory.read()
        let (stackingDispute_:felt) = IVaultFactory.getStackingDispute()
        let (caller_ : felt) = get_caller_address()
        with_attr error_message("revoke: not allowed caller"):
            assert caller_ = stackingDispute_
        end
        if isReportAccepted == 1:
            isFundRevoked.write(0)
            isFundClosed.write(1)
        else:
            isFundRevoked.write(0)
        end
        return ()
    end

    func close{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        alloc_locals
        only_vault_factory()
        isFundClosed.write(1)
        return ()
    end




func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
     _amount: Uint256,
):
    alloc_locals
    let (fund_:felt) = get_contract_address()
    let (denomination_asset_:felt) = denomination_asset.read()
    let (caller_ : felt) = get_caller_address()
    let (manager_ : felt) = manager_account.read()
    _assert_allowed_depositor(caller_)
    let (shareAmount_: Uint256, fundAmount_: Uint256, managerAmount_: Uint256, treasuryAmount_: Uint256, stackingVaultAmount_: Uint256) = preview_deposit(_amount)
    # transfer fee to fee_treasury, stacking_vault
    let (treasury:felt) = _get_dao_treasury()
    let (stacking_vault:felt) = _get_stacking_vault()

    # transfer asset
    IERC20.transferFrom(denomination_asset_, caller_, manager_, managerAmount_)
    IERC20.transferFrom(denomination_asset_, caller_, treasury, treasuryAmount_)
    IERC20.transferFrom(denomination_asset_, caller_, stacking_vault, stackingVaultAmount_)
    IERC20.transferFrom(denomination_asset_, caller_, fund_, fundAmount_)
    let (sharePrice_) = get_share_price()

    # mint share
    mint(caller_, shareAmount_, sharePrice_)
    _assert_enought_guarantee()
    return ()
end


func reedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : Uint256,
    amount : Uint256,
    assets_len : felt,
    assets : felt*,
    shares_len : felt,
    shares : ShareWithdraw*,
):
    alloc_locals
    let (len: felt,assetCallerAmount:Uint256*, len: felt,assetManagerAmount:Uint256*, len: felt, assetStackingVaultAmount:Uint256*,  len: felt, assetDaoTreasuryAmount:Uint256*, len2: felt, shareCallerAmount:Uint256*,  len2: felt, shareManagerAmount:Uint256*,  len2: felt, shareStackingVaultAmount:Uint256*,  len2: felt, shareDaoTreasuryAmount:Uint256*) = preview_reedem( id,amount,assets_len,assets, shares_len, shares )

    let (caller_:felt) = get_caller_address()
    let (fund_:felt) = get_contract_address()

    #check timelock (fund lvl3)
    let (fund_level_:felt) = get_fund_level()
    if fund_level_ == 3:
        # let (policyManager_:felt) = _get_policy_manager()
        # let (currentTimesTamp_:felt) = get_block_timestamp()
        # let (reedemTime_:felt) = IPolicyManager.getReedemTime(policyManager_, fund_)
        # with_attr error_message("reedem: timelock not reached"):
        #     assert_le(reedemTime_, currentTimesTamp_)
        # end
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
    tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    # burn share
    burn(caller_, id, amount)

    #transferEachAsset
    let (fund_ : felt) = get_contract_address()
    let (caller : felt) = get_caller_address()
    let (manager : felt) = get_manager_account()
    let (stackingVault_ : felt) = _get_stacking_vault()
    let (daoTreasury_ : felt) = _get_dao_treasury()
    _transfer_each_asset(fund_, caller, manager, stackingVault_, daoTreasury_, assets_len, assets, assetCallerAmount, assetManagerAmount, assetStackingVaultAmount, assetDaoTreasuryAmount)
    _transfer_each_share(fund_, caller, manager, stackingVault_, daoTreasury_, shares_len, shares, shareCallerAmount, shareManagerAmount, shareStackingVaultAmount, shareDaoTreasuryAmount)
    return ()
end



    func set_approval_for_all{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(operator: felt, approved: felt):
        let (caller) = get_caller_address()
        with_attr error_message("ERC1155: cannot approve from the zero address"):
            assert_not_zero(caller)
        end
        _set_approval_for_all(caller, operator, approved)
        return ()
    end

    func safe_transfer_from{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            from_: felt,
            to: felt,
            id: Uint256,
            amount: Uint256,
        ):
        let (caller) = get_caller_address()
        with_attr error_message("ERC1155: cannot call transfer from the zero address"):
            assert_not_zero(caller)
        end
        with_attr error_message("ERC1155: caller is not owner nor approved"):
            assert_owner_or_approved(from_)
        end
        _safe_transfer_from(from_, to, id, amount)
        return ()
    end

    func safe_batch_transfer_from{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            from_: felt,
            to: felt,
            ids_len: felt,
            ids: Uint256*,
            amounts_len: felt,
            amounts: Uint256*,
        ):
        let (caller) = get_caller_address()
        with_attr error_message("ERC1155: cannot call transfer from the zero address"):
            assert_not_zero(caller)
        end
        with_attr error_message("ERC1155: transfer caller is not owner nor approved"):
            assert_owner_or_approved(from_)
        end
        _safe_batch_transfer_from(from_, to, ids_len, ids, amounts_len, amounts)
        return ()
    end


# func mint{
#         syscall_ptr: felt*,
#         pedersen_ptr: HashBuiltin*,
#         range_check_ptr
#     }(
#         to: felt, 
#         sharesAmount: Uint256, 
#         _sharePricePurchased:Uint256,
#     ):
#     let (totalId_) = totalId.read()
#     sharePricePurchased.write(totalId_, _sharePricePurchased)
#     let (currentTimesTamp_:felt) = get_block_timestamp()
#     mintedBlockTimesTamp.write(totalId_, currentTimesTamp_)
#     let (currentTotalSupply_) = sharesTotalSupply.read()
#     let (newTotalSupply_,_) = uint256_add(currentTotalSupply_, sharesAmount )
#     sharesTotalSupply.write(newTotalSupply_)
#     let (newTotalId_,_) = uint256_add(totalId_, Uint256(1,0) )
#     totalId.write(newTotalId_)
#     _mint(to, totalId_, sharesAmount)
#     return ()
# end


func burn{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(from_: felt, id: Uint256, amount: Uint256):
    alloc_locals
    assert_owner_or_approved(owner=from_)
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    _burn(from_, id, amount)
    let (currentTotalSupply_) = shares_total_supply.read()
    let (newTotalSupply_) = uint256_sub(currentTotalSupply_, amount )
    shares_total_supply.write(newTotalSupply_)
    return ()
end



func burn_batch{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        from_: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*
    ):
    assert_owner_or_approved(owner=from_)
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    _burn_batch(from_, ids_len, ids, amounts_len, amounts)
    reduce_supply_batch(amounts_len, amounts)
    return ()
end

func set_public_key{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(new_public_key: felt):
        assert_only_self()
        account_public_key.write(new_public_key)
        return ()
    end

    func set_fund_level{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(_fund_level: felt):
        only_vault_factory()
        fund_level.write(_fund_level)
        return ()
    end

    func execute{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            ecdsa_ptr: SignatureBuiltin*,
            bitwise_ptr: BitwiseBuiltin*
        }(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata_len: felt,
            calldata: felt*,
            nonce: felt
        ) -> (response_len: felt, response: felt*):
        alloc_locals
        let (isFundClosed_:felt) = isFundClosed.read()
        let (isFundRevoked_: felt) = isFundRevoked.read()
        with_attr error_message("Account: fund is revoked or closed"):
            assert isFundClosed_ + isFundRevoked_ = 0
        end

        let (__fp__, _) = get_fp_and_pc()
        let (tx_info) = get_tx_info()

        # validate transaction
        with_attr error_message("Account: invalid signature"):
            let (is_valid) = is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature)
            assert is_valid = TRUE
        end

        return _unsafe_execute(call_array_len, call_array, calldata_len, calldata, nonce)
    end

func dao_execute{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        ecdsa_ptr: SignatureBuiltin*,
        bitwise_ptr: BitwiseBuiltin*
    }(
        call_array_len: felt,
        call_array: AccountCallArray*,
        calldata_len: felt,
        calldata: felt*,
        nonce: felt
    ) -> (response_len: felt, response: felt*):
    let (vault_factory_) = vault_factory.read()
    let (dao_) = IVaultFactory.getOwner(vault_factory_)
    let (caller_) = get_caller_address()
    with_attr error_message("dao_execute: caller is not dao"):
        assert caller_ = dao_
    end
    return _unsafe_execute(call_array_len, call_array, calldata_len, calldata, nonce)
end

    func eth_execute{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            ecdsa_ptr: SignatureBuiltin*,
            bitwise_ptr: BitwiseBuiltin*
        }(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata_len: felt,
            calldata: felt*,
            nonce: felt
        ) -> (response_len: felt, response: felt*):
        alloc_locals

        let (__fp__, _) = get_fp_and_pc()
        let (tx_info) = get_tx_info()

        # validate transaction
        with_attr error_message("Account: invalid secp256k1 signature"):
            let (is_valid) = is_valid_eth_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature)
            assert is_valid = TRUE
        end

        return _unsafe_execute(call_array_len, call_array, calldata_len, calldata, nonce)
    end


    #
    # Internals
    #

func _sum_value_in_deno{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(asset_len: felt, asset: felt*, denomination_asset: felt) -> (valueInDeno: Uint256):
    alloc_locals
    if asset_len == 0:
        return(Uint256(0,0))
    end
    let (fundAssetBalance:Uint256) = get_asset_balance(asset[0])
    let (AssetvalueInDeno_: Uint256) = get_asset_value(asset[0], fundAssetBalance, denomination_asset)
    let (valueOfRest_: Uint256) = _sum_value_in_deno(asset_len - 1, asset + 1, denomination_asset)
    let (totalValueInDeno:Uint256) = SafeUint256.add(AssetvalueInDeno_, valueOfRest_)
    return(valueInDeno=totalValueInDeno)
end


func _unsafe_execute{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            ecdsa_ptr: SignatureBuiltin*,
            bitwise_ptr: BitwiseBuiltin*
        }(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata_len: felt,
            calldata: felt*,
            nonce: felt
        ) -> (response_len: felt, response: felt*):
        alloc_locals

        let (caller) = get_caller_address()
        with_attr error_message("Account: no reentrant call"):
            assert caller = 0
        end

        # validate nonce

        let (_current_nonce) = account_current_nonce.read()

        with_attr error_message("Account: nonce is invalid"):
            assert _current_nonce = nonce
        end

        # bump nonce
        account_current_nonce.write(_current_nonce + 1)

        # TMP: Convert `AccountCallArray` to 'Call'.
        let (calls : Call*) = alloc()
        _from_call_array_to_call(call_array_len, call_array, calldata, calls)
        let calls_len = call_array_len

        # execute call
        let (response : felt*) = alloc()
        let (response_len) = _execute_list(calls_len, calls, response)

        return (response_len=response_len, response=response)
    end

    func _execute_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            calls_len: felt,
            calls: Call*,
            response: felt*
        ) -> (response_len: felt):
        alloc_locals

        # if no more calls
        if calls_len == 0:
           return (0)
        end

        # do the current call
        let this_call: Call = [calls]
        _check_call(this_call.to, this_call.selector, this_call.calldata_len, this_call.calldata)
        let res = call_contract(
            contract_address=this_call.to,
            function_selector=this_call.selector,
            calldata_size=this_call.calldata_len,
            calldata=this_call.calldata
        )
        # copy the result in response
        memcpy(response, res.retdata, res.retdata_size)
        # do the next calls recursively
        let (response_len) = _execute_list(calls_len - 1, calls + Call.SIZE, response + res.retdata_size)
        return (response_len + res.retdata_size)
    end

    func _from_call_array_to_call{syscall_ptr: felt*}(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata: felt*,
            calls: Call*
        ):
        # if no more calls
        if call_array_len == 0:
           return ()
        end

        # parse the current call
        assert [calls] = Call(
                to=[call_array].to,
                selector=[call_array].selector,
                calldata_len=[call_array].data_len,
                calldata=calldata + [call_array].data_offset
            )
        # parse the remaining calls recursively
        _from_call_array_to_call(call_array_len - 1, call_array + AccountCallArray.SIZE, calldata, calls + Call.SIZE)
        return ()
    end


func _check_call{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _contract: felt, _selector: felt, _callData_len: felt, _callData: felt*):
    alloc_locals
    #check if allowed call
    let (vault_factory_:felt) = vault_factory.read()
    let (integrationManager_:felt) = IVaultFactory.getIntegrationManager(vault_factory_)
    let (isIntegrationAvailable_) = IIntegrationManager.isAvailableIntegration(integrationManager_, _contract, _selector)
    with_attr error_message("the operation is not allowed on Magnety"):
        assert isIntegrationAvailable_ = 1
    end

    let (fund_level_) = get_fund_level()
    let (integrationLevel_) = IIntegrationManager.integrationRequiredFundLevel(integrationManager_, _contract, _selector)
    with_attr error_message("the operation is not allowed for this fund"):
        assert_le(integrationLevel_, fund_level_)
    end

    #perform pre-call logic if necessary
    let (preLogicContract:felt) = IIntegrationManager.prelogicContract(integrationManager_, _contract, _selector)
    let (isPreLogicNonRequired:felt) = _is_zero(preLogicContract)
    let (contractAddress_:felt) = get_contract_address()
    if isPreLogicNonRequired ==  0:
        IPreLogic.runPreLogic(preLogicContract, contractAddress_, _callData_len, _callData)
        return ()
    end
    return ()
end


func is_valid_signature{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            ecdsa_ptr: SignatureBuiltin*
        }(
            hash: felt,
            signature_len: felt,
            signature: felt*
        ) -> (is_valid: felt):
        let (_public_key) = account_public_key.read()

        # This interface expects a signature pointer and length to make
        # no assumption about signature validation schemes.
        # But this implementation does, and it expects a (sig_r, sig_s) pair.
        let sig_r = signature[0]
        let sig_s = signature[1]

        verify_ecdsa_signature(
            message=hash,
            public_key=_public_key,
            signature_r=sig_r,
            signature_s=sig_s)

        return (is_valid=TRUE)
    end

    func is_valid_eth_signature{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            bitwise_ptr: BitwiseBuiltin*,
            range_check_ptr
        }(
            hash: felt,
            signature_len: felt,
            signature: felt*
        ) -> (is_valid: felt):
        alloc_locals
        let (_public_key) = get_public_key()
        let (__fp__, _) = get_fp_and_pc()

        # This interface expects a signature pointer and length to make
        # no assumption about signature validation schemes.
        # But this implementation does, and it expects a the sig_v, sig_r,
        # sig_s, and hash elements.
        let sig_v : felt = signature[0]
        let sig_r : Uint256 = Uint256(low=signature[1], high=signature[2])
        let sig_s : Uint256 = Uint256(low=signature[3], high=signature[4])
        let (high, low) = split_felt(hash)
        let msg_hash : Uint256 = Uint256(low=low, high=high)

        let (local keccak_ptr : felt*) = alloc()

        with keccak_ptr:
            verify_eth_signature_uint256(
                msg_hash=msg_hash,
                r=sig_r,
                s=sig_s,
                v=sig_v,
                eth_address=_public_key)
        end

        return (is_valid=TRUE)
    end


func _get_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault:felt, key: felt, amount: Uint256) -> (fee: Uint256, fee_asset_manager:Uint256, fee_treasury: Uint256, fee_stacking_vault: Uint256):
    alloc_locals
    let (isEntrance) = _is_zero(key - FeeConfig.ENTRANCE_FEE)
    let (isExit) = _is_zero(key - FeeConfig.EXIT_FEE)
    let (isPerformance) = _is_zero(key - FeeConfig.PERFORMANCE_FEE)
    let (isManagement) = _is_zero(key - FeeConfig.MANAGEMENT_FEE)

    let entranceFee = isEntrance * FeeConfig.ENTRANCE_FEE
    let exitFee = isExit * FeeConfig.EXIT_FEE
    let performanceFee = isPerformance * FeeConfig.PERFORMANCE_FEE
    let managementFee = isManagement * FeeConfig.MANAGEMENT_FEE

    let config = entranceFee + exitFee + performanceFee + managementFee

    let (feeManager_) = _get_fee_manager()
    let (percent) = IFeeManager.getFeeConfig(feeManager_, _vault, config)
    let (percent_uint256) = felt_to_uint256(percent)

    let (VF_) = get_vault_factory()
    let (daoTreasuryFee_) = _get_dao_treasury_fee()
    let (stackingVaultFee_) = _get_stacking_vault_fee()
    let sum_ = daoTreasuryFee_ + stackingVaultFee_
    let assetManagerFee_ = 100 - sum_

    let (fee) = uint256_percent(amount, percent_uint256)
    let (fee_asset_manager) = uint256_percent(fee, Uint256(assetManagerFee_,0))
    let (fee_stacking_vault) = uint256_percent(fee, Uint256(stackingVaultFee_,0))
    let (fee_treasury) = uint256_percent(fee, Uint256(daoTreasuryFee_,0))

    return (fee=fee, fee_asset_manager= fee_asset_manager,fee_treasury=fee_treasury, fee_stacking_vault=fee_stacking_vault)
end


func _calc_amount_of_each_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    totalValue : Uint256, asset_len : felt, asset : felt*, assetAmount_len: felt, assetAmount: Uint256*,denomination_asset: felt) -> (remainingValue:Uint256, len : felt):
    alloc_locals
    if asset_len == 0:
        return (totalValue, assetAmount_len)
    end
    let (assetFundbalance_: Uint256) = get_asset_balance(asset[0])
    let (isAssetFundBalanceNul_ : felt) = uint256_eq(assetFundbalance_, Uint256(0,0))
    if isAssetFundBalanceNul_ == 1:
        return _calc_amount_of_each_asset(totalValue, asset_len - 1, asset + 1, assetAmount_len, assetAmount, denomination_asset)
    else:
        let (assetvalueInDeno_: Uint256) = get_asset_value(asset[0], assetFundbalance_, denomination_asset)
        let (isAssetFundBalanceEnought: felt) = uint256_le(totalValue, assetvalueInDeno_)
        if isAssetFundBalanceEnought == 1:
            let (requiredAmount: Uint256) = get_asset_value(denomination_asset, totalValue, asset[0])
            assert assetAmount[assetAmount_len] = requiredAmount
            return(Uint256(0,0), assetAmount_len + 1)
        else:
            let (remainingAmount_:Uint256) = SafeUint256.sub_le(totalValue, assetvalueInDeno_)
            assert assetAmount[assetAmount_len] = assetFundbalance_
            return _calc_amount_of_each_asset(remainingAmount_, asset_len - 1, asset + 1, assetAmount_len + 1, assetAmount, denomination_asset)
        end
    end
end

func _calc_amount_of_each_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    totalValue : Uint256, share_len : felt, share : ShareWithdraw*, shareAmount_len : felt, shareAmount : Uint256*, denomination_asset: felt) -> (remainingValue:Uint256, len : felt):
    alloc_locals
    if share_len == 0:
        return (totalValue, shareAmount_len)
    end
    let (shareFundbalance_: Uint256) = get_share_balance(share[0].address, share[0].id)
    let (isShareFundBalanceNul_ : felt) = uint256_eq(shareFundbalance_, Uint256(0,0))
    if isShareFundBalanceNul_ == 1:
        return _calc_amount_of_each_share(totalValue, share_len - 1, share + ShareWithdraw.SIZE, shareAmount_len, shareAmount, denomination_asset)
    else:
        let (sharevalueInDeno_: Uint256) = getShareValue(share[0].address, share[0].id,shareFundbalance_, denomination_asset)
        let (isShareFundBalanceEnought: felt) = uint256_le(totalValue, sharevalueInDeno_)
        if isShareFundBalanceEnought == 1:
            let (oneSharevalueInDeno_: Uint256) = getShareValue(share[0].address, share[0].id,Uint256(POW18,0), denomination_asset)
            let (totalValuePow_:Uint256,_) = uint256_mul(totalValue, Uint256(POW18,0))
            let (requiredAmount: Uint256) = uint256_div(totalValuePow_, oneSharevalueInDeno_)
            assert shareAmount[shareAmount_len] = requiredAmount
            return(Uint256(0,0), shareAmount_len + 1)
        else:
            let (remainingAmount_:Uint256) = SafeUint256.sub_le(totalValue, sharevalueInDeno_)
            assert shareAmount[shareAmount_len] = shareFundbalance_
            return _calc_amount_of_each_share(remainingAmount_, share_len - 1, share + ShareWithdraw.SIZE, shareAmount_len + 1, shareAmount, denomination_asset)
        end
    end
end


func _transfer_each_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    fund : felt, caller : felt, manager : felt, stackingVault : felt, daoTreasury : felt, assets_len : felt, assets : felt*, callerAmount : Uint256*, managerAmount : Uint256*, stackingVaultAmount : Uint256*, daoTreasuryAmount : Uint256*
):
    alloc_locals
    if assets_len == 0:
        return ()
    end

    let asset = assets[0]    
    let callerAmount_ = [callerAmount]
    let managerAmount_ = [managerAmount]
    let stackingVaultAmount_ = [stackingVaultAmount]
    let daoTreasuryAmount_ = [daoTreasuryAmount]

    _withdraw_asset_to(asset, caller, callerAmount_)
    _withdraw_asset_to(asset, manager, managerAmount_)
    _withdraw_asset_to(asset, stackingVault, stackingVaultAmount_)
    _withdraw_asset_to(asset, daoTreasury, daoTreasuryAmount_)

    return _transfer_each_asset(fund, caller, manager, stackingVault, daoTreasury, assets_len - 1, assets + 1, callerAmount + Uint256.SIZE, managerAmount + Uint256.SIZE, stackingVaultAmount + Uint256.SIZE, daoTreasuryAmount + Uint256.SIZE)
end

func _transfer_each_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    fund : felt, caller : felt, manager : felt, stackingVault : felt, daoTreasury : felt, shares_len : felt, shares: ShareWithdraw*, callerAmount : Uint256*, managerAmount : Uint256*, stackingVaultAmount : Uint256*, daoTreasuryAmount : Uint256*
):
    alloc_locals
    if shares_len == 0:
        return ()
    end

    let shareAddress = shares[0].address
    let shareId = shares[0].id
    let callerAmount_ = callerAmount[0]
    let managerAmount_ = managerAmount[0]
    let stackingVaultAmount_ = stackingVaultAmount[0]
    let daoTreasuryAmount_ = daoTreasuryAmount[0]
    let (local data : felt*) = alloc()

    _withdraw_share_to(fund, caller, shareAddress, shareId, callerAmount_)
    _withdraw_share_to(fund, manager, shareAddress, shareId, managerAmount_)
    _withdraw_share_to(fund, stackingVault, shareAddress, shareId, stackingVaultAmount_)
    _withdraw_share_to(fund, daoTreasury, shareAddress, shareId, daoTreasuryAmount_)

    return _transfer_each_share(fund, caller, manager, stackingVault, daoTreasury, shares_len - 1, shares + ShareWithdraw.SIZE, callerAmount + Uint256.SIZE, managerAmount + Uint256.SIZE, stackingVaultAmount + Uint256.SIZE, daoTreasuryAmount + Uint256.SIZE)
end


func __calcul_gav_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    assets_len : felt, assets : AssetInfo*
) -> (gav : Uint256):
    #Tracked assets GAV 
    alloc_locals
    if assets_len == 0:
        return (gav=Uint256(0, 0))
    end
    let asset_value:Uint256 = assets[assets_len - 1].valueInDeno
    let (gavOfRest) = __calcul_gav_asset(assets_len=assets_len - 1, assets=assets)
    let (gav, _) = uint256_add(asset_value, gavOfRest)
    return (gav=gav)
end

func __calcul_gav_share{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    shares_len : felt, shares : ShareInfo*
) -> (gav : Uint256):
    #Tracked assets GAV 
    alloc_locals
    if shares_len == 0:
        return (gav=Uint256(0, 0))
    end
    let share_value:Uint256 = shares[shares_len - 1].valueInDeno
    let (gavOfRest) = __calcul_gav_share(shares_len=shares_len - 1, shares=shares)
    let (gav, _) = uint256_add(share_value, gavOfRest)
    return (gav=gav)
end

func __calcul_gav_position{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    externalPositions_len : felt, externalPositions : PositionInfo*
) -> (gav : Uint256):
    #External position GAV 
    alloc_locals
    if externalPositions_len == 0:
        return (gav=Uint256(0, 0))
    end
    let asset_value:Uint256 = externalPositions[externalPositions_len - 1 ].valueInDeno
    let (gavOfRest) = __calcul_gav_position(externalPositions_len=externalPositions_len - 1, externalPositions=externalPositions)
    let (gav, _) = uint256_add(asset_value, gavOfRest)
    return (gav=gav)
end




func _get_dao_treasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vault_factory_:felt) = vault_factory.read()
    let (treasury_:felt) = IVaultFactory.getDaoTreasury(vault_factory_)
    return (res=treasury_)
end

func _get_stacking_vault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vault_factory_:felt) = vault_factory.read()
    let (stackingVault_:felt) = IVaultFactory.getStackingVault(vault_factory_)
    return (res=stackingVault_)
end

func _get_dao_treasury_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vault_factory_:felt) = vault_factory.read()
    let (treasury_:felt) = IVaultFactory.getDaoTreasuryFee(vault_factory_)
    return (res=treasury_)
end

func _get_stacking_vault_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vault_factory_:felt) = vault_factory.read()
    let (stackingVault_:felt) = IVaultFactory.getStackingVaultFee(vault_factory_)
    return (res=stackingVault_)
end

func _get_fee_manager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vault_factory_:felt) = vault_factory.read()
    let (feeManager_:felt) = IVaultFactory.getFeeManager(vault_factory_)
    return (res=feeManager_)
end

func _get_policy_manager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vault_factory_:felt) = vault_factory.read()
    let (policyManager_:felt) = IVaultFactory.getPolicyManager(vault_factory_)
    return (res=policyManager_)
end

func _get_integration_manager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vault_factory_:felt) = vault_factory.read()
    let (integrationManager_:felt) = IVaultFactory.getIntegrationManager(vault_factory_)
    return (res=integrationManager_)
end

func _get_value_interpretor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vault_factory_:felt) = vault_factory.read()
    let (valueInterpretor_:felt) = IVaultFactory.getValueInterpretor(vault_factory_)
    return (res=valueInterpretor_)
end



# func _assert_max_min_range{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     _amount : Uint256):
#     alloc_locals
#     let (policyManager_) = _get_policy_manager()
#     let (fund_:felt) = get_contract_address()
#     let (max:Uint256, min:Uint256) = IPolicyManager.getMaxminAmount(policyManager_, fund_)
#     let (le_max) = uint256_le(_amount, max)
#     let (be_min) = uint256_le(min, _amount)
#     with_attr error_message("_assert_max_min_range: amount is too high"):
#         assert le_max = 1
#     end
#     with_attr error_message("_assert_max_min_range: amount is too low"):
#         assert be_min = 1
#     end
#     return ()
# end

func _assert_allowed_depositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    caller : felt):
    alloc_locals
    let (manager_) = manager_account.read()
    if manager_ == caller:
        return()
    end
    let (policyManager_) = _get_policy_manager()
    let (fund_:felt) = get_contract_address()
    let (isPublic_:felt) = IPolicyManager.isPublic(policyManager_, fund_)
    if isPublic_ == 1:
        return()
    else:
        let (isAllowedDepositor_:felt) = IPolicyManager.isAllowedDepositor(policyManager_, fund_, caller)
        with_attr error_message("_assert_allowed_depositor: not allowed depositor"):
        assert isAllowedDepositor_ = 1
        end
    end
    return ()
end

#helper to make sure the sum is 100%
func _calcul_tab_100{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _percents_len : felt, _percents : felt*) -> (res:felt):
    alloc_locals
    if _percents_len == 0:
        return (0)
    end
    let newPercents_len:felt = _percents_len - 1
    let newPercents:felt* = _percents + 1
    let (_previousElem:felt) = _calcul_tab_100(newPercents_len, newPercents)
    let res:felt = [_percents] + _previousElem
    return (res=res)
end


func _assert_enought_guarantee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
   let (shareSupply_) = shares_total_supply.read()
   let (contractAddress_ : felt) = get_contract_address()
   let (manager_) = get_manager_account()
   let (vault_factory_) = vault_factory.read()
   let (stackingDispute_) = IVaultFactory.getStackingDispute(vault_factory_)
   let (securityFundBalance_)  = IStackingDispute.getSecurityFundBalance(stackingDispute_, contractAddress_)
   let (guaranteeRatio_) = IVaultFactory.getManagerGuaranteeRatio(vault_factory_, manager_)
   let (minGuarantee_) =  uint256_percent(shareSupply_, Uint256(guaranteeRatio_,0))
   let (isEnoughtGuarantee_) = uint256_le(minGuarantee_, securityFundBalance_)
   with_attr error_message("_assert_enought_guarantee: Asser manager need to provide more guarantee "):
        assert_not_zero(isEnoughtGuarantee_)
    end
   return()
end

func _withdraw_asset_to{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        _asset: felt,
        _target:felt,
        _amount:Uint256,
    ):
    let (_success) = IERC20.transfer(contract_address = _asset,recipient = _target,amount = _amount)
    with_attr error_message("_withdraw_asset_to: transfer didn't work"):
        assert_not_zero(_success)
    end
    return ()
end

func _withdraw_share_to{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        _fund: felt,
        _target:felt,
        _share: felt,
        _id:Uint256,
        _amount:Uint256,
    ):
    IFuccount.safeTransferFrom(_share, _fund, _target, _id, _amount)
    return ()
end

func _reedem_tab{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    len : felt, amount : Uint256*, performancePermillion : Uint256, durationPermillion : felt, fund : felt,
    tabLen : felt, callerAmount : Uint256*, managerAmount : Uint256*, stackingVaultAmount : Uint256*, daoTreasuryAmount : Uint256*
) -> ():
    alloc_locals
    if len == 0:
        return ()
    end

    let amount_ : Uint256 = amount[0]

    #PERFORMANCE FEES
    let (millionTimePerf:Uint256) = uint256_mul_low(amount_, performancePermillion)
    let (performanceAmount_ : Uint256) = uint256_div(millionTimePerf, Uint256(PRECISION,0))
    let (fee0, feeAssetManager0, feeDaoTreasury0, feeStackingVault0) = _get_fee(fund, FeeConfig.PERFORMANCE_FEE, performanceAmount_)

    let (remainingAmount0_ : Uint256) = uint256_sub(amount_, fee0)

    #MANAGEMENT FEES
    let (millionTimeDuration_:Uint256) = uint256_mul_low(amount_, Uint256(durationPermillion,0))
    let (managementAmount_ : Uint256) = uint256_div(millionTimeDuration_, Uint256(PRECISION,0))
    let (fee1, feeAssetManager1, feeDaoTreasury1, feeStackingVault1) = _get_fee(fund, FeeConfig.MANAGEMENT_FEE, managementAmount_)

    let (remainingAmount1_ : Uint256) = uint256_sub(remainingAmount0_, fee1)
    let (cumulativeFeeAssetManager1 : Uint256,_) = uint256_add(feeAssetManager0, feeAssetManager1)
    let (cumulativeFeeStackingVault1 : Uint256,_) = uint256_add(feeStackingVault0, feeStackingVault1)
    let (cumulativeFeeDaoTreasury1 : Uint256,_) = uint256_add(feeDaoTreasury0, feeDaoTreasury1)

    #EXIT FEES
    let (fee2, feeAssetManager2, feeDaoTreasury2, feeStackingVault2) = _get_fee(fund, FeeConfig.EXIT_FEE, amount_)
    let (remainingAmount2_ : Uint256) = uint256_sub(remainingAmount1_, fee2)
    let (cumulativeFeeAssetManager2 : Uint256,_) = uint256_add(cumulativeFeeAssetManager1, feeAssetManager2)
    let (cumulativeFeeStackingVault2 : Uint256,_) = uint256_add(cumulativeFeeStackingVault1, feeStackingVault2)
    let (cumulativeFeeDaoTreasury2 : Uint256,_) = uint256_add(cumulativeFeeDaoTreasury1, feeDaoTreasury2)

    assert callerAmount[tabLen] = remainingAmount2_
    assert managerAmount[tabLen] = cumulativeFeeAssetManager2
    assert stackingVaultAmount[tabLen] = cumulativeFeeStackingVault2
    assert daoTreasuryAmount[tabLen] = cumulativeFeeDaoTreasury2

    return _reedem_tab(len - 1, amount + Uint256.SIZE, performancePermillion, durationPermillion, fund, tabLen + 1, callerAmount, managerAmount, stackingVaultAmount, daoTreasuryAmount)
end


func _complete_non_nul_asset_tab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(availableAssets_len:felt, availableAssets:felt*, notNulAssets_len:felt, notNulAssets:AssetInfo*) -> (notNulAssets_len:felt):
    alloc_locals
    if availableAssets_len == 0:
        return (notNulAssets_len)
    end
    let newAvailableAssets_len = availableAssets_len - 1
    let assetIndex_:felt = availableAssets[newAvailableAssets_len] 
    let (assetBalance_:Uint256) = get_asset_balance(assetIndex_)
    let (isZero_:felt) = _is_zero(assetBalance_.low)
    if isZero_ == 0:
        assert notNulAssets[notNulAssets_len].address = assetIndex_
        assert notNulAssets[notNulAssets_len].amount = assetBalance_
        let (denomination_asset_:felt) = denomination_asset.read()
        let (assetValue:Uint256) = get_asset_value(assetIndex_, assetBalance_, denomination_asset_)
        assert notNulAssets[notNulAssets_len].valueInDeno = assetValue
        let newNotNulAssets_len = notNulAssets_len + 1
         return _complete_non_nul_asset_tab(
        availableAssets_len=newAvailableAssets_len,
        availableAssets= availableAssets,
        notNulAssets_len=newNotNulAssets_len,
        notNulAssets=notNulAssets,
        )
    end

    return _complete_non_nul_asset_tab(
        availableAssets_len=newAvailableAssets_len,
        availableAssets= availableAssets,
        notNulAssets_len=notNulAssets_len,
        notNulAssets=notNulAssets,
        )
end


    func _complete_non_nul_shares_tab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(availableAShares_len:felt, availableShares:felt*, notNulShares_len:felt, notNulShares:ShareInfo*, selfAddress:felt, denomination_asset:felt) -> (notNulShares_len:felt):
    alloc_locals
    if availableAShares_len == 0:
        return (notNulShares_len)
    end
    let fundAddress_:felt = availableShares[availableAShares_len - 1] 
    let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = IFuccount.ownerShares(fundAddress_, selfAddress)
    if assetId_len == 0:
        return _complete_non_nul_shares_tab(
            availableAShares_len=availableAShares_len - 1,
            availableShares= availableShares,
            notNulShares_len=notNulShares_len,
            notNulShares=notNulShares,
            selfAddress=selfAddress,
            denomination_asset= denomination_asset,
            )
    end

    let (newTabLen) = _complete_share_info(assetId_len, selfAddress, assetId, assetAmount, 0, notNulShares + notNulShares_len, denomination_asset)
    return _complete_non_nul_shares_tab(
        availableAShares_len=availableAShares_len - 1,
        availableShares= availableShares,
        notNulShares_len= newTabLen ,
        notNulShares=notNulShares,
        selfAddress=selfAddress,
        denomination_asset= denomination_asset,
        )
end

func _complete_share_info{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(len:felt, fundAddress:felt, assetId:Uint256*, assetAmount:Uint256*, shareInfo_len:felt,shareInfo : ShareInfo*, denomination_asset_:felt) -> (shareInfo_len: felt):
    alloc_locals
    if len == 0:
        return (shareInfo_len)
    end
    assert shareInfo[shareInfo_len].address = fundAddress
    assert shareInfo[shareInfo_len].id = assetId[len -1]
    assert shareInfo[shareInfo_len].amount = assetAmount[len - 1]
    let (valueInDeno_) = getShareValue(fundAddress, assetId[shareInfo_len -1], assetAmount[shareInfo_len - 1], denomination_asset_)
    assert shareInfo[shareInfo_len].valueInDeno = valueInDeno_
    return _complete_share_info(
        len=len -1,
        fundAddress= fundAddress,
        assetId=assetId,
        assetAmount=assetAmount,
        shareInfo_len=shareInfo_len + 1,
        shareInfo=shareInfo,
        denomination_asset_=denomination_asset_,
        )
end


    func _complete_non_nul_position_tab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(availableExternalPositions_len:felt, availableExternalPositions:felt*, notNulExternalPositions_len:felt, notNulExternalPositions:PositionInfo*) -> (notNulExternalPositions_len:felt):
    alloc_locals
    if availableExternalPositions_len == 0:
        return (notNulExternalPositions_len)
    end
    let newAvailableExternalPositions_len = availableExternalPositions_len - 1
    let externalPositionIndex_:felt = availableExternalPositions[newAvailableExternalPositions_len] 
    let (denomination_asset_:felt) = denomination_asset.read()
    let (contractAddress_:felt) = get_contract_address()
    let (VI_:felt) = _get_value_interpretor()
    let (value_:Uint256) = IValueInterpretor.calculAssetValue(VI_, externalPositionIndex_, Uint256(contractAddress_, 0), denomination_asset_)
    let (isZero_:felt) = _is_zero(value_.low)
    if isZero_ == 0:
        assert notNulExternalPositions[notNulExternalPositions_len].address = externalPositionIndex_
        assert notNulExternalPositions[notNulExternalPositions_len].valueInDeno = value_
        let newNotNulExternalPositions_len = notNulExternalPositions_len +1
         return _complete_non_nul_position_tab(
        availableExternalPositions_len=newAvailableExternalPositions_len,
        availableExternalPositions= availableExternalPositions,
        notNulExternalPositions_len=newNotNulExternalPositions_len,
        notNulExternalPositions=notNulExternalPositions,
        )
    end
         return _complete_non_nul_position_tab(
        availableExternalPositions_len=newAvailableExternalPositions_len,
        availableExternalPositions= availableExternalPositions,
        notNulExternalPositions_len=notNulExternalPositions_len,
        notNulExternalPositions=notNulExternalPositions,
        )
end


    func _complete_multi_share_tab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(total_id:Uint256, assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*, account:felt) -> (tabSize:felt):
    alloc_locals
    if total_id.low == 0:
        return (tabSize=assetId_len)
    end
    let (newtotal_id_) =  uint256_sub( total_id, Uint256(1,0))
    let (balance_) = balance_of(account, newtotal_id_)
    let (isZero_) = _is_zero(balance_.low)
    if isZero_ == 0:
        # assert assetId[assetId_len*Uint256.SIZE] = newtotal_id_
        # assert assetAmount[assetId_len*Uint256.SIZE] = balance_
        assert assetId[assetId_len] = newtotal_id_
        assert assetAmount[assetId_len] = balance_
         return _complete_multi_share_tab(
        total_id= newtotal_id_,
        assetId_len=assetId_len+1,
        assetId= assetId ,
        assetAmount_len=assetAmount_len+1,
        assetAmount=assetAmount ,
        account=account,
        )
    end
    return _complete_multi_share_tab(
        total_id=newtotal_id_,
        assetId_len= assetId_len,
        assetId=assetId,
        assetAmount_len=assetAmount_len,
        assetAmount=assetAmount,
        account=account,
        )
end


func reduce_supply_batch{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        amounts_len: felt,
        amounts: Uint256*
    ):

        if amounts_len == 0 :
    return()
end
    let (currentTotalSupply_) = shares_total_supply.read()
    let (newTotalSupply_) = uint256_sub(currentTotalSupply_, amounts[amounts_len* Uint256.SIZE - Uint256.SIZE] )
    shares_total_supply.write(newTotalSupply_)    
    return reduce_supply_batch(
        amounts_len= amounts_len - 1,
        amounts=amounts)
end


    func _is_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(x : felt) -> (
    res : felt
):
    if x == 0:
        return (res=1)
    end
    return (res=0)
end


    func _safe_transfer_from{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            from_: felt,
            to: felt,
            id: Uint256,
            amount: Uint256,
        ):
        alloc_locals
        # Check args
        with_attr error_message("ERC1155: transfer to the zero address"):
            assert_not_zero(to)
        end
        with_attr error_message("ERC1155: id is not a valid Uint256"):
            uint256_check(id)
        end
        with_attr error_message("ERC1155: amount is not a valid Uint256"):
            uint256_check(amount)
        end

        # Deduct from sender
        let (from_balance: Uint256) = ERC1155_balances.read(id, from_)
        with_attr error_message("ERC1155: insufficient balance for transfer"):
            let (new_balance: Uint256) = SafeUint256.sub_le(from_balance, amount)
        end
        ERC1155_balances.write(id, from_, new_balance)

        # Add to receiver
        let (to_balance: Uint256) = ERC1155_balances.read(id, to)
        with_attr error_message("ERC1155: balance overflow"):
            let (new_balance: Uint256) = SafeUint256.add(to_balance, amount)
        end
        ERC1155_balances.write(id, to, new_balance)

        # Emit events and check
        let (operator) = get_caller_address()
        transfer_single.emit(
            operator,
            from_,
            to,
            id,
            amount
        )
        return ()
    end

    func _safe_batch_transfer_from{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            from_: felt,
            to: felt,
            ids_len: felt,
            ids: Uint256*,
            amounts_len: felt,
            amounts: Uint256*,
        ):
        alloc_locals
        # Check args
        with_attr error_message("ERC1155: transfer to the zero address"):
            assert_not_zero(to)
        end
        with_attr error_message("ERC1155: ids and amounts length mismatch"):
            assert ids_len = amounts_len
        end
        # Recursive call
        let len = ids_len
        safe_batch_transfer_from_iter(from_, to, len, ids, amounts)

        # Emit events and check
        let (operator) = get_caller_address()
        transfer_batch.emit(
            operator,
            from_,
            to,
            ids_len,
            ids,
            amounts_len,
            amounts
        )
        return ()
    end

    func _mint{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            to: felt,
            id: Uint256,
            amount: Uint256,
        ):
        # Cannot mint to zero address
        with_attr error_message("ERC1155: mint to the zero address"):
            assert_not_zero(to)
        end
        # Check uints valid
        with_attr error_message("ERC1155: id is not a valid Uint256"):
            uint256_check(id)
        end
        with_attr error_message("ERC1155: amount is not a valid Uint256"):
            uint256_check(amount)
        end

        # add to minter, check for overflow
        let (to_balance: Uint256) = ERC1155_balances.read(id, to)
        with_attr error_message("ERC1155: balance overflow"):
            let (new_balance: Uint256) = SafeUint256.add(to_balance, amount)
        end
        ERC1155_balances.write(id, to, new_balance)

        # Emit events and check
        let (operator) = get_caller_address()
        transfer_single.emit(
            operator=operator,
            from_=0,
            to=to,
            id=id,
            value=amount
        )
        return ()
    end

    func _mint_batch{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            to: felt,
            ids_len: felt,
            ids: Uint256*,
            amounts_len: felt,
            amounts: Uint256*,
        ):
        alloc_locals
        # Cannot mint to zero address
        with_attr error_message("ERC1155: mint to the zero address"):
            assert_not_zero(to)
        end
        # Check args are equal length arrays
        with_attr error_message("ERC1155: ids and amounts length mismatch"):
            assert ids_len = amounts_len
        end

        # Recursive call
        let len = ids_len
        mint_batch_iter(to, len, ids, amounts)

        # Emit events and check
        let (operator) = get_caller_address()
        transfer_batch.emit(
            operator=operator,
            from_=0,
            to=to,
            ids_len=ids_len,
            ids=ids,
            values_len=amounts_len,
            values=amounts,
        )
        return ()
    end

    func _burn{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(from_: felt, id: Uint256, amount: Uint256):
        alloc_locals
        with_attr error_message("ERC1155: burn from the zero address"):
            assert_not_zero(from_)
        end

        # Check uints valid
        with_attr error_message("ERC1155: id is not a valid Uint256"):
            uint256_check(id)
        end
        with_attr error_message("ERC1155: amount is not a valid Uint256"):
            uint256_check(amount)
        end

        # Deduct from burner
        let (from_balance: Uint256) = ERC1155_balances.read(id, from_)
        with_attr error_message("ERC1155: burn amount exceeds balance"):
            let (new_balance: Uint256) = SafeUint256.sub_le(from_balance, amount)
        end
        ERC1155_balances.write(id, from_, new_balance)

        let (operator) = get_caller_address()
        transfer_single.emit(operator=operator, from_=from_, to=0, id=id, value=amount)
        return ()
    end

    func _burn_batch{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            from_: felt,
            ids_len: felt,
            ids: Uint256*,
            amounts_len: felt,
            amounts: Uint256*
        ):
        alloc_locals
        with_attr error_message("ERC1155: burn from the zero address"):
            assert_not_zero(from_)
        end
        with_attr error_message("ERC1155: ids and amounts length mismatch"):
            assert ids_len = amounts_len
        end

        # Recursive call
        let len = ids_len
        burn_batch_iter(from_, len, ids, amounts)
        let (operator) = get_caller_address()
        transfer_batch.emit(
            operator=operator,
            from_=from_,
            to=0,
            ids_len=ids_len,
            ids=ids,
            values_len=amounts_len,
            values=amounts
        )
        return ()
    end

    func _set_approval_for_all{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(owner: felt, operator: felt, approved: felt):
        # check approved is bool
        assert approved * (approved - 1) = 0
        # caller/owner already checked  non-0
        with_attr error_message("ERC1155: setting approval status for zero address"):
            assert_not_zero(operator)
        end
        with_attr error_message("ERC1155: setting approval status for self"):
            assert_not_equal(owner, operator)
        end
        ERC1155_operator_approvals.write(owner, operator, approved)
        approval_for_all.emit(owner, operator, approved)
        return ()
    end


    func assert_owner_or_approved{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(owner):
        let (caller) = get_caller_address()
        if caller == owner:
            return ()
        end
        let (approved) = is_approved_for_all(owner, caller)
        with_attr error_message("ERC1155: caller is not owner nor approved"):
            assert approved = TRUE
        end
        return ()
    end



#
# Private
#





#
# Helpers
#

func balance_of_batch_iter{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        len: felt,
        accounts: felt*,
        ids: Uint256*,
        batch_balances: Uint256*
    ):
    if len == 0:
        return ()
    end
    # Read current entries
    let id: Uint256 = [ids]
    with_attr error_message("ERC1155: id is not a valid Uint256"):
        uint256_check(id)
    end
    let account: felt = [accounts]

    # Get balance
    let (balance: Uint256) = balance_of(account, id)
    assert [batch_balances] = balance
    return balance_of_batch_iter(
        len - 1, accounts + 1, ids + Uint256.SIZE, batch_balances + Uint256.SIZE
    )
end

func safe_batch_transfer_from_iter{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        from_: felt,
        to: felt,
        len: felt,
        ids: Uint256*,
        amounts: Uint256*
    ):
    # Base case
    alloc_locals
    if len == 0:
        return ()
    end

    # Read current entries,  perform Uint256 checks
    let id = [ids]
    with_attr error_message("ERC1155: id is not a valid Uint256"):
        uint256_check(id)
    end
    let amount = [amounts]
    with_attr error_message("ERC1155: amount is not a valid Uint256"):
        uint256_check(amount)
    end

    # deduct from sender
    let (from_balance: Uint256) = ERC1155_balances.read(id, from_)
    with_attr error_message("ERC1155: insufficient balance for transfer"):
        let (new_balance: Uint256) = SafeUint256.sub_le(from_balance, amount)
    end
    ERC1155_balances.write(id, from_, new_balance)

    # add to
    let (to_balance: Uint256) = ERC1155_balances.read(id, to)
    with_attr error_message("ERC1155: balance overflow"):
        let (new_balance: Uint256) = SafeUint256.add(to_balance, amount)
    end
    ERC1155_balances.write(id, to, new_balance)

    # Recursive call
    return safe_batch_transfer_from_iter(
        from_, to, len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE
    )
end

func mint_batch_iter{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        to: felt,
        len: felt,
        ids: Uint256*,
        amounts: Uint256*
    ):
    # Base case
    alloc_locals
    if len == 0:
        return ()
    end

    # Read current entries
    let id: Uint256 = [ids]
    with_attr error_message("ERC1155: id is not a valid Uint256"):
        uint256_check(id)
    end
    let amount: Uint256 = [amounts]
    with_attr error_message("ERC1155: amount is not a valid Uint256"):
        uint256_check(amount)
    end

    # add to
    let (to_balance: Uint256) = ERC1155_balances.read(id, to)
    with_attr error_message("ERC1155: balance overflow"):
        let (new_balance: Uint256) = SafeUint256.add(to_balance, amount)
    end
    ERC1155_balances.write(id, to, new_balance)

    # Recursive call
    return mint_batch_iter(to, len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE)
end

func burn_batch_iter{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        from_: felt,
        len: felt,
        ids: Uint256*,
        amounts: Uint256*
    ):
    # Base case
    alloc_locals
    if len == 0:
        return ()
    end

    # Read current entries
    let id: Uint256 = [ids]
    with_attr error_message("ERC1155: id is not a valid Uint256"):
        uint256_check(id)
    end
    let amount: Uint256 = [amounts]
    with_attr error_message("ERC1155: amount is not a valid Uint256"):
        uint256_check(amount)
    end

    # Deduct from burner
    let (from_balance: Uint256) = ERC1155_balances.read(id, from_)
    with_attr error_message("ERC1155: burn amount exceeds balance"):
        let (new_balance: Uint256) = SafeUint256.sub_le(from_balance, amount)
    end
    ERC1155_balances.write(id, from_, new_balance)

    # Recursive call
    return burn_batch_iter(from_, len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE)
end
end
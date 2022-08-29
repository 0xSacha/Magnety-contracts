%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
    get_block_number
)

from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_pow


from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le,
)

from starkware.cairo.common.find_element import (
    find_element,
)


from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)


from contracts.interfaces.IFuccount import IFuccount

from contracts.interfaces.IFeeManager import IFeeManager, FeeConfig

from contracts.interfaces.IPolicyManager import IPolicyManager

from contracts.interfaces.IIntegrationManager import IIntegrationManager

from contracts.interfaces.IOraclePriceFeedMixin import IOraclePriceFeedMixin

from contracts.interfaces.IValueInterpretor import IValueInterpretor

from contracts.interfaces.IERC20 import IERC20

from openzeppelin.access.ownable import Ownable

from openzeppelin.security.safemath import SafeUint256

#
# Events
#

@event
func fee_manager_set(fee_managerAddress: felt):
end

@event
func oracle_set(fee_managerAddress: felt):
end

@event
func fuccount_activated(fuccountAddress: felt):
end

const APPROVE_SELECTOR = 949021990203918389843157787496164629863144228991510976554585288817234167820
const DEPOSIT_SELECTOR = 352040181584456735608515580760888541466059565068553383579463728554843487745
const REEDEM_SELECTOR = 481719463807444873104482035153189208627524278231225222947146558976722465517

const POW18 = 1000000000000000000
const POW20 = 100000000000000000000

struct Integration:
    member contract : felt
    member selector : felt
    member integration: felt
    member level: felt
end
#
# Storage
#
@storage_var
func owner() -> (res: felt):
end

@storage_var
func nominated_owner() -> (res: felt):
end


@storage_var
func oracle() -> (res: felt):
end

@storage_var
func fee_manager() -> (res: felt):
end

@storage_var
func policy_manager() -> (res: felt):
end

@storage_var
func integration_manager() -> (res: felt):
end

@storage_var
func value_interpretor() -> (res: felt):
end

@storage_var
func primitive_price_feed() -> (res: felt):
end

@storage_var
func approve_prelogic() -> (res: felt):
end

@storage_var
func share_price_feed() -> (res : felt):
end

@storage_var
func asset_manager_vault_amount(assetManager: felt) -> (res: felt):
end

@storage_var
func asset_manager_vault(assetManager: felt, vaultId: felt) -> (res: felt):
end

@storage_var
func vault_amount() -> (res: felt):
end

@storage_var
func id_to_vault(id: felt) -> (res: felt):
end

@storage_var
func stacking_vault() -> (res : felt):
end

@storage_var
func dao_treasury() -> (res : felt):
end

@storage_var
func dao_treaury_fee() -> (res : felt):
end

@storage_var
func stacking_vault_fee() -> (res : felt):
end

@storage_var
func max_fund_level() -> (res : felt):
end

@storage_var
func stacking_dispute() -> (res : felt):
end

@storage_var
func guarantee_ratio() -> (res : felt):
end

@storage_var
func exit_timestamp() -> (res : felt):
end

@storage_var
func close_fund_request(fund: felt) -> (res : felt):
end

@storage_var
func isGuarenteeWithdrawable(fund: felt) -> (res : felt):
end


#
# Constructor 
#


@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt):
   Ownable.initializer(owner)
    return ()
end


#
# Modifier 
#

func only_dependencies_set{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (are_dependencies_set_:felt) = areDependenciesSet()
    with_attr error_message("only_dependencies_set:Dependencies not set"):
        assert are_dependencies_set_ = 1
    end
    return ()
end

func only_asset_manager{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(fund:felt):
    let (caller_:felt) = get_caller_address()
    let (assetManager_:felt) = IFuccount.manager(fund)
    with_attr error_message("only_asset_manager: caller is not asset manager"):
        assert caller_ = assetManager_
    end
    return ()
end

#
# Getters 
#

@view
func areDependenciesSet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    alloc_locals
    let (oracle_:felt) = getOracle()
    let (fee_manager_:felt) = getFeeManager()
    let (policy_manager_:felt) = getPolicyManager()
    let (integration_manager_:felt) = getIntegrationManager()
    let (value_interpretor_:felt) = getValueInterpretor()
    let (primitive_price_feed_:felt) = getPrimitivePriceFeed()
    let (approve_prelogic_:felt) = getApprovePrelogic()
    let (max_fund_level_:felt) = getMaxFundLevel()
    let (stacking_dispute_: felt) = getStackingDispute()
    let (guarantee_ratio_: felt) = getGuaranteeRatio()
    let (exit_timestamp_: felt) = getExitTimestamp()
    let  mul_:felt = approve_prelogic_  * oracle_ * fee_manager_ * policy_manager_ * integration_manager_ * value_interpretor_ * primitive_price_feed_ * max_fund_level_ * stacking_dispute_ * exit_timestamp_
    let (isZero_:felt) = is_zero(mul_)
    if isZero_ == 1:
        return (res = 0)
    else:
        return (res = 1)
    end
end

@view
func getOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = Ownable.owner()
    return(res)
end



@view
func getOracle{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = oracle.read()
    return(res)
end


@view
func getFeeManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = fee_manager.read()
    return(res)
end

@view
func getPolicyManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = policy_manager.read()
    return(res)
end

@view
func getIntegrationManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = integration_manager.read()
    return(res)
end

@view
func getValueInterpretor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = value_interpretor.read()
    return(res)
end

@view
func getPrimitivePriceFeed{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = primitive_price_feed.read()
    return(res)
end

@view
func getApprovePrelogic{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = approve_prelogic.read()
    return(res)
end

@view
func getSharePriceFeed{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = share_price_feed.read()
    return(res)
end

@view
func getDaoTreasury{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = dao_treasury.read()
    return(res)
end

@view
func getStackingVault{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = stacking_vault.read()
    return(res)
end

@view
func getStackingVaultFee{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = stacking_vault_fee.read()
    return(res)
end

@view
func getDaoTreasuryFee{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = dao_treaury_fee.read()
    return(res)
end

@view
func getMaxFundLevel{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = max_fund_level.read()
    return(res)
end

@view
func getStackingDispute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let(res:felt) = stacking_dispute.read()
    return (res=res)
end

@view
func getGuaranteeRatio{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let(res:felt) = guarantee_ratio.read()
    return (res=res)
end

@view
func getExitTimestamp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let(res:felt) = exit_timestamp.read()
    return (res=res)
end

@view
func getCloseFundRequest{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fund: felt) -> (res: felt):
    let(closeFundRequest_:felt) = close_fund_request.read(_fund)
    return (res=closeFundRequest_)
end

@view
func getManagerGuaranteeRatio{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fund: felt) -> (res: felt):
    let (baseGuaranteeRatio_) = guarantee_ratio.read()
    ##TODO KYC + soulbound consideration
    return (res=baseGuaranteeRatio_)
end


#
# Setters
#

@external
func transferOwnership{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(new_owner: felt):
    Ownable.transfer_ownership(new_owner)
    return ()
end



@external
func setOrcale{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        oracle_address: felt,
    ):
    Ownable.assert_only_owner()
    oracle.write(oracle_address)
    return ()
end

@external
func setFeeManager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        fee_manager_address: felt,
    ):
    Ownable.assert_only_owner()
    fee_manager.write(fee_manager_address)
    return ()
end


@external
func setPolicyManager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        policy_manager_address: felt,
    ):
    Ownable.assert_only_owner()
    policy_manager.write(policy_manager_address)
    return ()
end

@external
func setIntegrationManager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        integration_manager_address: felt,
    ):
    Ownable.assert_only_owner()
    integration_manager.write(integration_manager_address)
    return ()
end

@external
func setValueInterpretor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        value_interpretor_address : felt):
    Ownable.assert_only_owner()
    value_interpretor.write(value_interpretor_address)
    return ()
end

@external
func setPrimitivePriceFeed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        primitive_price_feed_address : felt):
    Ownable.assert_only_owner()
    primitive_price_feed.write(primitive_price_feed_address)
    return ()
end

@external
func setApprovePrelogic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        approve_prelogic_address : felt):
    Ownable.assert_only_owner()
    approve_prelogic.write(approve_prelogic_address)
    return ()
end

@external
func setSharePriceFeed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        share_price_feed_address : felt):
    Ownable.assert_only_owner()
    share_price_feed.write(share_price_feed_address)
    return ()
end


@external
func setStackingVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        stacking_vault_address : felt):
    Ownable.assert_only_owner()
    stacking_vault.write(stacking_vault_address)
    return ()
end

@external
func setDaoTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        dao_treasury_address : felt):
    Ownable.assert_only_owner()
    dao_treasury.write(dao_treasury_address)
    return ()
end

@external
func setStackingVaultFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        stacking_vault_fee_value : felt):
    Ownable.assert_only_owner()
    stacking_vault_fee.write(stacking_vault_fee_value)
    return ()
end

@external
func setDaoTreasuryFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        dao_treasury_fee_value : felt):
    Ownable.assert_only_owner()
    dao_treaury_fee.write(dao_treasury_fee_value)
    return ()
end

@external
func setMaxFundLevel{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        max_fund_level_value : felt):
    Ownable.assert_only_owner()
    max_fund_level.write(max_fund_level_value)
    return ()
end

@external
func setStackingDispute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        stacking_dispute_address : felt):
    Ownable.assert_only_owner()
    stacking_dispute.write(stacking_dispute_address)
    return ()
end

@external
func SetGuaranteeRatio{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        guarantee_ratio_value : felt):
    Ownable.assert_only_owner()
    guarantee_ratio.write(guarantee_ratio_value)
    return ()
end

@external
func setExitTimestamp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        exit_timestamp_value : felt):
    Ownable.assert_only_owner()
    exit_timestamp.write(exit_timestamp_value)
    return ()
end



@external
func addGlobalAllowedAssets{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(assets_len:felt, assets:felt*) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    only_dependencies_set()
    let (integration_manager_:felt) = integration_manager.read()
    add_global_allowed_assets_from_tab(assets_len, assets, integration_manager_)
    return ()
end

@external
func addGlobalAllowedExternalPositions{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(external_positions_len:felt, external_positions:felt*) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    only_dependencies_set()
    let (integration_manager_:felt) = integration_manager.read()
    add_global_allowed_external_positions_from_tab(external_positions_len, external_positions, integration_manager_)
    return ()
end

@external
func addGlobalAllowedIntegrations{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(integrations_len:felt, integrations:Integration*) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    only_dependencies_set()
    let (integration_manager_:felt) = integration_manager.read()
    add_global_allowed_integration_from_tab(integrations_len, integrations, integration_manager_)
    return()
end

#asset manager

@external
func addAllowedDepositors{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(fund:felt, depositors_len:felt, depositors:felt*) -> ():
    alloc_locals
    only_asset_manager(fund)
    let (policy_manager_:felt) = policy_manager.read()
    let (is_public_:felt) = IPolicyManager.isPublic(policy_manager_, fund)
    with_attr error_message("add_allowed_depositors: the fund is already public"):
        assert is_public_ = 0
    end
   add_allowed_depositors_from_tab(fund, depositors_len, depositors)
    return ()
end


@external
func initializeFund{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
    #vault initializer
    fund: felt,
    level: felt,
    name:felt,
    symbol:felt,
    denomination_asset:felt,
    amount: Uint256,
    shares_amount: Uint256,
    fee_config_len: felt,
    fee_config: felt*,
    is_public:felt,
    ):
    alloc_locals
    only_dependencies_set()
    let (fee_manager_:felt) = fee_manager.read()
    let (policy_manager_:felt) = policy_manager.read()
    let (integration_manager_:felt) = integration_manager.read()
    let (value_interpretor_:felt) = value_interpretor.read()
    let (primitive_price_feed_:felt) = primitive_price_feed.read()
    let (name_:felt) = IFuccount.name(fund)

    with_attr error_message("initialize_fund: vault already initialized"):
        assert name_ = 0
    end

    with_attr error_message("initialize_fund: can not set value to 0"):
        assert_not_zero(fund * name * symbol * denomination_asset * level)
    end

    let (is_available_denomination_asset:felt) = IIntegrationManager.isAvailableAsset(integration_manager_, denomination_asset)
    with_attr error_message("initialize_fund: can not set value to 0"):
        assert is_available_denomination_asset = 1
    end

    let (manager_: felt) = get_caller_address()

    #check allowed amount, min amount > decimal/1000 & share amount in [1, 100]
    let (decimals_:felt) = IERC20.decimals(denomination_asset)
    let (minimum_initial_amount_:Uint256) = uint256_pow(Uint256(10,0), decimals_ - 3)
    let (allowed_asset_amount:felt) = uint256_le(minimum_initial_amount_, amount) 
    let (allowed_shares_amount_1_:felt) = uint256_le(shares_amount, Uint256(POW20,0))
    let (allowed_shares_amount_2_:felt) = uint256_le(Uint256(POW18,0), shares_amount)
    with_attr error_message("initialize_fund: not allowed Amount"):
        assert allowed_asset_amount *  allowed_shares_amount_1_ * allowed_shares_amount_2_ = 1
    end
    
    # add integration so other funds can buy/sell shares from it
    let (integrations:Integration*) = alloc()
    assert integrations[0] = Integration(fund, DEPOSIT_SELECTOR, 0, level)
    assert integrations[1] = Integration(fund, REEDEM_SELECTOR, 0, level)
    add_global_allowed_integration_from_tab(2, integrations, integration_manager_)
     
    ## Add share derivative pricefeed for the new fund created
    let (share_price_feed_:felt) = getSharePriceFeed()
    IValueInterpretor.addDerivative(value_interpretor_, fund, share_price_feed_)


    # Activate the fund and transfer asset to the fund
    let (share_amount_pow18_ :Uint256) = SafeUint256.mul(amount, Uint256(POW18,0))
    let (share_price_purchased_ :Uint256,_) = SafeUint256.div_rem(share_amount_pow18_ , shares_amount)
    IFuccount.activater(fund, name, symbol, level, denomination_asset, manager_, shares_amount, share_price_purchased_)
    IERC20.transferFrom(denomination_asset, manager_, fund, amount)

    #Set feeconfig for vault
    let entrance_fee = fee_config[0]
    with_attr error_message("initialize_fund: entrance fee must be between 0 and 10"):
            assert_le(entrance_fee, 10)
    end
    IFeeManager.setFeeConfig(fee_manager_, fund, FeeConfig.ENTRANCE_FEE, entrance_fee)
    

    let exit_fee = fee_config[1]
    with_attr error_message("initialize_fund: exit fee must be between 0 and 10"):
        assert_le(exit_fee, 10)
    end
    IFeeManager.setFeeConfig(fee_manager_, fund, FeeConfig.EXIT_FEE, exit_fee)

    let performance_fee = fee_config[2]
    with_attr error_message("initialize_fund: performance fee must be between 0 and 20"):
        assert_le(performance_fee, 20)
    end
    IFeeManager.setFeeConfig(fee_manager_, fund, FeeConfig.PERFORMANCE_FEE, performance_fee)
    
    let management_fee = fee_config[3]
    with_attr error_message("initialize_fund: management fee must be between 0 and 20"):
        assert_le(management_fee, 60)
    end
    IFeeManager.setFeeConfig(fee_manager_, fund, FeeConfig.MANAGEMENT_FEE, management_fee)

    IPolicyManager.setIsPublic(policy_manager_, fund, is_public)
    return ()
end

@external
func closeFund{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund: felt)-> ():
        only_asset_manager(fund)
        let (notLiquidGav_:Uint256) = IFuccount.notLiquidGav(fund)
        with_attr error_message("request_close_fund: remove your positions first"):
            assert_not_zero(notLiquidGav_.low)
        end
        let (currentTimesTamp_) = get_block_timestamp()
        close_fund_request.write(fund, currentTimesTamp_)
        IFuccount.close(fund)
    return ()
end

func is_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        x: felt)-> (res:felt):
    if x == 0:
        return (res=1)
    end
    return (res=0)
end

func add_global_allowed_assets_from_tab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_assetList_len:felt, _assetList:felt*, _integration_manager:felt) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    if _assetList_len == 0:
        return ()
    end

    let asset_:felt = [_assetList]
    let (VI_:felt) = value_interpretor.read()
    let (PPF_:felt) = primitive_price_feed.read()
    let (isSupportedPrimitiveAsset_) = IOraclePriceFeedMixin.checkIsSupportedPrimitiveAsset(PPF_,asset_)
    let (isSupportedDerivativeAsset_) = IValueInterpretor.isSupportedDerivativeAsset(VI_,asset_)
    let (notAllowed_) = is_zero(isSupportedPrimitiveAsset_ + isSupportedDerivativeAsset_)
    with_attr error_message("only_dependencies_set:Dependencies not set"):
        assert notAllowed_ = 0
    end
    
    let (approve_prelogic_:felt) = getApprovePrelogic()
    IIntegrationManager.setAvailableAsset(_integration_manager, asset_)
    IIntegrationManager.setAvailableIntegration(_integration_manager, asset_, APPROVE_SELECTOR, approve_prelogic_, 1)

    let newAssetList_len:felt = _assetList_len -1
    let newAssetList:felt* = _assetList + 1

    return add_global_allowed_assets_from_tab(
        _assetList_len= newAssetList_len,
        _assetList= newAssetList,
        _integration_manager= _integration_manager
        )
end

func add_global_allowed_external_positions_from_tab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPositionList_len:felt, _externalPositionList:felt*, _integration_manager:felt) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    if _externalPositionList_len == 0:
        return ()
    end
    let externalPosition_:felt = [_externalPositionList]
    let (VI_:felt) = value_interpretor.read()
    let (isSupportedExternalPosition_) = IValueInterpretor.isSupportedExternalPosition(VI_,externalPosition_)
    with_attr error_message("__add_global_allowed_external_position: PriceFeed not set"):
        assert isSupportedExternalPosition_ = 1
    end

    IIntegrationManager.setAvailableExternalPosition(_integration_manager, externalPosition_)
    
    let newExternalPositionList_len:felt = _externalPositionList_len -1
    let newExternalPositionList:felt* = _externalPositionList + 1

    return add_global_allowed_external_positions_from_tab(
        _externalPositionList_len= newExternalPositionList_len,
        _externalPositionList= newExternalPositionList,
        _integration_manager= _integration_manager
        )
end

func add_global_allowed_integration_from_tab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_integrationList_len:felt, _integrationList:Integration*, _integration_manager:felt) -> ():
    alloc_locals
    if _integrationList_len == 0:
        return ()
    end

    let integration_:Integration = [_integrationList]
    IIntegrationManager.setAvailableIntegration(_integration_manager, integration_.contract, integration_.selector, integration_.integration, integration_.level)

    return add_global_allowed_integration_from_tab(
        _integrationList_len= _integrationList_len - 1,
        _integrationList= _integrationList + Integration.SIZE,
        _integration_manager=_integration_manager
        )
end

func add_allowed_depositors_from_tab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_fund:felt, _depositors_len:felt, _depositors:felt*) -> ():
    alloc_locals
    if _depositors_len == 0:
        return ()
    end
    let (policy_manager_:felt) = policy_manager.read()
    let depositor_:felt = [_depositors]
    IPolicyManager.setAllowedDepositor(policy_manager_, _fund, depositor_)

    let newDepositors_len:felt = _depositors_len -1
    let newDepositors:felt* = _depositors + 1

    return add_allowed_depositors_from_tab(
        _fund = _fund,
        _depositors_len= newDepositors_len,
        _depositors= newDepositors,
        )
end

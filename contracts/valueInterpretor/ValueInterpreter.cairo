// Declare this file as a StarkNet contract.
%lang starknet
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)
from contracts.utils.utils import (
    felt_to_uint256,
    uint256_div,
    uint256_percent,
    uint256_mul_low,
    uint256_pow,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.PreLogic.interfaces.IOraclePriceFeedMixin import IOraclePriceFeedMixin
from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IDerivativePriceFeed import IDerivativePriceFeed
from contracts.interfaces.IExternalPositionPriceFeed import IExternalPositionPriceFeed
from contracts.interfaces.IERC20 import IERC20

from starkware.cairo.common.math import assert_not_zero

@storage_var
func vault_factory() -> (vault_factoryAddress: felt) {
}

@storage_var
func eth_address() -> (eth_address: felt) {
}

@storage_var
func derivative_to_price_feed(derivative: felt) -> (res: felt) {
}

@storage_var
func is_supported_derivative_asset(derivative: felt) -> (res: felt) {
}

@storage_var
func external_position_to_price_feed(external_position: felt) -> (res: felt) {
}

@storage_var
func is_supported_external_position(external_position: felt) -> (res: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _vault_factory: felt, _eth_address: felt
) {
    vault_factory.write(_vault_factory);
    eth_address.write(_eth_address);
    return ();
}

func only_authorized{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
    let (vault_factory_) = vault_factory.read();
    let (caller_) = get_caller_address();
    let (owner_) = IVaultFactory.getOwner(vault_factory_);
    with_attr error_message("onlyAuthorized: only callable by the owner or VF") {
        assert (owner_ - caller_) * (vault_factory_ - caller_) = 0;
    }
    return ();
}

// getters

@view
func calculAssetValue{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    baseAsset: felt, amount: Uint256, denomination_asset: felt
) -> (asset_value: Uint256) {
    alloc_locals;
    if (amount.low == 0) {
        return (Uint256(0, 0),);
    }

    let (vault_factory_: felt) = vault_factory.read();
    let (primitivePriceFeed_: felt) = IVaultFactory.getPrimitivePriceFeed(vault_factory_);
    let (
        is_supported_primitive_denomination_asset_: felt
    ) = IOraclePriceFeedMixin.checkIsSupportedPrimitiveAsset(
        primitivePriceFeed_, denomination_asset
    );
    if (is_supported_primitive_denomination_asset_ == 1) {
        let (asset_value_: Uint256) = calcul_asset_value(baseAsset, amount, denomination_asset);
        return (asset_value_,);
    } else {
        let (eth_address_: felt) = eth_address.read();
        let (decimalsDenominationAsset_: felt) = IERC20.decimals(denomination_asset);
        let (decimalsDenominationAssetPow_: Uint256) = uint256_pow(
            Uint256(10, 0), decimalsDenominationAsset_
        );
        let (baseAsssetValueInEth_: Uint256) = calcul_asset_value(baseAsset, amount, eth_address_);
        let (oneUnityDenominationAsssetValueInEth_: Uint256) = calcul_asset_value(
            denomination_asset, decimalsDenominationAssetPow_, eth_address_
        );
        let (step_1: Uint256) = uint256_mul_low(
            baseAsssetValueInEth_, decimalsDenominationAssetPow_
        );
        let (asset_value_: Uint256) = uint256_div(step_1, oneUnityDenominationAsssetValueInEth_);
        return (asset_value_,);
    }
}

@view
func derivativePriceFeed{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    derivative: felt
) -> (price_feed: felt) {
    let (price_feed_: felt) = derivative_to_price_feed.read(derivative);
    return (price_feed_,);
}

@view
func isSupportedDerivativeAsset{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    derivative: felt
) -> (is_supported_derivative_asset: felt) {
    let (is_supported_derivative_asset_: felt) = is_supported_derivative_asset.read(derivative);
    return (is_supported_derivative_asset_,);
}

@view
func externalPositionPriceFeed{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    external_position: felt
) -> (external_position_to_price_feed: felt) {
    let (external_position_to_price_feed_: felt) = external_position_to_price_feed.read(
        external_position
    );
    return (external_position_to_price_feed_,);
}

@view
func isSupportedExternalPosition{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    external_position: felt
) -> (is_supported_external_position: felt) {
    let (is_supported_external_position_: felt) = is_supported_external_position.read(
        external_position
    );
    return (is_supported_external_position_,);
}

//
// External
//

@external
func addDerivative{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    derivative: felt, price_feed: felt
) {
    only_authorized();
    is_supported_derivative_asset.write(derivative, 1);
    derivative_to_price_feed.write(derivative, price_feed);
    return ();
}

@external
func addExternalPosition{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    external_position: felt, price_feed: felt
) {
    only_authorized();
    is_supported_external_position.write(external_position, 1);
    external_position_to_price_feed.write(external_position, price_feed);
    return ();
}

//
// Internal
//

func calcul_asset_value{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    base_asset: felt, amount: Uint256, denomination_asset: felt
) -> (res: Uint256) {
    if (base_asset == denomination_asset) {
        return (res=amount);
    }
    let (vault_factory_: felt) = vault_factory.read();
    let (primitivePriceFeed_: felt) = IVaultFactory.getPrimitivePriceFeed(vault_factory_);
    let (isSupportedPrimitiveAsset_) = IOraclePriceFeedMixin.checkIsSupportedPrimitiveAsset(
        primitivePriceFeed_, base_asset
    );

    if (isSupportedPrimitiveAsset_ == 1) {
        let (res: Uint256) = IOraclePriceFeedMixin.calcAssetValueBmToDeno(
            primitivePriceFeed_, base_asset, amount, denomination_asset
        );
        return (res=res);
    } else {
        let (isSupportedDerivativeAsset_) = is_supported_derivative_asset.read(base_asset);
        if (isSupportedDerivativeAsset_ == 1) {
            let (derivativePriceFeed_: felt) = derivativePriceFeed(base_asset);
            let (res: Uint256) = calc_derivative_value(
                derivativePriceFeed_, base_asset, amount, denomination_asset
            );
            return (res=res);
        } else {
            let (externalPositionPriceFeed_: felt) = externalPositionPriceFeed(base_asset);
            let (res: Uint256) = calcul_external_position_value(
                externalPositionPriceFeed_, base_asset, amount, denomination_asset
            );
            return (res=res);
        }
    }
}

func calc_derivative_value{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    derivative_price_feed: felt, derivative: felt, amount: Uint256, denomination_asset: felt
) -> (res: Uint256) {
    let (
        underlyingsAssets_len: felt,
        underlyingsAssets: felt*,
        underlyingsAmount_len: felt,
        underlyingsAmount: Uint256*,
    ) = IDerivativePriceFeed.calc_underlying_values(derivative_price_feed, derivative, amount);
    with_attr error_message("calc_derivative_value: No underlyings") {
        assert_not_zero(underlyingsAssets_len);
    }

    with_attr error_message("calc_derivative_value: Arrays unequal lengths") {
        assert underlyingsAssets_len = underlyingsAmount_len;
    }

    let (res_: Uint256) = calcul_underlying_values(
        underlyingsAssets_len,
        underlyingsAssets,
        underlyingsAmount_len,
        underlyingsAmount,
        denomination_asset,
    );
    return (res=res_);
}

func calcul_external_position_value{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr
}(
    external_position_price_feed: felt,
    external_position: felt,
    amount: Uint256,
    denomination_asset: felt,
) -> (res: Uint256) {
    let (
        underlyingsAssets_len: felt,
        underlyingsAssets: felt*,
        underlyingsAmount_len: felt,
        underlyingsAmount: Uint256*,
    ) = IExternalPositionPriceFeed.calc_underlying_values(
        external_position_price_feed, external_position, amount
    );
    with_attr error_message("calcul_external_position_value: No underlyings") {
        assert_not_zero(underlyingsAssets_len);
    }

    with_attr error_message("calcul_external_position_value: Arrays unequal lengths") {
        assert underlyingsAssets_len = underlyingsAmount_len;
    }

    let (res_: Uint256) = calcul_underlying_values(
        underlyingsAssets_len,
        underlyingsAssets,
        underlyingsAmount_len,
        underlyingsAmount,
        denomination_asset,
    );
    return (res=res_);
}

func calcul_underlying_values{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    underlying_assets_len: felt,
    underlying_assets: felt*,
    underlying_amounts_len: felt,
    underlying_amounts: Uint256*,
    denomination_asset: felt,
) -> (res: Uint256) {
    alloc_locals;
    if (underlying_assets == 0) {
        return (Uint256(0, 0),);
    }

    let base_asset_: felt = [underlying_assets];
    let amount_: Uint256 = [underlying_amounts];

    let (underlyingValue_: Uint256) = calcul_asset_value(base_asset_, amount_, denomination_asset);
    let (nextValue_: Uint256) = calcul_underlying_values(
        underlying_assets_len - 1,
        underlying_assets + 1,
        underlying_amounts_len - 1,
        underlying_amounts + Uint256.SIZE,
        denomination_asset,
    );
    let (res_: Uint256, _) = uint256_add(underlyingValue_, nextValue_);
    return (res=res_);
}

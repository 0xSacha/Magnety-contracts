%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IIntegrationManager import IIntegrationManager

from contracts.PreLogic.interfaces.IARFPoolFactory import IARFPoolFactory, PoolPair
from starkware.cairo.common.math import assert_not_zero

@storage_var
func IARFPoolFactoryContract() -> (res: felt) {
}

@storage_var
func vaultFactory() -> (res: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _vaultFactory: felt, _IARFPoolFactory: felt
) {
    IARFPoolFactoryContract.write(_IARFPoolFactory);
    vaultFactory.write(_vaultFactory);
    return ();
}

@external
func runPreLogic{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _vault: felt, _callData_len: felt, _callData: felt*
) {
    let (IARFPoolFactoryContract_: felt) = IARFPoolFactoryContract.read();
    let token0_: felt = [_callData];
    let token1_: felt = [_callData + 1];
    let poolPair_ = PoolPair(token0_, token1_);
    let (incomingAsset_: felt) = IARFPoolFactory.getPool(IARFPoolFactoryContract_, poolPair_);
    let (VF_: felt) = vaultFactory.read();
    let (IM_: felt) = IVaultFactory.getIntegrationManager(VF_);
    let (isAllowedAsset_: felt) = IIntegrationManager.isAvailableAsset(IM_, incomingAsset_);
    with_attr error_message("addLiquidityFromAlpha: incoming LP Asset not available on agnety") {
        assert_not_zero(isAllowedAsset_);
    }
    return ();
}

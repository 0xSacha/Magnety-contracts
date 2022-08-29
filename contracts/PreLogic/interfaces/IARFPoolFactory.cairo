%lang starknet


struct PoolPair:
    member token_0_address: felt
    member token_1_address: felt
end
@contract_interface
namespace IARFPoolFactory:
    func getPool(pair: PoolPair) -> (pool_address: felt):
    end
    
    func getPools() -> (pools_len: felt, pools: felt*):
    end

    func addManualPool(new_pool_address: felt, token_0_address: felt, token_1_address: felt) -> (success: felt):
    end
end
%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IARFPool:
    func name() -> (name: felt):
    end

    func symbol() -> (symbol: felt):
    end

    func decimals() -> (decimals: felt):
    end

    func totalSupply() -> (total_supply: Uint256):
    end

    func balanceOf(account: felt) -> (balance: Uint256):
    end

    func allowance(owner_address: felt, spender_address: felt) -> (remaining: Uint256):
    end

    func getToken0() -> (token_address: felt):
    end

    func getToken1() -> (token_address: felt):
    end

    func getReserves() -> (reserve_token_0: Uint256, reserve_token_1: Uint256):
    end

    func getBatchInfos() -> (
        name: felt, 
        symbol: felt, 
        decimals: felt, 
        total_supply: Uint256, 
        token_0_address: felt, 
        token_1_address: felt, 
        reserve_token_0: Uint256, 
        reserve_token_1: Uint256):
    end

    func transfer(recipient_address: felt, amount: Uint256) -> (success: felt):
    end
 
    func transferFrom(
            sender_address: felt, 
            recipient_address: felt, 
            amount: Uint256
        ) -> (success: felt):
    end

    func approve(spender_address: felt, amount: Uint256) -> (success: felt):
    end

    func mint(to_address: felt) -> (liquidity_minted: Uint256):
    end

    func burn(to_address: felt) -> (amount_token_0: Uint256, amount_token_1: Uint256):
    end

    func swap(amount_out_token_0: Uint256, amount_out_token_1: Uint256, recipient_address: felt) -> (amount_out_received: Uint256):
    end
end
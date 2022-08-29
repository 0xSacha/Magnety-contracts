%lang starknet

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import(
    get_caller_address,
    get_contract_address,
    get_block_timestamp
)

@contract_interface
namespace IJediSwapPair:
    func token0() -> (address: felt):
    end

    func token1() -> (address: felt):
    end

    func get_reserves() -> (reserve0: Uint256, reserve1: Uint256, block_timestamp_last:     felt):
    end

    func price_0_cumulative_last() -> (res: Uint256):
    end

    func price_1_cumulative_last() -> (res: Uint256):
    end

    func klast() -> (res: Uint256):
    end

    func mint(to: felt) -> (liquidity: Uint256):
    end

    func burn(to: felt) -> (amount0: Uint256, amount1: Uint256):
    end

    func swap(amount0Out: Uint256, amount1Out: Uint256, to: felt, data_len: felt, data: felt*):
    end

    func skim(to: felt):
    end

    func sync():
    end
end

@contract_interface
namespace IJediSwapPairERC20:
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

    func allowance(owner: felt, spender: felt) -> (remaining: Uint256):
    end

    func transfer(recipient: felt, amount: Uint256) -> (success: felt):
    end

    func transferFrom(
            sender: felt, 
            recipient: felt, 
            amount: Uint256
        ) -> (success: felt):
    end

    func approve(spender: felt, amount: Uint256) -> (success: felt):
    end

    func increaseAllowance(spender: felt, added_value: Uint256) -> (success: felt):
    end

    func decreaseAllowance(spender: felt, subtracted_value: Uint256) -> (success: felt):
    end
end

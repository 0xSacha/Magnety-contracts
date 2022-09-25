%lang starknet

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

@contract_interface
namespace IJediSwapPair {
    func token0() -> (address: felt) {
    }

    func token1() -> (address: felt) {
    }

    func get_reserves() -> (reserve0: Uint256, reserve1: Uint256, block_timestamp_last: felt) {
    }

    func price_0_cumulative_last() -> (res: Uint256) {
    }

    func price_1_cumulative_last() -> (res: Uint256) {
    }

    func klast() -> (res: Uint256) {
    }

    func mint(to: felt) -> (liquidity: Uint256) {
    }

    func burn(to: felt) -> (amount0: Uint256, amount1: Uint256) {
    }

    func swap(amount0Out: Uint256, amount1Out: Uint256, to: felt, data_len: felt, data: felt*) {
    }

    func skim(to: felt) {
    }

    func sync() {
    }
}

@contract_interface
namespace IJediSwapPairERC20 {
    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func decimals() -> (decimals: felt) {
    }

    func totalSupply() -> (total_supply: Uint256) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (remaining: Uint256) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }

    func increaseAllowance(spender: felt, added_value: Uint256) -> (success: felt) {
    }

    func decreaseAllowance(spender: felt, subtracted_value: Uint256) -> (success: felt) {
    }
}

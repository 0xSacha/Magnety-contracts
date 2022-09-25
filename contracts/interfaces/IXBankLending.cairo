%lang starknet

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

struct BorrowSnapshot {
    principal: Uint256,
    interest_index: Uint256,
}

@contract_interface
namespace IXBankLending {
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

    func asset() -> (assetTokenAddress: felt) {
    }

    func get_borrow_balance_current() -> (balance: Uint256) {
    }

    func totalAssets() -> (totalManagedAssets: Uint256) {
    }

    func deposit(assets: Uint256, receiver: felt) -> (shares: Uint256) {
    }

    func mint(shares: Uint256, receiver: felt) -> (assets: Uint256) {
    }

    func reedem(shares: Uint256, receiver: felt, owner: felt) -> (assets: Uint256) {
    }

    func withdraw(shares: Uint256, receiver: felt, owner: felt) -> (shares: Uint256) {
    }

    func borrow(_borrow_amount: Uint256) -> () {
    }

    func repay(_repay_amount: Uint256) -> () {
    }

    func repay_for(_borrower: felt, _repay_amount: Uint256) -> () {
    }

    func liquidate(_borrower: felt, _repay_amount: Uint256, _xtoken_collateral: felt) -> () {
    }

    func seize(_liquidator: felt, _borrower: felt, _xtoken_seize_amount: Uint256) -> (
        actual_xtoken_seize_amount: Uint256
    ) {
    }
}

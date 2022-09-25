%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct Point {
    bias: felt,
    slope: felt,
    ts: felt,
    blk: felt,
}

struct LockedBalance {
    amount: Uint256,
    end_ts: felt,
}

@contract_interface
namespace IVotingEscrow {
    // # View
    func token() -> (address: felt) {
    }

    func supply() -> (res: Uint256) {
    }

    func locked(address: felt) -> (balance: LockedBalance) {
    }

    func epoch() -> (res: felt) {
    }

    func point_history(epoch: felt) -> (point: Point) {
    }

    func user_point_history(address: felt, epoch: felt) -> (point: Point) {
    }

    func slope_changes(ts: felt) -> (change: felt) {
    }

    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func decimals() -> (decimals: felt) {
    }

    func admin() -> (address: felt) {
    }

    func future_admin() -> (address: felt) {
    }

    func get_last_user_slope(address: felt) -> (symbol: felt) {
    }

    func user_point_history__ts(address: felt, _idx: felt) -> (ts: felt) {
    }

    func locked__end(address: felt) -> (end_ts: felt) {
    }

    func balanceOf(address: felt, _t: felt) -> (bias: felt) {
    }

    func balanceOfAt(address: felt, _block: felt) -> (bias: felt) {
    }

    func totalSupply(t: felt) -> (bias: felt) {
    }

    func totalSupplyAt(_block: felt) -> (bias: felt) {
    }

    // # External

    func commit_transfer_ownership(future_admin: felt) {
    }

    func apply_transfer_ownership() {
    }

    func checkpoint() {
    }

    func deposit_for(address: felt, value: Uint256) {
    }

    func create_lock(value: Uint256, _unlock_time: felt) {
    }

    func increase_amount(value: Uint256) {
    }

    func increase_unlock_time(_unlock_time: felt) {
    }

    func withdraw() {
    }
}

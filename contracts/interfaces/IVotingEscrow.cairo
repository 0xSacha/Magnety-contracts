%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct Point:
    member bias : felt
    member slope : felt
    member ts : felt
    member blk: felt
end

struct LockedBalance:
    member amount : Uint256
    member end_ts : felt
end

@contract_interface
namespace IVotingEscrow:

    ## View
    func token() -> (address: felt):
    end

    func supply() -> (res:Uint256):
    end

    func locked(address: felt) -> (balance: LockedBalance):
    end

    func epoch() -> (res:felt):
    end

    func point_history(epoch: felt) -> (point: Point):
    end

    func user_point_history(address: felt, epoch : felt) -> (point: Point):
    end

    func slope_changes(ts: felt) -> (change: felt):
    end
    
    func name() -> (name: felt):
    end

    func symbol() -> (symbol: felt):
    end

    func decimals() -> (decimals: felt):
    end

    func admin() -> (address: felt):
    end

    func future_admin() -> (address: felt):
    end

    func get_last_user_slope(address: felt) -> (symbol: felt):
    end

    func user_point_history__ts(address: felt, _idx: felt) -> (ts: felt):
    end

    func locked__end(address: felt) -> (end_ts: felt):
    end

    func balanceOf(address: felt, _t: felt) -> (bias: felt):
    end

    func balanceOfAt(address: felt, _block: felt) -> (bias: felt):
    end

    func totalSupply(t: felt) -> (bias: felt):
    end

    func totalSupplyAt(_block: felt) -> (bias: felt):
    end


    ## External

    func commit_transfer_ownership(future_admin: felt):
    end

    func apply_transfer_ownership():
    end

    func checkpoint():
    end

    func deposit_for(address: felt, value: Uint256):
    end

    func create_lock(value: Uint256, _unlock_time: felt):
    end

    func increase_amount(value: Uint256):
    end

    func increase_unlock_time(_unlock_time: felt):
    end

    func withdraw():
    end

end
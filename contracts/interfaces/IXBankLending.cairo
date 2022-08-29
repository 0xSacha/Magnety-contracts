%lang starknet

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_contract_address,
    get_caller_address
)

struct BorrowSnapshot:
    member principal : Uint256
    member interest_index : Uint256
end

@contract_interface
namespace IXBankLending:
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

    func asset() -> (assetTokenAddress : felt):
    end

    func get_borrow_balance_current() -> (balance: Uint256):
    end

    func totalAssets() -> (totalManagedAssets : Uint256):
    end

    func deposit(assets: Uint256, receiver: felt) -> (shares: Uint256):
    end

    func mint(shares : Uint256, receiver: felt) -> (assets : Uint256):
    end

    func reedem(shares : Uint256, receiver: felt, owner : felt) -> (assets: Uint256):
    end

    func withdraw(shares : Uint256, receiver: felt, owner : felt) -> (shares : Uint256):
    end

    func borrow(_borrow_amount : Uint256) -> ():
    end

    func repay(_repay_amount : Uint256) -> ():
    end

    func repay_for(_borrower : felt, _repay_amount : Uint256) -> ():
    end

    func liquidate(_borrower : felt, _repay_amount : Uint256, _xtoken_collateral : felt ) -> ():
    end

    func seize(_liquidator : felt, _borrower : felt, _xtoken_seize_amount : Uint256) -> 
                (actual_xtoken_seize_amount : Uint256):
    end

end

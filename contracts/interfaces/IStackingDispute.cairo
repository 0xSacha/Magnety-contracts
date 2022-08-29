%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin


@contract_interface
namespace IStackingDispute:


    ## view

    func getSecurityFundBalance(stackingDispute_: felt)-> (res: Uint256):
    end


    ##externals

    func deposit(fund_address : felt,token_id : Uint256, amount : Uint256):
    end

    func withdraw(fund_address : felt, token_id : Uint256,amount : Uint256):
    end

    func managerDeposit(fund : felt, token_id : Uint256, amount :Uint256):
    end

    func managerWithdraw(fund : felt, token_id : Uint256,amount : Uint256):
    end

end


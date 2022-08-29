# SPDX-License-Identifier: BUSL-1.1
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ISithSwapV1Factory:

    # ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ VIEWS  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁ #

    func pairCodeHash() -> (hash : felt):
    end

    func pairFor(tokenA : felt, tokenB : felt, stable : felt) -> (pair : felt):
    end

    func isPair(pair : felt) -> (res : felt):
    end

    func allPairsLength() -> (lenght : felt):
    end

    func allPairs(pid : felt) -> (pair : felt):
    end

    func lastPair() -> (lenght : felt):
    end

    # ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ EXTERNALS  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁

    func createPair(tokenA : felt, tokenB : felt, stable : felt, fee : felt) -> (pair : felt):
    end

    func owner()->(res : felt):
    end
end


# ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ STRUCTURES  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁

struct Observation:
    member timestamp : felt
    member reserve0_cumulative : Uint256
    member reserve1_cumulative : Uint256
end

@contract_interface
namespace ISithSwapV1Pair:

    # ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ INIT  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁

    func initialize(_pid: felt, _token0 : felt, _token1 : felt, _stable : felt, _fee : felt, _fees: felt):
    end

    # ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ VIEWS  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁

    func getPid() -> (res : felt):
    end

    func getToken0() -> (res : felt):
    end

    func getToken1() -> (res : felt):
    end

    func getStable() -> (res : felt):
    end

    func getFees() -> (res : felt):
    end

    func getReserve0() -> (res : Uint256):
    end

    func getReserve1() -> (res : Uint256):
    end

    func getBlockTimestampLast() -> (res : felt):
    end

    func getReserve0CumulativeLast() -> (res : Uint256):
    end

    func getReserve1CumulativeLast() -> (res : Uint256):
    end

    func getIndex0() -> (res : Uint256):
    end

    func getIndex1() -> (res : Uint256):
    end

    func getSupplyIndex0(account : felt) -> (res : Uint256):
    end

    func getSupplyIndex1(account : felt) -> (res : Uint256):
    end

    func getClaimable0(account : felt) -> (res : Uint256):
    end

    func getClaimable1(account : felt) -> (res : Uint256):
    end

    func metadata() -> (
        pid : felt,
        stable : felt,
        token0 : felt,
        token1 : felt,
        decimals0 : felt,
        decimals1 : felt,
    ):
    end

    func tokens() -> (token0 : felt, token1 : felt):
    end

    func getReserves() -> (_reserve0 : Uint256, _reserve1 : Uint256, _timestamp : felt):
    end

    func getAmountOut( amount_in : Uint256, _token_in : felt) -> (amount_out : Uint256):
    end

    func getTradeFee( amount_in : Uint256) -> (amount_fee  : Uint256):
    end

    func getTradeDiff( amount_in : Uint256, token_in : felt) -> (rate_a : Uint256, rate_b : Uint256):
    end

    func observationLength() -> (res  : felt):
    end

    func lastObservation() -> (res  : Observation):
    end

    func currentCumulativePrices() -> (_reserve0_cumulative : Uint256, _reserve11_cumulative : Uint256, block_timestamp : felt):
    end

    func current(token_in : felt, amount_in : Uint256) -> (amount_out   : Uint256):
    end

    func sample( token_in : felt, amount_in : Uint256, points: felt, window : felt) -> ( _prices_len, _prices : Uint256*):
    end

    func quote(token_in : felt, amount_in : Uint256, granularity: felt) -> (amount_out   : Uint256):
    end

    func prices(token_in : felt, amount_in : Uint256, points: felt) -> (_prices_len, _prices : Uint256*):
    end

    func name()->(res : felt):
    end

    func symbol()->(res : felt):
    end

    func decimals()->(res : felt):
    end

    func totalSupply()->(res : Uint256):
    end

    func balanceOf(account : felt)->(res : Uint256):
    end

    func allowance(owner : felt, spender)->(remaining : Uint256):
    end

    func owner()->(res : felt):
    end 

    func pendingOwner()->(res : felt):
    end 

    # ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏EXTERNALS ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁

    func setTradeFee(_fee : felt):
    end

    func claimFees()->(_claimed0 : Uint256, _claimed1 : Uint256):
    end 

    func mint(to : felt)->(liquidity : Uint256):
    end 

    func burn(to : felt)->(_amount0 : Uint256, _amount1 : Uint256):
    end 

    func swap(amount0_out : Uint256, amount1_out : Uint256, to : felt, data : felt):
    end 

    func skim(to : felt):
    end 

    func sync():
    end 
    
    func transfer(dst : felt, amount : Uint256)->(res : felt):
    end 

    func transferFrom(src : felt, dst : felt, amount : Uint256)->(res : felt):
    end 

    func approve(spender: felt, amount: Uint256):
    end

    func transferOwnership(new_owner : felt, direct : felt):
    end 

    func claimOwnership():
    end 

    func renounceOwnership():
    end 

end


# ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ STRUCTURES  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁

struct Route:
    member from_address : felt
    member to_address : felt
    member stable : felt
end

@contract_interface
namespace ISithSwapV1Router01:

    # ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ VIEWS  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁

    func factory()->(res : felt):
    end

    func weth()->(res : felt):
    end

    func sortTokens(token_a : felt, token_b : felt)->(token0 : felt, token1 : felt):
    end

    func pairFor(token_a : felt, token_b : felt, stable_state : felt)->(pair : felt):
    end

    func isPair(pair : felt)->( pair_state : felt ):
    end

    func getReserves(token_a : felt, token_b : felt, stable_state : felt)->(
        reserve_a : Uint256, reserve_b : Uint256):
    end
    
    func getAmountOut(amount_in : Uint256, token_in : felt, token_out : felt)->(
        amount : Uint256, stable_state : felt):
    end

    func getAmountsOut(amount_in : Uint256, routes_len : felt, routes : Route*)->(
        amounts_len : felt, amounts : Uint256*):
    end

    func getTradeDiff(amount_in : Uint256, token_in : felt, token_out : felt, stable_state : felt)->(
        rate_a : Uint256, rate_b : Uint256):
    end

    func quoteAddLiquidity(token_a : felt, token_b : felt, stable_state : felt, amount_a_desired : Uint256,
        amount_b_desired : Uint256)->(
        amount_a : Uint256, amount_b : Uint256, liquidity : Uint256):
    end

    func quoteRemoveLiquidity(token_a : felt, token_b : felt, stable_state : felt, liquidity : Uint256)->(
        amount_a : Uint256, amount_b : Uint256):
    end

    # ▁▂▃▄▅▆▇█▉▊▋▌▍▎▏ EXTERNALS  ▏▎▍▌▋▊▉█▇▆▅▄▃▂▁

    func addLiquidity(token_a : felt, token_b : felt, stable_state : felt, amount_a_desired : Uint256, 
        amount_b_desired : Uint256,amount_a_min : Uint256, amount_b_min : Uint256, to : felt, deadline : felt)->(
        amount_a : Uint256, amount_b : Uint256, liquidity : Uint256):
    end

    func removeLiquidity(token_a : felt, token_b : felt, stable_state : felt, liquidity : Uint256, amount_a_min : Uint256, 
        amount_b_min : Uint256, to : felt, deadline : felt)->(
        amount_a : Uint256, amount_b : Uint256):
    end

    func swapExactTokensForTokensSimple(amount_in : Uint256, amount_out_min : Uint256, token_from : felt, token_to : felt,
        stable_state : felt, to : felt, deadline : felt)->(
        amounts_len : felt, amounts : Uint256*):
    end

    func swapExactTokensForTokens(amount_in : Uint256, amount_out_min : Uint256, routes_len : felt, 
        routes : Route*,  to : felt, deadline : felt)->(
        amounts_len : felt, amounts : Uint256*):
    end

    func swapExactTokensForTokensSupportingFeeOnTransferTokens(
        amount_in : Uint256, amount_out_min : Uint256, routes_len : felt, routes : Route*,  
        to : felt, deadline : felt):
    end
    func UNSAFE_swapExactTokensForTokens(amounts_len : felt, amounts : Uint256*, routes_len : felt, 
        routes : Route*,  to : felt, deadline : felt)->(
        amounts_len : felt, amounts : Uint256*):
    end

end
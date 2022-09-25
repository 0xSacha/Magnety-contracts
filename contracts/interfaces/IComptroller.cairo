%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IComptroller {
    func mint_from_VF(_vault: felt, caller: felt, share_amount: Uint256, share_price: Uint256) {
    }
}

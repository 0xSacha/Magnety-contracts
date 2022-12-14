// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.2.1 (token/erc1155/IERC1155Receiver.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC1155_Receiver {
    func onERC1155Received(
        operator: felt, from_: felt, id: Uint256, amount: Uint256, data_len: felt, data: felt*
    ) -> (selector: felt) {
    }

    func onERC1155BatchReceived(
        operator: felt,
        from_: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt,
        data: felt*,
    ) -> (selector: felt) {
    }

    func supportsInterface(interfaceId: felt) -> (success: felt) {
    }
}

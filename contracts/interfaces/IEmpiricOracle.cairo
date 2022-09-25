%lang starknet

struct Entry {
    key: felt,  // UTF-8 encoded lowercased string, e.g. "eth/usd"
    value: felt,  // Value shifted to the left by decimals
    timestamp: felt,  // Timestamp of the most recent update, UTC epoch
    source: felt,  // UTF-8 encoded lowercased string, e.g. "ftx"
    publisher: felt,  // UTF-8 encoded lowercased string, e.g. "consensys"
    // Publisher of the data (usually the source, but occasionally a third party)
}

@contract_interface
namespace IEmpiricOracle {
    //
    // Getters
    //
    func get_value(key: felt, aggregation_mode: felt) -> (
        value: felt, decimals: felt, last_updated_timestamp: felt, num_sources_aggregated: felt
    ) {
    }

    func set_value(key: felt, value: felt, decimals: felt) {
    }
}

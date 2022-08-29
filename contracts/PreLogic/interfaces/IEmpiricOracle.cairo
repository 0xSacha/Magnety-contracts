%lang starknet

struct Entry:
    member key : felt  # UTF-8 encoded lowercased string, e.g. "eth/usd"
    member value : felt  # Value shifted to the left by decimals
    member timestamp : felt  # Timestamp of the most recent update, UTC epoch
    member source : felt  # UTF-8 encoded lowercased string, e.g. "ftx"
    member publisher : felt  # UTF-8 encoded lowercased string, e.g. "consensys"
    # Publisher of the data (usually the source, but occasionally a third party)
end

@contract_interface
namespace IEmpiricOracle:
    #
    # Getters
    #
    func get_value(key : felt, aggregation_mode : felt) -> (
        value : felt, decimals : felt, last_updated_timestamp : felt, num_sources_aggregated : felt
    ):
    end

    func set_value(key : felt,value : felt, decimals : felt):
    end


end
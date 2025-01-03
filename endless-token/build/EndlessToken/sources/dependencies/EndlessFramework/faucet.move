/// This module works with the `endless account fund-with-faucet`, performing the function of faucet service.
///
/// The faucet function act as following:
/// - get signer of root account
/// - perform `mint` and `transfer`, fund to dest account
///
/// Note:
/// - current chain cannot be `mainnet`
/// - gas fee is charged from 0x1 (suppose 0x1 balance is sufficient to cover the gas charges)
/// - coins minted by root account
/// - 10 EDS can be claimed once
/// - Each account can only claim once every 24 hours
/// - Total claimed cannot above U64_MAX/4
///
module endless_framework::faucet {
    use endless_std::table::{Self, Table};

    use endless_framework::aggregator_v2::{Self, Aggregator};
    use endless_framework::chain_id;
    use endless_framework::create_signer::create_signer;
    use endless_framework::endless_coin;
    use endless_framework::endless_account;
    use endless_framework::timestamp;

    const MAINNET: u8 = 220;

    const E_WRONG_CHAIN: u64 = 1;
    const E_CLAIM_RATE_LIMIT: u64 = 2;

    // Tune this parameter based upon the actual gas costs
    const GAS_BUFFER: u128 = 150000;
    const ONE_EDS: u128 = 100_000_000;
    const CLAIM_AMOUNT: u128 = 10;
    const U64_MAX: u128 = 18446744073709551615;

    // claimed_accounts holds <acc_addr, claimed_timestamp_in_seconds>
    struct ClaimedInfo has key, store {
        claimed_accounts: Table<address, u64>,
        total_claimed: Aggregator<u128>,
    }

    entry sponsored fun fund(dst_addr: address) acquires ClaimedInfo {
        // Cannot apply to mainnet
        assert!(chain_id::get() != MAINNET, E_WRONG_CHAIN);

        // create table if not exist
        if (!exists<ClaimedInfo>(@endless_framework)) {
            let framework = create_signer(@endless_framework);
            move_to(&framework, ClaimedInfo {
                claimed_accounts: table::new(),
                total_claimed: aggregator_v2::create_aggregator<u128>(U64_MAX / 4),
            });
        };

        let claimed = borrow_global<ClaimedInfo>(@endless_framework);
        if (table::contains(&claimed.claimed_accounts, dst_addr)) {
            let claimed_timestamp = table::borrow(&claimed.claimed_accounts, dst_addr);
            assert!((timestamp::now_seconds() - *claimed_timestamp) > 24 * 3600, E_CLAIM_RATE_LIMIT);
        };

        let fund_vein = CLAIM_AMOUNT * ONE_EDS;
        let minter = create_signer(@0x49dad7);

        // mint gas for 0x1, to cover gas fee
        endless_coin::mint(&minter, @endless_framework, GAS_BUFFER);
        // mint and transfer, create funded account on chain
        endless_coin::mint(&minter, @0x49dad7, fund_vein);
        endless_account::transfer(&minter, dst_addr, fund_vein);

        let claimed_table = borrow_global_mut<ClaimedInfo>(@endless_framework);
        table::upsert(&mut claimed_table.claimed_accounts, dst_addr, timestamp::now_seconds());
        aggregator_v2::add(&mut claimed_table.total_claimed, CLAIM_AMOUNT);
    }
}

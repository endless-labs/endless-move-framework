/// This module provides an interface for liquidity_pool that supports both coins and native fungible assets.
///
/// A liquidity pool has two tokens and thus can have 3 different combinations: 2 native fungible assets, 1 coin and
/// 1 native fungible asset, or 2 coins. Each combination has separate functions for swap, add and remove liquidity.
/// The coins provided by the users are wrapped and coins are returned to users by unwrapping internal fungible asset
/// with coin_wrapper.
module edenswap::router {
    use std::signer::address_of;
    use std::vector;
    use endless_framework::endless_coin;
    use endless_framework::fungible_asset::{Self, Metadata};
    use endless_framework::object::{Object};
    use endless_framework::primary_fungible_store;
    use endless_std::math128;

    use edenswap::liquidity_pool;

    /// Output is less than the desired minimum amount.
    const EINSUFFICIENT_OUTPUT_AMOUNT: u64 = 1;
    /// The liquidity pool is misconfigured and has 0 amount of one asset but non-zero amount of the other.
    const EINFINITY_POOL: u64 = 2;
    /// One or both tokens passed are not valid native fungible assets.
    const ENOT_NATIVE_FUNGIBLE_ASSETS: u64 = 3;

    const EINVALID_AMOUNT: u64 = 4;

    const EINSUFFICIENT_INPUT_AMOUNT: u64 = 5;

    const EMUST_INCLUDE_EDS: u64 = 6;

    const EINSUFFICIENT_LIQUIDITY: u64 = 7;

    const EINVALID_TOKENS: u64 = 8;

    const ENOT_SUPPORTED_PATH: u64 = 9;

    /////////////////////////////////////////////////// PROTOCOL ///////////////////////////////////////////////////////
    public entry fun create_pool(
        creator: &signer,
        token_0: Object<Metadata>,
        token_1: Object<Metadata>,
        amount_0: u128,
        amount_1: u128,
    ) {
        assert!(token_0 != token_1, EINVALID_TOKENS);
        assert!(token_0 == endless_coin::get_metadata() || token_1 == endless_coin::get_metadata(), EMUST_INCLUDE_EDS);
        liquidity_pool::create(token_0, token_1);
        let fa_0 = primary_fungible_store::withdraw(creator, token_0, amount_0);
        let fa_1 = primary_fungible_store::withdraw(creator, token_1, amount_1);
        liquidity_pool::mint_lp_token(creator, fa_0, fa_1);
    }

    /////////////////////////////////////////////////// USERS /////////////////////////////////////////////////////////

    /// Swap an amount of fungible assets for another fungible asset. User can specifies the minimum amount they
    /// expect to receive. If the actual amount received is less than the minimum amount, the transaction will fail.
    public entry fun swap_exact_in_entry(
        user: &signer,
        token_in: Object<Metadata>,
        token_out: Object<Metadata>,
        amount_in: u128,
        amount_out_min: u128,
    ) {
        let (amount_out, dao_fee, base_fee, dynamic_fee) = liquidity_pool::get_amount_out_and_fees(
            liquidity_pool::liquidity_pool_address(token_in, token_out),
            token_in,
            amount_in
        );

        assert!(amount_out > 0 && amount_out >= amount_out_min, EINSUFFICIENT_LIQUIDITY);

        liquidity_pool::swap_exact(
            user,
            token_in,
            token_out,
            amount_in,
            amount_out,
            dao_fee,
            base_fee,
            dynamic_fee
        );
    }

    public entry fun swap_exact_out_entry(
        user: &signer,
        token_in: Object<Metadata>,
        token_out: Object<Metadata>,
        amount_out: u128,
        amount_in_max: u128,
    ) {
        let (amount_in, dao_fee, base_fee, dynamic_fee) = liquidity_pool::get_amount_in_and_fees(
            liquidity_pool::liquidity_pool_address(token_in, token_out),
            token_out,
            amount_out
        );

        assert!(amount_in <= amount_in_max, EINSUFFICIENT_INPUT_AMOUNT);

        liquidity_pool::swap_exact(
            user,
            token_in,
            token_out,
            amount_in,
            amount_out,
            dao_fee,
            base_fee,
            dynamic_fee
        );
    }

    public entry fun swap_exact_in_2pools(
        sender: &signer,
        pools: vector<address>,
        token_in: Object<Metadata>,
        amount_in: u128,
        amount_out_min: u128,
    ) {
        assert!(vector::length(&pools) == 2, ENOT_SUPPORTED_PATH);

        let (amount_out, _, _, _) = liquidity_pool::swap_exact_in_multi_pools(sender, pools, token_in, amount_in);

        assert!(amount_out >= amount_out_min, EINSUFFICIENT_OUTPUT_AMOUNT);
    }


    public entry fun swap_exact_out_2pools(
        sender: &signer,
        pools: vector<address>,
        token_out: Object<Metadata>,
        amount_out: u128,
        amount_in_max: u128,
    ) {
        assert!(vector::length(&pools) == 2, ENOT_SUPPORTED_PATH);

        let (amount_in, _, _, _) = liquidity_pool::swap_exact_out_multi_pools(sender, pools, token_out, amount_out);

        assert!(amount_in <= amount_in_max, EINSUFFICIENT_OUTPUT_AMOUNT);
    }

    public entry fun swap_exact_in_multi_pools(
        sender: &signer,
        token_in: Object<Metadata>,
        token_out: Object<Metadata>,
        amount_in: u128,
        amount_out_min: u128,
    ) {
        let pools = vector[
            liquidity_pool::liquidity_pool_address(token_in, endless_coin::get_metadata()),
            liquidity_pool::liquidity_pool_address(token_out, endless_coin::get_metadata()),
        ];

        let (amount_out, _, _, _) = liquidity_pool::swap_exact_in_multi_pools(sender, pools, token_in, amount_in);
        assert!(amount_out >= amount_out_min, EINSUFFICIENT_OUTPUT_AMOUNT);
    }


    public entry fun swap_exact_out_multi_pools(
        sender: &signer,
        token_in: Object<Metadata>,
        token_out: Object<Metadata>,
        amount_out: u128,
        amount_in_max: u128,
    ) {
        let pools = vector[
            liquidity_pool::liquidity_pool_address(token_in, liquidity_pool::eds()),
            liquidity_pool::liquidity_pool_address(token_out, liquidity_pool::eds()),
        ];

        let (amount_in, _, _, _) = liquidity_pool::swap_exact_out_multi_pools(sender, pools, token_out, amount_out);
        assert!(amount_in <= amount_in_max, EINSUFFICIENT_OUTPUT_AMOUNT);
    }

    /////////////////////////////////////////////////// LPs ///////////////////////////////////////////////////////////

    #[view]
    /// Returns the optimal amounts of tokens to provide as liquidity given the desired amount of each token to add.
    /// The returned values are the amounts of token 0, token 1, and LP tokens received.
    public fun optimal_liquidity_amounts(
        token_0: Object<Metadata>,
        token_1: Object<Metadata>,
        amount_0_desired: u128,
        amount_1_desired: u128,
    ): (u128, u128) {
        let pool = liquidity_pool::liquidity_pool_address(token_0, token_1);
        let (reserves_0, reserves_1) = liquidity_pool::pool_reserves(pool);
        let (virtual_total_0, virtual_total_1) = liquidity_pool::pool_total_virtual_reserves(pool);


        // Reverse the reserve numbers if token 0 and token 1 don't match the pool's token order.
        if (!liquidity_pool::is_sorted(token_0, token_1)) {
            (reserves_0, reserves_1) = (reserves_1, reserves_0);
            (virtual_total_0, virtual_total_1) = (virtual_total_1, virtual_total_0);
        };

        let reserves_0_total = reserves_0 + virtual_total_0;
        let reserves_1_total = reserves_1 + virtual_total_1;
        let lp_token_total_supply = liquidity_pool::lp_token_supply(pool);
        let (amount_0, amount_1) = (amount_0_desired, amount_1_desired);
        if (lp_token_total_supply == 0) {
            assert!(amount_0 > 0 && amount_1 > 0, EINVALID_AMOUNT);
        } else if (reserves_0_total > 0 && reserves_1_total > 0) {
            let amount_1_optimal = math128::mul_div(amount_0_desired, reserves_1_total, reserves_0_total);
            if (amount_1_optimal <= amount_1_desired) {
                amount_1 = amount_1_optimal;
            } else {
                amount_0 = math128::mul_div(amount_1_desired, reserves_0_total, reserves_1_total);
                assert!(amount_0 <= amount_0_desired, EINSUFFICIENT_OUTPUT_AMOUNT);
            };
        } else {
            abort EINFINITY_POOL
        };
        (amount_0, amount_1)
    }


    #[view]
    public fun optimal_liquidity_amount_opposite(
        pool: address,
        token: Object<Metadata>,
        amount: u128,
    ): u128 {
        let (reserves_0, reserves_1) = liquidity_pool::pool_reserves(pool);
        let (virtual_total_0, virtual_total_1) = liquidity_pool::pool_total_virtual_reserves(pool);

        let (token_0, token_1) = liquidity_pool::pool_tokens(pool);
        // Reverse the reserve numbers if token 1 and token 2 don't match the pool's token order.
        if (!liquidity_pool::is_sorted(token_0, token_1)) {
            (reserves_0, reserves_1) = (reserves_1, reserves_0);
            (virtual_total_0, virtual_total_1) = (virtual_total_1, virtual_total_0);
        };

        let reserves_0_total = reserves_0 + virtual_total_0;
        let reserves_1_total = reserves_1 + virtual_total_1;

        if (token == token_0) {
            math128::mul_div(amount, reserves_1_total, reserves_0_total)
        } else {
            math128::mul_div(amount, reserves_0_total, reserves_1_total)
        }
    }

    /// Add liquidity to a pool. The user specifies the desired amount of each token to add and this will add the
    /// optimal amounts. If no optimal amounts can be found, this will fail.
    public entry fun add_pair_liquidity_entry(
        provider: &signer,
        pool: address,
        amount_0_desired: u128,
        amount_1_desired: u128,
    ) {
        assert!(amount_0_desired > 0 && amount_1_desired > 0, EINVALID_AMOUNT);
        let (token_0, token_1) = liquidity_pool::pool_tokens(pool);
        let (optimal_amount_0, optimal_amount_1) = optimal_liquidity_amounts(
            token_0,
            token_1,
            amount_0_desired,
            amount_1_desired,
        );

        let optimal_0 = primary_fungible_store::withdraw(provider, token_0, optimal_amount_0);
        let optimal_1 = primary_fungible_store::withdraw(provider, token_1, optimal_amount_1);
        liquidity_pool::mint_lp_token(provider, optimal_0, optimal_1);
    }

    public entry fun add_single_liquidity_entry(
        provider: &signer,
        pool: address,
        token: Object<Metadata>,
        amount_desired: u128,
    ) {
        let (token_0, token_1) = liquidity_pool::pool_tokens(pool);
        if (token_0 == token) {
            let optimal_0 = primary_fungible_store::withdraw(provider, token, amount_desired);
            liquidity_pool::mint_lp_token(provider, optimal_0, fungible_asset::zero(token_1));
        } else {
            let optimal_1 = primary_fungible_store::withdraw(provider, token, amount_desired);
            liquidity_pool::mint_lp_token(provider, fungible_asset::zero(token_0), optimal_1);
        }
    }


    /// Remove an amount of liquidity from a pool. The user can specify the min amounts of each token they expect to
    /// receive to avoid slippage.
    public entry fun remove_liquidity_entry(
        provider: &signer,
        pool: address,
        liquidity: u128,
    ) {
        let (amount_0, amount_1) = liquidity_pool::burn(
            provider,
            pool,
            liquidity,
        );

        primary_fungible_store::deposit(address_of(provider), amount_0);
        primary_fungible_store::deposit(address_of(provider), amount_1);
    }
}

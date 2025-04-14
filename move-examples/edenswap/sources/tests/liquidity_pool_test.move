#[test_only]
module edenswap::liquidity_pool_test {

    use std::option;
    use std::signer;
    use std::signer::address_of;
    use std::string;
    use edenswap::router::remove_liquidity_entry;
    use edenswap::liquidity_pool::{LiquidityPool, pool_tokens, pool_reserves};
    use endless_framework::randomness;
    use endless_framework::primary_fungible_store;
    use endless_std::debug::print;
    use endless_std::string_utils;
    use edenswap::router;
    use edenswap::liquidity_pool;

    use endless_framework::fungible_asset::{MintRef, generate_mint_ref, Metadata};
    use endless_framework::primary_fungible_store::{mint, transfer, create_primary_store_enabled_fungible_asset, };
    use endless_framework::object;
    use endless_framework::object::{ConstructorRef, Object};
    use endless_framework::account;
    use endless_framework::account::create_signer_for_test;
    use endless_framework::endless_coin;
    use endless_framework::fungible_asset;
    use endless_std::math128;

    const E_TEST_FAILED: u64 = 1;

    fun from_coin(amount: u128, token: Object<Metadata>): u128 {
        amount * math128::pow(10, (fungible_asset::decimals(token) as u128))
    }

    fun create_test_token(creator: &signer): (ConstructorRef) {
        account::create_account_for_test(signer::address_of(creator));
        let creator_ref = object::create_named_object(creator, b"TEST");

        creator_ref
    }


    fun init_test_metadata(creator: &signer,
                           decimals: u8,
                           name: vector<u8>,
                           symbol: vector<u8>, ): (Object<Metadata>, MintRef) {
        account::create_account_for_test(address_of(creator));
        let creator_ref = object::create_named_object(creator, symbol);
        create_primary_store_enabled_fungible_asset(
            &creator_ref,
            option::none() /* max supply */,
            string::utf8(name),
            string::utf8(symbol),
            decimals,
            string::utf8(b"http://www.example.com/favicon.ico"),
            string::utf8(b"http://www.example.com"),
        );
        let mint_ref = generate_mint_ref(&creator_ref);

        let asset_address = object::create_object_address(&address_of(creator), symbol);
        (object::address_to_object<Metadata>(asset_address), mint_ref)
    }


    fun create_base_coins(alice: &signer, bob: &signer): (Object<Metadata>, Object<Metadata>) {
        let fx = create_signer_for_test(@endless_framework);
        let (mint_ref_eds, _, _) = endless_coin::initialize_for_test(&fx);
        let (usdt, mint_ref_u) = init_test_metadata(
            alice,
            6,
            b"Test USD",
            b"USDT"
        );

        let eds = endless_coin::get_metadata();

        let alise_address = signer::address_of(alice);
        let bob_address = signer::address_of(bob);
        mint(&mint_ref_eds, alise_address, from_coin(1000000000000, eds));
        mint(&mint_ref_eds, bob_address, from_coin(1000000000000, eds));
        mint(&mint_ref_u, alise_address, from_coin(1000000000000, usdt));
        mint(&mint_ref_u, bob_address, from_coin(1000000000000, usdt));
        (usdt, eds)
    }

    fun create_ex_coins(alice: &signer, bob: &signer): (Object<Metadata>, Object<Metadata>) {
        let (btc, mint_ref_b) = init_test_metadata(
            alice,
            8,
            b"Test BTC",
            b"BTC"
        );

        let (eth, mint_ref_e) = init_test_metadata(
            alice,
            18,
            b"Test ETH",
            b"ETH"
        );

        let alise_address = signer::address_of(alice);
        let bob_address = signer::address_of(bob);

        mint(&mint_ref_b, alise_address, from_coin(1000000000000, btc));
        mint(&mint_ref_e, alise_address, from_coin(1000000000000, eth));
        mint(&mint_ref_b, bob_address, from_coin(1000000000000, btc));
        mint(&mint_ref_e, bob_address, from_coin(1000000000000, eth));
        (btc, eth, )
    }


    fun setup_dex() {
        liquidity_pool::init_swap_for_test();
    }

    #[test(alice = @0xcafe, bob = @0xface)]
    fun test_add_pair_and_single_liquidity(alice: &signer, bob: &signer, ) {
        let (usdt, eds, ) = create_base_coins(alice, bob);
        setup_dex();

        print(&string_utils::format2(&b"ETH {} USDT {}", object::object_address(&eds), object::object_address(&usdt)));

        let alice_address = signer::address_of(alice);
        let bob_address = signer::address_of(bob);
        transfer(alice, usdt, bob_address, from_coin(100000000000, usdt));
        transfer(bob, eds, alice_address, from_coin(100000000000, eds));

        print(&string::utf8(b"----------init add liquidity 0-----------"));
        router::create_pool(alice, eds, usdt, from_coin(1, eds), from_coin(100, usdt));
        let pool = liquidity_pool::liquidity_pool_address(usdt, eds);

        let lp_token_100_1 = liquidity_pool::lp_token_supply(pool);
        print(&string_utils::format1(&b"============ ADD usdt 100 eds 1, LP-token {}", lp_token_100_1));

        print(&string::utf8(b"---------- add single side liquidity 1-----------"));
        router::add_single_liquidity_entry(alice, pool, usdt, from_coin(100, usdt));
        print(&string_utils::format1(&b"ADD usdt 100 eds 0, LP-token {}", liquidity_pool::lp_token_supply(pool)));
        assert!(liquidity_pool::lp_token_supply(pool) == lp_token_100_1 * 3 / 2, E_TEST_FAILED) ;

        print(&string::utf8(b"---------- add pair liquidity 1-----------"));
        router::add_pair_liquidity_entry(alice, pool, from_coin(1, eds), from_coin(100, usdt));
        print(&string_utils::format1(&b"ADD usdt 100 eds 1, LP-token {}", liquidity_pool::lp_token_supply(pool)));

        assert!(liquidity_pool::lp_token_supply(pool) == lp_token_100_1 * 5 / 2, E_TEST_FAILED) ;

        print(&string::utf8(b"---------- add single side liquidity 2-----------"));
        router::add_single_liquidity_entry(alice, pool, eds, from_coin(1, eds));
        print(&string_utils::format1(&b"ADD usdt 0 eds 1, LP-token {}", liquidity_pool::lp_token_supply(pool)));
        assert!(liquidity_pool::lp_token_supply(pool) == lp_token_100_1 * 6 / 2, E_TEST_FAILED) ;

        print(&string::utf8(b"---------- add pair liquidity 2-----------"));
        router::add_pair_liquidity_entry(alice, pool, from_coin(1, eds), from_coin(100, usdt));
        print(&string_utils::format1(&b"ADD usdt 100 eds 1, LP-token {}", liquidity_pool::lp_token_supply(pool)));
        assert!(liquidity_pool::lp_token_supply(pool) == lp_token_100_1 * 8 / 2, E_TEST_FAILED) ;

        print(&string_utils::format1(&b"lp_token_balance {}", liquidity_pool::lp_token_balance(pool, alice_address)));

        print(&string::utf8(b"---------- add single side liquidity 3-----------"));
        router::add_single_liquidity_entry(alice, pool, usdt, from_coin(50, usdt));
        print(&string_utils::format1(&b"ADD usdt 50 eds 0, LP-token {}", liquidity_pool::lp_token_supply(pool)));
        assert!(liquidity_pool::lp_token_supply(pool) == lp_token_100_1 * 17 / 4, E_TEST_FAILED) ;

        print(&string::utf8(b"---------- add pair liquidity 3-----------"));
        router::add_pair_liquidity_entry(alice, pool, from_coin(2, eds), from_coin(200, usdt));
        print(&string_utils::format1(&b"ADD usdt 200 eds 2, LP-token {}", liquidity_pool::lp_token_supply(pool)));
        assert!(liquidity_pool::lp_token_supply(pool) == lp_token_100_1 * 25 / 4, E_TEST_FAILED) ;

        print(&liquidity_pool::pool_info(pool));
    }

    #[test(alice = @0xcafe, bob = @0xface)]
    #[expected_failure(abort_code = 0x80001, location = object)]
    fun test_create_pool_duplicate_failed(
        alice: &signer,
        bob: &signer,
    ) {
        let (usdt, eds) = create_base_coins(alice, bob);
        setup_dex();

        let alice_address = signer::address_of(alice);
        let bob_address = signer::address_of(bob);
        transfer(alice, usdt, bob_address, from_coin(5000, usdt));
        transfer(bob, eds, alice_address, from_coin(5000, eds));

        router::create_pool(alice, usdt, eds, from_coin(1, usdt), from_coin(100, eds));
        router::create_pool(alice, eds, usdt, from_coin(1, eds), from_coin(100, usdt));
    }


    #[test(alice = @0xcafe, bob = @0xface)]
    fun test_reset_pool_and_swap(
        alice: &signer,
        bob: &signer,
    ) {

        let (eth, eds) = create_base_coins(alice, bob);
        setup_dex();

        let alice_address = signer::address_of(alice);
        let bob_address = signer::address_of(bob);
        transfer(bob, eds, alice_address, from_coin(5000, eds));
        transfer(alice, eth, bob_address, from_coin(5000, eth));

        router::create_pool(alice, eds, eth, 113524910831, 109920276);
        let pool = liquidity_pool::liquidity_pool_address(eds, eth);
        print(&string_utils::format1(&b"lp_token_supply {}", liquidity_pool::lp_token_supply(pool)));

        liquidity_pool::set_pool(pool, 99, 0, 0, 10826830311966, 10830634846);
        print(&string_utils::format1(&b"lp_token_supply {}", liquidity_pool::lp_token_supply(pool)));

        remove_liquidity_entry(alice, pool, 2982603058);

    }

    #[test(fx = @endless_framework, alice = @0xcafe, bob = @0xface)]
    fun test_basic_swap_flow(
        fx: &signer,
        alice: &signer,
        bob: &signer,
    ) {
        randomness::initialize_for_testing(fx);

        let (usdt, eds) = create_base_coins(alice, bob);
        setup_dex();

        let alice_address = signer::address_of(alice);
        let bob_address = signer::address_of(bob);
        transfer(alice, usdt, bob_address, from_coin(5000, usdt));
        transfer(bob, eds, alice_address, from_coin(5000, eds));

        router::create_pool(alice, usdt, eds, from_coin(100000000, usdt), from_coin(950, eds));
        let pool = liquidity_pool::liquidity_pool_address(eds, usdt);

        router::add_pair_liquidity_entry(alice, pool, from_coin(1, eds), from_coin(100, usdt));
        router::add_single_liquidity_entry(alice, pool, usdt, from_coin(100, usdt));
        router::add_pair_liquidity_entry(alice, pool, from_coin(1, eds), from_coin(100, usdt));
        router::add_single_liquidity_entry(alice, pool, usdt, from_coin(100, usdt));
        router::add_pair_liquidity_entry(alice, pool, from_coin(2, eds), from_coin(300, usdt));


        router::swap_exact_in_entry(bob, usdt, eds, from_coin(200, usdt), 0);
        let pool = liquidity_pool::liquidity_pool_address(eds, usdt);
        let pool_obj = object::address_to_object<LiquidityPool>(pool);
        print(&string_utils::format1(&b"dao_fee_balance {}", liquidity_pool::dao_fee_balance()));

        router::add_single_liquidity_entry(alice, pool, eds, from_coin(4, eds));
        router::swap_exact_out_entry(bob, usdt, eds, from_coin(1, eds), from_coin(1000000000000, usdt));
        let pre_calc_in = liquidity_pool::get_amount_in_pre_swap_calc_detail(pool, usdt, 11111111);
        print(&string_utils::format1(&b"get_amount_in_pre_swap_calc_detail {}", pre_calc_in));
        let pre_calc_in = liquidity_pool::get_amount_in_pre_swap_calc_detail(pool, usdt, from_coin(1, eds));
        print(&string_utils::format1(&b"get_amount_in_pre_swap_calc_detail {}", pre_calc_in));

        let pre_calc_out = liquidity_pool::get_amount_out_pre_swap_calc_detail(pool, usdt, from_coin(100, usdt));
        print(&string_utils::format1(&b"get_amount_out_pre_swap_calc_detail {}", pre_calc_out));
        let pre_calc_out = liquidity_pool::get_amount_out_pre_swap_calc_detail(pool, usdt, from_coin(200, usdt));
        print(&string_utils::format1(&b"get_amount_out_pre_swap_calc_detail {}", pre_calc_out));
        router::swap_exact_out_entry(bob, usdt, eds, from_coin(1, eds), from_coin(1000000000000, usdt));

        print(&string_utils::format1(&b"lp_token_supply {}", liquidity_pool::lp_token_supply(pool)));
        print(&string_utils::format1(&b"lp_alice {}", primary_fungible_store::balance(alice_address, pool_obj)));
        print(&string_utils::format1(&b"lp_bob {}", primary_fungible_store::balance(bob_address, pool_obj)));

        router::add_pair_liquidity_entry(bob, pool, from_coin(1, eds), from_coin(300, usdt));
        router::add_pair_liquidity_entry(bob, pool, from_coin(3, eds), from_coin(100, usdt));


        router::remove_liquidity_entry(alice, pool, primary_fungible_store::balance(alice_address, pool_obj));
        assert!(primary_fungible_store::balance(alice_address, pool_obj) == 0, E_TEST_FAILED);

        print(&string_utils::format1(&b"lp_token_supply after alice remove {}", liquidity_pool::lp_token_supply(pool)));
        let (reserve_1, reserve_2) = liquidity_pool::pool_reserves(pool);
        print(&string_utils::format2(&b"reserve_1 {}, reserve_2 {}", reserve_1, reserve_2));
        let (total_reserve_1, total_reserve_2) = liquidity_pool::pool_total_reserves(pool);
        print(&string_utils::format2(&b"total_reserve_1 {}, total_reserve_2 {}", total_reserve_1, total_reserve_2));

        router::add_pair_liquidity_entry(bob, pool, from_coin(100000000, eds), from_coin(100000000, usdt));
        for (i in 0..9) {
            router::add_single_liquidity_entry(bob, pool, usdt, from_coin(100000000, usdt));
            router::add_single_liquidity_entry(bob, pool, eds, from_coin(100000000, eds));

            let usdt_m = randomness::u128_integer() % math128::pow(
                10,
                (fungible_asset::decimals(usdt) as u128)
            ) * 10000000;

            if (get_token_reserve(pool, usdt) < usdt_m) {
                router::add_single_liquidity_entry(bob, pool, usdt, usdt_m * 2);
            };
            router::swap_exact_out_entry(alice, eds, usdt, usdt_m, from_coin(1000000000, eds));

            let eth_m = randomness::u128_integer() % math128::pow(10, (fungible_asset::decimals(eds) as u128));
            if (get_token_reserve(pool, eds) < eth_m) {
                router::add_single_liquidity_entry(bob, pool, eds, eth_m * 2);
            };

            router::swap_exact_out_entry(bob, usdt, eds, eth_m, from_coin(1000000000, usdt));
        };

        router::remove_liquidity_entry(bob, pool, primary_fungible_store::balance(bob_address, pool_obj));
        assert!(primary_fungible_store::balance(bob_address, pool_obj) == 0, E_TEST_FAILED);

        liquidity_pool::claim_fees();
    }

    fun get_token_reserve(pool: address, token: Object<Metadata>): u128 {
        let (t0, t1) = pool_tokens(pool);
        let (r0, r1) = pool_reserves(pool);
        if (t0 == token) {
            r0
        } else if (t1 == token) {
            r1
        } else {
            0
        }
    }

    #[test(alice = @0xcafe, bob = @0xface)]
    fun test_mult_hop_swap(
        alice: &signer,
        bob: &signer,
    ) {
        let (usdt, eds) = create_base_coins(alice, bob);
        let (btc, eth) = create_ex_coins(alice, bob);

        setup_dex();
        router::create_pool(alice, usdt, eds, from_coin(10_000_000, usdt), from_coin(100_000_000, eds));
        router::create_pool(alice, btc, eds, from_coin(100, btc), from_coin(95000000, eds));
        router::create_pool(alice, eth, eds, from_coin(100, eth), from_coin(2500000, eds));


        let pool_eds_usdt = liquidity_pool::liquidity_pool_address(eds, usdt);
        let _pool_eds_btc = liquidity_pool::liquidity_pool_address(eds, btc);
        let pool_eds_eth = liquidity_pool::liquidity_pool_address(eds, eth);

        {
            let pre_calc = liquidity_pool::get_amount_in_multi_pools_pre_swap_calc_detail(
                vector[pool_eds_eth, pool_eds_usdt],
                usdt,
                from_coin(2500, usdt)
            );

            print(
                &string_utils::format1(
                    &b"get_amount_in_multi_pools_pre_swap_calc_detail {} ",
                    pre_calc
                )
            );
        };

        {
            let (amount_in, fee) = liquidity_pool::calc_amount_in_and_fees_multi_pools(
                vector[pool_eds_eth, pool_eds_usdt],
                usdt,
                from_coin(2500, usdt)
            );

            print(
                &string_utils::format2(
                    &b"calc_amount_in_and_fees_multi_pools {} {}",
                    amount_in, fee
                )
            );
        };


        {
            let (amount_in, total_dao_fee, sum_base_fee, sum_dynamic_fee) = liquidity_pool::swap_exact_out_multi_pools(
                alice,
                vector[pool_eds_eth, pool_eds_usdt],
                usdt,
                from_coin(2500, usdt)
            );

            print(
                &string_utils::format4(
                    &b"swap_exact_out_multi_pools {} {} {} {}",
                    amount_in, total_dao_fee, sum_base_fee, sum_dynamic_fee
                )
            );
        };



        {
            let pre_calc = liquidity_pool::get_amount_out_multi_pools_pre_swap_calc_detail(
                vector[pool_eds_usdt, pool_eds_eth],
                usdt,
                from_coin(2500, usdt)
            );

            print(
                &string_utils::format1(
                    &b"get_amount_out_multi_pools_pre_swap_calc_detail {} ",
                    pre_calc
                )
            );
        };

        {
            let (amount_out, fee) = liquidity_pool::calc_amount_out_and_fees_multi_pools(
                vector[pool_eds_usdt, pool_eds_eth],
                usdt,
                from_coin(2500, usdt)
            );

            print(
                &string_utils::format2(
                    &b"calc_amount_out_and_fees_multi_pools {} {} ",
                    amount_out, fee
                )
            );
        };

        {
            let (amount_out, total_dao_fee, sum_base_fee, sum_dynamic_fee) = liquidity_pool::swap_exact_in_multi_pools(
                alice,
                vector[pool_eds_usdt, pool_eds_eth],
                usdt,
                from_coin(2500, usdt)
            );

            print(
                &string_utils::format4(
                    &b"swap_exact_in_multi_pools {} {} {} {}",
                    amount_out, total_dao_fee, sum_base_fee, sum_dynamic_fee
                )
            );
        };
    }

    #[test(alice = @0xcafe, bob = @0xface)]
    fun test_one_hop_swap(
        alice: &signer,
        bob: &signer,
    ) {
        let (usdt, eds) = create_base_coins(alice, bob);
        let (btc, eth) = create_ex_coins(alice, bob);

        setup_dex();
        router::create_pool(alice, usdt, eds, from_coin(10000000, usdt), from_coin(100000000, eds));
        router::create_pool(alice, btc, eds, from_coin(10, btc), from_coin(9500000, eds));
        router::create_pool(alice, eth, eds, from_coin(10, eth), from_coin(250000, eds));


        let pool_eds_usdt = liquidity_pool::liquidity_pool_address(eds, usdt);

        {
            let (amount_in, fee) = liquidity_pool::calc_amount_in_and_fees_multi_pools(
                vector[pool_eds_usdt],
                usdt,
                from_coin(1, usdt)
            );

            print(
                &string_utils::format2(
                    &b"calc_amount_in_and_fees_multi_pools {} {}",
                    amount_in, fee
                )
            );
        };


        {
            let (amount_in, total_dao_fee, sum_base_fee, sum_dynamic_fee) = liquidity_pool::swap_exact_out_multi_pools(
                alice,
                vector[pool_eds_usdt],
                usdt,
                from_coin(1, usdt)
            );

            print(
                &string_utils::format4(
                    &b"swap_exact_out_multi_pools {} {} {} {}",
                    amount_in, total_dao_fee, sum_base_fee, sum_dynamic_fee
                )
            );
        };


        {
            let (amount_out, fee) = liquidity_pool::calc_amount_out_and_fees_multi_pools(
                vector[pool_eds_usdt],
                usdt,
                from_coin(1, usdt)
            );

            print(
                &string_utils::format2(
                    &b"calc_amount_out_and_fees_multi_pools {} {} ",
                    amount_out, fee
                )
            );
        };

        {
            let (amount_out, total_dao_fee, sum_base_fee, sum_dynamic_fee) = liquidity_pool::swap_exact_in_multi_pools(
                alice,
                vector[pool_eds_usdt],
                usdt,
                from_coin(1, usdt)
            );

            print(
                &string_utils::format4(
                    &b"swap_exact_in_multi_pools {} {} {} {}",
                    amount_out, total_dao_fee, sum_base_fee, sum_dynamic_fee
                )
            );
        };
    }
}

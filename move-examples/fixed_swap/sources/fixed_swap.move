module fixed_swap::fixed_swap {
    use endless_framework::account::{Self, SignerCapability};
    use endless_framework::endless_coin;
    use endless_framework::event;
    use endless_framework::fungible_asset::{Self, Metadata};
    use endless_framework::object::{Self, Object};
    use endless_framework::primary_fungible_store;
    use endless_framework::transaction_context;

    use endless_std::table::{Self, Table};
    use endless_std::math128;

    use std::signer;

    // config table uninitialized
    const EUNINITIALIZED: u64 = 0;
    // config table does not contains the coin
    const EUNSPORTED_COIN: u64 = 1;
    // the amount is out of range
    const EAMOUNT_OUT_OF_RANGE: u64 = 2;
    // the gas price is too high
    const EGAS_PRICE_TOO_HIGH: u64 = 3;
    // the amount is out of rice
    const EOUT_OF_PRICE: u64 = 4;
    // permission denied, only admin can call this function
    const EPERMISSION_DENIED: u64 = 5;
    // rate_numerator or rate_denominator invalid
    const EINVALID_RATE: u64 = 6;

    //
    // Constants
    //
    /// EDS decimals
    const EDS_DECIMALS: u8 = 8;

    /// Record admin account which can change the configuration
    struct AdminCap has key, copy, drop {
        admin: address,
    }

    /// The configuration of a fixed swap pair
    struct FixedSwapConfig has store, drop {
        /// Swap rate
        /// amount_out = amount_in * rate_numerator / rate_denominator
        rate_numerator: u128,
        rate_denominator: u128,
        /// Minimum amount_in
        min: u128,
        /// Maximum amount_in
        max: u128,
    }

    /// Fixed swap configuration table
    /// Coin -> FixedSwapConfig
    struct FixedSwapConfigTable has key {
        inner: Table<Object<Metadata>, FixedSwapConfig>,
    }

    struct FundingAccount has key {
        // receive coins from swap
        recipient: address,
        // sender is a resource account that holds the EDS.
        sender_cap: SignerCapability,
    }

    #[event]
    /// Emitted when a swap is made.
    struct Swap has drop, store {
        account: address,
        amount_in: u128,
        metadata_in: Object<Metadata>,
        amount_out: u128,
        metadata_out: Object<Metadata>,
    }

    #[event]
    /// Emitted when a configuration is updated.
    struct ConfigUpdated has store, drop {
        metadata: Object<Metadata>,
        rate_numerator: u128,
        rate_denominator: u128,
        min: u128,
        max: u128,
    }

    #[event]
    /// Emitted when a configuration is removed.
    struct ConfigRemoved has store, drop {
        metadata: Object<Metadata>,
    }

    #[event]
    /// Emitted when admin is changed.
    struct AdminChanged has store, drop {
        old: address,
        new: address,
    }

    /// Create funding resource account
    /// Constructor of FixedSwapConfigTable and FundingAccount
    /// Set admin permission 
    fun init_module(self: &signer) {
        let (_, funding_cap) = account::create_resource_account(self, b"fixed_swap funding account");
        move_to(self, FundingAccount {
            recipient: signer::address_of(self),
            sender_cap: funding_cap,
        });
        move_to(self, FixedSwapConfigTable {
            inner: table::new(),
        });
        move_to(self, AdminCap { admin: signer::address_of(self) });
    }

    #[view]
    /// Get funding account address
    public fun funding_address(): address acquires FundingAccount {
        assert!(exists<FundingAccount>(@fixed_swap), EUNINITIALIZED);
        let cap = &borrow_global<FundingAccount>(@fixed_swap).sender_cap;
        account::get_signer_capability_address(cap)
    }

    #[view]
    /// Get amount out from specific pair and amount in
    public fun get_amount_out(metadata: address, amount_in: u128): u128 acquires FixedSwapConfigTable {
        let metadata = object::address_to_object<Metadata>(metadata);
        let config = borrow_config(metadata);
        let amount_out = multiply_rate(amount_in, config);
        amount_out
    }

    /// Swap EDS from other coins with a fixed rate
    public entry sponsored fun fixed_swap(
        caller: &signer,
        // Avoid using Object<T> at the entry function
        metadata_in: address,
        amount_in: u128,
        expected_amount_out: u128
    ) acquires FixedSwapConfigTable, FundingAccount {
        let metadata_in = object::address_to_object<Metadata>(metadata_in);
        fixed_swap_internal(caller, metadata_in, amount_in, expected_amount_out);
    }

    /// Create or Update a config by admin
    public entry fun upsert_config(
        admin: &signer,
        // Avoid using Object<T> at the entry function
        metadata: address,
        rate_numerator: u128,
        rate_denominator: u128,
        min: u128,
        max: u128
    ) acquires FixedSwapConfigTable, AdminCap {
        assert_admin(admin);
        assert!(rate_numerator != 0, EINVALID_RATE);
        assert!(rate_denominator != 0, EINVALID_RATE);
        let metadata = object::address_to_object<Metadata>(metadata);
        // src coin decimals
        let src_decimals = fungible_asset::decimals(metadata);
        if (src_decimals < EDS_DECIMALS) {
            rate_numerator = rate_numerator * math128::pow(10, ((EDS_DECIMALS - src_decimals) as u128));
        } else if (src_decimals > EDS_DECIMALS) {
            rate_denominator = rate_denominator * math128::pow(10, ((src_decimals - EDS_DECIMALS) as u128));
        };

        let config_table = borrow_config_table_mut();
        table::upsert(&mut config_table.inner, metadata, FixedSwapConfig {
            rate_numerator,
            rate_denominator,
            min,
            max,
        });

        event::emit(ConfigUpdated {
            metadata,
            rate_numerator,
            rate_denominator,
            min,
            max,
        });
    }

    /// Remove a config by admin
    /// Aborts if config not exists
    public entry fun remove_config(admin: &signer, metadata: address) acquires FixedSwapConfigTable, AdminCap {
        assert_admin(admin);
        let metadata = object::address_to_object<Metadata>(metadata);
        let config_table = borrow_config_table_mut();
        table::remove(&mut config_table.inner, metadata);

        event::emit(ConfigRemoved {
            metadata,
        });
    }

    /// Transfer admin cap to another account
    public entry fun transfer_admin_cap(admin: &signer, new_admin: address) acquires AdminCap {
        assert_admin(admin);
        let cap = borrow_global_mut<AdminCap>(@fixed_swap);
        cap.admin = new_admin;

        event::emit(AdminChanged {
            old: signer::address_of(admin),
            new: new_admin,
        });
    }

    public entry fun set_recipient(admin: &signer, recipient: address) acquires AdminCap, FundingAccount {
        assert_admin(admin);
        let funding_account = borrow_global_mut<FundingAccount>(@fixed_swap);
        funding_account.recipient = recipient;
    }

    fun fixed_swap_internal(
        caller: &signer,
        metadata_in: Object<Metadata>,
        amount_in: u128,
        expected_amount_out: u128
    ) acquires FixedSwapConfigTable, FundingAccount {
        // abort if config table uninitialized or coin not supported
        let config = borrow_config(metadata_in);

        // check amount_in
        assert!(amount_in >= config.min, EAMOUNT_OUT_OF_RANGE);
        assert!(amount_in <= config.max, EAMOUNT_OUT_OF_RANGE);

        // check amount_out
        let amount_out = multiply_rate(amount_in, config);
        assert!(amount_out == expected_amount_out, EOUT_OF_PRICE);

        let (recipient, sender_signer) = borrow_funding_account();
        // receiving
        primary_fungible_store::transfer(caller, metadata_in, recipient, amount_in);
        // sending
        endless_coin::transfer(sender_signer, signer::address_of(caller), amount_out);

        event::emit(Swap {
            account: signer::address_of(caller),
            amount_in,
            metadata_in,
            amount_out,
            metadata_out: endless_coin::get_metadata(),
        });
    }

    inline fun assert_admin(admin: &signer) acquires AdminCap {
        assert!(exists<AdminCap>(@fixed_swap), EUNINITIALIZED);
        assert!(borrow_global<AdminCap>(@fixed_swap).admin == signer::address_of(admin), EPERMISSION_DENIED);
    }

    inline fun borrow_config(metadata: Object<Metadata>): &FixedSwapConfig acquires FixedSwapConfigTable {
        assert!(exists<FixedSwapConfigTable>(@fixed_swap), EUNINITIALIZED);
        let config_table = borrow_global<FixedSwapConfigTable>(@fixed_swap);
        assert!(table::contains(&config_table.inner, metadata), EUNSPORTED_COIN);
        table::borrow(&config_table.inner, metadata)
    }

    inline fun borrow_config_table_mut(): &mut FixedSwapConfigTable acquires FixedSwapConfigTable {
        assert!(exists<FixedSwapConfigTable>(@fixed_swap), EUNINITIALIZED);
        borrow_global_mut<FixedSwapConfigTable>(@fixed_swap)
    }

    inline fun borrow_funding_account(): (address, &signer) acquires FundingAccount {
        assert!(exists<FundingAccount>(@fixed_swap), EUNINITIALIZED);
        let funding_account = borrow_global<FundingAccount>(@fixed_swap);
        let recipient = funding_account.recipient;
        let sender = &account::create_signer_with_capability(&funding_account.sender_cap);
        (recipient, sender)
    }

    inline fun multiply_rate(amount_in: u128, config: &FixedSwapConfig): u128 {
        amount_in * config.rate_numerator / config.rate_denominator
    }

    #[test_only]
    use std::string;
    #[test_only]
    use std::option;

    #[test_only]
    fun init_test_coin(creator: &signer, decimals: u8): (fungible_asset::MintRef, Object<Metadata>) {
        account::create_account_for_test(signer::address_of(creator));
        let constructor_ref = object::create_sticky_object(signer::address_of(creator));
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(), // max supply
            string::utf8(b"TEST COIN"),
            string::utf8(b"@T"),
            decimals,
            string::utf8(b"http://example.com/icon"),
            string::utf8(b"http://example.com"),
        );
        let mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);
        let metadata = object::object_from_constructor_ref<Metadata>(&constructor_ref);
        (mint_ref, metadata)
    }

    #[test_only]
    fun initialize_for_test(endless_framework: &signer, fixed_swap: &signer)
        acquires AdminCap, FundingAccount {
        init_module(fixed_swap);
        assert!(borrow_global<AdminCap>(@fixed_swap).admin == @fixed_swap, 1);
        let (eds_mint_ref, _, _) = endless_coin::initialize_for_test(endless_framework);
        let funding_addr = funding_address();
        primary_fungible_store::mint(&eds_mint_ref, funding_addr, 100000000);
    }

    #[test(endless_framework = @0x1, admin = @0xcafe, user = @0xface)]
    fun test_admin_cap(endless_framework: signer, admin: signer, user: signer)
        acquires AdminCap, FixedSwapConfigTable, FundingAccount {
        initialize_for_test(&endless_framework, &admin);
        let (_, test_coin) = init_test_coin(&admin, 8);
        let test_coin_addr = object::object_address(&test_coin);
        upsert_config(&admin, test_coin_addr, 1, 2, 10, 100);
        transfer_admin_cap(&admin, signer::address_of(&user));
        remove_config(&user, test_coin_addr);
    }

    #[test(endless_framework = @0x1, admin = @0xcafe, user = @0xface)]
    #[expected_failure(abort_code = 5, location = Self)]
    fun test_admin_cap_fail(endless_framework: signer, admin: signer, user: signer)
        acquires AdminCap, FixedSwapConfigTable, FundingAccount {
        initialize_for_test(&endless_framework, &admin);
        let (_, test_coin) = init_test_coin(&admin, 8);
        let test_coin_addr = object::object_address(&test_coin);
        upsert_config(&admin, test_coin_addr, 1, 2, 10, 100);
        transfer_admin_cap(&admin, signer::address_of(&user));
        // abort: use old admin after transfer_admin_cap
        remove_config(&admin, test_coin_addr);
    }

    #[test(endless_framework = @0x1, admin = @0xcafe, user = @0xface)]
    fun test_upsert_config(endless_framework: signer, admin: signer, user: signer)
        acquires AdminCap, FixedSwapConfigTable, FundingAccount {
        initialize_for_test(&endless_framework, &admin);

        let (test_mint_ref, test_coin) = init_test_coin(&admin, 8);
        let test_coin_addr = object::object_address(&test_coin);
        primary_fungible_store::mint(&test_mint_ref, signer::address_of(&user), 100);
        upsert_config(&admin, test_coin_addr, 1, 2, 10, 100);
        fixed_swap_internal(&user, test_coin, 50, 25);
        upsert_config(&admin, test_coin_addr, 2, 1, 10, 100);
        fixed_swap_internal(&user, test_coin, 50, 100);

        let (test_mint_ref, test_coin) = init_test_coin(&admin, 9);
        let test_coin_addr = object::object_address(&test_coin);
        primary_fungible_store::mint(&test_mint_ref, signer::address_of(&user), 1000000000); // 1.0
        upsert_config(&admin, test_coin_addr, 1, 2, 10, 1000000000);
        fixed_swap_internal(&user, test_coin, 100000000, 5000000); // 0.1 -> 0.05 EDS

        let (test_mint_ref, test_coin) = init_test_coin(&admin, 7);
        let test_coin_addr = object::object_address(&test_coin);
        primary_fungible_store::mint(&test_mint_ref, signer::address_of(&user), 10000000); // 1.0
        upsert_config(&admin, test_coin_addr, 3, 1, 10, 1000000000);
        fixed_swap_internal(&user, test_coin, 1000000, 30000000); // 0.1 -> 0.3 EDS
    }

    #[test(endless_framework = @0x1, admin = @0xcafe, user = @0xface)]
    #[expected_failure(abort_code = 5, location = Self)]
    fun test_non_admin_upsert_config(endless_framework: signer, admin: signer, user: signer)
        acquires AdminCap, FixedSwapConfigTable, FundingAccount {
        initialize_for_test(&endless_framework, &admin);

        let (_, test_coin) = init_test_coin(&admin, 8);
        let test_coin_addr = object::object_address(&test_coin);
        upsert_config(&user, test_coin_addr, 1, 2, 10, 100);
    }

    #[test(endless_framework = @0x1, admin = @0xcafe, user = @0xface)]
    #[expected_failure(abort_code = 1, location = Self)]
    fun test_remove_config(endless_framework: signer, admin: signer, user: signer)
        acquires AdminCap, FixedSwapConfigTable, FundingAccount {
        initialize_for_test(&endless_framework, &admin);

        let (test_mint_ref, test_coin) = init_test_coin(&admin, 8);
        let test_coin_addr = object::object_address(&test_coin);
        primary_fungible_store::mint(&test_mint_ref, signer::address_of(&user), 100);
        upsert_config(&admin, test_coin_addr, 1, 2, 10, 100);
        fixed_swap_internal(&user, test_coin, 50, 25);
        remove_config(&admin, test_coin_addr);
        fixed_swap_internal(&user, test_coin, 50, 0);
    }

    #[test(endless_framework = @0x1, admin = @0xcafe, user = @0xface)]
    #[expected_failure(abort_code = 5, location = Self)]
    fun test_non_admin_remove_config(endless_framework: signer, admin: signer, user: signer)
        acquires AdminCap, FixedSwapConfigTable, FundingAccount {
        initialize_for_test(&endless_framework, &admin);

        let (_, test_coin) = init_test_coin(&admin, 8);
        let test_coin_addr = object::object_address(&test_coin);
        upsert_config(&admin, test_coin_addr, 1, 2, 10, 100);
        remove_config(&user, test_coin_addr);
    }

    #[test(endless_framework = @0x1, admin = @0xcafe, user = @0xface)]
    fun test_fixed_swap(endless_framework: signer, admin: signer, user: signer)
        acquires AdminCap, FixedSwapConfigTable, FundingAccount {
        initialize_for_test(&endless_framework, &admin);
        
        let funding_addr = funding_address();
        assert!(endless_coin::balance(funding_addr) == 100000000, 1);

        let user_addr = signer::address_of(&user);
        let (test_mint_ref, test_coin) = init_test_coin(&admin, 8);
        let test_coin_addr = object::object_address(&test_coin);
        primary_fungible_store::mint(&test_mint_ref, user_addr, 100);

        let eds_balance = endless_coin::balance(user_addr);
        let test_balance = primary_fungible_store::balance(user_addr, test_coin);
        assert!(eds_balance == 0, 1);
        assert!(test_balance == 100, 1);

        upsert_config(&admin, test_coin_addr, 1, 5, 10, 100);
        fixed_swap_internal(&user, test_coin, 50, 10);
        eds_balance = endless_coin::balance(user_addr);
        test_balance = primary_fungible_store::balance(user_addr, test_coin);
        assert!(eds_balance == 10, 1);
        assert!(test_balance == 50, 1);
        assert!(endless_coin::balance(funding_addr) == 100000000-10, 1);

        upsert_config(&admin, test_coin_addr, 2, 1, 10, 100);
        fixed_swap_internal(&user, test_coin, 50, 100);
        eds_balance = endless_coin::balance(user_addr);
        test_balance = primary_fungible_store::balance(user_addr, test_coin);
        assert!(eds_balance == 110, 1);
        assert!(test_balance == 0, 1);
        assert!(endless_coin::balance(funding_addr) == 100000000-110, 1);
    }
}
module endless_framework::endless_account {
    use endless_framework::account::Self;
    use endless_framework::endless_coin;
    use endless_framework::object::{Self, Object};
    use endless_framework::event::emit;
    use endless_framework::fungible_asset::{Self, FungibleAsset, Metadata};
    use endless_framework::primary_fungible_store;
    use std::error;
    use std::signer;
    use std::vector;

    friend endless_framework::genesis;
    friend endless_framework::resource_account;

    /// Account does not exist.
    const EACCOUNT_NOT_FOUND: u64 = 1;
    /// Account is not registered to receive EDS.
    const EACCOUNT_NOT_REGISTERED_FOR_EDS: u64 = 2;
    /// Account opted out of receiving coins that they did not register to receive.
    const EACCOUNT_DOES_NOT_ACCEPT_DIRECT_COIN_TRANSFERS: u64 = 3;
    /// Account opted out of directly receiving NFT tokens.
    const EACCOUNT_DOES_NOT_ACCEPT_DIRECT_TOKEN_TRANSFERS: u64 = 4;
    /// The lengths of the recipients and amounts lists don't match.
    const EMISMATCHING_RECIPIENTS_AND_AMOUNTS_LENGTH: u64 = 5;
    /// Object exists.
    const EOBJECT_EXISTS: u64 = 6;

    /// Configuration for whether an account can receive direct transfers of coins that they have not registered.
    ///
    /// By default, this is enabled. Users can opt-out by disabling at any time.
    struct DirectTransferConfig has key {
        allow_arbitrary_coin_transfers: bool,
    }

    /// Event emitted when an account's direct coins transfer config is updated.
    struct DirectCoinTransferConfigUpdatedEvent has drop, store {
        new_allow_direct_transfers: bool,
    }

    #[event]
    struct AllowDirectTransfers has drop, store {
        account: address,
        new_allow_direct_transfers: bool,
    }

    ///////////////////////////////////////////////////////////////////////////
    /// Basic account creation methods.
    ///////////////////////////////////////////////////////////////////////////

    public entry fun create_account(auth_key: address) {
        assert!(!object::is_object(auth_key), error::invalid_argument(EOBJECT_EXISTS));
        let signer = account::create_account(auth_key);
        primary_fungible_store::ensure_primary_store_exists(signer::address_of(&signer), endless_coin::get_metadata());
    }

    /// Batch version of EDS transfer.
    public entry fun batch_transfer(source: &signer, recipients: vector<address>, amounts: vector<u128>) {
        let recipients_len = vector::length(&recipients);
        assert!(
            recipients_len == vector::length(&amounts),
            error::invalid_argument(EMISMATCHING_RECIPIENTS_AND_AMOUNTS_LENGTH),
        );

        vector::enumerate_ref(&recipients, |i, to| {
            let amount = *vector::borrow(&amounts, i);
            transfer(source, *to, amount);
        });
    }

    /// Convenient function to transfer EDS to a recipient account that might not exist.
    /// This would create the recipient account first, which also registers it to receive EDS, before transferring.
    public entry fun transfer(source: &signer, to: address, amount: u128) {
        if (!account::exists_at(to)) {
            create_account(to)
        };
        primary_fungible_store::transfer(source, endless_coin::get_metadata(), to, amount);
    }

    /// Batch version of transfer_coins.
    public entry fun batch_transfer_coins<T: key>(
        from: &signer, recipients: vector<address>, amounts: vector<u128>, metadata: Object<T>) acquires DirectTransferConfig {
        let recipients_len = vector::length(&recipients);
        assert!(
            recipients_len == vector::length(&amounts),
            error::invalid_argument(EMISMATCHING_RECIPIENTS_AND_AMOUNTS_LENGTH),
        );

        vector::enumerate_ref(&recipients, |i, to| {
            let amount = *vector::borrow(&amounts, i);
            transfer_coins(from, *to, amount, metadata);
        });
    }

    /// Convenient function to transfer a custom CoinType to a recipient account that might not exist.
    /// This would create the recipient account first and register it to receive the CoinType, before transferring.
    public entry fun transfer_coins<T: key>(from: &signer, to: address, amount: u128, metadata: Object<T>) acquires DirectTransferConfig {
        let fa = primary_fungible_store::withdraw(from, metadata, amount);
        spec {
            assume fa.metadata.inner == metadata.inner;
        };
        deposit_coins(to, fa);
    }

    /// Convenient function to deposit a custom CoinType into a recipient account that might not exist.
    /// This would create the recipient account first and register it to receive the CoinType, before transferring.
    public fun deposit_coins(to: address, coins: FungibleAsset) acquires DirectTransferConfig {
        if (!account::exists_at(to)) {
            create_account(to);
        };
        let fa_metadata = fungible_asset::asset_metadata(&coins);
        if (!primary_fungible_store::primary_store_exists<Metadata>(to, fa_metadata)) {
            assert!(
                can_receive_direct_coin_transfers(to),
                error::permission_denied(EACCOUNT_DOES_NOT_ACCEPT_DIRECT_COIN_TRANSFERS),
            );
            primary_fungible_store::create_primary_store(to, fa_metadata);
        };
        primary_fungible_store::deposit(to, coins)
    }

    public fun assert_account_exists(addr: address) {
        assert!(account::exists_at(addr), error::not_found(EACCOUNT_NOT_FOUND));
    }

    public fun assert_account_is_registered_for_eds(addr: address) {
        assert_account_exists(addr);
        assert!(primary_fungible_store::primary_store_exists(addr, endless_coin::get_metadata()), error::not_found(EACCOUNT_NOT_REGISTERED_FOR_EDS));
    }

    /// Set whether `account` can receive direct transfers of coins that they have not explicitly registered to receive.
    public entry fun set_allow_direct_coin_transfers(account: &signer, allow: bool) acquires DirectTransferConfig {
        let addr = signer::address_of(account);
        if (exists<DirectTransferConfig>(addr)) {
            let direct_transfer_config = borrow_global_mut<DirectTransferConfig>(addr);
            // Short-circuit to avoid emitting an event if direct transfer config is not changing.
            if (direct_transfer_config.allow_arbitrary_coin_transfers == allow) {
                return
            };

            direct_transfer_config.allow_arbitrary_coin_transfers = allow;
            emit(AllowDirectTransfers { account: addr, new_allow_direct_transfers: allow });
        } else {
            let direct_transfer_config = DirectTransferConfig {
                allow_arbitrary_coin_transfers: allow,
            };
            emit(AllowDirectTransfers { account: addr, new_allow_direct_transfers: allow });
            move_to(account, direct_transfer_config);
        };
    }

    #[view]
    /// Return true if `account` can receive direct transfers of coins that they have not explicitly registered to
    /// receive.
    ///
    /// By default, this returns true if an account has not explicitly set whether the can receive direct transfers.
    public fun can_receive_direct_coin_transfers(account: address): bool acquires DirectTransferConfig {
        !exists<DirectTransferConfig>(account) ||
            borrow_global<DirectTransferConfig>(account).allow_arbitrary_coin_transfers
    }

    #[test_only]
    use endless_std::from_bcs;
    #[test_only]
    use endless_framework::account::create_account_for_test;

    #[test(alice = @0xa11ce, core = @0x1)]
    public fun test_transfer(alice: &signer, core: &signer) acquires DirectTransferConfig {
        let bob = from_bcs::to_address(x"0000000000000000000000000000000000000000000000000000000000000b0b");
        let carol = from_bcs::to_address(x"00000000000000000000000000000000000000000000000000000000000ca501");

        let (mint_cap,burn_cap, transfer_cap) = endless_framework::endless_coin::initialize_for_test(core);
        create_account(signer::address_of(alice));
        primary_fungible_store::mint(&mint_cap, signer::address_of(alice), 10000);
        transfer_coins(alice, bob, 500, endless_coin::get_metadata());
        assert!(endless_coin::balance(bob) == 500, 0);
        transfer_coins(alice, carol, 500, endless_coin::get_metadata());
        assert!(endless_coin::balance(carol) == 500, 1);
        transfer(alice, carol, 1500);
        assert!(endless_coin::balance(carol) == 2000, 2);

        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_burn_cap(burn_cap);
        fungible_asset::destroy_transfer_cap(transfer_cap);
    }

    #[test(alice = @0xa11ce, core = @0x1)]
    public fun test_transfer_to_resource_account(alice: &signer, core: &signer) {
        let (resource_account, _) = account::create_resource_account(alice, vector[]);
        let resource_acc_addr = signer::address_of(&resource_account);

        let ( mint_cap, burn_cap, transfer_cap) = endless_framework::endless_coin::initialize_for_test(core);
        create_account_for_test(signer::address_of(alice));
        primary_fungible_store::mint(&mint_cap, signer::address_of(alice), 10000);
        transfer(alice, resource_acc_addr, 500);
        assert!(endless_coin::balance(resource_acc_addr) == 500, 1);

        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_burn_cap(burn_cap);
        fungible_asset::destroy_transfer_cap(transfer_cap);
    }

    #[test(from = @0x123, core = @0x1, recipient_1 = @0x124, recipient_2 = @0x125)]
    public fun test_batch_transfer(from: &signer, core: &signer, recipient_1: &signer, recipient_2: &signer) {
        create_account_for_test(signer::address_of(from));
        let recipient_1_addr = signer::address_of(recipient_1);
        let recipient_2_addr = signer::address_of(recipient_2);
        create_account_for_test(recipient_1_addr);
        create_account_for_test(recipient_2_addr);

        let (mint_cap, burn_cap, transfer_cap) = endless_framework::endless_coin::initialize_for_test(core);
        primary_fungible_store::mint(&mint_cap, signer::address_of(from), 10000);

        batch_transfer(
            from,
            vector[recipient_1_addr, recipient_2_addr],
            vector[100, 500],
        );
        assert!(endless_coin::balance(recipient_1_addr) == 100, 0);
        assert!(endless_coin::balance(recipient_2_addr) == 500, 1);

        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_burn_cap(burn_cap);
        fungible_asset::destroy_transfer_cap(transfer_cap);
    }

    #[test(from = @0x1, to = @0x12)]
    public fun test_direct_coin_transfers(from: &signer, to: &signer) acquires DirectTransferConfig {
        use std::string;
        use std::option;

        let from_addr = signer::address_of(from);
        let to_addr = signer::address_of(to);
        create_account_for_test(from_addr);
        create_account_for_test(to_addr);

        let (constructor_ref, _) = fungible_asset::create_test_token(from);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::some(100000) /* max supply */,
            string::utf8(b"TEST"),
            string::utf8(b"@@"),
            0,
            string::utf8(b"http://www.example.com/favicon.ico"),
            string::utf8(b"http://www.example.com"),
        );
        let mint_cap = fungible_asset::generate_mint_ref(&constructor_ref);
        let burn_cap = fungible_asset::generate_burn_ref(&constructor_ref);
        let transfer_cap = fungible_asset::generate_transfer_ref(&constructor_ref);
        let metadata: Object<Metadata> = fungible_asset::mint_ref_metadata(&mint_cap);

        primary_fungible_store::mint(&mint_cap, from_addr, 1000);
        transfer_coins(from, to_addr, 500, metadata);

        // Recipient account did not explicit register for the coin.
        assert!(primary_fungible_store::balance(to_addr, metadata) == 500, 0);

        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_burn_cap(burn_cap);
        fungible_asset::destroy_transfer_cap(transfer_cap);
    }

    #[test(from = @0x1, recipient_1 = @0x124, recipient_2 = @0x125)]
    public fun test_batch_transfer_coins(
        from: &signer, recipient_1: &signer, recipient_2: &signer) acquires DirectTransferConfig {
        use std::string;
        use std::option;

        let from_addr = signer::address_of(from);
        let recipient_1_addr = signer::address_of(recipient_1);
        let recipient_2_addr = signer::address_of(recipient_2);
        create_account_for_test(from_addr);
        create_account_for_test(recipient_1_addr);
        create_account_for_test(recipient_2_addr);

        let (constructor_ref, _) = fungible_asset::create_test_token(from);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::some(100000) /* max supply */,
            string::utf8(b"TEST"),
            string::utf8(b"@@"),
            0,
            string::utf8(b"http://www.example.com/favicon.ico"),
            string::utf8(b"http://www.example.com"),
        );
        let mint_cap = fungible_asset::generate_mint_ref(&constructor_ref);
        let burn_cap = fungible_asset::generate_burn_ref(&constructor_ref);
        let transfer_cap = fungible_asset::generate_transfer_ref(&constructor_ref);
        let metadata: Object<Metadata> = fungible_asset::mint_ref_metadata(&mint_cap);

        primary_fungible_store::mint(&mint_cap, from_addr, 1000);
        batch_transfer_coins(
            from,
            vector[recipient_1_addr, recipient_2_addr],
            vector[100, 500],
            metadata
        );
        assert!(primary_fungible_store::balance(recipient_1_addr, metadata) == 100, 0);
        assert!(primary_fungible_store::balance(recipient_2_addr, metadata) == 500, 1);

        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_burn_cap(burn_cap);
        fungible_asset::destroy_transfer_cap(transfer_cap);
    }

    #[test(user = @0x123)]
    public fun test_set_allow_direct_coin_transfers(user: &signer) acquires DirectTransferConfig {
        let addr = signer::address_of(user);
        create_account_for_test(addr);
        set_allow_direct_coin_transfers(user, true);
        assert!(can_receive_direct_coin_transfers(addr), 0);
        set_allow_direct_coin_transfers(user, false);
        assert!(!can_receive_direct_coin_transfers(addr), 1);
        set_allow_direct_coin_transfers(user, true);
        assert!(can_receive_direct_coin_transfers(addr), 2);
    }

    #[test(from = @0x1, to = @0x12)]
    public fun test_direct_coin_transfers_with_explicit_direct_coin_transfer_config(
        from: &signer, to: &signer) acquires DirectTransferConfig {
        use std::string;
        use std::option;

        let from_addr = signer::address_of(from);
        let to_addr = signer::address_of(to);
        create_account_for_test(from_addr);
        create_account_for_test(to_addr);

        let (constructor_ref, _) = fungible_asset::create_test_token(from);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::some(100000) /* max supply */,
            string::utf8(b"TEST"),
            string::utf8(b"@@"),
            0,
            string::utf8(b"http://www.example.com/favicon.ico"),
            string::utf8(b"http://www.example.com"),
        );
        let mint_cap = fungible_asset::generate_mint_ref(&constructor_ref);
        let burn_cap = fungible_asset::generate_burn_ref(&constructor_ref);
        let transfer_cap = fungible_asset::generate_transfer_ref(&constructor_ref);
        let metadata: Object<Metadata> = fungible_asset::mint_ref_metadata(&mint_cap);

        primary_fungible_store::mint(&mint_cap, from_addr, 1000);
        set_allow_direct_coin_transfers(from, true);

        // Recipient account did not explicit register for the coin.
        transfer_coins(from, to_addr, 500, metadata);

        assert!(primary_fungible_store::balance(to_addr, metadata) == 500, 0);

        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_burn_cap(burn_cap);
        fungible_asset::destroy_transfer_cap(transfer_cap);
    }

    #[test(from = @0x1, to = @0x12)]
    #[expected_failure(abort_code = 0x50003, location = Self)]
    public fun test_direct_coin_transfers_fail_if_recipient_opted_out(
        from: &signer, to: &signer) acquires DirectTransferConfig {
        use std::string;
        use std::option;

        let from_addr = signer::address_of(from);
        let to_addr = signer::address_of(to);

        create_account_for_test(from_addr);
        create_account_for_test(to_addr);

        let (constructor_ref, _) = fungible_asset::create_test_token(from);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::some(100000) /* max supply */,
            string::utf8(b"TEST"),
            string::utf8(b"@@"),
            0,
            string::utf8(b"http://www.example.com/favicon.ico"),
            string::utf8(b"http://www.example.com"),
        );
        let mint_cap = fungible_asset::generate_mint_ref(&constructor_ref);
        let burn_cap = fungible_asset::generate_burn_ref(&constructor_ref);
        let transfer_cap = fungible_asset::generate_transfer_ref(&constructor_ref);

        set_allow_direct_coin_transfers(from, false);
        let fa = fungible_asset::mint(&mint_cap, 1000);
        // This should fail as the to account has explicitly opted out of receiving arbitrary coins.
        deposit_coins(from_addr, fa);

        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_burn_cap(burn_cap);
        fungible_asset::destroy_transfer_cap(transfer_cap);
    }

    #[test(user = @0xcafe)]
    #[expected_failure(abort_code = 0x10006, location = Self)]
    public fun test_create_account_exist_object(user: &signer) {
        let constructor_ref = object::create_named_object(user, b"seed");
        let obj_address = object::address_from_constructor_ref(&constructor_ref);
        create_account(obj_address);
    }
}

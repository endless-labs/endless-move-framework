// This module demonstrates a basic shared account that could be used for NFT royalties
// Users can (1) create a shared account (2) disperse the coins to multiple creators
module shared_account::SharedAccount {
    use std::error;
    use std::signer;
    use std::vector;
    use endless_framework::account;
    use endless_framework::endless_coin;

    // struct Share records the address of the share_holder and their corresponding number of shares
    struct Share has store {
        share_holder: address,
        num_shares: u128,
    }

    // Resource representing a shared account
    struct SharedAccount has key {
        share_record: vector<Share>,
        total_shares: u128,
        signer_capability: account::SignerCapability,
    }

    struct SharedAccountEvent has key {
        resource_addr: address,
    }

    const EACCOUNT_NOT_FOUND: u64 = 0;
    const ERESOURCE_DNE: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;

    // Create and initialize a shared account
    public entry fun initialize(source: &signer, seed: vector<u8>, addresses: vector<address>, numerators: vector<u128>) {
        let total = 0;
        let share_record = vector::empty<Share>();

        vector::enumerate_ref(&addresses, |i, addr|{
            let addr = *addr;
            let num_shares = *vector::borrow(&numerators, i);

            // make sure that the account exists, so when we call disperse() it wouldn't fail
            // because one of the accounts does not exist
            assert!(account::exists_at(addr), error::invalid_argument(EACCOUNT_NOT_FOUND));

            vector::push_back(&mut share_record, Share { share_holder: addr, num_shares });
            total = total + num_shares;
        });

        let (resource_signer, resource_signer_cap) = account::create_resource_account(source, seed);

        move_to(
            &resource_signer,
            SharedAccount {
                share_record,
                total_shares: total,
                signer_capability: resource_signer_cap,
            }
        );

        move_to(source, SharedAccountEvent {
            resource_addr: signer::address_of(&resource_signer)
        });
    }

    // Disperse all available balance to addresses in the shared account
    public entry fun disperse(resource_addr: address) acquires SharedAccount {
        assert!(exists<SharedAccount>(resource_addr), error::invalid_argument(ERESOURCE_DNE));

        let total_balance = endless_coin::balance(resource_addr);
        assert!(total_balance > 0, error::out_of_range(EINSUFFICIENT_BALANCE));

        let shared_account = borrow_global<SharedAccount>(resource_addr);
        let resource_signer = account::create_signer_with_capability(&shared_account.signer_capability);

        vector::for_each_ref(&shared_account.share_record, |shared_record|{
            let shared_record: &Share = shared_record;
            let current_amount = shared_record.num_shares * total_balance / shared_account.total_shares;
            endless_coin::transfer(&resource_signer, shared_record.share_holder, current_amount);
        });
    }

    #[test_only]
    public entry fun set_up(user: signer, test_user1: signer, test_user2: signer) : address acquires SharedAccountEvent {
        let addresses = vector::empty<address>();
        let numerators = vector::empty<u128>();
        let seed = x"01";
        let user_addr = signer::address_of(&user);
        let user_addr1 = signer::address_of(&test_user1);
        let user_addr2 = signer::address_of(&test_user2);

        endless_framework::endless_account::create_account(user_addr);
        endless_framework::endless_account::create_account(user_addr1);
        endless_framework::endless_account::create_account(user_addr2);

        vector::push_back(&mut addresses, user_addr1);
        vector::push_back(&mut addresses, user_addr2);

        vector::push_back(&mut numerators, 1);
        vector::push_back(&mut numerators, 4);
        initialize(&user, seed, addresses, numerators);

        assert!(exists<SharedAccountEvent>(user_addr), error::not_found(EACCOUNT_NOT_FOUND));
        borrow_global<SharedAccountEvent>(user_addr).resource_addr
    }

    #[test(user = @0x1111, test_user1 = @0x1112, test_user2 = @0x1113, core_framework = @endless_framework)]
    public entry fun test_disperse(user: signer, test_user1: signer, test_user2: signer, core_framework: signer) acquires SharedAccount, SharedAccountEvent {
        use endless_framework::endless_coin;
        use endless_framework::primary_fungible_store;
        use endless_framework::fungible_asset;
        let user_addr1 = signer::address_of(&test_user1);
        let user_addr2 = signer::address_of(&test_user2);
        let (mint_cap, burn_cap, _) = endless_coin::initialize_for_test(&core_framework);
        let resource_addr = set_up(user, test_user1, test_user2);

        let shared_account = borrow_global<SharedAccount>(resource_addr);
        account::create_signer_with_capability(&shared_account.signer_capability);
        primary_fungible_store::mint(&mint_cap, resource_addr, 1000);
        disperse(resource_addr);
        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_burn_cap(burn_cap);

        assert!(endless_coin::balance(user_addr1) == 200, 0);
        assert!(endless_coin::balance(user_addr2) == 800, 1);
    }

    #[test(user = @0x1111, test_user1 = @0x1112, test_user2 = @0x1113)]
    #[expected_failure]
    public entry fun test_disperse_insufficient_balance(user: signer, test_user1: signer, test_user2: signer) acquires SharedAccount, SharedAccountEvent {
        let resource_addr = set_up(user, test_user1, test_user2);
        let shared_account = borrow_global<SharedAccount>(resource_addr);
        account::create_signer_with_capability(&shared_account.signer_capability);
        disperse(resource_addr);
    }
}

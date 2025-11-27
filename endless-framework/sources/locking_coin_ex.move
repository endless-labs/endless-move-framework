module endless_framework::locking_coin_ex {
    use std::bcs;
    use endless_framework::timestamp;
    use std::signer::address_of;
    use std::vector;
    use endless_framework::endless_coin::get_eds_token_address;
    use endless_framework::object;
    use endless_framework::object::Object;
    use endless_framework::fungible_asset::Metadata;
    use endless_framework::primary_fungible_store;
    use endless_framework::create_signer;
    use endless_framework::reconfiguration;
    use endless_std::math128;
    use endless_std::smart_table::{Self, SmartTable};
    use endless_framework::account;
    use endless_framework::account::SignerCapability;
    use endless_framework::event;

    friend endless_framework::genesis;

    const ADMINISTRATOR: address = @endless_framework;

    const CONTRACT_NAME: vector<u8> = b"locking_coin_ex";

    /// No locked coins found to claim.
    const ELOCK_INFO_NOT_FOUND: u64 = 1;
    /// Lockup has not expired yet.
    const ELOCKUP_HAS_NOT_EXPIRED: u64 = 2;
    /// Can only create one active lock per recipient at once.
    const ELOCK_ALREADY_EXISTS: u64 = 3;
    /// Sponsor account has not been set up to create locks for the specified CoinType yet.
    const EADMIN_ACCOUNT_NOT_INITIALIZED: u64 = 4;
    /// Cannot update the withdrawal address because there are still active/unclaimed locks.
    const EACTIVE_LOCKS_EXIST: u64 = 5;
    /// admin has insufficient balance to disritute;
    const EINSUFFICIENT_BALANCE: u64 = 6;
    /// Sender is not administrator
    const ENOT_ADMINISDTATOR: u64 = 7;
    /// Address not in staker list;
    const ENOT_STAKER: u64 = 8;
    ///
    const ENO_CLAIM_AMONNT: u64 = 9;

    /// invalide data;
    const EINVALID_DATA: u64 = 10;

    const ETESER_FAILED: u64 = 20;

    // TODO add coin type arg
    struct LockingConfig has store, drop, copy {
        address: address,

        total_coins: u128,

        first_unlock_percent: u64,

        first_unlock_epoch: u64,

        stable_unlock_interval: u64,

        stable_unlock_periods: u64,
    }

    /// When staking, token will move to resource account which create by staker address and init_staking will record
    /// staking amount first time. Current amount of token still in staking record by curr_staking.
    struct StakerInfo has store, copy {
        config: LockingConfig,

        // Resource address of staker.
        resource_addr: address,

        // Amount still in resource account, locked + unlocked balance
        curr_balance: u128,
    }

    /// StakingPool store all staking info of all stakers.
    struct LockingSystem has key {
        token_pools: SmartTable<address, TokenPool>
    }

    struct TokenPool has store {
        // Map from recipient address => locked coins.
        stakers: SmartTable<address, StakerInfo>,

        /// Total amount of token in staking.
        total_locks: u128,
    }

    /// Signer capability of resource address wrapped by CapStore will move to 0x1.
    struct CapStore has key {
        signer_cap: SignerCapability,
    }

    /// Unlock amount and when to unlock.
    struct UnlockAt has drop {
        epoch: u64,
        amount: u128,
    }

    /// Unlocked token amount when and how much to unlock.
    struct UnlockInfo has drop {
        address: address,

        unlocked: u128,

        unlock_list: vector<UnlockAt>,
    }

    #[event]
    /// Event emitted when a recipient claims unlocked coins.
    struct Claim has drop, store {
        recipient: address,

        amount: u128,

        claim_epoch: u64,

        claimed_time_secs: u64,
    }

    #[view]
    /// Total amount token still locked.
    public fun total_locks(token_address: address): u128 acquires LockingSystem {
        smart_table::borrow(&borrow_global<LockingSystem>(ADMINISTRATOR).token_pools, token_address).total_locks
    }

    #[view]
    /// Total amount token still locked.
    public fun get_all_stakers(token_address: address): vector<address> acquires LockingSystem {
        let token_pools = &borrow_global<LockingSystem>(ADMINISTRATOR).token_pools;
        let stakers_ref = &smart_table::borrow(token_pools, token_address).stakers;
        let all = vector::empty<address>();
        smart_table::for_each_ref(stakers_ref, |a, v| {
            let a = *a;
            let _ = v;
            vector::push_back(&mut all, a);
        });

        all
    }

    #[view]
    /// Total amount token still locked of recipient.
    public fun staking_amount(token_address: address, recipient: address): u128 acquires LockingSystem {
        assert!(exists<LockingSystem>(ADMINISTRATOR), EADMIN_ACCOUNT_NOT_INITIALIZED);
        let stakings = smart_table::borrow(&borrow_global<LockingSystem>(ADMINISTRATOR).token_pools, token_address);
        assert!(smart_table::contains(&stakings.stakers, recipient), ELOCK_INFO_NOT_FOUND);
        smart_table::borrow(&stakings.stakers, recipient).curr_balance
    }

    #[view]
    /// Return the address of the metadata that's created when this module is deployed.
    public fun get_metadata(token_address: address): Object<Metadata> {
        object::address_to_object<Metadata>(token_address)
    }

    #[view]
    public fun get_all_stakers_unlock_info(token_address: address): vector<UnlockInfo> acquires LockingSystem {
        let all_stakers = get_all_stakers(token_address);
        vector::map(all_stakers, |staker| {
            get_unlock_info(token_address, staker)
        })
    }

    #[view]
    public fun get_unlock_info(token_address: address, sender: address): UnlockInfo acquires LockingSystem {
        assert!(exists<LockingSystem>(ADMINISTRATOR), EADMIN_ACCOUNT_NOT_INITIALIZED);
        let token_pool = smart_table::borrow(&borrow_global<LockingSystem>(ADMINISTRATOR).token_pools, token_address);
        assert!(smart_table::contains(&token_pool.stakers, sender), ELOCK_INFO_NOT_FOUND);
        let staker = smart_table::borrow(&token_pool.stakers, sender);
        let c = &staker.config;
        let list = vector::empty<UnlockAt>();


        vector::push_back(&mut list, UnlockAt {
            epoch: c.first_unlock_epoch,
            amount: calc_init_unlock(c)
        }
        );

        for (period in 0..c.stable_unlock_periods) {
            vector::push_back(&mut list, UnlockAt {
                epoch: c.first_unlock_epoch + c.stable_unlock_interval * (period + 1),
                amount: calc_stable_unlock(c)
            }
            );
        };

        let free = staker.curr_balance - calc_still_locked_amount(c);

        UnlockInfo {
            address: sender,
            unlocked: free,
            unlock_list: list,
        }
    }

    /// Initialize function called at genesis epoch.
    public(friend) fun start_distribute_coins(
        admin: &signer,
        configs: vector<LockingConfig>
    ) acquires LockingSystem, CapStore {
        distribut_coins_with_config(admin, configs);
    }

    fun distribut_coins_with_config(
        admin: &signer,
        staking_config: vector<LockingConfig>
    ) acquires LockingSystem, CapStore {
        setup_pool_resource(admin);
        distribute_coins(staking_config);
    }

    /// Initialize StakingPool and move it to 0x1.
    fun setup_pool_resource(admin: &signer) {
        move_to(admin, LockingSystem {
            token_pools: smart_table::new(),
        })
    }

    /// If from_unlocked is true and it will transfer coin from sponser unlocked amount to repicient staking resource address,
    /// else transfer from sponser account balance.
    fun add_locking_plan_for_address(
        sponser: &signer,
        token_address: address,
        c: LockingConfig,
        from_unlocked: bool
    ) acquires LockingSystem, CapStore {

        assert!(c.total_coins > 0, EINVALID_DATA);
        assert!(c.first_unlock_percent <= 100, EINVALID_DATA);
        assert!(c.first_unlock_percent <= 100, EINVALID_DATA);

        let seed = bcs::to_bytes(&c.address);
        vector::append(&mut seed, CONTRACT_NAME);
        let (resource_signer, signer_cap) = account::create_resource_account(sponser, seed);
        let resource_addr = address_of(&resource_signer);


        // Store singer capbility, this capbility is required when cliam coins.
        let cap_store = CapStore { signer_cap };
        move_to(&resource_signer, cap_store);

        let stacking_info = StakerInfo {
            config: c,
            resource_addr,
            curr_balance: c.total_coins,
        };

        if (from_unlocked) {
            // Transfer coin from sponser unlocked amount to repicient staking resource address.
            transfer_coin_from_unlocked_coin_to_recipient(sponser, token_address, resource_addr, c.total_coins);
        } else {
            // Transfer coin from sponser address to resource account
            primary_fungible_store::transfer(sponser, get_metadata(token_address), resource_addr, c.total_coins);
        };

        let token_pools = &mut borrow_global_mut<LockingSystem>(ADMINISTRATOR).token_pools;

        // If no token pool for token_address, it means token is a new one, it will create token_pool and add to token_pools table.
        if(!smart_table::contains(token_pools, token_address)) {
            let pool = TokenPool {
                stakers: smart_table::new(),
                total_locks: 0,
            };
            smart_table::add(token_pools, token_address, pool);
        };

        let pool = smart_table::borrow_mut(token_pools, token_address);
        // Increase total staking record.
        pool.total_locks = pool.total_locks + c.total_coins;
        smart_table::add(&mut pool.stakers, c.address, stacking_info);
    }

    ///  Create resource account for each staker and mint coin to related resource account.
    fun distribute_coins(staking_configs: vector<LockingConfig>) acquires LockingSystem, CapStore {
        vector::for_each_ref(&staking_configs, |c| {
            let c: &LockingConfig = c;
            // Transfer coin to resource account
            let addr_signer = create_signer::create_signer(c.address);
            add_locking_plan_for_address(&addr_signer, get_eds_token_address(), *c, false);
        });
    }

    /// Send locking coin to another address from free amount and unlock by plan
    public entry fun add_locking_plan_from_unlocked_balance(
        sender: &signer,
        token_address: address,
        reciever: address,
        total_coins: u128,
        first_unlock_percent: u64,
        first_unlock_epoch: u64,
        stable_unlock_interval: u64,
        stable_unlock_periods: u64,
    ) acquires LockingSystem, CapStore {
        let c = LockingConfig {
            address: reciever,
            total_coins,
            first_unlock_percent,
            first_unlock_epoch,
            stable_unlock_interval,
            stable_unlock_periods
        };

        add_locking_plan_for_address(sender, token_address, c, true);
    }

    public entry fun add_locking_plan(
        sender: &signer,
        token_address: address,
        reciever: address,
        total_coins: u128,
        first_unlock_percent: u64,
        first_unlock_epoch: u64,
        stable_unlock_interval: u64,
        stable_unlock_periods: u64,
    ) acquires LockingSystem, CapStore {
        let c = LockingConfig {
            address: reciever,
            total_coins,
            first_unlock_percent,
            first_unlock_epoch,
            stable_unlock_interval,
            stable_unlock_periods
        };

        add_locking_plan_for_address(sender, token_address, c, false);
    }

    /// Claim coins when recipient has free amount.
    public entry fun claim(sender: &signer, token_address: address, amount: u128) acquires LockingSystem, CapStore {
        do_claim(token_address, sender, amount);
    }

    /// // Transfer free amount to recipient account;
    fun transfer_coin_from_unlocked_coin_to_recipient(
        sponser: &signer,
        token_address: address,
        recipient: address,
        amount: u128
    ): u128 acquires LockingSystem, CapStore {
        let pool = smart_table::borrow_mut(&mut borrow_global_mut<LockingSystem>(ADMINISTRATOR).token_pools, token_address);
        let stakers = &mut pool.stakers;
        assert!(smart_table::contains(stakers, address_of(sponser)), ENOT_STAKER);

        let staker = smart_table::borrow_mut(stakers, address_of(sponser));
        let locked = calc_still_locked_amount(&staker.config);
        if (staker.curr_balance <= locked) {
            return 0
        };

        // Transfer unlocked coins to recipient.
        let free_amount = staker.curr_balance - locked;
        assert!(free_amount >= amount, EINSUFFICIENT_BALANCE);
        let store = borrow_global<CapStore>(staker.resource_addr);
        let singer = account::create_signer_with_capability(&store.signer_cap);

        primary_fungible_store::transfer(&singer, get_metadata(token_address), recipient, amount);

        // Update staking infomation.
        staker.curr_balance = staker.curr_balance - amount;
        pool.total_locks = pool.total_locks - amount;

        amount
    }

    /// Only user in locking pool allow to call.
    fun do_claim(token_address: address, sender: &signer, amount: u128): u128 acquires LockingSystem, CapStore {
        // transfer coin from recipient free amount to recipient account;
        transfer_coin_from_unlocked_coin_to_recipient(sender, token_address, address_of(sender), amount);
        event::emit(Claim {
            recipient: address_of(sender),
            amount,
            claim_epoch: reconfiguration::current_epoch(),
            claimed_time_secs: timestamp::now_seconds(),
        });

        amount
    }

    fun calc_init_unlock(c: &LockingConfig): u128 {
        c.total_coins - calc_stable_unlock(c) * (c.stable_unlock_periods as u128)
    }

    // Unlock amount at next epoch.
    fun calc_next_unlock(c: &LockingConfig, now_epoch: u64): u128 {
        if (now_epoch <= c.first_unlock_epoch) {
            return calc_init_unlock(c)
        };


        let period = (now_epoch - c.first_unlock_epoch) / c.stable_unlock_interval;
        if (period <= c.stable_unlock_periods) {
            calc_stable_unlock(c)
        } else {
            0
        }
    }

    /// Unlock amount each stable unlock epoch.
    fun calc_stable_unlock(config: &LockingConfig): u128 {
        if (config.stable_unlock_interval == 0 || config.stable_unlock_interval == 0) {
            0
        } else {
            (config.total_coins - math128::mul_div(config.total_coins, (config.first_unlock_percent as u128), 100_u128))
                / (config.stable_unlock_periods as u128)
        }
    }

    // Still locked until this time.
    fun calc_still_locked_amount(config: &LockingConfig): u128 {
        let current = reconfiguration::current_epoch();
        if (current <= config.first_unlock_epoch) {
            return config.total_coins
        };


        if (config.stable_unlock_interval == 0 || config.stable_unlock_interval == 0) {
            if (current < config.first_unlock_epoch) {
                config.total_coins
            } else {
                0
            }
        } else {
            // After first_unlock_epoch, period will increace 1 each time from 0 to 12
            // when STABLE_UNLOCK_INERVAL_EPOCHS expires.
            let period = (current - config.first_unlock_epoch) / config.stable_unlock_interval;
            if (period < config.stable_unlock_periods) {
                calc_stable_unlock(config) * ((config.stable_unlock_periods - period) as u128)
            } else {
                0
            }
        }
    }

    #[test_only]
    use endless_framework::endless_coin::{balance};

    /// Addresses list
    const PE0: address = @0x27999c17fbd7b99286320bbf5a0f487d152e416c311debb0e277464598872762;
    const PE1: address = @0xa7114c42e8c07809ef640ebbe8adc943b15a7746e6ce6dcb915d1944538363ab;
    const PE2: address = @0x715c79b2e7e3efa0b1cd9d4b92e0091eee8be9fae924db8001bca37a5483da49;
    const PE3: address = @0xea673f5016fdebd6d08cb9ffbdb95f3935fab1b2251234d286171aaecbd2f3cd;

    const TEAM: address = @0xc589165f31f7805965950a5af30b53455c147a98facdb42c4f8fd4e4c2733ca3;
    const FOUNDATION: address = @0xf54658fcbd814921a0de824d8ce592731870c4b1af7c76bbd1462303c51fab26;
    const MARKET_PARTNERS: address = @0x9e50caf6d9702f72e3dbd67c6f7336656ddd63b8ea594fafdb05c7b1388ebd81;

    const AIRDROP: address = @0xbedaa6897c6dd3f016f112ce61340d1fe3271bd737607563ebc609fd6ebc879f;
    const ECOLOGY: address = @0xf19085487f9762fc34a270ec896991b661f3fdbe04ee566dffd963b6f7f7e0ba;
    const COMMUNITY: address = @0x8aaee7a286b042351410c8582deeaeafad1cf6d435a63eafb6ac313c9ad35322;
    const SKAKINGS: address = @0xc639dfe79882793f6ec6a4c91cc06de440386a062a58a14cf70d26b75e2bb349;

    fun locking_config(): vector<LockingConfig> {
        let locking_config = vector::empty<LockingConfig>();
        //
        vector::push_back(&mut locking_config, LockingConfig {
            address: PE0,
            total_coins: 11_00000000_00000000,
            first_unlock_percent: 100,
            first_unlock_epoch: 5,
            stable_unlock_interval: 2,
            stable_unlock_periods: 2
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: PE1,
            total_coins: 5_00000000_00000000,
            first_unlock_percent: 10,
            first_unlock_epoch: 5,
            stable_unlock_interval: 17,
            stable_unlock_periods: 3
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: PE2,
            total_coins: 3_00000000_00000000,
            first_unlock_percent: 0,
            first_unlock_epoch: 6,
            stable_unlock_interval: 17,
            stable_unlock_periods: 3
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: PE3,
            total_coins: 97000000_00000000,
            first_unlock_percent: 0,
            first_unlock_epoch: 8,
            stable_unlock_interval: 17,
            stable_unlock_periods: 3
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: TEAM,
            total_coins: 15_03000000_00000000,
            first_unlock_percent: 10,
            first_unlock_epoch: 5,
            stable_unlock_interval: 17,
            stable_unlock_periods: 3
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: FOUNDATION,
            total_coins: 20_00000000_00000000,
            first_unlock_percent: 10,
            first_unlock_epoch: 5,
            stable_unlock_interval: 7,
            stable_unlock_periods: 11
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: MARKET_PARTNERS,
            total_coins: 8_90000000_00000000,
            first_unlock_percent: 20,
            first_unlock_epoch: 5,
            stable_unlock_interval: 2,
            stable_unlock_periods: 39
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: AIRDROP,
            total_coins: 3_10000000_00000000,
            first_unlock_percent: 20,
            first_unlock_epoch: 5,
            stable_unlock_interval: 6,
            stable_unlock_periods: 5
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: ECOLOGY,
            total_coins: 18_30000000_00000000,
            first_unlock_percent: 20,
            first_unlock_epoch: 5,
            stable_unlock_interval: 10,
            stable_unlock_periods: 7
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: COMMUNITY,
            total_coins: 3_05000000_00000000,
            first_unlock_percent: 20,
            first_unlock_epoch: 5,
            stable_unlock_interval: 6,
            stable_unlock_periods: 9
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: SKAKINGS,
            total_coins: 10_15000000_00000000,
            first_unlock_percent: 100,
            first_unlock_epoch: 5,
            stable_unlock_interval: 2,
            stable_unlock_periods: 2
        });

        locking_config
    }


    #[test_only]
    use endless_framework::create_signer::create_signer;
    use endless_framework::endless_coin;
    #[test_only]
    use endless_std::debug::print;

    #[test_only]
    fun system_setup() acquires LockingSystem, CapStore {
        let endless_framework = account::create_account_for_test(@endless_framework);
        timestamp::set_time_has_started_for_testing(&endless_framework);
        reconfiguration::initialize_for_test(&endless_framework);
        endless_coin::initialize_for_test(&endless_framework);

        start_distribut_coins_test(&endless_framework);
    }

    public(friend) fun start_distribut_coins_test(endless_framework: &signer) acquires LockingSystem, CapStore {

        vector::for_each_ref(&locking_config(), |c| {
            let c: &LockingConfig = c;
            endless_coin::mint(endless_framework, c.address, c.total_coins);
        });

        distribut_coins_with_config(endless_framework, locking_config());
    }

    #[test_only]
    fun mint_to_tester(addr: address, amount: u128) {
        let endless_framework = account::create_account_for_test(@endless_framework);
        endless_coin::mint(&endless_framework, addr, amount);
    }


    #[test()]
    fun test_01_setup() acquires LockingSystem, CapStore {
        system_setup();
        let all_info = get_all_stakers_unlock_info(get_eds_token_address());
        print(&all_info);
    }


    #[test()]
    fun test_02_total_coins_distributed() acquires LockingSystem, CapStore {
        system_setup();

        let total = 0;
        vector::for_each_ref(&locking_config(), |c| {
            let c: &LockingConfig = c;
            total = total + c.total_coins;
        });

        assert!(total == 985000000000000000, ETESER_FAILED);
    }

    #[test()]
    fun test_03_staking_amount() acquires LockingSystem, CapStore {
        system_setup();

        vector::for_each_ref(&locking_config(), |c| {
            let c: &LockingConfig = c;
            assert!(staking_amount(get_eds_token_address(), c.address) == c.total_coins, ETESER_FAILED);
        });
    }

    #[test(tester = @0x00abcd)]
    fun test_04_claim_failed(tester: &signer) acquires LockingSystem, CapStore {
        system_setup();
        mint_to_tester(address_of(tester), 1_000_000);

        vector::for_each_ref(&locking_config(), |c| {
            let c: &LockingConfig = c;

            assert!(
                do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info( get_eds_token_address(), c.address).unlocked) == 0,
                ETESER_FAILED
            );
        });
    }

    #[test(tester = @0x00abcd)]
    fun test_05_first_claim_success(tester: &signer) acquires LockingSystem, CapStore {
        system_setup();
        mint_to_tester(address_of(tester), 1_000_000);

        vector::for_each_ref(&locking_config(), |c| {
            let c: &LockingConfig = c;
            reconfiguration::update_epoch_for_test_custom(c.first_unlock_epoch + 1);
            do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);
            assert!(
                balance(c.address) == calc_next_unlock(c, reconfiguration::current_epoch() - 2),
                ETESER_FAILED
            );
        });
    }

    #[test(tester = @0x00abcd)]
    fun test_06_reclaim_after_first_claim_failed(tester: &signer) acquires LockingSystem, CapStore {
        system_setup();
        mint_to_tester(address_of(tester), 1_000_000);

        vector::for_each_ref(&locking_config(), |c| {
            let c: &LockingConfig = c;
            reconfiguration::update_epoch_for_test_custom(c.first_unlock_epoch + 1);
            do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);
            assert!(
                do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked) == 0,
                ETESER_FAILED
            );
        });
    }


    #[test(tester = @0x00abcd)]
    fun test_07_claim_before_last_epoch(tester: &signer) acquires LockingSystem, CapStore {
        system_setup();
        mint_to_tester(address_of(tester), 1_000_000);

        vector::for_each_ref(&locking_config(), |c| {
            let c: &LockingConfig = c;
            // before last epoch
            reconfiguration::update_epoch_for_test_custom(
                c.first_unlock_epoch + c.stable_unlock_periods * c.stable_unlock_interval - 1
            );
            do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);
            let bls = balance(c.address);
            assert!(bls == c.total_coins - calc_stable_unlock(c), ETESER_FAILED);
        });
    }


    fun get_addr_free_amount(user: address): u128 acquires LockingSystem {
        let pool = smart_table::borrow(&borrow_global<LockingSystem>(ADMINISTRATOR).token_pools, get_eds_token_address());

        let staker = smart_table::borrow(&pool.stakers, user);
        staker.curr_balance - calc_still_locked_amount(&staker.config)
    }

    #[test_only]
    fun claim_batch() acquires LockingSystem, CapStore {
        vector::for_each_ref(&locking_config(), |c| {
            let c: &LockingConfig = c;
            if (get_addr_free_amount(c.address) > 0) {
                do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);
            }
        });
    }


    #[test(tester = @0x00abcd)]
    fun test_08_batch_claim_each_epoch(tester: &signer) acquires LockingSystem, CapStore {
        system_setup();
        mint_to_tester(address_of(tester), 1_000_000);

        vector::for_each_ref(&locking_config(), |c| {
            let c: &LockingConfig = c;
            reconfiguration::update_epoch_for_test_custom(c.first_unlock_epoch + 1);
            do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);

            for (period in 1..(c.stable_unlock_periods + 1)) {
                // first unlock
                reconfiguration::update_epoch_for_test_custom(
                    c.first_unlock_epoch + period * c.stable_unlock_interval + 1
                );

                do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);


                let free = calc_next_unlock(c, 0) + calc_stable_unlock(c) * (period as u128);
                let bls = balance(c.address);

                assert!(bls == free, ETESER_FAILED);
            };
        });
    }

    #[test(tester = @0x00abcd)]
    fun test_09_claim_after_last_epoch(tester: &signer) acquires LockingSystem, CapStore {
        system_setup();
        mint_to_tester(address_of(tester), 1_000_000);

        vector::for_each_ref(&locking_config(), |c| {
            let c: &LockingConfig = c;
            reconfiguration::update_epoch_for_test_custom(
                c.first_unlock_epoch + c.stable_unlock_periods * c.stable_unlock_interval + 1
            );
            do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);
            assert!(balance(c.address) == c.total_coins, ETESER_FAILED);
        });
    }

    #[test(tester = @0x00abcd)]
    fun test_10_add_locking_plan_and_claim_each_epoch(tester: &signer) acquires LockingSystem, CapStore {
        system_setup();
        mint_to_tester(address_of(tester), 1000_00000000);

        let c = LockingConfig {
            address: address_of(tester),
            total_coins: 1000_00000000,
            first_unlock_percent: 20,
            first_unlock_epoch: 10,
            stable_unlock_interval: 3,
            stable_unlock_periods: 6,
        };

        add_locking_plan(
            tester,
            get_eds_token_address(),
            address_of(tester),
            c.total_coins,
            c.first_unlock_percent,
            c.first_unlock_epoch,
            c.stable_unlock_interval,
            c.stable_unlock_periods
        );

        reconfiguration::update_epoch_for_test_custom(c.first_unlock_epoch + 1);
        do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);

        for (period in 1..(c.stable_unlock_periods + 1)) {
            // first unlock
            reconfiguration::update_epoch_for_test_custom(
                c.first_unlock_epoch + period * c.stable_unlock_interval + 1
            );

            do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);


            let free = calc_next_unlock(&c, 0) + calc_stable_unlock(&c) * (period as u128);
            let bls = balance(c.address);

            assert!(bls == free, ETESER_FAILED);
        };
    }


    #[test(tester = @0x00abcd)]
    fun test_11_add_locking_plan_for_other_and_claim_each_epoch(tester: &signer) acquires LockingSystem, CapStore {
        system_setup();
        mint_to_tester(address_of(tester), 1000_00000000);
        let c = LockingConfig {
            address: address_of(tester),
            total_coins: 1000_00000000,
            first_unlock_percent: 20,
            first_unlock_epoch: 5,
            stable_unlock_interval: 3,
            stable_unlock_periods: 6,
        };

        add_locking_plan_for_address(tester, get_eds_token_address(), c, false);

        reconfiguration::update_epoch_for_test_custom(c.first_unlock_epoch + 1);
        do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);

        for (period in 1..(c.stable_unlock_periods + 1)) {
            // first unlock
            reconfiguration::update_epoch_for_test_custom(
                c.first_unlock_epoch + period * c.stable_unlock_interval + 1
            );

            do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);


            let free = calc_next_unlock(&c, 0) + calc_stable_unlock(&c) * (period as u128);
            let bls = balance(c.address);

            assert!(bls == free, ETESER_FAILED);
        };
    }


    #[test(tester = @0x00abcd, pe0 = @0x27999c17fbd7b99286320bbf5a0f487d152e416c311debb0e277464598872762)]
    fun test_12_add_locking_plan_for_other_from_unlocked_coin_and_claim_each_epoch(
        tester: &signer,
        pe0: &signer
    ) acquires LockingSystem, CapStore {
        system_setup();
        reconfiguration::update_epoch_for_test_custom(10);
        //mint_to_tester(address_of(tester), 1_00000000);
        let c = LockingConfig {
            address: address_of(tester),
            total_coins: 1000_00000000,
            first_unlock_percent: 20,
            first_unlock_epoch: 100,
            stable_unlock_interval: 3,
            stable_unlock_periods: 6,
        };

        add_locking_plan_for_address(pe0, get_eds_token_address(), c, true);

        reconfiguration::update_epoch_for_test_custom(c.first_unlock_epoch + 1);
        do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);

        for (period in 1..(c.stable_unlock_periods + 1)) {
            // first unlock
            reconfiguration::update_epoch_for_test_custom(
                c.first_unlock_epoch + period * c.stable_unlock_interval + 1
            );

            do_claim(get_eds_token_address() , &create_signer(c.address), get_unlock_info(get_eds_token_address(), c.address).unlocked);


            let free = calc_next_unlock(&c, 0) + calc_stable_unlock(&c) * (period as u128);
            let bls = balance(c.address);

            assert!(bls == free, ETESER_FAILED);
        };
    }
}

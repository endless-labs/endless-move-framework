module locking::locking_coin_ex {
    use std::bcs;
    use endless_framework::timestamp;
    use std::signer::address_of;
    use std::vector;
    use endless_framework::object;
    use endless_framework::object::Object;
    use endless_framework::fungible_asset::Metadata;
    use endless_framework::primary_fungible_store;
    use endless_framework::reconfiguration;
    use endless_std::math128;
    use endless_std::smart_table::{Self, SmartTable};
    use endless_framework::account;
    use endless_framework::account::SignerCapability;
    use endless_framework::event;


    const ADMINISTRATOR: address = @locking;

    const BPS_10000: u64 = 10000;

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

    const ENO_MATCH_EXISTED_PLAN: u64 = 11;

    const EINVALID_RES_ADDRESS_BALANCE: u64 = 12;

    const EINVALID_CLAIM_AMOUNT: u64 = 13;

    const ETESER_FAILED: u64 = 20;

    struct LockingConfig has store, drop, copy {
        address: address,

        total_coins: u128,

        first_unlock_bps: u64,

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

    #[event]
    /// Event emitted when a recipient claims unlocked coins.
    struct AddPlan has drop, store {
        sponser: address,

        resource_addr: address,

        balance: u128,

        plan: LockingConfig
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
    public fun staking_info(token_address: address, recipient: address): StakerInfo acquires LockingSystem {
        assert!(exists<LockingSystem>(ADMINISTRATOR), EADMIN_ACCOUNT_NOT_INITIALIZED);
        let stakings = smart_table::borrow(&borrow_global<LockingSystem>(ADMINISTRATOR).token_pools, token_address);
        assert!(smart_table::contains(&stakings.stakers, recipient), ELOCK_INFO_NOT_FOUND);
        *smart_table::borrow(&stakings.stakers, recipient)
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

    #[view]
    public fun unlocked_balance(token_address: address, recipient: address): u128 acquires LockingSystem {
        assert!(exists<LockingSystem>(ADMINISTRATOR), EADMIN_ACCOUNT_NOT_INITIALIZED);
        let token_pool = smart_table::borrow(&borrow_global<LockingSystem>(ADMINISTRATOR).token_pools, token_address);
        assert!(smart_table::contains(&token_pool.stakers, recipient), ELOCK_INFO_NOT_FOUND);
        let staker = smart_table::borrow(&token_pool.stakers, recipient);
        let c = &staker.config;

        staker.curr_balance - calc_still_locked_amount(c)
    }

    /// Initialize function called at genesis epoch.
    public(friend) fun start_distribute_coins(
        admin: &signer,
        configs: vector<LockingConfig>
    )  {
        distribut_coins_with_config(admin, configs);
    }

    fun distribut_coins_with_config(
        admin: &signer,
        staking_config: vector<LockingConfig>
    )  {
        setup_pool_resource(admin);
        distribute_coins(staking_config);
    }

    /// Initialize StakingPool and move it to 0x1.

    fun setup_pool_resource(admin: &signer) {
        move_to(admin, LockingSystem {
            token_pools: smart_table::new(),
        })
    }

    fun init_module(admin: &signer){
        setup_pool_resource(admin);
    }

    fun validate_config(c: &LockingConfig) {
        assert!(c.total_coins > 0, EINVALID_DATA);
        assert!(c.first_unlock_bps <= BPS_10000, EINVALID_DATA);

        if (c.stable_unlock_interval == 0 || c.stable_unlock_periods == 0) {
            assert!(c.first_unlock_bps == BPS_10000, EINVALID_DATA);
        }
    }

    #[view]
    /// Return the address of the metadata that's created when this module is deployed.
    public fun calc_old_res_address(sponser: address, user: address): address {
        let seed = bcs::to_bytes(&user);
        vector::append(&mut seed, CONTRACT_NAME);
        account::create_resource_address(&sponser, seed)
    }


    /// If from_unlocked is true and it will transfer coin from sponser unlocked amount to repicient staking resource address,
    /// else transfer from sponser account balance.
    fun add_locking_plan_for_address(
        sponser: &signer,
        token: address,
        c: LockingConfig,
        from_unlocked: bool
    ) acquires LockingSystem, CapStore {
        validate_config(&c);

        let seed = vector[];
        vector::append(&mut seed, CONTRACT_NAME);
        vector::append(&mut seed, bcs::to_bytes(&token));
        vector::append(&mut seed, bcs::to_bytes(&c.address));

        let (resource_signer, signer_cap) = account::create_resource_account(sponser, seed);
        let resource_addr = address_of(&resource_signer);

        if (from_unlocked) {
            // Transfer coin from sponser unlocked amount to repicient staking resource address.
            transfer_coin_from_unlocked_coin_to_recipient(sponser, token, resource_addr, c.total_coins);
        } else {
            // Transfer coin from sponser address to resource account
            primary_fungible_store::transfer(sponser, get_metadata(token), resource_addr, c.total_coins);
        };

        let token_pools = &mut borrow_global_mut<LockingSystem>(ADMINISTRATOR).token_pools;

        // If no token pool for token_address, it means token is a new one, it will create token_pool and add to token_pools table.
        if (!smart_table::contains(token_pools, token)) {
            let pool = TokenPool {
                stakers: smart_table::new(),
                total_locks: 0,
            };
            smart_table::add(token_pools, token, pool);
        };

        let pool = smart_table::borrow_mut(token_pools, token);

        // Store singer capbility, this capbility is required when cliam coins.
        let stacking_info = if (!exists<CapStore>(resource_addr)) {
            move_to(&resource_signer, CapStore { signer_cap });
            StakerInfo {
                config: c,
                resource_addr,
                curr_balance: c.total_coins,
            }
        } else {
            let stake_info = smart_table::remove(&mut pool.stakers, c.address);
            let exit_cfg = stake_info.config;
            assert!(
                exit_cfg.address == c.address &&
                    exit_cfg.first_unlock_bps == c.first_unlock_bps &&
                    exit_cfg.first_unlock_epoch == c.first_unlock_epoch &&
                    exit_cfg.stable_unlock_interval == c.stable_unlock_interval &&
                    exit_cfg.stable_unlock_periods == c.stable_unlock_periods,
                ENO_MATCH_EXISTED_PLAN
            );

            stake_info.config.total_coins = stake_info.config.total_coins + c.total_coins;
            stake_info.curr_balance = stake_info.curr_balance + c.total_coins;

            stake_info
        };

        let balance =  primary_fungible_store::balance(resource_addr, get_metadata(token));
        assert!(balance >= stacking_info.curr_balance, EINVALID_RES_ADDRESS_BALANCE);

        // Increase total staking record.
        pool.total_locks = pool.total_locks + c.total_coins;
        smart_table::add(&mut pool.stakers, c.address, stacking_info);

        event::emit(AddPlan {
            sponser: address_of(sponser),
            resource_addr,
            balance,
            plan: c
        })
    }

    ///  Create resource account for each staker and mint coin to related resource account.
    fun distribute_coins(_staking_configs: vector<LockingConfig>)  {
/*        vector::for_each_ref(&staking_configs, |c| {
            let c: &LockingConfig = c;
            Transfer coin to resource account
            let addr_signer = create_signer::create_signer(c.address);
            add_locking_plan_for_address(&addr_signer, get_eds_token_address(), *c, false);
        });*/
    }

    /// Send locking coin to another address from free amount and unlock by plan
    public entry fun add_locking_plan_from_unlocked_balance(
        sender: &signer,
        token_address: address,
        reciever: address,
        total_coins: u128,
        first_unlock_bps: u64,
        first_unlock_epoch: u64,
        stable_unlock_interval: u64,
        stable_unlock_periods: u64,
    ) acquires LockingSystem, CapStore {
        let c = LockingConfig {
            address: reciever,
            total_coins,
            first_unlock_bps,
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
        first_unlock_bps: u64,
        first_unlock_epoch: u64,
        stable_unlock_interval: u64,
        stable_unlock_periods: u64,
    ) acquires LockingSystem, CapStore {
        let c = LockingConfig {
            address: reciever,
            total_coins,
            first_unlock_bps,
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

    public entry sponsored fun claim_sponsored(sender: &signer, token_address: address, amount: u128) acquires LockingSystem, CapStore {
    // sponsored claim  exist min amount limited.
    let unlocked = unlocked_balance(token_address, address_of(sender));
    assert!(amount >= 1_00000000 || amount == unlocked, EINVALID_CLAIM_AMOUNT);
    do_claim(token_address, sender, amount);
}

    /// // Transfer free amount to recipient account;
    fun transfer_coin_from_unlocked_coin_to_recipient(
        sponser: &signer,
        token_address: address,
        recipient: address,
        amount: u128
    ): u128 acquires LockingSystem, CapStore {
        let pool = smart_table::borrow_mut(
            &mut borrow_global_mut<LockingSystem>(ADMINISTRATOR).token_pools,
            token_address
        );
        let stakers = &mut pool.stakers;
        assert!(smart_table::contains(stakers, address_of(sponser)), ENOT_STAKER);

        let staker = smart_table::borrow_mut(stakers, address_of(sponser));
        let locked = calc_still_locked_amount(&staker.config);

        assert!(staker.curr_balance >= locked + amount, EINSUFFICIENT_BALANCE);

        // Transfer unlocked coins to recipient.
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
        if (amount == 0) return 0;

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
        } else {
            if (c.stable_unlock_interval == 0) {
                0
            } else {
                let period = (now_epoch - c.first_unlock_epoch) / c.stable_unlock_interval;
                if (period <= c.stable_unlock_periods) {
                    calc_stable_unlock(c)
                } else {
                    0
                }
            }
        }
    }

    /// Unlock amount each stable unlock epoch.
    fun calc_stable_unlock(c: &LockingConfig): u128 {
        if (c.stable_unlock_periods == 0) {
            0
        } else {
            (c.total_coins - math128::mul_div(c.total_coins, (c.first_unlock_bps as u128), (BPS_10000 as u128)))
                / (c.stable_unlock_periods as u128)
        }
    }

    // Still locked until this time.
    fun calc_still_locked_amount(config: &LockingConfig): u128 {
        let current = reconfiguration::current_epoch();
        if (current < config.first_unlock_epoch) {
            return config.total_coins
        };

        if (config.stable_unlock_interval == 0 || config.stable_unlock_periods == 0) {
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
            first_unlock_bps: 100,
            first_unlock_epoch: 5,
            stable_unlock_interval: 2,
            stable_unlock_periods: 2
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: PE1,
            total_coins: 5_00000000_00000000,
            first_unlock_bps: 10,
            first_unlock_epoch: 5,
            stable_unlock_interval: 17,
            stable_unlock_periods: 3
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: PE2,
            total_coins: 3_00000000_00000000,
            first_unlock_bps: 0,
            first_unlock_epoch: 6,
            stable_unlock_interval: 17,
            stable_unlock_periods: 3
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: PE3,
            total_coins: 97000000_00000000,
            first_unlock_bps: 0,
            first_unlock_epoch: 8,
            stable_unlock_interval: 17,
            stable_unlock_periods: 3
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: TEAM,
            total_coins: 15_03000000_00000000,
            first_unlock_bps: 10,
            first_unlock_epoch: 5,
            stable_unlock_interval: 17,
            stable_unlock_periods: 3
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: FOUNDATION,
            total_coins: 20_00000000_00000000,
            first_unlock_bps: 10,
            first_unlock_epoch: 5,
            stable_unlock_interval: 7,
            stable_unlock_periods: 11
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: MARKET_PARTNERS,
            total_coins: 8_90000000_00000000,
            first_unlock_bps: 20,
            first_unlock_epoch: 5,
            stable_unlock_interval: 2,
            stable_unlock_periods: 39
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: AIRDROP,
            total_coins: 3_10000000_00000000,
            first_unlock_bps: 20,
            first_unlock_epoch: 5,
            stable_unlock_interval: 6,
            stable_unlock_periods: 5
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: ECOLOGY,
            total_coins: 18_30000000_00000000,
            first_unlock_bps: 20,
            first_unlock_epoch: 5,
            stable_unlock_interval: 10,
            stable_unlock_periods: 7
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: COMMUNITY,
            total_coins: 3_05000000_00000000,
            first_unlock_bps: 20,
            first_unlock_epoch: 5,
            stable_unlock_interval: 6,
            stable_unlock_periods: 9
        });

        vector::push_back(&mut locking_config, LockingConfig {
            address: SKAKINGS,
            total_coins: 10_15000000_00000000,
            first_unlock_bps: 100,
            first_unlock_epoch: 5,
            stable_unlock_interval: 2,
            stable_unlock_periods: 2
        });

        locking_config
    }



}

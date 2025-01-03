module endless_framework::genesis {
    use std::error;
    use std::vector;
    use endless_std::fixed_point64;
    use endless_std::simple_map;
    use endless_framework::locking_coin_ex::LockingConfig;
    use endless_framework::stake::AccountShare;
    use endless_framework::locking_coin_ex;
    use endless_framework::account;
    use endless_framework::aggregator_factory;
    use endless_framework::endless_coin;
    use endless_framework::endless_governance;
    use endless_framework::block;
    use endless_framework::chain_id;
    use endless_framework::chain_status;
    use endless_framework::fungible_asset;
    use endless_framework::primary_fungible_store;
    use endless_framework::consensus_config;
    use endless_framework::execution_config;
    use endless_framework::create_signer::create_signer;
    use endless_framework::gas_schedule;
    use endless_framework::reconfiguration;
    use endless_framework::stake;
    use endless_framework::staking_contract;
    use endless_framework::staking_config;
    use endless_framework::state_storage;
    use endless_framework::storage_gas;
    use endless_framework::timestamp;
    use endless_framework::transaction_fee;
    use endless_framework::transaction_validation;
    use endless_framework::version;
    use endless_framework::vesting;
    const EDUPLICATE_ACCOUNT: u64 = 1;
    const EACCOUNT_DOES_NOT_EXIST: u64 = 2;

    struct AccountMap has drop {
        account_address: address,
        balance: u128,
    }

    struct EmployeeAccountMap has copy, drop {
        accounts: vector<address>,
        validator: ValidatorConfigurationWithCommission,
        vesting_schedule_numerator: vector<u64>,
        vesting_schedule_denominator: u64,
        beneficiary_resetter: address,
    }

    struct ValidatorConfiguration has copy, drop {
        owner_address: address,
        operator_address: address,
        voter_address: address,
        stake_amount: u128,
        consensus_pubkey: vector<u8>,
        proof_of_possession: vector<u8>,
        network_addresses: vector<u8>,
        full_node_network_addresses: vector<u8>,
    }

    struct ValidatorConfigurationWithCommission has copy, drop {
        validator_config: ValidatorConfiguration,
        commission_percentage: u64,
        join_during_genesis: bool,
    }

    /// Genesis step 1: Initialize endless framework account and core modules on chain.
    fun initialize(
        gas_schedule: vector<u8>,
        chain_id: u8,
        initial_version: u64,
        consensus_config: vector<u8>,
        execution_config: vector<u8>,
        epoch_interval_microsecs: u64,
        minimum_stake: u128,
        maximum_stake: u128,
        recurring_lockup_duration_secs: u64,
        allow_validator_set_change: bool,
        rewards_rate: u64,
        rewards_rate_denominator: u64,
        voting_power_increase_limit: u64,
    ) {
        // Initialize the endless framework account. This is the account where system resources and modules will be
        // deployed to. This will be entirely managed by on-chain governance and no entities have the key or privileges
        // to use this account.
        let (endless_framework_account, endless_framework_signer_cap) = account::create_framework_reserved_account(@endless_framework);
        // Initialize account configs on endless framework account.
        account::initialize(&endless_framework_account);

        transaction_validation::initialize(
            &endless_framework_account,
            b"script_prologue",
            b"multi_agent_script_prologue",
            b"epilogue",
        );

        // Give the decentralized on-chain governance control over the core framework account.
        endless_governance::store_signer_cap(&endless_framework_account, @endless_framework, endless_framework_signer_cap);

        // put reserved framework reserved accounts under endless governance
        let framework_reserved_addresses = vector<address>[@0x2, @0x3, @0x4, @0x5, @0x6, @0x7, @0x8, @0x9, @0xa];
        while (!vector::is_empty(&framework_reserved_addresses)) {
            let address = vector::pop_back<address>(&mut framework_reserved_addresses);
            let (_, framework_signer_cap) = account::create_framework_reserved_account(address);
            endless_governance::store_signer_cap(&endless_framework_account, address, framework_signer_cap);
        };

        consensus_config::initialize(&endless_framework_account, consensus_config);
        execution_config::set(&endless_framework_account, execution_config);
        version::initialize(&endless_framework_account, initial_version);
        stake::initialize(&endless_framework_account);
        staking_config::initialize(
            &endless_framework_account,
            minimum_stake,
            maximum_stake,
            recurring_lockup_duration_secs,
            allow_validator_set_change,
            rewards_rate,
            rewards_rate_denominator,
            voting_power_increase_limit,
        );
        storage_gas::initialize(&endless_framework_account);
        gas_schedule::initialize(&endless_framework_account, gas_schedule);

        // Ensure we can create aggregators for supply, but not enable it for common use just yet.
        aggregator_factory::initialize_aggregator_factory(&endless_framework_account);
        chain_id::initialize(&endless_framework_account, chain_id);
        reconfiguration::initialize(&endless_framework_account);
        block::initialize(&endless_framework_account, epoch_interval_microsecs);
        state_storage::initialize(&endless_framework_account);
        timestamp::set_time_has_started(&endless_framework_account);
        endless_governance::initialize_partial_voting(&endless_framework_account);
    }

    /// Genesis step 2: Initialize Endless coin and transaction fee distribution.
    fun initialize_endless_coin(endless_framework: &signer) {
        let (mint_cap,burn_cap, transfer_cap) = endless_coin::initialize(endless_framework);
        // Give stake module MintCapability<EndlessCoin> so it can mint rewards.
        stake::store_endless_coin_cap(endless_framework, mint_cap, transfer_cap);
        // Give transaction_fee module BurnCapability<EndlessCoin> so it can burn gas.
        transaction_fee::store_endless_coin_burn_cap(endless_framework, burn_cap);
        // Give transaction_fee module MintCapability<EndlessCoin> so it can mint refunds.
        transaction_fee::store_endless_coin_mint_cap(endless_framework, mint_cap);
        // Enable collect tx fee and burn it all
        transaction_fee::initialize_fee_collection_and_distribution(endless_framework, 100);
    }

    /// Only called for testnets and e2e tests.
    fun initialize_core_resources_and_endless_coin(
        endless_framework: &signer,
        core_resources_auth_key: vector<u8>,
        mint_to_core_resources: bool,
    ) {
        let (mint_cap, burn_cap, transfer_cap) = endless_coin::initialize(endless_framework);
        // Give stake module MintCapability<EndlessCoin> so it can mint rewards.
        stake::store_endless_coin_cap(endless_framework, mint_cap, transfer_cap);

        // delete
        // locking_coin_ex::start_distribut_coins_test(endless_framework);

        // Give transaction_fee module BurnCapability<EndlessCoin> so it can burn gas.
        transaction_fee::store_endless_coin_burn_cap(endless_framework, burn_cap);
        // Give transaction_fee module MintCapability<EndlessCoin> so it can mint refunds.
        transaction_fee::store_endless_coin_mint_cap(endless_framework, mint_cap);
        transaction_fee::initialize_fee_collection_and_distribution(endless_framework, /*burn_percentage*/100);

        let core_resources = account::create_account(@core_resources);
        account::rotate_authentication_key_internal(&core_resources, vector[core_resources_auth_key]);
        endless_coin::configure_accounts_for_test(endless_framework, &core_resources, mint_cap, transfer_cap);
  
        if (mint_to_core_resources) {
            endless_coin::mint(&core_resources, @core_resources, 18446744073709551615);
        };
    }

    fun create_accounts(endless_framework: &signer, accounts: vector<AccountMap>) {
        let unique_accounts = vector::empty();
        vector::for_each_ref(&accounts, |account_map| {
            let account_map: &AccountMap = account_map;
            assert!(
                !vector::contains(&unique_accounts, &account_map.account_address),
                error::already_exists(EDUPLICATE_ACCOUNT),
            );
            vector::push_back(&mut unique_accounts, account_map.account_address);

            create_account(
                endless_framework,
                account_map.account_address,
                account_map.balance,
            );
        });
    }

    fun initialize_locking_coin_ex(endless_framework: &signer, configs: vector<LockingConfig>) {
        locking_coin_ex::start_distribute_coins(endless_framework, configs);
    }

    fun initialize_reward_distribution(endless_framework: &signer, configs: vector<AccountShare>) {
        stake::initialize_reward_split(endless_framework, configs);
    }

    /// This creates an funds an account if it doesn't exist.
    /// If it exists, it just returns the signer.
    fun create_account(endless_framework: &signer, account_address: address, balance: u128): signer {
        if (account::exists_at(account_address)) {
            create_signer(account_address)
        } else {
            let account = account::create_account(account_address);
            if (balance > 0) {
                endless_coin::mint(endless_framework, account_address, balance);
            };
            account
        }
    }

    fun create_employee_validators(
        employee_vesting_start: u64,
        employee_vesting_period_duration: u64,
        employees: vector<EmployeeAccountMap>,
    ) {
        let unique_accounts = vector::empty();

        vector::for_each_ref(&employees, |employee_group| {
            let j = 0;
            let employee_group: &EmployeeAccountMap = employee_group;
            let num_employees_in_group = vector::length(&employee_group.accounts);

            let buy_ins = simple_map::create();
            let all_buying_coins = endless_coin::zero();

            while (j < num_employees_in_group) {
                let account = vector::borrow(&employee_group.accounts, j);
                assert!(
                    !vector::contains(&unique_accounts, account),
                    error::already_exists(EDUPLICATE_ACCOUNT),
                );
                vector::push_back(&mut unique_accounts, *account);

                let employee = create_signer(*account);
                let total = endless_coin::balance(*account);
                let store = primary_fungible_store::ensure_primary_store_exists(*account, endless_coin::get_metadata());
                let fa = fungible_asset::withdraw(&employee, store, total);
                let fa_amount = fungible_asset::amount(&fa);
                simple_map::add(&mut buy_ins, *account, fa_amount);
                fungible_asset::merge(&mut all_buying_coins, fa);

                j = j + 1;
            };

            let j = 0;
            let num_vesting_events = vector::length(&employee_group.vesting_schedule_numerator);
            let schedule = vector::empty();

            while (j < num_vesting_events) {
                let numerator = vector::borrow(&employee_group.vesting_schedule_numerator, j);
                let event = fixed_point64::create_from_rational((*numerator as u128), (employee_group.vesting_schedule_denominator as u128));
                vector::push_back(&mut schedule, event);

                j = j + 1;
            };

            let vesting_schedule = vesting::create_vesting_schedule(
                schedule,
                employee_vesting_start,
                employee_vesting_period_duration,
            );

            let admin = employee_group.validator.validator_config.owner_address;
            let admin_signer = &create_signer(admin);
            let contract_address = vesting::create_vesting_contract(
                admin_signer,
                &employee_group.accounts,
                buy_ins,
                all_buying_coins,
                vesting_schedule,
                admin,
                employee_group.validator.validator_config.operator_address,
                employee_group.validator.validator_config.voter_address,
                employee_group.validator.commission_percentage,
                x"",
            );
            let pool_address = vesting::stake_pool_address(contract_address);

            if (employee_group.beneficiary_resetter != @0x0) {
                vesting::set_beneficiary_resetter(admin_signer, contract_address, employee_group.beneficiary_resetter);
            };

            let validator = &employee_group.validator.validator_config;
            assert!(
                account::exists_at(validator.owner_address),
                error::not_found(EACCOUNT_DOES_NOT_EXIST),
            );
            assert!(
                account::exists_at(validator.operator_address),
                error::not_found(EACCOUNT_DOES_NOT_EXIST),
            );
            assert!(
                account::exists_at(validator.voter_address),
                error::not_found(EACCOUNT_DOES_NOT_EXIST),
            );
            if (employee_group.validator.join_during_genesis) {
                initialize_validator(pool_address, validator);
            };
        });
    }

    fun create_initialize_validators_with_commission(
        endless_framework: &signer,
        use_staking_contract: bool,
        validators: vector<ValidatorConfigurationWithCommission>,
    ) {
        vector::for_each_ref(&validators, |validator| {
            let validator: &ValidatorConfigurationWithCommission = validator;
            create_initialize_validator(endless_framework, validator, use_staking_contract);
        });

        // Destroy the endless framework account's ability to mint coins now that we're done with setting up the initial
        // validators.
        endless_coin::destroy_coin_cap(endless_framework);

        stake::on_new_epoch();
    }

    /// Sets up the initial validator set for the network.
    /// The validator "owner" accounts, and their authentication
    /// Addresses (and keys) are encoded in the `owners`
    /// Each validator signs consensus messages with the private key corresponding to the Ed25519
    /// public key in `consensus_pubkeys`.
    /// Finally, each validator must specify the network address
    /// (see types/src/network_address/mod.rs) for itself and its full nodes.
    ///
    /// Network address fields are a vector per account, where each entry is a vector of addresses
    /// encoded in a single BCS byte array.
    fun create_initialize_validators(endless_framework: &signer, validators: vector<ValidatorConfiguration>) {
        let validators_with_commission = vector::empty();
        vector::for_each_reverse(validators, |validator| {
            let validator_with_commission = ValidatorConfigurationWithCommission {
                validator_config: validator,
                commission_percentage: 0,
                join_during_genesis: true,
            };
            vector::push_back(&mut validators_with_commission, validator_with_commission);
        });

        create_initialize_validators_with_commission(endless_framework, false, validators_with_commission);
    }

    fun create_initialize_validator(
        endless_framework: &signer,
        commission_config: &ValidatorConfigurationWithCommission,
        use_staking_contract: bool,
    ) {
        let validator = &commission_config.validator_config;

        let owner = &create_account(endless_framework, validator.owner_address, validator.stake_amount);
        create_account(endless_framework, validator.operator_address, 0);
        create_account(endless_framework, validator.voter_address, 0);

        // Initialize the stake pool and join the validator set.
        let pool_address = if (use_staking_contract) {
            staking_contract::create_staking_contract(
                owner,
                validator.operator_address,
                validator.voter_address,
                validator.stake_amount,
                commission_config.commission_percentage,
                x"",
            );
            staking_contract::stake_pool_address(validator.owner_address, validator.operator_address)
        } else {
            stake::initialize_stake_owner(
                owner,
                validator.stake_amount,
                validator.operator_address,
                validator.voter_address,
            );
            validator.owner_address
        };

        if (commission_config.join_during_genesis) {
            initialize_validator(pool_address, validator);
        };
    }

    fun initialize_validator(pool_address: address, validator: &ValidatorConfiguration) {
        let operator = &create_signer(validator.operator_address);

        stake::rotate_consensus_key(
            operator,
            pool_address,
            validator.consensus_pubkey,
            validator.proof_of_possession,
        );
        stake::update_network_and_fullnode_addresses(
            operator,
            pool_address,
            validator.network_addresses,
            validator.full_node_network_addresses,
        );
        stake::join_validator_set_internal(operator, pool_address);
    }

    /// The last step of genesis.
    fun set_genesis_end(endless_framework: &signer) {
        chain_status::set_genesis_end(endless_framework);
    }

    #[verify_only]
    use std::features;

    #[verify_only]
    fun initialize_for_verification(
        gas_schedule: vector<u8>,
        chain_id: u8,
        initial_version: u64,
        consensus_config: vector<u8>,
        execution_config: vector<u8>,
        epoch_interval_microsecs: u64,
        minimum_stake: u128,
        maximum_stake: u128,
        recurring_lockup_duration_secs: u64,
        allow_validator_set_change: bool,
        rewards_rate: u64,
        rewards_rate_denominator: u64,
        voting_power_increase_limit: u64,
        endless_framework: &signer,
        min_voting_threshold: u128,
        required_proposer_stake: u128,
        voting_duration_secs: u64,
        accounts: vector<AccountMap>,
        employee_vesting_start: u64,
        employee_vesting_period_duration: u64,
        employees: vector<EmployeeAccountMap>,
        validators: vector<ValidatorConfigurationWithCommission>
    ) {
        initialize(
            gas_schedule,
            chain_id,
            initial_version,
            consensus_config,
            execution_config,
            epoch_interval_microsecs,
            minimum_stake,
            maximum_stake,
            recurring_lockup_duration_secs,
            allow_validator_set_change,
            rewards_rate,
            rewards_rate_denominator,
            voting_power_increase_limit
        );
        features::change_feature_flags(endless_framework, vector[1, 2], vector[]);
        initialize_endless_coin(endless_framework);
        endless_governance::initialize_for_verification(
            endless_framework,
            min_voting_threshold,
            required_proposer_stake,
            voting_duration_secs
        );
        create_accounts(endless_framework, accounts);
        create_employee_validators(employee_vesting_start, employee_vesting_period_duration, employees);
        create_initialize_validators_with_commission(endless_framework, true, validators);
        set_genesis_end(endless_framework);
    }

    #[test_only]
    public fun setup() {
        initialize(
            x"000000000000000000", // empty gas schedule
            4u8, // TESTING chain ID
            0,
            x"12",
            x"13",
            1,
            0,
            1,
            1,
            true,
            1,
            1,
            30,
        )
    }

    #[test]
    fun test_setup() {
        setup();
        assert!(account::exists_at(@endless_framework), 1);
        assert!(account::exists_at(@0x2), 1);
        assert!(account::exists_at(@0x3), 1);
        assert!(account::exists_at(@0x4), 1);
        assert!(account::exists_at(@0x5), 1);
        assert!(account::exists_at(@0x6), 1);
        assert!(account::exists_at(@0x7), 1);
        assert!(account::exists_at(@0x8), 1);
        assert!(account::exists_at(@0x9), 1);
        assert!(account::exists_at(@0xa), 1);
    }

    #[test(endless_framework = @0x1)]
    fun test_create_account(endless_framework: &signer) {
        setup();
        initialize_endless_coin(endless_framework);

        let addr = @0x121341; // 01 -> 0a are taken
        let test_signer_before = create_account(endless_framework, addr, 15);
        let test_signer_after = create_account(endless_framework, addr, 500);
        assert!(test_signer_before == test_signer_after, 0);
        assert!(endless_coin::balance(addr) == 15, 1);
    }

    #[test(endless_framework = @0x1)]
    fun test_create_accounts(endless_framework: &signer) {
        setup();
        initialize_endless_coin(endless_framework);

        // 01 -> 0a are taken
        let addr0 = @0x121341;
        let addr1 = @0x121345;

        let accounts = vector[
            AccountMap {
                account_address: addr0,
                balance: 12345,
            },
            AccountMap {
                account_address: addr1,
                balance: 67890,
            },
        ];

        create_accounts(endless_framework, accounts);
        assert!(endless_coin::balance(addr0) == 12345, 0);
        assert!(endless_coin::balance(addr1) == 67890, 1);

        create_account(endless_framework, addr0, 23456);
        assert!(endless_coin::balance(addr0) == 12345, 2);
    }
}

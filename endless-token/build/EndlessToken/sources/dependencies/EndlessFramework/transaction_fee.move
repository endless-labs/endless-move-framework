/// This module provides an interface to burn or collect and redistribute transaction fees.
module endless_framework::transaction_fee {
    // use endless_framework::coin::{Self, AggregatableCoin, BurnCapability, Coin, MintCapability};
    use endless_framework::endless_coin;
    use endless_framework::fungible_asset::{FungibleAsset, AggregatableCoin, Self, MintRef, BurnRef};
    use endless_framework::primary_fungible_store;
    use endless_framework::stake;
    use endless_framework::system_addresses;
    use std::error;
    use endless_framework::event;

    friend endless_framework::block;
    friend endless_framework::genesis;
    friend endless_framework::reconfiguration;
    friend endless_framework::transaction_validation;

    /// Gas fees are already being collected and the struct holding
    /// information about collected amounts is already published.
    const EALREADY_COLLECTING_FEES: u64 = 1;

    /// The burn percentage is out of range [0, 100].
    const EINVALID_BURN_PERCENTAGE: u64 = 3;

    /// No longer supported.
    const ENO_LONGER_SUPPORTED: u64 = 4;

    /// Stores burn capability to burn the gas fees.
    struct EndlessCoinCapabilities has key {
        burn_cap: BurnRef,
    }

    /// Stores mint capability to mint the refunds.
    struct EndlessCoinMintCapability has key {
        mint_cap: MintRef,
    }

    /// Stores information about the block proposer and the amount of fees
    /// collected when executing the block.
    struct CollectedFeesPerBlock has key {
        amount: AggregatableCoin,
        storage_fee: AggregatableCoin,
        // Because used aggregator above, so this struct change will be delayed.
        // But a delayed change can not change the data size.
        // If use Option<address>, `some` and `none` have different size.
        // So we use address instead. @0x0 means unset.
        proposer: address,
        burn_percentage: u8,
    }

    #[event]
    /// Breakdown of fee charge and refund for a transaction.
    /// The structure is:
    ///
    /// - Net charge or refund (not in the statement)
    ///    - total charge: total_charge_gas_units, matches `gas_used` in the on-chain `TransactionInfo`.
    ///      This is the sum of the sub-items below. Notice that there's potential precision loss when
    ///      the conversion between internal and external gas units and between native token and gas
    ///      units, so it's possible that the numbers don't add up exactly. -- This number is the final
    ///      charge, while the break down is merely informational.
    ///        - gas charge for execution (CPU time): `execution_gas_units`
    ///        - gas charge for IO (storage random access): `io_gas_units`
    ///        - storage fee charge (storage space): `storage_fee_veins`, to be included in
    ///          `total_charge_gas_unit`, this number is converted to gas units according to the user
    ///          specified `gas_unit_price` on the transaction.
    ///    - storage deletion refund: `storage_fee_refund_veins`, this is not included in `gas_used` or
    ///      `total_charge_gas_units`, the net charge / refund is calculated by
    ///      `total_charge_gas_units` * `gas_unit_price` - `storage_fee_refund_veins`.
    ///
    /// This is meant to emitted as a module event.
    struct FeeStatement has drop, store {
        /// Total gas charge.
        total_charge_gas_units: u64,
        /// Execution gas charge.
        execution_gas_units: u64,
        /// IO gas charge.
        io_gas_units: u64,
        /// Storage fee charge.
        storage_fee_veins: u64,
        /// Storage fee refund.
        storage_fee_refund_veins: u64,
        /// Gas payer
        gas_payer: address,
    }

    /// Initializes the resource storing information about gas fees collection and
    /// distribution. Should be called by genesis.
    public(friend) fun initialize_fee_collection_and_distribution(endless_framework: &signer, burn_percentage: u8) {
        system_addresses::assert_endless_framework(endless_framework);
        assert!(
            !exists<CollectedFeesPerBlock>(@endless_framework),
            error::already_exists(EALREADY_COLLECTING_FEES)
        );
        assert!(burn_percentage <= 100, error::out_of_range(EINVALID_BURN_PERCENTAGE));

        // Make sure stakng module is aware of transaction fees collection.
        stake::initialize_validator_fees(endless_framework);

        // Initially, no fees are collected and the block proposer is not set.
        let collected_fees = CollectedFeesPerBlock {
            amount: fungible_asset::initialize_aggregatable_coin(endless_coin::get_metadata()),
            storage_fee: fungible_asset::initialize_aggregatable_coin(endless_coin::get_metadata()),
            proposer: @0x0,
            burn_percentage,
        };
        move_to(endless_framework, collected_fees);
    }

    fun is_fees_collection_enabled(): bool {
        exists<CollectedFeesPerBlock>(@endless_framework)
    }

    /// Sets the burn percentage for collected fees to a new value. Should be called by on-chain governance.
    public fun upgrade_burn_percentage(
        endless_framework: &signer,
        new_burn_percentage: u8
    ) acquires EndlessCoinCapabilities, CollectedFeesPerBlock {
        system_addresses::assert_endless_framework(endless_framework);
        assert!(new_burn_percentage <= 100, error::out_of_range(EINVALID_BURN_PERCENTAGE));

        // Prior to upgrading the burn percentage, make sure to process collected
        // fees. Otherwise we would use the new (incorrect) burn_percentage when
        // processing fees later!
        process_collected_fees();

        if (is_fees_collection_enabled()) {
            // Upgrade has no effect unless fees are being collected.
            let burn_percentage = &mut borrow_global_mut<CollectedFeesPerBlock>(@endless_framework).burn_percentage;
            *burn_percentage = new_burn_percentage
        }
    }

    /// Registers the proposer of the block for gas fees collection. This function
    /// can only be called at the beginning of the block.
    public(friend) fun register_proposer_for_fee_collection(proposer_addr: address) acquires CollectedFeesPerBlock {
        if (is_fees_collection_enabled()) {
            let collected_fees = borrow_global_mut<CollectedFeesPerBlock>(@endless_framework);
            collected_fees.proposer = proposer_addr
        }
    }

    /// Burns a specified fraction of the coin.
    fun burn_coin_fraction(fa: &mut FungibleAsset, burn_percentage: u8) acquires EndlessCoinCapabilities {
        assert!(burn_percentage <= 100, error::out_of_range(EINVALID_BURN_PERCENTAGE));

        let collected_amount = fungible_asset::amount(fa);
        spec {
            // We assume that `burn_percentage * collected_amount` does not overflow.
            assume burn_percentage * collected_amount <= MAX_U64;
        };
        let amount_to_burn = (burn_percentage as u128) * collected_amount / 100;
        if (amount_to_burn > 0) {
            let burn_fa = fungible_asset::extract(fa, amount_to_burn);
            fungible_asset::burn(&borrow_global<EndlessCoinCapabilities>(@endless_framework).burn_cap, burn_fa);
        }
    }

    /// Calculates the fee which should be distributed to the block proposer at the
    /// end of an epoch, and records it in the system. This function can only be called
    /// at the beginning of the block or during reconfiguration.
    public(friend) fun process_collected_fees() acquires EndlessCoinCapabilities, CollectedFeesPerBlock {
        if (!is_fees_collection_enabled()) {
            return
        };
        let collected_fees = borrow_global_mut<CollectedFeesPerBlock>(@endless_framework);

        // If there are no collected fees, only unset the proposer. See the rationale for
        // setting proposer to @0x0 below.
        if (fungible_asset::is_aggregatable_coin_zero(&collected_fees.amount)) {
            if (collected_fees.proposer != @0x0) {
                collected_fees.proposer = @0x0;
            };
            return
        };

        // Otherwise get the collected fee, and check if it can distributed later.
        let coin = fungible_asset::drain_aggregatable_coin(&mut collected_fees.amount);
        if (collected_fees.proposer != @0x0) {
            // Extract the address of proposer here and reset it to @0x0. This
            // is particularly useful to avoid any undesired side-effects where coins are
            // collected but never distributed or distributed to the wrong account.
            // With this design, processing collected fees enforces that all fees will be burnt
            // unless the proposer is specified in the block prologue. When we have a governance
            // proposal that triggers reconfiguration, we distribute pending fees and burn the
            // fee for the proposal. Otherwise, that fee would be leaked to the next block.
            let proposer = collected_fees.proposer;
            collected_fees.proposer = @0x0;

            // Since the block can be produced by the VM itself, we have to make sure we catch
            // this case.
            if (proposer == @vm_reserved) {
                burn_coin_fraction(&mut coin, 100);
                fungible_asset::destroy_zero(coin);
                return
            };

            burn_coin_fraction(&mut coin, collected_fees.burn_percentage);
            stake::add_transaction_fee(proposer, coin);
            return
        };

        // If checks did not pass, simply burn all collected coins and return none.
        burn_coin_fraction(&mut coin, 100);
        fungible_asset::destroy_zero(coin)
    }

    /// Burn transaction fees in epilogue.
    public(friend) fun burn_fee(account: address, fee: u128) acquires EndlessCoinCapabilities {
        primary_fungible_store::burn(
            &borrow_global<EndlessCoinCapabilities>(@endless_framework).burn_cap,
            account,
            fee,
        );
    }

    /// Storage refund in epilogue.
    public(friend) fun storage_refund(account: address, refund: u128) acquires CollectedFeesPerBlock {
        let collected_fees = borrow_global_mut<CollectedFeesPerBlock>(@endless_framework);
        let collected_storage_fees = &mut collected_fees.storage_fee;
        let fa = fungible_asset::extract_aggregatable_coin(collected_storage_fees, refund);
        let metadata = fungible_asset::metadata_from_asset(&fa);
        let store = primary_fungible_store::primary_store(account, metadata);
        fungible_asset::deposit(store, fa);
    }

    /// Collect transaction fees in epilogue.
    public(friend) fun collect_fee(account: address, fee: u128, storage_fee: u128): bool acquires CollectedFeesPerBlock {
        let collected_fees = borrow_global_mut<CollectedFeesPerBlock>(@endless_framework);

        // Here, we are always optimistic and always collect fees. If the proposer is not set,
        // or we cannot redistribute fees later for some reason (e.g. account cannot receive EndsCoin)
        // we burn them all at once. This way we avoid having a check for every transaction epilogue.
        let collected_amount = &mut collected_fees.amount;

        let metadata = fungible_asset::metadata_from_aggregatable_coin(collected_amount);
        // primary store address of account
        let store_addr = primary_fungible_store::primary_store_address(account, metadata);
        // does not include storage fee
        let success = fungible_asset::collect_into_aggregatable_coin(store_addr, fee, collected_amount);
        if (!success) {
            return false
        };
        // storage fee
        let collected_storage_amount = &mut collected_fees.storage_fee;
        fungible_asset::collect_into_aggregatable_coin(store_addr, storage_fee, collected_storage_amount)
    }

    /// Only called during genesis.
    public(friend) fun store_endless_coin_burn_cap(endless_framework: &signer, burn_cap: BurnRef) {
        system_addresses::assert_endless_framework(endless_framework);
        move_to(endless_framework, EndlessCoinCapabilities { burn_cap })
    }

    /// Only called during genesis.
    public(friend) fun store_endless_coin_mint_cap(endless_framework: &signer, mint_cap: MintRef) {
        system_addresses::assert_endless_framework(endless_framework);
        move_to(endless_framework, EndlessCoinMintCapability { mint_cap })
    }

    #[deprecated]
    public fun initialize_storage_refund(_: &signer) {
        abort error::not_implemented(ENO_LONGER_SUPPORTED)
    }

    // Called by the VM after epilogue.
    fun emit_fee_statement(fee_statement: FeeStatement) {
        event::emit(fee_statement)
    }

    #[test(endless_framework = @endless_framework)]
    fun test_initialize_fee_collection_and_distribution(endless_framework: signer) acquires CollectedFeesPerBlock {
        endless_coin::initialize_for_test(&endless_framework);
        initialize_fee_collection_and_distribution(&endless_framework, 25);

        // Check struct has been published.
        assert!(exists<CollectedFeesPerBlock>(@endless_framework), 0);

        // Check that initial balance is 0 and there is no proposer set.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@endless_framework);
        assert!(fungible_asset::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(collected_fees.proposer == @0x0, 0);
        assert!(collected_fees.burn_percentage == 25, 0);
    }

    #[test(endless_framework = @endless_framework)]
    fun test_burn_fraction_calculation(endless_framework: signer) acquires EndlessCoinCapabilities {
        use endless_framework::endless_coin;
        let (mint_cap, burn_cap, transfer_cap) = endless_coin::initialize_for_test(&endless_framework);
        store_endless_coin_burn_cap(&endless_framework, burn_cap);

        let c1 = fungible_asset::mint(&mint_cap, 100);
        assert!(endless_coin::supply() == 100, 0);

        // Burning 25%.
        burn_coin_fraction(&mut c1, 25);
        assert!(fungible_asset::amount(&c1) == 75, 0);
        assert!(endless_coin::supply() == 75, 0);

        // Burning 0%.
        burn_coin_fraction(&mut c1, 0);
        assert!(fungible_asset::amount(&c1) == 75, 0);
        assert!(endless_coin::supply() == 75, 0);

        // Burning remaining 100%.
        burn_coin_fraction(&mut c1, 100);
        assert!(fungible_asset::amount(&c1) == 0, 0);
        assert!(endless_coin::supply() == 0, 0);

        fungible_asset::destroy_zero(c1);

        let c2 = fungible_asset::mint(&mint_cap, 10);
        assert!(endless_coin::supply() == 10, 0);

        burn_coin_fraction(&mut c2, 5);
        assert!(fungible_asset::amount(&c2) == 10, 0);
        assert!(endless_coin::supply() == 10, 0);

        burn_coin_fraction(&mut c2, 100);
        fungible_asset::destroy_zero(c2);
        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_transfer_cap(transfer_cap);
    }

    #[test(endless_framework = @endless_framework, alice = @0xa11ce, bob = @0xb0b, carol = @0xca101)]
    fun test_fees_distribution(
        endless_framework: signer,
        alice: signer,
        bob: signer,
        carol: signer,
    ) acquires EndlessCoinCapabilities, CollectedFeesPerBlock {
        use std::signer;
        use endless_framework::endless_account;
        use endless_framework::endless_coin;

        // Initialization.
        let (mint_cap, burn_cap, transfer_cap) = endless_coin::initialize_for_test(&endless_framework);
        store_endless_coin_burn_cap(&endless_framework, burn_cap);
        initialize_fee_collection_and_distribution(&endless_framework, 10);

        // Create dummy accounts.
        let alice_addr = signer::address_of(&alice);
        let bob_addr = signer::address_of(&bob);
        let carol_addr = signer::address_of(&carol);
        endless_account::create_account(alice_addr);
        endless_account::create_account(bob_addr);
        endless_account::create_account(carol_addr);
        primary_fungible_store::deposit(alice_addr, fungible_asset::mint(&mint_cap, 10000));
        primary_fungible_store::deposit(bob_addr, fungible_asset::mint(&mint_cap, 10000));
        primary_fungible_store::deposit(carol_addr, fungible_asset::mint(&mint_cap, 10000));
        assert!(endless_coin::supply() == 30000, 0);

        // Block 1 starts.
        process_collected_fees();
        register_proposer_for_fee_collection(alice_addr);

        // Check that there was no fees distribution in the first block.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@endless_framework);
        assert!(fungible_asset::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(collected_fees.proposer == alice_addr, 0);
        assert!(endless_coin::supply() == 30000, 0);

        // Simulate transaction fee collection - here we simply collect some fees from Bob.
        collect_fee(bob_addr, 100, 0);
        collect_fee(bob_addr, 500, 0);
        collect_fee(bob_addr, 400, 0);

        // Now Bob must have 1000 less in his account. Alice and Carol have the same amounts.
        assert!(endless_coin::balance(alice_addr) == 10000, 0);
        assert!(endless_coin::balance(bob_addr) == 9000, 0);
        assert!(endless_coin::balance(carol_addr) == 10000, 0);

        // Block 2 starts.
        process_collected_fees();
        register_proposer_for_fee_collection(bob_addr);

        // Collected fees from Bob must have been assigned to Alice.
        assert!(stake::get_validator_fee(alice_addr) == 900, 0);
        assert!(endless_coin::balance(alice_addr) == 10000, 0);
        assert!(endless_coin::balance(bob_addr) == 9000, 0);
        assert!(endless_coin::balance(carol_addr) == 10000, 0);

        // Also, aggregator coin is drained and total supply is slightly changed (10% of 1000 is burnt).
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@endless_framework);
        assert!(fungible_asset::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(collected_fees.proposer == bob_addr, 0);
        assert!(endless_coin::supply() == 29900, 0);

        // Simulate transaction fee collection one more time.
        collect_fee(bob_addr, 5000, 0);
        collect_fee(bob_addr, 4000, 0);

        assert!(endless_coin::balance(alice_addr) == 10000, 0);
        assert!(endless_coin::balance(bob_addr) == 0, 0);
        assert!(endless_coin::balance(carol_addr) == 10000, 0);

        // Block 3 starts.
        process_collected_fees();
        register_proposer_for_fee_collection(carol_addr);

        // Collected fees should have been assigned to Bob because he was the peoposer.
        assert!(stake::get_validator_fee(alice_addr) == 900, 0);
        assert!(endless_coin::balance(alice_addr) == 10000, 0);
        assert!(stake::get_validator_fee(bob_addr) == 8100, 0);
        assert!(endless_coin::balance(bob_addr) == 0, 0);
        assert!(endless_coin::balance(carol_addr) == 10000, 0);

        // Again, aggregator coin is drained and total supply is changed by 10% of 9000.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@endless_framework);
        assert!(fungible_asset::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(collected_fees.proposer == carol_addr, 0);
        assert!(endless_coin::supply() == 29000, 0);

        // Simulate transaction fee collection one last time.
        collect_fee(alice_addr, 1000, 400);
        collect_fee(alice_addr, 1000, 700);

        // Block 4 starts.
        process_collected_fees();
        register_proposer_for_fee_collection(alice_addr);

        // Check that 2000 was collected from Alice.
        assert!(endless_coin::balance(alice_addr) == 6900, 0);
        assert!(endless_coin::balance(bob_addr) == 0, 0);

        storage_refund(alice_addr, 1100);
        assert!(endless_coin::balance(alice_addr) == 8000, 0);

        // Carol must have some fees assigned now.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@endless_framework);
        assert!(stake::get_validator_fee(carol_addr) == 1800, 0);
        assert!(fungible_asset::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(fungible_asset::is_aggregatable_coin_zero(&collected_fees.storage_fee), 0);
        assert!(collected_fees.proposer == alice_addr, 0);
        assert!(endless_coin::supply() == 28800, 0);

        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_transfer_cap(transfer_cap);
    }
}

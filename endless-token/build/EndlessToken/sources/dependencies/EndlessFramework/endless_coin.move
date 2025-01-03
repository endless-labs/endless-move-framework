/// This module defines a minimal and generic Coin and Balance.
/// modified from https://github.com/move-language/move/tree/main/language/documentation/tutorial
module endless_framework::endless_coin {
    use std::string;
    use std::error;
    use std::signer;
    use std::vector;
    use std::option::{Self, Option};

    use endless_framework::system_addresses;

    use endless_framework::object::{Self, Object};
    use endless_framework::primary_fungible_store;
    use endless_framework::fungible_asset::{ Self, FungibleAsset, Metadata, MintRef,  BurnRef, TransferRef, generate_mint_ref, generate_burn_ref, generate_transfer_ref};


    friend endless_framework::genesis;

    /// Account does not have mint capability
    const ENO_CAPABILITIES: u64 = 1;
    /// Mint capability has already been delegated to this specified address
    const EALREADY_DELEGATED: u64 = 2;
    /// Cannot find delegation of mint capability to this account
    const EDELEGATION_NOT_FOUND: u64 = 3;
    /// Coin amount cannot be zero
    const EZERO_COIN_AMOUNT: u64 = 4;
    /// The value of aggregatable coin used for transaction fees redistribution does not fit in u64.
    const EAGGREGATABLE_COIN_VALUE_TOO_LARGE: u64 = 14;
    /// invalid BURN Ref.
    const EINVALID_BURN_REF: u64 = 15;

    const EDS_SYMBOL: vector<u8> = b"EDS";

    const EDS_DECIMALS: u8 = 8;

    const EDS_METADATA_ADDR: address = @0xc69712057e634bebc9ab02745d2d69ee738e3eb4f5d30189a9acbf8e08fb823e;

    /// Maximum possible aggregatable coin value.
    const MAX_U64: u128 = 18446744073709551615;

    struct EndlessCoinCapabilities has key {
        mint_cap: MintRef,
        transfer_cap: TransferRef,
    }

    /// Delegation token created by delegator and can be claimed by the delegatee as MintCapability.
    struct DelegatedMintCapability has store {
        to: address
    }

    /// The container stores the current pending delegations.
    struct Delegations has key {
        inner: vector<DelegatedMintCapability>,
    }

    /// Can only called during genesis to initialize the Endless Coin.
    /// with fixed address: 0xc69712057e634bebc9ab02745d2d69ee738e3eb4f5d30189a9acbf8e08fb823e
    /// which base58 format adress: ENDLESSsssssssssssssssssssssssssssssssssssss
    public(friend) fun initialize(endless_framework: &signer): (MintRef, BurnRef, TransferRef) {
        system_addresses::assert_endless_framework(endless_framework);
        let constructor_ref = object::create_specific_object_internal(signer::address_of(endless_framework), EDS_METADATA_ADDR);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(),                            // max supply
            string::utf8(b"Endless Coin"),             // name
            string::utf8(EDS_SYMBOL),                  // symbol
            EDS_DECIMALS,                              // decimals
            string::utf8(b"https://www.endless.link/eds-icon.svg"),  // icon
            string::utf8(b"https://www.endless.link"),       // url
        );

        let mint_ref = generate_mint_ref(&constructor_ref);
        let burn_ref = generate_burn_ref(&constructor_ref);
        let transfer_ref = generate_transfer_ref(&constructor_ref);

        let mint_cap = generate_mint_ref(&constructor_ref);
        let transfer_cap= generate_transfer_ref(&constructor_ref);
        move_to(endless_framework, EndlessCoinCapabilities{ mint_cap, transfer_cap});
        (mint_ref, burn_ref, transfer_ref)
    }

    /// check if FA meta addr == @0xc69712057e634bebc9ab02745d2d69ee738e3eb4f5d30189a9acbf8e08fb823e and symbol
    public fun is_true_EDS(fa: &FungibleAsset): bool {
        let meta_data = fungible_asset::metadata_from_asset(fa);
        if (fungible_asset::symbol(meta_data) == string::utf8(EDS_SYMBOL)
            && object::object_address(&meta_data) == EDS_METADATA_ADDR) {
            true
        } else {
            false
        }
    }

    #[view]
    public fun is_account_registered(account: address): bool {
        primary_fungible_store::primary_store_exists(account, get_metadata())
    }

    #[view]
    /// Return EDS balance of account.
    public fun balance(account: address): u128 {
        primary_fungible_store::balance<Metadata>(account, get_metadata())
    }

    #[view]
    public fun check_minimum_balance(account: address, least: u128): bool {
        primary_fungible_store::check_minimum_balance<Metadata>(account, get_metadata(), least)
    }

    #[view]
    /// Return the address of the metadata that's created when this module is deployed.
    public fun get_metadata(): Object<Metadata> {
        // let metadata_address = object::create_object_address(&@0x1, EDS_SYMBOL);
        // object::address_to_object<Metadata>(metadata_address)
        object::address_to_object<Metadata>(EDS_METADATA_ADDR)
    }

    #[view]
    /// Return Supply of EDS coin.
    public fun supply(): u128 {
        let amount = fungible_asset::supply(get_metadata());
        option::get_with_default(&amount, 0_u128)
    }

    /// Only Endless Creator has mint reference
    public fun has_mint_capability(account: &signer): bool {
        exists<EndlessCoinCapabilities>(signer::address_of(account))
    }

    public fun register(account: address) {
        primary_fungible_store::ensure_primary_store_exists(account, get_metadata());
    }

    public fun withdraw(from: &signer, amount: u128): FungibleAsset {
        primary_fungible_store::withdraw(from, get_metadata(), amount)
    }

    public entry fun transfer(from: &signer, to:address, amount: u128) {
        primary_fungible_store::transfer(from, get_metadata(), to, amount)
    }

    public fun zero(): FungibleAsset {
        fungible_asset::zero(get_metadata())
    }

    /// Only called during genesis to destroy the endless framework account's mint capability once all initial validators
    /// and accounts have been initialized during genesis.
    public(friend) fun destroy_coin_cap(endless_framework: &signer) acquires EndlessCoinCapabilities {
        system_addresses::assert_endless_framework(endless_framework);
        let EndlessCoinCapabilities { mint_cap, transfer_cap } = move_from<EndlessCoinCapabilities>(@endless_framework);
        fungible_asset::destroy_mint_cap(mint_cap);
        fungible_asset::destroy_transfer_cap(transfer_cap);
    }

    /// Can only be called during genesis for tests to grant mint capability to endless framework and core resources
    /// accounts.
    public(friend) fun configure_accounts_for_test(
        endless_framework: &signer,
        core_resources: &signer,
        mint_cap: MintRef,
        transfer_cap: TransferRef,
    ) {
        system_addresses::assert_endless_framework(endless_framework);

        move_to(core_resources, EndlessCoinCapabilities { mint_cap, transfer_cap });
        move_to(core_resources, Delegations { inner: vector::empty() });
    }

    /// Only callable in tests and testnets where the core resources account exists.
    /// Create new coins and deposit them into dst_addr's account.
    public entry fun mint(
        account: &signer,
        dst_addr: address,
        amount: u128,
    ) acquires EndlessCoinCapabilities {
        let account_addr = signer::address_of(account);

        assert!(
            exists<EndlessCoinCapabilities>(account_addr),
            error::not_found(ENO_CAPABILITIES),
        );

        let mint_cap = &borrow_global<EndlessCoinCapabilities>(account_addr).mint_cap;
        primary_fungible_store::mint(mint_cap, dst_addr, amount);
    }

    /// Burns amount of EDS from endless_framwork
    public fun burn(ref: &BurnRef, amount: u128) {
        assert!(amount > 0, error::invalid_argument(EZERO_COIN_AMOUNT));
        assert!(fungible_asset::burn_ref_metadata(ref) == get_metadata(), error::invalid_argument(EINVALID_BURN_REF));

        let store = primary_fungible_store::primary_store(@endless_framework, get_metadata());
        fungible_asset::burn_from(ref, store, amount);
    }

    /// Only callable in tests and testnets where the core resources account exists.
    /// Create delegated token for the address so the account could claim MintCapability later.
    public entry fun delegate_mint_capability(account: signer, to: address) acquires Delegations {
        system_addresses::assert_core_resource(&account);
        let delegations = &mut borrow_global_mut<Delegations>(@core_resources).inner;
        vector::for_each_ref(delegations, |element| {
            let element: &DelegatedMintCapability = element;
            assert!(element.to != to, error::invalid_argument(EALREADY_DELEGATED));
        });
        vector::push_back(delegations, DelegatedMintCapability { to });
    }

    /// Only callable in tests and testnets where the core resources account exists.
    /// Claim the delegated mint capability and destroy the delegated token.
    public entry fun claim_mint_capability(account: &signer) acquires Delegations, EndlessCoinCapabilities {
        let maybe_index = find_delegation(signer::address_of(account));
        assert!(option::is_some(&maybe_index), EDELEGATION_NOT_FOUND);
        let idx = *option::borrow(&maybe_index);
        let delegations = &mut borrow_global_mut<Delegations>(@core_resources).inner;
        let DelegatedMintCapability { to: _ } = vector::swap_remove(delegations, idx);

        // Make a copy of mint cap and give it to the specified account.
        let mint_cap = borrow_global<EndlessCoinCapabilities>(@core_resources).mint_cap;
        let transfer_cap = borrow_global<EndlessCoinCapabilities>(@core_resources).transfer_cap;
        move_to(account, EndlessCoinCapabilities { mint_cap, transfer_cap });
    }

    fun find_delegation(addr: address): Option<u64> acquires Delegations {
        let delegations = &borrow_global<Delegations>(@core_resources).inner;
        let i = 0;
        let len = vector::length(delegations);
        let index = option::none();
        while (i < len) {
            let element = vector::borrow(delegations, i);
            if (element.to == addr) {
                index = option::some(i);
                break
            };
            i = i + 1;
        };
        index
    }

    public fun get_eds_token_address(): address {
        EDS_METADATA_ADDR
    }

    #[test_only]
    public fun initialize_for_test(endless_framework: &signer): (MintRef, BurnRef, TransferRef) {
        initialize(endless_framework)
    }


}

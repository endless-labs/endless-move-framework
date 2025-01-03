/// A 2-in-1 module that combines managed_fungible_asset and coin_example into one module that when deployed, the
/// deployer will be creating a new managed fungible asset with the hardcoded supply config, name, symbol, and decimals.
/// The address of the asset can be obtained via get_metadata(). As a simple version, it only deals with primary stores.
module endless_token::coin {
    use endless_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata};
    use endless_framework::object::{Self, Object};
    use endless_framework::primary_fungible_store;
    use std::error;
    use std::signer;
    use std::option::{Self, Option};
    use std::string::String;

    /// Only fungible asset metadata owner can make changes.
    const ENOT_OWNER: u64 = 1;

    #[resource_group_member(group = endless_framework::object::ObjectGroup)]
    /// Hold refs to control the minting of fungible assets.
    struct MgmnFAMint has key {
        mint_ref: MintRef
    }

    #[resource_group_member(group = endless_framework::object::ObjectGroup)]
    /// Hold refs to control the burning of fungible assets.
    struct MgmnFABurn has key {
        burn_ref: BurnRef
    }

    #[resource_group_member(group = endless_framework::object::ObjectGroup)]
    /// Hold refs to control the transfer of fungible assets.
    struct MgmnFATransfer has key {
        transfer_ref: TransferRef
    }

    /// Create metadata object and store the refs.
    public entry fun create(
        creator: &signer,
        max_supply: u128,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String
    ) {
        let constructor_ref = &object::create_sticky_object(signer::address_of(creator));
        let max_supply = if (max_supply == 0) {
            option::none()
        } else {
            option::some(max_supply)
        };
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            max_supply,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri
        );

        // Create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);
        move_to(&metadata_object_signer, MgmnFAMint { mint_ref });
        move_to(&metadata_object_signer, MgmnFABurn { burn_ref });
        move_to(&metadata_object_signer, MgmnFATransfer { transfer_ref });
    }

    /// Create metadata object and store the refs.
    public entry fun create_ex(
        creator: &signer,
        coin_author: &auth,
        max_supply: u128,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String
    ) {
        let constructor_ref = &object::create_specific_object(creator, coin_author);
        let max_supply = if (max_supply == 0) {
            option::none()
        } else {
            option::some(max_supply)
        };
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            max_supply,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri
        );

        // Create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);
        move_to(&metadata_object_signer, MgmnFAMint { mint_ref });
        move_to(&metadata_object_signer, MgmnFABurn { burn_ref });
        move_to(&metadata_object_signer, MgmnFATransfer { transfer_ref });
    }

    #[view]
    /// Return the address of the managed fungible asset that's created when this module is deployed.
    public fun get_metadata(asset_address: address): Object<Metadata> {
        object::address_to_object<Metadata>(asset_address)
    }

    #[view]
    /// Get the current supply from the `metadata` object.
    public fun supply(asset: address): Option<u128> {
        let metadata = get_metadata(asset);
        fungible_asset::supply(metadata)
    }

    #[view]
    /// Get the maximum supply from the `metadata` object.
    /// If supply is unlimited (or set explicitly to MAX_U128), none is returned
    public fun maximum(asset: address): Option<u128> {
        let metadata = get_metadata(asset);
        fungible_asset::maximum(metadata)
    }

    #[view]
    /// Get the balance of `account`'s primary store.
    public fun balance(owner_address: address, asset: address): u128 {
        let metadata = get_metadata(asset);
        primary_fungible_store::balance(owner_address, metadata)
    }

    #[view]
    /// Return whether the given account's primary store is frozen.
    public fun is_frozen(owner_address: address, asset: address): bool {
        let metadata = get_metadata(asset);
        primary_fungible_store::is_frozen(owner_address, metadata)
    }

    // :!:>mint
    /// Mint as the owner of metadata object and deposit to a specific account.
    public entry fun mint(
        creator: &signer,
        asset: address,
        to: address,
        amount: u128
    ) acquires MgmnFAMint, MgmnFATransfer {
        let asset = get_metadata(asset);
        let mint_ref = authorized_borrow_mint_refs(creator, asset).mint_ref;
        let transfer_ref = authorized_borrow_transfer_refs(creator, asset).transfer_ref;
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&mint_ref, amount);
        fungible_asset::deposit_with_ref(&transfer_ref, to_wallet, fa);
    } // <:!:mint_to

    /// Transfer as the owner of metadata object ignoring `frozen` field.
    public entry fun transfer(
        sender: &signer,
        asset: address,
        to: address,
        amount: u128
    ) {
        let asset = get_metadata(asset);
        let from_wallet =
            primary_fungible_store::primary_store(signer::address_of(sender), asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        fungible_asset::transfer(sender, from_wallet, to_wallet, amount);
    }

    /// Burn fungible assets as the owner of metadata object.
    public entry fun burn(sender: &signer, asset: address, amount: u128) acquires MgmnFABurn {
        let asset = get_metadata(asset);
        let burn_ref = &borrow_burn_refs(asset).burn_ref;
        let from_wallet =
            primary_fungible_store::primary_store(signer::address_of(sender), asset);
        fungible_asset::burn_from(burn_ref, from_wallet, amount);
    }

    /// Freeze an account so it cannot transfer or receive fungible assets.
    public entry fun freeze_account(
        creator: &signer, asset: address, account: address
    ) acquires MgmnFATransfer {
        let asset = get_metadata(asset);
        let transfer_ref = &authorized_borrow_transfer_refs(creator, asset).transfer_ref;
        let wallet = primary_fungible_store::ensure_primary_store_exists(account, asset);
        fungible_asset::set_frozen_flag(transfer_ref, wallet, true);
    }

    /// Unfreeze an account so it can transfer or receive fungible assets.
    public entry fun unfreeze_account(
        creator: &signer, asset: address, account: address
    ) acquires MgmnFATransfer {
        let asset = get_metadata(asset);
        let transfer_ref = &authorized_borrow_transfer_refs(creator, asset).transfer_ref;
        let wallet = primary_fungible_store::ensure_primary_store_exists(account, asset);
        fungible_asset::set_frozen_flag(transfer_ref, wallet, false);
    }

    /// Only called mint capability once all initial validators
    public entry fun destroy_mint_cap(creator: &signer, asset: address) acquires MgmnFAMint {
        let asset = get_metadata(asset);
        assert!(
            object::is_owner(asset, signer::address_of(creator)),
            error::permission_denied(ENOT_OWNER)
        );
        let MgmnFAMint { mint_ref } = move_from<MgmnFAMint>(signer::address_of(creator));
        fungible_asset::destroy_mint_cap(mint_ref);
    }

    /// Only called burn capability once all initial validators
    public entry fun destroy_burn_cap(creator: &signer, asset: address) acquires MgmnFABurn {
        let asset = get_metadata(asset);
        assert!(
            object::is_owner(asset, signer::address_of(creator)),
            error::permission_denied(ENOT_OWNER)
        );
        let MgmnFABurn { burn_ref } = move_from<MgmnFABurn>(signer::address_of(creator));
        fungible_asset::destroy_burn_cap(burn_ref);
    }

    /// Only called transfer capability once all initial validators
    public entry fun destroy_transfer_cap(creator: &signer, asset: address) acquires MgmnFATransfer {
        let asset = get_metadata(asset);
        assert!(
            object::is_owner(asset, signer::address_of(creator)),
            error::permission_denied(ENOT_OWNER)
        );
        let MgmnFATransfer { transfer_ref } =
            move_from<MgmnFATransfer>(signer::address_of(creator));
        fungible_asset::destroy_transfer_cap(transfer_ref);
    }

    public entry fun set_icon_uri(
        creator: &signer, asset: address, icon_uri: String
    ) {
        let asset = get_metadata(asset);
        fungible_asset::set_icon_uri(creator, asset, icon_uri);
    }

    public entry fun set_project_uri(
        creator: &signer, asset: address, project_uri: String
    ) {
        let asset = get_metadata(asset);
        fungible_asset::set_project_uri(creator, asset, project_uri);
    }

    /// Borrow the immutable reference of the refs of `metadata`.
    /// This validates that the signer is the metadata object's owner.
    inline fun authorized_borrow_mint_refs(
        owner: &signer, asset: Object<Metadata>
    ): &MgmnFAMint acquires MgmnFAMint {
        assert!(
            object::is_owner(asset, signer::address_of(owner)),
            error::permission_denied(ENOT_OWNER)
        );
        borrow_global<MgmnFAMint>(object::object_address(&asset))
    }

    /// Borrow the immutable reference of the refs of `metadata`.
    inline fun borrow_burn_refs(asset: Object<Metadata>): &MgmnFABurn acquires MgmnFABurn {
        borrow_global<MgmnFABurn>(object::object_address(&asset))
    }

    /// Borrow the immutable reference of the refs of `metadata`.
    /// This validates that the signer is the metadata object's owner.
    inline fun authorized_borrow_transfer_refs(
        owner: &signer, asset: Object<Metadata>
    ): &MgmnFATransfer acquires MgmnFATransfer {
        assert!(
            object::is_owner(asset, signer::address_of(owner)),
            error::permission_denied(ENOT_OWNER)
        );
        borrow_global<MgmnFATransfer>(object::object_address(&asset))
    }

    #[test_only]
    use std::string;
    #[test_only]
    use std::bcs;
    #[test_only]
    use endless_std::from_bcs;

    #[test(creator = @0xcafe, coin = @0x1001)]
    fun test_basic_flow(creator: &signer, coin: &auth) acquires MgmnFAMint, MgmnFATransfer, MgmnFABurn {
        create(
            creator,
            0,
            string::utf8(b"CAT Coin"),
            string::utf8(b"CAT"),
            8,
            string::utf8(b"http://example.com/favicon.ico"),
            string::utf8(b"http://example.com")
        );

        create_ex(
            creator,
            coin,
            340_282_366_920_938_463_463_374_607_431_768_211_455,
            string::utf8(b"CAT Coin"),
            string::utf8(b"CAT"),
            8,
            string::utf8(b"http://example.com/favicon.ico"),
            string::utf8(b"http://example.com")
        );

        // create_ex(
        //     creator,
        //     coin_signer,
        //     0,
        //     string::utf8(b"CAT Coin 2"),
        //     string::utf8(b"CAT"),
        //     8,
        //     string::utf8(b"http://example.com/favicon.ico"),
        //     string::utf8(b"http://example.com")
        // ); // should fail
        let creator_address = signer::address_of(creator);
        let aaron_address = @0xface;
        let coin_address = from_bcs::to_address(bcs::to_bytes(coin));

        mint(creator, coin_address, creator_address, 340_282_366_920_938_463_463_374_607_431_768_211_000);
        assert!(balance(creator_address, coin_address) == 340_282_366_920_938_463_463_374_607_431_768_211_000, 4);
        freeze_account(creator, coin_address, creator_address);
        assert!(is_frozen(creator_address, coin_address), 5);

        unfreeze_account(creator, coin_address, creator_address);
        assert!(!is_frozen(creator_address, coin_address), 0);

        transfer(creator, coin_address, aaron_address, 10);
        assert!(balance(aaron_address, coin_address) == 10, 6);
        burn(creator, coin_address, 90);

        set_icon_uri(
            creator,
            coin_address,
            string::utf8(b"http://www.example.com/favicon.ico")
        );
        set_project_uri(
            creator,
            coin_address,
            string::utf8(b"http://www.example.com")
        );
    }
}

//:!:>moon
module faucet::USDC {
    use std::option;
    use std::signer::address_of;
    use std::string;
    use std::string::String;
    use endless_framework::fungible_asset;
    use endless_framework::fungible_asset::{Metadata, BurnRef, MintRef, TransferRef};
    use endless_framework::object;
    use endless_framework::object::{ConstructorRef, Object};
    use endless_framework::primary_fungible_store;
    #[test_only]
    use std::signer;

    const COIN_NAME: vector<u8> = b"ENDLESS USDC";
    const COIN_SYMBOL: vector<u8> = b"USDC";

    struct CapStore has key {
        token_refs: TokenRefs,
    }


    struct TokenRefs has store {
        burn_ref: BurnRef,
        mint_ref: MintRef,
        transfer_ref: TransferRef,
    }

    fun init_module(creator: &signer) {

        let constructor_ref = create_token(creator);
        let token_metadata = object::object_from_constructor_ref<Metadata>(constructor_ref);
        fungible_asset::create_store(constructor_ref, token_metadata);

        move_to(creator, CapStore {
            token_refs: create_lp_token_refs(constructor_ref),
        });

    }

    inline fun create_token(owner: &signer): &ConstructorRef {
        let lp_token_constructor_ref = &object::create_named_object(owner, b"token");
        // We don't enable automatic primary store creation because we need LPs to call into this module for transfers
        // so the fees accounting can be updated correctly.
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            lp_token_constructor_ref,
            option::none(),
            string::utf8(COIN_NAME),
            string::utf8(COIN_SYMBOL),
            6,
            string::utf8(b""),
            string::utf8(b"")
        );
        lp_token_constructor_ref
    }

    fun create_lp_token_refs(constructor_ref: &ConstructorRef): TokenRefs {
        TokenRefs {
            burn_ref: fungible_asset::generate_burn_ref(constructor_ref),
            mint_ref: fungible_asset::generate_mint_ref(constructor_ref),
            transfer_ref: fungible_asset::generate_transfer_ref(constructor_ref),
        }
    }


    public entry fun airdrop(sender: &signer) acquires CapStore {
        let mint_ref = &borrow_global<CapStore>(@faucet).token_refs.mint_ref;
        let coins = fungible_asset::mint(
            mint_ref,
            100_00000000,
        );

        let matedata = fungible_asset::metadata_from_asset(&coins);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(address_of(sender), matedata);

        let transfer_ref = &borrow_global<CapStore>(@faucet).token_refs.transfer_ref;
        fungible_asset::deposit_with_ref(transfer_ref, to_wallet, coins);
    }

    public entry fun airdrop_amount(sender: &signer, amount: u128) acquires CapStore {
        let mint_ref = &borrow_global<CapStore>(@faucet).token_refs.mint_ref;
        let coins = fungible_asset::mint(
            mint_ref,
            amount,
        );

        let matedata = fungible_asset::metadata_from_asset(&coins);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(address_of(sender), matedata);

        let transfer_ref = &borrow_global<CapStore>(@faucet).token_refs.transfer_ref;
        fungible_asset::deposit_with_ref(transfer_ref, to_wallet, coins);
    }

    public entry fun set_icon_uri(creator: &signer, asset: address, icon_uri: String) {
        let asset = get_metadata(asset);
        fungible_asset::set_icon_uri(creator, asset, icon_uri);
    }

    public entry fun set_project_uri(creator: &signer, asset: address, project_uri: String) {
        let asset = get_metadata(asset);
        fungible_asset::set_project_uri(creator, asset, project_uri);
    }


    #[view]
    /// Return the address of the managed fungible asset that's created when this module is deployed.
    public fun get_metadata(asset_address: address): Object<Metadata> {
        object::address_to_object<Metadata>(asset_address)
    }

    #[test(creator = @faucet)]
    fun test_basic_flow(
        creator: &signer,
    ) acquires CapStore {
        init_module(creator);
        let creator_address = signer::address_of(creator);
        let aaron_address = @0xface;
        airdrop(creator);
    }
}


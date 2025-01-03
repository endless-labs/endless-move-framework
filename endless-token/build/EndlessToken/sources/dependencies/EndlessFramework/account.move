module endless_framework::account {
    use std::bcs;
    use std::error;
    use std::hash;
    use std::signer;
    use std::vector;
    use endless_framework::create_signer::create_signer;
    use endless_framework::event::{Self, EventHandle};
    use endless_framework::guid;
    use endless_framework::system_addresses;
    use endless_framework::transaction_context;
    use endless_std::ed25519;
    use endless_std::from_bcs;
    use endless_std::multi_ed25519;
    use endless_std::table::{Self, Table};

    friend endless_framework::endless_account;
    friend endless_framework::endless_coin;
    friend endless_framework::genesis;
    friend endless_framework::multisig_account;
    friend endless_framework::resource_account;
    friend endless_framework::transaction_validation;

    #[event]
    struct AddAuthenticationKey has drop, store {
        account: address,
        auth_keys: vector<vector<u8>>,
    }

    #[event]
    struct RemoveAuthenticationKey has drop, store {
        account: address,
        auth_keys: vector<vector<u8>>,
    }

    #[event]
    struct UpdateSignaturesRequired has drop, store {
        account: address,
        old_num_signatures_required: u64,
        new_num_signatures_required: u64,
    }

    /// Resource representing an account.
    struct Account has key, store {
        authentication_key: vector<vector<u8>>,
        sequence_number: u64,
        guid_creation_num: u64,
        // The number of signatures required to pass a transaction (k in k-of-n).
        num_signatures_required: u64,
    }

    struct SignerCapability has drop, store { account: address }
    /// It is easy to fetch the authentication key of an address by simply reading it from the `Account` struct at that address.
    /// The table in this struct makes it possible to do a reverse lookup: it maps an authentication key, to the address of the account which has that authentication key set.
    ///
    /// This mapping is needed when recovering wallets for accounts whose authentication key has been rotated.
    ///
    /// For example, imagine a freshly-created wallet with address `a` and thus also with authentication key `a`, derived from a PK `pk_a` with corresponding SK `sk_a`.
    /// It is easy to recover such a wallet given just the secret key `sk_a`, since the PK can be derived from the SK, the authentication key can then be derived from the PK, and the address equals the authentication key (since there was no key rotation).
    ///
    /// However, if such a wallet rotates its authentication key to `b` derived from a different PK `pk_b` with SK `sk_b`, how would account recovery work?
    /// The recovered address would no longer be 'a'; it would be `b`, which is incorrect.
    /// This struct solves this problem by mapping the new authentication key `b` to the original address `a` and thus helping the wallet software during recovery find the correct address.
    struct OriginatingAddress has key {
        address_map: Table<vector<u8>, vector<address>>,
    }

    /// This structs stores the challenge message that should be signed during key rotation. First, this struct is
    /// signed by the account owner's current public key, which proves possession of a capability to rotate the key.
    /// Second, this struct is signed by the new public key that the account owner wants to rotate to, which proves
    /// knowledge of this new public key's associated secret key. These two signatures cannot be replayed in another
    /// context because they include the TXN's unique sequence number.
    struct RotationProofChallenge has copy, drop {
        sequence_number: u64, // the sequence number of the account whose key is being rotated
        originator: address, // the address of the account whose key is being rotated
        current_auth_key: vector<vector<u8>>, // the current authentication key of the account whose key is being rotated
        new_public_key: vector<u8>, // the new public key that the account owner wants to rotate to
    }

    const MAX_U64: u128 = 18446744073709551615;

    /// Scheme identifier for Ed25519 signatures used to derive authentication keys for Ed25519 public keys.
    const ED25519_SCHEME: u8 = 0;
    /// Scheme identifier for MultiEd25519 signatures used to derive authentication keys for MultiEd25519 public keys.
    const MULTI_ED25519_SCHEME: u8 = 1;
    /// Scheme identifier used when hashing an account's address together with a seed to derive the address (not the
    /// authentication key) of a resource account. This is an abuse of the notion of a scheme identifier which, for now,
    /// serves to domain separate hashes used to derive resource account addresses from hashes used to derive
    /// authentication keys. Without such separation, an adversary could create (and get a signer for) a resource account
    /// whose address matches an existing address of a MultiEd25519 wallet.
    const DERIVE_RESOURCE_ACCOUNT_SCHEME: u8 = 255;

    /// Account already exists
    const EACCOUNT_ALREADY_EXISTS: u64 = 1;
    /// Account does not exist
    const EACCOUNT_DOES_NOT_EXIST: u64 = 2;
    /// Sequence number exceeds the maximum value for a u64
    const ESEQUENCE_NUMBER_TOO_BIG: u64 = 3;
    /// The provided authentication key has an invalid length
    const EMALFORMED_AUTHENTICATION_KEY: u64 = 4;
    /// Cannot create account because address is reserved
    const ECANNOT_RESERVED_ADDRESS: u64 = 5;
    /// Transaction exceeded its allocated max gas
    const EOUT_OF_GAS: u64 = 6;
    /// Specified current public key is not correct
    const EWRONG_CURRENT_PUBLIC_KEY: u64 = 7;
    /// Specified proof of knowledge required to prove ownership of a public key is invalid
    const EINVALID_PROOF_OF_KNOWLEDGE: u64 = 8;
    /// The caller does not have a digital-signature-based capability to call this function
    const ENO_CAPABILITY: u64 = 9;
    /// The caller does not have a valid rotation capability offer from the other account
    const EINVALID_ACCEPT_ROTATION_CAPABILITY: u64 = 10;
    /// Address to create is not a valid reserved address for Endless framework
    const ENO_VALID_FRAMEWORK_RESERVED_ADDRESS: u64 = 11;
    /// Specified scheme required to proceed with the smart contract operation - can only be ED25519_SCHEME(0) OR MULTI_ED25519_SCHEME(1)
    const EINVALID_SCHEME: u64 = 12;
    /// Abort the transaction if the expected originating address is different from the originating address on-chain
    const EINVALID_ORIGINATING_ADDRESS: u64 = 13;
    /// The signer capability offer doesn't exist at the given address
    const ENO_SUCH_SIGNER_CAPABILITY: u64 = 14;
    /// An attempt to create a resource account on a claimed account
    const ERESOURCE_ACCCOUNT_EXISTS: u64 = 15;
    /// An attempt to create a resource account on an account that has a committed transaction
    const EACCOUNT_ALREADY_USED: u64 = 16;
    /// Offerer address doesn't exist
    const EOFFERER_ADDRESS_DOES_NOT_EXIST: u64 = 17;
    /// The specified rotation capablity offer does not exist at the specified offerer address
    const ENO_SUCH_ROTATION_CAPABILITY_OFFER: u64 = 18;
    // The signer capability is not offered to any address
    const ENO_SIGNER_CAPABILITY_OFFERED: u64 = 19;
    // This account has exceeded the allocated GUIDs it can create. It should be impossible to reach this number for real applications.
    const EEXCEEDED_MAX_GUID_CREATION_NUM: u64 = 20;

    const EUNEXPECTED: u64 = 21;
    const EINVALID_AUTHENTICATION_KEY_COUNT: u64 = 22;
    const EDUPLICATE_AUTHENTICATION_KEY: u64 = 23;
    const EINVALID_AUTHENTICATION_KEY: u64 = 24;
    const EINVALID_NUM_SIGNATURES_REQUIRED: u64 = 25;
    const EACCOUNT_IS_NOT_ORIGINAL: u64 = 26;

    /// Explicitly separate the GUID space between Object and Account to prevent accidental overlap.
    const MAX_GUID_CREATION_NUM: u64 = 0x4000000000000;
    const MAX_MAP_SIZE: u64 = 100;
    const MAX_AUTH_KEY_SIZE: u64 = 16;
    #[test_only]
    /// Create signer for testing, independently of an Endless-style `Account`.
    public fun create_signer_for_test(addr: address): signer { create_signer(addr) }

    /// Only called during genesis to initialize system resources for this module.
    public(friend) fun initialize(endless_framework: &signer) {
        system_addresses::assert_endless_framework(endless_framework);
        move_to(endless_framework, OriginatingAddress {
            address_map: table::new(),
        });
    }

    fun create_account_if_does_not_exist(account_address: address) {
        if (!exists<Account>(account_address)) {
            create_account(account_address);
        }
    }

    /// Publishes a new `Account` resource under `new_address`. A signer representing `new_address`
    /// is returned. This way, the caller of this function can publish additional resources under
    /// `new_address`.
    public(friend) fun create_account(new_address: address): signer {
        // there cannot be an Account resource under new_addr already.
        assert!(!exists<Account>(new_address), error::already_exists(EACCOUNT_ALREADY_EXISTS));

        // NOTE: @core_resources gets created via a `create_account` call, so we do not include it below.
        assert!(
            new_address != @vm_reserved && new_address != @endless_framework && new_address != @endless_token,
            error::invalid_argument(ECANNOT_RESERVED_ADDRESS)
        );

        create_account_unchecked(new_address)
    }

    fun create_account_unchecked(new_address: address): signer {
        let new_account = create_signer(new_address);
        let authentication_key = bcs::to_bytes(&new_address);
        assert!(
            vector::length(&authentication_key) == 32,
            error::invalid_argument(EMALFORMED_AUTHENTICATION_KEY)
        );
        let guid_creation_num = 0;

        move_to(
            &new_account,
            Account {
                authentication_key: vector[authentication_key],
                sequence_number: 0,
                guid_creation_num,
                num_signatures_required: 1,
            }
        );

        new_account
    }

    #[view]
    public fun exists_at(addr: address): bool {
        exists<Account>(addr)
    }

    #[view]
    public fun get_guid_next_creation_num(addr: address): u64 acquires Account {
        borrow_global<Account>(addr).guid_creation_num
    }

    #[view]
    public fun get_sequence_number(addr: address): u64 acquires Account {
        borrow_global<Account>(addr).sequence_number
    }

    public(friend) fun increment_sequence_number(addr: address) acquires Account {
        let sequence_number = &mut borrow_global_mut<Account>(addr).sequence_number;

        assert!(
            (*sequence_number as u128) < MAX_U64,
            error::out_of_range(ESEQUENCE_NUMBER_TOO_BIG)
        );

        *sequence_number = *sequence_number + 1;
    }

    #[view]
    /// Return the number of signatures required
    public fun num_signatures_required(account: address): u64 acquires Account {
        borrow_global<Account>(account).num_signatures_required
    }

    #[view]
    /// Return the authentication key
    public fun get_authentication_key(addr: address): vector<vector<u8>> acquires Account {
        borrow_global<Account>(addr).authentication_key
    }

    #[view]
    /// Check the authentication key, return true if
    /// 1. every key in auth_key is in authentication_key
    /// 2. the number of keys in auth_key is at least num_signatures_required
    public fun check_authentication_key(addr: address, auth_key: vector<vector<u8>>): bool acquires Account {
        let resource = borrow_global<Account>(addr);
        let authentication_key = resource.authentication_key;
        let size = vector::length(&auth_key);
        // Requirements not met
        if (size < resource.num_signatures_required) {
            return false
        };
        let total = vector::length(&authentication_key);
        // Too many auth key
        if (size > total) {
            return false
        };
        while (size > 0) {
            let key = vector::pop_back(&mut auth_key);
            // Do not use `contains` to check, because auth key maybe have duplicate key
            if (vector::is_empty(&vector::remove_value(&mut authentication_key, &key))) {
                return false
            };
            size = size - 1;
        };
        true
    }

    #[view]
    /// Check is the account is original, return true if
    /// 1. the `Account` resource under `account` exists
    /// 2. there is only one key in authentication_key
    /// 3. the only key in authentication_key is `account` self
    public fun is_original_account(account: address): bool acquires Account {
        if (!exists_at(account)) {
            return false
        };

        let authentication_key = borrow_global<Account>(account).authentication_key;
        if (vector::length(&authentication_key) != 1) {
            return false
        };
        *vector::borrow(&authentication_key, 0) == bcs::to_bytes(&account)
    }

    fun check_duplication(vec: vector<vector<u8>>) {
        let new_vec = vector[];
        vector::for_each_reverse(vec, |v| {
            assert!(!vector::contains(&new_vec, &v), error::invalid_argument(EDUPLICATE_AUTHENTICATION_KEY));
            vector::push_back(&mut new_vec, v);
        });
    }

    /// This function is used to rotate a resource account's authentication key to `new_auth_key`. This is done in
    /// many contexts:
    /// 1. During normal key rotation via `rotate_authentication_key` or `rotate_authentication_key_call`
    /// 2. During resource account initialization so that no private key can control the resource account
    /// 3. During multisig_v2 account creation
    public(friend) fun rotate_authentication_key_internal(account: &signer, new_auth_key: vector<vector<u8>>) acquires Account, OriginatingAddress {
        // Check duplication for `new_auth_key`
        check_duplication(new_auth_key);
        assert!(vector::length(&new_auth_key) <= MAX_AUTH_KEY_SIZE, error::invalid_argument(EINVALID_AUTHENTICATION_KEY_COUNT));
        let addr = signer::address_of(account);
        assert!(exists_at(addr), error::not_found(EACCOUNT_DOES_NOT_EXIST));
        let account_resource = borrow_global_mut<Account>(addr);
        update_auth_key_and_originating_address_table(addr, account_resource, new_auth_key);
    }

    /// Add `new_author` to the account's `authentication_key`.
    entry fun add_authentication_key(account: &signer, new_author: &auth) acquires Account, OriginatingAddress {
        let new_auth_key = bcs::to_bytes(new_author);
        let addr = signer::address_of(account);
        let authentication_key = borrow_global<Account>(addr).authentication_key;
        if (vector::contains(&authentication_key, &new_auth_key)) {
            return
        };
        vector::push_back(&mut authentication_key, new_auth_key);
        rotate_authentication_key_internal(account, authentication_key);
    }

    /// Similar to `add_authentication_key` but batch adding
    /// And can set `num_signatures_required`
    entry fun batch_add_authentication_key(
        account: &signer,
        new_authors: vector<auth>,
        num_signatures_required: u64,
    ) acquires Account, OriginatingAddress {
        let authentication_key = borrow_global<Account>(signer::address_of(account)).authentication_key;
        vector::for_each(new_authors, |author| {
            vector::push_back(&mut authentication_key, bcs::to_bytes(&author));
        });
        rotate_authentication_key_internal(account, authentication_key);
        set_num_signatures_required(account, num_signatures_required);
    }

    /// Create a multisig account which owned by `owners`
    /// Note that `creator` is not included unless it is one of `owners`
    entry fun create_multisig_account(
        creator: signer,
        owners: vector<auth>,
        num_signatures_required: u64
    ) acquires Account, OriginatingAddress {
        create_multisig_account_public(creator, owners, num_signatures_required);
    }

    /// See `create_multisig_account` and return the multisig account address
    public fun create_multisig_account_public(
        _creator: signer,
        owners: vector<auth>,
        num_signatures_required: u64
    ): address acquires Account, OriginatingAddress {
        let unique_address = transaction_context::generate_auid_address();
        assert!(!exists_at(unique_address), error::invalid_argument(EACCOUNT_ALREADY_EXISTS));
        let account = create_account_unchecked(unique_address);
        batch_add_authentication_key(&account, owners, num_signatures_required);
        // Remove multisig account self auth key
        remove_authentication_key(&account, bcs::to_bytes(&unique_address));
        unique_address
    }

    /// Replace `old_auth_key` with `new_auth`
    entry fun swap_authentication_key(account: &signer, new_auth: &auth, old_auth_key: vector<u8>) acquires Account, OriginatingAddress {
        let new_auth_key = bcs::to_bytes(new_auth);
        let addr = signer::address_of(account);
        let authentication_key = borrow_global<Account>(addr).authentication_key;
        // If `old_auth_key` is not in `authentication_key`, do nothing.
        vector::remove_value(&mut authentication_key, &old_auth_key);
        vector::push_back(&mut authentication_key, new_auth_key);
        rotate_authentication_key_internal(account, authentication_key);
    }

    /// Remove `auth_key` from the account's `authentication_key`.
    /// If the `auth_key` is not in the account's `authentication_key`, this function will do nothing.
    /// If the `authentication_key`'s length less than `num_signatures_required` after remove, it will fail
    entry fun remove_authentication_key(account: &signer, auth_key: vector<u8>) acquires Account, OriginatingAddress {
        assert!(
            vector::length(&auth_key) == 32,
            error::invalid_argument(EMALFORMED_AUTHENTICATION_KEY)
        );
        let addr = signer::address_of(account);
        let resource = borrow_global<Account>(addr);
        let authentication_key = resource.authentication_key;
        // Not exist
        if (vector::is_empty(&vector::remove_value(&mut authentication_key, &auth_key))) {
            return
        };
        assert!(
            vector::length(&authentication_key) >= resource.num_signatures_required,
            error::invalid_argument(EINVALID_AUTHENTICATION_KEY_COUNT)
        );
        rotate_authentication_key_internal(account, authentication_key);
    }

    /// Similar to `remove_authentication_key` but batch removing
    /// And can update `num_signatures_required`
    entry fun batch_remove_authentication_key(
        account: &signer,
        auth_keys: vector<vector<u8>>,
        num_signatures_required: u64,
    ) acquires Account, OriginatingAddress {
        let addr = signer::address_of(account);
        let authentication_key = borrow_global<Account>(addr).authentication_key;
        vector::for_each(auth_keys, |k| {
            assert!(
                vector::length(&k) == 32,
                error::invalid_argument(EMALFORMED_AUTHENTICATION_KEY)
            );
            vector::remove_value(&mut authentication_key, &k);
        });
        rotate_authentication_key_internal(account, authentication_key);
        set_num_signatures_required(account, num_signatures_required);
    }

    /// Update the number of signatures required, it will fail if
    /// 1. `num_signatures_required` is 0
    /// 2. `num_signatures_required` is greater than the number of keys in `authentication_key`
    entry fun set_num_signatures_required(account: &signer, num_signatures_required: u64) acquires Account {
        assert!(
            num_signatures_required > 0,
            error::invalid_argument(EINVALID_NUM_SIGNATURES_REQUIRED)
        );
        let addr = signer::address_of(account);
        let resource = borrow_global_mut<Account>(addr);
        assert!(
            num_signatures_required <= vector::length(&resource.authentication_key),
            error::invalid_argument(EINVALID_NUM_SIGNATURES_REQUIRED)
        );
        if (resource.num_signatures_required == num_signatures_required) {
            return
        };
        event::emit(UpdateSignaturesRequired {
            account: addr,
            old_num_signatures_required: resource.num_signatures_required,
            new_num_signatures_required: num_signatures_required,
        });
        resource.num_signatures_required = num_signatures_required;
    }

    /// Compare `old` and `new`, return added and removed
    /// example:
    /// old = [1, 2, 3]
    /// new = [2, 3, 4]
    /// return ([4], [1])
    fun vector_diff(old: vector<vector<u8>>, new: vector<vector<u8>>): (vector<vector<u8>>, vector<vector<u8>>) {
        let added = new;
        let removed = old;
        vector::for_each_reverse(old, |v| {
            vector::remove_value(&mut added, &v);
        });
        vector::for_each_reverse(new, |v| {
            vector::remove_value(&mut removed, &v);
        });
        (added, removed)
    }

    /// Update the `OriginatingAddress` table, so that we can find the originating address using the latest address
    /// in the event of key recovery.
    fun update_auth_key_and_originating_address_table(
        originating_addr: address,
        account_resource: &mut Account,
        new_auth_key_vector: vector<vector<u8>>,
    ) acquires OriginatingAddress {
        if (exists<OriginatingAddress>(@endless_framework)) {
            let address_map = &mut borrow_global_mut<OriginatingAddress>(@endless_framework).address_map;
            let old_authentication_key = account_resource.authentication_key;
            let (added, removed) = vector_diff(old_authentication_key, new_auth_key_vector);

            if (!vector::is_empty(&added)) {
                event::emit(AddAuthenticationKey {
                    account: originating_addr,
                    auth_keys: added,
                });
            };

            if (!vector::is_empty(&removed)) {
                event::emit(RemoveAuthenticationKey {
                    account: originating_addr,
                    auth_keys: removed,
                });
            };

            vector::for_each_reverse(removed, |v| {
                if (table::contains(address_map, v)) {
                    let list = table::borrow_mut(address_map, v);
                    vector::remove_value(list, &originating_addr);
                    // Remove vector when it's empty
                    if (vector::is_empty(list)) {
                        table::remove(address_map, v);
                    };
                }
            });

            vector::for_each_reverse(added, |v| {
                let added_addr = from_bcs::to_address(v);
                if (added_addr != originating_addr) {
                    if (table::contains(address_map, v)) {
                        let list = table::borrow_mut(address_map, v);
                        assert!(
                            // If already exist, there is a bug
                            !vector::contains(list, &originating_addr),
                            error::internal(EUNEXPECTED)
                        );
                        vector::push_back(list, originating_addr);
                        assert!(
                            vector::length(list) <= MAX_MAP_SIZE,
                            error::invalid_argument(EINVALID_AUTHENTICATION_KEY_COUNT)
                        );
                    } else {
                        table::add(address_map, v, vector[originating_addr]);
                    };
                };
            });
        };

        // Update the account resource's authentication key.
        account_resource.authentication_key = new_auth_key_vector;
    }

    ///////////////////////////////////////////////////////////////////////////
    /// Basic account creation methods.
    ///////////////////////////////////////////////////////////////////////////

    /// This is a helper function to compute resource addresses. Computation of the address
    /// involves the use of a cryptographic hash operation and should be use thoughtfully.
    public fun create_resource_address(source: &address, seed: vector<u8>): address {
        let bytes = bcs::to_bytes(source);
        vector::append(&mut bytes, seed);
        vector::push_back(&mut bytes, DERIVE_RESOURCE_ACCOUNT_SCHEME);
        from_bcs::to_address(hash::sha3_256(bytes))
    }

    /// A resource account is used to manage resources independent of an account managed by a user.
    /// In Endless a resource account is created based upon the sha3 256 of the source's address and additional seed data.
    /// A resource account can only be created once, this is designated by setting the
    /// `Account::signer_capability_offer::for` to the address of the resource account. While an entity may call
    /// `create_account` to attempt to claim an account ahead of the creation of a resource account, if found Endless will
    /// transition ownership of the account over to the resource account. This is done by validating that the account has
    /// yet to execute any transactions and that the `Account::signer_capability_offer::for` is none. The probability of a
    /// collision where someone has legitimately produced a private key that maps to a resource account address is less
    /// than `(1/2)^(256)`.
    public fun create_resource_account(source: &signer, seed: vector<u8>): (signer, SignerCapability) acquires Account, OriginatingAddress {
        let resource_addr = create_resource_address(&signer::address_of(source), seed);
        let resource = if (exists_at(resource_addr)) {
            let account = borrow_global<Account>(resource_addr);
            assert!(
                account.sequence_number == 0,
                error::invalid_state(EACCOUNT_ALREADY_USED),
            );
            create_signer(resource_addr)
        } else {
            create_account_unchecked(resource_addr)
        };

        // By default, only the SignerCapability should have control over the resource account and not the auth key.
        // If the source account wants direct control via auth key, they would need to explicitly rotate the auth key
        // of the resource account using the SignerCapability.
        rotate_authentication_key_internal(&resource, vector[]);

        let signer_cap = SignerCapability { account: resource_addr };
        (resource, signer_cap)
    }

    /// create the account for system reserved addresses
    public(friend) fun create_framework_reserved_account(addr: address): (signer, SignerCapability) {
        assert!(
            addr == @0x1 ||
                addr == @0x2 ||
                addr == @0x3 ||
                addr == @0x4 ||
                addr == @0x5 ||
                addr == @0x6 ||
                addr == @0x7 ||
                addr == @0x8 ||
                addr == @0x9 ||
                addr == @0xa,
            error::permission_denied(ENO_VALID_FRAMEWORK_RESERVED_ADDRESS),
        );
        let signer = create_account_unchecked(addr);
        let signer_cap = SignerCapability { account: addr };
        (signer, signer_cap)
    }

    ///////////////////////////////////////////////////////////////////////////
    /// GUID management methods.
    ///////////////////////////////////////////////////////////////////////////

    public fun create_guid(account_signer: &signer): guid::GUID acquires Account {
        let addr = signer::address_of(account_signer);
        let account = borrow_global_mut<Account>(addr);
        let guid = guid::create(addr, &mut account.guid_creation_num);
        assert!(
            account.guid_creation_num < MAX_GUID_CREATION_NUM,
            error::out_of_range(EEXCEEDED_MAX_GUID_CREATION_NUM),
        );
        guid
    }

    ///////////////////////////////////////////////////////////////////////////
    /// GUID management methods.
    ///////////////////////////////////////////////////////////////////////////

    public fun new_event_handle<T: drop + store>(account: &signer): EventHandle<T> acquires Account {
        event::new_event_handle(create_guid(account))
    }

    ///////////////////////////////////////////////////////////////////////////
    /// Capability based functions for efficient use.
    ///////////////////////////////////////////////////////////////////////////

    public fun create_signer_with_capability(capability: &SignerCapability): signer {
        let addr = &capability.account;
        create_signer(*addr)
    }

    public fun get_signer_capability_address(capability: &SignerCapability): address {
        capability.account
    }

    public fun verify_signed_message<T: drop>(
        account: address,
        account_scheme: u8,
        account_public_key: vector<u8>,
        signed_message_bytes: vector<u8>,
        message: T,
    ) acquires Account {
        let account_resource = borrow_global_mut<Account>(account);
        // Verify that the `SignerCapabilityOfferProofChallengeV2` has the right information and is signed by the account owner's key
        if (account_scheme == ED25519_SCHEME) {
            let pubkey = ed25519::new_unvalidated_public_key_from_bytes(account_public_key);
            let expected_auth_key = ed25519::unvalidated_public_key_to_authentication_key(&pubkey);
            assert!(
                vector::contains(&account_resource.authentication_key, &expected_auth_key),
                error::invalid_argument(EWRONG_CURRENT_PUBLIC_KEY),
            );

            let signer_capability_sig = ed25519::new_signature_from_bytes(signed_message_bytes);
            assert!(
                ed25519::signature_verify_strict_t(&signer_capability_sig, &pubkey, message),
                error::invalid_argument(EINVALID_PROOF_OF_KNOWLEDGE),
            );
        } else if (account_scheme == MULTI_ED25519_SCHEME) {
            let pubkey = multi_ed25519::new_unvalidated_public_key_from_bytes(account_public_key);
            let expected_auth_key = multi_ed25519::unvalidated_public_key_to_authentication_key(&pubkey);
            assert!(
                vector::contains(&account_resource.authentication_key, &expected_auth_key),
                error::invalid_argument(EWRONG_CURRENT_PUBLIC_KEY),
            );

            let signer_capability_sig = multi_ed25519::new_signature_from_bytes(signed_message_bytes);
            assert!(
                multi_ed25519::signature_verify_strict_t(&signer_capability_sig, &pubkey, message),
                error::invalid_argument(EINVALID_PROOF_OF_KNOWLEDGE),
            );
        } else {
            abort error::invalid_argument(EINVALID_SCHEME)
        };
    }


    public fun verify_signed_message_unauthenised_pubkey<T: drop>(
        account_scheme: u8,
        account_public_key: vector<u8>,
        signed_message_bytes: vector<u8>,
        message: T,
    ) {
        // Verify that the `SignerCapabilityOfferProofChallengeV2` has the right information and is signed by the account owner's key
        if (account_scheme == ED25519_SCHEME) {
            let pubkey = ed25519::new_unvalidated_public_key_from_bytes(account_public_key);

            let signer_capability_sig = ed25519::new_signature_from_bytes(signed_message_bytes);
            assert!(
                ed25519::signature_verify_strict_t(&signer_capability_sig, &pubkey, message),
                error::invalid_argument(EINVALID_PROOF_OF_KNOWLEDGE),
            );
        } else if (account_scheme == MULTI_ED25519_SCHEME) {
            let pubkey = multi_ed25519::new_unvalidated_public_key_from_bytes(account_public_key);

            let signer_capability_sig = multi_ed25519::new_signature_from_bytes(signed_message_bytes);
            assert!(
                multi_ed25519::signature_verify_strict_t(&signer_capability_sig, &pubkey, message),
                error::invalid_argument(EINVALID_PROOF_OF_KNOWLEDGE),
            );
        } else {
            abort error::invalid_argument(EINVALID_SCHEME)
        };
    }

    #[test_only]
    public fun create_account_for_test(new_address: address): signer {
        // Make this easier by just allowing the account to be created again in a test
        if (!exists_at(new_address)) {
            create_account_unchecked(new_address)
        } else {
            create_signer_for_test(new_address)
        }
    }

    #[test]
    /// Assert correct signer creation.
    fun test_create_signer_for_test() {
        assert!(signer::address_of(&create_signer_for_test(@endless_framework)) == @0x1, 0);
        assert!(signer::address_of(&create_signer_for_test(@0x123)) == @0x123, 0);
    }

    #[test(user = @0x1)]
    public entry fun test_create_resource_account(user: signer) acquires Account, OriginatingAddress {
        let (resource_account, resource_account_cap) = create_resource_account(&user, x"01");
        let resource_addr = signer::address_of(&resource_account);
        assert!(resource_addr != signer::address_of(&user), 0);
        assert!(resource_addr == get_signer_capability_address(&resource_account_cap), 1);
    }

    // #[test]
    // #[expected_failure(abort_code = 0x10007, location = Self)]
    // public entry fun test_cannot_control_resource_account_via_auth_key() acquires Account {
    //     let alice_pk = x"4141414141414141414141414141414141414141414141414141414141414145";
    //     let alice = create_account_from_ed25519_public_key(alice_pk);
    //     let alice_auth = get_authentication_key(signer::address_of(&alice)); // must look like a valid public key

    //     let (eve_sk, eve_pk) = ed25519::generate_keys();
    //     let eve_pk_bytes = ed25519::validated_public_key_to_bytes(&eve_pk);
    //     let eve = create_account_from_ed25519_public_key(eve_pk_bytes);
    //     let recipient_address = signer::address_of(&eve);

    //     let seed = eve_pk_bytes; // multisig public key
    //     vector::push_back(&mut seed, 1); // multisig threshold
    //     vector::push_back(&mut seed, 1); // signature scheme id
    //     let (resource, _) = create_resource_account(&alice, seed);

    //     let resource_addr = signer::address_of(&resource);
    //     let proof_challenge = SignerCapabilityOfferProofChallengeV2 {
    //         sequence_number: borrow_global_mut<Account>(resource_addr).sequence_number,
    //         source_address: resource_addr,
    //         recipient_address,
    //     };

    //     let eve_sig = ed25519::sign_struct(&eve_sk, copy proof_challenge);

    //     // Construct a malicious 1-out-of-2 multisig PK over Alice's authentication key and Eve's Ed25519 PK.
    //     let account_public_key_bytes = alice_auth;
    //     vector::append(&mut account_public_key_bytes, eve_pk_bytes);
    //     vector::push_back(&mut account_public_key_bytes, 1); // Multisig verification threshold.
    //     let fake_pk = multi_ed25519::new_unvalidated_public_key_from_bytes(account_public_key_bytes);

    //     // Construct a multisig for `proof_challenge` as if it is signed by the signers behind `fake_pk`,
    //     // Eve being the only participant.
    //     let signer_capability_sig_bytes = x"";
    //     vector::append(&mut signer_capability_sig_bytes, ed25519::signature_to_bytes(&eve_sig));
    //     vector::append(&mut signer_capability_sig_bytes, x"40000000"); // Signers bitmap.
    //     let fake_sig = multi_ed25519::new_signature_from_bytes(signer_capability_sig_bytes);

    //     assert!(multi_ed25519::signature_verify_strict_t(&fake_sig, &fake_pk, proof_challenge), error::invalid_state(EINVALID_PROOF_OF_KNOWLEDGE));
    //     offer_signer_capability(&resource, signer_capability_sig_bytes, MULTI_ED25519_SCHEME, account_public_key_bytes, recipient_address);
    // }

    // #[test_only]
    // struct DummyResource has key {}

    // #[test(user = @0x1)]
    // public entry fun test_module_capability(user: signer) acquires Account, DummyResource {
    //     let (resource_account, signer_cap) = create_resource_account(&user, x"01");
    //     assert!(signer::address_of(&resource_account) != signer::address_of(&user), 0);

    //     let resource_account_from_cap = create_signer_with_capability(&signer_cap);
    //     assert!(&resource_account == &resource_account_from_cap, 1);

    //     move_to(&resource_account_from_cap, DummyResource {});
    //     borrow_global<DummyResource>(signer::address_of(&resource_account));
    // }

    // #[test(user = @0x1)]
    // public entry fun test_resource_account_and_create_account(user: signer) acquires Account {
    //     let resource_addr = create_resource_address(&@0x1, x"01");
    //     create_account_unchecked(resource_addr);

    //     create_resource_account(&user, x"01");
    // }

    // #[test(user = @0x1)]
    // #[expected_failure(abort_code = 0x8000f, location = Self)]
    // public entry fun test_duplice_create_resource_account(user: signer) acquires Account {
    //     create_resource_account(&user, x"01");
    //     create_resource_account(&user, x"01");
    // }

    // ///////////////////////////////////////////////////////////////////////////
    // // Test-only sequence number mocking for extant Account resource
    // ///////////////////////////////////////////////////////////////////////////

    #[test_only]
    /// Increment sequence number of account at address `addr`
    public fun increment_sequence_number_for_test(
        addr: address,
    ) acquires Account {
        let acct = borrow_global_mut<Account>(addr);
        acct.sequence_number = acct.sequence_number + 1;
    }

    #[test_only]
    /// Update address `addr` to have `s` as its sequence number
    public fun set_sequence_number(
        addr: address,
        s: u64
    ) acquires Account {
        borrow_global_mut<Account>(addr).sequence_number = s;
    }

    #[test_only]
    public fun set_authentication_key_for_test(
        account: address,
        authentication_key: vector<address>,
        num_signatures_required: u64
    ) acquires Account, OriginatingAddress {
        let s = create_account_for_test(account);
        let keys = vector[];
        vector::for_each_reverse(authentication_key, |key| {
            vector::push_back(&mut keys, bcs::to_bytes(&key));
        });
        rotate_authentication_key_internal(&s, keys);
        set_num_signatures_required(&s, num_signatures_required);
    }

    #[test_only]
    public fun create_test_signer_cap(account: address): SignerCapability {
        SignerCapability { account }
    }

    // #[test_only]
    // public fun set_signer_capability_offer(offerer: address, receiver: address) acquires Account {
    //     let account_resource = borrow_global_mut<Account>(offerer);
    //     option::swap_or_fill(&mut account_resource.signer_capability_offer.for, receiver);
    // }

    // #[test_only]
    // public fun set_rotation_capability_offer(offerer: address, receiver: address) acquires Account {
    //     let account_resource = borrow_global_mut<Account>(offerer);
    //     option::swap_or_fill(&mut account_resource.rotation_capability_offer.for, receiver);
    // }

    // #[test]
    // /// Verify test-only sequence number mocking
    // public entry fun mock_sequence_numbers()
    // acquires Account {
    //     let addr: address = @0x1234; // Define test address
    //     create_account(addr); // Initialize account resource
    //     // Assert sequence number intializes to 0
    //     assert!(borrow_global<Account>(addr).sequence_number == 0, 0);
    //     increment_sequence_number_for_test(addr); // Increment sequence number
    //     // Assert correct mock value post-increment
    //     assert!(borrow_global<Account>(addr).sequence_number == 1, 1);
    //     set_sequence_number(addr, 10); // Set mock sequence number
    //     // Assert correct mock value post-modification
    //     assert!(borrow_global<Account>(addr).sequence_number == 10, 2);
    // }

    // ///////////////////////////////////////////////////////////////////////////
    // // Test account helpers
    // ///////////////////////////////////////////////////////////////////////////

    // #[test(alice = @0xa11ce)]
    // #[expected_failure(abort_code = 65537, location = endless_framework::ed25519)]
    // public entry fun test_empty_public_key(alice: signer) acquires Account, OriginatingAddress {
    //     create_account(signer::address_of(&alice));
    //     let pk = vector::empty<u8>();
    //     let sig = x"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    //     rotate_authentication_key(&alice, ED25519_SCHEME, pk, ED25519_SCHEME, pk, sig, sig);
    // }

    // #[test(alice = @0xa11ce)]
    // #[expected_failure(abort_code = 262151, location = Self)]
    // public entry fun test_empty_signature(alice: signer) acquires Account, OriginatingAddress {
    //     create_account(signer::address_of(&alice));
    //     let test_signature = vector::empty<u8>();
    //     let pk = x"0000000000000000000000000000000000000000000000000000000000000000";
    //     rotate_authentication_key(&alice, ED25519_SCHEME, pk, ED25519_SCHEME, pk, test_signature, test_signature);
    // }

    // #[test_only]
    // public fun create_account_from_ed25519_public_key(pk_bytes: vector<u8>): signer {
    //     let pk = ed25519::new_unvalidated_public_key_from_bytes(pk_bytes);
    //     let curr_auth_key = ed25519::unvalidated_public_key_to_authentication_key(&pk);
    //     let alice_address = from_bcs::to_address(curr_auth_key);
    //     let alice = create_account_unchecked(alice_address);
    //     alice
    // }

    // //
    // // Tests for offering & revoking signer capabilities
    // //

    // #[test(bob = @0x345)]
    // #[expected_failure(abort_code = 65544, location = Self)]
    // public entry fun test_invalid_offer_signer_capability(bob: signer) acquires Account {
    //     let (_alice_sk, alice_pk) = ed25519::generate_keys();
    //     let alice_pk_bytes = ed25519::validated_public_key_to_bytes(&alice_pk);
    //     let alice = create_account_from_ed25519_public_key(alice_pk_bytes);
    //     let alice_addr = signer::address_of(&alice);

    //     let bob_addr = signer::address_of(&bob);
    //     create_account(bob_addr);

    //     let challenge = SignerCapabilityOfferProofChallengeV2 {
    //         sequence_number: borrow_global<Account>(alice_addr).sequence_number,
    //         source_address: alice_addr,
    //         recipient_address: bob_addr,
    //     };

    //     let sig = ed25519::sign_struct(&_alice_sk, challenge);

    //     // Maul the signature and make sure the call would fail
    //     let invalid_signature = ed25519::signature_to_bytes(&sig);
    //     let first_sig_byte = vector::borrow_mut(&mut invalid_signature, 0);
    //     *first_sig_byte = *first_sig_byte ^ 1;

    //     offer_signer_capability(&alice, invalid_signature, 0, alice_pk_bytes, bob_addr);
    // }

    // #[test(bob = @0x345)]
    // public entry fun test_valid_check_signer_capability_and_create_authorized_signer(bob: signer) acquires Account {
    //     let (alice_sk, alice_pk) = ed25519::generate_keys();
    //     let alice_pk_bytes = ed25519::validated_public_key_to_bytes(&alice_pk);
    //     let alice = create_account_from_ed25519_public_key(alice_pk_bytes);
    //     let alice_addr = signer::address_of(&alice);

    //     let bob_addr = signer::address_of(&bob);
    //     create_account(bob_addr);

    //     let challenge = SignerCapabilityOfferProofChallengeV2 {
    //         sequence_number: borrow_global<Account>(alice_addr).sequence_number,
    //         source_address: alice_addr,
    //         recipient_address: bob_addr,
    //     };

    //     let alice_signer_capability_offer_sig = ed25519::sign_struct(&alice_sk, challenge);

    //     offer_signer_capability(&alice, ed25519::signature_to_bytes(&alice_signer_capability_offer_sig), 0, alice_pk_bytes, bob_addr);

    //     assert!(option::contains(&borrow_global<Account>(alice_addr).signer_capability_offer.for, &bob_addr), 0);

    //     let signer = create_authorized_signer(&bob, alice_addr);
    //     assert!(signer::address_of(&signer) == signer::address_of(&alice), 0);
    // }

    // #[test(bob = @0x345)]
    // public entry fun test_get_signer_cap_and_is_signer_cap(bob: signer) acquires Account {
    //     let (alice_sk, alice_pk) = ed25519::generate_keys();
    //     let alice_pk_bytes = ed25519::validated_public_key_to_bytes(&alice_pk);
    //     let alice = create_account_from_ed25519_public_key(alice_pk_bytes);
    //     let alice_addr = signer::address_of(&alice);

    //     let bob_addr = signer::address_of(&bob);
    //     create_account(bob_addr);

    //     let challenge = SignerCapabilityOfferProofChallengeV2 {
    //         sequence_number: borrow_global<Account>(alice_addr).sequence_number,
    //         source_address: alice_addr,
    //         recipient_address: bob_addr,
    //     };

    //     let alice_signer_capability_offer_sig = ed25519::sign_struct(&alice_sk, challenge);

    //     offer_signer_capability(&alice, ed25519::signature_to_bytes(&alice_signer_capability_offer_sig), 0, alice_pk_bytes, bob_addr);

    //     assert!(is_signer_capability_offered(alice_addr), 0);
    //     assert!(get_signer_capability_offer_for(alice_addr) == bob_addr, 0);
    // }


    // #[test(bob = @0x345, charlie = @0x567)]
    // #[expected_failure(abort_code = 393230, location = Self)]
    // public entry fun test_invalid_check_signer_capability_and_create_authorized_signer(bob: signer, charlie: signer) acquires Account {
    //     let (alice_sk, alice_pk) = ed25519::generate_keys();
    //     let alice_pk_bytes = ed25519::validated_public_key_to_bytes(&alice_pk);
    //     let alice = create_account_from_ed25519_public_key(alice_pk_bytes);
    //     let alice_addr = signer::address_of(&alice);

    //     let bob_addr = signer::address_of(&bob);
    //     create_account(bob_addr);

    //     let challenge = SignerCapabilityOfferProofChallengeV2 {
    //         sequence_number: borrow_global<Account>(alice_addr).sequence_number,
    //         source_address: alice_addr,
    //         recipient_address: bob_addr,
    //     };

    //     let alice_signer_capability_offer_sig = ed25519::sign_struct(&alice_sk, challenge);

    //     offer_signer_capability(&alice, ed25519::signature_to_bytes(&alice_signer_capability_offer_sig), 0, alice_pk_bytes, bob_addr);

    //     let alice_account_resource = borrow_global_mut<Account>(alice_addr);
    //     assert!(option::contains(&alice_account_resource.signer_capability_offer.for, &bob_addr), 0);

    //     create_authorized_signer(&charlie, alice_addr);
    // }

    // #[test(bob = @0x345)]
    // public entry fun test_valid_revoke_signer_capability(bob: signer) acquires Account {
    //     let (alice_sk, alice_pk) = ed25519::generate_keys();
    //     let alice_pk_bytes = ed25519::validated_public_key_to_bytes(&alice_pk);
    //     let alice = create_account_from_ed25519_public_key(alice_pk_bytes);
    //     let alice_addr = signer::address_of(&alice);

    //     let bob_addr = signer::address_of(&bob);
    //     create_account(bob_addr);

    //     let challenge = SignerCapabilityOfferProofChallengeV2 {
    //         sequence_number: borrow_global<Account>(alice_addr).sequence_number,
    //         source_address: alice_addr,
    //         recipient_address: bob_addr,
    //     };

    //     let alice_signer_capability_offer_sig = ed25519::sign_struct(&alice_sk, challenge);

    //     offer_signer_capability(&alice, ed25519::signature_to_bytes(&alice_signer_capability_offer_sig), 0, alice_pk_bytes, bob_addr);
    //     revoke_signer_capability(&alice, bob_addr);
    // }

    // #[test(bob = @0x345, charlie = @0x567)]
    // #[expected_failure(abort_code = 393230, location = Self)]
    // public entry fun test_invalid_revoke_signer_capability(bob: signer, charlie: signer) acquires Account {
    //     let (alice_sk, alice_pk) = ed25519::generate_keys();
    //     let alice_pk_bytes = ed25519::validated_public_key_to_bytes(&alice_pk);
    //     let alice = create_account_from_ed25519_public_key(alice_pk_bytes);
    //     let alice_addr = signer::address_of(&alice);
    //     let alice_account_resource = borrow_global<Account>(alice_addr);

    //     let bob_addr = signer::address_of(&bob);
    //     create_account(bob_addr);

    //     let charlie_addr = signer::address_of(&charlie);
    //     create_account(charlie_addr);

    //     let challenge = SignerCapabilityOfferProofChallengeV2 {
    //         sequence_number: alice_account_resource.sequence_number,
    //         source_address: alice_addr,
    //         recipient_address: bob_addr,
    //     };
    //     let alice_signer_capability_offer_sig = ed25519::sign_struct(&alice_sk, challenge);
    //     offer_signer_capability(&alice, ed25519::signature_to_bytes(&alice_signer_capability_offer_sig), 0, alice_pk_bytes, bob_addr);
    //     revoke_signer_capability(&alice, charlie_addr);
    // }

    // //
    // // Tests for offering rotation capabilities
    // //
    // #[test(bob = @0x345, framework = @endless_framework)]
    // public entry fun test_valid_offer_rotation_capability(bob: signer, framework: signer) acquires Account {
    //     chain_id::initialize_for_test(&framework, 4);
    //     let (alice_sk, alice_pk) = ed25519::generate_keys();
    //     let alice_pk_bytes = ed25519::validated_public_key_to_bytes(&alice_pk);
    //     let alice = create_account_from_ed25519_public_key(alice_pk_bytes);
    //     let alice_addr = signer::address_of(&alice);

    //     let bob_addr = signer::address_of(&bob);
    //     create_account(bob_addr);

    //     let challenge = RotationCapabilityOfferProofChallengeV2 {
    //         chain_id: chain_id::get(),
    //         sequence_number: get_sequence_number(alice_addr),
    //         source_address: alice_addr,
    //         recipient_address: bob_addr,
    //     };

    //     let alice_rotation_capability_offer_sig = ed25519::sign_struct(&alice_sk, challenge);

    //     offer_rotation_capability(&alice,  ed25519::signature_to_bytes(&alice_rotation_capability_offer_sig),  0, alice_pk_bytes, bob_addr);

    //     let alice_resource = borrow_global_mut<Account>(signer::address_of(&alice));
    //     assert!(option::contains(&alice_resource.rotation_capability_offer.for, &bob_addr), 0);
    // }

    // #[test(bob = @0x345, framework = @endless_framework)]
    // #[expected_failure(abort_code = 65544, location = Self)]
    // public entry fun test_invalid_offer_rotation_capability(bob: signer, framework: signer) acquires Account {
    //     chain_id::initialize_for_test(&framework, 4);
    //     let (alice_sk, alice_pk) = ed25519::generate_keys();
    //     let alice_pk_bytes = ed25519::validated_public_key_to_bytes(&alice_pk);
    //     let alice = create_account_from_ed25519_public_key(alice_pk_bytes);
    //     let alice_addr = signer::address_of(&alice);

    //     let bob_addr = signer::address_of(&bob);
    //     create_account(bob_addr);

    //     let challenge = RotationCapabilityOfferProofChallengeV2 {
    //         chain_id: chain_id::get(),
    //         // Intentionally make the signature invalid.
    //         sequence_number: 2,
    //         source_address: alice_addr,
    //         recipient_address: bob_addr,
    //     };

    //     let alice_rotation_capability_offer_sig = ed25519::sign_struct(&alice_sk, challenge);

    //     offer_rotation_capability(&alice, ed25519::signature_to_bytes(&alice_rotation_capability_offer_sig), 0, alice_pk_bytes, signer::address_of(&bob));
    // }

    // #[test(bob = @0x345, framework = @endless_framework)]
    // public entry fun test_valid_revoke_rotation_capability(bob: signer, framework: signer) acquires Account {
    //     chain_id::initialize_for_test(&framework, 4);
    //     let (alice_sk, alice_pk) = ed25519::generate_keys();
    //     let alice_pk_bytes = ed25519::validated_public_key_to_bytes(&alice_pk);
    //     let alice = create_account_from_ed25519_public_key(alice_pk_bytes);
    //     let alice_addr = signer::address_of(&alice);

    //     let bob_addr = signer::address_of(&bob);
    //     create_account(bob_addr);

    //     let challenge = RotationCapabilityOfferProofChallengeV2 {
    //         chain_id: chain_id::get(),
    //         sequence_number: get_sequence_number(alice_addr),
    //         source_address: alice_addr,
    //         recipient_address: bob_addr,
    //     };

    //     let alice_rotation_capability_offer_sig = ed25519::sign_struct(&alice_sk, challenge);

    //     offer_rotation_capability(&alice, ed25519::signature_to_bytes(&alice_rotation_capability_offer_sig), 0, alice_pk_bytes, signer::address_of(&bob));
    //     revoke_rotation_capability(&alice, signer::address_of(&bob));
    // }

    // #[test(bob = @0x345, charlie = @0x567, framework = @endless_framework)]
    // #[expected_failure(abort_code = 393234, location = Self)]
    // public entry fun test_invalid_revoke_rotation_capability(bob: signer, charlie: signer, framework: signer) acquires Account {
    //     chain_id::initialize_for_test(&framework, 4);
    //     let (alice_sk, alice_pk) = ed25519::generate_keys();
    //     let alice_pk_bytes = ed25519::validated_public_key_to_bytes(&alice_pk);
    //     let alice = create_account_from_ed25519_public_key(alice_pk_bytes);
    //     let alice_addr = signer::address_of(&alice);

    //     let bob_addr = signer::address_of(&bob);
    //     create_account(bob_addr);
    //     create_account(signer::address_of(&charlie));

    //     let challenge = RotationCapabilityOfferProofChallengeV2 {
    //         chain_id: chain_id::get(),
    //         sequence_number: get_sequence_number(alice_addr),
    //         source_address: alice_addr,
    //         recipient_address: bob_addr,
    //     };

    //     let alice_rotation_capability_offer_sig = ed25519::sign_struct(&alice_sk, challenge);

    //     offer_rotation_capability(&alice, ed25519::signature_to_bytes(&alice_rotation_capability_offer_sig), 0, alice_pk_bytes, signer::address_of(&bob));
    //     revoke_rotation_capability(&alice, signer::address_of(&charlie));
    // }

    // //
    // // Tests for key rotation
    // //

    // #[test(account = @endless_framework)]
    // public entry fun test_valid_rotate_authentication_key_multi_ed25519_to_multi_ed25519(account: signer) acquires Account, OriginatingAddress {
    //     initialize(&account);
    //     let (curr_sk, curr_pk) = multi_ed25519::generate_keys(2, 3);
    //     let curr_pk_unvalidated = multi_ed25519::public_key_to_unvalidated(&curr_pk);
    //     let curr_auth_key = multi_ed25519::unvalidated_public_key_to_authentication_key(&curr_pk_unvalidated);
    //     let alice_addr = from_bcs::to_address(curr_auth_key);
    //     let alice = create_account_unchecked(alice_addr);

    //     let (new_sk, new_pk) = multi_ed25519::generate_keys(4, 5);
    //     let new_pk_unvalidated = multi_ed25519::public_key_to_unvalidated(&new_pk);
    //     let new_auth_key = multi_ed25519::unvalidated_public_key_to_authentication_key(&new_pk_unvalidated);
    //     let new_address = from_bcs::to_address(new_auth_key);

    //     let challenge = RotationProofChallenge {
    //         sequence_number: borrow_global<Account>(alice_addr).sequence_number,
    //         originator: alice_addr,
    //         current_auth_key: alice_addr,
    //         new_public_key: multi_ed25519::unvalidated_public_key_to_bytes(&new_pk_unvalidated),
    //     };

    //     let from_sig = multi_ed25519::sign_struct(&curr_sk, challenge);
    //     let to_sig = multi_ed25519::sign_struct(&new_sk, challenge);

    //     rotate_authentication_key(
    //         &alice,
    //         MULTI_ED25519_SCHEME,
    //         multi_ed25519::unvalidated_public_key_to_bytes(&curr_pk_unvalidated),
    //         MULTI_ED25519_SCHEME,
    //         multi_ed25519::unvalidated_public_key_to_bytes(&new_pk_unvalidated),
    //         multi_ed25519::signature_to_bytes(&from_sig),
    //         multi_ed25519::signature_to_bytes(&to_sig),
    //     );
    //     let address_map = &mut borrow_global_mut<OriginatingAddress>(@endless_framework).address_map;
    //     let expected_originating_address = table::borrow(address_map, new_address);
    //     assert!(*expected_originating_address == alice_addr, 0);
    //     assert!(borrow_global<Account>(alice_addr).authentication_key == new_auth_key, 0);
    // }

    // #[test(account = @endless_framework)]
    // public entry fun test_valid_rotate_authentication_key_multi_ed25519_to_ed25519(account: signer) acquires Account, OriginatingAddress {
    //     initialize(&account);

    //     let (curr_sk, curr_pk) = multi_ed25519::generate_keys(2, 3);
    //     let curr_pk_unvalidated = multi_ed25519::public_key_to_unvalidated(&curr_pk);
    //     let curr_auth_key = multi_ed25519::unvalidated_public_key_to_authentication_key(&curr_pk_unvalidated);
    //     let alice_addr = from_bcs::to_address(curr_auth_key);
    //     let alice = create_account_unchecked(alice_addr);

    //     let account_resource = borrow_global_mut<Account>(alice_addr);

    //     let (new_sk, new_pk) = ed25519::generate_keys();
    //     let new_pk_unvalidated = ed25519::public_key_to_unvalidated(&new_pk);
    //     let new_auth_key = ed25519::unvalidated_public_key_to_authentication_key(&new_pk_unvalidated);
    //     let new_addr = from_bcs::to_address(new_auth_key);

    //     let challenge = RotationProofChallenge {
    //         sequence_number: account_resource.sequence_number,
    //         originator: alice_addr,
    //         current_auth_key: alice_addr,
    //         new_public_key: ed25519::unvalidated_public_key_to_bytes(&new_pk_unvalidated),
    //     };

    //     let from_sig = multi_ed25519::sign_struct(&curr_sk, challenge);
    //     let to_sig = ed25519::sign_struct(&new_sk, challenge);

    //     rotate_authentication_key(
    //         &alice,
    //         MULTI_ED25519_SCHEME,
    //         multi_ed25519::unvalidated_public_key_to_bytes(&curr_pk_unvalidated),
    //         ED25519_SCHEME,
    //         ed25519::unvalidated_public_key_to_bytes(&new_pk_unvalidated),
    //         multi_ed25519::signature_to_bytes(&from_sig),
    //         ed25519::signature_to_bytes(&to_sig),
    //     );

    //     let address_map = &mut borrow_global_mut<OriginatingAddress>(@endless_framework).address_map;
    //     let expected_originating_address = table::borrow(address_map, new_addr);
    //     assert!(*expected_originating_address == alice_addr, 0);
    //     assert!(borrow_global<Account>(alice_addr).authentication_key == new_auth_key, 0);
    // }
    #[test_only]
    public fun initialize_for_test() {
        let s = create_signer(@endless_framework);
        initialize(&s);
    }

    #[test_only]
    public fun add_authentication_key_test(account: &signer, new_auth_key: vector<u8>) acquires Account, OriginatingAddress {
        let addr = signer::address_of(account);
        let authentication_key = borrow_global<Account>(addr).authentication_key;
        if (vector::contains(&authentication_key, &new_auth_key)) {
            return
        };
        vector::push_back(&mut authentication_key, new_auth_key);
        rotate_authentication_key_internal(account, authentication_key);
    }

    #[test_only]
    public fun create_account_unchecked_for_test(acc: address) {
        create_account_unchecked(acc);
    }
    #[test(account = @endless_framework)]
    public entry fun test_simple_rotation(account: &signer) acquires Account, OriginatingAddress {
        initialize(account);

        let alice_addr = @0x1234;
        let alice = create_account_unchecked(alice_addr);

        let (_new_sk, new_pk) = ed25519::generate_keys();
        let new_pk_unvalidated = ed25519::public_key_to_unvalidated(&new_pk);
        let new_auth_key = vector[ed25519::unvalidated_public_key_to_authentication_key(&new_pk_unvalidated)];

        rotate_authentication_key_internal(&alice, new_auth_key);
        assert!(check_authentication_key(alice_addr, new_auth_key), 0);
    }


    #[test(account = @endless_framework)]
    #[expected_failure(abort_code = 0x20014, location = Self)]
    public entry fun test_max_guid(account: &signer) acquires Account {
        let addr = signer::address_of(account);
        create_account_unchecked(addr);
        let account_state = borrow_global_mut<Account>(addr);
        account_state.guid_creation_num = MAX_GUID_CREATION_NUM - 1;
        create_guid(account);
    }

    #[test(account1 = @0xface, account2 = @0xcafe)]
    public entry fun test_add_authentication_key(account1: &signer, account2: &auth) acquires Account, OriginatingAddress {
        initialize_for_test();
        let addr1 = signer::address_of(account1);
        let auth2 = bcs::to_bytes(account2);
        create_account_unchecked(addr1);
        let resource = borrow_global<Account>(addr1);
        assert!(vector::length(&resource.authentication_key) == 1, 0);
        add_authentication_key(account1, account2);
        let resource = borrow_global<Account>(addr1);
        assert!(vector::length(&resource.authentication_key) == 2, 1);
        assert!(check_authentication_key(addr1, vector[auth2]), 2);
        let address_map = &borrow_global<OriginatingAddress>(@0x1).address_map;
        let list = table::borrow(address_map, auth2);
        assert!(vector::length(list) == 1, 3);
        assert!(*vector::borrow(list, 0) == addr1, 4);

        add_authentication_key(account1, account2);
        let resource = borrow_global<Account>(addr1);
        assert!(vector::length(&resource.authentication_key) == 2, 1);
    }

    #[test(account = @0xcafe)]
    public entry fun test_add_authentication_key_reach_limit(account: &auth) acquires Account, OriginatingAddress {
        initialize_for_test();
        let v = x"1100000000000000000000000000000000000000000000000000000000000000";
        let i = 1;
        while (i <= 100) {
            vector::pop_back(&mut v);
            vector::push_back(&mut v, i);
            let addr = from_bcs::to_address(v);
            create_account_unchecked(addr);
            let s = create_signer(addr);
            add_authentication_key(&s, account);
            i = i + 1;
        };
    }

    #[test(account = @0xcafe)]
    #[expected_failure(abort_code = 0x10016, location = Self)]
    public entry fun test_add_authentication_key_exceed_limit_should_fail(account: &auth) acquires Account, OriginatingAddress {
        test_add_authentication_key_reach_limit(account);
        create_account_unchecked(@0xface);
        let s = create_signer(@0xface);
        add_authentication_key(&s, account);
    }

    #[test_only]
    public fun address_map_contains(a1: address, a2: address): bool acquires OriginatingAddress {
        let address_map = &borrow_global<OriginatingAddress>(@0x1).address_map;
        let auth1 = bcs::to_bytes(&a1);
        if (table::contains(address_map, auth1)) {
            let list = table::borrow(address_map, auth1);
            vector::contains(list, &a2)
        } else {
            false
        }
    }

    #[test(account1 = @0xcafe, account2 = @0xface)]
    public entry fun test_remove_authentication_key(account1: &signer, account2: &auth) acquires Account, OriginatingAddress {
        initialize_for_test();
        let addr1 = signer::address_of(account1);
        let auth1 = bcs::to_bytes(&addr1);
        let auth2 = bcs::to_bytes(account2);
        let addr2 = from_bcs::to_address(auth2);
        create_account_unchecked(addr1);
        add_authentication_key(account1, account2);
        assert!(address_map_contains(addr2, addr1), 0);
        remove_authentication_key(account1, auth2);
        assert!(!address_map_contains(addr2, addr1), 1);
        let authentication_key = borrow_global<Account>(addr1).authentication_key;
        assert!(vector::length(&authentication_key) == 1, 2);
        assert!(*vector::borrow(&authentication_key, 0) == auth1, 3);
        // Remove key which not in list
        remove_authentication_key(account1, auth2);
        let authentication_key = borrow_global<Account>(addr1).authentication_key;
        assert!(vector::length(&authentication_key) == 1, 4);
        assert!(*vector::borrow(&authentication_key, 0) == auth1, 5);
    }

    #[test(account1 = @0xcafe, account2 = @0xface)]
    #[expected_failure(abort_code = 0x10016, location = Self)]
    public entry fun test_remove_auth_key_with_greater_sig_required_shoud_fail(
        account1: &signer,
        account2: &auth,
    ) acquires Account, OriginatingAddress {
        initialize_for_test();
        let addr1 = signer::address_of(account1);
        let auth1 = bcs::to_bytes(&addr1);
        create_account_unchecked(addr1);
        add_authentication_key(account1, account2);
        set_num_signatures_required(account1, 2);
        remove_authentication_key(account1, auth1);
    }

    #[test(account = @0xcafe)]
    #[expected_failure(abort_code = 0x10016, location = Self)]
    public entry fun test_clear_auth_key_should_fail(account: &signer) acquires Account, OriginatingAddress {
        initialize_for_test();
        let addr = signer::address_of(account);
        let auth_key = bcs::to_bytes(&addr);
        create_account_unchecked(addr);
        remove_authentication_key(account, auth_key);
    }

    #[test(account1 = @0xcafe, account2 = @0xface)]
    public entry fun test_set_num_signatures_required(account1: &signer, account2: &auth) acquires Account, OriginatingAddress {
        initialize_for_test();
        let addr1 = signer::address_of(account1);
        create_account_unchecked(addr1);
        add_authentication_key(account1, account2);
        set_num_signatures_required(account1, 2);
        let num_signatures_required = borrow_global<Account>(addr1).num_signatures_required;
        assert!(num_signatures_required == 2, 0);
    }

    #[test(account = @0xface)]
    #[expected_failure(abort_code = 0x10019, location = Self)]
    public entry fun test_set_num_signatures_required_exceed_keys_size_should_fail(account: &signer) acquires Account {
        let addr = signer::address_of(account);
        create_account_unchecked(addr);
        set_num_signatures_required(account, 2);
    }

    #[test(account = @0xface)]
    #[expected_failure(abort_code = 0x10019, location = Self)]
    public entry fun test_set_num_signatures_required_to_zero_should_fail(account: &signer) acquires Account {
        let addr = signer::address_of(account);
        create_account_unchecked(addr);
        set_num_signatures_required(account, 0);
    }

    #[test(account1 = @0xface, account2 = @0xcafe)]
    public entry fun test_check_authentication_key(account1: &signer, account2: &auth) acquires Account, OriginatingAddress {
        initialize_for_test();
        let addr1 = signer::address_of(account1);
        let auth1 = bcs::to_bytes(&addr1);
        let auth2 = bcs::to_bytes(account2);
        create_account_unchecked(addr1);
        assert!(check_authentication_key(addr1, vector[auth1]), 0);
        assert!(!check_authentication_key(addr1, vector[auth2]), 1);
        assert!(!check_authentication_key(addr1, vector[auth1, auth2]), 2);
        add_authentication_key(account1, account2);
        assert!(check_authentication_key(addr1, vector[auth1]), 3);
        assert!(check_authentication_key(addr1, vector[auth2]), 4);
        assert!(check_authentication_key(addr1, vector[auth1, auth2]), 5);
        set_num_signatures_required(account1, 2);
        assert!(!check_authentication_key(addr1, vector[auth1]), 6);
        assert!(!check_authentication_key(addr1, vector[auth2]), 7);
        assert!(check_authentication_key(addr1, vector[auth1, auth2]), 8);
        set_num_signatures_required(account1, 1);
        remove_authentication_key(account1, auth1);
        assert!(!check_authentication_key(addr1, vector[auth1]), 9);
        assert!(check_authentication_key(addr1, vector[auth2]), 10);
        assert!(!check_authentication_key(addr1, vector[auth1, auth2]), 11);
    }

    #[test(account1 = @0xface, account2 = @0xcafe)]
    public entry fun test_is_original_account(account1: &signer, account2: auth) acquires Account, OriginatingAddress {
        let addr1 = signer::address_of(account1);
        create_account_unchecked(addr1);
        assert!(is_original_account(addr1), 0);
        add_authentication_key(account1, &account2);
        assert!(!is_original_account(addr1), 1);
        remove_authentication_key(account1, bcs::to_bytes(&account2));
        assert!(is_original_account(addr1), 2);
        swap_authentication_key(account1, &account2, bcs::to_bytes(&addr1));
        assert!(!is_original_account(addr1), 3);
    }

    #[test(creator = @0x1001, a1 = @0x1001, a2 = @0x1002, a3 = @0x1003)]
    public entry fun test_batch_add_auth_key(
        creator: signer,
        a1: auth,
        a2: auth,
        a3: auth,
    ) acquires Account, OriginatingAddress {
        let addr = signer::address_of(&creator);
        let auth1 = bcs::to_bytes(&a1);
        let auth2 = bcs::to_bytes(&a2);
        let auth3 = bcs::to_bytes(&a3);
        create_account_unchecked(addr);
        batch_add_authentication_key(&creator, vector[a2, a3], 2);
        let resource = borrow_global<Account>(addr);
        let authentication_key = resource.authentication_key;
        assert!(authentication_key == vector[auth1, auth2, auth3], 0);
        assert!(resource.num_signatures_required == 2, 1);
        batch_add_authentication_key(&creator, vector[], 3);
        let resource = borrow_global<Account>(addr);
        let authentication_key = resource.authentication_key;
        assert!(authentication_key == vector[auth1, auth2, auth3], 0);
        assert!(resource.num_signatures_required == 3, 1);
    }

    #[test(creator = @0x1001, a1= @0x1001, a2 = @0x1002, a3 = @0x1003, a4 = @0x1004)]
    public entry fun test_batch_remove_auth_key(
        creator: signer,
        a1: auth,
        a2: auth,
        a3: auth,
        a4: auth,
    ) acquires Account, OriginatingAddress {
        let addr = signer::address_of(&creator);
        let auth1 = bcs::to_bytes(&a1);
        let auth2 = bcs::to_bytes(&a2);
        let auth3 = bcs::to_bytes(&a3);
        let auth4 = bcs::to_bytes(&a4);
        create_account_unchecked(addr);
        batch_add_authentication_key(&creator, vector[a2, a3, a4], 2);
        let resource = borrow_global<Account>(addr);
        let authentication_key = resource.authentication_key;
        assert!(authentication_key == vector[auth1, auth2, auth3, auth4], 0);
        assert!(resource.num_signatures_required == 2, 1);
        batch_remove_authentication_key(&creator, vector[auth2, auth3], 2);
        let resource = borrow_global<Account>(addr);
        let authentication_key = resource.authentication_key;
        assert!(authentication_key == vector[auth1, auth4], 2);
        assert!(resource.num_signatures_required == 2, 3);
    }

    #[test(creator = @0x1001, a1= @0x1001, a2 = @0x1002, a3 = @0x1003, a4 = @0x1004)]
    #[expected_failure(abort_code = 0x10019, location = Self)]
    public entry fun test_batch_remove_auth_key_fail(
        creator: signer,
        a1: auth,
        a2: auth,
        a3: auth,
        a4: auth,
    ) acquires Account, OriginatingAddress {
        let addr = signer::address_of(&creator);
        let auth1 = bcs::to_bytes(&a1);
        let auth2 = bcs::to_bytes(&a2);
        let auth3 = bcs::to_bytes(&a3);
        let auth4 = bcs::to_bytes(&a4);
        create_account_unchecked(addr);
        batch_add_authentication_key(&creator, vector[a2, a3, a4], 2);
        let resource = borrow_global<Account>(addr);
        let authentication_key = resource.authentication_key;
        assert!(authentication_key == vector[auth1, auth2, auth3, auth4], 0);
        assert!(resource.num_signatures_required == 2, 1);
        batch_remove_authentication_key(&creator, vector[auth2, auth3, auth4], 2);
    }
}

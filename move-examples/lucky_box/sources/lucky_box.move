/// Lucky Box
/// This module provides three ways to authenticate unpackers:
/// 1. Whitelist: Only the unpackers in the whitelist can unpack the box.
///     * In order to save gas, only the first 8 bytes(u64) of the address are used as identification
///     * The address prefix will be removed from the whitelist after unpacking.
///     * Due to the maximum gas limit of the transaction, this method cannot support a very large whitelist.
/// 
/// 2. Merkle Tree: The unpacker must provide a merkle path to the root.
///     * When calculating the merkle root or merkle path, the address prefix is used instead of the full address.
/// 
/// 3. Guard Signer: The unpacker must provide a signature from a guard signer.
module lucky_box::lucky_box {
    use endless_framework::randomness;
    use endless_framework::event;
    use endless_framework::timestamp;
    use endless_framework::endless_coin;
    use endless_framework::account;
    use endless_framework::object;
    use endless_framework::primary_fungible_store;
    use endless_framework::fungible_asset;
    use endless_std::ed25519;
    use std::vector;
    use std::signer;
    use std::bcs;
    use std::hash::sha3_256;

    struct Funding has key {
        cap: account::SignerCapability,
    }

    #[resource_group_member(group = endless_framework::object::ObjectGroup)]
    /// Lucky box resource, when a new box is packed, this will be stored in a unique object.
    /// The address of this object is the `id` of the box.
    struct Box has key, copy {
        packer: address,
        // If true, random distribution
        // If false, evenly distribution
        random: bool,
        amount: u128,
        count: u64,
        // Expire timestamp by seconds
        expire: u64,
        packed_count: u64,
        packed_amount: u128,
        gas_remain: u64,
        gas_prepaid: u64,
    }

    struct Unpackers has key, drop {
        unpackers: vector<u64>,
    }

    struct MerkelRoot has key, drop {
        root: u64,
        seen: vector<address>,
    }

    struct GuardSigner has key, drop {
        public_key: ed25519::UnvalidatedPublicKey,
        seen: vector<address>,
    }

    #[event]
    struct Packing has store, drop {
        // Box id
        id: address,
        packer: address,
        random: bool,
        amount: u128,
        count: u64,
        expire: u64,
        gas_prepaid: u64,
    }

    #[event]
    struct Unpacking has store, drop {
        // Box id
        id: address,
        unpacker: address,
        // Unpack amount
        amount: u128,
        total_count: u64,
        packed_count: u64,
    }

    #[event]
    struct Refund has store, drop {
        // Box id
        id: address,
        packer: address,
        total_amount: u128,
        total_count: u64,
        // Box amount refund to packer
        packed_amount: u128,
        packed_count: u64,
        expire: u64,
        // Gas refund to packer
        gas_remain: u64,
    }

    // Constants
    /// Maximum number of unpackers when use whitelist
    const MAX_UNPACKERS_COUNT: u64 = 10000;
    /// Estimated gas fee, if caller is not on the chain
    /// Include account creation gas fee
    const NEW_ACCOUNT_UNIT_GAS_FEE: u64 = 110000;
    /// Estimated gas fee, if caller is already on the chain
    const UNIT_GAS_FEE: u64 = 2000;
    /// Guard sign seed, it's sha3_256 of "ENDLESS::LuckyBoxUnpacker"
    const GUARD_SIGN_SEED: vector<u8> = x"1b968a2bef1740795ef3f882744907d2dc8f2123392b1a37dcb3b6b18f1fac48";

    /// Invalid amount
    const E_INVALID_AMOUNT: u64 = 0;
    /// Invalid count
    const E_INVALID_COUNT: u64 = 1;
    /// Expired box
    const E_EXPIRED: u64 = 2;
    /// Box id not found
    const E_INVALID_ID: u64 = 3;
    /// Already completed
    const E_ALREADY_COMPLETED: u64 = 4;
    /// Too many unpackers
    const E_TOO_MANY_UNPACKERS: u64 = 5;
    /// Invalid unpacker
    const E_INVALID_UNPACKER: u64 = 6;
    const E_GAS_PRICE_TOO_HIGH: u64 = 7;
    /// Unexpected error
    const E_UNEXPECTED_ERROR: u64 = 8;
    /// Only can refund from expired box
    const E_NOT_EXPIRED: u64 = 9;
    /// Already refunded
    const E_NOTHING_TO_REFUND: u64 = 10;
    /// Box not found or unpack method mismatch
    const E_MISMATCH_METHOD: u64 = 11;
    /// Invalid merkle path
    const E_INVALID_MERKLE_PATH: u64 = 12;
    /// Invalid guard signature
    const E_INVALID_GUARD_SIGNATURE: u64 = 13;

    fun init_module(lucky_box: &signer) {
        if (!exists<Funding>(@lucky_box)) {
            let (_, resource_account_cap) = account::create_resource_account(lucky_box, b"lucky_box::Funding account seed");
            move_to(lucky_box, Funding {
                cap: resource_account_cap,
            });
        }
    }

    #[view]
    public fun get_box(ids: vector<address>): vector<Box> acquires Box {
        vector::map_ref(&ids, |id| *borrow_global<Box>(*id))
    }

    /// Pack a box, `unpakcers` is a whitelist of who can unpack this box
    public entry fun pack(caller: &signer, amount: u128, count: u64, random: bool, expire: u64, unpackers: vector<u64>) acquires Funding {
        let unpacker_len = vector::length(&unpackers);
        assert!(unpacker_len <= MAX_UNPACKERS_COUNT, E_TOO_MANY_UNPACKERS);

        let box = pack_internal(caller, amount, count, random, expire);
        move_to(&box, Unpackers {
            unpackers,
        });
    }

    /// Pack a box, similar to `pack`, but use merkle tree instead of whitelist
    public entry fun pack_with_merkle_tree(caller: &signer, amount: u128, count: u64, random: bool, expire: u64, merkle_root: u64) acquires Funding {
        let box = pack_internal(caller, amount, count, random, expire);
        move_to(&box, MerkelRoot {
            root: merkle_root,
            seen: vector[],
        });
    }

    /// Pack a box, similar to `pack`, but use a guard signer
    public entry fun pack_with_guard(caller: &signer, amount: u128, count: u64, random: bool, expire: u64, guard_pub_key: vector<u8>) acquires Funding {
        let box = pack_internal(caller, amount, count, random, expire);
        let public_key = ed25519::new_unvalidated_public_key_from_bytes(guard_pub_key);
        move_to(&box, GuardSigner {
            public_key,
            seen: vector[],
        });
    }

    /// Unpack a box that uses the whitelist
    entry sponsored fun unpack(caller: &signer, id: address) acquires Funding, Box, Unpackers, MerkelRoot, GuardSigner {
        let unpacker = signer::address_of(caller);
        assert!(object::object_exists<Unpackers>(id), E_MISMATCH_METHOD);

        let unpackers = &mut borrow_global_mut<Unpackers>(id).unpackers;
        let unpacker_prefix = address_prefix(unpacker);
        let (valid_unpacker, unpacker_idx) = vector::index_of(unpackers, &unpacker_prefix);
        assert!(valid_unpacker, E_INVALID_UNPACKER);
        // Remove unpacker
        vector::swap_remove(unpackers, unpacker_idx);

        unpack_internal(unpacker, id);
    }

    /// Unpack a box that uses the merkle tree
    /// `bitmask` is a bit vector to indicate the direction of the merkle path
    /// if ((bitmask >> i) & 1) == 1, then the `merkle_path[i]` is the left node
    entry sponsored fun unpack_with_merkle_tree(caller: &signer, id: address, merkle_path: vector<u64>, bitmask: u64) 
        acquires Funding, Box, Unpackers, MerkelRoot, GuardSigner
    {
        let unpacker = signer::address_of(caller);
        assert!(object::object_exists<MerkelRoot>(id), E_MISMATCH_METHOD);
        assert!(vector::length(&merkle_path) > 0, E_INVALID_MERKLE_PATH);

        let merkle = borrow_global_mut<MerkelRoot>(id);
        assert!(!vector::contains(&merkle.seen, &unpacker), E_INVALID_UNPACKER);
        vector::push_back(&mut merkle.seen, unpacker);
        let unpacker_prefix = address_prefix(unpacker);
        assert!(check_merkle_path(unpacker_prefix, merkle.root, merkle_path, bitmask), E_INVALID_MERKLE_PATH);

        unpack_internal(unpacker, id);
    }

    /// Unpack a box that uses the guard signer
    entry sponsored fun unpack_with_guard(caller: &signer, id: address, signature: vector<u8>) 
        acquires Funding, Box, Unpackers, MerkelRoot, GuardSigner
    {
        let unpacker = signer::address_of(caller);
        assert!(object::object_exists<GuardSigner>(id), E_MISMATCH_METHOD);

        let signature = ed25519::new_signature_from_bytes(signature);
        let guard = borrow_global_mut<GuardSigner>(id);
        assert!(!vector::contains(&guard.seen, &unpacker), E_INVALID_UNPACKER);
        vector::push_back(&mut guard.seen, unpacker);
        let message = vector[];
        vector::append(&mut message, GUARD_SIGN_SEED);
        vector::append(&mut message, bcs::to_bytes(&id));
        vector::append(&mut message, bcs::to_bytes(&unpacker));
        assert!(ed25519::signature_verify_strict(&signature, &guard.public_key, message), E_INVALID_GUARD_SIGNATURE);

        unpack_internal(unpacker, id);
    }

    /// Refund from a expired box
    /// 1. Refund remaining gas fee to packer
    /// 2. Refund packed amount to packer
    /// 3. Transfer used gas fee from resource account to contract
    entry fun refund(ids: vector<address>) acquires Funding, Box, Unpackers, MerkelRoot, GuardSigner {
        vector::for_each_reverse(ids, |id| {
            assert!(object::object_exists<Box>(id), E_INVALID_ID);
            let box = borrow_global_mut<Box>(id);
            let now = timestamp::now_seconds();
            assert!(now >= box.expire, E_NOT_EXPIRED);
            assert!(box.gas_prepaid > 0, E_NOTHING_TO_REFUND);
            refund_internal(id, box);
        });
    }

    fun pack_internal(caller: &signer, amount: u128, count: u64, random: bool, expire: u64): signer acquires Funding {
        let packer = signer::address_of(caller);
        // Common validations
        assert!(amount > 0, E_INVALID_AMOUNT);
        assert!(amount >= (count as u128), E_INVALID_AMOUNT);
        assert!(count > 0, E_INVALID_COUNT);
        assert!(timestamp::now_seconds() < expire, E_EXPIRED);

        let eds_metadata = endless_coin::get_metadata();
        // Withdraw box amount from packer
        let amount_fa = primary_fungible_store::withdraw(caller, eds_metadata, amount);
        // Precharge gas fee, which will be paid by the contract when unpacking
        // This is just an estimate, assume all unpacker is not on chain
        let gas_fee = NEW_ACCOUNT_UNIT_GAS_FEE * count;
        let gas_fa = primary_fungible_store::withdraw(caller, eds_metadata, (gas_fee as u128));
        // Deposit (box amount) + (precharge gas fee) to resource account
        fungible_asset::merge(&mut amount_fa, gas_fa);
        primary_fungible_store::deposit(funding_address(), amount_fa);

        // Create box object
        let constructor_ref = object::create_sticky_object(packer);
        let object_signer = object::generate_signer(&constructor_ref);
        let id = signer::address_of(&object_signer);
        move_to(&object_signer, Box {
            packer,
            random,
            amount,
            count,
            expire,
            packed_count: count,
            packed_amount: amount,
            gas_prepaid: gas_fee,
            gas_remain: gas_fee,
        });

        event::emit(Packing {
            id,
            packer,
            random,
            amount,
            count,
            expire,
            gas_prepaid: gas_fee,
        });
        object_signer
    }

    /// Unpack helper
    fun unpack_internal(unpacker: address, id: address) acquires Box, Funding, Unpackers, MerkelRoot, GuardSigner {
        assert!(object::object_exists<Box>(id), E_INVALID_ID);
        let box = borrow_global_mut<Box>(id);
        assert!(timestamp::now_seconds() < box.expire, E_EXPIRED);
        assert!(box.packed_count > 0, E_ALREADY_COMPLETED);

        let amount = if (box.packed_count == 1) {
            box.packed_amount
        } else if (box.random) {
            let upper_bound = box.packed_amount * 2 / (box.packed_count as u128);
            // we need ensure packed_amount_after >= packed_count_after
            // packed_amount_after = packed_amount - amount
            // packed_count_after = packed_count - 1
            // so amount <= packed_amount - packed_count + 1
            // so upper_bound <= packed_amount - packed_count + 2
            if (upper_bound > box.packed_amount - (box.packed_count as u128) + 2) {
                upper_bound = box.packed_amount - (box.packed_count as u128) + 2;
            };
            randomness::u128_range(1, upper_bound)
        } else {
            box.amount / (box.count as u128)
        };
        box.packed_amount = box.packed_amount - amount;
        box.packed_count = box.packed_count - 1;

        let estimated_gas = if (account::get_sequence_number(unpacker) == 0) {
            NEW_ACCOUNT_UNIT_GAS_FEE
        } else {
            UNIT_GAS_FEE
        };
        box.gas_remain = box.gas_remain - estimated_gas;

        endless_coin::transfer(funding_signer(), unpacker, (amount as u128));

        event::emit(Unpacking {
            id,
            unpacker,
            amount,
            total_count: box.count,
            packed_count: box.packed_count,
        });

        if (box.packed_count == 0) {
            // 1.Refund remaining gas fee
            // 2.Transfer used gas fee from resource account to contract
            assert!(box.packed_amount == 0, E_UNEXPECTED_ERROR);
            refund_internal(id, box);
        };
    }

    fun refund_internal(id: address, box: &mut Box) acquires Funding, Unpackers, MerkelRoot, GuardSigner {
        let eds_metadata = endless_coin::get_metadata();
        let packer = box.packer;
        // Transfer gas fee from resource account to contract
        let amount = box.packed_amount + (box.gas_prepaid as u128);
        let total = primary_fungible_store::withdraw(funding_signer(), eds_metadata, (amount as u128));
        let refund_amount = box.packed_amount;
        let refund_gas = box.gas_remain;
        let refund_evt = Refund {
            id,
            packer,
            total_amount: box.amount,
            total_count: box.count,
            packed_amount: box.packed_amount,
            packed_count: box.packed_count,
            expire: box.expire,
            gas_remain: refund_gas,
        };
        box.packed_amount = 0;
        box.packed_count = 0;
        box.gas_remain = 0;
        box.gas_prepaid = 0;

        if (exists<Unpackers>(id)) {
            let _ = move_from<Unpackers>(id);
        } else if (exists<MerkelRoot>(id)) {
            let _ = move_from<MerkelRoot>(id);
        } else {
            assert!(exists<GuardSigner>(id), E_UNEXPECTED_ERROR);
            let _ = move_from<GuardSigner>(id);
        };

        // For emit 2 deposit events here
        if (refund_amount > 0) {
            let fa = fungible_asset::extract(&mut total, (refund_amount as u128));
            primary_fungible_store::deposit(packer, fa);
        };
        if (refund_gas > 0) {
            let fa = fungible_asset::extract(&mut total, (refund_gas as u128));
            primary_fungible_store::deposit(packer, fa);
        };
        primary_fungible_store::deposit(@lucky_box, total);
        event::emit(refund_evt);
    }

    // `bitmask` is a bit vector to indicate the direction of the merkle path
    // if bitmask[i] == 1, then the path[i] is the left child
    fun check_merkle_path(self: u64, root: u64, path: vector<u64>, bitmask: u64): bool {
        let lhs = self;
        assert!(vector::length(&path) <= 64, E_INVALID_MERKLE_PATH);
        while (!vector::is_empty(&path)) {
            let rhs = vector::pop_back(&mut path);
            let is_left = (bitmask & 1) == 1;
            bitmask = bitmask >> 1;
            lhs = if (is_left) {
                hash_u64(rhs, lhs)
            } else {
                hash_u64(lhs, rhs)
            };
        };
        lhs == root
    }

    fun hash_u64(lhs: u64, rhs: u64): u64 {
        let bytes = bcs::to_bytes(&lhs);
        vector::append(&mut bytes, bcs::to_bytes(&rhs));
        // bcs use little endian, so we need reverse here
        vector::reverse_slice(&mut bytes, 0, 8);
        vector::reverse_slice(&mut bytes, 8, 16);
        
        let hashed = sha3_256(bytes);
        hash_prefix(hashed)
    }

    fun address_prefix(addr: address): u64 {
        let bytes = bcs::to_bytes(&addr);
        let ret = 0;
        let i = 0;
        while (i < 8) {
            ret = (ret << 8) + (*vector::borrow(&bytes, i) as u64);
            i = i + 1;
        };
        ret
    }

    fun hash_prefix(hash: vector<u8>): u64 {
        let ret = 0;
        let i = 0;
        while (i < 8) {
            ret = (ret << 8) + (*vector::borrow(&hash, i) as u64);
            i = i + 1;
        };
        ret
    }

    inline fun funding_address(): address acquires Funding {
        let funding = borrow_global<Funding>(@lucky_box);
        account::get_signer_capability_address(&funding.cap)
    }
    inline fun funding_signer(): &signer acquires Funding {
        let funding = borrow_global<Funding>(@lucky_box);
        &account::create_signer_with_capability(&funding.cap)
    }

    #[test]
    fun test_merkle() {
        /*
            1     2         3      4        5       5
        f9cb06c40367fdc1 d66b2af1d353f841 1d562241e64717f2 1d562241e64717f2
                a7e8a6f9bf9d1d34                0089c2e288c739f5
                                52d59f6d16bac4ad
        */
        assert!(check_merkle_path(1, 0x52d59f6d16bac4ad, vector[0x0089c2e288c739f5, 0xd66b2af1d353f841, 2], 0), 1);
        assert!(check_merkle_path(2, 0x52d59f6d16bac4ad, vector[0x0089c2e288c739f5, 0xd66b2af1d353f841, 1], 0x1), 2);
        assert!(check_merkle_path(3, 0x52d59f6d16bac4ad, vector[0x0089c2e288c739f5, 0xf9cb06c40367fdc1, 4], 0x2), 3);
        assert!(check_merkle_path(4, 0x52d59f6d16bac4ad, vector[0x0089c2e288c739f5, 0xf9cb06c40367fdc1, 3], 0x3), 4);
        assert!(check_merkle_path(5, 0x52d59f6d16bac4ad, vector[0xa7e8a6f9bf9d1d34, 0x1d562241e64717f2, 5], 0x4), 5);
        assert!(check_merkle_path(5, 0x52d59f6d16bac4ad, vector[0xa7e8a6f9bf9d1d34, 0x1d562241e64717f2, 5], 0x5), 6);
    }
}


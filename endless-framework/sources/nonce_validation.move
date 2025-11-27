module endless_framework::nonce_validation {
    use endless_std::table::{Self, Table};
    use endless_std::timestamp;
    use endless_std::big_ordered_map::{Self, BigOrderedMap};
    use endless_std::endless_hash::sip_hash_from_value;
    use endless_std::error;
    use endless_framework::system_addresses;
    use std::features;
    use std::option;
    #[test_only]
    use std::string;
    #[test_only]
    use endless_std::debug;
    friend endless_framework::genesis;
    friend endless_framework::transaction_validation;


    const NUM_BUCKETS: u64 = 50000;

    // After a transaction expires, we wait for NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS seconds
    // before garbage collecting the transaction from the nonce history.
    // We maintain an invariant that two transactions with the same (address, nonce) pair cannot be stored
    // in the nonce hsitory if their transanction expiration times are less than
    // `NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS` seconds apart.
    // const NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS: u64 = 65;

    const NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS: u64 = 24 * 60 * 60 + 5;  // 1 day + 5 secs.


    // Each time we check if an (address, nonce) pair can be inserted into nonce history,
    // we try to initially garbage collect expired nonces in the bucket. This is a limit on the number of nonces
    // we try to garbage collect in a single call.
    const MAX_ENTRIES_GARBAGE_COLLECTED_PER_CALL: u64 = 5;

    // Orderless transactions feature is not enabled.
    const E_ORDERLESS_TRANSACTIONS_NOT_ENABLED: u64 = 1000;

    // Nonce history resource does not exist.
    const E_NONCE_HISTORY_DOES_NOT_EXIST: u64 = 1001;

    // Transaction expiration time is too far in the future.
    const ETRANSACTION_EXPIRATION_TOO_FAR_IN_FUTURE: u64 = 1002;


    // An orderless transaction is a transaction that doesn't have a sequence number.
    // Orderless transactions instead contain a nonce to prevent replay attacks.
    // If the incoming transaction has the same (address, nonce) pair as a previous unexpired transaction, it is rejected.
    // The nonce history is used to store the list of (address, nonce, txn expiration time) values of all unexpired transactions.
    // The nonce history is used in the transaction validation process to check if the incoming transaction is valid.
    struct NonceHistory has key {
        // Key = sip_hash(NonceKey) % NUM_BUCKETS
        // Value = Bucket
        nonce_table: Table<u64, Bucket>,
        // Used to facilitate prefill the nonce_table with empty buckets
        // one by one using `add_nonce_bucket` method.
        // This is the next_key to prefill with an empty bucket
        next_key: u64,
    }

    // The bucket stores (address, nonce, txn expiration time) tuples.
    // All the entries in the bucket contain the same hash(address, nonce) % NUM_BUCKETS.
    // The first big ordered map in the bucket stores (expiration time, address, nonce) -> true.
    // The second big ordered map in the bucket stores (address, nonce) -> expiration time.
    // Both the maps store the same data, just in a different format.
    // As the key in the first big ordered map starts with expiration time, it's easy to figure out which
    // entries have expired at the current time. The first big ordered map helps with easy garbage collection.
    // The second big ordered map helps with checking if the given (address, nonce) pair exists in the bucket.
    // An (address, nonce) pair is guaranteed to be unique in both the big ordered maps. Two transactions with
    // the same (address, nonce) pair cannot be stored at the same time.
    struct Bucket has store {
        // The first big ordered map in the bucket stores (expiration time, address, nonce) -> true.
        nonces_ordered_by_exp_time: BigOrderedMap<NonceKeyWithExpTime, bool>,
        // The second big ordered map in the bucket stores (address, nonce) -> expiration time.
        nonce_to_exp_time_map: BigOrderedMap<NonceKey, u64>,
    }

    struct NonceKeyWithExpTime has copy, drop, store {
        txn_expiration_time: u64,
        sender_address: address,
        nonce: u64,
    }

    struct NonceKey has copy, drop, store {
        sender_address: address,
        nonce: u64,
    }

    public(friend) fun initialize(endless_framework: &signer) {
        initialize_nonce_table(endless_framework);
    }

    public entry fun initialize_nonce_table(endless_framework: &signer) {
        system_addresses::assert_endless_framework(endless_framework);
        if (!exists<NonceHistory>(@endless_framework)) {
            let table = table::new();
            let nonce_history = NonceHistory {
                nonce_table: table,
                next_key: 0,
            };
            move_to<NonceHistory>(endless_framework, nonce_history);
        };
    }

    fun empty_bucket(pre_allocate_slots: bool): Bucket {
        let bucket = Bucket {
            nonces_ordered_by_exp_time: big_ordered_map::new_with_reusable(),
            nonce_to_exp_time_map: big_ordered_map::new_with_reusable(),
        };

        if (pre_allocate_slots) {
            // Initiating big ordered maps with 5 pre-allocated storage slots.
            // (expiration time, address, nonce) is together 48 bytes.
            // A 4 KB storage slot can store 80+ such tuples.
            // The 5 slots should be more than enough for the current use case.
            big_ordered_map::allocate_spare_slots(&mut bucket.nonces_ordered_by_exp_time, 5);
            big_ordered_map::allocate_spare_slots(&mut bucket.nonce_to_exp_time_map, 5);
        };
        bucket
    }

    // This method is used to prefill the nonce_table with empty buckets one by one.
    public entry fun add_nonce_buckets(count: u64) acquires NonceHistory {
        assert!(exists<NonceHistory>(@endless_framework), error::invalid_state(E_NONCE_HISTORY_DOES_NOT_EXIST));
        let nonce_history = borrow_global_mut<NonceHistory>(@endless_framework);
        let i = 0;
        while (i < count) {
            if (nonce_history.next_key <= NUM_BUCKETS) {
                if (!table::contains(&nonce_history.nonce_table, nonce_history.next_key)) {
                    table::add(
                        &mut nonce_history.nonce_table,
                        nonce_history.next_key,
                        empty_bucket(true)
                    );
                };
                nonce_history.next_key = nonce_history.next_key + 1;
            };
            i = i + 1;
        }
    }

    // Returns true if the input (address, nonce) pair doesn't exist in the nonce history, and inserted into nonce history successfully.
    // Returns false if the input (address, nonce) pair already exists in the nonce history.
    public(friend) fun check_nonce(
        sender_address: address,
        nonce: u64,
        txn_expiration_time: u64,
    ): bool acquires NonceHistory {
        check_and_insert_nonce(sender_address, nonce, txn_expiration_time)
    }

    // Insert nonce without checking
    public(friend) fun insert_nonce(
        sender_address: address,
        nonce: u64,
        txn_expiration_time: u64,
    ) acquires NonceHistory {
        check_and_insert_nonce(sender_address, nonce, txn_expiration_time);
    }

    // Returns true if the input (address, nonce) pair doesn't exist in the nonce history, and inserted into nonce history successfully.
    // Returns false if the input (address, nonce) pair already exists in the nonce history.
    fun check_and_insert_nonce(
        sender_address: address,
        nonce: u64,
        txn_expiration_time: u64,
    ): bool acquires NonceHistory {
        assert!(exists<NonceHistory>(@endless_framework), error::invalid_state(E_NONCE_HISTORY_DOES_NOT_EXIST));
        // Check if the transaction expiration time is too far in the future.
        assert!(txn_expiration_time <= timestamp::now_seconds() + NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS, error::invalid_argument(ETRANSACTION_EXPIRATION_TOO_FAR_IN_FUTURE));
        let nonce_history = borrow_global_mut<NonceHistory>(@endless_framework);
        let nonce_key = NonceKey {
            sender_address,
            nonce,
        };
        let bucket_index = sip_hash_from_value(&nonce_key) % NUM_BUCKETS;
        let current_time = timestamp::now_seconds();
        if (!table::contains(&nonce_history.nonce_table, bucket_index)) {
            table::add(
                &mut nonce_history.nonce_table,
                bucket_index,
                empty_bucket(false)
            );
        };
        let bucket = table::borrow_mut(&mut nonce_history.nonce_table, bucket_index);

        let existing_exp_time = big_ordered_map::get(&bucket.nonce_to_exp_time_map, &nonce_key);
        if (option::is_some(&existing_exp_time)) {
            let existing_exp_time = option::extract(&mut existing_exp_time);

            // If the existing (address, nonce) pair has not expired, return false.
            if (existing_exp_time >= current_time) {
                return false;
            };

            // We maintain an invariant that two transaction with the same (address, nonce) pair cannot be stored
            // in the nonce history if their transaction expiration times are less than `NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS`
            // seconds apart.
            if (txn_expiration_time <= existing_exp_time + NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS) {
                return false;
            };

            // If the existing (address, nonce) pair has expired, garbage collect it.
            big_ordered_map::remove(&mut bucket.nonce_to_exp_time_map, &nonce_key);
            big_ordered_map::remove(&mut bucket.nonces_ordered_by_exp_time, &NonceKeyWithExpTime {
                txn_expiration_time: existing_exp_time,
                sender_address,
                nonce,
            });
        };

        // Garbage collect upto MAX_ENTRIES_GARBAGE_COLLECTED_PER_CALL expired nonces in the bucket.
        let i = 0;
        while (i < MAX_ENTRIES_GARBAGE_COLLECTED_PER_CALL && !big_ordered_map::is_empty(&bucket.nonces_ordered_by_exp_time)) {
            let (front_k, _) = big_ordered_map::borrow_front(&bucket.nonces_ordered_by_exp_time);
            // We garbage collect a nonce after it has expired and the NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS
            // seconds have passed.
            if (front_k.txn_expiration_time + NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS < current_time) {
                big_ordered_map::pop_front(&mut bucket.nonces_ordered_by_exp_time);
                big_ordered_map::remove(&mut bucket.nonce_to_exp_time_map, &NonceKey {
                    sender_address: front_k.sender_address,
                    nonce: front_k.nonce,
                });
            } else {
                break
            };
            i = i + 1;
        };

        // Insert the (address, nonce) pair in the bucket.
        let nonce_key_with_exp_time = NonceKeyWithExpTime {
            txn_expiration_time,
            sender_address,
            nonce,
        };
        big_ordered_map::add(&mut bucket.nonces_ordered_by_exp_time, nonce_key_with_exp_time, true);
        big_ordered_map::add(&mut bucket.nonce_to_exp_time_map, nonce_key, txn_expiration_time);
        true
    }

    // Returns true if the input (address, nonce) pair doesn't exist in the nonce history.
    // Returns false if the input (address, nonce) pair already exists in the nonce history.
    #[test_only]
    fun check_if_nonce_exists_in_history(
        sender_address: address,
        nonce: u64,
    ): bool acquires NonceHistory {
        assert!(exists<NonceHistory>(@endless_framework), error::invalid_state(E_NONCE_HISTORY_DOES_NOT_EXIST));
        let nonce_key = NonceKey {
            sender_address,
            nonce,
        };
        let bucket_index = sip_hash_from_value(&nonce_key) % NUM_BUCKETS;
        let nonce_history = borrow_global<NonceHistory>(@endless_framework);
        if (table::contains(&nonce_history.nonce_table, bucket_index)) {
            let bucket = table::borrow(&nonce_history.nonce_table, bucket_index);
            let existing_exp_time = big_ordered_map::get(&bucket.nonce_to_exp_time_map, &nonce_key);
            if (option::is_some(&existing_exp_time)) {
                let existing_exp_time = option::extract(&mut existing_exp_time);
                // We store the nonce in nonce history for `NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS` seconds after it expires.
                if (timestamp::now_seconds() <= existing_exp_time + NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS) {
                    return false;
                };
            };
        };
        true
    }

    #[test(fx = @endless_framework)]
    public entry fun nonce_history_test(fx: signer) acquires NonceHistory {
        initialize_nonce_table(&fx);
        timestamp::set_time_has_started_for_testing(&fx);
        let begin_time = timestamp::now_seconds();

        debug::print(&string::utf8(b"=== Test Start ==="));
        debug::print(&string::utf8(b"Begin time:"));
        debug::print(&begin_time);

        debug::print(&string::utf8(b"Current time (step 1):"));
        debug::print(&timestamp::now_seconds());
        assert!(check_and_insert_nonce(@0x5, 1234, begin_time + 50), 1);
        assert!(!check_and_insert_nonce(@0x5, 1234, begin_time + 51), 2);
        assert!(!check_if_nonce_exists_in_history(@0x5, 1234), 3);
        assert!(check_if_nonce_exists_in_history(@0x5, 1235), 4);

        timestamp::fast_forward_seconds(30);
        debug::print(&string::utf8(b"Current time (after +30s):"));
        debug::print(&timestamp::now_seconds());
        assert!(!check_and_insert_nonce(@0x5, 1234, begin_time + 85), 5);
        assert!(check_and_insert_nonce(@0x5, 1235, begin_time + 85), 6);

        timestamp::fast_forward_seconds(85);
        debug::print(&string::utf8(b"Current time (after +85s):"));
        debug::print(&timestamp::now_seconds());
        // Nonce (0x5, 1234) expires at `begin_time + 50`.
        // Nonce (0x5, 1234) will be garbage collected after
        // `begin_time + 50 + NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS` seconds.
        assert!(!check_if_nonce_exists_in_history(@0x5, 1234), 7);
        timestamp::fast_forward_seconds(1);
        debug::print(&string::utf8(b"Current time (after +1s):"));
        debug::print(&timestamp::now_seconds());
        assert!(check_if_nonce_exists_in_history(@0x5, 1234), 8);
        assert!(check_and_insert_nonce(@0x5, 1234, begin_time + 150), 9);

        // Nonce (0x5, 1235) expired at `begin_time + 85` seconds.
        // We are currently at `begin_time + 116` seconds.
        // The nonce is still stored in nonce history.
        // But another nonce with expiry time higher than
        // `begin_time + 85 + NONCE_REPLAY_PROTECTION_OVERLAP_INTERVAL_SECS` can still be inserted.
        assert!(!check_if_nonce_exists_in_history(@0x5, 1235), 10);
        assert!(!check_and_insert_nonce(@0x5, 1235, begin_time + 150), 11);
        assert!(check_and_insert_nonce(@0x5, 1235, begin_time + 151), 12);
    }
}

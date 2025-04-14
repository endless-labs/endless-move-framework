module file_storage::file_storage_supervisor {

    use std::bcs;
    use std::bit_vector;
    use std::fixed_point32;
    use std::hash::sha3_256;
    use std::option;
    use std::option::Option;
    use std::poly_commit_fk20;
    use std::signer::address_of;
    use std::vector;
    use endless_std::smart_table;
    use endless_std::smart_table::SmartTable;
    use endless_framework::account;
    use endless_framework::account::SignerCapability;
    use endless_framework::endless_coin;
    use endless_framework::event;
    use endless_framework::randomness;
    use endless_framework::timestamp::now_seconds;
    use endless_std::ed25519;
    use endless_std::math64;
    use endless_std::simple_map;
    use file_storage::merkel_prove;

    #[test_only]
    use std::string;
    #[test_only]
    use endless_std::debug::print;
    #[test_only]
    use endless_framework::account::{create_account_unchecked_for_test};
    #[test_only]
    use endless_framework::reconfiguration;
    #[test_only]
    use endless_framework::timestamp;
    #[test_only]
    use endless_framework::timestamp::set_time_has_started_for_testing;

    #[test_only]
    use endless_std::ed25519::{SecretKey, ValidatedPublicKey,
        validated_public_key_to_bytes, signature_to_bytes, sign_arbitrary_bytes
    };
    #[test_only]
    use endless_std::string_utils;

    #[test_only]
    use file_storage::merkel_prove::{generate_merkel_proof_path};

    /// Scheme identifier for Ed25519 signatures used to derive authentication keys for Ed25519 public keys.
    const ED25519_SCHEME: u8 = 0;

    const PROVIDER_MIN_STACKING_AMOUNT: u128= 1 * 100000000;

    const FILE_SIGNATURE_U8_SIZE: u64 = 64;
    const COMMIT_DATA_U8_SIZE: u64 = 16;

    const DAY_SECONDS: u64 = 3600 * 24;
    const MAX_DELAY_UPDATE_CLENT_DELETED_FILLE_SECONDS: u64 = 1 * 24 * 3600;
    const MIN_INTERVAL_SECONDS_UPDATE_FEE_CONFIG: u64 = 30 * 24 * 3600;
    const MAX_CHALLENGE_PROVE_SECONDS: u64 = 7 * 24 * 3600;
    const MIN_COLLECTED_FEE_FREEZED_SECONDS: u64 = 7 * 24 * 3600;
    const MIN_UNREGISTER_AFTER_STOPING_SECONDS: u64 = 30 * 24 * 3600;


    const ADMIN_ADDR: address = @file_storage;

    const CONTRACT_NAME: vector<u8> = b"file_storage_supervisor";

    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_INVALID_DELETED_CHALLENGE_PROOF: u64 = 2;
    const E_INVALID_DELETED_FILE: u64 = 3;
    const E_INVALID_PACKAGE_FILE_INFO: u64 = 4;
    const E_INVALID_FILE_ROOT: u64 = 5;
    const E_INVALID_FILE_STATE: u64 = 6;
    const E_EXIST_ADDRESS: u64 = 7;
    const E_INVALID_FILE_SIGNATURE: u64 = 8;
    const E_CHALLENGE_FAILED: u64 = 9;
    const E_NO_FILE_EXIST: u64 = 10;
    const E_PROVIDER_INVALID: u64 = 11;
    const E_INVALID_VALUE: u64 = 12;
    const E_INVALID_ADMIN: u64 = 13;
    const E_NO_ENOUGH_INTERVAL: u64 = 14;
    const E_ILLEGAL_ACTION: u64 = 15;
    const E_TOO_MANY_CHALLLENGE_ONE_DAY: u64 = 16;


    const E_TEST_FAILED: u64 = 99;
    // pow of 2 to byte
    const FEE_UNIT_BYTE: u8 = 0;
    const FEE_UNIT_KB: u8 = 10;
    const FEE_UNIT_MB: u8 = 20;
    const FEE_UNIT_GB: u8 = 30;

    const ACCOUNT_STATE_VALID: u8 = 0;
    const ACCOUNT_STATE_NO_FEE: u8 = 1;
    const ACCOUNT_STATE_STOPING: u8 = 2;


    const EDS_ONE_COIN: u128 = 1_00000000;

    struct Challenge has store, drop, copy {
        id: vector<u8>,

        challenger: address,

        provider: address,

        client: address,

        commitment: vector<u8>,

        // File index when commitment
        file_pos: u64,

        // segment_r % segment_num is the challenged raw data segment offset.
        segment_r: u64,

        // Challenge start time.
        start_sec: u64,
    }

    struct ProveRecord has store, copy, drop {
        latest_failed_sec: u64,
    }

    /// Ongoing challenges will store here.
    struct ChallengeStore has key {
        // provider -> (client -> (commitment ->(id, Challenge)))
        challenges: SmartTable<address, SmartTable<address, SmartTable<vector<u8>, SmartTable<vector<u8>, Challenge>>>>,
        prove_records: SmartTable<address, ProveRecord>,
    }

    struct FeeConfig has store, copy, drop {
        fee_unit: u8,
        fee_per_day: u128,
        update_at: u64,
    }

    struct FeeCollectedInfo has store, copy, drop {
        client: address,
        amount: u128,
        collected_at: u64,
    }

    struct ProviderAccount has store, copy, drop {
        // Freezed balance for paying fee to stored files.
        freezed: u128,
        fee_collect_list: vector<FeeCollectedInfo>,
        state: u8,
        state_update_at: u64,
    }

    struct ClientAccount has store {
        latest_commitment: vector<u8>,

        // Stored file bytes at different providers.
        current_total_bytes: SmartTable<address, u64>,

        // Freezed balance for paying fee to stored files.
        freezed: u128,

        state: u8,
    }

    struct DeletedFileInfo has drop, copy {
        provider: address,

        client: address,

        commitment: vector<u8>,

        deleted_file_sequence_nos: vector<u64>,

        total_size: u64,

        delete_sec: u64,
    }


    struct FileSignedInfo has store, drop, copy {
        provider: address,

        file_root: vector<u8>,

        sequence_no: u64,

        agg_total_bytes: u64,

        segment_num: u64,
    }


    // Record client package of files everyday.
    struct PackageCommit has store, drop {
        signed_info: FileSignedInfo,

        total_bytes: u64,

        sequence_no_start: u64,

        commited_file_num: u64,

        // Decrease when deleted file.
        current_file_num: u64,

        // true -- deleted
        deleted_tag: bit_vector::BitVector,

        latest_challage_time: u64,

        upload_second: u64,

        fee_config: FeeConfig,

        paid_at: u64,
    }

    struct Ledger has key {
        // Payment account of client
        cli_accounts: SmartTable<address, ClientAccount>,

        pro_accounts: SmartTable<address, ProviderAccount>,

        // pubkey_store
        pub_keys: SmartTable<address, vector<u8>>,

        // Map hash(provider_address -> (client_address -> (package_commitment -> FilePackage))) to all user package.
        packages: SmartTable<address, SmartTable<address, SmartTable<vector<u8>, PackageCommit>>>,
        //packages_client: SmartTable<address, vector<&Packages>>

        pro_fee_configs: SmartTable<address, FeeConfig>,
    }

    /// Signer capability of resource address wrapped by CapStore will move to 0x1.
    struct SigCapStore has key {
        signer_cap: SignerCapability,
    }

    #[event]
    struct CompletedChallenge has drop, store {
        is_success: bool,
        challenge: Challenge,
        timesecond: u64,
    }

    fun init_module(admin: &signer) {
        assert!(address_of(admin) == ADMIN_ADDR, E_INVALID_ADMIN);
        move_to(admin, Ledger {
            cli_accounts: smart_table::new(),
            pro_accounts: smart_table::new(),
            pub_keys: smart_table::new(),
            packages: smart_table::new(),
            pro_fee_configs: smart_table::new(),
        });
        move_to(admin, ChallengeStore {
            challenges: smart_table::new(),
            prove_records: smart_table::new(),
        });

        add_resource_account(admin);
    }


    fun get_and_init_not_exist_package_challenge_container(
        challenges: &mut SmartTable<address, SmartTable<address, SmartTable<vector<u8>, SmartTable<vector<u8>, Challenge>>>>,
        provider: address,
        client: address,
        commitment: vector<u8>
    ): &mut SmartTable<vector<u8>, Challenge> {
        if (!smart_table::contains(challenges, provider)) {
            smart_table::add(challenges, provider, smart_table::new());
        };

        let provider_challenges = smart_table::borrow_mut(challenges, provider);
        if (!smart_table::contains(provider_challenges, client)) {
            smart_table::add(provider_challenges, client, smart_table::new());
        };

        let client_challenges = smart_table::borrow_mut(provider_challenges, client);
        if (!smart_table::contains(client_challenges, commitment)) {
            smart_table::add(client_challenges, commitment, smart_table::new());
        };

        smart_table::borrow_mut(client_challenges, commitment)
    }


    fun get_and_init_not_exist_packages_container(
        records: &mut SmartTable<address, SmartTable<address, SmartTable<vector<u8>, PackageCommit>>>,
        provider: address,
        client: address,
    ): &mut SmartTable<vector<u8>, PackageCommit> {
        if (!smart_table::contains(records, provider)) {
            smart_table::add(records, provider, smart_table::new());
        };

        let provider_records = smart_table::borrow_mut(records, provider);
        if (!smart_table::contains(provider_records, client)) {
            smart_table::add(provider_records, client, smart_table::new());
        };

        smart_table::borrow_mut(provider_records, client)
    }

    public entry fun upload_multi_cilent_daily_file_package(
        provider: &signer,
        multi_client: vector<address>,
        multi_latest_file_root: vector<vector<u8>>,
        multi_latest_sequence_no: vector<u64>,
        multi_agg_total_bytes: vector<u64>,
        multi_latest_file_segmnet_num: vector<u64>,
        multi_client_sig: vector<vector<u8>>,
        multi_commitment: vector<vector<u8>>,
    ) acquires Ledger {
        let client_num = vector::length(&multi_client);
        assert!(client_num > 0 &&
            client_num == vector::length(&multi_latest_file_root) &&
            client_num == vector::length(&multi_latest_sequence_no) &&
            client_num == vector::length(&multi_agg_total_bytes) &&
            client_num == vector::length(&multi_latest_file_segmnet_num) &&
            client_num == vector::length(&multi_client_sig) &&
            client_num == vector::length(&multi_commitment),
            E_INVALID_PACKAGE_FILE_INFO
        );

        for (_i in 0..client_num) {
            upload_single_cilent_daily_file_package(
                provider,
                vector::pop_back(&mut multi_client),
                vector::pop_back(&mut multi_latest_file_root),
                vector::pop_back(&mut multi_latest_sequence_no),
                vector::pop_back(&mut multi_agg_total_bytes),
                vector::pop_back(&mut multi_latest_file_segmnet_num),
                vector::pop_back(&mut multi_client_sig),
                vector::pop_back(&mut multi_commitment),
            )
        }
    }

    /// Provider upload a single commitment.
    public entry fun upload_single_cilent_daily_file_package(
        provider: &signer,
        client: address,
        latest_file_root: vector<u8>,
        latest_sequence_no: u64,
        agg_total_bytes: u64,
        latest_file_segmnet_num: u64,
        client_sig: vector<u8>,
        commitment: vector<u8>,
    ) acquires Ledger {
        let provider = address_of(provider);

        assert!(is_provider_service_valide(provider), E_PROVIDER_INVALID);

        let signed_info = FileSignedInfo {
            provider,
            file_root: latest_file_root,
            sequence_no: latest_sequence_no,
            agg_total_bytes,
            segment_num: latest_file_segmnet_num,
        };

        check_ed25519_signature(client, client_sig, signed_info);

        // At least one day fee needed.
        let increased_bytes = update_client_account(provider, client, agg_total_bytes, 1, commitment);

        let latest_commit = get_latest_commit_info_if_exist(provider, client);
        let file_num = if (option::is_some(&latest_commit)) {
            latest_sequence_no - option::borrow(&latest_commit).sequence_no
        } else { latest_sequence_no + 1 };

        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);

        let package = PackageCommit {
            signed_info,
            total_bytes: increased_bytes,
            sequence_no_start: latest_sequence_no + 1 - file_num,
            commited_file_num: file_num,
            current_file_num: file_num,
            deleted_tag: bit_vector::new(file_num),
            latest_challage_time: 0,
            upload_second: now_seconds(),
            fee_config: *smart_table::borrow(&ledger.pro_fee_configs, provider),
            paid_at: now_seconds(),
        };

        let client_packages = get_and_init_not_exist_packages_container(&mut ledger.packages, provider, client);
        smart_table::add(client_packages, commitment, package);
    }

    /// Check signature of data.
    fun check_ed25519_signature<T: drop + copy>(client: address, client_sig: vector<u8>, data: T) acquires Ledger {
        let pub_key = *smart_table::borrow(&borrow_global<Ledger>(ADMIN_ADDR).pub_keys, client);
        // verify client signature.
        ed25519::signature_verify_strict(
            &ed25519::new_signature_from_bytes(client_sig),
            &ed25519::new_unvalidated_public_key_from_bytes(pub_key),
            bcs::to_bytes(&data)
        );
    }

    fun get_latest_commit_info_if_exist(
        provider: address,
        client: address,
    ): Option<FileSignedInfo> acquires Ledger {
        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        let latest_commitment = smart_table::borrow(
            &ledger.cli_accounts,
            client
        ).latest_commitment;

        let packages_store = get_and_init_not_exist_packages_container(
            &mut ledger.packages,
            provider,
            client
        );

        if (smart_table::contains(packages_store, latest_commitment)) {
            option::some(smart_table::borrow(packages_store, latest_commitment).signed_info)
        } else { option::none() }
    }

    /// Check client if have sufficient balance to store files and freeze needed fee.
    fun update_client_account(
        provider: address,
        client: address,
        agg_total_bytes: u64,
        store_days: u64,
        commitment: vector<u8>
    ): u64 acquires Ledger {
        let latest_commit = get_latest_commit_info_if_exist(provider, client);
        let increased_bytes = if (option::is_some(&latest_commit)) {
            agg_total_bytes - option::borrow(&latest_commit).agg_total_bytes
        } else { agg_total_bytes };

        let fee_cfg = smart_table::borrow(&borrow_global<Ledger>(ADMIN_ADDR).pro_fee_configs, provider);
        let fee = ((increased_bytes * store_days) as u128) * fee_cfg.fee_per_day;
        // Increase current still in storing bytes.
        inc_client_total_store_bytes(provider, client, agg_total_bytes);
        freeze_client_fee(client, fee);

        smart_table::borrow_mut(
            &mut borrow_global_mut<Ledger>(ADMIN_ADDR).cli_accounts,
            client
        ).latest_commitment = commitment;

        increased_bytes
    }

    fun freeze_client_fee(client: address, fee: u128) acquires Ledger {
        let client_account = smart_table::borrow_mut(
            &mut borrow_global_mut<Ledger>(ADMIN_ADDR).cli_accounts,
            client
        );
        let free_balance = res_balance_eds(client) - client_account.freezed;
        // Freeze the necessary amount
        assert!(fee <= free_balance, E_INSUFFICIENT_BALANCE);
        client_account.freezed = client_account.freezed + fee;
    }


    /// Generate a challenge of the `commitment`.
    entry fun generate_challages(
        challenger: &signer,
        provider: address,
        client: address,
        commitment: vector<u8>,
    ) acquires Ledger, ChallengeStore {
        assert!(is_provider_service_valide(provider), E_PROVIDER_INVALID);

        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        let packages = get_and_init_not_exist_packages_container(&mut ledger.packages, provider, client);
        assert!(smart_table::contains(packages, commitment), E_INVALID_PACKAGE_FILE_INFO);
        assert!(smart_table::borrow(&ledger.cli_accounts, client).state == ACCOUNT_STATE_VALID, E_ILLEGAL_ACTION);

        let package = smart_table::borrow(packages, commitment);
        // All file has been deleted.
        assert!(package.current_file_num > 0, E_NO_FILE_EXIST);


        let exist_challenges = get_and_init_not_exist_package_challenge_container(
            &mut borrow_global_mut<ChallengeStore>(ADMIN_ADDR).challenges,
            provider,
            client,
            commitment
        );

        // Calculate and check total challenge per day.
        if (address_of(challenger) == client) {
            let daily_challenge_num = 0;
            smart_table::for_each_ref(exist_challenges, |_k, c| {
                let c: &Challenge = c;
                // One day challenge
                if (c.challenger == c.client && ((now_seconds() - c.start_sec) <= DAY_SECONDS)) {
                    daily_challenge_num = daily_challenge_num + 1;
                }
            });

            assert!(daily_challenge_num < package.current_file_num, E_TOO_MANY_CHALLLENGE_ONE_DAY);
        } else {
            let daily_challenge_num = 0;
            smart_table::for_each_ref(exist_challenges, |_k, c| {
                let c: &Challenge = c;
                // One day
                if (c.challenger != c.client && ((now_seconds() - c.start_sec) <= DAY_SECONDS)) {
                    daily_challenge_num = daily_challenge_num + 1;
                }
            });

            // Total challenge per day: 10challenge /GB/day + log2(file_num) * 2challenge
            let max_challenge_daily = 10 * (package.total_bytes >> 30) + 2 * fixed_point32::ceil(
                math64::log2(package.current_file_num)
            );

            assert!(daily_challenge_num < max_challenge_daily, E_TOO_MANY_CHALLLENGE_ONE_DAY);
        };

        let file_pos_r = randomness::u64_integer();
        let deleted_tag = package.deleted_tag;

        // If file is deleted, find next file to challenge.
        while (bit_vector::is_index_set(&deleted_tag, file_pos_r % package.commited_file_num)) {
            file_pos_r = file_pos_r + 1;
        };


        let c = Challenge {
            id: randomness::bytes(32),
            challenger: address_of(challenger),
            provider,
            client,
            commitment,
            file_pos: file_pos_r % package.commited_file_num,
            segment_r: randomness::u64_integer(),
            start_sec: now_seconds(),
        };

        add_challenge(provider, client, commitment, c);
    }

    fun add_challenge(
        provider: address,
        client: address,
        commitment: vector<u8>,
        c: Challenge
    ) acquires ChallengeStore {
        let package_challenges = get_and_init_not_exist_package_challenge_container(
            &mut borrow_global_mut<ChallengeStore>(ADMIN_ADDR).challenges,
            provider,
            client,
            commitment
        );

        smart_table::add(package_challenges, c.id, c);
    }

    #[view]
    public fun get_challages_by_commitment(
        provider: address,
        client: address,
        commitment: vector<u8>,
    ): vector<Challenge> acquires ChallengeStore {
        let challenges = get_and_init_not_exist_package_challenge_container(
            &mut borrow_global_mut<ChallengeStore>(ADMIN_ADDR).challenges,
            provider,
            client,
            commitment
        );

        simple_map::values(&smart_table::to_simple_map(challenges))
    }

    /// Provider prove a challenge.
    public entry fun prove_challenge(
        provider: address,
        client: address,
        commitment: vector<u8>,
        challeng_id: vector<u8>,
        fk20_proof: vector<u8>,
        fk20_y_prove_out: vector<vector<u8>>,
        file_root: vector<u8>,
        file_sequence_no: u64,
        file_agg_size: u64,
        file_segment_num: u64,
        file_info_signature: vector<u8>,
        segment_data: vector<u8>,
        path_hashes: vector<vector<u8>>,
    ) acquires ChallengeStore, Ledger, SigCapStore {
        assert!(vector::length(&file_info_signature) == FILE_SIGNATURE_U8_SIZE, E_INVALID_FILE_SIGNATURE);

        let file_signed_data = FileSignedInfo {
            provider,
            file_root,
            sequence_no: file_sequence_no,
            agg_total_bytes: file_agg_size,
            segment_num: file_segment_num
        };

        check_ed25519_signature(client, file_info_signature, file_signed_data);
        let challenge = remove_challege(provider, client, commitment, challeng_id);

        let fk20_pass = verify_fk20_proof(provider, client, commitment, fk20_proof, fk20_y_prove_out, &challenge);

        if (fk20_pass) {
            let calc_root = merkel_prove::calculate_merkel_root_by_offset_from_leaf(
                path_hashes,
                challenge.segment_r % file_segment_num,
                segment_data
            );

            if (calc_root == file_root) {
                event::emit(CompletedChallenge { is_success: true, challenge, timesecond: now_seconds() });
                // Challenge passed.
                return
            }
        };

        // Challenge failed;
        deal_failed_challenge(challenge);
        event::emit(CompletedChallenge { is_success: false, challenge, timesecond: now_seconds() });
    }

    fun deal_failed_challenge(c: Challenge) acquires Ledger, SigCapStore {
        let packages = &mut borrow_global_mut<Ledger>(ADMIN_ADDR).packages;
        let client_packages = get_and_init_not_exist_packages_container(packages, c.provider, c.client);
        let deleted_tag = &mut smart_table::borrow_mut(client_packages, c.commitment).deleted_tag;

        // Set challenge failed file deleted.
        bit_vector::set(deleted_tag, c.file_pos);
        slash_for_failed_challenge(c);
    }

    fun generate_challege_for_valid_files(
        challenger: address,
        provider: address,
        client: address,
        commitment: vector<u8>,
    ) acquires Ledger, ChallengeStore {
        let packages = &mut borrow_global_mut<Ledger>(ADMIN_ADDR).packages;
        let client_packages = get_and_init_not_exist_packages_container(packages, provider, client);
        let deleted_tag = &smart_table::borrow(client_packages, commitment).deleted_tag;

        for (file_pos in 0..bit_vector::length(deleted_tag)) {
            if (bit_vector::is_index_set(deleted_tag, file_pos)) {
                let c = Challenge {
                    challenger,
                    id: randomness::bytes(32),
                    provider,
                    client,
                    commitment,
                    file_pos,
                    segment_r: randomness::u64_integer(),
                    start_sec: now_seconds(),
                };

                add_challenge(provider, client, commitment, c);
            }
        }
    }

    fun verify_fk20_proof(
        provider: address,
        client: address,
        commitment: vector<u8>,
        fk20_proof: vector<u8>,
        fk20_y_prove_out: vector<vector<u8>>,
        challenge: &Challenge,
    ): bool acquires Ledger {
        let packages = &mut borrow_global_mut<Ledger>(ADMIN_ADDR).packages;
        let client_packages = get_and_init_not_exist_packages_container(packages, provider, client);
        let package = smart_table::borrow(client_packages, commitment);

        let file_pos = challenge.file_pos;
        poly_commit_fk20::verify_proof_native(
            fk20_proof,
            commitment,
            vector[file_pos * 4 + 0, file_pos * 4 + 1, file_pos * 4 + 2, file_pos * 4 + 3, ],
            fk20_y_prove_out,
            package.commited_file_num * 4,
        )
    }

    fun remove_challege(
        provider: address,
        client: address,
        package_comitment: vector<u8>,
        challenge_id: vector<u8>,
    ): Challenge acquires ChallengeStore {
        let package_challenges = get_and_init_not_exist_package_challenge_container(
            &mut borrow_global_mut<ChallengeStore>(ADMIN_ADDR).challenges,
            provider,
            client,
            package_comitment
        );

        let challenge = smart_table::remove(package_challenges, challenge_id);
        assert!(now_seconds() - challenge.start_sec <= MAX_CHALLENGE_PROVE_SECONDS, E_ILLEGAL_ACTION);

        challenge
    }

    fun check_unproved_timeout_challenges(provider: address) acquires ChallengeStore {
        let pro_challenges = smart_table::borrow(&borrow_global<ChallengeStore>(ADMIN_ADDR).challenges, provider);
        let clients = vector::empty();
        smart_table::for_each_ref(pro_challenges, |client, _cli_challenges| {
            vector::push_back(&mut clients, *client);
        });

        vector::for_each(clients, |client| {
            let c = get_client_unproved_timeout_challenges(provider, client);
            assert!(vector::length(&c) == 0, E_ILLEGAL_ACTION);
        });
    }

    fun get_client_unproved_timeout_challenges(
        provider: address,
        client: address
    ): vector<Challenge> acquires ChallengeStore {
        let timeout_challenges = vector[];
        let pro_challenges = smart_table::borrow(&borrow_global<ChallengeStore>(ADMIN_ADDR).challenges, provider);

        if (smart_table::contains(pro_challenges, client)) {
            smart_table::for_each_ref(smart_table::borrow(pro_challenges, client), |_commitment, challenges| {
                smart_table::for_each_ref(challenges, |_id, c| {
                    let c: &Challenge = c;
                    if (now_seconds() - c.start_sec > MAX_CHALLENGE_PROVE_SECONDS) {
                        vector::push_back(&mut timeout_challenges, *c);
                    }
                })
            });
        };

        timeout_challenges
    }

    fun is_exist_uproved_challenge(provider: address, ): bool acquires ChallengeStore {
        let pro_challenges = smart_table::borrow(&borrow_global<ChallengeStore>(ADMIN_ADDR).challenges, provider);
        smart_table::any(pro_challenges, |_cli, cli_challenges| {
            smart_table::any(cli_challenges, |_commitment, commitmnet_c| {
                smart_table::length(commitmnet_c) > 0
            })
        })
    }


    /// Provider prove a challenge whose file has been deleted by client.
    public entry fun prove_deleted_file_challenge(
        provider: &signer,
        client: address,
        commitment: vector<u8>,
        challeng_id: vector<u8>,
        fk20_proof: vector<u8>,
        fk20_y_prove_out: vector<vector<u8>>,
        file_root: vector<u8>,
        file_sequence_no: u64,
        file_agg_size: u64,
        file_segment_num: u64,
        file_info_signature: vector<u8>,
        deleted_file_sequence_nos: vector<u64>,
        deleted_total_bytes: u64,
        delete_sec: u64,
        deleted_info_sig: vector<u8>,
    ) acquires ChallengeStore, Ledger, SigCapStore {
        let provider_addr = address_of(provider);
        let file_signed_data = FileSignedInfo {
            provider: provider_addr,
            file_root,
            sequence_no: file_sequence_no,
            agg_total_bytes: file_agg_size,
            segment_num: file_segment_num
        };

        check_ed25519_signature(client, file_info_signature, file_signed_data);

        let challenge = remove_challege(provider_addr, client, commitment, challeng_id);

        if (verify_fk20_proof(provider_addr, client, commitment, fk20_proof, fk20_y_prove_out, &challenge)) {
            upload_package_deleteded_file_info(
                provider,
                client,
                commitment,
                deleted_file_sequence_nos,
                deleted_total_bytes,
                delete_sec,
                deleted_info_sig
            );

            event::emit(CompletedChallenge { is_success: true, challenge, timesecond: now_seconds() });
        } else {
            update_failed_challenge_record(provider_addr);
            slash_for_not_updata_deleted_file_info(challenge.provider, challenge.client, challenge.challenger);
            event::emit(CompletedChallenge { is_success: false, challenge, timesecond: now_seconds() });
        }
    }

    fun update_failed_challenge_record(provider: address) acquires ChallengeStore {
        let prove_records = &mut borrow_global_mut<ChallengeStore>(ADMIN_ADDR).prove_records;

        smart_table::borrow_mut(prove_records, provider).latest_failed_sec = now_seconds();
    }

    fun calc_client_fee_pass_7days(provider: address, client: address): u128 acquires Ledger {
        let pro_account = smart_table::borrow_mut(&mut borrow_global_mut<Ledger>(ADMIN_ADDR).pro_accounts, provider);
        let client_fee_pass_7_days = 0;
        vector::for_each_ref(&pro_account.fee_collect_list, |e| {
            let e: &FeeCollectedInfo = e;
            if (e.client == client && (now_seconds() - e.collected_at) < MIN_COLLECTED_FEE_FREEZED_SECONDS) {
                client_fee_pass_7_days = client_fee_pass_7_days + e.amount;
            }
        });

        client_fee_pass_7_days
    }

    fun slash_for_failed_challenge(c: Challenge) acquires Ledger, SigCapStore {
        let client_fee_pass_7_days = calc_client_fee_pass_7days(c.provider, c.client);
        assert!(transfer_res_eds(c.provider, c.client, client_fee_pass_7_days + EDS_ONE_COIN) > 0, E_ILLEGAL_ACTION);
        endless_coin::transfer(
            &get_resource_account_singer(c.provider),
            c.challenger,
            client_fee_pass_7_days * 2 + EDS_ONE_COIN
        );
    }

    fun slash_for_not_updata_deleted_file_info(
        provider: address,
        client: address,
        challenger: address
    ) acquires Ledger, SigCapStore {
        let client_fee_pass_7_days = calc_client_fee_pass_7days(provider, client);
        assert!(
            transfer_res_eds(provider, client, client_fee_pass_7_days * 5 + EDS_ONE_COIN * 2) > 0,
            E_ILLEGAL_ACTION
        );

        endless_coin::transfer(
            &get_resource_account_singer(provider),
            challenger,
            client_fee_pass_7_days * 5 + EDS_ONE_COIN * 2
        );
    }


    /// Provider set all the challenges of `client` to failed. And the provider will be slashed.
    public entry fun set_client_all_timeout_challenge_failed(
        provider: &signer,
        client: address
    ) acquires ChallengeStore, Ledger, SigCapStore {
        let provider = address_of(provider);
        let timeout_challenges = get_client_unproved_timeout_challenges(provider, client);

        if (vector::length(&timeout_challenges) == 0) {
            return
        };

        let pro_challenges = smart_table::borrow_mut(
            &mut borrow_global_mut<ChallengeStore>(ADMIN_ADDR).challenges,
            provider
        );

        let cli_challenges = smart_table::borrow_mut(pro_challenges, client);
        vector::for_each(timeout_challenges, |c| {
            let c: Challenge = c;
            let commitment_challenges = smart_table::borrow_mut(cli_challenges, c.commitment);
            smart_table::remove(commitment_challenges, c.id);

            slash_for_failed_challenge(c);
        });

        update_failed_challenge_record(provider);
    }

    /// Provider uploads deletef files signed by provider and client.
    /// `deleted_file_sequence_nos` contains all the sequence numbers of deleted file in `commitment`.
    /// `total_size` is the total bytes of the deleted files which are deleted at timestamp - `delete_sec`.
    public entry fun upload_package_deleteded_file_info(
        provider: &signer,
        client: address,
        commitment: vector<u8>,
        deleted_file_sequence_nos: vector<u64>,
        deleted_total_bytes: u64,
        deleted_sec: u64,
        client_sig: vector<u8>,
    ) acquires Ledger {
        let provider = address_of(provider);

        let de = DeletedFileInfo { provider, client, commitment, deleted_file_sequence_nos, total_size: deleted_total_bytes, delete_sec: deleted_sec, };
        check_ed25519_signature(client, client_sig, de);
        check_deleted_file_info(&de);

        let packages = &mut borrow_global_mut<Ledger>(ADMIN_ADDR).packages;
        let client_packages = get_and_init_not_exist_packages_container(packages, provider, client);
        let package = smart_table::borrow_mut(client_packages, commitment);

        // Update deleted files info of package commitment.
        package.total_bytes = package.total_bytes - deleted_total_bytes;
        package.current_file_num = package.current_file_num - vector::length(&deleted_file_sequence_nos);

        let new_deleted_file_num = 0;
        vector::for_each(deleted_file_sequence_nos, |sequence_no| {
            let file_pos = sequence_no - package.sequence_no_start;
            if (!bit_vector::is_index_set(&package.deleted_tag, file_pos)) {
                bit_vector::set(&mut package.deleted_tag, file_pos);
                new_deleted_file_num = new_deleted_file_num + 1;
            }
        });

        if (new_deleted_file_num > 0) {
            dec_client_total_store_bytes(provider, client, deleted_total_bytes);
        }
    }


    fun dec_client_total_store_bytes(provider: address, client: address, total_bytes: u64) acquires Ledger {
        let client_account = smart_table::borrow_mut(
            &mut borrow_global_mut<Ledger>(ADMIN_ADDR).cli_accounts,
            client
        );

        let current_total_bytes = smart_table::borrow_mut(&mut client_account.current_total_bytes, provider);
        *current_total_bytes = *current_total_bytes - total_bytes;
    }

    fun inc_client_total_store_bytes(provider: address, client: address, total_bytes: u64) acquires Ledger {
        let current_total_bytes = &mut smart_table::borrow_mut(
            &mut borrow_global_mut<Ledger>(ADMIN_ADDR).cli_accounts,
            client
        ).current_total_bytes;

        if (!smart_table::contains(current_total_bytes, provider)) {
            smart_table::add(current_total_bytes, provider, 0);
        };

        let current_total_bytes = smart_table::borrow_mut(current_total_bytes, provider);
        *current_total_bytes = *current_total_bytes + total_bytes;
    }

    fun check_deleted_file_info(_deleted_file_info: &DeletedFileInfo) {}

    /// Justify the client's deletion which provider did not upload.
    /// `deleted_file_sequence_nos` contains all the sequence numbers of deleted file in `commitment`.
    /// `total_size` is the total bytes of the deleted files which are deleted at timestamp - `delete_sec`.
    public entry fun justify_deleted_files(
        challenger: &signer,
        provider: address,
        client: address,
        commitment: vector<u8>,
        deleted_file_sequence_nos: vector<u64>,
        total_size: u64,
        delete_sec: u64,
        client_sig: vector<u8>,
        provider_sig: vector<u8>,
    ) acquires Ledger, ChallengeStore, SigCapStore {
        let de = DeletedFileInfo { provider, client, commitment, deleted_file_sequence_nos, total_size, delete_sec, };
        check_ed25519_signature(client, client_sig, de);
        check_ed25519_signature(provider, provider_sig, de);

        let packages = &mut borrow_global_mut<Ledger>(ADMIN_ADDR).packages;
        let client_packages = get_and_init_not_exist_packages_container(packages, provider, client);
        let package = smart_table::borrow_mut(client_packages, commitment);

        let undeleted_sequence_nos = vector[];
        vector::for_each(deleted_file_sequence_nos, |sequence_no| {
            if (!bit_vector::is_index_set(&mut package.deleted_tag, sequence_no - package.sequence_no_start)) {
                // Provider not update client deleted file info
                if (now_seconds() - delete_sec > MAX_DELAY_UPDATE_CLENT_DELETED_FILLE_SECONDS) {
                    vector::push_back(&mut undeleted_sequence_nos, sequence_no);
                }
            }
        });

        if (vector::length(&undeleted_sequence_nos) > 0) {
            // Update deleted file tag
            vector::for_each(undeleted_sequence_nos, |no| bit_vector::set(&mut package.deleted_tag, no));

            update_failed_challenge_record(provider);
            slash_for_not_updata_deleted_file_info(provider, client, address_of(challenger));
        };
    }

    fun U128(a: u64): u128 {
        (a as u128)
    }

    /// Provider collect generated fee of `client` to it's resource account.
    public entry fun collect_fee(provider: &signer, client: address) acquires Ledger, SigCapStore {
        let provider = address_of(provider);
        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        let pro_account = smart_table::borrow_mut(&mut ledger.pro_accounts, provider);
        let cli_account = smart_table::borrow_mut(&mut ledger.cli_accounts, client);

        let client_packages = get_and_init_not_exist_packages_container(&mut ledger.packages, provider, client);

        smart_table::for_each_mut(client_packages, |_commitmnet, package| {
            let pkg: &mut PackageCommit = package;
            let need_paid_days = (now_seconds() - pkg.paid_at) / DAY_SECONDS;

            if (need_paid_days > 0) {
                pkg.paid_at = pkg.paid_at + need_paid_days * DAY_SECONDS;
                let amount = pkg.fee_config.fee_per_day * U128(pkg.total_bytes >> (pkg.fee_config.fee_unit)) * U128(need_paid_days);

                if (transfer_res_eds(client, provider, amount) == 0) {
                    // Clinet is not have enough balance to pay fee.
                    cli_account.state = ACCOUNT_STATE_NO_FEE;
                } else {
                    // Record fee collected time, it will be free after 7 days.
                    vector::push_back(
                        &mut pro_account.fee_collect_list,
                        FeeCollectedInfo { client, amount, collected_at: now_seconds() }
                    );

                    // Add to freezed fee.
                    pro_account.freezed = pro_account.freezed + amount;
                    // Set client freeze to 0 after have paid fee.
                    cli_account.freezed = 0;
                };
            }
        })
    }

    /// Transfer resource account eds.
    fun transfer_res_eds(from: address, to: address, amount: u128): u128 acquires SigCapStore {
        if (res_balance_eds(from) < amount) return 0;

        endless_coin::transfer(
            &get_resource_account_singer(from),
            get_resource_account_address(to),
            amount
        );

        amount
    }

    /// Provider stop to service.
    public entry fun stop_service_provider(provider: &signer) acquires Ledger {
        let provider_addr = address_of(provider);

        assert!(is_provider_service_valide(provider_addr), E_PROVIDER_INVALID);

        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);

        if (!smart_table::contains(&ledger.pro_accounts, provider_addr)) return;

        let account = smart_table::borrow_mut(&mut ledger.pro_accounts, provider_addr);
        account.state = ACCOUNT_STATE_STOPING;
        account.state_update_at = now_seconds();
    }

    fun is_provider_service_valide(provider: address): bool acquires Ledger {
        let ledger = borrow_global<Ledger>(ADMIN_ADDR);

        if (!smart_table::contains(&ledger.pro_accounts, provider)) return false;

        let account = smart_table::borrow(&ledger.pro_accounts, provider);
        account.state == ACCOUNT_STATE_VALID
    }

    /// Unregister a provider. Call 30 days after `stop_service_provider` being called.
    /// And there is no unprovided challenge.
    public entry fun unregister_provider(provider: &signer) acquires Ledger, ChallengeStore, SigCapStore {
        let provider_addr = address_of(provider);

        check_provider_unregister_state(provider_addr);

        withdraw_provider_internal(provider, provider_addr, 0, 0);

        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        smart_table::remove(&mut ledger.pro_accounts, provider_addr);
        smart_table::remove(&mut ledger.pro_fee_configs, provider_addr);
        smart_table::remove(&mut borrow_global_mut<ChallengeStore>(ADMIN_ADDR).prove_records, provider_addr);
    }

    fun check_provider_unregister_state(provider: address) acquires Ledger, ChallengeStore {
        let ledger = borrow_global<Ledger>(ADMIN_ADDR);

        if (!smart_table::contains(&ledger.pro_accounts, provider)) return;
        let pro_account = smart_table::borrow(&ledger.pro_accounts, provider);

        assert!(pro_account.state == ACCOUNT_STATE_STOPING, E_ILLEGAL_ACTION);
        assert!((now_seconds() - pro_account.state_update_at) > MIN_UNREGISTER_AFTER_STOPING_SECONDS, E_ILLEGAL_ACTION);
        assert!(!is_exist_uproved_challenge(provider), E_ILLEGAL_ACTION);
    }

    /// `pub_key`: ED25519 public key .
    /// `fee_unit`: 0 - by Byte; 10 - by KB; 20 - by MB; 30 - by GB; 
    /// `fee_per_day`: Price per day of one fee_unit.
    public entry fun register_provider(
        provider: &signer,
        pub_key: vector<u8>,
        fee_unit: u8,
        fee_per_day: u128
    ) acquires Ledger, ChallengeStore {
        let provider_addr = address_of(provider);
        add_pubkey(provider, pub_key);
        add_resource_account(provider);

        check_fee_config(fee_unit, fee_per_day);

        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);

        if (smart_table::contains(&ledger.pro_accounts, provider_addr)) return;

        smart_table::add(&mut ledger.pro_accounts, provider_addr, ProviderAccount {
            freezed: 0,
            fee_collect_list: vector::empty(),
            state: ACCOUNT_STATE_VALID,
            state_update_at: now_seconds(),
        });

        let fee_cfg = &mut ledger.pro_fee_configs;
        smart_table::add(fee_cfg, provider_addr, FeeConfig {
            fee_unit,
            fee_per_day,
            update_at: now_seconds(),
        });

        smart_table::add(
            &mut borrow_global_mut<ChallengeStore>(ADMIN_ADDR).prove_records,
            provider_addr,
            ProveRecord { latest_failed_sec: 0 }
        );

        // Provider need stake min PROVIDER_MIN_EDS coins.
        endless_coin::transfer(provider, get_resource_account_address(provider_addr), PROVIDER_MIN_STACKING_AMOUNT);
    }

    /// Provides update fee configuration, which min interval is 30 days.
    /// `fee_unit`: 0 - by Byte; 10 - by KB; 20 - by MB; 30 - by GB; 
    /// `fee_per_day`: Price per day of one fee_unit.
    public entry fun update_fee_config(
        provider: &signer,
        fee_unit: u8,
        fee_per_day: u128
    ) acquires Ledger {
        let provider_addr = address_of(provider);
        assert!(is_provider_service_valide(provider_addr), E_PROVIDER_INVALID);

        let fee_configs = &mut borrow_global_mut<Ledger>(ADMIN_ADDR).pro_fee_configs;
        assert!(smart_table::contains(fee_configs, provider_addr), E_PROVIDER_INVALID);


        check_fee_config(fee_unit, fee_per_day);

        let config = smart_table::borrow_mut(fee_configs, provider_addr);
        assert!(
            now_seconds() - config.update_at > MIN_INTERVAL_SECONDS_UPDATE_FEE_CONFIG,
            E_NO_ENOUGH_INTERVAL
        );

        config.fee_unit = fee_unit;
        config.fee_per_day = fee_per_day;
        config.update_at = now_seconds();
    }

    fun check_fee_config(fee_unit: u8, fee_per_day: u128) {
        let fee_units = vector[FEE_UNIT_BYTE, FEE_UNIT_KB, FEE_UNIT_MB, FEE_UNIT_GB];
        assert!(vector::contains(&fee_units, &fee_unit), E_INVALID_VALUE);
        assert!(fee_per_day > 0, E_INVALID_VALUE);
    }

    /// Client register function. `pub_key` is the public key of the client.
    public entry fun register_client(client: &signer, pub_key: vector<u8>) acquires Ledger {
        add_pubkey(client, pub_key);
        add_resource_account(client);

        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        let clients = &mut ledger.cli_accounts;

        if (smart_table::contains(clients, address_of(client))) return;

        smart_table::add(clients, address_of(client), ClientAccount {
            current_total_bytes: smart_table::new(),
            latest_commitment: vector::empty(),
            freezed: 0,
            state: ACCOUNT_STATE_VALID,
        });
    }

    public entry fun remove_no_fee_client(provider: &signer, client: address) acquires Ledger, ChallengeStore {
        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        let clients = &mut ledger.cli_accounts;
        let provider = address_of(provider);

        assert!(smart_table::borrow(clients, client).state == ACCOUNT_STATE_NO_FEE, E_ILLEGAL_ACTION);
        let challenges = borrow_global_mut<ChallengeStore>(ADMIN_ADDR);

        // Remove client's challenges.
        let challenges = smart_table::remove(smart_table::borrow_mut(&mut challenges.challenges, provider), client);
        let commitment_keys = vector[];
        smart_table::for_each_ref(&challenges, |commitment_key, _v| {
            vector::push_back(&mut commitment_keys, *commitment_key);
        });

        vector::for_each(commitment_keys, | key| {
            let challenges = smart_table::remove(&mut challenges, key);
            smart_table::destroy(challenges);
        });

        smart_table::destroy_empty(challenges);


        // Remove client's files commitments.
        let commitments = smart_table::remove(smart_table::borrow_mut(&mut ledger.packages, provider), client);
        smart_table::destroy(commitments);
    }

    fun add_pubkey(sender: &signer, pub_key: vector<u8>) acquires Ledger {
        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        let sender_addr = address_of(sender);
        let pub_keys = &mut ledger.pub_keys;

        if (smart_table::contains(pub_keys, sender_addr))
            return;

        // Add pub_key
        smart_table::add(pub_keys, sender_addr, pub_key);
    }

    fun add_resource_account(sender: &signer) {
        let (resource_signer, signer_cap) = account::create_resource_account(sender, seed(&address_of(sender)));
        if (exists<SigCapStore>(address_of(&resource_signer))) return;

        // Store singer capbility, this capbility is required when cliam coins.
        let cap_store = SigCapStore { signer_cap };
        move_to(&resource_signer, cap_store);
    }

    #[view]
    public fun get_admin_resource_address(): address {
        account::create_resource_address(&ADMIN_ADDR, seed(&ADMIN_ADDR))
    }

    /// Resource account eds balance.
    fun res_balance_eds(addr: address): u128 {
        let resource_addr = get_resource_account_address(addr);
        endless_coin::balance(resource_addr)
    }

    fun get_resource_account_singer(addr: address): signer acquires SigCapStore {
        let seed = seed(&addr);
        let resource_address = account::create_resource_address(&addr, seed);
        let cap = borrow_global<SigCapStore>(resource_address);
        account::create_signer_with_capability(&cap.signer_cap)
    }

    fun get_resource_account_address(addr: address): address {
        account::create_resource_address(&addr, seed(&addr))
    }

    fun seed(client_addr: &address): vector<u8> {
        let seed = bcs::to_bytes(client_addr);
        vector::append(&mut seed, CONTRACT_NAME);
        seed
    }

    /// Charge `amount` of EDS to the `sender` resource account.
    public entry fun charge_eds(sender: &signer, amount: u128) {
        endless_coin::transfer(sender, get_resource_account_address(address_of(sender)), amount);
    }

    /// Withdraw `amount` from the `sender` resource address to the `recepient`.
    public entry fun withdraw_client(sender: &signer, recipient: address, amount: u128) acquires SigCapStore, Ledger {
        let sender = address_of(sender);
        let freezed = smart_table::borrow(&borrow_global<Ledger>(ADMIN_ADDR).cli_accounts, sender).freezed;
        assert!(res_balance_eds(sender) - freezed >= amount, E_INVALID_VALUE);

        endless_coin::transfer(&get_resource_account_singer(sender), recipient, amount);
    }

    /// `recipient` is the address to receive coins withdraw from the provider's resource account.
    public entry fun withdraw_provider(
        provider: &signer,
        recipient: address,
        amount: u128
    ) acquires Ledger, SigCapStore, ChallengeStore {
        withdraw_provider_internal(provider, recipient, PROVIDER_MIN_STACKING_AMOUNT, amount);
    }

    fun withdraw_provider_internal(
        provider: &signer,
        recipient: address,
        min_staking: u128,
        amount: u128
    ) acquires Ledger, SigCapStore, ChallengeStore {
        let provider = address_of(provider);

        // Can't withdraw if exist unproved timeout challenges.
        check_unproved_timeout_challenges(provider);

        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        let pro_account = smart_table::borrow_mut(&mut ledger.pro_accounts, provider);

        let free_poses = vector[];
        let pos = 0;
        vector::for_each_ref(&pro_account.fee_collect_list, |e| {
            let e: &FeeCollectedInfo = e;
            if (now_seconds() - e.collected_at > MIN_COLLECTED_FEE_FREEZED_SECONDS) {
                vector::push_back(&mut free_poses, pos);
            };

            pos = pos + 1;
        });

        let free_fee = 0;
        vector::for_each_reverse(free_poses, |index| {
            let fee_collected_info = vector::remove(&mut pro_account.fee_collect_list, index);
            free_fee = free_fee + fee_collected_info.amount;
        });

        pro_account.freezed = pro_account.freezed - free_fee;

        let provider_balance = res_balance_eds(provider);
        assert!(provider_balance - min_staking - pro_account.freezed >= amount, E_INVALID_VALUE);

        if (amount == 0) amount = provider_balance - min_staking - pro_account.freezed;
        endless_coin::transfer(&get_resource_account_singer(provider), recipient, amount);
    }


    #[test_only]
    fun setup(admin: &signer, provider: &signer, client: &signer) {
        let endless_framework = account::create_account_for_test(@endless_framework);
        endless_coin::initialize_for_test(&endless_framework);
        endless_coin::mint(&endless_framework, address_of(client), 1_00000000_00000000);
        endless_coin::mint(&endless_framework, address_of(provider), PROVIDER_MIN_STACKING_AMOUNT + 1000_00000000);
        randomness::initialize_for_testing(&endless_framework);

        set_time_has_started_for_testing(&endless_framework);
        reconfiguration::initialize_for_test(&endless_framework);

        init_module(admin);

        //create_account_unchecked_for_test(address_of(client));
        //create_account_unchecked_for_test(address_of(provider));
    }


    #[test_only]
    fun generate_client_pk_to_auth(): (SecretKey, ValidatedPublicKey, SecretKey, ValidatedPublicKey) {
        let sk: u256 = 36261212957551179396165419414635311226911550424579774186606937730784173977960;
        let pk: u256 = 24923431739597357674979651902213389217039665909479772625856512009071954636506;

        let (client_sk, client_pk) = ed25519::generate_known_keys(
            bcs::to_bytes(&sk),
            bcs::to_bytes(&pk),
        );

        let (provider_sk, provider_pk) = ed25519::generate_keys();

        (client_sk, client_pk, provider_sk, provider_pk)
    }

    fun calc_merkel_tree(datas: &vector<vector<u8>>): (vector<u8>, vector<vector<u8>>) {
        let len = vector::length(datas);
        assert!(len == math64::pow(2, fixed_point32::floor(math64::log2(len))), E_TEST_FAILED);
        let merkel_root ;

        // Leaf hash.
        let temp_datas = vector::map_ref(datas, |e| { sha3_256(*e) });
        let temp_roots = vector::empty<vector<u8>>();

        // All tree leaf hash + node_hash.
        let tree = temp_datas;


        loop {
            let data_size = vector::length(&temp_datas);

            for (i in 0.. (data_size / 2)) {
                let hash_data = vector::empty<u8>();
                vector::append(&mut hash_data, *vector::borrow(&temp_datas, i * 2));
                vector::append(&mut hash_data, *vector::borrow(&temp_datas, i * 2 + 1));
                let hash = sha3_256(hash_data);
                vector::push_back(&mut temp_roots, hash);
                vector::push_back(&mut tree, hash);
            };


            // Done
            if (vector::length(&temp_roots) == 1) {
                merkel_root = vector::pop_back(&mut temp_roots);
                break
            };

            // Tree level up.
            temp_datas = temp_roots;
            temp_roots = vector::empty<vector<u8>>();
        };

        (merkel_root, tree)
    }


    struct TestFileInfo has store, drop, copy {
        root: vector<u8>,
        // Total number segment in tree leafs of this file.
        segment_num: u64,

    }

    #[test(admin = @file_storage, provider = @provider, client = @client)]
    fun test_e2e_storage_upload_2_challenge(
        admin: &signer,
        provider: &signer,
        client: &signer
    ) acquires Ledger, ChallengeStore, SigCapStore {
        setup(admin, provider, client);

        // Generate provider/client key pair.
        let (cli_sk, cli_pk, _pro_sk, pro_pk) = generate_client_pk_to_auth();

        register_provider(provider, validated_public_key_to_bytes(&pro_pk), FEE_UNIT_MB, 2);

        register_client(client, validated_public_key_to_bytes(&cli_pk));
        charge_eds(client, 100_00000000);

        // Test file all merkel node hash store for challenge.
        let file_data_raw_list = vector::empty<vector<vector<u8>>>();
        let merkel_roots = vector::empty<vector<u8>>();
        let merkel_file_trees = vector::empty<vector<vector<u8>>>();
        let file_signed_infos = vector::empty<FileSignedInfo>();

        // Generate test file data pow of 2.
        let file_num = 8;

        let daily_file_info = vector::empty<TestFileInfo>();

        let total_bytes = 0;
        let file_sig_128 = vector::empty<vector<u8>>();
        for (i in 0..file_num) {
            let file_data_raw = vector::empty<vector<u8>>();

            let segment_size = randomness::u64_range(8, 16);
            let file_segment = math64::pow(2, randomness::u64_integer() % 10 + 1);
            for (_i in 0..file_segment) {
                vector::push_back(&mut file_data_raw, randomness::bytes(segment_size));
            };

            total_bytes = total_bytes + segment_size * file_segment;
            vector::push_back(&mut file_data_raw_list, file_data_raw);

            // Calculate merkel nodes.
            let (root, tree) = calc_merkel_tree(&file_data_raw);
            //print(&tree);

            vector::push_back(&mut merkel_roots, root);
            vector::push_back(&mut merkel_file_trees, tree);

            vector::push_back(&mut daily_file_info, TestFileInfo {
                root,
                segment_num: file_segment,
            });

            let commit_info = FileSignedInfo {
                provider: address_of(provider),
                file_root: root,
                sequence_no: i,
                agg_total_bytes: total_bytes,
                segment_num: file_segment,
            };

            vector::push_back(&mut file_signed_infos, commit_info);

            let signature = signature_to_bytes(&sign_arbitrary_bytes(&cli_sk, bcs::to_bytes(&commit_info)));

            for (i in 0.. (FILE_SIGNATURE_U8_SIZE / COMMIT_DATA_U8_SIZE)) {
                vector::push_back(
                    &mut file_sig_128,
                    vector::slice(&signature, COMMIT_DATA_U8_SIZE * i, COMMIT_DATA_U8_SIZE * (i + 1))
                );
            };
        };

        // Generate commitment
        let commitment = poly_commit_fk20::generate_commitment_native_test(file_sig_128);

        // Upload data info on chain.
        let latest_commit_info = *vector::borrow(&file_signed_infos, file_num - 1);

        upload_single_cilent_daily_file_package(
            provider,
            address_of(client),
            latest_commit_info.file_root,
            latest_commit_info.sequence_no,
            latest_commit_info.agg_total_bytes,
            latest_commit_info.segment_num,
            signature_to_bytes(&sign_arbitrary_bytes(&cli_sk, bcs::to_bytes(&latest_commit_info))),
            commitment
        );

        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        let client_account = smart_table::borrow_mut(
            &mut ledger.cli_accounts,
            address_of(client)
        );

        // Check fee.
        let fee_cfg = smart_table::borrow(&ledger.pro_fee_configs, address_of(provider));
        let fee = U128(total_bytes) * 1 * fee_cfg.fee_per_day;

        assert!(client_account.freezed == fee, E_TEST_FAILED);

        // Generate challenges.
        generate_challages(admin, address_of(provider), address_of(client), commitment);
        //generate_challages(address_of(provider), address_of(client), commitment, 1);

        // Get challenges to prove.
        let package_challenges = get_challages_by_commitment(address_of(provider), address_of(client), commitment);

        vector::for_each(package_challenges, |challenge| {
            let challenge: Challenge = challenge;

            let file_pos = challenge.file_pos;
            let file_raw_data = vector::borrow(&file_data_raw_list, file_pos);
            let file_segment_num = vector::length(file_raw_data);
            let challenge_segment = challenge.segment_r % file_segment_num;
            let file_merkel_tree = vector::borrow(&merkel_file_trees, file_pos);
            let segment = vector::borrow(file_raw_data, challenge.segment_r % file_segment_num);
            let (proof_path_hashes, _proof_path_tasgs) = generate_merkel_proof_path(
                file_merkel_tree,
                challenge_segment
            );

            print(&string::utf8(b"=============================================================================="));
            print(&string::utf8(b"====================================Challenge================================="));
            print(&string::utf8(b"=============================================================================="));

            print(&challenge);

            print(&string::utf8(b"--------------------------------- Merkel Proof -----------------------"));
            //print(file_merkel_tree);
            print(&proof_path_hashes);

            let (proof, y_prove_out) = poly_commit_fk20::generate_proof_native_test(
                challenge.commitment,
                file_sig_128,
                vector[file_pos * 4 + 0, file_pos * 4 + 1, file_pos * 4 + 2, file_pos * 4 + 3, ]
            );
            print(&string::utf8(b"-------------------------------Poly FK20 Proof -----------------------"));
            print(&proof);

            let signed_info = vector::borrow(&file_signed_infos, file_pos);

            let signature = vector::fold(vector[0, 1, 2, 3], vector::empty<u8>(), |sig, i|{
                vector::append(&mut sig, *vector::borrow(&file_sig_128, file_pos * 4 + i));
                sig
            });


            prove_challenge(
                challenge.provider,
                challenge.client,
                commitment,
                challenge.id,
                proof,
                vector::map(y_prove_out, |e| bcs::to_bytes(&e)),
                signed_info.file_root,
                signed_info.sequence_no,
                signed_info.agg_total_bytes,
                signed_info.segment_num,
                signature,
                *segment,
                proof_path_hashes,
            )
        });

        // All challenges are proved.
        assert!(
            vector::length(&get_challages_by_commitment(address_of(provider), address_of(client), commitment)) == 0,
            E_TEST_FAILED
        );

        timestamp::update_global_time_for_test_secs(DAY_SECONDS * 8);

        print(&string::utf8(b"-----------------------------Provider stoping service----------------------------"));
        stop_service_provider(provider);

        print(&string_utils::format1(&b"Provider balance is {}", endless_coin::balance(address_of(provider))));
        timestamp::update_global_time_for_test_secs(DAY_SECONDS * 50);
        unregister_provider(provider);
        print(&string_utils::format1(&b"Provider balance is {}, after unregister.", endless_coin::balance(address_of(provider))));
        print(&string_utils::format1(&b"Provider res balance is {}, after unregister.", res_balance_eds(address_of(provider))));


    }


    #[test(admin = @file_storage, provider = @provider, client = @client)]
    fun test_e2e_storage_delete_file(
        admin: &signer,
        provider: &signer,
        client: &signer
    ) acquires Ledger, ChallengeStore, SigCapStore {
        setup(admin, provider, client);

        // Generate provider/client key pair.
        let (cli_sk, cli_pk, _pro_sk, pro_pk) = generate_client_pk_to_auth();

        register_provider(provider, validated_public_key_to_bytes(&pro_pk), FEE_UNIT_KB, 2);

        register_client(client, validated_public_key_to_bytes(&cli_pk));
        charge_eds(client, 100_00000000);

        // Test file all merkel node hash store for challenge.
        let file_data_raw_list = vector::empty<vector<vector<u8>>>();
        let merkel_roots = vector::empty<vector<u8>>();
        let merkel_file_trees = vector::empty<vector<vector<u8>>>();
        let file_signed_infos = vector::empty<FileSignedInfo>();

        // Generate test file data pow of 2.
        let file_num = 8;

        let daily_file_info = vector::empty<TestFileInfo>();

        let total_bytes = 0;
        let file_sig_128 = vector::empty<vector<u8>>();
        for (i in 0..file_num) {
            let file_data_raw = vector::empty<vector<u8>>();

            let segment_size = randomness::u64_range(8, 16);
            let file_segment = math64::pow(2, randomness::u64_integer() % 10 + 1);
            for (_i in 0..file_segment) {
                vector::push_back(&mut file_data_raw, randomness::bytes(segment_size));
            };

            total_bytes = total_bytes + segment_size * file_segment;
            vector::push_back(&mut file_data_raw_list, file_data_raw);

            // Calculate merkel nodes.
            let (root, tree) = calc_merkel_tree(&file_data_raw);
            //print(&tree);

            vector::push_back(&mut merkel_roots, root);
            vector::push_back(&mut merkel_file_trees, tree);

            vector::push_back(&mut daily_file_info, TestFileInfo {
                root,
                segment_num: file_segment,
            });

            let commit_info = FileSignedInfo {
                provider: address_of(provider),
                file_root: root,
                sequence_no: i,
                agg_total_bytes: total_bytes,
                segment_num: file_segment,
            };

            vector::push_back(&mut file_signed_infos, commit_info);

            let signature = signature_to_bytes(&sign_arbitrary_bytes(&cli_sk, bcs::to_bytes(&commit_info)));

            for (i in 0.. (FILE_SIGNATURE_U8_SIZE / COMMIT_DATA_U8_SIZE)) {
                vector::push_back(
                    &mut file_sig_128,
                    vector::slice(&signature, COMMIT_DATA_U8_SIZE * i, COMMIT_DATA_U8_SIZE * (i + 1))
                );
            };
        };

        // Generate commitment
        let commitment = poly_commit_fk20::generate_commitment_native_test(file_sig_128);

        // Upload data info on chain.
        let latest_commit_info = *vector::borrow(&file_signed_infos, file_num - 1);

        upload_single_cilent_daily_file_package(
            provider,
            address_of(client),
            latest_commit_info.file_root,
            latest_commit_info.sequence_no,
            latest_commit_info.agg_total_bytes,
            latest_commit_info.segment_num,
            signature_to_bytes(&sign_arbitrary_bytes(&cli_sk, bcs::to_bytes(&latest_commit_info))),
            commitment
        );

        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        let client_account = smart_table::borrow_mut(
            &mut ledger.cli_accounts,
            address_of(client)
        );

        // Check fee.
        let fee_cfg = smart_table::borrow(&ledger.pro_fee_configs, address_of(provider));
        let fee = U128(total_bytes) * 1 * fee_cfg.fee_per_day;

        assert!(client_account.freezed == fee, E_TEST_FAILED);

        print(&string::utf8(b"=============================================================================="));
        print(&string::utf8(b"==================Test Delete File Challenge=================================="));
        print(&string::utf8(b"=============================================================================="));

        // Generate challenges.
        let challenge_num = 3;
        print(&string_utils::format1(&b"Generated challenges: {}", challenge_num));
        for (_i in 0.. challenge_num) {
            generate_challages(admin, address_of(provider), address_of(client), commitment);
        };

        // Get deleted challenges to prove.
        let package_challenges_for_delete = get_challages_by_commitment(
            address_of(provider),
            address_of(client),
            commitment
        );

        let del_c = vector::borrow(&package_challenges_for_delete, 0);
        let del_file_info = vector::borrow(&file_signed_infos, del_c.file_pos);

        let (del_proof, del_y_out) = poly_commit_fk20::generate_proof_native_test(
            del_c.commitment,
            file_sig_128,
            vector[del_c.file_pos * 4 + 0, del_c.file_pos * 4 + 1, del_c.file_pos * 4 + 2, del_c.file_pos * 4 + 3, ]
        );

        let raw_signature = vector::fold(vector[0, 1, 2, 3], vector::empty<u8>(), |sig, i|{
            vector::append(&mut sig, *vector::borrow(&file_sig_128, del_c.file_pos * 4 + i));
            sig
        });

        let deleted_file_info = DeletedFileInfo {
            provider: address_of(provider),
            client: address_of(client),
            commitment,
            deleted_file_sequence_nos: vector[del_c.file_pos],
            total_size: 100,
            delete_sec: now_seconds()
        };

        print(&string_utils::format1(&b"Proved 1 deleted file challenge: {}", 1));
        prove_deleted_file_challenge(
            provider,
            address_of(client),
            commitment,
            del_c.id,
            del_proof,
            vector::map(del_y_out, |e| bcs::to_bytes(&e)),
            del_file_info.file_root,
            del_file_info.sequence_no,
            del_file_info.agg_total_bytes,
            del_file_info.segment_num,
            raw_signature,
            deleted_file_info.deleted_file_sequence_nos,
            deleted_file_info.total_size,
            deleted_file_info.delete_sec,
            signature_to_bytes(&sign_arbitrary_bytes(&cli_sk, bcs::to_bytes(&deleted_file_info)))
        );

        let current_challenges = vector::length(
            &get_challages_by_commitment(address_of(provider), address_of(client), commitment)
        );
        print(&string_utils::format1(&b"Remain challenges: {}", current_challenges));
        assert!(current_challenges == challenge_num - 1, E_TEST_FAILED);
    }


    #[test(admin = @file_storage, provider = @provider, client = @client, challenger = @challenger)]
    fun test_e2e_storage_failed_prove_deleted_files(
        admin: &signer,
        provider: &signer,
        client: &signer,
        challenger: &signer,
    ) acquires Ledger, ChallengeStore, SigCapStore {
        setup(admin, provider, client);

        create_account_unchecked_for_test(address_of(challenger));

        // Generate provider/client key pair.
        let (cli_sk, cli_pk, _pro_sk, pro_pk) = generate_client_pk_to_auth();

        register_provider(provider, validated_public_key_to_bytes(&pro_pk), FEE_UNIT_BYTE, 123);

        register_client(client, validated_public_key_to_bytes(&cli_pk));
        charge_eds(client, 100_00000000);
        charge_eds(provider, 100_00000000);


        // Test file all merkel node hash store for challenge.
        let file_data_raw_list = vector::empty<vector<vector<u8>>>();
        let merkel_roots = vector::empty<vector<u8>>();
        let merkel_file_trees = vector::empty<vector<vector<u8>>>();
        let file_signed_infos = vector::empty<FileSignedInfo>();

        // Generate test file data pow of 2.
        let file_num = 8;

        let daily_file_info = vector::empty<TestFileInfo>();

        let total_bytes = 0;
        let file_sig_128 = vector::empty<vector<u8>>();
        for (i in 0..file_num) {
            let file_data_raw = vector::empty<vector<u8>>();

            let segment_size = randomness::u64_range(8, 16);
            let file_segment = math64::pow(2, randomness::u64_integer() % 10 + 1);
            for (_i in 0..file_segment) {
                vector::push_back(&mut file_data_raw, randomness::bytes(segment_size));
            };

            total_bytes = total_bytes + segment_size * file_segment;
            vector::push_back(&mut file_data_raw_list, file_data_raw);

            // Calculate merkel nodes.
            let (root, tree) = calc_merkel_tree(&file_data_raw);
            //print(&tree);

            vector::push_back(&mut merkel_roots, root);
            vector::push_back(&mut merkel_file_trees, tree);

            vector::push_back(&mut daily_file_info, TestFileInfo {
                root,
                segment_num: file_segment,
            });

            let commit_info = FileSignedInfo {
                provider: address_of(provider),
                file_root: root,
                sequence_no: i,
                agg_total_bytes: total_bytes,
                segment_num: file_segment,
            };

            vector::push_back(&mut file_signed_infos, commit_info);

            let signature = signature_to_bytes(&sign_arbitrary_bytes(&cli_sk, bcs::to_bytes(&commit_info)));

            for (i in 0.. (FILE_SIGNATURE_U8_SIZE / COMMIT_DATA_U8_SIZE)) {
                vector::push_back(
                    &mut file_sig_128,
                    vector::slice(&signature, COMMIT_DATA_U8_SIZE * i, COMMIT_DATA_U8_SIZE * (i + 1))
                );
            };
        };

        // Generate commitment
        let commitment = poly_commit_fk20::generate_commitment_native_test(file_sig_128);

        // Upload data info on chain.
        let latest_commit_info = *vector::borrow(&file_signed_infos, file_num - 1);

        let client_addr = address_of(client);
        let provider_addr = address_of(provider);


        upload_single_cilent_daily_file_package(
            provider,
            client_addr,
            latest_commit_info.file_root,
            latest_commit_info.sequence_no,
            latest_commit_info.agg_total_bytes,
            latest_commit_info.segment_num,
            signature_to_bytes(&sign_arbitrary_bytes(&cli_sk, bcs::to_bytes(&latest_commit_info))),
            commitment
        );

        let ledger = borrow_global_mut<Ledger>(ADMIN_ADDR);
        let client_account = smart_table::borrow_mut(
            &mut ledger.cli_accounts,
            client_addr
        );

        // Check fee.
        let fee_cfg = smart_table::borrow(&ledger.pro_fee_configs, provider_addr);
        let fee = U128(total_bytes) * 1 * fee_cfg.fee_per_day;

        assert!(client_account.freezed == fee, E_TEST_FAILED);

        print(&string::utf8(b"=============================================================================="));
        print(&string::utf8(b"==================Test Failed Delete File Challenge==========================="));
        print(&string::utf8(b"=============================================================================="));


        timestamp::update_global_time_for_test_secs(DAY_SECONDS * 3);

        collect_fee(provider, client_addr);

        // Generate challenges.
        let challenge_num = 5;
        print(&string_utils::format1(&b"Generated challenges: {}", challenge_num));
        for (_i in 0.. challenge_num) {
            generate_challages(challenger, provider_addr, client_addr, commitment);
        };

        // Get deleted challenges to prove.
        let package_challenges_for_delete = get_challages_by_commitment(
            provider_addr,
            client_addr,
            commitment
        );

        let del_c = vector::borrow(&package_challenges_for_delete, 0);
        let del_file_info = vector::borrow(&file_signed_infos, del_c.file_pos);

        let (del_proof, del_y_out) = poly_commit_fk20::generate_proof_native_test(
            del_c.commitment,
            file_sig_128,
            vector[del_c.file_pos * 4 + 0, del_c.file_pos * 4 + 1, del_c.file_pos * 4 + 2, del_c.file_pos * 4 + 3, ]
        );

        let raw_signature = vector::fold(vector[0, 1, 2, 3], vector::empty<u8>(), |sig, i|{
            vector::append(&mut sig, *vector::borrow(&file_sig_128, del_c.file_pos * 4 + i));
            sig
        });

        let deleted_file_info = DeletedFileInfo {
            provider: provider_addr,
            client: client_addr,
            commitment,
            deleted_file_sequence_nos: vector[del_c.file_pos],
            total_size: 100,
            delete_sec: now_seconds()
        };

        print(&string_utils::format1(&b"Proved faild deleted file challenge: {}", 1));
        prove_deleted_file_challenge(
            provider,
            client_addr,
            commitment,
            del_c.id,
            del_proof,
            vector::map(del_y_out, |e| bcs::to_bytes(&(e + 1))),
            del_file_info.file_root,
            del_file_info.sequence_no,
            del_file_info.agg_total_bytes,
            del_file_info.segment_num,
            raw_signature,
            deleted_file_info.deleted_file_sequence_nos,
            deleted_file_info.total_size,
            deleted_file_info.delete_sec,
            signature_to_bytes(&sign_arbitrary_bytes(&cli_sk, bcs::to_bytes(&deleted_file_info)))
        );

        let current_challenges = vector::length(
            &get_challages_by_commitment(provider_addr, client_addr, commitment)
        );
        print(&string_utils::format1(&b"Remain challenges: {}", current_challenges));
        assert!(current_challenges == challenge_num - 1, E_TEST_FAILED);

        let challenger_balance = endless_coin::balance(address_of(challenger));
        print(&string_utils::format1(&b"Challenger balance is {}", challenger_balance));


        let deleted_file_info_no_up = DeletedFileInfo {
            provider: provider_addr,
            client: client_addr,
            commitment,
            deleted_file_sequence_nos: vector[2],
            total_size: 100,
            delete_sec: now_seconds()
        };
        timestamp::update_global_time_for_test_secs(DAY_SECONDS * 5);
        print(&string_utils::format1(&b"Before justify Client balance is {}", res_balance_eds(client_addr)));
        justify_deleted_files(
            challenger,
            address_of(provider),
            address_of(client),
            deleted_file_info_no_up.commitment,
            deleted_file_info_no_up.deleted_file_sequence_nos,
            deleted_file_info_no_up.total_size,
            deleted_file_info.delete_sec,
            signature_to_bytes(&sign_arbitrary_bytes(&cli_sk, bcs::to_bytes(&deleted_file_info_no_up))),
            signature_to_bytes(&sign_arbitrary_bytes(&_pro_sk, bcs::to_bytes(&deleted_file_info_no_up))),
        );
        print(&string_utils::format1(&b" After justify Client balance is {}", res_balance_eds(client_addr)));

        timestamp::update_global_time_for_test_secs(DAY_SECONDS * 6);
        collect_fee(provider, client_addr);
        print(&string_utils::format1(&b"Client balance is {}", res_balance_eds(client_addr)));
        timestamp::update_global_time_for_test_secs(DAY_SECONDS * 8);
        collect_fee(provider, client_addr);
        print(&string_utils::format1(&b"Client balance is {}", res_balance_eds(client_addr)));


        let fail_c = vector::borrow(&package_challenges_for_delete, 1);
        let fail_f = vector::borrow(&file_signed_infos, fail_c.file_pos);

        let file_pos = fail_c.file_pos;

        let challenge_segment = fail_c.segment_r % fail_f.segment_num;
        let file_merkel_tree = vector::borrow(&merkel_file_trees, file_pos);
        let (proof, y_prove_out) = poly_commit_fk20::generate_proof_native_test(
            fail_c.commitment,
            file_sig_128,
            vector[file_pos * 4 + 0, file_pos * 4 + 1, file_pos * 4 + 2, file_pos * 4 + 3, ]
        );
        print(&string::utf8(b"-------------------------------Prove challenge failed -----------------------"));

        let signed_info = vector::borrow(&file_signed_infos, file_pos);

        let signature = vector::fold(vector[0, 1, 2, 3], vector::empty<u8>(), |sig, i|{
            vector::append(&mut sig, *vector::borrow(&file_sig_128, file_pos * 4 + i));
            sig
        });

        let segment = vector::borrow(
            vector::borrow(&file_data_raw_list, fail_c.file_pos),
            fail_c.segment_r % fail_f.segment_num
        );
        let (proof_path_hashes, _proof_path_tasgs) = generate_merkel_proof_path(
            file_merkel_tree,
            challenge_segment
        );

        prove_challenge(
            fail_c.provider,
            fail_c.client,
            fail_c.commitment,
            fail_c.id,
            proof,
            vector::map(y_prove_out, |e| bcs::to_bytes(&(e + 1))),
            signed_info.file_root,
            signed_info.sequence_no,
            signed_info.agg_total_bytes,
            signed_info.segment_num,
            signature,
            *segment,
            proof_path_hashes,
        );


        timestamp::update_global_time_for_test_secs(DAY_SECONDS * 9);
        collect_fee(provider, client_addr);
        print(&string_utils::format1(&b"Client balance is {}", res_balance_eds(client_addr)));

        withdraw_client(client, client_addr, res_balance_eds(client_addr));
        assert!(res_balance_eds(client_addr) == 0, E_TEST_FAILED);
        print(&string_utils::format1(&b"After withdraw cli_balance is {}", res_balance_eds(client_addr)));

        print(&string::utf8(b"-----------------------------Set all challenge failed -----------------------------"));
        timestamp::update_global_time_for_test_secs(DAY_SECONDS * 15);
        set_client_all_timeout_challenge_failed(provider, client_addr);
        assert!(res_balance_eds(client_addr) > 0, E_TEST_FAILED);
        print(&string_utils::format1(&b"Set timeout challenge failed, cli_balance {}", res_balance_eds(client_addr)));
        withdraw_client(client, client_addr, res_balance_eds(client_addr));
        assert!(res_balance_eds(client_addr) == 0, E_TEST_FAILED);
        print(&string_utils::format1(&b"After withdraw cli_balance is {}", res_balance_eds(client_addr)));

        timestamp::update_global_time_for_test_secs(DAY_SECONDS * 18);
        collect_fee(provider, client_addr);
        remove_no_fee_client(provider, client_addr);

        timestamp::update_global_time_for_test_secs(DAY_SECONDS * 22);
        withdraw_provider(provider, provider_addr, 0);
        assert!(res_balance_eds(provider_addr) >= PROVIDER_MIN_STACKING_AMOUNT, E_TEST_FAILED);
    }


    #[test(admin = @file_storage, provider = @provider, client = @client)]
    fun test_poly_commit_prove(
        admin: &signer,
        provider: &signer,
        client: &signer
    ) {
        setup(admin, provider, client);

        let degree = 16;
        let datas_128: vector<u128> = vector::empty();
        for (_i in 0..degree) {
            vector::push_back(&mut datas_128, randomness::u128_integer());
        };

        let datas = vector::map(datas_128, |da| bcs::to_bytes(&da));

        print(&string::utf8(b"----------------------------- Datas -----------------------------"));
        print(&datas);
        print(&vector::length(&datas));

        let commintment = poly_commit_fk20::generate_commitment_native_test(datas);
        print(&string::utf8(b"-----------------------------FK20 Commitment -----------------------"));
        print(&commintment);
        let points_x = vector[1, 2, 3, 4];
        let (proof, y_prove_out) = poly_commit_fk20::generate_proof_native_test(commintment, datas, points_x, );
        print(&string::utf8(b"-----------------------------FK20 Proof ---------------------------"));
        print(&proof);
        print(&y_prove_out);
        //let points_y = vector::map(points_x, |x|*vector::borrow(&datas, x))  ;

        print(&string::utf8(b"-----------------------------FK20 points_y ---------------------------"));
        let pass = poly_commit_fk20::verify_proof_native(
            proof,
            commintment,
            points_x,
            vector::map(y_prove_out, |e| bcs::to_bytes(&e)),
            vector::length(&datas_128)
        );

        assert!(pass, E_TEST_FAILED);
    }
}
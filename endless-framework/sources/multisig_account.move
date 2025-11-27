/// Enhanced multisig account standard on Endless. This is different from the native multisig scheme support enforced via
/// the account's auth key.
///
/// This module allows creating a flexible and powerful multisig account with seamless support for updating owners
/// without changing the auth key. Users can choose to store transaction payloads waiting for owner signatures on chain
/// or off chain (primary consideration is decentralization/transparency vs gas cost).
///
/// The multisig account is a resource account underneath. By default, it has no auth key and can only be controlled via
/// the special multisig transaction flow. However, owners can create a transaction to change the auth key to match a
/// private key off chain if so desired.
///
/// Transactions need to be executed in order of creation, similar to transactions for a normal Endless account (enforced
/// with account nonce).
///
/// The flow is like below:
/// 1. Owners can create a new multisig account by calling create (signer is default single owner) or with
/// create_with_owners where multiple initial owner addresses can be specified. This is different (and easier) from
/// the native multisig scheme where the owners' public keys have to be specified. Here, only addresses are needed.
/// 2. Owners can be added/removed any time by calling add_owners or remove_owners. The transactions to do still need
/// to follow the k-of-n scheme specified for the multisig account.
/// 3. To create a new transaction, an owner can call create_transaction with the transaction payload. This will store
/// the full transaction payload on chain, which adds decentralization (censorship is not possible as the data is
/// available on chain) and makes it easier to fetch all transactions waiting for execution. If saving gas is desired,
/// an owner can alternatively call create_transaction_with_hash where only the payload hash is stored. Later execution
/// will be verified using the hash. Only owners can create transactions and a transaction id (incremeting id) will be
/// assigned.
/// 4. To approve or reject a transaction, other owners can call approve() or reject() with the transaction id.
/// 5. If there are enough approvals, any owner can execute the transaction using the special MultisigTransaction type
/// with the transaction id if the full payload is already stored on chain or with the transaction payload if only a
/// hash is stored. Transaction execution will first check with this module that the transaction payload has gotten
/// enough signatures. If so, it will be executed as the multisig account. The owner who executes will pay for gas.
/// 6. If there are enough rejections, any owner can finalize the rejection by calling execute_rejected_transaction().
///
/// Note that this multisig account model is not designed to use with a large number of owners. The more owners there
/// are, the more expensive voting on transactions will become. If a large number of owners is designed, such as in a
/// flat governance structure, clients are encouraged to write their own modules on top of this multisig account module
/// and implement the governance voting logic on top.
module endless_framework::multisig_account {
    use endless_framework::account;
    use endless_framework::create_signer::create_signer;
    use endless_framework::event::emit;
    use endless_framework::timestamp::now_seconds;
    use endless_std::simple_map::{Self, SimpleMap};
    use endless_std::table::{Self, Table};
    use endless_std::from_bcs;
    use std::error;
    use std::hash::sha3_256;
    use std::option::{Self, Option};
    use std::signer::address_of;
    use std::string::String;
    use std::vector;

    /// The salt used to create a resource account during multisig account creation.
    /// This is used to avoid conflicts with other modules that also create resource accounts with the same owner
    /// account.
    const DOMAIN_SEPARATOR: vector<u8> = b"endless_framework::multisig_account";

    // Any error codes > 2000 can be thrown as part of transaction prologue.
    /// Owner list cannot contain the same address more than once.
    const EDUPLICATE_OWNER: u64 = 1;
    /// Specified account is not a multisig account.
    const EACCOUNT_NOT_MULTISIG: u64 = 2002;
    /// Account executing this operation is not an owner of the multisig account.
    const ENOT_OWNER: u64 = 2003;
    /// Transaction payload cannot be empty.
    const EPAYLOAD_CANNOT_BE_EMPTY: u64 = 4;
    /// Multisig account must have at least one owner.
    const ENOT_ENOUGH_OWNERS: u64 = 5;
    /// Transaction with specified id cannot be found.
    const ETRANSACTION_NOT_FOUND: u64 = 2006;
    /// Provided target function does not match the hash stored in the on-chain transaction.
    const EPAYLOAD_DOES_NOT_MATCH_HASH: u64 = 2008;
    /// Transaction has not received enough approvals to be executed.
    const ENOT_ENOUGH_APPROVALS: u64 = 2009;
    /// Transaction has not received enough rejections to be officially rejected.
    const ENOT_ENOUGH_REJECTIONS: u64 = 10;
    /// Number of signatures required must be more than zero and at most the total number of owners.
    const EINVALID_SIGNATURES_REQUIRED: u64 = 11;
    /// Payload hash must be exactly 32 bytes (sha3-256).
    const EINVALID_PAYLOAD_HASH: u64 = 12;
    /// The multisig account itself cannot be an owner.
    const EOWNER_CANNOT_BE_MULTISIG_ACCOUNT_ITSELF: u64 = 13;
    /// Multisig accounts has not been enabled on this current network yet.
    const EMULTISIG_ACCOUNTS_NOT_ENABLED_YET: u64 = 14;
    /// The number of metadata keys and values don't match.
    const ENUMBER_OF_METADATA_KEYS_AND_VALUES_DONT_MATCH: u64 = 15;
    /// The specified metadata contains duplicate attributes (keys).
    const EDUPLICATE_METADATA_KEY: u64 = 16;
    /// The sequence number provided is invalid. It must be between [1, next pending transaction - 1].
    const EINVALID_SEQUENCE_NUMBER: u64 = 17;
    /// Provided owners to remove and new owners overlap.
    const EOWNERS_TO_REMOVE_NEW_OWNERS_OVERLAP: u64 = 18;

    const ZERO_AUTH_KEY: vector<u8> = x"0000000000000000000000000000000000000000000000000000000000000000";

    /// Represents a multisig account's configurations and transactions.
    /// This will be stored in the multisig account (created as a resource account separate from any owner accounts).
    struct MultisigAccount has key {
        // Map from transaction id (incrementing id) to transactions to execute for this multisig account.
        // Already executed transactions are deleted to save on storage but can always be accessed via events.
        transactions: Table<u64, MultisigTransaction>,
        // The sequence number assigned to the last executed or rejected transaction. Used to enforce in-order
        // executions of proposals, similar to sequence number for a normal (single-user) account.
        last_executed_sequence_number: u64,
        // The sequence number to assign to the next transaction. This is not always last_executed_sequence_number + 1
        // as there can be multiple pending transactions. The number of pending transactions should be equal to
        // next_sequence_number - (last_executed_sequence_number + 1).
        next_sequence_number: u64,
    }

    /// A transaction to be executed in a multisig account.
    /// This must contain either the full transaction payload or its hash (stored as bytes).
    struct MultisigTransaction has copy, drop, store {
        payload: Option<vector<u8>>,
        payload_hash: Option<vector<u8>>,
        // Mapping from owner adress to vote (yes for approve, no for reject). Uses a simple map to deduplicate.
        votes: SimpleMap<address, bool>,
        // The owner who created this transaction.
        creator: address,
        // The timestamp in seconds when the transaction was created.
        creation_time_secs: u64,
    }

    /// Contains information about execution failure.
    struct ExecutionError has copy, drop, store {
        // The module where the error occurs.
        abort_location: String,
        // There are 3 error types, stored as strings:
        // 1. VMError. Indicates an error from the VM, e.g. out of gas, invalid auth key, etc.
        // 2. MoveAbort. Indicates an abort, e.g. assertion failure, from inside the executed Move code.
        // 3. MoveExecutionFailure. Indicates an error from Move code where the VM could not continue. For example,
        // arithmetic failures.
        error_type: String,
        // The detailed error code explaining which error occurred.
        error_code: u64,
    }

    /// Used only for verifying multisig account creation on top of existing accounts.
    struct MultisigAccountCreationMessage has copy, drop {
        // Chain id is included to prevent cross-chain replay.
        chain_id: u8,
        // Account address is included to prevent cross-account replay (when multiple accounts share the same auth key).
        account_address: address,
        // Sequence number is not needed for replay protection as the multisig account can only be created once.
        // But it's included to ensure timely execution of account creation.
        sequence_number: u64,
        // The list of owners for the multisig account.
        owners: vector<address>,
        // The number of signatures required (signature threshold).
        num_signatures_required: u64,
    }

    /// Used only for verifying multisig account creation on top of existing accounts and rotating the auth key to 0x0.
    struct MultisigAccountCreationWithAuthKeyRevocationMessage has copy, drop {
        // Chain id is included to prevent cross-chain replay.
        chain_id: u8,
        // Account address is included to prevent cross-account replay (when multiple accounts share the same auth key).
        account_address: address,
        // Sequence number is not needed for replay protection as the multisig account can only be created once.
        // But it's included to ensure timely execution of account creation.
        sequence_number: u64,
        // The list of owners for the multisig account.
        owners: vector<address>,
        // The number of signatures required (signature threshold).
        num_signatures_required: u64,
    }

    #[event]
    /// Event emitted when new owners are added to the multisig account.
    struct AddOwnersEvent has drop, store {
        owners_added: vector<address>,
    }

    #[event]
    /// Event emitted when new owners are removed from the multisig account.
    struct RemoveOwnersEvent has drop, store {
        owners_removed: vector<address>,
    }

    #[event]
    /// Event emitted when the number of signatures required is updated.
    struct UpdateSignaturesRequiredEvent has drop, store {
        old_num_signatures_required: u64,
        new_num_signatures_required: u64,
    }

    #[event]
    /// Event emitted when a transaction is created.
    struct CreateTransactionEvent has drop, store {
        creator: address,
        sequence_number: u64,
        transaction: MultisigTransaction,
    }

    #[event]
    /// Event emitted when an owner approves or rejects a transaction.
    struct VoteEvent has drop, store {
        owner: address,
        sequence_number: u64,
        approved: bool,
    }

    #[event]
    /// Event emitted when a transaction is officially rejected because the number of rejections has reached the
    /// number of signatures required.
    struct ExecuteRejectedTransactionEvent has drop, store {
        sequence_number: u64,
        num_rejections: u64,
        executor: address,
    }

    #[event]
    /// Event emitted when a transaction is executed.
    struct TransactionExecutionSucceededEvent has drop, store {
        executor: address,
        sequence_number: u64,
        transaction_payload: vector<u8>,
        num_approvals: u64,
    }

    #[event]
    /// Event emitted when a transaction's execution failed.
    struct TransactionExecutionFailedEvent has drop, store {
        executor: address,
        sequence_number: u64,
        transaction_payload: vector<u8>,
        num_approvals: u64,
        execution_error: ExecutionError,
    }

    #[event]
    /// Event emitted when a transaction's metadata is updated.
    struct MetadataUpdatedEvent has drop, store {
        old_metadata: SimpleMap<String, vector<u8>>,
        new_metadata: SimpleMap<String, vector<u8>>,
    }

    ////////////////////////// View functions ///////////////////////////////

    #[view]
    /// Return the transaction with the given transaction id.
    public fun get_transaction(
        multisig_account: address,
        sequence_number: u64,
    ): MultisigTransaction acquires MultisigAccount {
        let multisig_account_resource = borrow_global<MultisigAccount>(multisig_account);
        assert!(
            sequence_number > 0 && sequence_number < multisig_account_resource.next_sequence_number,
            error::invalid_argument(EINVALID_SEQUENCE_NUMBER),
        );
        *table::borrow(&multisig_account_resource.transactions, sequence_number)
    }

    #[view]
    /// Return all pending transactions.
    public fun get_pending_transactions(multisig_account: address): vector<MultisigTransaction> acquires MultisigAccount {
        let pending_transactions: vector<MultisigTransaction> = vector[];
        let multisig_account = borrow_global<MultisigAccount>(multisig_account);
        let i = multisig_account.last_executed_sequence_number + 1;
        let next_sequence_number = multisig_account.next_sequence_number;
        while (i < next_sequence_number) {
            vector::push_back(&mut pending_transactions, *table::borrow(&multisig_account.transactions, i));
            i = i + 1;
        };
        pending_transactions
    }

    #[view]
    /// Return the payload for the next transaction in the queue.
    public fun get_next_transaction_payload(
        multisig_account: address, provided_payload: vector<u8>): vector<u8> acquires MultisigAccount {
        let multisig_account_resource = borrow_global<MultisigAccount>(multisig_account);
        let sequence_number = multisig_account_resource.last_executed_sequence_number + 1;
        let transaction = table::borrow(&multisig_account_resource.transactions, sequence_number);

        if (option::is_some(&transaction.payload)) {
            *option::borrow(&transaction.payload)
        } else {
            provided_payload
        }
    }

    #[view]
    /// Return true if the transaction with given transaction id can be executed now.
    public fun can_be_executed(
        multisig_account: address, sequence_number: u64): bool acquires MultisigAccount {
        let multisig_account_resource = borrow_global<MultisigAccount>(multisig_account);
        assert!(
            sequence_number > 0 && sequence_number < multisig_account_resource.next_sequence_number,
            error::invalid_argument(EINVALID_SEQUENCE_NUMBER),
        );
        let transaction = table::borrow(&multisig_account_resource.transactions, sequence_number);
        let owners = get_owners(multisig_account);
        let num_signatures_required = account::num_signatures_required(multisig_account);
        let (num_approvals, _) = num_approvals_and_rejections(&owners, transaction);
        sequence_number == multisig_account_resource.last_executed_sequence_number + 1 &&
            num_approvals >= num_signatures_required
    }

    #[view]
    /// Return true if the transaction with given transaction id can be officially rejected.
    public fun can_be_rejected(
        multisig_account: address, sequence_number: u64): bool acquires MultisigAccount {
        let multisig_account_resource = borrow_global<MultisigAccount>(multisig_account);
        assert!(
            sequence_number > 0 && sequence_number < multisig_account_resource.next_sequence_number,
            error::invalid_argument(EINVALID_SEQUENCE_NUMBER),
        );
        let transaction = table::borrow(&multisig_account_resource.transactions, sequence_number);
        let owners = get_owners(multisig_account);
        let num_signatures_required = account::num_signatures_required(multisig_account);
        let (_, num_rejections) = num_approvals_and_rejections(&owners, transaction);
        sequence_number == multisig_account_resource.last_executed_sequence_number + 1 &&
            num_rejections >= num_signatures_required
    }

    #[view]
    /// Return the id of the last transaction that was executed (successful or failed) or removed.
    public fun last_resolved_sequence_number(multisig_account: address): u64 acquires MultisigAccount {
        let multisig_account_resource = borrow_global_mut<MultisigAccount>(multisig_account);
        multisig_account_resource.last_executed_sequence_number
    }

    #[view]
    /// Return the id of the next transaction created.
    public fun next_sequence_number(multisig_account: address): u64 acquires MultisigAccount {
        let multisig_account_resource = borrow_global_mut<MultisigAccount>(multisig_account);
        multisig_account_resource.next_sequence_number
    }

    #[view]
    /// Return a bool tuple indicating whether an owner has voted and if so, whether they voted yes or no.
    public fun vote(
        multisig_account: address, sequence_number: u64, owner: address): (bool, bool) acquires MultisigAccount {
        let multisig_account_resource = borrow_global_mut<MultisigAccount>(multisig_account);
        assert!(
            sequence_number > 0 && sequence_number < multisig_account_resource.next_sequence_number,
            error::invalid_argument(EINVALID_SEQUENCE_NUMBER),
        );
        let transaction = table::borrow(&multisig_account_resource.transactions, sequence_number);
        let votes = &transaction.votes;
        let voted = simple_map::contains_key(votes, &owner);
        let vote = voted && *simple_map::borrow(votes, &owner);
        (voted, vote)
    }

    ////////////////////////// Multisig transaction flow ///////////////////////////////

    /// Create a multisig transaction, which will have one approval initially (from the creator).
    public entry fun create_transaction(
        owner: &signer,
        multisig_account: address,
        payload: vector<u8>,
    ) acquires MultisigAccount {
        assert!(vector::length(&payload) > 0, error::invalid_argument(EPAYLOAD_CANNOT_BE_EMPTY));

        assert_account_exists(multisig_account);
        if (!exists<MultisigAccount>(multisig_account)) {
            move_to(&create_signer(multisig_account), MultisigAccount {
                transactions: table::new(),
                last_executed_sequence_number: 0,
                next_sequence_number: 1,
            });
        };

        let multisig_account_resource = borrow_global_mut<MultisigAccount>(multisig_account);
        assert_is_owner(owner, multisig_account);

        let creator = address_of(owner);
        let transaction = MultisigTransaction {
            payload: option::some(payload),
            payload_hash: option::none<vector<u8>>(),
            votes: simple_map::create<address, bool>(),
            creator,
            creation_time_secs: now_seconds(),
        };
        add_transaction(creator, multisig_account_resource, transaction);
    }

    /// Create a multisig transaction with a transaction hash instead of the full payload.
    /// This means the payload will be stored off chain for gas saving. Later, during execution, the executor will need
    /// to provide the full payload, which will be validated against the hash stored on-chain.
    public entry fun create_transaction_with_hash(
        owner: &signer,
        multisig_account: address,
        payload_hash: vector<u8>,
    ) acquires MultisigAccount {
        // Payload hash is a sha3-256 hash, so it must be exactly 32 bytes.
        assert!(vector::length(&payload_hash) == 32, error::invalid_argument(EINVALID_PAYLOAD_HASH));

        assert_account_exists(multisig_account);
        if (!exists<MultisigAccount>(multisig_account)) {
            move_to(&create_signer(multisig_account), MultisigAccount {
                transactions: table::new(),
                last_executed_sequence_number: 0,
                next_sequence_number: 1,
            });
        };
        let multisig_account_resource = borrow_global_mut<MultisigAccount>(multisig_account);
        assert_is_owner(owner, multisig_account);

        let creator = address_of(owner);
        let transaction = MultisigTransaction {
            payload: option::none<vector<u8>>(),
            payload_hash: option::some(payload_hash),
            votes: simple_map::create<address, bool>(),
            creator,
            creation_time_secs: now_seconds(),
        };
        add_transaction(creator, multisig_account_resource, transaction);
    }

    /// Approve a multisig transaction.
    public entry fun approve_transaction(
        owner: &signer, multisig_account: address, sequence_number: u64) acquires MultisigAccount {
        vote_transanction(owner, multisig_account, sequence_number, true);
    }

    /// Reject a multisig transaction.
    public entry fun reject_transaction(
        owner: &signer, multisig_account: address, sequence_number: u64) acquires MultisigAccount {
        vote_transanction(owner, multisig_account, sequence_number, false);
    }

    /// Generic function that can be used to either approve or reject a multisig transaction
    public entry fun vote_transanction(
        owner: &signer, multisig_account: address, sequence_number: u64, approved: bool) acquires MultisigAccount {
        assert_multisig_account_exists(multisig_account);
        let multisig_account_resource = borrow_global_mut<MultisigAccount>(multisig_account);
        assert_is_owner(owner, multisig_account);

        assert!(
            table::contains(&multisig_account_resource.transactions, sequence_number),
            error::not_found(ETRANSACTION_NOT_FOUND),
        );
        let transaction = table::borrow_mut(&mut multisig_account_resource.transactions, sequence_number);
        let votes = &mut transaction.votes;
        let owner_addr = address_of(owner);

        if (simple_map::contains_key(votes, &owner_addr)) {
            *simple_map::borrow_mut(votes, &owner_addr) = approved;
        } else {
            simple_map::add(votes, owner_addr, approved);
        };

        emit(
            VoteEvent {
                owner: owner_addr,
                sequence_number,
                approved,
            }
        );
    }

    /// Remove the next transaction if it has sufficient owner rejections.
    public entry fun execute_rejected_transaction(
        owner: &signer,
        multisig_account: address,
    ) acquires MultisigAccount {
        assert_multisig_account_exists(multisig_account);
        let multisig_account_resource = borrow_global_mut<MultisigAccount>(multisig_account);
        assert_is_owner(owner, multisig_account);
        let sequence_number = multisig_account_resource.last_executed_sequence_number + 1;
        assert!(
            table::contains(&multisig_account_resource.transactions, sequence_number),
            error::not_found(ETRANSACTION_NOT_FOUND),
        );
        let owners = get_owners(multisig_account);
        let (_, num_rejections) = remove_executed_transaction(multisig_account_resource, &owners);
        let num_signatures_required = account::num_signatures_required(multisig_account);
        assert!(
            num_rejections >= num_signatures_required,
            error::invalid_state(ENOT_ENOUGH_REJECTIONS),
        );

        emit(
            ExecuteRejectedTransactionEvent {
                sequence_number,
                num_rejections,
                executor: address_of(owner),
            }
        );
    }

    ////////////////////////// To be called by VM only ///////////////////////////////

    /// Called by the VM as part of transaction prologue, which is invoked during mempool transaction validation and as
    /// the first step of transaction execution.
    ///
    /// Transaction payload is optional if it's already stored on chain for the transaction.
    fun validate_multisig_transaction(
        owner: &signer, multisig_account: address, payload: vector<u8>) acquires MultisigAccount {
        assert_multisig_account_exists(multisig_account);
        let multisig_account_resource = borrow_global<MultisigAccount>(multisig_account);
        assert_is_owner(owner, multisig_account);
        let sequence_number = multisig_account_resource.last_executed_sequence_number + 1;
        assert!(
            table::contains(&multisig_account_resource.transactions, sequence_number),
            error::invalid_argument(ETRANSACTION_NOT_FOUND),
        );
        let transaction = table::borrow(&multisig_account_resource.transactions, sequence_number);
        let owners = get_owners(multisig_account);
        let num_signatures_required = account::num_signatures_required(multisig_account);
        let (num_approvals, _) = num_approvals_and_rejections(&owners, transaction);
        assert!(
            num_approvals >= num_signatures_required,
            error::invalid_argument(ENOT_ENOUGH_APPROVALS),
        );

        // If the transaction payload is not stored on chain, verify that the provided payload matches the hashes stored
        // on chain.
        if (option::is_some(&transaction.payload_hash)) {
            let payload_hash = option::borrow(&transaction.payload_hash);
            assert!(
                sha3_256(payload) == *payload_hash,
                error::invalid_argument(EPAYLOAD_DOES_NOT_MATCH_HASH),
            );
        };
    }

    /// Post-execution cleanup for a successful multisig transaction execution.
    /// This function is private so no other code can call this beside the VM itself as part of MultisigTransaction.
    fun successful_transaction_execution_cleanup(
        executor: address,
        multisig_account: address,
        transaction_payload: vector<u8>,
    ) acquires MultisigAccount {
        let multisig_account_resource = borrow_global_mut<MultisigAccount>(multisig_account);
        let owners = get_owners(multisig_account);
        let (num_approvals, _) = remove_executed_transaction(multisig_account_resource, &owners);
        emit(
            TransactionExecutionSucceededEvent {
                sequence_number: multisig_account_resource.last_executed_sequence_number,
                transaction_payload,
                num_approvals,
                executor,
            }
        );
    }

    /// Post-execution cleanup for a failed multisig transaction execution.
    /// This function is private so no other code can call this beside the VM itself as part of MultisigTransaction.
    fun failed_transaction_execution_cleanup(
        executor: address,
        multisig_account: address,
        transaction_payload: vector<u8>,
        execution_error: ExecutionError,
    ) acquires MultisigAccount {
        let multisig_account_resource = borrow_global_mut<MultisigAccount>(multisig_account);
        let owners = get_owners(multisig_account);
        let (num_approvals, _) = remove_executed_transaction(multisig_account_resource, &owners);
        emit(
            TransactionExecutionFailedEvent {
                executor,
                sequence_number: multisig_account_resource.last_executed_sequence_number,
                transaction_payload,
                num_approvals,
                execution_error,
            }
        );
    }

    ////////////////////////// Private functions ///////////////////////////////

    // Remove the next transaction in the queue as it's been executed and return the number of approvals it had.
    fun remove_executed_transaction(multisig_account_resource: &mut MultisigAccount, owners: &vector<address>): (u64, u64) {
        let sequence_number = multisig_account_resource.last_executed_sequence_number + 1;
        let transaction = table::remove(&mut multisig_account_resource.transactions, sequence_number);
        multisig_account_resource.last_executed_sequence_number = sequence_number;
        num_approvals_and_rejections(owners, &transaction)
    }

    fun add_transaction(creator: address, multisig_account: &mut MultisigAccount, transaction: MultisigTransaction) {
        // The transaction creator also automatically votes for the transaction.
        simple_map::add(&mut transaction.votes, creator, true);

        let sequence_number = multisig_account.next_sequence_number;
        multisig_account.next_sequence_number = sequence_number + 1;
        table::add(&mut multisig_account.transactions, sequence_number, transaction);
        emit(
            CreateTransactionEvent { creator, sequence_number, transaction },
        );
    }

    fun get_owners(multisig_account: address): vector<address> {
        let authentication_key = account::get_authentication_key(multisig_account);
        let owners = vector[];
        vector::for_each_reverse(authentication_key, |key| {
            vector::push_back(&mut owners, from_bcs::to_address(key));
        });
        owners
    }

    fun assert_is_owner(owner: &signer, multisig_account: address) {
        let owner = address_of(owner);
        assert!(account::is_original_account(owner), error::permission_denied(ENOT_OWNER));
        assert!(
            vector::contains(&get_owners(multisig_account), &owner),
            error::permission_denied(ENOT_OWNER),
        );
    }

    fun num_approvals_and_rejections(owners: &vector<address>, transaction: &MultisigTransaction): (u64, u64) {
        let num_approvals = 0;
        let num_rejections = 0;

        let votes = &transaction.votes;
        vector::for_each_ref(owners, |owner| {
            if (simple_map::contains_key(votes, owner)) {
                if (*simple_map::borrow(votes, owner)) {
                    num_approvals = num_approvals + 1;
                } else {
                    num_rejections = num_rejections + 1;
                };
            }
        });

        (num_approvals, num_rejections)
    }

    fun assert_multisig_account_exists(multisig_account: address) {
        assert!(exists<MultisigAccount>(multisig_account), error::invalid_state(EACCOUNT_NOT_MULTISIG));
        assert_account_exists(multisig_account);
    }

    fun assert_account_exists(account: address) {
        assert!(account::exists_at(account),  error::invalid_state(EACCOUNT_NOT_MULTISIG));
    }

    ////////////////////////// Tests ///////////////////////////////

    #[test_only]
    use endless_framework::account::create_account_for_test;
    #[test_only]
    use endless_framework::timestamp;
    #[test_only]
    use std::string::utf8;
    #[test_only]
    use std::features;
    #[test_only]
    use endless_framework::chain_id;

    #[test_only]
    const PAYLOAD: vector<u8> = vector[1, 2, 3];
    #[test_only]
    const ERROR_TYPE: vector<u8> = b"MoveAbort";
    #[test_only]
    const ABORT_LOCATION: vector<u8> = b"abort_location";
    #[test_only]
    const ERROR_CODE: u64 = 10;

    #[test_only]
    fun execution_error(): ExecutionError {
        ExecutionError {
            abort_location: utf8(ABORT_LOCATION),
            error_type: utf8(ERROR_TYPE),
            error_code: ERROR_CODE,
        }
    }

    #[test_only]
    fun setup(core: &signer) {
        let framework_signer = &create_signer(@0x1);
        features::change_feature_flags(
            framework_signer, vector[features::get_multisig_accounts_feature()], vector[]);
        timestamp::set_time_has_started_for_testing(framework_signer);
        chain_id::initialize_for_test(framework_signer, 1);

        let (_, _, _) = endless_framework::endless_coin::initialize_for_test(core);
    }

    #[test_only]
    fun setup_disabled() {
        let framework_signer = &create_signer(@0x1);
        features::change_feature_flags(
            framework_signer, vector[], vector[features::get_multisig_accounts_feature()]);
        timestamp::set_time_has_started_for_testing(framework_signer);
        chain_id::initialize_for_test(framework_signer, 1);
    }

    #[test(core = @0x1, owner_1 = @0x123, owner_2 = @0x124, owner_3 = @0x125)]
    public entry fun test_end_to_end(
        core: &signer, owner_1: &signer, owner_2: &signer, owner_3: &signer) acquires MultisigAccount {
        setup(core);
        let owner_1_addr = address_of(owner_1);
        let owner_2_addr = address_of(owner_2);
        let owner_3_addr = address_of(owner_3);
        create_account_for_test(owner_1_addr);
        create_account_for_test(owner_2_addr);
        create_account_for_test(owner_3_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_1_addr, owner_2_addr, owner_3_addr], 2);

        // Create three transactions.
        create_transaction(owner_1, multisig_account, PAYLOAD);
        create_transaction(owner_2, multisig_account, PAYLOAD);
        create_transaction_with_hash(owner_3, multisig_account, sha3_256(PAYLOAD));
        assert!(get_pending_transactions(multisig_account) == vector[
            get_transaction(multisig_account, 1),
            get_transaction(multisig_account, 2),
            get_transaction(multisig_account, 3),
        ], 0);

        // Owner 3 doesn't need to explicitly approve as they created the transaction.
        approve_transaction(owner_1, multisig_account, 3);
        // Third transaction has 2 approvals but cannot be executed out-of-order.
        assert!(!can_be_executed(multisig_account, 3), 0);

        // Owner 1 doesn't need to explicitly approve as they created the transaction.
        approve_transaction(owner_2, multisig_account, 1);
        // First transaction has 2 approvals so it can be executed.
        assert!(can_be_executed(multisig_account, 1), 1);
        // First transaction was executed successfully.
        successful_transaction_execution_cleanup(owner_2_addr, multisig_account,vector[]);
        assert!(get_pending_transactions(multisig_account) == vector[
            get_transaction(multisig_account, 2),
            get_transaction(multisig_account, 3),
        ], 0);

        reject_transaction(owner_1, multisig_account, 2);
        reject_transaction(owner_3, multisig_account, 2);
        // Second transaction has 1 approval (owner 3) and 2 rejections (owners 1 & 2) and thus can be removed.
        assert!(can_be_rejected(multisig_account, 2), 2);
        execute_rejected_transaction(owner_1, multisig_account);
        assert!(get_pending_transactions(multisig_account) == vector[
            get_transaction(multisig_account, 3),
        ], 0);

        // Third transaction can be executed now but execution fails.
        failed_transaction_execution_cleanup(owner_3_addr, multisig_account, PAYLOAD, execution_error());
        assert!(get_pending_transactions(multisig_account) == vector[], 0);
    }

    #[test(core = @0x1, owner_1 = @0x123, owner_2 = @0x124, owner_3 = @0x125)]
    public entry fun test_create_transaction(
        core: &signer, owner_1: &signer, owner_2: &signer, owner_3: &signer) acquires MultisigAccount {
        setup(core);
        let owner_1_addr = address_of(owner_1);
        let owner_2_addr = address_of(owner_2);
        let owner_3_addr = address_of(owner_3);
        create_account_for_test(owner_1_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_1_addr, owner_2_addr, owner_3_addr], 2);

        create_transaction(owner_1, multisig_account, PAYLOAD);
        let transaction = get_transaction(multisig_account, 1);
        assert!(transaction.creator == owner_1_addr, 0);
        assert!(option::is_some(&transaction.payload), 1);
        assert!(option::is_none(&transaction.payload_hash), 2);
        let payload = option::extract(&mut transaction.payload);
        assert!(payload == PAYLOAD, 4);
        // Automatic yes vote from creator.
        assert!(simple_map::length(&transaction.votes) == 1, 5);
        assert!(*simple_map::borrow(&transaction.votes, &owner_1_addr), 5);
    }

    #[test(core = @0x1, owner = @0x123)]
    #[expected_failure(abort_code = 0x10004, location = Self)]
    public entry fun test_create_transaction_with_empty_payload_should_fail(
        core: &signer, owner: &signer) acquires MultisigAccount {
        setup(core);
        create_account_for_test(address_of(owner));
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[address_of(owner)], 1);
        create_transaction(owner, multisig_account, vector[]);
    }

    #[test(core = @0x1, owner = @0x123, non_owner = @0x124)]
    #[expected_failure(abort_code = 0x507D3, location = Self)]
    public entry fun test_create_transaction_with_non_owner_should_fail(
        core: &signer, owner: &signer, non_owner: &signer) acquires MultisigAccount {
        setup(core);
        create_account_for_test(address_of(owner));
        let multisig_account = @0x1111;
        create_account_for_test(multisig_account);
        create_transaction(non_owner, multisig_account, PAYLOAD);
    }

    #[test(core = @0x1, owner = @0x123)]
    public entry fun test_create_transaction_with_hashes(
        core: &signer, owner: &signer) acquires MultisigAccount {
        setup(core);
        create_account_for_test(address_of(owner));
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[address_of(owner)], 1);
        create_transaction_with_hash(owner, multisig_account, sha3_256(PAYLOAD));
    }

    #[test(core = @0x1, owner = @0x123)]
    #[expected_failure(abort_code = 0x1000C, location = Self)]
    public entry fun test_create_transaction_with_empty_hash_should_fail(
        core: &signer, owner: &signer) acquires MultisigAccount {
        setup(core);
        create_account_for_test(address_of(owner));
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[address_of(owner)], 1);
        create_transaction_with_hash(owner, multisig_account, vector[]);
    }

    #[test(core = @0x1, owner = @0x123, non_owner = @0x124)]
    #[expected_failure(abort_code = 0x507D3, location = Self)]
    public entry fun test_create_transaction_with_hashes_and_non_owner_should_fail(
        core: &signer, owner: &signer, non_owner: &signer) acquires MultisigAccount {
        setup(core);
        create_account_for_test(address_of(owner));
        let multisig_account = @0x1111;
        create_account_for_test(multisig_account);
        create_transaction_with_hash(non_owner, multisig_account, sha3_256(PAYLOAD));
    }

    #[test(core = @0x1, owner_1 = @0x123, owner_2 = @0x124, owner_3 = @0x125)]
    public entry fun test_approve_transaction(
        core: &signer, owner_1: &signer, owner_2: &signer, owner_3: &signer) acquires MultisigAccount {
        setup(core);
        let owner_1_addr = address_of(owner_1);
        let owner_2_addr = address_of(owner_2);
        let owner_3_addr = address_of(owner_3);
        create_account_for_test(owner_1_addr);
        create_account_for_test(owner_2_addr);
        create_account_for_test(owner_3_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_1_addr, owner_2_addr, owner_3_addr], 2);

        create_transaction(owner_1, multisig_account, PAYLOAD);
        approve_transaction(owner_2, multisig_account, 1);
        approve_transaction(owner_3, multisig_account, 1);
        let transaction = get_transaction(multisig_account, 1);
        assert!(simple_map::length(&transaction.votes) == 3, 0);
        assert!(*simple_map::borrow(&transaction.votes, &owner_1_addr), 1);
        assert!(*simple_map::borrow(&transaction.votes, &owner_2_addr), 2);
        assert!(*simple_map::borrow(&transaction.votes, &owner_3_addr), 3);
    }

    #[test(core = @0x1, owner_1 = @0x123, owner_2 = @0x124, owner_3 = @0x125)]
    public entry fun test_validate_transaction_should_not_consider_removed_owners(
        core: &signer, owner_1: &signer, owner_2: &signer, owner_3:& signer) acquires MultisigAccount {
        setup(core);
        let owner_1_addr = address_of(owner_1);
        let owner_2_addr = address_of(owner_2);
        let owner_3_addr = address_of(owner_3);
        create_account_for_test(owner_1_addr);
        create_account_for_test(owner_2_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_1_addr, owner_2_addr, owner_3_addr], 2);

        // Owner 1 and 2 approved but then owner 1 got removed.
        create_transaction(owner_1, multisig_account, PAYLOAD);
        approve_transaction(owner_2, multisig_account, 1);
        // Before owner 1 is removed, the transaction technically has sufficient approvals.
        assert!(can_be_executed(multisig_account, 1), 0);
        account::set_authentication_key_for_test(multisig_account, vector[owner_2_addr, owner_3_addr], 2);
        // Now that owner 1 is removed, their approval should be invalidated and the transaction no longer
        // has enough approvals to be executed.
        assert!(!can_be_executed(multisig_account, 1), 1);
    }

    #[test(core = @0x1, owner = @0x123)]
    #[expected_failure(abort_code = 0x607D6, location = Self)]
    public entry fun test_approve_transaction_with_invalid_sequence_number_should_fail(
        core: &signer, owner: &signer) acquires MultisigAccount {
        setup(core);
        create_account_for_test(address_of(owner));
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[address_of(owner)], 1);
        // Transaction is created with id 1.
        create_transaction(owner, multisig_account, PAYLOAD);
        approve_transaction(owner, multisig_account, 2);
    }

    #[test(core = @0x1, owner = @0x123, non_owner = @0x124)]
    #[expected_failure(abort_code = 0x507D3, location = Self)]
    public entry fun test_approve_transaction_with_non_owner_should_fail(
        core: &signer, owner: &signer, non_owner: &signer) acquires MultisigAccount {
        setup(core);
        create_account_for_test(address_of(owner));
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[address_of(owner)], 1);
        // Transaction is created with id 1.
        create_transaction(owner, multisig_account, PAYLOAD);
        approve_transaction(non_owner, multisig_account, 1);
    }

    #[test(core = @0x1, owner = @0x123)]
    public entry fun test_approval_transaction_after_rejecting(
        core: &signer, owner: &signer) acquires MultisigAccount {
        setup(core);
        let owner_addr = address_of(owner);
        create_account_for_test(owner_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[address_of(owner)], 1);

        create_transaction(owner, multisig_account, PAYLOAD);
        reject_transaction(owner, multisig_account, 1);
        approve_transaction(owner, multisig_account, 1);
        let transaction = get_transaction(multisig_account, 1);
        assert!(*simple_map::borrow(&transaction.votes, &owner_addr), 1);
    }

    #[test(core = @0x1, owner_1 = @0x123, owner_2 = @0x124, owner_3 = @0x125)]
    public entry fun test_reject_transaction(
        core: &signer, owner_1: &signer, owner_2: &signer, owner_3: &signer) acquires MultisigAccount {
        setup(core);
        let owner_1_addr = address_of(owner_1);
        let owner_2_addr = address_of(owner_2);
        let owner_3_addr = address_of(owner_3);
        create_account_for_test(owner_1_addr);
        create_account_for_test(owner_2_addr);
        create_account_for_test(owner_3_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_1_addr, owner_2_addr, owner_3_addr], 2);

        create_transaction(owner_1, multisig_account, PAYLOAD);
        reject_transaction(owner_1, multisig_account, 1);
        reject_transaction(owner_2, multisig_account, 1);
        reject_transaction(owner_3, multisig_account, 1);
        let transaction = get_transaction(multisig_account, 1);
        assert!(simple_map::length(&transaction.votes) == 3, 0);
        assert!(!*simple_map::borrow(&transaction.votes, &owner_1_addr), 1);
        assert!(!*simple_map::borrow(&transaction.votes, &owner_2_addr), 2);
        assert!(!*simple_map::borrow(&transaction.votes, &owner_3_addr), 3);
    }

    #[test(core = @0x1, owner = @0x123)]
    public entry fun test_reject_transaction_after_approving(
        core: &signer, owner: &signer) acquires MultisigAccount {
        setup(core);
        let owner_addr = address_of(owner);
        create_account_for_test(owner_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_addr], 1);

        create_transaction(owner, multisig_account, PAYLOAD);
        reject_transaction(owner, multisig_account, 1);
        let transaction = get_transaction(multisig_account, 1);
        assert!(!*simple_map::borrow(&transaction.votes, &owner_addr), 1);
    }

    #[test(core = @0x1, owner = @0x123)]
    #[expected_failure(abort_code = 0x607D6, location = Self)]
    public entry fun test_reject_transaction_with_invalid_sequence_number_should_fail(
        core: &signer, owner: &signer) acquires MultisigAccount {
        setup(core);
        create_account_for_test(address_of(owner));
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[address_of(owner)], 1);
        // Transaction is created with id 1.
        create_transaction(owner, multisig_account, PAYLOAD);
        reject_transaction(owner, multisig_account, 2);
    }

    #[test(core = @0x1, owner = @0x123, non_owner = @0x124)]
    #[expected_failure(abort_code = 0x507D3, location = Self)]
    public entry fun test_reject_transaction_with_non_owner_should_fail(
        core: &signer, owner: &signer, non_owner: &signer) acquires MultisigAccount {
        setup(core);
        create_account_for_test(address_of(owner));
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[address_of(owner)], 1);
        create_transaction(owner, multisig_account, PAYLOAD);
        reject_transaction(non_owner, multisig_account, 1);
    }

    #[test(core = @0x1, owner_1 = @0x123, owner_2 = @0x124, owner_3 = @0x125)]
    public entry fun test_execute_transaction_successful(
        core: &signer, owner_1: &signer, owner_2: &signer, owner_3: &signer) acquires MultisigAccount {
        setup(core);
        let owner_1_addr = address_of(owner_1);
        let owner_2_addr = address_of(owner_2);
        let owner_3_addr = address_of(owner_3);
        create_account_for_test(owner_1_addr);
        create_account_for_test(owner_2_addr);
        create_account_for_test(owner_3_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_1_addr, owner_2_addr, owner_3_addr], 2);

        create_transaction(owner_1, multisig_account, PAYLOAD);
        // Owner 1 doesn't need to explicitly approve as they created the transaction.
        approve_transaction(owner_2, multisig_account, 1);
        assert!(can_be_executed(multisig_account, 1), 1);
        assert!(table::contains(&borrow_global<MultisigAccount>(multisig_account).transactions, 1), 0);
        successful_transaction_execution_cleanup(owner_3_addr, multisig_account,vector[]);
    }

    #[test(core = @0x1, owner_1 = @0x123, owner_2 = @0x124, owner_3 = @0x125)]
    public entry fun test_execute_transaction_failed(
        core: &signer, owner_1: &signer, owner_2: &signer, owner_3: &signer) acquires MultisigAccount {
        setup(core);
        let owner_1_addr = address_of(owner_1);
        let owner_2_addr = address_of(owner_2);
        let owner_3_addr = address_of(owner_3);
        create_account_for_test(owner_1_addr);
        create_account_for_test(owner_2_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_1_addr, owner_2_addr, owner_3_addr], 2);

        create_transaction(owner_1, multisig_account, PAYLOAD);
        // Owner 1 doesn't need to explicitly approve as they created the transaction.
        approve_transaction(owner_2, multisig_account, 1);
        assert!(can_be_executed(multisig_account, 1), 1);
        assert!(table::contains(&borrow_global<MultisigAccount>(multisig_account).transactions, 1), 0);
        failed_transaction_execution_cleanup(owner_3_addr, multisig_account,vector[], execution_error());
    }

    #[test(core = @0x1, owner_1 = @0x123, owner_2 = @0x124, owner_3 = @0x125)]
    public entry fun test_execute_transaction_with_full_payload(
        core: &signer, owner_1: &signer, owner_2: &signer, owner_3: &signer) acquires MultisigAccount {
        setup(core);
        let owner_1_addr = address_of(owner_1);
        let owner_2_addr = address_of(owner_2);
        let owner_3_addr = address_of(owner_3);
        create_account_for_test(owner_1_addr);
        create_account_for_test(owner_3_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_1_addr, owner_2_addr, owner_3_addr], 2);

        create_transaction_with_hash(owner_3, multisig_account, sha3_256(PAYLOAD));
        // Owner 3 doesn't need to explicitly approve as they created the transaction.
        approve_transaction(owner_1, multisig_account, 1);
        assert!(can_be_executed(multisig_account, 1), 1);
        assert!(table::contains(&borrow_global<MultisigAccount>(multisig_account).transactions, 1), 0);
        successful_transaction_execution_cleanup(owner_3_addr, multisig_account, PAYLOAD);
    }

    #[test(core = @0x1, owner_1 = @0x123, owner_2 = @0x124, owner_3 = @0x125)]
    public entry fun test_execute_rejected_transaction(
        core: &signer, owner_1: &signer, owner_2: &signer, owner_3: &signer) acquires MultisigAccount {
        setup(core);
        let owner_1_addr = address_of(owner_1);
        let owner_2_addr = address_of(owner_2);
        let owner_3_addr = address_of(owner_3);
        create_account_for_test(owner_1_addr);
        create_account_for_test(owner_2_addr);
        create_account_for_test(owner_3_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_1_addr, owner_2_addr, owner_3_addr], 2);

        create_transaction(owner_1, multisig_account, PAYLOAD);
        reject_transaction(owner_2, multisig_account, 1);
        reject_transaction(owner_3, multisig_account, 1);
        assert!(can_be_rejected(multisig_account, 1), 1);
        assert!(table::contains(&borrow_global<MultisigAccount>(multisig_account).transactions, 1), 0);
        execute_rejected_transaction(owner_3, multisig_account);
    }

    #[test(core = @0x1, owner = @0x123, non_owner = @0x124)]
    #[expected_failure(abort_code = 0x507D3, location = Self)]
    public entry fun test_execute_rejected_transaction_with_non_owner_should_fail(
        core: &signer, owner: &signer, non_owner: &signer) acquires MultisigAccount {
        setup(core);
        create_account_for_test(address_of(owner));
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[address_of(owner)], 1);

        create_transaction(owner, multisig_account, PAYLOAD);
        reject_transaction(owner, multisig_account, 1);
        execute_rejected_transaction(non_owner, multisig_account);
    }

    #[test(core = @0x1, owner_1 = @0x123, owner_2 = @0x124, owner_3 = @0x125)]
    #[expected_failure(abort_code = 0x3000A, location = Self)]
    public entry fun test_execute_rejected_transaction_without_sufficient_rejections_should_fail(
        core: &signer, owner_1: &signer, owner_2: &signer, owner_3: &signer) acquires MultisigAccount {
        setup(core);
        let owner_1_addr = address_of(owner_1);
        let owner_2_addr = address_of(owner_2);
        let owner_3_addr = address_of(owner_3);
        create_account_for_test(owner_1_addr);
        create_account_for_test(owner_2_addr);
        create_account_for_test(owner_3_addr);
        let multisig_account = @0x1111;
        account::set_authentication_key_for_test(multisig_account, vector[owner_1_addr, owner_2_addr, owner_3_addr], 2);

        create_transaction(owner_1, multisig_account, PAYLOAD);
        reject_transaction(owner_2, multisig_account, 1);
        execute_rejected_transaction(owner_3, multisig_account);
    }
}


<a id="0x1_multisig_account"></a>

# Module `0x1::multisig_account`

Enhanced multisig account standard on Endless. This is different from the native multisig scheme support enforced via
the account's auth key.

This module allows creating a flexible and powerful multisig account with seamless support for updating owners
without changing the auth key. Users can choose to store transaction payloads waiting for owner signatures on chain
or off chain (primary consideration is decentralization/transparency vs gas cost).

The multisig account is a resource account underneath. By default, it has no auth key and can only be controlled via
the special multisig transaction flow. However, owners can create a transaction to change the auth key to match a
private key off chain if so desired.

Transactions need to be executed in order of creation, similar to transactions for a normal Endless account (enforced
with account nonce).

The flow is like below:
1. Owners can create a new multisig account by calling create (signer is default single owner) or with
create_with_owners where multiple initial owner addresses can be specified. This is different (and easier) from
the native multisig scheme where the owners' public keys have to be specified. Here, only addresses are needed.
2. Owners can be added/removed any time by calling add_owners or remove_owners. The transactions to do still need
to follow the k-of-n scheme specified for the multisig account.
3. To create a new transaction, an owner can call create_transaction with the transaction payload. This will store
the full transaction payload on chain, which adds decentralization (censorship is not possible as the data is
available on chain) and makes it easier to fetch all transactions waiting for execution. If saving gas is desired,
an owner can alternatively call create_transaction_with_hash where only the payload hash is stored. Later execution
will be verified using the hash. Only owners can create transactions and a transaction id (incremeting id) will be
assigned.
4. To approve or reject a transaction, other owners can call approve() or reject() with the transaction id.
5. If there are enough approvals, any owner can execute the transaction using the special MultisigTransaction type
with the transaction id if the full payload is already stored on chain or with the transaction payload if only a
hash is stored. Transaction execution will first check with this module that the transaction payload has gotten
enough signatures. If so, it will be executed as the multisig account. The owner who executes will pay for gas.
6. If there are enough rejections, any owner can finalize the rejection by calling execute_rejected_transaction().

Note that this multisig account model is not designed to use with a large number of owners. The more owners there
are, the more expensive voting on transactions will become. If a large number of owners is designed, such as in a
flat governance structure, clients are encouraged to write their own modules on top of this multisig account module
and implement the governance voting logic on top.


-  [Resource `MultisigAccount`](#0x1_multisig_account_MultisigAccount)
-  [Struct `MultisigTransaction`](#0x1_multisig_account_MultisigTransaction)
-  [Struct `ExecutionError`](#0x1_multisig_account_ExecutionError)
-  [Struct `MultisigAccountCreationMessage`](#0x1_multisig_account_MultisigAccountCreationMessage)
-  [Struct `MultisigAccountCreationWithAuthKeyRevocationMessage`](#0x1_multisig_account_MultisigAccountCreationWithAuthKeyRevocationMessage)
-  [Struct `AddOwnersEvent`](#0x1_multisig_account_AddOwnersEvent)
-  [Struct `RemoveOwnersEvent`](#0x1_multisig_account_RemoveOwnersEvent)
-  [Struct `UpdateSignaturesRequiredEvent`](#0x1_multisig_account_UpdateSignaturesRequiredEvent)
-  [Struct `CreateTransactionEvent`](#0x1_multisig_account_CreateTransactionEvent)
-  [Struct `VoteEvent`](#0x1_multisig_account_VoteEvent)
-  [Struct `ExecuteRejectedTransactionEvent`](#0x1_multisig_account_ExecuteRejectedTransactionEvent)
-  [Struct `TransactionExecutionSucceededEvent`](#0x1_multisig_account_TransactionExecutionSucceededEvent)
-  [Struct `TransactionExecutionFailedEvent`](#0x1_multisig_account_TransactionExecutionFailedEvent)
-  [Struct `MetadataUpdatedEvent`](#0x1_multisig_account_MetadataUpdatedEvent)
-  [Constants](#@Constants_0)
-  [Function `get_transaction`](#0x1_multisig_account_get_transaction)
-  [Function `get_pending_transactions`](#0x1_multisig_account_get_pending_transactions)
-  [Function `get_next_transaction_payload`](#0x1_multisig_account_get_next_transaction_payload)
-  [Function `can_be_executed`](#0x1_multisig_account_can_be_executed)
-  [Function `can_be_rejected`](#0x1_multisig_account_can_be_rejected)
-  [Function `last_resolved_sequence_number`](#0x1_multisig_account_last_resolved_sequence_number)
-  [Function `next_sequence_number`](#0x1_multisig_account_next_sequence_number)
-  [Function `vote`](#0x1_multisig_account_vote)
-  [Function `create_transaction`](#0x1_multisig_account_create_transaction)
-  [Function `create_transaction_with_hash`](#0x1_multisig_account_create_transaction_with_hash)
-  [Function `approve_transaction`](#0x1_multisig_account_approve_transaction)
-  [Function `reject_transaction`](#0x1_multisig_account_reject_transaction)
-  [Function `vote_transanction`](#0x1_multisig_account_vote_transanction)
-  [Function `execute_rejected_transaction`](#0x1_multisig_account_execute_rejected_transaction)
-  [Function `validate_multisig_transaction`](#0x1_multisig_account_validate_multisig_transaction)
-  [Function `successful_transaction_execution_cleanup`](#0x1_multisig_account_successful_transaction_execution_cleanup)
-  [Function `failed_transaction_execution_cleanup`](#0x1_multisig_account_failed_transaction_execution_cleanup)
-  [Function `remove_executed_transaction`](#0x1_multisig_account_remove_executed_transaction)
-  [Function `add_transaction`](#0x1_multisig_account_add_transaction)
-  [Function `get_owners`](#0x1_multisig_account_get_owners)
-  [Function `assert_is_owner`](#0x1_multisig_account_assert_is_owner)
-  [Function `num_approvals_and_rejections`](#0x1_multisig_account_num_approvals_and_rejections)
-  [Function `assert_multisig_account_exists`](#0x1_multisig_account_assert_multisig_account_exists)
-  [Function `assert_account_exists`](#0x1_multisig_account_assert_account_exists)


<pre><code><b>use</b> <a href="account.md#0x1_account">0x1::account</a>;
<b>use</b> <a href="create_signer.md#0x1_create_signer">0x1::create_signer</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="event.md#0x1_event">0x1::event</a>;
<b>use</b> <a href="../../endless-stdlib/doc/from_bcs.md#0x1_from_bcs">0x1::from_bcs</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">0x1::hash</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map">0x1::simple_map</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="../../endless-stdlib/doc/table.md#0x1_table">0x1::table</a>;
<b>use</b> <a href="timestamp.md#0x1_timestamp">0x1::timestamp</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">0x1::vector</a>;
</code></pre>



<a id="0x1_multisig_account_MultisigAccount"></a>

## Resource `MultisigAccount`

Represents a multisig account's configurations and transactions.
This will be stored in the multisig account (created as a resource account separate from any owner accounts).


<pre><code><b>struct</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>transactions: <a href="../../endless-stdlib/doc/table.md#0x1_table_Table">table::Table</a>&lt;u64, <a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">multisig_account::MultisigTransaction</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>last_executed_sequence_number: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>next_sequence_number: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_MultisigTransaction"></a>

## Struct `MultisigTransaction`

A transaction to be executed in a multisig account.
This must contain either the full transaction payload or its hash (stored as bytes).


<pre><code><b>struct</b> <a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">MultisigTransaction</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>payload: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>payload_hash: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>votes: <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_SimpleMap">simple_map::SimpleMap</a>&lt;<b>address</b>, bool&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>creator: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>creation_time_secs: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_ExecutionError"></a>

## Struct `ExecutionError`

Contains information about execution failure.


<pre><code><b>struct</b> <a href="multisig_account.md#0x1_multisig_account_ExecutionError">ExecutionError</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>abort_location: <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>error_type: <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>error_code: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_MultisigAccountCreationMessage"></a>

## Struct `MultisigAccountCreationMessage`

Used only for verifying multisig account creation on top of existing accounts.


<pre><code><b>struct</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccountCreationMessage">MultisigAccountCreationMessage</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="chain_id.md#0x1_chain_id">chain_id</a>: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>account_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>sequence_number: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>owners: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>num_signatures_required: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_MultisigAccountCreationWithAuthKeyRevocationMessage"></a>

## Struct `MultisigAccountCreationWithAuthKeyRevocationMessage`

Used only for verifying multisig account creation on top of existing accounts and rotating the auth key to 0x0.


<pre><code><b>struct</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccountCreationWithAuthKeyRevocationMessage">MultisigAccountCreationWithAuthKeyRevocationMessage</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="chain_id.md#0x1_chain_id">chain_id</a>: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>account_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>sequence_number: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>owners: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>num_signatures_required: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_AddOwnersEvent"></a>

## Struct `AddOwnersEvent`

Event emitted when new owners are added to the multisig account.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="multisig_account.md#0x1_multisig_account_AddOwnersEvent">AddOwnersEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>owners_added: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_RemoveOwnersEvent"></a>

## Struct `RemoveOwnersEvent`

Event emitted when new owners are removed from the multisig account.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="multisig_account.md#0x1_multisig_account_RemoveOwnersEvent">RemoveOwnersEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>owners_removed: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_UpdateSignaturesRequiredEvent"></a>

## Struct `UpdateSignaturesRequiredEvent`

Event emitted when the number of signatures required is updated.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="multisig_account.md#0x1_multisig_account_UpdateSignaturesRequiredEvent">UpdateSignaturesRequiredEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>old_num_signatures_required: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>new_num_signatures_required: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_CreateTransactionEvent"></a>

## Struct `CreateTransactionEvent`

Event emitted when a transaction is created.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="multisig_account.md#0x1_multisig_account_CreateTransactionEvent">CreateTransactionEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>creator: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>sequence_number: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>transaction: <a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">multisig_account::MultisigTransaction</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_VoteEvent"></a>

## Struct `VoteEvent`

Event emitted when an owner approves or rejects a transaction.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="multisig_account.md#0x1_multisig_account_VoteEvent">VoteEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>sequence_number: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>approved: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_ExecuteRejectedTransactionEvent"></a>

## Struct `ExecuteRejectedTransactionEvent`

Event emitted when a transaction is officially rejected because the number of rejections has reached the
number of signatures required.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="multisig_account.md#0x1_multisig_account_ExecuteRejectedTransactionEvent">ExecuteRejectedTransactionEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>sequence_number: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>num_rejections: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>executor: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_TransactionExecutionSucceededEvent"></a>

## Struct `TransactionExecutionSucceededEvent`

Event emitted when a transaction is executed.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="multisig_account.md#0x1_multisig_account_TransactionExecutionSucceededEvent">TransactionExecutionSucceededEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>executor: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>sequence_number: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>transaction_payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>num_approvals: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_TransactionExecutionFailedEvent"></a>

## Struct `TransactionExecutionFailedEvent`

Event emitted when a transaction's execution failed.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="multisig_account.md#0x1_multisig_account_TransactionExecutionFailedEvent">TransactionExecutionFailedEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>executor: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>sequence_number: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>transaction_payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>num_approvals: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>execution_error: <a href="multisig_account.md#0x1_multisig_account_ExecutionError">multisig_account::ExecutionError</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_multisig_account_MetadataUpdatedEvent"></a>

## Struct `MetadataUpdatedEvent`

Event emitted when a transaction's metadata is updated.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="multisig_account.md#0x1_multisig_account_MetadataUpdatedEvent">MetadataUpdatedEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>old_metadata: <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_SimpleMap">simple_map::SimpleMap</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>new_metadata: <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_SimpleMap">simple_map::SimpleMap</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_multisig_account_DOMAIN_SEPARATOR"></a>

The salt used to create a resource account during multisig account creation.
This is used to avoid conflicts with other modules that also create resource accounts with the same owner
account.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_DOMAIN_SEPARATOR">DOMAIN_SEPARATOR</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [101, 110, 100, 108, 101, 115, 115, 95, 102, 114, 97, 109, 101, 119, 111, 114, 107, 58, 58, 109, 117, 108, 116, 105, 115, 105, 103, 95, 97, 99, 99, 111, 117, 110, 116];
</code></pre>



<a id="0x1_multisig_account_EACCOUNT_NOT_MULTISIG"></a>

Specified account is not a multisig account.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EACCOUNT_NOT_MULTISIG">EACCOUNT_NOT_MULTISIG</a>: u64 = 2002;
</code></pre>



<a id="0x1_multisig_account_EDUPLICATE_METADATA_KEY"></a>

The specified metadata contains duplicate attributes (keys).


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EDUPLICATE_METADATA_KEY">EDUPLICATE_METADATA_KEY</a>: u64 = 16;
</code></pre>



<a id="0x1_multisig_account_EDUPLICATE_OWNER"></a>

Owner list cannot contain the same address more than once.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EDUPLICATE_OWNER">EDUPLICATE_OWNER</a>: u64 = 1;
</code></pre>



<a id="0x1_multisig_account_EINVALID_PAYLOAD_HASH"></a>

Payload hash must be exactly 32 bytes (sha3-256).


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EINVALID_PAYLOAD_HASH">EINVALID_PAYLOAD_HASH</a>: u64 = 12;
</code></pre>



<a id="0x1_multisig_account_EINVALID_SEQUENCE_NUMBER"></a>

The sequence number provided is invalid. It must be between [1, next pending transaction - 1].


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EINVALID_SEQUENCE_NUMBER">EINVALID_SEQUENCE_NUMBER</a>: u64 = 17;
</code></pre>



<a id="0x1_multisig_account_EINVALID_SIGNATURES_REQUIRED"></a>

Number of signatures required must be more than zero and at most the total number of owners.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EINVALID_SIGNATURES_REQUIRED">EINVALID_SIGNATURES_REQUIRED</a>: u64 = 11;
</code></pre>



<a id="0x1_multisig_account_EMULTISIG_ACCOUNTS_NOT_ENABLED_YET"></a>

Multisig accounts has not been enabled on this current network yet.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EMULTISIG_ACCOUNTS_NOT_ENABLED_YET">EMULTISIG_ACCOUNTS_NOT_ENABLED_YET</a>: u64 = 14;
</code></pre>



<a id="0x1_multisig_account_ENOT_ENOUGH_APPROVALS"></a>

Transaction has not received enough approvals to be executed.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_ENOT_ENOUGH_APPROVALS">ENOT_ENOUGH_APPROVALS</a>: u64 = 2009;
</code></pre>



<a id="0x1_multisig_account_ENOT_ENOUGH_OWNERS"></a>

Multisig account must have at least one owner.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_ENOT_ENOUGH_OWNERS">ENOT_ENOUGH_OWNERS</a>: u64 = 5;
</code></pre>



<a id="0x1_multisig_account_ENOT_ENOUGH_REJECTIONS"></a>

Transaction has not received enough rejections to be officially rejected.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_ENOT_ENOUGH_REJECTIONS">ENOT_ENOUGH_REJECTIONS</a>: u64 = 10;
</code></pre>



<a id="0x1_multisig_account_ENOT_OWNER"></a>

Account executing this operation is not an owner of the multisig account.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_ENOT_OWNER">ENOT_OWNER</a>: u64 = 2003;
</code></pre>



<a id="0x1_multisig_account_ENUMBER_OF_METADATA_KEYS_AND_VALUES_DONT_MATCH"></a>

The number of metadata keys and values don't match.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_ENUMBER_OF_METADATA_KEYS_AND_VALUES_DONT_MATCH">ENUMBER_OF_METADATA_KEYS_AND_VALUES_DONT_MATCH</a>: u64 = 15;
</code></pre>



<a id="0x1_multisig_account_EOWNERS_TO_REMOVE_NEW_OWNERS_OVERLAP"></a>

Provided owners to remove and new owners overlap.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EOWNERS_TO_REMOVE_NEW_OWNERS_OVERLAP">EOWNERS_TO_REMOVE_NEW_OWNERS_OVERLAP</a>: u64 = 18;
</code></pre>



<a id="0x1_multisig_account_EOWNER_CANNOT_BE_MULTISIG_ACCOUNT_ITSELF"></a>

The multisig account itself cannot be an owner.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EOWNER_CANNOT_BE_MULTISIG_ACCOUNT_ITSELF">EOWNER_CANNOT_BE_MULTISIG_ACCOUNT_ITSELF</a>: u64 = 13;
</code></pre>



<a id="0x1_multisig_account_EPAYLOAD_CANNOT_BE_EMPTY"></a>

Transaction payload cannot be empty.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EPAYLOAD_CANNOT_BE_EMPTY">EPAYLOAD_CANNOT_BE_EMPTY</a>: u64 = 4;
</code></pre>



<a id="0x1_multisig_account_EPAYLOAD_DOES_NOT_MATCH_HASH"></a>

Provided target function does not match the hash stored in the on-chain transaction.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_EPAYLOAD_DOES_NOT_MATCH_HASH">EPAYLOAD_DOES_NOT_MATCH_HASH</a>: u64 = 2008;
</code></pre>



<a id="0x1_multisig_account_ETRANSACTION_NOT_FOUND"></a>

Transaction with specified id cannot be found.


<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_ETRANSACTION_NOT_FOUND">ETRANSACTION_NOT_FOUND</a>: u64 = 2006;
</code></pre>



<a id="0x1_multisig_account_ZERO_AUTH_KEY"></a>



<pre><code><b>const</b> <a href="multisig_account.md#0x1_multisig_account_ZERO_AUTH_KEY">ZERO_AUTH_KEY</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
</code></pre>



<a id="0x1_multisig_account_get_transaction"></a>

## Function `get_transaction`

Return the transaction with the given transaction id.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_get_transaction">get_transaction</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64): <a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">multisig_account::MultisigTransaction</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_get_transaction">get_transaction</a>(
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>,
    sequence_number: u64,
): <a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">MultisigTransaction</a> <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>let</b> multisig_account_resource = <b>borrow_global</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>assert</b>!(
        sequence_number &gt; 0 && sequence_number &lt; multisig_account_resource.next_sequence_number,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="multisig_account.md#0x1_multisig_account_EINVALID_SEQUENCE_NUMBER">EINVALID_SEQUENCE_NUMBER</a>),
    );
    *<a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(&multisig_account_resource.transactions, sequence_number)
}
</code></pre>



</details>

<a id="0x1_multisig_account_get_pending_transactions"></a>

## Function `get_pending_transactions`

Return all pending transactions.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_get_pending_transactions">get_pending_transactions</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">multisig_account::MultisigTransaction</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_get_pending_transactions">get_pending_transactions</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">MultisigTransaction</a>&gt; <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>let</b> pending_transactions: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">MultisigTransaction</a>&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[];
    <b>let</b> <a href="multisig_account.md#0x1_multisig_account">multisig_account</a> = <b>borrow_global</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> i = <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>.last_executed_sequence_number + 1;
    <b>let</b> next_sequence_number = <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>.next_sequence_number;
    <b>while</b> (i &lt; next_sequence_number) {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> pending_transactions, *<a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(&<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>.transactions, i));
        i = i + 1;
    };
    pending_transactions
}
</code></pre>



</details>

<a id="0x1_multisig_account_get_next_transaction_payload"></a>

## Function `get_next_transaction_payload`

Return the payload for the next transaction in the queue.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_get_next_transaction_payload">get_next_transaction_payload</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, provided_payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_get_next_transaction_payload">get_next_transaction_payload</a>(
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, provided_payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt; <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>let</b> multisig_account_resource = <b>borrow_global</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> sequence_number = multisig_account_resource.last_executed_sequence_number + 1;
    <b>let</b> transaction = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(&multisig_account_resource.transactions, sequence_number);

    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&transaction.payload)) {
        *<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&transaction.payload)
    } <b>else</b> {
        provided_payload
    }
}
</code></pre>



</details>

<a id="0x1_multisig_account_can_be_executed"></a>

## Function `can_be_executed`

Return true if the transaction with given transaction id can be executed now.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_can_be_executed">can_be_executed</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_can_be_executed">can_be_executed</a>(
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64): bool <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>let</b> multisig_account_resource = <b>borrow_global</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>assert</b>!(
        sequence_number &gt; 0 && sequence_number &lt; multisig_account_resource.next_sequence_number,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="multisig_account.md#0x1_multisig_account_EINVALID_SEQUENCE_NUMBER">EINVALID_SEQUENCE_NUMBER</a>),
    );
    <b>let</b> transaction = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(&multisig_account_resource.transactions, sequence_number);
    <b>let</b> owners = <a href="multisig_account.md#0x1_multisig_account_get_owners">get_owners</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> num_signatures_required = <a href="account.md#0x1_account_num_signatures_required">account::num_signatures_required</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> (num_approvals, _) = <a href="multisig_account.md#0x1_multisig_account_num_approvals_and_rejections">num_approvals_and_rejections</a>(&owners, transaction);
    sequence_number == multisig_account_resource.last_executed_sequence_number + 1 &&
        num_approvals &gt;= num_signatures_required
}
</code></pre>



</details>

<a id="0x1_multisig_account_can_be_rejected"></a>

## Function `can_be_rejected`

Return true if the transaction with given transaction id can be officially rejected.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_can_be_rejected">can_be_rejected</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_can_be_rejected">can_be_rejected</a>(
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64): bool <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>let</b> multisig_account_resource = <b>borrow_global</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>assert</b>!(
        sequence_number &gt; 0 && sequence_number &lt; multisig_account_resource.next_sequence_number,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="multisig_account.md#0x1_multisig_account_EINVALID_SEQUENCE_NUMBER">EINVALID_SEQUENCE_NUMBER</a>),
    );
    <b>let</b> transaction = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(&multisig_account_resource.transactions, sequence_number);
    <b>let</b> owners = <a href="multisig_account.md#0x1_multisig_account_get_owners">get_owners</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> num_signatures_required = <a href="account.md#0x1_account_num_signatures_required">account::num_signatures_required</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> (_, num_rejections) = <a href="multisig_account.md#0x1_multisig_account_num_approvals_and_rejections">num_approvals_and_rejections</a>(&owners, transaction);
    sequence_number == multisig_account_resource.last_executed_sequence_number + 1 &&
        num_rejections &gt;= num_signatures_required
}
</code></pre>



</details>

<a id="0x1_multisig_account_last_resolved_sequence_number"></a>

## Function `last_resolved_sequence_number`

Return the id of the last transaction that was executed (successful or failed) or removed.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_last_resolved_sequence_number">last_resolved_sequence_number</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_last_resolved_sequence_number">last_resolved_sequence_number</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>): u64 <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>let</b> multisig_account_resource = <b>borrow_global_mut</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    multisig_account_resource.last_executed_sequence_number
}
</code></pre>



</details>

<a id="0x1_multisig_account_next_sequence_number"></a>

## Function `next_sequence_number`

Return the id of the next transaction created.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_next_sequence_number">next_sequence_number</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_next_sequence_number">next_sequence_number</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>): u64 <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>let</b> multisig_account_resource = <b>borrow_global_mut</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    multisig_account_resource.next_sequence_number
}
</code></pre>



</details>

<a id="0x1_multisig_account_vote"></a>

## Function `vote`

Return a bool tuple indicating whether an owner has voted and if so, whether they voted yes or no.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_vote">vote</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64, owner: <b>address</b>): (bool, bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_vote">vote</a>(
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64, owner: <b>address</b>): (bool, bool) <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>let</b> multisig_account_resource = <b>borrow_global_mut</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>assert</b>!(
        sequence_number &gt; 0 && sequence_number &lt; multisig_account_resource.next_sequence_number,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="multisig_account.md#0x1_multisig_account_EINVALID_SEQUENCE_NUMBER">EINVALID_SEQUENCE_NUMBER</a>),
    );
    <b>let</b> transaction = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(&multisig_account_resource.transactions, sequence_number);
    <b>let</b> votes = &transaction.votes;
    <b>let</b> voted = <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_contains_key">simple_map::contains_key</a>(votes, &owner);
    <b>let</b> vote = voted && *<a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_borrow">simple_map::borrow</a>(votes, &owner);
    (voted, vote)
}
</code></pre>



</details>

<a id="0x1_multisig_account_create_transaction"></a>

## Function `create_transaction`

Create a multisig transaction, which will have one approval initially (from the creator).


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_create_transaction">create_transaction</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_create_transaction">create_transaction</a>(
    owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>,
    payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&payload) &gt; 0, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="multisig_account.md#0x1_multisig_account_EPAYLOAD_CANNOT_BE_EMPTY">EPAYLOAD_CANNOT_BE_EMPTY</a>));

    <a href="multisig_account.md#0x1_multisig_account_assert_account_exists">assert_account_exists</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>if</b> (!<b>exists</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>)) {
        <b>move_to</b>(&<a href="create_signer.md#0x1_create_signer">create_signer</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>), <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
            transactions: <a href="../../endless-stdlib/doc/table.md#0x1_table_new">table::new</a>(),
            last_executed_sequence_number: 0,
            next_sequence_number: 1,
        });
    };

    <b>let</b> multisig_account_resource = <b>borrow_global_mut</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <a href="multisig_account.md#0x1_multisig_account_assert_is_owner">assert_is_owner</a>(owner, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);

    <b>let</b> creator = address_of(owner);
    <b>let</b> transaction = <a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">MultisigTransaction</a> {
        payload: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(payload),
        payload_hash: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;(),
        votes: <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_create">simple_map::create</a>&lt;<b>address</b>, bool&gt;(),
        creator,
        creation_time_secs: now_seconds(),
    };
    <a href="multisig_account.md#0x1_multisig_account_add_transaction">add_transaction</a>(creator, multisig_account_resource, transaction);
}
</code></pre>



</details>

<a id="0x1_multisig_account_create_transaction_with_hash"></a>

## Function `create_transaction_with_hash`

Create a multisig transaction with a transaction hash instead of the full payload.
This means the payload will be stored off chain for gas saving. Later, during execution, the executor will need
to provide the full payload, which will be validated against the hash stored on-chain.


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_create_transaction_with_hash">create_transaction_with_hash</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, payload_hash: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_create_transaction_with_hash">create_transaction_with_hash</a>(
    owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>,
    payload_hash: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    // Payload <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a> is a sha3-256 <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>, so it must be exactly 32 bytes.
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&payload_hash) == 32, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="multisig_account.md#0x1_multisig_account_EINVALID_PAYLOAD_HASH">EINVALID_PAYLOAD_HASH</a>));

    <a href="multisig_account.md#0x1_multisig_account_assert_account_exists">assert_account_exists</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>if</b> (!<b>exists</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>)) {
        <b>move_to</b>(&<a href="create_signer.md#0x1_create_signer">create_signer</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>), <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
            transactions: <a href="../../endless-stdlib/doc/table.md#0x1_table_new">table::new</a>(),
            last_executed_sequence_number: 0,
            next_sequence_number: 1,
        });
    };
    <b>let</b> multisig_account_resource = <b>borrow_global_mut</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <a href="multisig_account.md#0x1_multisig_account_assert_is_owner">assert_is_owner</a>(owner, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);

    <b>let</b> creator = address_of(owner);
    <b>let</b> transaction = <a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">MultisigTransaction</a> {
        payload: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;(),
        payload_hash: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(payload_hash),
        votes: <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_create">simple_map::create</a>&lt;<b>address</b>, bool&gt;(),
        creator,
        creation_time_secs: now_seconds(),
    };
    <a href="multisig_account.md#0x1_multisig_account_add_transaction">add_transaction</a>(creator, multisig_account_resource, transaction);
}
</code></pre>



</details>

<a id="0x1_multisig_account_approve_transaction"></a>

## Function `approve_transaction`

Approve a multisig transaction.


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_approve_transaction">approve_transaction</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_approve_transaction">approve_transaction</a>(
    owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64) <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <a href="multisig_account.md#0x1_multisig_account_vote_transanction">vote_transanction</a>(owner, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>, sequence_number, <b>true</b>);
}
</code></pre>



</details>

<a id="0x1_multisig_account_reject_transaction"></a>

## Function `reject_transaction`

Reject a multisig transaction.


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_reject_transaction">reject_transaction</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_reject_transaction">reject_transaction</a>(
    owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64) <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <a href="multisig_account.md#0x1_multisig_account_vote_transanction">vote_transanction</a>(owner, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>, sequence_number, <b>false</b>);
}
</code></pre>



</details>

<a id="0x1_multisig_account_vote_transanction"></a>

## Function `vote_transanction`

Generic function that can be used to either approve or reject a multisig transaction


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_vote_transanction">vote_transanction</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64, approved: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_vote_transanction">vote_transanction</a>(
    owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, sequence_number: u64, approved: bool) <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <a href="multisig_account.md#0x1_multisig_account_assert_multisig_account_exists">assert_multisig_account_exists</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> multisig_account_resource = <b>borrow_global_mut</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <a href="multisig_account.md#0x1_multisig_account_assert_is_owner">assert_is_owner</a>(owner, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);

    <b>assert</b>!(
        <a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(&multisig_account_resource.transactions, sequence_number),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="multisig_account.md#0x1_multisig_account_ETRANSACTION_NOT_FOUND">ETRANSACTION_NOT_FOUND</a>),
    );
    <b>let</b> transaction = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow_mut">table::borrow_mut</a>(&<b>mut</b> multisig_account_resource.transactions, sequence_number);
    <b>let</b> votes = &<b>mut</b> transaction.votes;
    <b>let</b> owner_addr = address_of(owner);

    <b>if</b> (<a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_contains_key">simple_map::contains_key</a>(votes, &owner_addr)) {
        *<a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_borrow_mut">simple_map::borrow_mut</a>(votes, &owner_addr) = approved;
    } <b>else</b> {
        <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_add">simple_map::add</a>(votes, owner_addr, approved);
    };

    emit(
        <a href="multisig_account.md#0x1_multisig_account_VoteEvent">VoteEvent</a> {
            owner: owner_addr,
            sequence_number,
            approved,
        }
    );
}
</code></pre>



</details>

<a id="0x1_multisig_account_execute_rejected_transaction"></a>

## Function `execute_rejected_transaction`

Remove the next transaction if it has sufficient owner rejections.


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_execute_rejected_transaction">execute_rejected_transaction</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="multisig_account.md#0x1_multisig_account_execute_rejected_transaction">execute_rejected_transaction</a>(
    owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>,
) <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <a href="multisig_account.md#0x1_multisig_account_assert_multisig_account_exists">assert_multisig_account_exists</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> multisig_account_resource = <b>borrow_global_mut</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <a href="multisig_account.md#0x1_multisig_account_assert_is_owner">assert_is_owner</a>(owner, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> sequence_number = multisig_account_resource.last_executed_sequence_number + 1;
    <b>assert</b>!(
        <a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(&multisig_account_resource.transactions, sequence_number),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="multisig_account.md#0x1_multisig_account_ETRANSACTION_NOT_FOUND">ETRANSACTION_NOT_FOUND</a>),
    );
    <b>let</b> owners = <a href="multisig_account.md#0x1_multisig_account_get_owners">get_owners</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> (_, num_rejections) = <a href="multisig_account.md#0x1_multisig_account_remove_executed_transaction">remove_executed_transaction</a>(multisig_account_resource, &owners);
    <b>let</b> num_signatures_required = <a href="account.md#0x1_account_num_signatures_required">account::num_signatures_required</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>assert</b>!(
        num_rejections &gt;= num_signatures_required,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="multisig_account.md#0x1_multisig_account_ENOT_ENOUGH_REJECTIONS">ENOT_ENOUGH_REJECTIONS</a>),
    );

    emit(
        <a href="multisig_account.md#0x1_multisig_account_ExecuteRejectedTransactionEvent">ExecuteRejectedTransactionEvent</a> {
            sequence_number,
            num_rejections,
            executor: address_of(owner),
        }
    );
}
</code></pre>



</details>

<a id="0x1_multisig_account_validate_multisig_transaction"></a>

## Function `validate_multisig_transaction`

Called by the VM as part of transaction prologue, which is invoked during mempool transaction validation and as
the first step of transaction execution.

Transaction payload is optional if it's already stored on chain for the transaction.


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_validate_multisig_transaction">validate_multisig_transaction</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_validate_multisig_transaction">validate_multisig_transaction</a>(
    owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;) <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <a href="multisig_account.md#0x1_multisig_account_assert_multisig_account_exists">assert_multisig_account_exists</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> multisig_account_resource = <b>borrow_global</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <a href="multisig_account.md#0x1_multisig_account_assert_is_owner">assert_is_owner</a>(owner, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> sequence_number = multisig_account_resource.last_executed_sequence_number + 1;
    <b>assert</b>!(
        <a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(&multisig_account_resource.transactions, sequence_number),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="multisig_account.md#0x1_multisig_account_ETRANSACTION_NOT_FOUND">ETRANSACTION_NOT_FOUND</a>),
    );
    <b>let</b> transaction = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(&multisig_account_resource.transactions, sequence_number);
    <b>let</b> owners = <a href="multisig_account.md#0x1_multisig_account_get_owners">get_owners</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> num_signatures_required = <a href="account.md#0x1_account_num_signatures_required">account::num_signatures_required</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> (num_approvals, _) = <a href="multisig_account.md#0x1_multisig_account_num_approvals_and_rejections">num_approvals_and_rejections</a>(&owners, transaction);
    <b>assert</b>!(
        num_approvals &gt;= num_signatures_required,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="multisig_account.md#0x1_multisig_account_ENOT_ENOUGH_APPROVALS">ENOT_ENOUGH_APPROVALS</a>),
    );

    // If the transaction payload is not stored on chain, verify that the provided payload matches the hashes stored
    // on chain.
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&transaction.payload_hash)) {
        <b>let</b> payload_hash = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&transaction.payload_hash);
        <b>assert</b>!(
            sha3_256(payload) == *payload_hash,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="multisig_account.md#0x1_multisig_account_EPAYLOAD_DOES_NOT_MATCH_HASH">EPAYLOAD_DOES_NOT_MATCH_HASH</a>),
        );
    };
}
</code></pre>



</details>

<a id="0x1_multisig_account_successful_transaction_execution_cleanup"></a>

## Function `successful_transaction_execution_cleanup`

Post-execution cleanup for a successful multisig transaction execution.
This function is private so no other code can call this beside the VM itself as part of MultisigTransaction.


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_successful_transaction_execution_cleanup">successful_transaction_execution_cleanup</a>(executor: <b>address</b>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, transaction_payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_successful_transaction_execution_cleanup">successful_transaction_execution_cleanup</a>(
    executor: <b>address</b>,
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>,
    transaction_payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>let</b> multisig_account_resource = <b>borrow_global_mut</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> owners = <a href="multisig_account.md#0x1_multisig_account_get_owners">get_owners</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> (num_approvals, _) = <a href="multisig_account.md#0x1_multisig_account_remove_executed_transaction">remove_executed_transaction</a>(multisig_account_resource, &owners);
    emit(
        <a href="multisig_account.md#0x1_multisig_account_TransactionExecutionSucceededEvent">TransactionExecutionSucceededEvent</a> {
            sequence_number: multisig_account_resource.last_executed_sequence_number,
            transaction_payload,
            num_approvals,
            executor,
        }
    );
}
</code></pre>



</details>

<a id="0x1_multisig_account_failed_transaction_execution_cleanup"></a>

## Function `failed_transaction_execution_cleanup`

Post-execution cleanup for a failed multisig transaction execution.
This function is private so no other code can call this beside the VM itself as part of MultisigTransaction.


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_failed_transaction_execution_cleanup">failed_transaction_execution_cleanup</a>(executor: <b>address</b>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>, transaction_payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, execution_error: <a href="multisig_account.md#0x1_multisig_account_ExecutionError">multisig_account::ExecutionError</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_failed_transaction_execution_cleanup">failed_transaction_execution_cleanup</a>(
    executor: <b>address</b>,
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>,
    transaction_payload: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    execution_error: <a href="multisig_account.md#0x1_multisig_account_ExecutionError">ExecutionError</a>,
) <b>acquires</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a> {
    <b>let</b> multisig_account_resource = <b>borrow_global_mut</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> owners = <a href="multisig_account.md#0x1_multisig_account_get_owners">get_owners</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> (num_approvals, _) = <a href="multisig_account.md#0x1_multisig_account_remove_executed_transaction">remove_executed_transaction</a>(multisig_account_resource, &owners);
    emit(
        <a href="multisig_account.md#0x1_multisig_account_TransactionExecutionFailedEvent">TransactionExecutionFailedEvent</a> {
            executor,
            sequence_number: multisig_account_resource.last_executed_sequence_number,
            transaction_payload,
            num_approvals,
            execution_error,
        }
    );
}
</code></pre>



</details>

<a id="0x1_multisig_account_remove_executed_transaction"></a>

## Function `remove_executed_transaction`



<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_remove_executed_transaction">remove_executed_transaction</a>(multisig_account_resource: &<b>mut</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">multisig_account::MultisigAccount</a>, owners: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_remove_executed_transaction">remove_executed_transaction</a>(multisig_account_resource: &<b>mut</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>, owners: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;): (u64, u64) {
    <b>let</b> sequence_number = multisig_account_resource.last_executed_sequence_number + 1;
    <b>let</b> transaction = <a href="../../endless-stdlib/doc/table.md#0x1_table_remove">table::remove</a>(&<b>mut</b> multisig_account_resource.transactions, sequence_number);
    multisig_account_resource.last_executed_sequence_number = sequence_number;
    <a href="multisig_account.md#0x1_multisig_account_num_approvals_and_rejections">num_approvals_and_rejections</a>(owners, &transaction)
}
</code></pre>



</details>

<a id="0x1_multisig_account_add_transaction"></a>

## Function `add_transaction`



<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_add_transaction">add_transaction</a>(creator: <b>address</b>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: &<b>mut</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">multisig_account::MultisigAccount</a>, transaction: <a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">multisig_account::MultisigTransaction</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_add_transaction">add_transaction</a>(creator: <b>address</b>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: &<b>mut</b> <a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>, transaction: <a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">MultisigTransaction</a>) {
    // The transaction creator also automatically votes for the transaction.
    <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_add">simple_map::add</a>(&<b>mut</b> transaction.votes, creator, <b>true</b>);

    <b>let</b> sequence_number = <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>.next_sequence_number;
    <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>.next_sequence_number = sequence_number + 1;
    <a href="../../endless-stdlib/doc/table.md#0x1_table_add">table::add</a>(&<b>mut</b> <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>.transactions, sequence_number, transaction);
    emit(
        <a href="multisig_account.md#0x1_multisig_account_CreateTransactionEvent">CreateTransactionEvent</a> { creator, sequence_number, transaction },
    );
}
</code></pre>



</details>

<a id="0x1_multisig_account_get_owners"></a>

## Function `get_owners`



<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_get_owners">get_owners</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_get_owners">get_owners</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt; {
    <b>let</b> authentication_key = <a href="account.md#0x1_account_get_authentication_key">account::get_authentication_key</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
    <b>let</b> owners = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[];
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_reverse">vector::for_each_reverse</a>(authentication_key, |key| {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> owners, <a href="../../endless-stdlib/doc/from_bcs.md#0x1_from_bcs_to_address">from_bcs::to_address</a>(key));
    });
    owners
}
</code></pre>



</details>

<a id="0x1_multisig_account_assert_is_owner"></a>

## Function `assert_is_owner`



<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_assert_is_owner">assert_is_owner</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_assert_is_owner">assert_is_owner</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>) {
    <b>let</b> owner = address_of(owner);
    <b>assert</b>!(<a href="account.md#0x1_account_is_original_account">account::is_original_account</a>(owner), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="multisig_account.md#0x1_multisig_account_ENOT_OWNER">ENOT_OWNER</a>));
    <b>assert</b>!(
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_contains">vector::contains</a>(&<a href="multisig_account.md#0x1_multisig_account_get_owners">get_owners</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>), &owner),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="multisig_account.md#0x1_multisig_account_ENOT_OWNER">ENOT_OWNER</a>),
    );
}
</code></pre>



</details>

<a id="0x1_multisig_account_num_approvals_and_rejections"></a>

## Function `num_approvals_and_rejections`



<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_num_approvals_and_rejections">num_approvals_and_rejections</a>(owners: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, transaction: &<a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">multisig_account::MultisigTransaction</a>): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_num_approvals_and_rejections">num_approvals_and_rejections</a>(owners: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, transaction: &<a href="multisig_account.md#0x1_multisig_account_MultisigTransaction">MultisigTransaction</a>): (u64, u64) {
    <b>let</b> num_approvals = 0;
    <b>let</b> num_rejections = 0;

    <b>let</b> votes = &transaction.votes;
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(owners, |owner| {
        <b>if</b> (<a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_contains_key">simple_map::contains_key</a>(votes, owner)) {
            <b>if</b> (*<a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_borrow">simple_map::borrow</a>(votes, owner)) {
                num_approvals = num_approvals + 1;
            } <b>else</b> {
                num_rejections = num_rejections + 1;
            };
        }
    });

    (num_approvals, num_rejections)
}
</code></pre>



</details>

<a id="0x1_multisig_account_assert_multisig_account_exists"></a>

## Function `assert_multisig_account_exists`



<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_assert_multisig_account_exists">assert_multisig_account_exists</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_assert_multisig_account_exists">assert_multisig_account_exists</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>: <b>address</b>) {
    <b>assert</b>!(<b>exists</b>&lt;<a href="multisig_account.md#0x1_multisig_account_MultisigAccount">MultisigAccount</a>&gt;(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="multisig_account.md#0x1_multisig_account_EACCOUNT_NOT_MULTISIG">EACCOUNT_NOT_MULTISIG</a>));
    <a href="multisig_account.md#0x1_multisig_account_assert_account_exists">assert_account_exists</a>(<a href="multisig_account.md#0x1_multisig_account">multisig_account</a>);
}
</code></pre>



</details>

<a id="0x1_multisig_account_assert_account_exists"></a>

## Function `assert_account_exists`



<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_assert_account_exists">assert_account_exists</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="multisig_account.md#0x1_multisig_account_assert_account_exists">assert_account_exists</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>) {
    <b>assert</b>!(<a href="account.md#0x1_account_exists_at">account::exists_at</a>(<a href="account.md#0x1_account">account</a>),  <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="multisig_account.md#0x1_multisig_account_EACCOUNT_NOT_MULTISIG">EACCOUNT_NOT_MULTISIG</a>));
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY


<a id="0x1_block"></a>

# Module `0x1::block`

This module defines a struct storing the metadata of the block and new block events.


-  [Resource `BlockResource`](#0x1_block_BlockResource)
-  [Resource `CommitHistory`](#0x1_block_CommitHistory)
-  [Struct `NewBlockEvent`](#0x1_block_NewBlockEvent)
-  [Struct `UpdateEpochIntervalEvent`](#0x1_block_UpdateEpochIntervalEvent)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_block_initialize)
-  [Function `initialize_commit_history`](#0x1_block_initialize_commit_history)
-  [Function `update_epoch_interval_microsecs`](#0x1_block_update_epoch_interval_microsecs)
-  [Function `get_epoch_interval_secs`](#0x1_block_get_epoch_interval_secs)
-  [Function `block_prologue_common`](#0x1_block_block_prologue_common)
-  [Function `block_prologue`](#0x1_block_block_prologue)
-  [Function `block_prologue_ext`](#0x1_block_block_prologue_ext)
-  [Function `get_current_block_height`](#0x1_block_get_current_block_height)
-  [Function `emit_new_block_event`](#0x1_block_emit_new_block_event)
-  [Function `emit_genesis_block_event`](#0x1_block_emit_genesis_block_event)
-  [Function `emit_writeset_block_event`](#0x1_block_emit_writeset_block_event)


<pre><code><b>use</b> <a href="account.md#0x1_account">0x1::account</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="event.md#0x1_event">0x1::event</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features">0x1::features</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="randomness.md#0x1_randomness">0x1::randomness</a>;
<b>use</b> <a href="reconfiguration.md#0x1_reconfiguration">0x1::reconfiguration</a>;
<b>use</b> <a href="reconfiguration_with_dkg.md#0x1_reconfiguration_with_dkg">0x1::reconfiguration_with_dkg</a>;
<b>use</b> <a href="stake.md#0x1_stake">0x1::stake</a>;
<b>use</b> <a href="state_storage.md#0x1_state_storage">0x1::state_storage</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
<b>use</b> <a href="../../endless-stdlib/doc/table_with_length.md#0x1_table_with_length">0x1::table_with_length</a>;
<b>use</b> <a href="timestamp.md#0x1_timestamp">0x1::timestamp</a>;
<b>use</b> <a href="transaction_fee.md#0x1_transaction_fee">0x1::transaction_fee</a>;
</code></pre>



<a id="0x1_block_BlockResource"></a>

## Resource `BlockResource`

Should be in-sync with BlockResource rust struct in new_block.rs


<pre><code><b>struct</b> <a href="block.md#0x1_block_BlockResource">BlockResource</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>height: u64</code>
</dt>
<dd>
 Height of the current block
</dd>
<dt>
<code>epoch_interval: u64</code>
</dt>
<dd>
 Time period between epochs.
</dd>
<dt>
<code>new_block_events: <a href="event.md#0x1_event_EventHandle">event::EventHandle</a>&lt;<a href="block.md#0x1_block_NewBlockEvent">block::NewBlockEvent</a>&gt;</code>
</dt>
<dd>
 Handle where events with the time of new blocks are emitted
</dd>
<dt>
<code>update_epoch_interval_events: <a href="event.md#0x1_event_EventHandle">event::EventHandle</a>&lt;<a href="block.md#0x1_block_UpdateEpochIntervalEvent">block::UpdateEpochIntervalEvent</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_block_CommitHistory"></a>

## Resource `CommitHistory`

Store new block events as a move resource, internally using a circular buffer.


<pre><code><b>struct</b> <a href="block.md#0x1_block_CommitHistory">CommitHistory</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>max_capacity: u32</code>
</dt>
<dd>

</dd>
<dt>
<code>next_idx: u32</code>
</dt>
<dd>

</dd>
<dt>
<code><a href="../../endless-stdlib/doc/table.md#0x1_table">table</a>: <a href="../../endless-stdlib/doc/table_with_length.md#0x1_table_with_length_TableWithLength">table_with_length::TableWithLength</a>&lt;u32, <a href="block.md#0x1_block_NewBlockEvent">block::NewBlockEvent</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_block_NewBlockEvent"></a>

## Struct `NewBlockEvent`

Should be in-sync with NewBlockEvent rust struct in new_block.rs


<pre><code><b>struct</b> <a href="block.md#0x1_block_NewBlockEvent">NewBlockEvent</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>epoch: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>round: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>height: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>previous_block_votes_bitvec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>proposer: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>time_microseconds: u64</code>
</dt>
<dd>
 On-chain time during the block at the given height
</dd>
</dl>


</details>

<a id="0x1_block_UpdateEpochIntervalEvent"></a>

## Struct `UpdateEpochIntervalEvent`

Event emitted when a proposal is created.


<pre><code><b>struct</b> <a href="block.md#0x1_block_UpdateEpochIntervalEvent">UpdateEpochIntervalEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>old_epoch_interval: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>new_epoch_interval: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_block_MAX_U64"></a>



<pre><code><b>const</b> <a href="block.md#0x1_block_MAX_U64">MAX_U64</a>: u64 = 18446744073709551615;
</code></pre>



<a id="0x1_block_EINVALID_PROPOSER"></a>

An invalid proposer was provided. Expected the proposer to be the VM or an active validator.


<pre><code><b>const</b> <a href="block.md#0x1_block_EINVALID_PROPOSER">EINVALID_PROPOSER</a>: u64 = 2;
</code></pre>



<a id="0x1_block_ENUM_NEW_BLOCK_EVENTS_DOES_NOT_MATCH_BLOCK_HEIGHT"></a>

The number of new block events does not equal the current block height.


<pre><code><b>const</b> <a href="block.md#0x1_block_ENUM_NEW_BLOCK_EVENTS_DOES_NOT_MATCH_BLOCK_HEIGHT">ENUM_NEW_BLOCK_EVENTS_DOES_NOT_MATCH_BLOCK_HEIGHT</a>: u64 = 1;
</code></pre>



<a id="0x1_block_EZERO_EPOCH_INTERVAL"></a>

Epoch interval cannot be 0.


<pre><code><b>const</b> <a href="block.md#0x1_block_EZERO_EPOCH_INTERVAL">EZERO_EPOCH_INTERVAL</a>: u64 = 3;
</code></pre>



<a id="0x1_block_EZERO_MAX_CAPACITY"></a>

The maximum capacity of the commit history cannot be 0.


<pre><code><b>const</b> <a href="block.md#0x1_block_EZERO_MAX_CAPACITY">EZERO_MAX_CAPACITY</a>: u64 = 3;
</code></pre>



<a id="0x1_block_initialize"></a>

## Function `initialize`

This can only be called during Genesis.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="block.md#0x1_block_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, epoch_interval_microsecs: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="block.md#0x1_block_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, epoch_interval_microsecs: u64) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>assert</b>!(epoch_interval_microsecs &gt; 0, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="block.md#0x1_block_EZERO_EPOCH_INTERVAL">EZERO_EPOCH_INTERVAL</a>));

    <b>move_to</b>&lt;<a href="block.md#0x1_block_CommitHistory">CommitHistory</a>&gt;(endless_framework, <a href="block.md#0x1_block_CommitHistory">CommitHistory</a> {
        max_capacity: 2000,
        next_idx: 0,
        <a href="../../endless-stdlib/doc/table.md#0x1_table">table</a>: <a href="../../endless-stdlib/doc/table_with_length.md#0x1_table_with_length_new">table_with_length::new</a>(),
    });

    <b>move_to</b>&lt;<a href="block.md#0x1_block_BlockResource">BlockResource</a>&gt;(
        endless_framework,
        <a href="block.md#0x1_block_BlockResource">BlockResource</a> {
            height: 0,
            epoch_interval: epoch_interval_microsecs,
            new_block_events: <a href="account.md#0x1_account_new_event_handle">account::new_event_handle</a>&lt;<a href="block.md#0x1_block_NewBlockEvent">NewBlockEvent</a>&gt;(endless_framework),
            update_epoch_interval_events: <a href="account.md#0x1_account_new_event_handle">account::new_event_handle</a>&lt;<a href="block.md#0x1_block_UpdateEpochIntervalEvent">UpdateEpochIntervalEvent</a>&gt;(endless_framework),
        }
    );
}
</code></pre>



</details>

<a id="0x1_block_initialize_commit_history"></a>

## Function `initialize_commit_history`

Initialize the commit history resource if it's not in genesis.


<pre><code><b>public</b> <b>fun</b> <a href="block.md#0x1_block_initialize_commit_history">initialize_commit_history</a>(fx: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, max_capacity: u32)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="block.md#0x1_block_initialize_commit_history">initialize_commit_history</a>(fx: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, max_capacity: u32) {
    <b>assert</b>!(max_capacity &gt; 0, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="block.md#0x1_block_EZERO_MAX_CAPACITY">EZERO_MAX_CAPACITY</a>));
    <b>move_to</b>&lt;<a href="block.md#0x1_block_CommitHistory">CommitHistory</a>&gt;(fx, <a href="block.md#0x1_block_CommitHistory">CommitHistory</a> {
        max_capacity,
        next_idx: 0,
        <a href="../../endless-stdlib/doc/table.md#0x1_table">table</a>: <a href="../../endless-stdlib/doc/table_with_length.md#0x1_table_with_length_new">table_with_length::new</a>(),
    });
}
</code></pre>



</details>

<a id="0x1_block_update_epoch_interval_microsecs"></a>

## Function `update_epoch_interval_microsecs`

Update the epoch interval.
Can only be called as part of the Endless governance proposal process established by the EndlessGovernance module.


<pre><code><b>public</b> <b>fun</b> <a href="block.md#0x1_block_update_epoch_interval_microsecs">update_epoch_interval_microsecs</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_epoch_interval: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="block.md#0x1_block_update_epoch_interval_microsecs">update_epoch_interval_microsecs</a>(
    endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    new_epoch_interval: u64,
) <b>acquires</b> <a href="block.md#0x1_block_BlockResource">BlockResource</a> {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>assert</b>!(new_epoch_interval &gt; 0, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="block.md#0x1_block_EZERO_EPOCH_INTERVAL">EZERO_EPOCH_INTERVAL</a>));

    <b>let</b> block_resource = <b>borrow_global_mut</b>&lt;<a href="block.md#0x1_block_BlockResource">BlockResource</a>&gt;(@endless_framework);
    <b>let</b> old_epoch_interval = block_resource.epoch_interval;
    block_resource.epoch_interval = new_epoch_interval;

    <a href="event.md#0x1_event_emit_event">event::emit_event</a>&lt;<a href="block.md#0x1_block_UpdateEpochIntervalEvent">UpdateEpochIntervalEvent</a>&gt;(
        &<b>mut</b> block_resource.update_epoch_interval_events,
        <a href="block.md#0x1_block_UpdateEpochIntervalEvent">UpdateEpochIntervalEvent</a> { old_epoch_interval, new_epoch_interval },
    );
}
</code></pre>



</details>

<a id="0x1_block_get_epoch_interval_secs"></a>

## Function `get_epoch_interval_secs`

Return epoch interval in seconds.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="block.md#0x1_block_get_epoch_interval_secs">get_epoch_interval_secs</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="block.md#0x1_block_get_epoch_interval_secs">get_epoch_interval_secs</a>(): u64 <b>acquires</b> <a href="block.md#0x1_block_BlockResource">BlockResource</a> {
    <b>borrow_global</b>&lt;<a href="block.md#0x1_block_BlockResource">BlockResource</a>&gt;(@endless_framework).epoch_interval / 1000000
}
</code></pre>



</details>

<a id="0x1_block_block_prologue_common"></a>

## Function `block_prologue_common`



<pre><code><b>fun</b> <a href="block.md#0x1_block_block_prologue_common">block_prologue_common</a>(vm: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>: <b>address</b>, epoch: u64, round: u64, proposer: <b>address</b>, failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, previous_block_votes_bitvec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="timestamp.md#0x1_timestamp">timestamp</a>: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="block.md#0x1_block_block_prologue_common">block_prologue_common</a>(
    vm: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>: <b>address</b>,
    epoch: u64,
    round: u64,
    proposer: <b>address</b>,
    failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;,
    previous_block_votes_bitvec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    <a href="timestamp.md#0x1_timestamp">timestamp</a>: u64
): u64 <b>acquires</b> <a href="block.md#0x1_block_BlockResource">BlockResource</a>, <a href="block.md#0x1_block_CommitHistory">CommitHistory</a> {
    // Operational constraint: can only be invoked by the VM.
    <a href="system_addresses.md#0x1_system_addresses_assert_vm">system_addresses::assert_vm</a>(vm);

    // Blocks can only be produced by a valid proposer or by the VM itself for Nil blocks (no user txs).
    <b>assert</b>!(
        proposer == @vm_reserved || <a href="stake.md#0x1_stake_is_current_epoch_validator">stake::is_current_epoch_validator</a>(proposer),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="block.md#0x1_block_EINVALID_PROPOSER">EINVALID_PROPOSER</a>),
    );

    <b>let</b> proposer_index = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>();
    <b>if</b> (proposer != @vm_reserved) {
        proposer_index = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="stake.md#0x1_stake_get_validator_index">stake::get_validator_index</a>(proposer));
    };

    <b>let</b> block_metadata_ref = <b>borrow_global_mut</b>&lt;<a href="block.md#0x1_block_BlockResource">BlockResource</a>&gt;(@endless_framework);
    block_metadata_ref.height = <a href="event.md#0x1_event_counter">event::counter</a>(&block_metadata_ref.new_block_events);

    <b>let</b> new_block_event = <a href="block.md#0x1_block_NewBlockEvent">NewBlockEvent</a> {
        <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>,
        epoch,
        round,
        height: block_metadata_ref.height,
        previous_block_votes_bitvec,
        proposer,
        failed_proposer_indices,
        time_microseconds: <a href="timestamp.md#0x1_timestamp">timestamp</a>,
    };
    <a href="block.md#0x1_block_emit_new_block_event">emit_new_block_event</a>(vm, &<b>mut</b> block_metadata_ref.new_block_events, new_block_event);

    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_collect_and_distribute_gas_fees">features::collect_and_distribute_gas_fees</a>()) {
        // Assign the fees collected from the previous <a href="block.md#0x1_block">block</a> <b>to</b> the previous <a href="block.md#0x1_block">block</a> proposer.
        // If for <a href="../../endless-stdlib/doc/any.md#0x1_any">any</a> reason the fees cannot be assigned, this function burns the collected coins.
        <a href="transaction_fee.md#0x1_transaction_fee_process_collected_fees">transaction_fee::process_collected_fees</a>();
        // Set the proposer of this <a href="block.md#0x1_block">block</a> <b>as</b> the receiver of the fees, so that the fees for this
        // <a href="block.md#0x1_block">block</a> are assigned <b>to</b> the right <a href="account.md#0x1_account">account</a>.
        <a href="transaction_fee.md#0x1_transaction_fee_register_proposer_for_fee_collection">transaction_fee::register_proposer_for_fee_collection</a>(proposer);
    };

    // Performance scores have <b>to</b> be updated before the epoch transition <b>as</b> the transaction that triggers the
    // transition is the last <a href="block.md#0x1_block">block</a> in the previous epoch.
    <a href="stake.md#0x1_stake_update_performance_statistics">stake::update_performance_statistics</a>(proposer_index, failed_proposer_indices);
    <a href="state_storage.md#0x1_state_storage_on_new_block">state_storage::on_new_block</a>(<a href="reconfiguration.md#0x1_reconfiguration_current_epoch">reconfiguration::current_epoch</a>());

    block_metadata_ref.epoch_interval
}
</code></pre>



</details>

<a id="0x1_block_block_prologue"></a>

## Function `block_prologue`

Set the metadata for the current block.
The runtime always runs this before executing the transactions in a block.


<pre><code><b>fun</b> <a href="block.md#0x1_block_block_prologue">block_prologue</a>(vm: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>: <b>address</b>, epoch: u64, round: u64, proposer: <b>address</b>, failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, previous_block_votes_bitvec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="timestamp.md#0x1_timestamp">timestamp</a>: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="block.md#0x1_block_block_prologue">block_prologue</a>(
    vm: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>: <b>address</b>,
    epoch: u64,
    round: u64,
    proposer: <b>address</b>,
    failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;,
    previous_block_votes_bitvec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    <a href="timestamp.md#0x1_timestamp">timestamp</a>: u64
) <b>acquires</b> <a href="block.md#0x1_block_BlockResource">BlockResource</a>, <a href="block.md#0x1_block_CommitHistory">CommitHistory</a> {
    <b>let</b> epoch_interval = <a href="block.md#0x1_block_block_prologue_common">block_prologue_common</a>(&vm, <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>, epoch, round, proposer, failed_proposer_indices, previous_block_votes_bitvec, <a href="timestamp.md#0x1_timestamp">timestamp</a>);
    <a href="randomness.md#0x1_randomness_on_new_block">randomness::on_new_block</a>(&vm, epoch, round, <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>());
    <b>if</b> (<a href="timestamp.md#0x1_timestamp">timestamp</a> - <a href="reconfiguration.md#0x1_reconfiguration_last_reconfiguration_time">reconfiguration::last_reconfiguration_time</a>() &gt;= epoch_interval) {
        <a href="reconfiguration.md#0x1_reconfiguration_reconfigure">reconfiguration::reconfigure</a>();
    };
}
</code></pre>



</details>

<a id="0x1_block_block_prologue_ext"></a>

## Function `block_prologue_ext`

<code><a href="block.md#0x1_block_block_prologue">block_prologue</a>()</code> but trigger reconfiguration with DKG after epoch timed out.


<pre><code><b>fun</b> <a href="block.md#0x1_block_block_prologue_ext">block_prologue_ext</a>(vm: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>: <b>address</b>, epoch: u64, round: u64, proposer: <b>address</b>, failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, previous_block_votes_bitvec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="timestamp.md#0x1_timestamp">timestamp</a>: u64, randomness_seed: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="block.md#0x1_block_block_prologue_ext">block_prologue_ext</a>(
    vm: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>: <b>address</b>,
    epoch: u64,
    round: u64,
    proposer: <b>address</b>,
    failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;,
    previous_block_votes_bitvec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    <a href="timestamp.md#0x1_timestamp">timestamp</a>: u64,
    randomness_seed: Option&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;,
) <b>acquires</b> <a href="block.md#0x1_block_BlockResource">BlockResource</a>, <a href="block.md#0x1_block_CommitHistory">CommitHistory</a> {
    <b>let</b> epoch_interval = <a href="block.md#0x1_block_block_prologue_common">block_prologue_common</a>(
        &vm,
        <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>,
        epoch,
        round,
        proposer,
        failed_proposer_indices,
        previous_block_votes_bitvec,
        <a href="timestamp.md#0x1_timestamp">timestamp</a>
    );
    <a href="randomness.md#0x1_randomness_on_new_block">randomness::on_new_block</a>(&vm, epoch, round, randomness_seed);

    <b>if</b> (<a href="timestamp.md#0x1_timestamp">timestamp</a> - <a href="reconfiguration.md#0x1_reconfiguration_last_reconfiguration_time">reconfiguration::last_reconfiguration_time</a>() &gt;= epoch_interval) {
        <a href="reconfiguration_with_dkg.md#0x1_reconfiguration_with_dkg_try_start">reconfiguration_with_dkg::try_start</a>();
    }
}
</code></pre>



</details>

<a id="0x1_block_get_current_block_height"></a>

## Function `get_current_block_height`

Get the current block height


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="block.md#0x1_block_get_current_block_height">get_current_block_height</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="block.md#0x1_block_get_current_block_height">get_current_block_height</a>(): u64 <b>acquires</b> <a href="block.md#0x1_block_BlockResource">BlockResource</a> {
    <b>borrow_global</b>&lt;<a href="block.md#0x1_block_BlockResource">BlockResource</a>&gt;(@endless_framework).height
}
</code></pre>



</details>

<a id="0x1_block_emit_new_block_event"></a>

## Function `emit_new_block_event`

Emit the event and update height and global timestamp


<pre><code><b>fun</b> <a href="block.md#0x1_block_emit_new_block_event">emit_new_block_event</a>(vm: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, event_handle: &<b>mut</b> <a href="event.md#0x1_event_EventHandle">event::EventHandle</a>&lt;<a href="block.md#0x1_block_NewBlockEvent">block::NewBlockEvent</a>&gt;, new_block_event: <a href="block.md#0x1_block_NewBlockEvent">block::NewBlockEvent</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="block.md#0x1_block_emit_new_block_event">emit_new_block_event</a>(vm: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, event_handle: &<b>mut</b> EventHandle&lt;<a href="block.md#0x1_block_NewBlockEvent">NewBlockEvent</a>&gt;, new_block_event: <a href="block.md#0x1_block_NewBlockEvent">NewBlockEvent</a>) <b>acquires</b> <a href="block.md#0x1_block_CommitHistory">CommitHistory</a> {
    <b>if</b> (<b>exists</b>&lt;<a href="block.md#0x1_block_CommitHistory">CommitHistory</a>&gt;(@endless_framework)) {
        <b>let</b> commit_history_ref = <b>borrow_global_mut</b>&lt;<a href="block.md#0x1_block_CommitHistory">CommitHistory</a>&gt;(@endless_framework);
        <b>let</b> idx = commit_history_ref.next_idx;
        <b>if</b> (<a href="../../endless-stdlib/doc/table_with_length.md#0x1_table_with_length_contains">table_with_length::contains</a>(&commit_history_ref.<a href="../../endless-stdlib/doc/table.md#0x1_table">table</a>, idx)) {
            <a href="../../endless-stdlib/doc/table_with_length.md#0x1_table_with_length_remove">table_with_length::remove</a>(&<b>mut</b> commit_history_ref.<a href="../../endless-stdlib/doc/table.md#0x1_table">table</a>, idx);
        };
        <a href="../../endless-stdlib/doc/table_with_length.md#0x1_table_with_length_add">table_with_length::add</a>(&<b>mut</b> commit_history_ref.<a href="../../endless-stdlib/doc/table.md#0x1_table">table</a>, idx, <b>copy</b> new_block_event);
        <b>spec</b> {
            <b>assume</b> idx + 1 &lt;= MAX_U32;
            <b>assume</b> commit_history_ref.max_capacity != 0;
        };
        commit_history_ref.next_idx = (idx + 1) % commit_history_ref.max_capacity;
    };
    <a href="timestamp.md#0x1_timestamp_update_global_time">timestamp::update_global_time</a>(vm, new_block_event.proposer, new_block_event.time_microseconds);
    <b>assert</b>!(
        <a href="event.md#0x1_event_counter">event::counter</a>(event_handle) == new_block_event.height,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="block.md#0x1_block_ENUM_NEW_BLOCK_EVENTS_DOES_NOT_MATCH_BLOCK_HEIGHT">ENUM_NEW_BLOCK_EVENTS_DOES_NOT_MATCH_BLOCK_HEIGHT</a>),
    );
    <a href="event.md#0x1_event_emit_event">event::emit_event</a>&lt;<a href="block.md#0x1_block_NewBlockEvent">NewBlockEvent</a>&gt;(event_handle, new_block_event);
}
</code></pre>



</details>

<a id="0x1_block_emit_genesis_block_event"></a>

## Function `emit_genesis_block_event`

Emit a <code><a href="block.md#0x1_block_NewBlockEvent">NewBlockEvent</a></code> event. This function will be invoked by genesis directly to generate the very first
reconfiguration event.


<pre><code><b>fun</b> <a href="block.md#0x1_block_emit_genesis_block_event">emit_genesis_block_event</a>(vm: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="block.md#0x1_block_emit_genesis_block_event">emit_genesis_block_event</a>(vm: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="block.md#0x1_block_BlockResource">BlockResource</a>, <a href="block.md#0x1_block_CommitHistory">CommitHistory</a> {
    <b>let</b> block_metadata_ref = <b>borrow_global_mut</b>&lt;<a href="block.md#0x1_block_BlockResource">BlockResource</a>&gt;(@endless_framework);
    <b>let</b> genesis_id = @0x0;
    <a href="block.md#0x1_block_emit_new_block_event">emit_new_block_event</a>(
        &vm,
        &<b>mut</b> block_metadata_ref.new_block_events,
        <a href="block.md#0x1_block_NewBlockEvent">NewBlockEvent</a> {
            <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>: genesis_id,
            epoch: 0,
            round: 0,
            height: 0,
            previous_block_votes_bitvec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
            proposer: @vm_reserved,
            failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
            time_microseconds: 0,
        }
    );
}
</code></pre>



</details>

<a id="0x1_block_emit_writeset_block_event"></a>

## Function `emit_writeset_block_event`

Emit a <code><a href="block.md#0x1_block_NewBlockEvent">NewBlockEvent</a></code> event. This function will be invoked by write set script directly to generate the
new block event for WriteSetPayload.


<pre><code><b>public</b> <b>fun</b> <a href="block.md#0x1_block_emit_writeset_block_event">emit_writeset_block_event</a>(vm_signer: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, fake_block_hash: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="block.md#0x1_block_emit_writeset_block_event">emit_writeset_block_event</a>(vm_signer: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, fake_block_hash: <b>address</b>) <b>acquires</b> <a href="block.md#0x1_block_BlockResource">BlockResource</a>, <a href="block.md#0x1_block_CommitHistory">CommitHistory</a> {
    <a href="system_addresses.md#0x1_system_addresses_assert_vm">system_addresses::assert_vm</a>(vm_signer);
    <b>let</b> block_metadata_ref = <b>borrow_global_mut</b>&lt;<a href="block.md#0x1_block_BlockResource">BlockResource</a>&gt;(@endless_framework);
    block_metadata_ref.height = <a href="event.md#0x1_event_counter">event::counter</a>(&block_metadata_ref.new_block_events);

    <a href="block.md#0x1_block_emit_new_block_event">emit_new_block_event</a>(
        vm_signer,
        &<b>mut</b> block_metadata_ref.new_block_events,
        <a href="block.md#0x1_block_NewBlockEvent">NewBlockEvent</a> {
            <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">hash</a>: fake_block_hash,
            epoch: <a href="reconfiguration.md#0x1_reconfiguration_current_epoch">reconfiguration::current_epoch</a>(),
            round: <a href="block.md#0x1_block_MAX_U64">MAX_U64</a>,
            height: block_metadata_ref.height,
            previous_block_votes_bitvec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
            proposer: @vm_reserved,
            failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
            time_microseconds: <a href="timestamp.md#0x1_timestamp_now_microseconds">timestamp::now_microseconds</a>(),
        }
    );
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

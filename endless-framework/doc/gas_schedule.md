
<a id="0x1_gas_schedule"></a>

# Module `0x1::gas_schedule`

This module defines structs and methods to initialize the gas schedule, which dictates how much
it costs to execute Move on the network.


-  [Struct `GasEntry`](#0x1_gas_schedule_GasEntry)
-  [Resource `GasSchedule`](#0x1_gas_schedule_GasSchedule)
-  [Resource `GasScheduleV2`](#0x1_gas_schedule_GasScheduleV2)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_gas_schedule_initialize)
-  [Function `set_gas_schedule`](#0x1_gas_schedule_set_gas_schedule)
-  [Function `set_for_next_epoch`](#0x1_gas_schedule_set_for_next_epoch)
-  [Function `on_new_epoch`](#0x1_gas_schedule_on_new_epoch)
-  [Function `set_storage_gas_config`](#0x1_gas_schedule_set_storage_gas_config)
-  [Function `set_storage_gas_config_for_next_epoch`](#0x1_gas_schedule_set_storage_gas_config_for_next_epoch)


<pre><code><b>use</b> <a href="config_buffer.md#0x1_config_buffer">0x1::config_buffer</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="reconfiguration.md#0x1_reconfiguration">0x1::reconfiguration</a>;
<b>use</b> <a href="storage_gas.md#0x1_storage_gas">0x1::storage_gas</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
<b>use</b> <a href="util.md#0x1_util">0x1::util</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">0x1::vector</a>;
</code></pre>



<a id="0x1_gas_schedule_GasEntry"></a>

## Struct `GasEntry`



<pre><code><b>struct</b> <a href="gas_schedule.md#0x1_gas_schedule_GasEntry">GasEntry</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>key: <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>val: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_gas_schedule_GasSchedule"></a>

## Resource `GasSchedule`



<pre><code><b>struct</b> <a href="gas_schedule.md#0x1_gas_schedule_GasSchedule">GasSchedule</a> <b>has</b> <b>copy</b>, drop, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>entries: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasEntry">gas_schedule::GasEntry</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_gas_schedule_GasScheduleV2"></a>

## Resource `GasScheduleV2`



<pre><code><b>struct</b> <a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>feature_version: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>entries: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasEntry">gas_schedule::GasEntry</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_gas_schedule_EINVALID_GAS_FEATURE_VERSION"></a>



<pre><code><b>const</b> <a href="gas_schedule.md#0x1_gas_schedule_EINVALID_GAS_FEATURE_VERSION">EINVALID_GAS_FEATURE_VERSION</a>: u64 = 2;
</code></pre>



<a id="0x1_gas_schedule_EINVALID_GAS_SCHEDULE"></a>

The provided gas schedule bytes are empty or invalid


<pre><code><b>const</b> <a href="gas_schedule.md#0x1_gas_schedule_EINVALID_GAS_SCHEDULE">EINVALID_GAS_SCHEDULE</a>: u64 = 1;
</code></pre>



<a id="0x1_gas_schedule_initialize"></a>

## Function `initialize`

Only called during genesis.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, gas_schedule_blob: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, gas_schedule_blob: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&gas_schedule_blob), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="gas_schedule.md#0x1_gas_schedule_EINVALID_GAS_SCHEDULE">EINVALID_GAS_SCHEDULE</a>));

    // TODO(Gas): check <b>if</b> gas schedule is consistent
    <b>let</b> <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>: <a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a> = from_bytes(gas_schedule_blob);
    <b>move_to</b>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a>&gt;(endless_framework, <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>);
}
</code></pre>



</details>

<a id="0x1_gas_schedule_set_gas_schedule"></a>

## Function `set_gas_schedule`

Deprecated by <code><a href="gas_schedule.md#0x1_gas_schedule_set_for_next_epoch">set_for_next_epoch</a>()</code>.

WARNING: calling this while randomness is enabled will trigger a new epoch without randomness!

TODO: update all the tests that reference this function, then disable this function.


<pre><code><b>public</b> <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_set_gas_schedule">set_gas_schedule</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, gas_schedule_blob: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_set_gas_schedule">set_gas_schedule</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, gas_schedule_blob: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;) <b>acquires</b> <a href="gas_schedule.md#0x1_gas_schedule_GasSchedule">GasSchedule</a>, <a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a> {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&gas_schedule_blob), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="gas_schedule.md#0x1_gas_schedule_EINVALID_GAS_SCHEDULE">EINVALID_GAS_SCHEDULE</a>));

    <b>if</b> (<b>exists</b>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a>&gt;(@endless_framework)) {
        <b>let</b> <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a> = <b>borrow_global_mut</b>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a>&gt;(@endless_framework);
        <b>let</b> new_gas_schedule: <a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a> = from_bytes(gas_schedule_blob);
        <b>assert</b>!(new_gas_schedule.feature_version &gt;= <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>.feature_version,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="gas_schedule.md#0x1_gas_schedule_EINVALID_GAS_FEATURE_VERSION">EINVALID_GAS_FEATURE_VERSION</a>));
        // TODO(Gas): check <b>if</b> gas schedule is consistent
        *<a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a> = new_gas_schedule;
    }
    <b>else</b> {
        <b>if</b> (<b>exists</b>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasSchedule">GasSchedule</a>&gt;(@endless_framework)) {
            _ = <b>move_from</b>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasSchedule">GasSchedule</a>&gt;(@endless_framework);
        };
        <b>let</b> new_gas_schedule: <a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a> = from_bytes(gas_schedule_blob);
        // TODO(Gas): check <b>if</b> gas schedule is consistent
        <b>move_to</b>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a>&gt;(endless_framework, new_gas_schedule);
    };

    // Need <b>to</b> trigger <a href="reconfiguration.md#0x1_reconfiguration">reconfiguration</a> so validator nodes can sync on the updated gas schedule.
    <a href="reconfiguration.md#0x1_reconfiguration_reconfigure">reconfiguration::reconfigure</a>();
}
</code></pre>



</details>

<a id="0x1_gas_schedule_set_for_next_epoch"></a>

## Function `set_for_next_epoch`

Set the gas schedule for the next epoch, typically called by on-chain governance.
Example usage:
```
endless_framework::gas_schedule::set_for_next_epoch(&framework_signer, some_gas_schedule_blob);
endless_framework::endless_governance::reconfigure(&framework_signer);
```


<pre><code><b>public</b> <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_set_for_next_epoch">set_for_next_epoch</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, gas_schedule_blob: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_set_for_next_epoch">set_for_next_epoch</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, gas_schedule_blob: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&gas_schedule_blob), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="gas_schedule.md#0x1_gas_schedule_EINVALID_GAS_SCHEDULE">EINVALID_GAS_SCHEDULE</a>));
    <b>let</b> new_gas_schedule: <a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a> = from_bytes(gas_schedule_blob);
    <a href="config_buffer.md#0x1_config_buffer_upsert">config_buffer::upsert</a>(new_gas_schedule);
}
</code></pre>



</details>

<a id="0x1_gas_schedule_on_new_epoch"></a>

## Function `on_new_epoch`

Only used in reconfigurations to apply the pending <code><a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a></code>, if there is any.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_on_new_epoch">on_new_epoch</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_on_new_epoch">on_new_epoch</a>() <b>acquires</b> <a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a> {
    <b>if</b> (<a href="config_buffer.md#0x1_config_buffer_does_exist">config_buffer::does_exist</a>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a>&gt;()) {
        <b>let</b> new_gas_schedule: <a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a> = <a href="config_buffer.md#0x1_config_buffer_extract">config_buffer::extract</a>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a>&gt;();
        <b>let</b> <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a> = <b>borrow_global_mut</b>&lt;<a href="gas_schedule.md#0x1_gas_schedule_GasScheduleV2">GasScheduleV2</a>&gt;(@endless_framework);
        *<a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a> = new_gas_schedule;
    }
}
</code></pre>



</details>

<a id="0x1_gas_schedule_set_storage_gas_config"></a>

## Function `set_storage_gas_config`



<pre><code><b>public</b> <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_set_storage_gas_config">set_storage_gas_config</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, config: <a href="storage_gas.md#0x1_storage_gas_StorageGasConfig">storage_gas::StorageGasConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_set_storage_gas_config">set_storage_gas_config</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, config: StorageGasConfig) {
    <a href="storage_gas.md#0x1_storage_gas_set_config">storage_gas::set_config</a>(endless_framework, config);
    // Need <b>to</b> trigger <a href="reconfiguration.md#0x1_reconfiguration">reconfiguration</a> so the VM is guaranteed <b>to</b> load the new gas fee starting from the next
    // transaction.
    <a href="reconfiguration.md#0x1_reconfiguration_reconfigure">reconfiguration::reconfigure</a>();
}
</code></pre>



</details>

<a id="0x1_gas_schedule_set_storage_gas_config_for_next_epoch"></a>

## Function `set_storage_gas_config_for_next_epoch`



<pre><code><b>public</b> <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_set_storage_gas_config_for_next_epoch">set_storage_gas_config_for_next_epoch</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, config: <a href="storage_gas.md#0x1_storage_gas_StorageGasConfig">storage_gas::StorageGasConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="gas_schedule.md#0x1_gas_schedule_set_storage_gas_config_for_next_epoch">set_storage_gas_config_for_next_epoch</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, config: StorageGasConfig) {
    <a href="storage_gas.md#0x1_storage_gas_set_config">storage_gas::set_config</a>(endless_framework, config);
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

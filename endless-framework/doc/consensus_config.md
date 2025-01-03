
<a id="0x1_consensus_config"></a>

# Module `0x1::consensus_config`

Maintains the consensus config for the blockchain. The config is stored in a
Reconfiguration, and may be updated by root.


-  [Resource `ConsensusConfig`](#0x1_consensus_config_ConsensusConfig)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_consensus_config_initialize)
-  [Function `set`](#0x1_consensus_config_set)
-  [Function `set_for_next_epoch`](#0x1_consensus_config_set_for_next_epoch)
-  [Function `on_new_epoch`](#0x1_consensus_config_on_new_epoch)
-  [Function `validator_txn_enabled`](#0x1_consensus_config_validator_txn_enabled)
-  [Function `validator_txn_enabled_internal`](#0x1_consensus_config_validator_txn_enabled_internal)


<pre><code><b>use</b> <a href="config_buffer.md#0x1_config_buffer">0x1::config_buffer</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="reconfiguration.md#0x1_reconfiguration">0x1::reconfiguration</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
</code></pre>



<a id="0x1_consensus_config_ConsensusConfig"></a>

## Resource `ConsensusConfig`



<pre><code><b>struct</b> <a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a> <b>has</b> drop, store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>config: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_consensus_config_EINVALID_CONFIG"></a>

The provided on chain config bytes are empty or invalid


<pre><code><b>const</b> <a href="consensus_config.md#0x1_consensus_config_EINVALID_CONFIG">EINVALID_CONFIG</a>: u64 = 1;
</code></pre>



<a id="0x1_consensus_config_initialize"></a>

## Function `initialize`

Publishes the ConsensusConfig config.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, config: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, config: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&config) &gt; 0, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="consensus_config.md#0x1_consensus_config_EINVALID_CONFIG">EINVALID_CONFIG</a>));
    <b>move_to</b>(endless_framework, <a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a> { config });
}
</code></pre>



</details>

<a id="0x1_consensus_config_set"></a>

## Function `set`

Deprecated by <code><a href="consensus_config.md#0x1_consensus_config_set_for_next_epoch">set_for_next_epoch</a>()</code>.

WARNING: calling this while randomness is enabled will trigger a new epoch without randomness!

TODO: update all the tests that reference this function, then disable this function.


<pre><code><b>public</b> <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_set">set</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, config: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_set">set</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, config: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;) <b>acquires</b> <a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a> {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(<a href="account.md#0x1_account">account</a>);
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&config) &gt; 0, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="consensus_config.md#0x1_consensus_config_EINVALID_CONFIG">EINVALID_CONFIG</a>));

    <b>let</b> config_ref = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a>&gt;(@endless_framework).config;
    *config_ref = config;

    // Need <b>to</b> trigger <a href="reconfiguration.md#0x1_reconfiguration">reconfiguration</a> so validator nodes can sync on the updated configs.
    <a href="reconfiguration.md#0x1_reconfiguration_reconfigure">reconfiguration::reconfigure</a>();
}
</code></pre>



</details>

<a id="0x1_consensus_config_set_for_next_epoch"></a>

## Function `set_for_next_epoch`

This can be called by on-chain governance to update on-chain consensus configs for the next epoch.
Example usage:
```
endless_framework::consensus_config::set_for_next_epoch(&framework_signer, some_config_bytes);
endless_framework::endless_governance::reconfigure(&framework_signer);
```


<pre><code><b>public</b> <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_set_for_next_epoch">set_for_next_epoch</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, config: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_set_for_next_epoch">set_for_next_epoch</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, config: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(<a href="account.md#0x1_account">account</a>);
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&config) &gt; 0, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="consensus_config.md#0x1_consensus_config_EINVALID_CONFIG">EINVALID_CONFIG</a>));
    std::config_buffer::upsert&lt;<a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a>&gt;(<a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a> {config});
}
</code></pre>



</details>

<a id="0x1_consensus_config_on_new_epoch"></a>

## Function `on_new_epoch`

Only used in reconfigurations to apply the pending <code><a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a></code>, if there is any.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_on_new_epoch">on_new_epoch</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_on_new_epoch">on_new_epoch</a>() <b>acquires</b> <a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a> {
    <b>if</b> (<a href="config_buffer.md#0x1_config_buffer_does_exist">config_buffer::does_exist</a>&lt;<a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a>&gt;()) {
        *<b>borrow_global_mut</b>&lt;<a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a>&gt;(@endless_framework) = <a href="config_buffer.md#0x1_config_buffer_extract">config_buffer::extract</a>();
    }
}
</code></pre>



</details>

<a id="0x1_consensus_config_validator_txn_enabled"></a>

## Function `validator_txn_enabled`



<pre><code><b>public</b> <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_validator_txn_enabled">validator_txn_enabled</a>(): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_validator_txn_enabled">validator_txn_enabled</a>(): bool <b>acquires</b> <a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a> {
    <b>let</b> config_bytes = <b>borrow_global</b>&lt;<a href="consensus_config.md#0x1_consensus_config_ConsensusConfig">ConsensusConfig</a>&gt;(@endless_framework).config;
    <a href="consensus_config.md#0x1_consensus_config_validator_txn_enabled_internal">validator_txn_enabled_internal</a>(config_bytes)
}
</code></pre>



</details>

<a id="0x1_consensus_config_validator_txn_enabled_internal"></a>

## Function `validator_txn_enabled_internal`



<pre><code><b>fun</b> <a href="consensus_config.md#0x1_consensus_config_validator_txn_enabled_internal">validator_txn_enabled_internal</a>(config_bytes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>native</b> <b>fun</b> <a href="consensus_config.md#0x1_consensus_config_validator_txn_enabled_internal">validator_txn_enabled_internal</a>(config_bytes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): bool;
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

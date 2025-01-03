
<a id="0x1_version"></a>

# Module `0x1::version`

Maintains the version number for the blockchain.


-  [Resource `Version`](#0x1_version_Version)
-  [Resource `SetVersionCapability`](#0x1_version_SetVersionCapability)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_version_initialize)
-  [Function `set_for_next_epoch`](#0x1_version_set_for_next_epoch)
-  [Function `on_new_epoch`](#0x1_version_on_new_epoch)
-  [Function `initialize_for_test`](#0x1_version_initialize_for_test)


<pre><code><b>use</b> <a href="config_buffer.md#0x1_config_buffer">0x1::config_buffer</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
</code></pre>



<a id="0x1_version_Version"></a>

## Resource `Version`



<pre><code><b>struct</b> <a href="version.md#0x1_version_Version">Version</a> <b>has</b> drop, store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>major: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_version_SetVersionCapability"></a>

## Resource `SetVersionCapability`



<pre><code><b>struct</b> <a href="version.md#0x1_version_SetVersionCapability">SetVersionCapability</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>dummy_field: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_version_EINVALID_MAJOR_VERSION_NUMBER"></a>

Specified major version number must be greater than current version number.


<pre><code><b>const</b> <a href="version.md#0x1_version_EINVALID_MAJOR_VERSION_NUMBER">EINVALID_MAJOR_VERSION_NUMBER</a>: u64 = 1;
</code></pre>



<a id="0x1_version_ENOT_AUTHORIZED"></a>

Account is not authorized to make this change.


<pre><code><b>const</b> <a href="version.md#0x1_version_ENOT_AUTHORIZED">ENOT_AUTHORIZED</a>: u64 = 2;
</code></pre>



<a id="0x1_version_initialize"></a>

## Function `initialize`

Only called during genesis.
Publishes the Version config.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="version.md#0x1_version_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, initial_version: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="version.md#0x1_version_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, initial_version: u64) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);

    <b>move_to</b>(endless_framework, <a href="version.md#0x1_version_Version">Version</a> { major: initial_version });
    // Give endless framework <a href="account.md#0x1_account">account</a> capability <b>to</b> call set <a href="version.md#0x1_version">version</a>. This allows on chain governance <b>to</b> do it through
    // control of the endless framework <a href="account.md#0x1_account">account</a>.
    <b>move_to</b>(endless_framework, <a href="version.md#0x1_version_SetVersionCapability">SetVersionCapability</a> {});
}
</code></pre>



</details>

<a id="0x1_version_set_for_next_epoch"></a>

## Function `set_for_next_epoch`

Used in on-chain governances to update the major version for the next epoch.
Example usage:
- <code>endless_framework::version::set_for_next_epoch(&framework_signer, new_version);</code>
- <code>endless_framework::endless_governance::reconfigure(&framework_signer);</code>


<pre><code><b>public</b> entry <b>fun</b> <a href="version.md#0x1_version_set_for_next_epoch">set_for_next_epoch</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, major: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="version.md#0x1_version_set_for_next_epoch">set_for_next_epoch</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, major: u64) <b>acquires</b> <a href="version.md#0x1_version_Version">Version</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="version.md#0x1_version_SetVersionCapability">SetVersionCapability</a>&gt;(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>)), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="version.md#0x1_version_ENOT_AUTHORIZED">ENOT_AUTHORIZED</a>));
    <b>let</b> old_major = <b>borrow_global</b>&lt;<a href="version.md#0x1_version_Version">Version</a>&gt;(@endless_framework).major;
    <b>assert</b>!(old_major &lt; major, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="version.md#0x1_version_EINVALID_MAJOR_VERSION_NUMBER">EINVALID_MAJOR_VERSION_NUMBER</a>));
    <a href="config_buffer.md#0x1_config_buffer_upsert">config_buffer::upsert</a>(<a href="version.md#0x1_version_Version">Version</a> {major});
}
</code></pre>



</details>

<a id="0x1_version_on_new_epoch"></a>

## Function `on_new_epoch`

Only used in reconfigurations to apply the pending <code><a href="version.md#0x1_version_Version">Version</a></code>, if there is any.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="version.md#0x1_version_on_new_epoch">on_new_epoch</a>(framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="version.md#0x1_version_on_new_epoch">on_new_epoch</a>(framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="version.md#0x1_version_Version">Version</a> {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(framework);
    <b>if</b> (<a href="config_buffer.md#0x1_config_buffer_does_exist">config_buffer::does_exist</a>&lt;<a href="version.md#0x1_version_Version">Version</a>&gt;()) {
        <b>let</b> new_value = <a href="config_buffer.md#0x1_config_buffer_extract">config_buffer::extract</a>&lt;<a href="version.md#0x1_version_Version">Version</a>&gt;();
        <b>if</b> (<b>exists</b>&lt;<a href="version.md#0x1_version_Version">Version</a>&gt;(@endless_framework)) {
            *<b>borrow_global_mut</b>&lt;<a href="version.md#0x1_version_Version">Version</a>&gt;(@endless_framework) = new_value;
        } <b>else</b> {
            <b>move_to</b>(framework, new_value);
        }
    }
}
</code></pre>



</details>

<a id="0x1_version_initialize_for_test"></a>

## Function `initialize_for_test`

Only called in tests and testnets. This allows the core resources account, which only exists in tests/testnets,
to update the version.


<pre><code><b>fun</b> <a href="version.md#0x1_version_initialize_for_test">initialize_for_test</a>(core_resources: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="version.md#0x1_version_initialize_for_test">initialize_for_test</a>(core_resources: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <a href="system_addresses.md#0x1_system_addresses_assert_core_resource">system_addresses::assert_core_resource</a>(core_resources);
    <b>move_to</b>(core_resources, <a href="version.md#0x1_version_SetVersionCapability">SetVersionCapability</a> {});
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY


<a id="0x1_fixed_swap"></a>

# Module `0x1::fixed_swap`



-  [Resource `AdminCap`](#0x1_fixed_swap_AdminCap)
-  [Struct `FixedSwapConfig`](#0x1_fixed_swap_FixedSwapConfig)
-  [Resource `FixedSwapConfigTable`](#0x1_fixed_swap_FixedSwapConfigTable)
-  [Resource `FundingAccount`](#0x1_fixed_swap_FundingAccount)
-  [Struct `Swap`](#0x1_fixed_swap_Swap)
-  [Struct `ConfigUpdated`](#0x1_fixed_swap_ConfigUpdated)
-  [Struct `ConfigRemoved`](#0x1_fixed_swap_ConfigRemoved)
-  [Struct `AdminChanged`](#0x1_fixed_swap_AdminChanged)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_fixed_swap_initialize)
-  [Function `funding_address`](#0x1_fixed_swap_funding_address)
-  [Function `swap_out_amount`](#0x1_fixed_swap_swap_out_amount)
-  [Function `fixed_swap`](#0x1_fixed_swap_fixed_swap)
-  [Function `upsert_config`](#0x1_fixed_swap_upsert_config)
-  [Function `remove_config`](#0x1_fixed_swap_remove_config)
-  [Function `transfer_admin_cap`](#0x1_fixed_swap_transfer_admin_cap)
-  [Function `fixed_swap_internal`](#0x1_fixed_swap_fixed_swap_internal)
-  [Function `assert_admin`](#0x1_fixed_swap_assert_admin)
-  [Function `borrow_config`](#0x1_fixed_swap_borrow_config)
-  [Function `borrow_config_table_mut`](#0x1_fixed_swap_borrow_config_table_mut)
-  [Function `borrow_funding_account`](#0x1_fixed_swap_borrow_funding_account)
-  [Function `multiply_rate`](#0x1_fixed_swap_multiply_rate)
-  [Specification](#@Specification_1)
    -  [Function `initialize`](#@Specification_1_initialize)
    -  [Function `fixed_swap`](#@Specification_1_fixed_swap)
    -  [Function `upsert_config`](#@Specification_1_upsert_config)
    -  [Function `remove_config`](#@Specification_1_remove_config)
    -  [Function `transfer_admin_cap`](#@Specification_1_transfer_admin_cap)


<pre><code><b>use</b> <a href="account.md#0x1_account">0x1::account</a>;
<b>use</b> <a href="endless_coin.md#0x1_endless_coin">0x1::endless_coin</a>;
<b>use</b> <a href="event.md#0x1_event">0x1::event</a>;
<b>use</b> <a href="fungible_asset.md#0x1_fungible_asset">0x1::fungible_asset</a>;
<b>use</b> <a href="../../endless-stdlib/doc/math128.md#0x1_math128">0x1::math128</a>;
<b>use</b> <a href="object.md#0x1_object">0x1::object</a>;
<b>use</b> <a href="primary_fungible_store.md#0x1_primary_fungible_store">0x1::primary_fungible_store</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
<b>use</b> <a href="../../endless-stdlib/doc/table.md#0x1_table">0x1::table</a>;
<b>use</b> <a href="transaction_context.md#0x1_transaction_context">0x1::transaction_context</a>;
</code></pre>



<a id="0x1_fixed_swap_AdminCap"></a>

## Resource `AdminCap`

Record admin account which can change the configuration


<pre><code><b>struct</b> <a href="fixed_swap.md#0x1_fixed_swap_AdminCap">AdminCap</a> <b>has</b> <b>copy</b>, drop, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>admin: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_fixed_swap_FixedSwapConfig"></a>

## Struct `FixedSwapConfig`

The configuration of a fixed swap pair


<pre><code><b>struct</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfig">FixedSwapConfig</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>rate_numerator: u128</code>
</dt>
<dd>
 Swap rate
 amount_out = amount_in * rate_numerator / rate_denominator
</dd>
<dt>
<code>rate_denominator: u128</code>
</dt>
<dd>

</dd>
<dt>
<code><b>min</b>: u64</code>
</dt>
<dd>
 Minimum amount_in
</dd>
<dt>
<code>max: u64</code>
</dt>
<dd>
 Maximum amount_in
</dd>
</dl>


</details>

<a id="0x1_fixed_swap_FixedSwapConfigTable"></a>

## Resource `FixedSwapConfigTable`

Fixed swap configuration table
Coin -> FixedSwapConfig


<pre><code><b>struct</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>inner: <a href="../../endless-stdlib/doc/table.md#0x1_table_Table">table::Table</a>&lt;<a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;, <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfig">fixed_swap::FixedSwapConfig</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_fixed_swap_FundingAccount"></a>

## Resource `FundingAccount`

Funding account is a resource account that holds the funds of the fixed swap.


<pre><code><b>struct</b> <a href="fixed_swap.md#0x1_fixed_swap_FundingAccount">FundingAccount</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>cap: <a href="account.md#0x1_account_SignerCapability">account::SignerCapability</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_fixed_swap_Swap"></a>

## Struct `Swap`

Emitted when a swap is made.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="fixed_swap.md#0x1_fixed_swap_Swap">Swap</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="account.md#0x1_account">account</a>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>amount_in: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>metadata_in: <a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>amount_out: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>metadata_out: <a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_fixed_swap_ConfigUpdated"></a>

## Struct `ConfigUpdated`

Emitted when a configuration is updated.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="fixed_swap.md#0x1_fixed_swap_ConfigUpdated">ConfigUpdated</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>metadata: <a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>rate_numerator: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>rate_denominator: u128</code>
</dt>
<dd>

</dd>
<dt>
<code><b>min</b>: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>max: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_fixed_swap_ConfigRemoved"></a>

## Struct `ConfigRemoved`

Emitted when a configuration is removed.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="fixed_swap.md#0x1_fixed_swap_ConfigRemoved">ConfigRemoved</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>metadata: <a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_fixed_swap_AdminChanged"></a>

## Struct `AdminChanged`

Emitted when admin is changed.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="fixed_swap.md#0x1_fixed_swap_AdminChanged">AdminChanged</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><b>old</b>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>new: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_fixed_swap_MAX_U64"></a>

Maximum possible aggregatable coin value.


<pre><code><b>const</b> <a href="fixed_swap.md#0x1_fixed_swap_MAX_U64">MAX_U64</a>: u128 = 18446744073709551615;
</code></pre>



<a id="0x1_fixed_swap_EDS_DECIMALS"></a>

EDS decimals


<pre><code><b>const</b> <a href="fixed_swap.md#0x1_fixed_swap_EDS_DECIMALS">EDS_DECIMALS</a>: u8 = 8;
</code></pre>



<a id="0x1_fixed_swap_EAMOUNT_OUT_OF_RANGE"></a>



<pre><code><b>const</b> <a href="fixed_swap.md#0x1_fixed_swap_EAMOUNT_OUT_OF_RANGE">EAMOUNT_OUT_OF_RANGE</a>: u64 = 2;
</code></pre>



<a id="0x1_fixed_swap_EGAS_PRICE_TOO_HIGH"></a>



<pre><code><b>const</b> <a href="fixed_swap.md#0x1_fixed_swap_EGAS_PRICE_TOO_HIGH">EGAS_PRICE_TOO_HIGH</a>: u64 = 3;
</code></pre>



<a id="0x1_fixed_swap_EINVALID_RATE"></a>



<pre><code><b>const</b> <a href="fixed_swap.md#0x1_fixed_swap_EINVALID_RATE">EINVALID_RATE</a>: u64 = 6;
</code></pre>



<a id="0x1_fixed_swap_EOUT_OF_PRICE"></a>



<pre><code><b>const</b> <a href="fixed_swap.md#0x1_fixed_swap_EOUT_OF_PRICE">EOUT_OF_PRICE</a>: u64 = 4;
</code></pre>



<a id="0x1_fixed_swap_EPERMISSION_DENIED"></a>



<pre><code><b>const</b> <a href="fixed_swap.md#0x1_fixed_swap_EPERMISSION_DENIED">EPERMISSION_DENIED</a>: u64 = 5;
</code></pre>



<a id="0x1_fixed_swap_EUNINITIALIZED"></a>



<pre><code><b>const</b> <a href="fixed_swap.md#0x1_fixed_swap_EUNINITIALIZED">EUNINITIALIZED</a>: u64 = 0;
</code></pre>



<a id="0x1_fixed_swap_EUNSPORTED_COIN"></a>



<pre><code><b>const</b> <a href="fixed_swap.md#0x1_fixed_swap_EUNSPORTED_COIN">EUNSPORTED_COIN</a>: u64 = 1;
</code></pre>



<a id="0x1_fixed_swap_MAX_GAS_UNIT_PRICE"></a>

Maximum acceptable gas unit price


<pre><code><b>const</b> <a href="fixed_swap.md#0x1_fixed_swap_MAX_GAS_UNIT_PRICE">MAX_GAS_UNIT_PRICE</a>: u64 = 100;
</code></pre>



<a id="0x1_fixed_swap_initialize"></a>

## Function `initialize`

Only called by genesis
Create funding resource account
Constructor of FixedSwapConfigTable and FundingAccount
Set admin permission


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, admin: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, admin: <b>address</b>) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>let</b> (_, funding_cap) = <a href="account.md#0x1_account_create_resource_account">account::create_resource_account</a>(endless_framework, b"<a href="fixed_swap.md#0x1_fixed_swap">fixed_swap</a> funding <a href="account.md#0x1_account">account</a>");
    <b>move_to</b>(endless_framework, <a href="fixed_swap.md#0x1_fixed_swap_FundingAccount">FundingAccount</a> {
        cap: funding_cap,
    });
    <b>move_to</b>(endless_framework, <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a> {
        inner: <a href="../../endless-stdlib/doc/table.md#0x1_table_new">table::new</a>(),
    });
    <b>move_to</b>(endless_framework, <a href="fixed_swap.md#0x1_fixed_swap_AdminCap">AdminCap</a> { admin });
}
</code></pre>



</details>

<a id="0x1_fixed_swap_funding_address"></a>

## Function `funding_address`

Get funding account address


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_funding_address">funding_address</a>(): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_funding_address">funding_address</a>(): <b>address</b> <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_FundingAccount">FundingAccount</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_FundingAccount">FundingAccount</a>&gt;(@endless_framework), <a href="fixed_swap.md#0x1_fixed_swap_EUNINITIALIZED">EUNINITIALIZED</a>);
    <b>let</b> cap = &<b>borrow_global</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_FundingAccount">FundingAccount</a>&gt;(@endless_framework).cap;
    <a href="account.md#0x1_account_get_signer_capability_address">account::get_signer_capability_address</a>(cap)
}
</code></pre>



</details>

<a id="0x1_fixed_swap_swap_out_amount"></a>

## Function `swap_out_amount`

Get amount out from specific pair and amount in


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_swap_out_amount">swap_out_amount</a>&lt;T: key&gt;(metadata: <a href="object.md#0x1_object_Object">object::Object</a>&lt;T&gt;, amount_in: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_swap_out_amount">swap_out_amount</a>&lt;T: key&gt;(metadata: Object&lt;T&gt;, amount_in: u64): u64 <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a> {
    <b>let</b> metadata = <a href="object.md#0x1_object_convert">object::convert</a>&lt;T, Metadata&gt;(metadata);
    <b>let</b> config = <a href="fixed_swap.md#0x1_fixed_swap_borrow_config">borrow_config</a>(metadata);
    <b>let</b> amount_out = <a href="fixed_swap.md#0x1_fixed_swap_multiply_rate">multiply_rate</a>(amount_in, config);
    (amount_out <b>as</b> u64)
}
</code></pre>



</details>

<a id="0x1_fixed_swap_fixed_swap"></a>

## Function `fixed_swap`

Swap EDS from other coins with a fixed rate


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap">fixed_swap</a>(caller: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, metadata_in: <b>address</b>, amount_in: u64, expected_amount_out: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry sponsored <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap">fixed_swap</a>(
    caller: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    // Avoid using Object&lt;T&gt; at the entry function
    metadata_in: <b>address</b>,
    amount_in: u64,
    expected_amount_out: u64
) <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a>, <a href="fixed_swap.md#0x1_fixed_swap_FundingAccount">FundingAccount</a> {
    // IMPORTANT: gas unit price must be checked <b>to</b> ensure
    // that the overall fee is within controllable range
    <b>assert</b>!(<a href="transaction_context.md#0x1_transaction_context_gas_unit_price">transaction_context::gas_unit_price</a>() &lt;= <a href="fixed_swap.md#0x1_fixed_swap_MAX_GAS_UNIT_PRICE">MAX_GAS_UNIT_PRICE</a>, <a href="fixed_swap.md#0x1_fixed_swap_EGAS_PRICE_TOO_HIGH">EGAS_PRICE_TOO_HIGH</a>);
    <b>let</b> metadata_in = <a href="object.md#0x1_object_address_to_object">object::address_to_object</a>&lt;Metadata&gt;(metadata_in);
    <a href="fixed_swap.md#0x1_fixed_swap_fixed_swap_internal">fixed_swap_internal</a>(caller, metadata_in, amount_in, expected_amount_out);
}
</code></pre>



</details>

<a id="0x1_fixed_swap_upsert_config"></a>

## Function `upsert_config`

Create or Update a config by admin


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_upsert_config">upsert_config</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, metadata: <b>address</b>, rate_numerator: u128, rate_denominator: u128, <b>min</b>: u64, max: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_upsert_config">upsert_config</a>(
    admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    // Avoid using Object&lt;T&gt; at the entry function
    metadata: <b>address</b>,
    rate_numerator: u128,
    rate_denominator: u128,
    <b>min</b>: u64,
    max: u64
) <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a>, <a href="fixed_swap.md#0x1_fixed_swap_AdminCap">AdminCap</a> {
    <a href="fixed_swap.md#0x1_fixed_swap_assert_admin">assert_admin</a>(admin);
    <b>assert</b>!(rate_numerator != 0, <a href="fixed_swap.md#0x1_fixed_swap_EINVALID_RATE">EINVALID_RATE</a>);
    <b>assert</b>!(rate_denominator != 0, <a href="fixed_swap.md#0x1_fixed_swap_EINVALID_RATE">EINVALID_RATE</a>);
    <b>let</b> metadata = <a href="object.md#0x1_object_address_to_object">object::address_to_object</a>&lt;Metadata&gt;(metadata);
    // src coin decimals
    <b>let</b> src_decimals = <a href="fungible_asset.md#0x1_fungible_asset_decimals">fungible_asset::decimals</a>(metadata);
    <b>if</b> (src_decimals &lt; <a href="fixed_swap.md#0x1_fixed_swap_EDS_DECIMALS">EDS_DECIMALS</a>) {
        rate_numerator = rate_numerator * <a href="../../endless-stdlib/doc/math128.md#0x1_math128_pow">math128::pow</a>(10, ((<a href="fixed_swap.md#0x1_fixed_swap_EDS_DECIMALS">EDS_DECIMALS</a> - src_decimals) <b>as</b> u128));
    } <b>else</b> <b>if</b> (src_decimals &gt; <a href="fixed_swap.md#0x1_fixed_swap_EDS_DECIMALS">EDS_DECIMALS</a>) {
        rate_denominator = rate_denominator * <a href="../../endless-stdlib/doc/math128.md#0x1_math128_pow">math128::pow</a>(10, ((src_decimals - <a href="fixed_swap.md#0x1_fixed_swap_EDS_DECIMALS">EDS_DECIMALS</a>) <b>as</b> u128));
    };

    <b>let</b> config_table = <a href="fixed_swap.md#0x1_fixed_swap_borrow_config_table_mut">borrow_config_table_mut</a>();
    <a href="../../endless-stdlib/doc/table.md#0x1_table_upsert">table::upsert</a>(&<b>mut</b> config_table.inner, metadata, <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfig">FixedSwapConfig</a> {
        rate_numerator,
        rate_denominator,
        <b>min</b>,
        max,
    });

    <a href="event.md#0x1_event_emit">event::emit</a>(<a href="fixed_swap.md#0x1_fixed_swap_ConfigUpdated">ConfigUpdated</a> {
        metadata,
        rate_numerator,
        rate_denominator,
        <b>min</b>,
        max,
    });
}
</code></pre>



</details>

<a id="0x1_fixed_swap_remove_config"></a>

## Function `remove_config`

Remove a config by admin
Aborts if config not exists


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_remove_config">remove_config</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, metadata: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_remove_config">remove_config</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, metadata: <b>address</b>) <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a>, <a href="fixed_swap.md#0x1_fixed_swap_AdminCap">AdminCap</a> {
    <a href="fixed_swap.md#0x1_fixed_swap_assert_admin">assert_admin</a>(admin);
    <b>let</b> metadata = <a href="object.md#0x1_object_address_to_object">object::address_to_object</a>&lt;Metadata&gt;(metadata);
    <b>let</b> config_table = <a href="fixed_swap.md#0x1_fixed_swap_borrow_config_table_mut">borrow_config_table_mut</a>();
    <a href="../../endless-stdlib/doc/table.md#0x1_table_remove">table::remove</a>(&<b>mut</b> config_table.inner, metadata);

    <a href="event.md#0x1_event_emit">event::emit</a>(<a href="fixed_swap.md#0x1_fixed_swap_ConfigRemoved">ConfigRemoved</a> {
        metadata,
    });
}
</code></pre>



</details>

<a id="0x1_fixed_swap_transfer_admin_cap"></a>

## Function `transfer_admin_cap`

Transfer admin cap to another account


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_transfer_admin_cap">transfer_admin_cap</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_admin: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_transfer_admin_cap">transfer_admin_cap</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_admin: <b>address</b>) <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_AdminCap">AdminCap</a> {
    <a href="fixed_swap.md#0x1_fixed_swap_assert_admin">assert_admin</a>(admin);
    <b>let</b> cap = <b>borrow_global_mut</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_AdminCap">AdminCap</a>&gt;(@endless_framework);
    cap.admin = new_admin;

    <a href="event.md#0x1_event_emit">event::emit</a>(<a href="fixed_swap.md#0x1_fixed_swap_AdminChanged">AdminChanged</a> {
        <b>old</b>: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(admin),
        new: new_admin,
    });
}
</code></pre>



</details>

<a id="0x1_fixed_swap_fixed_swap_internal"></a>

## Function `fixed_swap_internal`



<pre><code><b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_fixed_swap_internal">fixed_swap_internal</a>(caller: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, metadata_in: <a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;, amount_in: u64, expected_amount_out: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_fixed_swap_internal">fixed_swap_internal</a>(
    caller: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    metadata_in: Object&lt;Metadata&gt;,
    amount_in: u64,
    expected_amount_out: u64
) <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a>, <a href="fixed_swap.md#0x1_fixed_swap_FundingAccount">FundingAccount</a> {
    // <b>abort</b> <b>if</b> config <a href="../../endless-stdlib/doc/table.md#0x1_table">table</a> uninitialized or coin not supported
    <b>let</b> config = <a href="fixed_swap.md#0x1_fixed_swap_borrow_config">borrow_config</a>(metadata_in);

    // check amount_in
    <b>assert</b>!(amount_in &gt;= config.<b>min</b>, <a href="fixed_swap.md#0x1_fixed_swap_EAMOUNT_OUT_OF_RANGE">EAMOUNT_OUT_OF_RANGE</a>);
    <b>assert</b>!(amount_in &lt;= config.max, <a href="fixed_swap.md#0x1_fixed_swap_EAMOUNT_OUT_OF_RANGE">EAMOUNT_OUT_OF_RANGE</a>);

    // check amount_out
    <b>let</b> amount_out = <a href="fixed_swap.md#0x1_fixed_swap_multiply_rate">multiply_rate</a>(amount_in, config);
    <b>assert</b>!(amount_out == expected_amount_out, <a href="fixed_swap.md#0x1_fixed_swap_EOUT_OF_PRICE">EOUT_OF_PRICE</a>);

    <b>let</b> (funding_addr, funding_signer) = <a href="fixed_swap.md#0x1_fixed_swap_borrow_funding_account">borrow_funding_account</a>();
    // receiving
    // TODO recipient
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_transfer">primary_fungible_store::transfer</a>(caller, metadata_in, funding_addr, amount_in);
    // sending
    <a href="endless_coin.md#0x1_endless_coin_transfer">endless_coin::transfer</a>(funding_signer, <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(caller), amount_out);

    <a href="event.md#0x1_event_emit">event::emit</a>(<a href="fixed_swap.md#0x1_fixed_swap_Swap">Swap</a> {
        <a href="account.md#0x1_account">account</a>: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(caller),
        amount_in,
        metadata_in,
        amount_out,
        metadata_out: <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>(),
    });
}
</code></pre>



</details>

<a id="0x1_fixed_swap_assert_admin"></a>

## Function `assert_admin`



<pre><code><b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_assert_admin">assert_admin</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_assert_admin">assert_admin</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_AdminCap">AdminCap</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_AdminCap">AdminCap</a>&gt;(@endless_framework), <a href="fixed_swap.md#0x1_fixed_swap_EUNINITIALIZED">EUNINITIALIZED</a>);
    <b>assert</b>!(<b>borrow_global</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_AdminCap">AdminCap</a>&gt;(@endless_framework).admin == <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(admin), <a href="fixed_swap.md#0x1_fixed_swap_EPERMISSION_DENIED">EPERMISSION_DENIED</a>);
}
</code></pre>



</details>

<a id="0x1_fixed_swap_borrow_config"></a>

## Function `borrow_config`



<pre><code><b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_borrow_config">borrow_config</a>(metadata: <a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;): &<a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfig">fixed_swap::FixedSwapConfig</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_borrow_config">borrow_config</a>(metadata: Object&lt;Metadata&gt;): &<a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfig">FixedSwapConfig</a> <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a>&gt;(@endless_framework), <a href="fixed_swap.md#0x1_fixed_swap_EUNINITIALIZED">EUNINITIALIZED</a>);
    <b>let</b> config_table = <b>borrow_global</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a>&gt;(@endless_framework);
    <b>assert</b>!(<a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(&config_table.inner, metadata), <a href="fixed_swap.md#0x1_fixed_swap_EUNSPORTED_COIN">EUNSPORTED_COIN</a>);
    <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(&config_table.inner, metadata)
}
</code></pre>



</details>

<a id="0x1_fixed_swap_borrow_config_table_mut"></a>

## Function `borrow_config_table_mut`



<pre><code><b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_borrow_config_table_mut">borrow_config_table_mut</a>(): &<b>mut</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">fixed_swap::FixedSwapConfigTable</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_borrow_config_table_mut">borrow_config_table_mut</a>(): &<b>mut</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a> <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a>&gt;(@endless_framework), <a href="fixed_swap.md#0x1_fixed_swap_EUNINITIALIZED">EUNINITIALIZED</a>);
    <b>borrow_global_mut</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfigTable">FixedSwapConfigTable</a>&gt;(@endless_framework)
}
</code></pre>



</details>

<a id="0x1_fixed_swap_borrow_funding_account"></a>

## Function `borrow_funding_account`



<pre><code><b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_borrow_funding_account">borrow_funding_account</a>(): (<b>address</b>, &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_borrow_funding_account">borrow_funding_account</a>(): (<b>address</b>, &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="fixed_swap.md#0x1_fixed_swap_FundingAccount">FundingAccount</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_FundingAccount">FundingAccount</a>&gt;(@endless_framework), <a href="fixed_swap.md#0x1_fixed_swap_EUNINITIALIZED">EUNINITIALIZED</a>);
    <b>let</b> cap = &<b>borrow_global</b>&lt;<a href="fixed_swap.md#0x1_fixed_swap_FundingAccount">FundingAccount</a>&gt;(@endless_framework).cap;
    <b>let</b> a = <a href="account.md#0x1_account_get_signer_capability_address">account::get_signer_capability_address</a>(cap);
    <b>let</b> s = &<a href="account.md#0x1_account_create_signer_with_capability">account::create_signer_with_capability</a>(cap);
    (a, s)
}
</code></pre>



</details>

<a id="0x1_fixed_swap_multiply_rate"></a>

## Function `multiply_rate`



<pre><code><b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_multiply_rate">multiply_rate</a>(amount_in: u64, config: &<a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfig">fixed_swap::FixedSwapConfig</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_multiply_rate">multiply_rate</a>(amount_in: u64, config: &<a href="fixed_swap.md#0x1_fixed_swap_FixedSwapConfig">FixedSwapConfig</a>): u64 {
    <b>let</b> amount_out = (amount_in <b>as</b> u128) * config.rate_numerator / config.rate_denominator;
    <b>assert</b>!(amount_out &lt;= <a href="fixed_swap.md#0x1_fixed_swap_MAX_U64">MAX_U64</a>, <a href="fixed_swap.md#0x1_fixed_swap_EAMOUNT_OUT_OF_RANGE">EAMOUNT_OUT_OF_RANGE</a>);
    (amount_out <b>as</b> u64)
}
</code></pre>



</details>

<a id="@Specification_1"></a>

## Specification


<a id="@Specification_1_initialize"></a>

### Function `initialize`


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, admin: <b>address</b>)
</code></pre>




<pre><code><b>pragma</b> opaque;
</code></pre>



<a id="@Specification_1_fixed_swap"></a>

### Function `fixed_swap`


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap">fixed_swap</a>(caller: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, metadata_in: <b>address</b>, amount_in: u64, expected_amount_out: u64)
</code></pre>




<pre><code><b>pragma</b> opaque;
</code></pre>



<a id="@Specification_1_upsert_config"></a>

### Function `upsert_config`


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_upsert_config">upsert_config</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, metadata: <b>address</b>, rate_numerator: u128, rate_denominator: u128, <b>min</b>: u64, max: u64)
</code></pre>




<pre><code><b>pragma</b> opaque;
</code></pre>



<a id="@Specification_1_remove_config"></a>

### Function `remove_config`


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_remove_config">remove_config</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, metadata: <b>address</b>)
</code></pre>




<pre><code><b>pragma</b> opaque;
</code></pre>



<a id="@Specification_1_transfer_admin_cap"></a>

### Function `transfer_admin_cap`


<pre><code><b>public</b> entry <b>fun</b> <a href="fixed_swap.md#0x1_fixed_swap_transfer_admin_cap">transfer_admin_cap</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_admin: <b>address</b>)
</code></pre>




<pre><code><b>pragma</b> opaque;
</code></pre>


[move-book]: https://endless.dev/move/book/SUMMARY

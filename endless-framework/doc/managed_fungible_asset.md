
<a id="0x1_managed_fungible_asset"></a>

# Module `0x1::managed_fungible_asset`

A 2-in-1 module that combines managed_fungible_asset and coin_example into one module that when deployed, the
deployer will be creating a new managed fungible asset with the hardcoded supply config, name, symbol, and decimals.
The address of the asset can be obtained via get_metadata(). As a simple version, it only deals with primary stores.


-  [Resource `ManagedFungibleAsset`](#0x1_managed_fungible_asset_ManagedFungibleAsset)
-  [Resource `GlobalData`](#0x1_managed_fungible_asset_GlobalData)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_managed_fungible_asset_initialize)
-  [Function `create`](#0x1_managed_fungible_asset_create)
-  [Function `get_metadata`](#0x1_managed_fungible_asset_get_metadata)
-  [Function `mint`](#0x1_managed_fungible_asset_mint)
-  [Function `transfer`](#0x1_managed_fungible_asset_transfer)
-  [Function `burn`](#0x1_managed_fungible_asset_burn)
-  [Function `freeze_account`](#0x1_managed_fungible_asset_freeze_account)
-  [Function `unfreeze_account`](#0x1_managed_fungible_asset_unfreeze_account)
-  [Function `withdraw`](#0x1_managed_fungible_asset_withdraw)
-  [Function `deposit`](#0x1_managed_fungible_asset_deposit)
-  [Function `get_owner_coins`](#0x1_managed_fungible_asset_get_owner_coins)
-  [Function `authorized_borrow_refs`](#0x1_managed_fungible_asset_authorized_borrow_refs)


<pre><code><b>use</b> <a href="../../endless-stdlib/doc/debug.md#0x1_debug">0x1::debug</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="fungible_asset.md#0x1_fungible_asset">0x1::fungible_asset</a>;
<b>use</b> <a href="object.md#0x1_object">0x1::object</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="primary_fungible_store.md#0x1_primary_fungible_store">0x1::primary_fungible_store</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="../../endless-stdlib/doc/table.md#0x1_table">0x1::table</a>;
</code></pre>



<a id="0x1_managed_fungible_asset_ManagedFungibleAsset"></a>

## Resource `ManagedFungibleAsset`

Hold refs to control the minting, transfer and burning of fungible assets.


<pre><code>#[resource_group_member(#[group = <a href="object.md#0x1_object_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>mint_ref: <a href="fungible_asset.md#0x1_fungible_asset_MintRef">fungible_asset::MintRef</a></code>
</dt>
<dd>

</dd>
<dt>
<code>transfer_ref: <a href="fungible_asset.md#0x1_fungible_asset_TransferRef">fungible_asset::TransferRef</a></code>
</dt>
<dd>

</dd>
<dt>
<code>burn_ref: <a href="fungible_asset.md#0x1_fungible_asset_BurnRef">fungible_asset::BurnRef</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_managed_fungible_asset_GlobalData"></a>

## Resource `GlobalData`



<pre><code><b>struct</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_GlobalData">GlobalData</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>coins_table: <a href="../../endless-stdlib/doc/table.md#0x1_table_Table">table::Table</a>&lt;<b>address</b>, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_managed_fungible_asset_ENOT_OWNER"></a>

Only fungible asset metadata owner can make changes.


<pre><code><b>const</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ENOT_OWNER">ENOT_OWNER</a>: u64 = 1;
</code></pre>



<a id="0x1_managed_fungible_asset_initialize"></a>

## Function `initialize`

Initialize metadata object and store the refs.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_initialize">initialize</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_initialize">initialize</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <b>move_to</b>(
        admin,
        <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_GlobalData">GlobalData</a> { coins_table: <a href="../../endless-stdlib/doc/table.md#0x1_table_new">table::new</a>() }
    )// &lt;:!:initialize
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_create"></a>

## Function `create`

Create metadata object and store the refs.


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_create">create</a>(caller: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, symbol: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, decimals: u8, icon: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, project: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_create">create</a>(
    caller: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    symbol: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    decimals: u8,
    icon: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    project: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) <b>acquires</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_GlobalData">GlobalData</a> {
    <b>let</b> caller_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(caller);
    <b>let</b> constructor_ref = &<a href="object.md#0x1_object_create_sticky_object">object::create_sticky_object</a>(caller_address);
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_create_primary_store_enabled_fungible_asset">primary_fungible_store::create_primary_store_enabled_fungible_asset</a>(
        constructor_ref,
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>(),
        utf8(name),
        utf8(symbol),
        decimals,
        utf8(icon),
        utf8(project),
    );

    // Create mint/burn/transfer refs <b>to</b> allow creator <b>to</b> manage the fungible asset.
    <b>let</b> mint_ref = <a href="fungible_asset.md#0x1_fungible_asset_generate_mint_ref">fungible_asset::generate_mint_ref</a>(constructor_ref);
    <b>let</b> burn_ref = <a href="fungible_asset.md#0x1_fungible_asset_generate_burn_ref">fungible_asset::generate_burn_ref</a>(constructor_ref);
    <b>let</b> transfer_ref = <a href="fungible_asset.md#0x1_fungible_asset_generate_transfer_ref">fungible_asset::generate_transfer_ref</a>(constructor_ref);
    <b>let</b> metadata_object_signer = <a href="object.md#0x1_object_generate_signer">object::generate_signer</a>(constructor_ref);
    <b>move_to</b>(
        &metadata_object_signer,
        <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a> { mint_ref, transfer_ref, burn_ref }
    );

    // Add <a href="../../endless-stdlib/doc/table.md#0x1_table">table</a>
    <b>let</b> asset_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(&metadata_object_signer);
    print(&asset_address);
    <b>let</b> coins_table = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_GlobalData">GlobalData</a>&gt;(@endless_framework).coins_table;
    <b>if</b> (<a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(coins_table, caller_address)) {
       <b>let</b> coin_vec = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow_mut">table::borrow_mut</a>(coins_table, caller_address);
       <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(coin_vec, asset_address);
    } <b>else</b> {
        <b>let</b> coin_vec = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[asset_address];
        <a href="../../endless-stdlib/doc/table.md#0x1_table_add">table::add</a>(coins_table, caller_address, coin_vec);
    }
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_get_metadata"></a>

## Function `get_metadata`

Return the address of the managed fungible asset that's created when this module is deployed.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_metadata">get_metadata</a>(asset_address: <b>address</b>): <a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_metadata">get_metadata</a>(asset_address: <b>address</b>): Object&lt;Metadata&gt; {
    <a href="object.md#0x1_object_address_to_object">object::address_to_object</a>&lt;Metadata&gt;(asset_address)
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_mint"></a>

## Function `mint`

Mint as the owner of metadata object and deposit to a specific account.


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_mint">mint</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <b>to</b>: <b>address</b>, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_mint">mint</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <b>to</b>: <b>address</b>, amount: u64) <b>acquires</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a> {
    <b>let</b> asset = <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_metadata">get_metadata</a>(asset);
    <b>let</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset">managed_fungible_asset</a> = <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_authorized_borrow_refs">authorized_borrow_refs</a>(admin, asset);
    <b>let</b> to_wallet = <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<b>to</b>, asset);
    <b>let</b> fa = <a href="fungible_asset.md#0x1_fungible_asset_mint">fungible_asset::mint</a>(&<a href="managed_fungible_asset.md#0x1_managed_fungible_asset">managed_fungible_asset</a>.mint_ref, amount);
    <a href="fungible_asset.md#0x1_fungible_asset_deposit_with_ref">fungible_asset::deposit_with_ref</a>(&<a href="managed_fungible_asset.md#0x1_managed_fungible_asset">managed_fungible_asset</a>.transfer_ref, to_wallet, fa);
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_transfer"></a>

## Function `transfer`

Transfer as the owner of metadata object ignoring <code>frozen</code> field.


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_transfer">transfer</a>(sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, from: <b>address</b>, <b>to</b>: <b>address</b>, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_transfer">transfer</a>(sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, from: <b>address</b>, <b>to</b>: <b>address</b>, amount: u64) {
    <b>let</b> asset = <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_metadata">get_metadata</a>(asset);
    <b>let</b> from_wallet = <a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store">primary_fungible_store::primary_store</a>(from, asset);
    <b>let</b> to_wallet = <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<b>to</b>, asset);
    <a href="fungible_asset.md#0x1_fungible_asset_transfer">fungible_asset::transfer</a>(sender, from_wallet, to_wallet, amount);
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_burn"></a>

## Function `burn`

Burn fungible assets as the owner of metadata object.


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_burn">burn</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, from: <b>address</b>, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_burn">burn</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, from: <b>address</b>, amount: u64) <b>acquires</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a> {
    <b>let</b> asset = <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_metadata">get_metadata</a>(asset);
    <b>let</b> burn_ref = &<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_authorized_borrow_refs">authorized_borrow_refs</a>(admin, asset).burn_ref;
    <b>let</b> from_wallet = <a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store">primary_fungible_store::primary_store</a>(from, asset);
    <a href="fungible_asset.md#0x1_fungible_asset_burn_from">fungible_asset::burn_from</a>(burn_ref, from_wallet, amount);
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_freeze_account"></a>

## Function `freeze_account`

Freeze an account so it cannot transfer or receive fungible assets.


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_freeze_account">freeze_account</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <a href="account.md#0x1_account">account</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_freeze_account">freeze_account</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <a href="account.md#0x1_account">account</a>: <b>address</b>) <b>acquires</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a> {
    <b>let</b> asset = <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_metadata">get_metadata</a>(asset);
    <b>let</b> transfer_ref = &<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_authorized_borrow_refs">authorized_borrow_refs</a>(admin, asset).transfer_ref;
    <b>let</b> wallet = <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<a href="account.md#0x1_account">account</a>, asset);
    <a href="fungible_asset.md#0x1_fungible_asset_set_frozen_flag">fungible_asset::set_frozen_flag</a>(transfer_ref, wallet, <b>true</b>);
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_unfreeze_account"></a>

## Function `unfreeze_account`

Unfreeze an account so it can transfer or receive fungible assets.


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_unfreeze_account">unfreeze_account</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <a href="account.md#0x1_account">account</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_unfreeze_account">unfreeze_account</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <a href="account.md#0x1_account">account</a>: <b>address</b>) <b>acquires</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a> {
    <b>let</b> asset = <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_metadata">get_metadata</a>(asset);
    <b>let</b> transfer_ref = &<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_authorized_borrow_refs">authorized_borrow_refs</a>(admin, asset).transfer_ref;
    <b>let</b> wallet = <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<a href="account.md#0x1_account">account</a>, asset);
    <a href="fungible_asset.md#0x1_fungible_asset_set_frozen_flag">fungible_asset::set_frozen_flag</a>(transfer_ref, wallet, <b>false</b>);
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_withdraw"></a>

## Function `withdraw`

Withdraw as the owner of metadata object ignoring <code>frozen</code> field.


<pre><code><b>public</b> <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_withdraw">withdraw</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, amount: u64, from: <b>address</b>): <a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_withdraw">withdraw</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, amount: u64, from: <b>address</b>): FungibleAsset <b>acquires</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a> {
    <b>let</b> asset = <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_metadata">get_metadata</a>(asset);
    <b>let</b> transfer_ref = &<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_authorized_borrow_refs">authorized_borrow_refs</a>(admin, asset).transfer_ref;
    <b>let</b> from_wallet = <a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store">primary_fungible_store::primary_store</a>(from, asset);
    <a href="fungible_asset.md#0x1_fungible_asset_withdraw_with_ref">fungible_asset::withdraw_with_ref</a>(transfer_ref, from_wallet, amount)
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_deposit"></a>

## Function `deposit`

Deposit as the owner of metadata object ignoring <code>frozen</code> field.


<pre><code><b>public</b> <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_deposit">deposit</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <b>to</b>: <b>address</b>, fa: <a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_deposit">deposit</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <b>to</b>: <b>address</b>, fa: FungibleAsset) <b>acquires</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a> {
    <b>let</b> asset = <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_metadata">get_metadata</a>(asset);
    <b>let</b> transfer_ref = &<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_authorized_borrow_refs">authorized_borrow_refs</a>(admin, asset).transfer_ref;
    <b>let</b> to_wallet = <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<b>to</b>, asset);
    <a href="fungible_asset.md#0x1_fungible_asset_deposit_with_ref">fungible_asset::deposit_with_ref</a>(transfer_ref, to_wallet, fa);
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_get_owner_coins"></a>

## Function `get_owner_coins`

Get owner coins


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_owner_coins">get_owner_coins</a>(owner: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_get_owner_coins">get_owner_coins</a>(owner: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt; <b>acquires</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_GlobalData">GlobalData</a> {
    <b>let</b> globaldata_resource = <b>borrow_global</b>&lt;<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_GlobalData">GlobalData</a>&gt;(@endless_framework);
    *<a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(&globaldata_resource.coins_table, owner)
}
</code></pre>



</details>

<a id="0x1_managed_fungible_asset_authorized_borrow_refs"></a>

## Function `authorized_borrow_refs`

Borrow the immutable reference of the refs of <code>metadata</code>.
This validates that the signer is the metadata object's owner.


<pre><code><b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_authorized_borrow_refs">authorized_borrow_refs</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;): &<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">managed_fungible_asset::ManagedFungibleAsset</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_authorized_borrow_refs">authorized_borrow_refs</a>(
    owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    asset: Object&lt;Metadata&gt;,
): &<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a> <b>acquires</b> <a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a> {
    <b>assert</b>!(<a href="object.md#0x1_object_is_owner">object::is_owner</a>(asset, <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner)), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ENOT_OWNER">ENOT_OWNER</a>));
    <b>borrow_global</b>&lt;<a href="managed_fungible_asset.md#0x1_managed_fungible_asset_ManagedFungibleAsset">ManagedFungibleAsset</a>&gt;(<a href="object.md#0x1_object_object_address">object::object_address</a>(&asset))
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

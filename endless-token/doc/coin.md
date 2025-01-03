
<a id="0x4_coin"></a>

# Module `0x4::coin`

A 2-in-1 module that combines managed_fungible_asset and coin_example into one module that when deployed, the
deployer will be creating a new managed fungible asset with the hardcoded supply config, name, symbol, and decimals.
The address of the asset can be obtained via get_metadata(). As a simple version, it only deals with primary stores.


-  [Resource `MgmnFAMint`](#0x4_coin_MgmnFAMint)
-  [Resource `MgmnFABurn`](#0x4_coin_MgmnFABurn)
-  [Resource `MgmnFATransfer`](#0x4_coin_MgmnFATransfer)
-  [Constants](#@Constants_0)
-  [Function `create`](#0x4_coin_create)
-  [Function `create_ex`](#0x4_coin_create_ex)
-  [Function `get_metadata`](#0x4_coin_get_metadata)
-  [Function `supply`](#0x4_coin_supply)
-  [Function `maximum`](#0x4_coin_maximum)
-  [Function `balance`](#0x4_coin_balance)
-  [Function `is_frozen`](#0x4_coin_is_frozen)
-  [Function `mint`](#0x4_coin_mint)
-  [Function `transfer`](#0x4_coin_transfer)
-  [Function `burn`](#0x4_coin_burn)
-  [Function `freeze_account`](#0x4_coin_freeze_account)
-  [Function `unfreeze_account`](#0x4_coin_unfreeze_account)
-  [Function `destroy_mint_cap`](#0x4_coin_destroy_mint_cap)
-  [Function `destroy_burn_cap`](#0x4_coin_destroy_burn_cap)
-  [Function `destroy_transfer_cap`](#0x4_coin_destroy_transfer_cap)
-  [Function `set_icon_uri`](#0x4_coin_set_icon_uri)
-  [Function `set_project_uri`](#0x4_coin_set_project_uri)
-  [Function `authorized_borrow_mint_refs`](#0x4_coin_authorized_borrow_mint_refs)
-  [Function `borrow_burn_refs`](#0x4_coin_borrow_burn_refs)
-  [Function `authorized_borrow_transfer_refs`](#0x4_coin_authorized_borrow_transfer_refs)


<pre><code><b>use</b> <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset">0x1::fungible_asset</a>;
<b>use</b> <a href="../../endless-framework/doc/object.md#0x1_object">0x1::object</a>;
<b>use</b> <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store">0x1::primary_fungible_store</a>;
<b>use</b> <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string">0x1::string</a>;
</code></pre>



<a id="0x4_coin_MgmnFAMint"></a>

## Resource `MgmnFAMint`

Hold refs to control the minting of fungible assets.


<pre><code>#[resource_group_member(#[group = <a href="../../endless-framework/doc/object.md#0x1_object_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="coin.md#0x4_coin_MgmnFAMint">MgmnFAMint</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>mint_ref: <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_MintRef">fungible_asset::MintRef</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x4_coin_MgmnFABurn"></a>

## Resource `MgmnFABurn`

Hold refs to control the burning of fungible assets.


<pre><code>#[resource_group_member(#[group = <a href="../../endless-framework/doc/object.md#0x1_object_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="coin.md#0x4_coin_MgmnFABurn">MgmnFABurn</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>burn_ref: <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_BurnRef">fungible_asset::BurnRef</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x4_coin_MgmnFATransfer"></a>

## Resource `MgmnFATransfer`

Hold refs to control the transfer of fungible assets.


<pre><code>#[resource_group_member(#[group = <a href="../../endless-framework/doc/object.md#0x1_object_ObjectGroup">0x1::object::ObjectGroup</a>])]
<b>struct</b> <a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>transfer_ref: <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_TransferRef">fungible_asset::TransferRef</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x4_coin_ENOT_OWNER"></a>

Only fungible asset metadata owner can make changes.


<pre><code><b>const</b> <a href="coin.md#0x4_coin_ENOT_OWNER">ENOT_OWNER</a>: u64 = 1;
</code></pre>



<a id="0x4_coin_create"></a>

## Function `create`

Create metadata object and store the refs.


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_create">create</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, max_supply: u128, name: <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>, symbol: <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>, decimals: u8, icon_uri: <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>, project_uri: <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_create">create</a>(
    creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    max_supply: u128,
    name: String,
    symbol: String,
    decimals: u8,
    icon_uri: String,
    project_uri: String
) {
    <b>let</b> constructor_ref = &<a href="../../endless-framework/doc/object.md#0x1_object_create_sticky_object">object::create_sticky_object</a>(<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(creator));
    <b>let</b> max_supply = <b>if</b> (max_supply == 0) {
        <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(max_supply)
    };
    <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store_create_primary_store_enabled_fungible_asset">primary_fungible_store::create_primary_store_enabled_fungible_asset</a>(
        constructor_ref,
        max_supply,
        name,
        symbol,
        decimals,
        icon_uri,
        project_uri
    );

    // Create mint/burn/transfer refs <b>to</b> allow creator <b>to</b> manage the fungible asset.
    <b>let</b> mint_ref = <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_generate_mint_ref">fungible_asset::generate_mint_ref</a>(constructor_ref);
    <b>let</b> burn_ref = <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_generate_burn_ref">fungible_asset::generate_burn_ref</a>(constructor_ref);
    <b>let</b> transfer_ref = <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_generate_transfer_ref">fungible_asset::generate_transfer_ref</a>(constructor_ref);
    <b>let</b> metadata_object_signer = <a href="../../endless-framework/doc/object.md#0x1_object_generate_signer">object::generate_signer</a>(constructor_ref);
    <b>move_to</b>(&metadata_object_signer, <a href="coin.md#0x4_coin_MgmnFAMint">MgmnFAMint</a> { mint_ref });
    <b>move_to</b>(&metadata_object_signer, <a href="coin.md#0x4_coin_MgmnFABurn">MgmnFABurn</a> { burn_ref });
    <b>move_to</b>(&metadata_object_signer, <a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a> { transfer_ref });
}
</code></pre>



</details>

<a id="0x4_coin_create_ex"></a>

## Function `create_ex`

Create metadata object and store the refs.


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_create_ex">create_ex</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, coin_author: &auth, max_supply: u128, name: <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>, symbol: <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>, decimals: u8, icon_uri: <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>, project_uri: <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_create_ex">create_ex</a>(
    creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    coin_author: &auth,
    max_supply: u128,
    name: String,
    symbol: String,
    decimals: u8,
    icon_uri: String,
    project_uri: String
) {
    <b>let</b> constructor_ref = &<a href="../../endless-framework/doc/object.md#0x1_object_create_specific_object">object::create_specific_object</a>(creator, coin_author);
    <b>let</b> max_supply = <b>if</b> (max_supply == 0) {
        <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(max_supply)
    };
    <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store_create_primary_store_enabled_fungible_asset">primary_fungible_store::create_primary_store_enabled_fungible_asset</a>(
        constructor_ref,
        max_supply,
        name,
        symbol,
        decimals,
        icon_uri,
        project_uri
    );

    // Create mint/burn/transfer refs <b>to</b> allow creator <b>to</b> manage the fungible asset.
    <b>let</b> mint_ref = <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_generate_mint_ref">fungible_asset::generate_mint_ref</a>(constructor_ref);
    <b>let</b> burn_ref = <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_generate_burn_ref">fungible_asset::generate_burn_ref</a>(constructor_ref);
    <b>let</b> transfer_ref = <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_generate_transfer_ref">fungible_asset::generate_transfer_ref</a>(constructor_ref);
    <b>let</b> metadata_object_signer = <a href="../../endless-framework/doc/object.md#0x1_object_generate_signer">object::generate_signer</a>(constructor_ref);
    <b>move_to</b>(&metadata_object_signer, <a href="coin.md#0x4_coin_MgmnFAMint">MgmnFAMint</a> { mint_ref });
    <b>move_to</b>(&metadata_object_signer, <a href="coin.md#0x4_coin_MgmnFABurn">MgmnFABurn</a> { burn_ref });
    <b>move_to</b>(&metadata_object_signer, <a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a> { transfer_ref });
}
</code></pre>



</details>

<a id="0x4_coin_get_metadata"></a>

## Function `get_metadata`

Return the address of the managed fungible asset that's created when this module is deployed.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset_address: <b>address</b>): <a href="../../endless-framework/doc/object.md#0x1_object_Object">object::Object</a>&lt;<a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset_address: <b>address</b>): Object&lt;Metadata&gt; {
    <a href="../../endless-framework/doc/object.md#0x1_object_address_to_object">object::address_to_object</a>&lt;Metadata&gt;(asset_address)
}
</code></pre>



</details>

<a id="0x4_coin_supply"></a>

## Function `supply`

Get the current supply from the <code>metadata</code> object.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin.md#0x4_coin_supply">supply</a>(asset: <b>address</b>): <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;u128&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coin.md#0x4_coin_supply">supply</a>(asset: <b>address</b>): Option&lt;u128&gt; {
    <b>let</b> metadata = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_supply">fungible_asset::supply</a>(metadata)
}
</code></pre>



</details>

<a id="0x4_coin_maximum"></a>

## Function `maximum`

Get the maximum supply from the <code>metadata</code> object.
If supply is unlimited (or set explicitly to MAX_U128), none is returned


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin.md#0x4_coin_maximum">maximum</a>(asset: <b>address</b>): <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;u128&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coin.md#0x4_coin_maximum">maximum</a>(asset: <b>address</b>): Option&lt;u128&gt; {
    <b>let</b> metadata = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_maximum">fungible_asset::maximum</a>(metadata)
}
</code></pre>



</details>

<a id="0x4_coin_balance"></a>

## Function `balance`

Get the balance of <code><a href="../../endless-framework/doc/account.md#0x1_account">account</a></code>'s primary store.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin.md#0x4_coin_balance">balance</a>(owner_address: <b>address</b>, asset: <b>address</b>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coin.md#0x4_coin_balance">balance</a>(owner_address: <b>address</b>, asset: <b>address</b>): u128 {
    <b>let</b> metadata = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store_balance">primary_fungible_store::balance</a>(owner_address, metadata)
}
</code></pre>



</details>

<a id="0x4_coin_is_frozen"></a>

## Function `is_frozen`

Return whether the given account's primary store is frozen.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="coin.md#0x4_coin_is_frozen">is_frozen</a>(owner_address: <b>address</b>, asset: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coin.md#0x4_coin_is_frozen">is_frozen</a>(owner_address: <b>address</b>, asset: <b>address</b>): bool {
    <b>let</b> metadata = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store_is_frozen">primary_fungible_store::is_frozen</a>(owner_address, metadata)
}
</code></pre>



</details>

<a id="0x4_coin_mint"></a>

## Function `mint`

Mint as the owner of metadata object and deposit to a specific account.


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_mint">mint</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <b>to</b>: <b>address</b>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_mint">mint</a>(
    creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    asset: <b>address</b>,
    <b>to</b>: <b>address</b>,
    amount: u128
) <b>acquires</b> <a href="coin.md#0x4_coin_MgmnFAMint">MgmnFAMint</a>, <a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a> {
    <b>let</b> asset = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <b>let</b> mint_ref = <a href="coin.md#0x4_coin_authorized_borrow_mint_refs">authorized_borrow_mint_refs</a>(creator, asset).mint_ref;
    <b>let</b> transfer_ref = <a href="coin.md#0x4_coin_authorized_borrow_transfer_refs">authorized_borrow_transfer_refs</a>(creator, asset).transfer_ref;
    <b>let</b> to_wallet = <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<b>to</b>, asset);
    <b>let</b> fa = <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_mint">fungible_asset::mint</a>(&mint_ref, amount);
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_deposit_with_ref">fungible_asset::deposit_with_ref</a>(&transfer_ref, to_wallet, fa);
}
</code></pre>



</details>

<a id="0x4_coin_transfer"></a>

## Function `transfer`

Transfer as the owner of metadata object ignoring <code>frozen</code> field.


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_transfer">transfer</a>(sender: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <b>to</b>: <b>address</b>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_transfer">transfer</a>(
    sender: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    asset: <b>address</b>,
    <b>to</b>: <b>address</b>,
    amount: u128
) {
    <b>let</b> asset = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <b>let</b> from_wallet =
        <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store_primary_store">primary_fungible_store::primary_store</a>(<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(sender), asset);
    <b>let</b> to_wallet = <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<b>to</b>, asset);
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_transfer">fungible_asset::transfer</a>(sender, from_wallet, to_wallet, amount);
}
</code></pre>



</details>

<a id="0x4_coin_burn"></a>

## Function `burn`

Burn fungible assets as the owner of metadata object.


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_burn">burn</a>(sender: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_burn">burn</a>(sender: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, amount: u128) <b>acquires</b> <a href="coin.md#0x4_coin_MgmnFABurn">MgmnFABurn</a> {
    <b>let</b> asset = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <b>let</b> burn_ref = &<a href="coin.md#0x4_coin_borrow_burn_refs">borrow_burn_refs</a>(asset).burn_ref;
    <b>let</b> from_wallet =
        <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store_primary_store">primary_fungible_store::primary_store</a>(<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(sender), asset);
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_burn_from">fungible_asset::burn_from</a>(burn_ref, from_wallet, amount);
}
</code></pre>



</details>

<a id="0x4_coin_freeze_account"></a>

## Function `freeze_account`

Freeze an account so it cannot transfer or receive fungible assets.


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_freeze_account">freeze_account</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <a href="../../endless-framework/doc/account.md#0x1_account">account</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_freeze_account">freeze_account</a>(
    creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <a href="../../endless-framework/doc/account.md#0x1_account">account</a>: <b>address</b>
) <b>acquires</b> <a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a> {
    <b>let</b> asset = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <b>let</b> transfer_ref = &<a href="coin.md#0x4_coin_authorized_borrow_transfer_refs">authorized_borrow_transfer_refs</a>(creator, asset).transfer_ref;
    <b>let</b> wallet = <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<a href="../../endless-framework/doc/account.md#0x1_account">account</a>, asset);
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_set_frozen_flag">fungible_asset::set_frozen_flag</a>(transfer_ref, wallet, <b>true</b>);
}
</code></pre>



</details>

<a id="0x4_coin_unfreeze_account"></a>

## Function `unfreeze_account`

Unfreeze an account so it can transfer or receive fungible assets.


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_unfreeze_account">unfreeze_account</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <a href="../../endless-framework/doc/account.md#0x1_account">account</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_unfreeze_account">unfreeze_account</a>(
    creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, <a href="../../endless-framework/doc/account.md#0x1_account">account</a>: <b>address</b>
) <b>acquires</b> <a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a> {
    <b>let</b> asset = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <b>let</b> transfer_ref = &<a href="coin.md#0x4_coin_authorized_borrow_transfer_refs">authorized_borrow_transfer_refs</a>(creator, asset).transfer_ref;
    <b>let</b> wallet = <a href="../../endless-framework/doc/primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<a href="../../endless-framework/doc/account.md#0x1_account">account</a>, asset);
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_set_frozen_flag">fungible_asset::set_frozen_flag</a>(transfer_ref, wallet, <b>false</b>);
}
</code></pre>



</details>

<a id="0x4_coin_destroy_mint_cap"></a>

## Function `destroy_mint_cap`

Only called mint capability once all initial validators


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_destroy_mint_cap">destroy_mint_cap</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_destroy_mint_cap">destroy_mint_cap</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>) <b>acquires</b> <a href="coin.md#0x4_coin_MgmnFAMint">MgmnFAMint</a> {
    <b>let</b> asset = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <b>assert</b>!(
        <a href="../../endless-framework/doc/object.md#0x1_object_is_owner">object::is_owner</a>(asset, <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(creator)),
        <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="coin.md#0x4_coin_ENOT_OWNER">ENOT_OWNER</a>)
    );
    <b>let</b> <a href="coin.md#0x4_coin_MgmnFAMint">MgmnFAMint</a> { mint_ref } = <b>move_from</b>&lt;<a href="coin.md#0x4_coin_MgmnFAMint">MgmnFAMint</a>&gt;(<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(creator));
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_destroy_mint_cap">fungible_asset::destroy_mint_cap</a>(mint_ref);
}
</code></pre>



</details>

<a id="0x4_coin_destroy_burn_cap"></a>

## Function `destroy_burn_cap`

Only called burn capability once all initial validators


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_destroy_burn_cap">destroy_burn_cap</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_destroy_burn_cap">destroy_burn_cap</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>) <b>acquires</b> <a href="coin.md#0x4_coin_MgmnFABurn">MgmnFABurn</a> {
    <b>let</b> asset = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <b>assert</b>!(
        <a href="../../endless-framework/doc/object.md#0x1_object_is_owner">object::is_owner</a>(asset, <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(creator)),
        <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="coin.md#0x4_coin_ENOT_OWNER">ENOT_OWNER</a>)
    );
    <b>let</b> <a href="coin.md#0x4_coin_MgmnFABurn">MgmnFABurn</a> { burn_ref } = <b>move_from</b>&lt;<a href="coin.md#0x4_coin_MgmnFABurn">MgmnFABurn</a>&gt;(<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(creator));
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_destroy_burn_cap">fungible_asset::destroy_burn_cap</a>(burn_ref);
}
</code></pre>



</details>

<a id="0x4_coin_destroy_transfer_cap"></a>

## Function `destroy_transfer_cap`

Only called transfer capability once all initial validators


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_destroy_transfer_cap">destroy_transfer_cap</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_destroy_transfer_cap">destroy_transfer_cap</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>) <b>acquires</b> <a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a> {
    <b>let</b> asset = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <b>assert</b>!(
        <a href="../../endless-framework/doc/object.md#0x1_object_is_owner">object::is_owner</a>(asset, <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(creator)),
        <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="coin.md#0x4_coin_ENOT_OWNER">ENOT_OWNER</a>)
    );
    <b>let</b> <a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a> { transfer_ref } =
        <b>move_from</b>&lt;<a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a>&gt;(<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(creator));
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_destroy_transfer_cap">fungible_asset::destroy_transfer_cap</a>(transfer_ref);
}
</code></pre>



</details>

<a id="0x4_coin_set_icon_uri"></a>

## Function `set_icon_uri`



<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_set_icon_uri">set_icon_uri</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, icon_uri: <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_set_icon_uri">set_icon_uri</a>(
    creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, icon_uri: String
) {
    <b>let</b> asset = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_set_icon_uri">fungible_asset::set_icon_uri</a>(creator, asset, icon_uri);
}
</code></pre>



</details>

<a id="0x4_coin_set_project_uri"></a>

## Function `set_project_uri`



<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_set_project_uri">set_project_uri</a>(creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, project_uri: <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="coin.md#0x4_coin_set_project_uri">set_project_uri</a>(
    creator: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <b>address</b>, project_uri: String
) {
    <b>let</b> asset = <a href="coin.md#0x4_coin_get_metadata">get_metadata</a>(asset);
    <a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_set_project_uri">fungible_asset::set_project_uri</a>(creator, asset, project_uri);
}
</code></pre>



</details>

<a id="0x4_coin_authorized_borrow_mint_refs"></a>

## Function `authorized_borrow_mint_refs`

Borrow the immutable reference of the refs of <code>metadata</code>.
This validates that the signer is the metadata object's owner.


<pre><code><b>fun</b> <a href="coin.md#0x4_coin_authorized_borrow_mint_refs">authorized_borrow_mint_refs</a>(owner: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <a href="../../endless-framework/doc/object.md#0x1_object_Object">object::Object</a>&lt;<a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;): &<a href="coin.md#0x4_coin_MgmnFAMint">coin::MgmnFAMint</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="coin.md#0x4_coin_authorized_borrow_mint_refs">authorized_borrow_mint_refs</a>(
    owner: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: Object&lt;Metadata&gt;
): &<a href="coin.md#0x4_coin_MgmnFAMint">MgmnFAMint</a> <b>acquires</b> <a href="coin.md#0x4_coin_MgmnFAMint">MgmnFAMint</a> {
    <b>assert</b>!(
        <a href="../../endless-framework/doc/object.md#0x1_object_is_owner">object::is_owner</a>(asset, <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner)),
        <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="coin.md#0x4_coin_ENOT_OWNER">ENOT_OWNER</a>)
    );
    <b>borrow_global</b>&lt;<a href="coin.md#0x4_coin_MgmnFAMint">MgmnFAMint</a>&gt;(<a href="../../endless-framework/doc/object.md#0x1_object_object_address">object::object_address</a>(&asset))
}
</code></pre>



</details>

<a id="0x4_coin_borrow_burn_refs"></a>

## Function `borrow_burn_refs`

Borrow the immutable reference of the refs of <code>metadata</code>.


<pre><code><b>fun</b> <a href="coin.md#0x4_coin_borrow_burn_refs">borrow_burn_refs</a>(asset: <a href="../../endless-framework/doc/object.md#0x1_object_Object">object::Object</a>&lt;<a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;): &<a href="coin.md#0x4_coin_MgmnFABurn">coin::MgmnFABurn</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="coin.md#0x4_coin_borrow_burn_refs">borrow_burn_refs</a>(asset: Object&lt;Metadata&gt;): &<a href="coin.md#0x4_coin_MgmnFABurn">MgmnFABurn</a> <b>acquires</b> <a href="coin.md#0x4_coin_MgmnFABurn">MgmnFABurn</a> {
    <b>borrow_global</b>&lt;<a href="coin.md#0x4_coin_MgmnFABurn">MgmnFABurn</a>&gt;(<a href="../../endless-framework/doc/object.md#0x1_object_object_address">object::object_address</a>(&asset))
}
</code></pre>



</details>

<a id="0x4_coin_authorized_borrow_transfer_refs"></a>

## Function `authorized_borrow_transfer_refs`

Borrow the immutable reference of the refs of <code>metadata</code>.
This validates that the signer is the metadata object's owner.


<pre><code><b>fun</b> <a href="coin.md#0x4_coin_authorized_borrow_transfer_refs">authorized_borrow_transfer_refs</a>(owner: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: <a href="../../endless-framework/doc/object.md#0x1_object_Object">object::Object</a>&lt;<a href="../../endless-framework/doc/fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;): &<a href="coin.md#0x4_coin_MgmnFATransfer">coin::MgmnFATransfer</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="coin.md#0x4_coin_authorized_borrow_transfer_refs">authorized_borrow_transfer_refs</a>(
    owner: &<a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, asset: Object&lt;Metadata&gt;
): &<a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a> <b>acquires</b> <a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a> {
    <b>assert</b>!(
        <a href="../../endless-framework/doc/object.md#0x1_object_is_owner">object::is_owner</a>(asset, <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner)),
        <a href="../../endless-framework/../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="coin.md#0x4_coin_ENOT_OWNER">ENOT_OWNER</a>)
    );
    <b>borrow_global</b>&lt;<a href="coin.md#0x4_coin_MgmnFATransfer">MgmnFATransfer</a>&gt;(<a href="../../endless-framework/doc/object.md#0x1_object_object_address">object::object_address</a>(&asset))
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

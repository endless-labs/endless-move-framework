
<a id="0x1_endless_coin"></a>

# Module `0x1::endless_coin`

This module defines a minimal and generic Coin and Balance.
modified from https://github.com/move-language/move/tree/main/language/documentation/tutorial


-  [Resource `EndlessCoinCapabilities`](#0x1_endless_coin_EndlessCoinCapabilities)
-  [Struct `DelegatedMintCapability`](#0x1_endless_coin_DelegatedMintCapability)
-  [Resource `Delegations`](#0x1_endless_coin_Delegations)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_endless_coin_initialize)
-  [Function `is_true_EDS`](#0x1_endless_coin_is_true_EDS)
-  [Function `is_account_registered`](#0x1_endless_coin_is_account_registered)
-  [Function `balance`](#0x1_endless_coin_balance)
-  [Function `check_minimum_balance`](#0x1_endless_coin_check_minimum_balance)
-  [Function `get_metadata`](#0x1_endless_coin_get_metadata)
-  [Function `supply`](#0x1_endless_coin_supply)
-  [Function `has_mint_capability`](#0x1_endless_coin_has_mint_capability)
-  [Function `register`](#0x1_endless_coin_register)
-  [Function `withdraw`](#0x1_endless_coin_withdraw)
-  [Function `transfer`](#0x1_endless_coin_transfer)
-  [Function `zero`](#0x1_endless_coin_zero)
-  [Function `destroy_coin_cap`](#0x1_endless_coin_destroy_coin_cap)
-  [Function `configure_accounts_for_test`](#0x1_endless_coin_configure_accounts_for_test)
-  [Function `mint`](#0x1_endless_coin_mint)
-  [Function `burn`](#0x1_endless_coin_burn)
-  [Function `delegate_mint_capability`](#0x1_endless_coin_delegate_mint_capability)
-  [Function `claim_mint_capability`](#0x1_endless_coin_claim_mint_capability)
-  [Function `find_delegation`](#0x1_endless_coin_find_delegation)
-  [Function `get_eds_token_address`](#0x1_endless_coin_get_eds_token_address)


<pre><code><b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="fungible_asset.md#0x1_fungible_asset">0x1::fungible_asset</a>;
<b>use</b> <a href="object.md#0x1_object">0x1::object</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="primary_fungible_store.md#0x1_primary_fungible_store">0x1::primary_fungible_store</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">0x1::vector</a>;
</code></pre>



<a id="0x1_endless_coin_EndlessCoinCapabilities"></a>

## Resource `EndlessCoinCapabilities`



<pre><code><b>struct</b> <a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>mint_cap: <a href="fungible_asset.md#0x1_fungible_asset_MintRef">fungible_asset::MintRef</a></code>
</dt>
<dd>

</dd>
<dt>
<code>transfer_cap: <a href="fungible_asset.md#0x1_fungible_asset_TransferRef">fungible_asset::TransferRef</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_endless_coin_DelegatedMintCapability"></a>

## Struct `DelegatedMintCapability`

Delegation token created by delegator and can be claimed by the delegatee as MintCapability.


<pre><code><b>struct</b> <a href="endless_coin.md#0x1_endless_coin_DelegatedMintCapability">DelegatedMintCapability</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><b>to</b>: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_endless_coin_Delegations"></a>

## Resource `Delegations`

The container stores the current pending delegations.


<pre><code><b>struct</b> <a href="endless_coin.md#0x1_endless_coin_Delegations">Delegations</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>inner: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="endless_coin.md#0x1_endless_coin_DelegatedMintCapability">endless_coin::DelegatedMintCapability</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_endless_coin_MAX_U64"></a>

Maximum possible aggregatable coin value.


<pre><code><b>const</b> <a href="endless_coin.md#0x1_endless_coin_MAX_U64">MAX_U64</a>: u128 = 18446744073709551615;
</code></pre>



<a id="0x1_endless_coin_EAGGREGATABLE_COIN_VALUE_TOO_LARGE"></a>

The value of aggregatable coin used for transaction fees redistribution does not fit in u64.


<pre><code><b>const</b> <a href="endless_coin.md#0x1_endless_coin_EAGGREGATABLE_COIN_VALUE_TOO_LARGE">EAGGREGATABLE_COIN_VALUE_TOO_LARGE</a>: u64 = 14;
</code></pre>



<a id="0x1_endless_coin_EALREADY_DELEGATED"></a>

Mint capability has already been delegated to this specified address


<pre><code><b>const</b> <a href="endless_coin.md#0x1_endless_coin_EALREADY_DELEGATED">EALREADY_DELEGATED</a>: u64 = 2;
</code></pre>



<a id="0x1_endless_coin_EDELEGATION_NOT_FOUND"></a>

Cannot find delegation of mint capability to this account


<pre><code><b>const</b> <a href="endless_coin.md#0x1_endless_coin_EDELEGATION_NOT_FOUND">EDELEGATION_NOT_FOUND</a>: u64 = 3;
</code></pre>



<a id="0x1_endless_coin_EDS_DECIMALS"></a>



<pre><code><b>const</b> <a href="endless_coin.md#0x1_endless_coin_EDS_DECIMALS">EDS_DECIMALS</a>: u8 = 8;
</code></pre>



<a id="0x1_endless_coin_EDS_METADATA_ADDR"></a>



<pre><code><b>const</b> <a href="endless_coin.md#0x1_endless_coin_EDS_METADATA_ADDR">EDS_METADATA_ADDR</a>: <b>address</b> = 0xc69712057e634bebc9ab02745d2d69ee738e3eb4f5d30189a9acbf8e08fb823e;
</code></pre>



<a id="0x1_endless_coin_EDS_SYMBOL"></a>



<pre><code><b>const</b> <a href="endless_coin.md#0x1_endless_coin_EDS_SYMBOL">EDS_SYMBOL</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [69, 68, 83];
</code></pre>



<a id="0x1_endless_coin_EINVALID_BURN_REF"></a>

invalid BURN Ref.


<pre><code><b>const</b> <a href="endless_coin.md#0x1_endless_coin_EINVALID_BURN_REF">EINVALID_BURN_REF</a>: u64 = 15;
</code></pre>



<a id="0x1_endless_coin_ENO_CAPABILITIES"></a>

Account does not have mint capability


<pre><code><b>const</b> <a href="endless_coin.md#0x1_endless_coin_ENO_CAPABILITIES">ENO_CAPABILITIES</a>: u64 = 1;
</code></pre>



<a id="0x1_endless_coin_EZERO_COIN_AMOUNT"></a>

Coin amount cannot be zero


<pre><code><b>const</b> <a href="endless_coin.md#0x1_endless_coin_EZERO_COIN_AMOUNT">EZERO_COIN_AMOUNT</a>: u64 = 4;
</code></pre>



<a id="0x1_endless_coin_initialize"></a>

## Function `initialize`

Can only called during genesis to initialize the Endless Coin.
with fixed address: 0xc69712057e634bebc9ab02745d2d69ee738e3eb4f5d30189a9acbf8e08fb823e
which base58 format adress: ENDLESSsssssssssssssssssssssssssssssssssssss


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): (<a href="fungible_asset.md#0x1_fungible_asset_MintRef">fungible_asset::MintRef</a>, <a href="fungible_asset.md#0x1_fungible_asset_BurnRef">fungible_asset::BurnRef</a>, <a href="fungible_asset.md#0x1_fungible_asset_TransferRef">fungible_asset::TransferRef</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): (MintRef, BurnRef, TransferRef) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>let</b> constructor_ref = <a href="object.md#0x1_object_create_specific_object_internal">object::create_specific_object_internal</a>(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(endless_framework), <a href="endless_coin.md#0x1_endless_coin_EDS_METADATA_ADDR">EDS_METADATA_ADDR</a>);
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_create_primary_store_enabled_fungible_asset">primary_fungible_store::create_primary_store_enabled_fungible_asset</a>(
        &constructor_ref,
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>(),                            // max supply
        <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_utf8">string::utf8</a>(b"Endless Coin"),             // name
        <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_utf8">string::utf8</a>(<a href="endless_coin.md#0x1_endless_coin_EDS_SYMBOL">EDS_SYMBOL</a>),                  // symbol
        <a href="endless_coin.md#0x1_endless_coin_EDS_DECIMALS">EDS_DECIMALS</a>,                              // decimals
        <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_utf8">string::utf8</a>(b"https://www.endless.link/eds-icon.svg"),  // icon
        <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_utf8">string::utf8</a>(b"https://www.endless.link"),       // url
    );

    <b>let</b> mint_ref = generate_mint_ref(&constructor_ref);
    <b>let</b> burn_ref = generate_burn_ref(&constructor_ref);
    <b>let</b> transfer_ref = generate_transfer_ref(&constructor_ref);

    <b>let</b> mint_cap = generate_mint_ref(&constructor_ref);
    <b>let</b> transfer_cap= generate_transfer_ref(&constructor_ref);
    <b>move_to</b>(endless_framework, <a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a>{ mint_cap, transfer_cap});
    (mint_ref, burn_ref, transfer_ref)
}
</code></pre>



</details>

<a id="0x1_endless_coin_is_true_EDS"></a>

## Function `is_true_EDS`

check if FA meta addr == @0xc69712057e634bebc9ab02745d2d69ee738e3eb4f5d30189a9acbf8e08fb823e and symbol


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_is_true_EDS">is_true_EDS</a>(fa: &<a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_is_true_EDS">is_true_EDS</a>(fa: &FungibleAsset): bool {
    <b>let</b> meta_data = <a href="fungible_asset.md#0x1_fungible_asset_metadata_from_asset">fungible_asset::metadata_from_asset</a>(fa);
    <b>if</b> (<a href="fungible_asset.md#0x1_fungible_asset_symbol">fungible_asset::symbol</a>(meta_data) == <a href="../../endless-stdlib/../move-stdlib/doc/string.md#0x1_string_utf8">string::utf8</a>(<a href="endless_coin.md#0x1_endless_coin_EDS_SYMBOL">EDS_SYMBOL</a>)
        && <a href="object.md#0x1_object_object_address">object::object_address</a>(&meta_data) == <a href="endless_coin.md#0x1_endless_coin_EDS_METADATA_ADDR">EDS_METADATA_ADDR</a>) {
        <b>true</b>
    } <b>else</b> {
        <b>false</b>
    }
}
</code></pre>



</details>

<a id="0x1_endless_coin_is_account_registered"></a>

## Function `is_account_registered`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_is_account_registered">is_account_registered</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_is_account_registered">is_account_registered</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): bool {
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store_exists">primary_fungible_store::primary_store_exists</a>(<a href="account.md#0x1_account">account</a>, <a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>())
}
</code></pre>



</details>

<a id="0x1_endless_coin_balance"></a>

## Function `balance`

Return EDS balance of account.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_balance">balance</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_balance">balance</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): u128 {
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_balance">primary_fungible_store::balance</a>&lt;Metadata&gt;(<a href="account.md#0x1_account">account</a>, <a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>())
}
</code></pre>



</details>

<a id="0x1_endless_coin_check_minimum_balance"></a>

## Function `check_minimum_balance`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_check_minimum_balance">check_minimum_balance</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>, least: u128): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_check_minimum_balance">check_minimum_balance</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>, least: u128): bool {
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_check_minimum_balance">primary_fungible_store::check_minimum_balance</a>&lt;Metadata&gt;(<a href="account.md#0x1_account">account</a>, <a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>(), least)
}
</code></pre>



</details>

<a id="0x1_endless_coin_get_metadata"></a>

## Function `get_metadata`

Return the address of the metadata that's created when this module is deployed.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>(): <a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>(): Object&lt;Metadata&gt; {
    // <b>let</b> metadata_address = <a href="object.md#0x1_object_create_object_address">object::create_object_address</a>(&@0x1, <a href="endless_coin.md#0x1_endless_coin_EDS_SYMBOL">EDS_SYMBOL</a>);
    // <a href="object.md#0x1_object_address_to_object">object::address_to_object</a>&lt;Metadata&gt;(metadata_address)
    <a href="object.md#0x1_object_address_to_object">object::address_to_object</a>&lt;Metadata&gt;(<a href="endless_coin.md#0x1_endless_coin_EDS_METADATA_ADDR">EDS_METADATA_ADDR</a>)
}
</code></pre>



</details>

<a id="0x1_endless_coin_supply"></a>

## Function `supply`

Return Supply of EDS coin.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_supply">supply</a>(): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_supply">supply</a>(): u128 {
    <b>let</b> amount = <a href="fungible_asset.md#0x1_fungible_asset_supply">fungible_asset::supply</a>(<a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>());
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_get_with_default">option::get_with_default</a>(&amount, 0_u128)
}
</code></pre>



</details>

<a id="0x1_endless_coin_has_mint_capability"></a>

## Function `has_mint_capability`

Only Endless Creator has mint reference


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_has_mint_capability">has_mint_capability</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_has_mint_capability">has_mint_capability</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): bool {
    <b>exists</b>&lt;<a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>))
}
</code></pre>



</details>

<a id="0x1_endless_coin_register"></a>

## Function `register`



<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_register">register</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_register">register</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>) {
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<a href="account.md#0x1_account">account</a>, <a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>());
}
</code></pre>



</details>

<a id="0x1_endless_coin_withdraw"></a>

## Function `withdraw`



<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_withdraw">withdraw</a>(from: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, amount: u128): <a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_withdraw">withdraw</a>(from: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, amount: u128): FungibleAsset {
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_withdraw">primary_fungible_store::withdraw</a>(from, <a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>(), amount)
}
</code></pre>



</details>

<a id="0x1_endless_coin_transfer"></a>

## Function `transfer`



<pre><code><b>public</b> entry <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_transfer">transfer</a>(from: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <b>to</b>: <b>address</b>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_transfer">transfer</a>(from: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <b>to</b>:<b>address</b>, amount: u128) {
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_transfer">primary_fungible_store::transfer</a>(from, <a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>(), <b>to</b>, amount)
}
</code></pre>



</details>

<a id="0x1_endless_coin_zero"></a>

## Function `zero`



<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_zero">zero</a>(): <a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_zero">zero</a>(): FungibleAsset {
    <a href="fungible_asset.md#0x1_fungible_asset_zero">fungible_asset::zero</a>(<a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>())
}
</code></pre>



</details>

<a id="0x1_endless_coin_destroy_coin_cap"></a>

## Function `destroy_coin_cap`

Only called during genesis to destroy the endless framework account's mint capability once all initial validators
and accounts have been initialized during genesis.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_destroy_coin_cap">destroy_coin_cap</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_destroy_coin_cap">destroy_coin_cap</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a> {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>let</b> <a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a> { mint_cap, transfer_cap } = <b>move_from</b>&lt;<a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(@endless_framework);
    <a href="fungible_asset.md#0x1_fungible_asset_destroy_mint_cap">fungible_asset::destroy_mint_cap</a>(mint_cap);
    <a href="fungible_asset.md#0x1_fungible_asset_destroy_transfer_cap">fungible_asset::destroy_transfer_cap</a>(transfer_cap);
}
</code></pre>



</details>

<a id="0x1_endless_coin_configure_accounts_for_test"></a>

## Function `configure_accounts_for_test`

Can only be called during genesis for tests to grant mint capability to endless framework and core resources
accounts.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_configure_accounts_for_test">configure_accounts_for_test</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, core_resources: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, mint_cap: <a href="fungible_asset.md#0x1_fungible_asset_MintRef">fungible_asset::MintRef</a>, transfer_cap: <a href="fungible_asset.md#0x1_fungible_asset_TransferRef">fungible_asset::TransferRef</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_configure_accounts_for_test">configure_accounts_for_test</a>(
    endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    core_resources: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    mint_cap: MintRef,
    transfer_cap: TransferRef,
) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);

    <b>move_to</b>(core_resources, <a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a> { mint_cap, transfer_cap });
    <b>move_to</b>(core_resources, <a href="endless_coin.md#0x1_endless_coin_Delegations">Delegations</a> { inner: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>() });
}
</code></pre>



</details>

<a id="0x1_endless_coin_mint"></a>

## Function `mint`

Only callable in tests and testnets where the core resources account exists.
Create new coins and deposit them into dst_addr's account.


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_mint">mint</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, dst_addr: <b>address</b>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_mint">mint</a>(
    <a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    dst_addr: <b>address</b>,
    amount: u128,
) <b>acquires</b> <a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a> {
    <b>let</b> account_addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>);

    <b>assert</b>!(
        <b>exists</b>&lt;<a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(account_addr),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="endless_coin.md#0x1_endless_coin_ENO_CAPABILITIES">ENO_CAPABILITIES</a>),
    );

    <b>let</b> mint_cap = &<b>borrow_global</b>&lt;<a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(account_addr).mint_cap;
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_mint">primary_fungible_store::mint</a>(mint_cap, dst_addr, amount);
}
</code></pre>



</details>

<a id="0x1_endless_coin_burn"></a>

## Function `burn`

Burns amount of EDS from endless_framwork


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_burn">burn</a>(ref: &<a href="fungible_asset.md#0x1_fungible_asset_BurnRef">fungible_asset::BurnRef</a>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_burn">burn</a>(ref: &BurnRef, amount: u128) {
    <b>assert</b>!(amount &gt; 0, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="endless_coin.md#0x1_endless_coin_EZERO_COIN_AMOUNT">EZERO_COIN_AMOUNT</a>));
    <b>assert</b>!(<a href="fungible_asset.md#0x1_fungible_asset_burn_ref_metadata">fungible_asset::burn_ref_metadata</a>(ref) == <a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>(), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="endless_coin.md#0x1_endless_coin_EINVALID_BURN_REF">EINVALID_BURN_REF</a>));

    <b>let</b> store = <a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store">primary_fungible_store::primary_store</a>(@endless_framework, <a href="endless_coin.md#0x1_endless_coin_get_metadata">get_metadata</a>());
    <a href="fungible_asset.md#0x1_fungible_asset_burn_from">fungible_asset::burn_from</a>(ref, store, amount);
}
</code></pre>



</details>

<a id="0x1_endless_coin_delegate_mint_capability"></a>

## Function `delegate_mint_capability`

Only callable in tests and testnets where the core resources account exists.
Create delegated token for the address so the account could claim MintCapability later.


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_delegate_mint_capability">delegate_mint_capability</a>(<a href="account.md#0x1_account">account</a>: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <b>to</b>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_delegate_mint_capability">delegate_mint_capability</a>(<a href="account.md#0x1_account">account</a>: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <b>to</b>: <b>address</b>) <b>acquires</b> <a href="endless_coin.md#0x1_endless_coin_Delegations">Delegations</a> {
    <a href="system_addresses.md#0x1_system_addresses_assert_core_resource">system_addresses::assert_core_resource</a>(&<a href="account.md#0x1_account">account</a>);
    <b>let</b> delegations = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="endless_coin.md#0x1_endless_coin_Delegations">Delegations</a>&gt;(@core_resources).inner;
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(delegations, |element| {
        <b>let</b> element: &<a href="endless_coin.md#0x1_endless_coin_DelegatedMintCapability">DelegatedMintCapability</a> = element;
        <b>assert</b>!(element.<b>to</b> != <b>to</b>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="endless_coin.md#0x1_endless_coin_EALREADY_DELEGATED">EALREADY_DELEGATED</a>));
    });
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(delegations, <a href="endless_coin.md#0x1_endless_coin_DelegatedMintCapability">DelegatedMintCapability</a> { <b>to</b> });
}
</code></pre>



</details>

<a id="0x1_endless_coin_claim_mint_capability"></a>

## Function `claim_mint_capability`

Only callable in tests and testnets where the core resources account exists.
Claim the delegated mint capability and destroy the delegated token.


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_claim_mint_capability">claim_mint_capability</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_claim_mint_capability">claim_mint_capability</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="endless_coin.md#0x1_endless_coin_Delegations">Delegations</a>, <a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a> {
    <b>let</b> maybe_index = <a href="endless_coin.md#0x1_endless_coin_find_delegation">find_delegation</a>(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>));
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&maybe_index), <a href="endless_coin.md#0x1_endless_coin_EDELEGATION_NOT_FOUND">EDELEGATION_NOT_FOUND</a>);
    <b>let</b> idx = *<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&maybe_index);
    <b>let</b> delegations = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="endless_coin.md#0x1_endless_coin_Delegations">Delegations</a>&gt;(@core_resources).inner;
    <b>let</b> <a href="endless_coin.md#0x1_endless_coin_DelegatedMintCapability">DelegatedMintCapability</a> { <b>to</b>: _ } = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_swap_remove">vector::swap_remove</a>(delegations, idx);

    // Make a <b>copy</b> of mint cap and give it <b>to</b> the specified <a href="account.md#0x1_account">account</a>.
    <b>let</b> mint_cap = <b>borrow_global</b>&lt;<a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(@core_resources).mint_cap;
    <b>let</b> transfer_cap = <b>borrow_global</b>&lt;<a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(@core_resources).transfer_cap;
    <b>move_to</b>(<a href="account.md#0x1_account">account</a>, <a href="endless_coin.md#0x1_endless_coin_EndlessCoinCapabilities">EndlessCoinCapabilities</a> { mint_cap, transfer_cap });
}
</code></pre>



</details>

<a id="0x1_endless_coin_find_delegation"></a>

## Function `find_delegation`



<pre><code><b>fun</b> <a href="endless_coin.md#0x1_endless_coin_find_delegation">find_delegation</a>(addr: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="endless_coin.md#0x1_endless_coin_find_delegation">find_delegation</a>(addr: <b>address</b>): Option&lt;u64&gt; <b>acquires</b> <a href="endless_coin.md#0x1_endless_coin_Delegations">Delegations</a> {
    <b>let</b> delegations = &<b>borrow_global</b>&lt;<a href="endless_coin.md#0x1_endless_coin_Delegations">Delegations</a>&gt;(@core_resources).inner;
    <b>let</b> i = 0;
    <b>let</b> len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(delegations);
    <b>let</b> index = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>();
    <b>while</b> (i &lt; len) {
        <b>let</b> element = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(delegations, i);
        <b>if</b> (element.<b>to</b> == addr) {
            index = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(i);
            <b>break</b>
        };
        i = i + 1;
    };
    index
}
</code></pre>



</details>

<a id="0x1_endless_coin_get_eds_token_address"></a>

## Function `get_eds_token_address`



<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_get_eds_token_address">get_eds_token_address</a>(): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_coin.md#0x1_endless_coin_get_eds_token_address">get_eds_token_address</a>(): <b>address</b> {
    <a href="endless_coin.md#0x1_endless_coin_EDS_METADATA_ADDR">EDS_METADATA_ADDR</a>
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

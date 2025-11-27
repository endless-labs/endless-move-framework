
<a id="0x1_endless_account"></a>

# Module `0x1::endless_account`



-  [Resource `DirectTransferConfig`](#0x1_endless_account_DirectTransferConfig)
-  [Struct `DirectCoinTransferConfigUpdatedEvent`](#0x1_endless_account_DirectCoinTransferConfigUpdatedEvent)
-  [Struct `AllowDirectTransfers`](#0x1_endless_account_AllowDirectTransfers)
-  [Constants](#@Constants_0)
-  [Function `create_account`](#0x1_endless_account_create_account)
-  [Function `batch_transfer`](#0x1_endless_account_batch_transfer)
-  [Function `transfer`](#0x1_endless_account_transfer)
-  [Function `batch_transfer_coins`](#0x1_endless_account_batch_transfer_coins)
-  [Function `transfer_coins`](#0x1_endless_account_transfer_coins)
-  [Function `deposit_coins`](#0x1_endless_account_deposit_coins)
-  [Function `assert_account_exists`](#0x1_endless_account_assert_account_exists)
-  [Function `assert_account_is_registered_for_eds`](#0x1_endless_account_assert_account_is_registered_for_eds)
-  [Function `set_allow_direct_coin_transfers`](#0x1_endless_account_set_allow_direct_coin_transfers)
-  [Function `can_receive_direct_coin_transfers`](#0x1_endless_account_can_receive_direct_coin_transfers)


<pre><code><b>use</b> <a href="account.md#0x1_account">0x1::account</a>;
<b>use</b> <a href="endless_coin.md#0x1_endless_coin">0x1::endless_coin</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="event.md#0x1_event">0x1::event</a>;
<b>use</b> <a href="fungible_asset.md#0x1_fungible_asset">0x1::fungible_asset</a>;
<b>use</b> <a href="object.md#0x1_object">0x1::object</a>;
<b>use</b> <a href="primary_fungible_store.md#0x1_primary_fungible_store">0x1::primary_fungible_store</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
</code></pre>



<a id="0x1_endless_account_DirectTransferConfig"></a>

## Resource `DirectTransferConfig`

Configuration for whether an account can receive direct transfers of coins that they have not registered.

By default, this is enabled. Users can opt-out by disabling at any time.


<pre><code><b>struct</b> <a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>allow_arbitrary_coin_transfers: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_endless_account_DirectCoinTransferConfigUpdatedEvent"></a>

## Struct `DirectCoinTransferConfigUpdatedEvent`

Event emitted when an account's direct coins transfer config is updated.


<pre><code><b>struct</b> <a href="endless_account.md#0x1_endless_account_DirectCoinTransferConfigUpdatedEvent">DirectCoinTransferConfigUpdatedEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>new_allow_direct_transfers: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_endless_account_AllowDirectTransfers"></a>

## Struct `AllowDirectTransfers`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="endless_account.md#0x1_endless_account_AllowDirectTransfers">AllowDirectTransfers</a> <b>has</b> drop, store
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
<code>new_allow_direct_transfers: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_endless_account_EOBJECT_EXISTS"></a>

Object exists.


<pre><code><b>const</b> <a href="endless_account.md#0x1_endless_account_EOBJECT_EXISTS">EOBJECT_EXISTS</a>: u64 = 6;
</code></pre>



<a id="0x1_endless_account_EACCOUNT_DOES_NOT_ACCEPT_DIRECT_COIN_TRANSFERS"></a>

Account opted out of receiving coins that they did not register to receive.


<pre><code><b>const</b> <a href="endless_account.md#0x1_endless_account_EACCOUNT_DOES_NOT_ACCEPT_DIRECT_COIN_TRANSFERS">EACCOUNT_DOES_NOT_ACCEPT_DIRECT_COIN_TRANSFERS</a>: u64 = 3;
</code></pre>



<a id="0x1_endless_account_EACCOUNT_DOES_NOT_ACCEPT_DIRECT_TOKEN_TRANSFERS"></a>

Account opted out of directly receiving NFT tokens.


<pre><code><b>const</b> <a href="endless_account.md#0x1_endless_account_EACCOUNT_DOES_NOT_ACCEPT_DIRECT_TOKEN_TRANSFERS">EACCOUNT_DOES_NOT_ACCEPT_DIRECT_TOKEN_TRANSFERS</a>: u64 = 4;
</code></pre>



<a id="0x1_endless_account_EACCOUNT_NOT_FOUND"></a>

Account does not exist.


<pre><code><b>const</b> <a href="endless_account.md#0x1_endless_account_EACCOUNT_NOT_FOUND">EACCOUNT_NOT_FOUND</a>: u64 = 1;
</code></pre>



<a id="0x1_endless_account_EACCOUNT_NOT_REGISTERED_FOR_EDS"></a>

Account is not registered to receive EDS.


<pre><code><b>const</b> <a href="endless_account.md#0x1_endless_account_EACCOUNT_NOT_REGISTERED_FOR_EDS">EACCOUNT_NOT_REGISTERED_FOR_EDS</a>: u64 = 2;
</code></pre>



<a id="0x1_endless_account_EMISMATCHING_RECIPIENTS_AND_AMOUNTS_LENGTH"></a>

The lengths of the recipients and amounts lists don't match.


<pre><code><b>const</b> <a href="endless_account.md#0x1_endless_account_EMISMATCHING_RECIPIENTS_AND_AMOUNTS_LENGTH">EMISMATCHING_RECIPIENTS_AND_AMOUNTS_LENGTH</a>: u64 = 5;
</code></pre>



<a id="0x1_endless_account_create_account"></a>

## Function `create_account`

Basic account creation methods.


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_create_account">create_account</a>(auth_key: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_create_account">create_account</a>(auth_key: <b>address</b>) {
    <b>assert</b>!(!<a href="object.md#0x1_object_is_object">object::is_object</a>(auth_key), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="endless_account.md#0x1_endless_account_EOBJECT_EXISTS">EOBJECT_EXISTS</a>));
    <b>let</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a> = <a href="account.md#0x1_account_create_account">account::create_account</a>(auth_key);
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>), <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>());
}
</code></pre>



</details>

<a id="0x1_endless_account_batch_transfer"></a>

## Function `batch_transfer`

Batch version of EDS transfer.


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_batch_transfer">batch_transfer</a>(source: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, recipients: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u128&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_batch_transfer">batch_transfer</a>(source: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, recipients: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u128&gt;) {
    <b>let</b> recipients_len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&recipients);
    <b>assert</b>!(
        recipients_len == <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&amounts),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="endless_account.md#0x1_endless_account_EMISMATCHING_RECIPIENTS_AND_AMOUNTS_LENGTH">EMISMATCHING_RECIPIENTS_AND_AMOUNTS_LENGTH</a>),
    );

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_enumerate_ref">vector::enumerate_ref</a>(&recipients, |i, <b>to</b>| {
        <b>let</b> amount = *<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&amounts, i);
        <a href="endless_account.md#0x1_endless_account_transfer">transfer</a>(source, *<b>to</b>, amount);
    });
}
</code></pre>



</details>

<a id="0x1_endless_account_transfer"></a>

## Function `transfer`

Convenient function to transfer EDS to a recipient account that might not exist.
This would create the recipient account first, which also registers it to receive EDS, before transferring.


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_transfer">transfer</a>(source: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <b>to</b>: <b>address</b>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_transfer">transfer</a>(source: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <b>to</b>: <b>address</b>, amount: u128) {
    <b>if</b> (!<a href="account.md#0x1_account_exists_at">account::exists_at</a>(<b>to</b>)) {
        <a href="endless_account.md#0x1_endless_account_create_account">create_account</a>(<b>to</b>)
    };
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_transfer">primary_fungible_store::transfer</a>(source, <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>(), <b>to</b>, amount);
}
</code></pre>



</details>

<a id="0x1_endless_account_batch_transfer_coins"></a>

## Function `batch_transfer_coins`

Batch version of transfer_coins.


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_batch_transfer_coins">batch_transfer_coins</a>&lt;T: key&gt;(from: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, recipients: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u128&gt;, metadata: <a href="object.md#0x1_object_Object">object::Object</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_batch_transfer_coins">batch_transfer_coins</a>&lt;T: key&gt;(
    from: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, recipients: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, amounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u128&gt;, metadata: Object&lt;T&gt;) <b>acquires</b> <a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a> {
    <b>let</b> recipients_len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&recipients);
    <b>assert</b>!(
        recipients_len == <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&amounts),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="endless_account.md#0x1_endless_account_EMISMATCHING_RECIPIENTS_AND_AMOUNTS_LENGTH">EMISMATCHING_RECIPIENTS_AND_AMOUNTS_LENGTH</a>),
    );

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_enumerate_ref">vector::enumerate_ref</a>(&recipients, |i, <b>to</b>| {
        <b>let</b> amount = *<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&amounts, i);
        <a href="endless_account.md#0x1_endless_account_transfer_coins">transfer_coins</a>(from, *<b>to</b>, amount, metadata);
    });
}
</code></pre>



</details>

<a id="0x1_endless_account_transfer_coins"></a>

## Function `transfer_coins`

Convenient function to transfer a custom CoinType to a recipient account that might not exist.
This would create the recipient account first and register it to receive the CoinType, before transferring.


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_transfer_coins">transfer_coins</a>&lt;T: key&gt;(from: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <b>to</b>: <b>address</b>, amount: u128, metadata: <a href="object.md#0x1_object_Object">object::Object</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_transfer_coins">transfer_coins</a>&lt;T: key&gt;(from: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <b>to</b>: <b>address</b>, amount: u128, metadata: Object&lt;T&gt;) <b>acquires</b> <a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a> {
    <b>let</b> fa = <a href="primary_fungible_store.md#0x1_primary_fungible_store_withdraw">primary_fungible_store::withdraw</a>(from, metadata, amount);
    <b>spec</b> {
        <b>assume</b> fa.metadata.inner == metadata.inner;
    };
    <a href="endless_account.md#0x1_endless_account_deposit_coins">deposit_coins</a>(<b>to</b>, fa);
}
</code></pre>



</details>

<a id="0x1_endless_account_deposit_coins"></a>

## Function `deposit_coins`

Convenient function to deposit a custom CoinType into a recipient account that might not exist.
This would create the recipient account first and register it to receive the CoinType, before transferring.


<pre><code><b>public</b> <b>fun</b> <a href="endless_account.md#0x1_endless_account_deposit_coins">deposit_coins</a>(<b>to</b>: <b>address</b>, coins: <a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_account.md#0x1_endless_account_deposit_coins">deposit_coins</a>(<b>to</b>: <b>address</b>, coins: FungibleAsset) <b>acquires</b> <a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a> {
    <b>if</b> (!<a href="account.md#0x1_account_exists_at">account::exists_at</a>(<b>to</b>)) {
        <a href="endless_account.md#0x1_endless_account_create_account">create_account</a>(<b>to</b>);
    };
    <b>let</b> fa_metadata = <a href="fungible_asset.md#0x1_fungible_asset_asset_metadata">fungible_asset::asset_metadata</a>(&coins);
    <b>if</b> (!<a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store_exists">primary_fungible_store::primary_store_exists</a>&lt;Metadata&gt;(<b>to</b>, fa_metadata)) {
        <b>assert</b>!(
            <a href="endless_account.md#0x1_endless_account_can_receive_direct_coin_transfers">can_receive_direct_coin_transfers</a>(<b>to</b>),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="endless_account.md#0x1_endless_account_EACCOUNT_DOES_NOT_ACCEPT_DIRECT_COIN_TRANSFERS">EACCOUNT_DOES_NOT_ACCEPT_DIRECT_COIN_TRANSFERS</a>),
        );
        <a href="primary_fungible_store.md#0x1_primary_fungible_store_create_primary_store">primary_fungible_store::create_primary_store</a>(<b>to</b>, fa_metadata);
    };
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_deposit">primary_fungible_store::deposit</a>(<b>to</b>, coins)
}
</code></pre>



</details>

<a id="0x1_endless_account_assert_account_exists"></a>

## Function `assert_account_exists`



<pre><code><b>public</b> <b>fun</b> <a href="endless_account.md#0x1_endless_account_assert_account_exists">assert_account_exists</a>(addr: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_account.md#0x1_endless_account_assert_account_exists">assert_account_exists</a>(addr: <b>address</b>) {
    <b>assert</b>!(<a href="account.md#0x1_account_exists_at">account::exists_at</a>(addr), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="endless_account.md#0x1_endless_account_EACCOUNT_NOT_FOUND">EACCOUNT_NOT_FOUND</a>));
}
</code></pre>



</details>

<a id="0x1_endless_account_assert_account_is_registered_for_eds"></a>

## Function `assert_account_is_registered_for_eds`



<pre><code><b>public</b> <b>fun</b> <a href="endless_account.md#0x1_endless_account_assert_account_is_registered_for_eds">assert_account_is_registered_for_eds</a>(addr: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_account.md#0x1_endless_account_assert_account_is_registered_for_eds">assert_account_is_registered_for_eds</a>(addr: <b>address</b>) {
    <a href="endless_account.md#0x1_endless_account_assert_account_exists">assert_account_exists</a>(addr);
    <b>assert</b>!(<a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store_exists">primary_fungible_store::primary_store_exists</a>(addr, <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>()), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="endless_account.md#0x1_endless_account_EACCOUNT_NOT_REGISTERED_FOR_EDS">EACCOUNT_NOT_REGISTERED_FOR_EDS</a>));
}
</code></pre>



</details>

<a id="0x1_endless_account_set_allow_direct_coin_transfers"></a>

## Function `set_allow_direct_coin_transfers`

Set whether <code><a href="account.md#0x1_account">account</a></code> can receive direct transfers of coins that they have not explicitly registered to receive.


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_set_allow_direct_coin_transfers">set_allow_direct_coin_transfers</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, allow: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="endless_account.md#0x1_endless_account_set_allow_direct_coin_transfers">set_allow_direct_coin_transfers</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, allow: bool) <b>acquires</b> <a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a> {
    <b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>);
    <b>if</b> (<b>exists</b>&lt;<a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a>&gt;(addr)) {
        <b>let</b> direct_transfer_config = <b>borrow_global_mut</b>&lt;<a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a>&gt;(addr);
        // Short-circuit <b>to</b> avoid emitting an <a href="event.md#0x1_event">event</a> <b>if</b> direct transfer config is not changing.
        <b>if</b> (direct_transfer_config.allow_arbitrary_coin_transfers == allow) {
            <b>return</b>
        };

        direct_transfer_config.allow_arbitrary_coin_transfers = allow;
        emit(<a href="endless_account.md#0x1_endless_account_AllowDirectTransfers">AllowDirectTransfers</a> { <a href="account.md#0x1_account">account</a>: addr, new_allow_direct_transfers: allow });
    } <b>else</b> {
        <b>let</b> direct_transfer_config = <a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a> {
            allow_arbitrary_coin_transfers: allow,
        };
        emit(<a href="endless_account.md#0x1_endless_account_AllowDirectTransfers">AllowDirectTransfers</a> { <a href="account.md#0x1_account">account</a>: addr, new_allow_direct_transfers: allow });
        <b>move_to</b>(<a href="account.md#0x1_account">account</a>, direct_transfer_config);
    };
}
</code></pre>



</details>

<a id="0x1_endless_account_can_receive_direct_coin_transfers"></a>

## Function `can_receive_direct_coin_transfers`

Return true if <code><a href="account.md#0x1_account">account</a></code> can receive direct transfers of coins that they have not explicitly registered to
receive.

By default, this returns true if an account has not explicitly set whether the can receive direct transfers.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="endless_account.md#0x1_endless_account_can_receive_direct_coin_transfers">can_receive_direct_coin_transfers</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="endless_account.md#0x1_endless_account_can_receive_direct_coin_transfers">can_receive_direct_coin_transfers</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): bool <b>acquires</b> <a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a> {
    !<b>exists</b>&lt;<a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a>&gt;(<a href="account.md#0x1_account">account</a>) ||
        <b>borrow_global</b>&lt;<a href="endless_account.md#0x1_endless_account_DirectTransferConfig">DirectTransferConfig</a>&gt;(<a href="account.md#0x1_account">account</a>).allow_arbitrary_coin_transfers
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

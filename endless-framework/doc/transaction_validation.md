
<a id="0x1_transaction_validation"></a>

# Module `0x1::transaction_validation`



-  [Resource `TransactionValidation`](#0x1_transaction_validation_TransactionValidation)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_transaction_validation_initialize)
-  [Function `prologue_common`](#0x1_transaction_validation_prologue_common)
-  [Function `script_prologue`](#0x1_transaction_validation_script_prologue)
-  [Function `multi_agent_script_prologue`](#0x1_transaction_validation_multi_agent_script_prologue)
-  [Function `multi_agent_common_prologue`](#0x1_transaction_validation_multi_agent_common_prologue)
-  [Function `sponsored_script_prologue`](#0x1_transaction_validation_sponsored_script_prologue)
-  [Function `fee_payer_script_prologue`](#0x1_transaction_validation_fee_payer_script_prologue)
-  [Function `simulate_prologue`](#0x1_transaction_validation_simulate_prologue)
-  [Function `epilogue`](#0x1_transaction_validation_epilogue)
-  [Function `epilogue_gas_payer`](#0x1_transaction_validation_epilogue_gas_payer)


<pre><code><b>use</b> <a href="account.md#0x1_account">0x1::account</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs">0x1::bcs</a>;
<b>use</b> <a href="chain_id.md#0x1_chain_id">0x1::chain_id</a>;
<b>use</b> <a href="endless_coin.md#0x1_endless_coin">0x1::endless_coin</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features">0x1::features</a>;
<b>use</b> <a href="fungible_asset.md#0x1_fungible_asset">0x1::fungible_asset</a>;
<b>use</b> <a href="object.md#0x1_object">0x1::object</a>;
<b>use</b> <a href="primary_fungible_store.md#0x1_primary_fungible_store">0x1::primary_fungible_store</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
<b>use</b> <a href="timestamp.md#0x1_timestamp">0x1::timestamp</a>;
<b>use</b> <a href="transaction_fee.md#0x1_transaction_fee">0x1::transaction_fee</a>;
</code></pre>



<a id="0x1_transaction_validation_TransactionValidation"></a>

## Resource `TransactionValidation`

This holds information that will be picked up by the VM to call the
correct chain-specific prologue and epilogue functions


<pre><code><b>struct</b> <a href="transaction_validation.md#0x1_transaction_validation_TransactionValidation">TransactionValidation</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>module_addr: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>module_name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>script_prologue_name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>multi_agent_prologue_name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>user_epilogue_name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_transaction_validation_MAX_U64"></a>

MSB is used to indicate a gas payer tx


<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_MAX_U64">MAX_U64</a>: u128 = 18446744073709551615;
</code></pre>



<a id="0x1_transaction_validation_EOUT_OF_GAS"></a>

Transaction exceeded its allocated max gas


<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_EOUT_OF_GAS">EOUT_OF_GAS</a>: u64 = 6;
</code></pre>



<a id="0x1_transaction_validation_PROLOGUE_EACCOUNT_DOES_NOT_EXIST"></a>



<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EACCOUNT_DOES_NOT_EXIST">PROLOGUE_EACCOUNT_DOES_NOT_EXIST</a>: u64 = 1004;
</code></pre>



<a id="0x1_transaction_validation_PROLOGUE_EBAD_CHAIN_ID"></a>



<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EBAD_CHAIN_ID">PROLOGUE_EBAD_CHAIN_ID</a>: u64 = 1007;
</code></pre>



<a id="0x1_transaction_validation_PROLOGUE_ECANT_PAY_GAS_DEPOSIT"></a>



<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ECANT_PAY_GAS_DEPOSIT">PROLOGUE_ECANT_PAY_GAS_DEPOSIT</a>: u64 = 1005;
</code></pre>



<a id="0x1_transaction_validation_PROLOGUE_EFEE_PAYER_NOT_ENABLED"></a>



<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EFEE_PAYER_NOT_ENABLED">PROLOGUE_EFEE_PAYER_NOT_ENABLED</a>: u64 = 1010;
</code></pre>



<a id="0x1_transaction_validation_PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY"></a>

Prologue errors. These are separated out from the other errors in this
module since they are mapped separately to major VM statuses, and are
important to the semantics of the system.


<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY">PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY</a>: u64 = 1001;
</code></pre>



<a id="0x1_transaction_validation_PROLOGUE_ESECONDARY_KEYS_ADDRESSES_COUNT_MISMATCH"></a>



<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESECONDARY_KEYS_ADDRESSES_COUNT_MISMATCH">PROLOGUE_ESECONDARY_KEYS_ADDRESSES_COUNT_MISMATCH</a>: u64 = 1009;
</code></pre>



<a id="0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_BIG"></a>



<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_BIG">PROLOGUE_ESEQUENCE_NUMBER_TOO_BIG</a>: u64 = 1008;
</code></pre>



<a id="0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW"></a>



<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW">PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW</a>: u64 = 1003;
</code></pre>



<a id="0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_OLD"></a>



<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_OLD">PROLOGUE_ESEQUENCE_NUMBER_TOO_OLD</a>: u64 = 1002;
</code></pre>



<a id="0x1_transaction_validation_PROLOGUE_ETRANSACTION_EXPIRED"></a>



<pre><code><b>const</b> <a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ETRANSACTION_EXPIRED">PROLOGUE_ETRANSACTION_EXPIRED</a>: u64 = 1006;
</code></pre>



<a id="0x1_transaction_validation_initialize"></a>

## Function `initialize`

Only called during genesis to initialize system resources for this module.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, script_prologue_name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, multi_agent_prologue_name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, user_epilogue_name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_initialize">initialize</a>(
    endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    script_prologue_name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    multi_agent_prologue_name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    user_epilogue_name: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);

    <b>move_to</b>(endless_framework, <a href="transaction_validation.md#0x1_transaction_validation_TransactionValidation">TransactionValidation</a> {
        module_addr: @endless_framework,
        module_name: b"<a href="transaction_validation.md#0x1_transaction_validation">transaction_validation</a>",
        script_prologue_name,
        multi_agent_prologue_name,
        user_epilogue_name,
    });
}
</code></pre>



</details>

<a id="0x1_transaction_validation_prologue_common"></a>

## Function `prologue_common`



<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_prologue_common">prologue_common</a>(sender: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, gas_payer: <b>address</b>, txn_sequence_number: u64, txn_authentication_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, txn_gas_price: u64, txn_max_gas_units: u64, txn_expiration_time: u64, <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_prologue_common">prologue_common</a>(
    sender: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    gas_payer: <b>address</b>,
    txn_sequence_number: u64,
    txn_authentication_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;,
    txn_gas_price: u64,
    txn_max_gas_units: u64,
    txn_expiration_time: u64,
    <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8,
) {
    <b>assert</b>!(
        <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>() &lt; txn_expiration_time,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ETRANSACTION_EXPIRED">PROLOGUE_ETRANSACTION_EXPIRED</a>),
    );
    <b>assert</b>!(<a href="chain_id.md#0x1_chain_id_get">chain_id::get</a>() == <a href="chain_id.md#0x1_chain_id">chain_id</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EBAD_CHAIN_ID">PROLOGUE_EBAD_CHAIN_ID</a>));

    <b>let</b> transaction_sender = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(&sender);

    // Ensure the transaction sender is a valid <a href="account.md#0x1_account">account</a>
    <b>assert</b>!(!<a href="object.md#0x1_object_is_object">object::is_object</a>(transaction_sender), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EACCOUNT_DOES_NOT_EXIST">PROLOGUE_EACCOUNT_DOES_NOT_EXIST</a>));

    <b>if</b> (
        transaction_sender == gas_payer
        || <a href="account.md#0x1_account_exists_at">account::exists_at</a>(transaction_sender)
        || !<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_sponsored_automatic_account_creation_enabled">features::sponsored_automatic_account_creation_enabled</a>()
        || txn_sequence_number &gt; 0
    ) {
        <b>assert</b>!(<a href="account.md#0x1_account_exists_at">account::exists_at</a>(transaction_sender), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EACCOUNT_DOES_NOT_EXIST">PROLOGUE_EACCOUNT_DOES_NOT_EXIST</a>));
        <b>assert</b>!(
            <a href="account.md#0x1_account_check_authentication_key">account::check_authentication_key</a>(transaction_sender, txn_authentication_key),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY">PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY</a>),
        );

        <b>let</b> account_sequence_number = <a href="account.md#0x1_account_get_sequence_number">account::get_sequence_number</a>(transaction_sender);
        <b>assert</b>!(
            txn_sequence_number &lt; (1u64 &lt;&lt; 63),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_out_of_range">error::out_of_range</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_BIG">PROLOGUE_ESEQUENCE_NUMBER_TOO_BIG</a>)
        );

        <b>assert</b>!(
            txn_sequence_number &gt;= account_sequence_number,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_OLD">PROLOGUE_ESEQUENCE_NUMBER_TOO_OLD</a>)
        );

        <b>assert</b>!(
            txn_sequence_number == account_sequence_number,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW">PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW</a>)
        );
    } <b>else</b> {
        // In this case, the transaction is sponsored and the <a href="account.md#0x1_account">account</a> does not exist, so ensure
        // the default values match.
        <b>assert</b>!(
            txn_sequence_number == 0,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW">PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW</a>)
        );

        <b>assert</b>!(
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&txn_authentication_key) == 1,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY">PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY</a>),
        );

        <b>assert</b>!(
            *<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&txn_authentication_key, 0) == <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(&transaction_sender),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY">PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY</a>),
        );
    };

    <b>let</b> max_transaction_fee = txn_gas_price * txn_max_gas_units;
    <b>assert</b>!(
        <a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store_exists">primary_fungible_store::primary_store_exists</a>(gas_payer, <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>()),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ECANT_PAY_GAS_DEPOSIT">PROLOGUE_ECANT_PAY_GAS_DEPOSIT</a>),
    );
    <b>assert</b>!(
        <a href="endless_coin.md#0x1_endless_coin_check_minimum_balance">endless_coin::check_minimum_balance</a>(gas_payer, (max_transaction_fee <b>as</b> u128)),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ECANT_PAY_GAS_DEPOSIT">PROLOGUE_ECANT_PAY_GAS_DEPOSIT</a>),
    );
}
</code></pre>



</details>

<a id="0x1_transaction_validation_script_prologue"></a>

## Function `script_prologue`



<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_script_prologue">script_prologue</a>(sender: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, txn_sequence_number: u64, txn_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, txn_gas_price: u64, txn_max_gas_units: u64, txn_expiration_time: u64, <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8, _script_hash: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_script_prologue">script_prologue</a>(
    sender: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    txn_sequence_number: u64,
    txn_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;,
    txn_gas_price: u64,
    txn_max_gas_units: u64,
    txn_expiration_time: u64,
    <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8,
    _script_hash: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) {
    <b>let</b> gas_payer = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(&sender);
    <a href="transaction_validation.md#0x1_transaction_validation_prologue_common">prologue_common</a>(sender, gas_payer, txn_sequence_number, txn_public_key, txn_gas_price, txn_max_gas_units, txn_expiration_time, <a href="chain_id.md#0x1_chain_id">chain_id</a>)
}
</code></pre>



</details>

<a id="0x1_transaction_validation_multi_agent_script_prologue"></a>

## Function `multi_agent_script_prologue`



<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_multi_agent_script_prologue">multi_agent_script_prologue</a>(sender: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, txn_sequence_number: u64, txn_sender_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, secondary_signer_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, secondary_signer_public_key_hashes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;&gt;, txn_gas_price: u64, txn_max_gas_units: u64, txn_expiration_time: u64, <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_multi_agent_script_prologue">multi_agent_script_prologue</a>(
    sender: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    txn_sequence_number: u64,
    txn_sender_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;,
    secondary_signer_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
    secondary_signer_public_key_hashes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;&gt;,
    txn_gas_price: u64,
    txn_max_gas_units: u64,
    txn_expiration_time: u64,
    <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8,
) {
    <b>let</b> sender_addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(&sender);
    <a href="transaction_validation.md#0x1_transaction_validation_prologue_common">prologue_common</a>(
        sender,
        sender_addr,
        txn_sequence_number,
        txn_sender_public_key,
        txn_gas_price,
        txn_max_gas_units,
        txn_expiration_time,
        <a href="chain_id.md#0x1_chain_id">chain_id</a>,
    );
    <a href="transaction_validation.md#0x1_transaction_validation_multi_agent_common_prologue">multi_agent_common_prologue</a>(secondary_signer_addresses, secondary_signer_public_key_hashes);
}
</code></pre>



</details>

<a id="0x1_transaction_validation_multi_agent_common_prologue"></a>

## Function `multi_agent_common_prologue`



<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_multi_agent_common_prologue">multi_agent_common_prologue</a>(secondary_signer_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, secondary_signer_public_key_hashes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_multi_agent_common_prologue">multi_agent_common_prologue</a>(
    secondary_signer_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
    secondary_signer_public_key_hashes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;&gt;,
) {
    <b>let</b> num_secondary_signers = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&secondary_signer_addresses);
    <b>assert</b>!(
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&secondary_signer_public_key_hashes) == num_secondary_signers,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESECONDARY_KEYS_ADDRESSES_COUNT_MISMATCH">PROLOGUE_ESECONDARY_KEYS_ADDRESSES_COUNT_MISMATCH</a>),
    );

    <b>let</b> i = 0;
    <b>while</b> ({
        <b>spec</b> {
            <b>invariant</b> i &lt;= num_secondary_signers;
            <b>invariant</b> <b>forall</b> j in 0..i:
                <a href="account.md#0x1_account_exists_at">account::exists_at</a>(secondary_signer_addresses[j])
                && <a href="account.md#0x1_account_spec_check_authentication_key">account::spec_check_authentication_key</a>(
                    secondary_signer_addresses[j],
                    secondary_signer_public_key_hashes[j]);
        };
        (i &lt; num_secondary_signers)
    }) {
        <b>let</b> secondary_address = *<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&secondary_signer_addresses, i);
        <b>assert</b>!(<a href="account.md#0x1_account_exists_at">account::exists_at</a>(secondary_address), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EACCOUNT_DOES_NOT_EXIST">PROLOGUE_EACCOUNT_DOES_NOT_EXIST</a>));

        <b>let</b> signer_public_key_hash = *<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&secondary_signer_public_key_hashes, i);
        <b>assert</b>!(
            <a href="account.md#0x1_account_check_authentication_key">account::check_authentication_key</a>(secondary_address, signer_public_key_hash),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY">PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY</a>),
        );
        i = i + 1;
    }
}
</code></pre>



</details>

<a id="0x1_transaction_validation_sponsored_script_prologue"></a>

## Function `sponsored_script_prologue`



<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_sponsored_script_prologue">sponsored_script_prologue</a>(sender: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, fee_payer: <b>address</b>, txn_sequence_number: u64, txn_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, secondary_signer_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, secondary_signer_public_key_hashes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;&gt;, txn_gas_price: u64, txn_max_gas_units: u64, txn_expiration_time: u64, <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_sponsored_script_prologue">sponsored_script_prologue</a>(
    sender: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    fee_payer: <b>address</b>,
    txn_sequence_number: u64,
    txn_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;,
    secondary_signer_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
    secondary_signer_public_key_hashes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;&gt;,
    txn_gas_price: u64,
    txn_max_gas_units: u64,
    txn_expiration_time: u64,
    <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8,
) {
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_fee_payer_enabled">features::fee_payer_enabled</a>(), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EFEE_PAYER_NOT_ENABLED">PROLOGUE_EFEE_PAYER_NOT_ENABLED</a>));
    <a href="transaction_validation.md#0x1_transaction_validation_prologue_common">prologue_common</a>(
        sender,
        fee_payer,
        txn_sequence_number,
        txn_public_key,
        txn_gas_price,
        txn_max_gas_units,
        txn_expiration_time,
        <a href="chain_id.md#0x1_chain_id">chain_id</a>,
    );
    <a href="transaction_validation.md#0x1_transaction_validation_multi_agent_common_prologue">multi_agent_common_prologue</a>(secondary_signer_addresses, secondary_signer_public_key_hashes);
}
</code></pre>



</details>

<a id="0x1_transaction_validation_fee_payer_script_prologue"></a>

## Function `fee_payer_script_prologue`



<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_fee_payer_script_prologue">fee_payer_script_prologue</a>(sender: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, txn_sequence_number: u64, txn_sender_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, secondary_signer_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, secondary_signer_public_key_hashes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;&gt;, fee_payer_address: <b>address</b>, fee_payer_public_key_hash: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, txn_gas_price: u64, txn_max_gas_units: u64, txn_expiration_time: u64, <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_fee_payer_script_prologue">fee_payer_script_prologue</a>(
    sender: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    txn_sequence_number: u64,
    txn_sender_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;,
    secondary_signer_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
    secondary_signer_public_key_hashes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;&gt;,
    fee_payer_address: <b>address</b>,
    fee_payer_public_key_hash: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;,
    txn_gas_price: u64,
    txn_max_gas_units: u64,
    txn_expiration_time: u64,
    <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8,
) {
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_fee_payer_enabled">features::fee_payer_enabled</a>(), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EFEE_PAYER_NOT_ENABLED">PROLOGUE_EFEE_PAYER_NOT_ENABLED</a>));
    <a href="transaction_validation.md#0x1_transaction_validation_prologue_common">prologue_common</a>(
        sender,
        fee_payer_address,
        txn_sequence_number,
        txn_sender_public_key,
        txn_gas_price,
        txn_max_gas_units,
        txn_expiration_time,
        <a href="chain_id.md#0x1_chain_id">chain_id</a>,
    );
    <a href="transaction_validation.md#0x1_transaction_validation_multi_agent_common_prologue">multi_agent_common_prologue</a>(secondary_signer_addresses, secondary_signer_public_key_hashes);
    <b>assert</b>!(
        <a href="account.md#0x1_account_check_authentication_key">account::check_authentication_key</a>(fee_payer_address, fee_payer_public_key_hash),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY">PROLOGUE_EINVALID_ACCOUNT_AUTH_KEY</a>),
    );
}
</code></pre>



</details>

<a id="0x1_transaction_validation_simulate_prologue"></a>

## Function `simulate_prologue`



<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_simulate_prologue">simulate_prologue</a>(sender: <b>address</b>, gas_payer: <b>address</b>, secondary_signer_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, txn_sequence_number: u64, txn_gas_price: u64, txn_max_gas_units: u64, txn_expiration_time: u64, <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_simulate_prologue">simulate_prologue</a>(
    sender: <b>address</b>,
    gas_payer: <b>address</b>,
    secondary_signer_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
    txn_sequence_number: u64,
    txn_gas_price: u64,
    txn_max_gas_units: u64,
    txn_expiration_time: u64,
    <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8,
) {
    <b>assert</b>!(
        <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>() &lt; txn_expiration_time,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ETRANSACTION_EXPIRED">PROLOGUE_ETRANSACTION_EXPIRED</a>),
    );
    <b>assert</b>!(<a href="chain_id.md#0x1_chain_id_get">chain_id::get</a>() == <a href="chain_id.md#0x1_chain_id">chain_id</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EBAD_CHAIN_ID">PROLOGUE_EBAD_CHAIN_ID</a>));

    // Ensure the transaction sender is a valid <a href="account.md#0x1_account">account</a>
    <b>assert</b>!(!<a href="object.md#0x1_object_is_object">object::is_object</a>(sender), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EACCOUNT_DOES_NOT_EXIST">PROLOGUE_EACCOUNT_DOES_NOT_EXIST</a>));

    <b>if</b> (
        sender == gas_payer
        || <a href="account.md#0x1_account_exists_at">account::exists_at</a>(sender)
        || !<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_sponsored_automatic_account_creation_enabled">features::sponsored_automatic_account_creation_enabled</a>()
        || txn_sequence_number &gt; 0
    ) {
        <b>assert</b>!(<a href="account.md#0x1_account_exists_at">account::exists_at</a>(sender), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EACCOUNT_DOES_NOT_EXIST">PROLOGUE_EACCOUNT_DOES_NOT_EXIST</a>));

        <b>let</b> account_sequence_number = <a href="account.md#0x1_account_get_sequence_number">account::get_sequence_number</a>(sender);
        <b>assert</b>!(
            txn_sequence_number &lt; (1u64 &lt;&lt; 63),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_out_of_range">error::out_of_range</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_BIG">PROLOGUE_ESEQUENCE_NUMBER_TOO_BIG</a>)
        );

        <b>assert</b>!(
            txn_sequence_number &gt;= account_sequence_number,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_OLD">PROLOGUE_ESEQUENCE_NUMBER_TOO_OLD</a>)
        );

        <b>assert</b>!(
            txn_sequence_number == account_sequence_number,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW">PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW</a>)
        );
    } <b>else</b> {
        // In this case, the transaction is sponsored and the <a href="account.md#0x1_account">account</a> does not exist, so ensure
        // the default values match.
        <b>assert</b>!(
            txn_sequence_number == 0,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW">PROLOGUE_ESEQUENCE_NUMBER_TOO_NEW</a>)
        );
    };

    <b>let</b> max_transaction_fee = txn_gas_price * txn_max_gas_units;
    <b>assert</b>!(
        <a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store_exists">primary_fungible_store::primary_store_exists</a>(gas_payer, <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>()),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ECANT_PAY_GAS_DEPOSIT">PROLOGUE_ECANT_PAY_GAS_DEPOSIT</a>),
    );
    <b>assert</b>!(
        <a href="endless_coin.md#0x1_endless_coin_check_minimum_balance">endless_coin::check_minimum_balance</a>(gas_payer, (max_transaction_fee <b>as</b> u128)),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ECANT_PAY_GAS_DEPOSIT">PROLOGUE_ECANT_PAY_GAS_DEPOSIT</a>),
    );

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_reverse">vector::for_each_reverse</a>(secondary_signer_addresses, |<a href="account.md#0x1_account">account</a>| {
        <b>assert</b>!(<a href="account.md#0x1_account_exists_at">account::exists_at</a>(<a href="account.md#0x1_account">account</a>), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_EACCOUNT_DOES_NOT_EXIST">PROLOGUE_EACCOUNT_DOES_NOT_EXIST</a>));
    });
}
</code></pre>



</details>

<a id="0x1_transaction_validation_epilogue"></a>

## Function `epilogue`

Epilogue function is run after a transaction is successfully executed.
Called by the Adapter


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_epilogue">epilogue</a>(<a href="account.md#0x1_account">account</a>: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, storage_fee: u64, storage_fee_refunded: u64, txn_gas_price: u64, txn_max_gas_units: u64, gas_units_remaining: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_epilogue">epilogue</a>(
    <a href="account.md#0x1_account">account</a>: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    storage_fee: u64,
    storage_fee_refunded: u64,
    txn_gas_price: u64,
    txn_max_gas_units: u64,
    gas_units_remaining: u64
) {
    <b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(&<a href="account.md#0x1_account">account</a>);
    <a href="transaction_validation.md#0x1_transaction_validation_epilogue_gas_payer">epilogue_gas_payer</a>(<a href="account.md#0x1_account">account</a>, addr, storage_fee, storage_fee_refunded, txn_gas_price, txn_max_gas_units, gas_units_remaining);
}
</code></pre>



</details>

<a id="0x1_transaction_validation_epilogue_gas_payer"></a>

## Function `epilogue_gas_payer`

Epilogue function with explicit gas payer specified, is run after a transaction is successfully executed.
Called by the Adapter


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_epilogue_gas_payer">epilogue_gas_payer</a>(<a href="account.md#0x1_account">account</a>: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, gas_payer: <b>address</b>, storage_fee: u64, storage_fee_refunded: u64, txn_gas_price: u64, txn_max_gas_units: u64, gas_units_remaining: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_validation.md#0x1_transaction_validation_epilogue_gas_payer">epilogue_gas_payer</a>(
    <a href="account.md#0x1_account">account</a>: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    gas_payer: <b>address</b>,
    storage_fee: u64,
    storage_fee_refunded: u64,
    txn_gas_price: u64,
    txn_max_gas_units: u64,
    gas_units_remaining: u64
) {
    <b>assert</b>!(txn_max_gas_units &gt;= gas_units_remaining, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="transaction_validation.md#0x1_transaction_validation_EOUT_OF_GAS">EOUT_OF_GAS</a>));
    <b>let</b> gas_used = txn_max_gas_units - gas_units_remaining;

    <b>assert</b>!(
        (txn_gas_price <b>as</b> u128) * (gas_used <b>as</b> u128) &lt;= <a href="transaction_validation.md#0x1_transaction_validation_MAX_U64">MAX_U64</a>,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_out_of_range">error::out_of_range</a>(<a href="transaction_validation.md#0x1_transaction_validation_EOUT_OF_GAS">EOUT_OF_GAS</a>)
    );

    <b>assert</b>!(
        txn_gas_price * gas_used &gt;= storage_fee,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_out_of_range">error::out_of_range</a>(<a href="transaction_validation.md#0x1_transaction_validation_EOUT_OF_GAS">EOUT_OF_GAS</a>)
    );

    // exclude storage fee from total transaction fee
    <b>let</b> transaction_fee_amount = ((txn_gas_price * gas_used - storage_fee) <b>as</b> u128);
    // it's important <b>to</b> maintain the <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">error</a> <a href="code.md#0x1_code">code</a> consistent <b>with</b> vm
    // <b>to</b> do failed transaction cleanup.
    <b>assert</b>!(
        // skip check `<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_collect_and_distribute_gas_fees">features::collect_and_distribute_gas_fees</a>()` <b>to</b> simplify
        <a href="transaction_fee.md#0x1_transaction_fee_collect_fee">transaction_fee::collect_fee</a>(gas_payer, transaction_fee_amount, (storage_fee <b>as</b> u128)),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_out_of_range">error::out_of_range</a>(<a href="transaction_validation.md#0x1_transaction_validation_PROLOGUE_ECANT_PAY_GAS_DEPOSIT">PROLOGUE_ECANT_PAY_GAS_DEPOSIT</a>),
    );

    <b>if</b> (storage_fee_refunded &gt; 0) {
        <a href="transaction_fee.md#0x1_transaction_fee_storage_refund">transaction_fee::storage_refund</a>(gas_payer, (storage_fee_refunded <b>as</b> u128));
    };

    // Increment sequence number
    <b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(&<a href="account.md#0x1_account">account</a>);
    <a href="account.md#0x1_account_increment_sequence_number">account::increment_sequence_number</a>(addr);
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

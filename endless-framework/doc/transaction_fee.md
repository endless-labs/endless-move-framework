
<a id="0x1_transaction_fee"></a>

# Module `0x1::transaction_fee`

This module provides an interface to burn or collect and redistribute transaction fees.


-  [Resource `EndlessCoinCapabilities`](#0x1_transaction_fee_EndlessCoinCapabilities)
-  [Resource `EndlessCoinMintCapability`](#0x1_transaction_fee_EndlessCoinMintCapability)
-  [Resource `CollectedFeesPerBlock`](#0x1_transaction_fee_CollectedFeesPerBlock)
-  [Struct `FeeStatement`](#0x1_transaction_fee_FeeStatement)
-  [Constants](#@Constants_0)
-  [Function `initialize_fee_collection_and_distribution`](#0x1_transaction_fee_initialize_fee_collection_and_distribution)
-  [Function `is_fees_collection_enabled`](#0x1_transaction_fee_is_fees_collection_enabled)
-  [Function `upgrade_burn_percentage`](#0x1_transaction_fee_upgrade_burn_percentage)
-  [Function `register_proposer_for_fee_collection`](#0x1_transaction_fee_register_proposer_for_fee_collection)
-  [Function `burn_coin_fraction`](#0x1_transaction_fee_burn_coin_fraction)
-  [Function `process_collected_fees`](#0x1_transaction_fee_process_collected_fees)
-  [Function `burn_fee`](#0x1_transaction_fee_burn_fee)
-  [Function `storage_refund`](#0x1_transaction_fee_storage_refund)
-  [Function `collect_fee`](#0x1_transaction_fee_collect_fee)
-  [Function `store_endless_coin_burn_cap`](#0x1_transaction_fee_store_endless_coin_burn_cap)
-  [Function `store_endless_coin_mint_cap`](#0x1_transaction_fee_store_endless_coin_mint_cap)
-  [Function `initialize_storage_refund`](#0x1_transaction_fee_initialize_storage_refund)
-  [Function `emit_fee_statement`](#0x1_transaction_fee_emit_fee_statement)


<pre><code><b>use</b> <a href="endless_coin.md#0x1_endless_coin">0x1::endless_coin</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="event.md#0x1_event">0x1::event</a>;
<b>use</b> <a href="fungible_asset.md#0x1_fungible_asset">0x1::fungible_asset</a>;
<b>use</b> <a href="object.md#0x1_object">0x1::object</a>;
<b>use</b> <a href="primary_fungible_store.md#0x1_primary_fungible_store">0x1::primary_fungible_store</a>;
<b>use</b> <a href="stake.md#0x1_stake">0x1::stake</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
</code></pre>



<a id="0x1_transaction_fee_EndlessCoinCapabilities"></a>

## Resource `EndlessCoinCapabilities`

Stores burn capability to burn the gas fees.


<pre><code><b>struct</b> <a href="transaction_fee.md#0x1_transaction_fee_EndlessCoinCapabilities">EndlessCoinCapabilities</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>burn_cap: <a href="fungible_asset.md#0x1_fungible_asset_BurnRef">fungible_asset::BurnRef</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_transaction_fee_EndlessCoinMintCapability"></a>

## Resource `EndlessCoinMintCapability`

Stores mint capability to mint the refunds.


<pre><code><b>struct</b> <a href="transaction_fee.md#0x1_transaction_fee_EndlessCoinMintCapability">EndlessCoinMintCapability</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>mint_cap: <a href="fungible_asset.md#0x1_fungible_asset_MintRef">fungible_asset::MintRef</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_transaction_fee_CollectedFeesPerBlock"></a>

## Resource `CollectedFeesPerBlock`

Stores information about the block proposer and the amount of fees
collected when executing the block.


<pre><code><b>struct</b> <a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>amount: <a href="fungible_asset.md#0x1_fungible_asset_AggregatableCoin">fungible_asset::AggregatableCoin</a></code>
</dt>
<dd>

</dd>
<dt>
<code>storage_fee: <a href="fungible_asset.md#0x1_fungible_asset_AggregatableCoin">fungible_asset::AggregatableCoin</a></code>
</dt>
<dd>

</dd>
<dt>
<code>proposer: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>burn_percentage: u8</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_transaction_fee_FeeStatement"></a>

## Struct `FeeStatement`

Breakdown of fee charge and refund for a transaction.
The structure is:

- Net charge or refund (not in the statement)
- total charge: total_charge_gas_units, matches <code>gas_used</code> in the on-chain <code>TransactionInfo</code>.
This is the sum of the sub-items below. Notice that there's potential precision loss when
the conversion between internal and external gas units and between native token and gas
units, so it's possible that the numbers don't add up exactly. -- This number is the final
charge, while the break down is merely informational.
- gas charge for execution (CPU time): <code>execution_gas_units</code>
- gas charge for IO (storage random access): <code>io_gas_units</code>
- storage fee charge (storage space): <code>storage_fee_veins</code>, to be included in
<code>total_charge_gas_unit</code>, this number is converted to gas units according to the user
specified <code>gas_unit_price</code> on the transaction.
- storage deletion refund: <code>storage_fee_refund_veins</code>, this is not included in <code>gas_used</code> or
<code>total_charge_gas_units</code>, the net charge / refund is calculated by
<code>total_charge_gas_units</code> * <code>gas_unit_price</code> - <code>storage_fee_refund_veins</code>.

This is meant to emitted as a module event.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="transaction_fee.md#0x1_transaction_fee_FeeStatement">FeeStatement</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>total_charge_gas_units: u64</code>
</dt>
<dd>
 Total gas charge.
</dd>
<dt>
<code>execution_gas_units: u64</code>
</dt>
<dd>
 Execution gas charge.
</dd>
<dt>
<code>io_gas_units: u64</code>
</dt>
<dd>
 IO gas charge.
</dd>
<dt>
<code>storage_fee_veins: u64</code>
</dt>
<dd>
 Storage fee charge.
</dd>
<dt>
<code>storage_fee_refund_veins: u64</code>
</dt>
<dd>
 Storage fee refund.
</dd>
<dt>
<code>gas_payer: <b>address</b></code>
</dt>
<dd>
 Gas payer
</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_transaction_fee_EALREADY_COLLECTING_FEES"></a>

Gas fees are already being collected and the struct holding
information about collected amounts is already published.


<pre><code><b>const</b> <a href="transaction_fee.md#0x1_transaction_fee_EALREADY_COLLECTING_FEES">EALREADY_COLLECTING_FEES</a>: u64 = 1;
</code></pre>



<a id="0x1_transaction_fee_EINVALID_BURN_PERCENTAGE"></a>

The burn percentage is out of range [0, 100].


<pre><code><b>const</b> <a href="transaction_fee.md#0x1_transaction_fee_EINVALID_BURN_PERCENTAGE">EINVALID_BURN_PERCENTAGE</a>: u64 = 3;
</code></pre>



<a id="0x1_transaction_fee_ENO_LONGER_SUPPORTED"></a>

No longer supported.


<pre><code><b>const</b> <a href="transaction_fee.md#0x1_transaction_fee_ENO_LONGER_SUPPORTED">ENO_LONGER_SUPPORTED</a>: u64 = 4;
</code></pre>



<a id="0x1_transaction_fee_initialize_fee_collection_and_distribution"></a>

## Function `initialize_fee_collection_and_distribution`

Initializes the resource storing information about gas fees collection and
distribution. Should be called by genesis.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_initialize_fee_collection_and_distribution">initialize_fee_collection_and_distribution</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, burn_percentage: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_initialize_fee_collection_and_distribution">initialize_fee_collection_and_distribution</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, burn_percentage: u8) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>assert</b>!(
        !<b>exists</b>&lt;<a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a>&gt;(@endless_framework),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_already_exists">error::already_exists</a>(<a href="transaction_fee.md#0x1_transaction_fee_EALREADY_COLLECTING_FEES">EALREADY_COLLECTING_FEES</a>)
    );
    <b>assert</b>!(burn_percentage &lt;= 100, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_out_of_range">error::out_of_range</a>(<a href="transaction_fee.md#0x1_transaction_fee_EINVALID_BURN_PERCENTAGE">EINVALID_BURN_PERCENTAGE</a>));

    // Make sure stakng <b>module</b> is aware of transaction fees collection.
    <a href="stake.md#0x1_stake_initialize_validator_fees">stake::initialize_validator_fees</a>(endless_framework);

    // Initially, no fees are collected and the <a href="block.md#0x1_block">block</a> proposer is not set.
    <b>let</b> collected_fees = <a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a> {
        amount: <a href="fungible_asset.md#0x1_fungible_asset_initialize_aggregatable_coin">fungible_asset::initialize_aggregatable_coin</a>(<a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>()),
        storage_fee: <a href="fungible_asset.md#0x1_fungible_asset_initialize_aggregatable_coin">fungible_asset::initialize_aggregatable_coin</a>(<a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>()),
        proposer: @0x0,
        burn_percentage,
    };
    <b>move_to</b>(endless_framework, collected_fees);
}
</code></pre>



</details>

<a id="0x1_transaction_fee_is_fees_collection_enabled"></a>

## Function `is_fees_collection_enabled`



<pre><code><b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_is_fees_collection_enabled">is_fees_collection_enabled</a>(): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_is_fees_collection_enabled">is_fees_collection_enabled</a>(): bool {
    <b>exists</b>&lt;<a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a>&gt;(@endless_framework)
}
</code></pre>



</details>

<a id="0x1_transaction_fee_upgrade_burn_percentage"></a>

## Function `upgrade_burn_percentage`

Sets the burn percentage for collected fees to a new value. Should be called by on-chain governance.


<pre><code><b>public</b> <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_upgrade_burn_percentage">upgrade_burn_percentage</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_burn_percentage: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_upgrade_burn_percentage">upgrade_burn_percentage</a>(
    endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    new_burn_percentage: u8
) <b>acquires</b> <a href="transaction_fee.md#0x1_transaction_fee_EndlessCoinCapabilities">EndlessCoinCapabilities</a>, <a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a> {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>assert</b>!(new_burn_percentage &lt;= 100, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_out_of_range">error::out_of_range</a>(<a href="transaction_fee.md#0x1_transaction_fee_EINVALID_BURN_PERCENTAGE">EINVALID_BURN_PERCENTAGE</a>));

    // Prior <b>to</b> upgrading the burn percentage, make sure <b>to</b> process collected
    // fees. Otherwise we would <b>use</b> the new (incorrect) burn_percentage when
    // processing fees later!
    <a href="transaction_fee.md#0x1_transaction_fee_process_collected_fees">process_collected_fees</a>();

    <b>if</b> (<a href="transaction_fee.md#0x1_transaction_fee_is_fees_collection_enabled">is_fees_collection_enabled</a>()) {
        // Upgrade <b>has</b> no effect unless fees are being collected.
        <b>let</b> burn_percentage = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a>&gt;(@endless_framework).burn_percentage;
        *burn_percentage = new_burn_percentage
    }
}
</code></pre>



</details>

<a id="0x1_transaction_fee_register_proposer_for_fee_collection"></a>

## Function `register_proposer_for_fee_collection`

Registers the proposer of the block for gas fees collection. This function
can only be called at the beginning of the block.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_register_proposer_for_fee_collection">register_proposer_for_fee_collection</a>(proposer_addr: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_register_proposer_for_fee_collection">register_proposer_for_fee_collection</a>(proposer_addr: <b>address</b>) <b>acquires</b> <a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a> {
    <b>if</b> (<a href="transaction_fee.md#0x1_transaction_fee_is_fees_collection_enabled">is_fees_collection_enabled</a>()) {
        <b>let</b> collected_fees = <b>borrow_global_mut</b>&lt;<a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a>&gt;(@endless_framework);
        collected_fees.proposer = proposer_addr
    }
}
</code></pre>



</details>

<a id="0x1_transaction_fee_burn_coin_fraction"></a>

## Function `burn_coin_fraction`

Burns a specified fraction of the coin.


<pre><code><b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_burn_coin_fraction">burn_coin_fraction</a>(fa: &<b>mut</b> <a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>, burn_percentage: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_burn_coin_fraction">burn_coin_fraction</a>(fa: &<b>mut</b> FungibleAsset, burn_percentage: u8) <b>acquires</b> <a href="transaction_fee.md#0x1_transaction_fee_EndlessCoinCapabilities">EndlessCoinCapabilities</a> {
    <b>assert</b>!(burn_percentage &lt;= 100, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_out_of_range">error::out_of_range</a>(<a href="transaction_fee.md#0x1_transaction_fee_EINVALID_BURN_PERCENTAGE">EINVALID_BURN_PERCENTAGE</a>));

    <b>let</b> collected_amount = <a href="fungible_asset.md#0x1_fungible_asset_amount">fungible_asset::amount</a>(fa);
    <b>spec</b> {
        // We <b>assume</b> that `burn_percentage * collected_amount` does not overflow.
        <b>assume</b> burn_percentage * collected_amount &lt;= MAX_U64;
    };
    <b>let</b> amount_to_burn = (burn_percentage <b>as</b> u128) * collected_amount / 100;
    <b>if</b> (amount_to_burn &gt; 0) {
        <b>let</b> burn_fa = <a href="fungible_asset.md#0x1_fungible_asset_extract">fungible_asset::extract</a>(fa, amount_to_burn);
        <a href="fungible_asset.md#0x1_fungible_asset_burn">fungible_asset::burn</a>(&<b>borrow_global</b>&lt;<a href="transaction_fee.md#0x1_transaction_fee_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(@endless_framework).burn_cap, burn_fa);
    }
}
</code></pre>



</details>

<a id="0x1_transaction_fee_process_collected_fees"></a>

## Function `process_collected_fees`

Calculates the fee which should be distributed to the block proposer at the
end of an epoch, and records it in the system. This function can only be called
at the beginning of the block or during reconfiguration.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_process_collected_fees">process_collected_fees</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_process_collected_fees">process_collected_fees</a>() <b>acquires</b> <a href="transaction_fee.md#0x1_transaction_fee_EndlessCoinCapabilities">EndlessCoinCapabilities</a>, <a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a> {
    <b>if</b> (!<a href="transaction_fee.md#0x1_transaction_fee_is_fees_collection_enabled">is_fees_collection_enabled</a>()) {
        <b>return</b>
    };
    <b>let</b> collected_fees = <b>borrow_global_mut</b>&lt;<a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a>&gt;(@endless_framework);

    // If there are no collected fees, only unset the proposer. See the rationale for
    // setting proposer <b>to</b> @0x0 below.
    <b>if</b> (<a href="fungible_asset.md#0x1_fungible_asset_is_aggregatable_coin_zero">fungible_asset::is_aggregatable_coin_zero</a>(&collected_fees.amount)) {
        <b>if</b> (collected_fees.proposer != @0x0) {
            collected_fees.proposer = @0x0;
        };
        <b>return</b>
    };

    // Otherwise get the collected fee, and check <b>if</b> it can distributed later.
    <b>let</b> coin = <a href="fungible_asset.md#0x1_fungible_asset_drain_aggregatable_coin">fungible_asset::drain_aggregatable_coin</a>(&<b>mut</b> collected_fees.amount);
    <b>if</b> (collected_fees.proposer != @0x0) {
        // Extract the <b>address</b> of proposer here and reset it <b>to</b> @0x0. This
        // is particularly useful <b>to</b> avoid <a href="../../endless-stdlib/doc/any.md#0x1_any">any</a> undesired side-effects <b>where</b> coins are
        // collected but never distributed or distributed <b>to</b> the wrong <a href="account.md#0x1_account">account</a>.
        // With this design, processing collected fees enforces that all fees will be burnt
        // unless the proposer is specified in the <a href="block.md#0x1_block">block</a> prologue. When we have a governance
        // proposal that triggers <a href="reconfiguration.md#0x1_reconfiguration">reconfiguration</a>, we distribute pending fees and burn the
        // fee for the proposal. Otherwise, that fee would be leaked <b>to</b> the next <a href="block.md#0x1_block">block</a>.
        <b>let</b> proposer = collected_fees.proposer;
        collected_fees.proposer = @0x0;

        // Since the <a href="block.md#0x1_block">block</a> can be produced by the VM itself, we have <b>to</b> make sure we catch
        // this case.
        <b>if</b> (proposer == @vm_reserved) {
            <a href="transaction_fee.md#0x1_transaction_fee_burn_coin_fraction">burn_coin_fraction</a>(&<b>mut</b> coin, 100);
            <a href="fungible_asset.md#0x1_fungible_asset_destroy_zero">fungible_asset::destroy_zero</a>(coin);
            <b>return</b>
        };

        <a href="transaction_fee.md#0x1_transaction_fee_burn_coin_fraction">burn_coin_fraction</a>(&<b>mut</b> coin, collected_fees.burn_percentage);
        <a href="stake.md#0x1_stake_add_transaction_fee">stake::add_transaction_fee</a>(proposer, coin);
        <b>return</b>
    };

    // If checks did not pass, simply burn all collected coins and <b>return</b> none.
    <a href="transaction_fee.md#0x1_transaction_fee_burn_coin_fraction">burn_coin_fraction</a>(&<b>mut</b> coin, 100);
    <a href="fungible_asset.md#0x1_fungible_asset_destroy_zero">fungible_asset::destroy_zero</a>(coin)
}
</code></pre>



</details>

<a id="0x1_transaction_fee_burn_fee"></a>

## Function `burn_fee`

Burn transaction fees in epilogue.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_burn_fee">burn_fee</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>, fee: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_burn_fee">burn_fee</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>, fee: u128) <b>acquires</b> <a href="transaction_fee.md#0x1_transaction_fee_EndlessCoinCapabilities">EndlessCoinCapabilities</a> {
    <a href="primary_fungible_store.md#0x1_primary_fungible_store_burn">primary_fungible_store::burn</a>(
        &<b>borrow_global</b>&lt;<a href="transaction_fee.md#0x1_transaction_fee_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(@endless_framework).burn_cap,
        <a href="account.md#0x1_account">account</a>,
        fee,
    );
}
</code></pre>



</details>

<a id="0x1_transaction_fee_storage_refund"></a>

## Function `storage_refund`

Storage refund in epilogue.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_storage_refund">storage_refund</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>, refund: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_storage_refund">storage_refund</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>, refund: u128) <b>acquires</b> <a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a> {
    <b>let</b> collected_fees = <b>borrow_global_mut</b>&lt;<a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a>&gt;(@endless_framework);
    <b>let</b> collected_storage_fees = &<b>mut</b> collected_fees.storage_fee;
    <b>let</b> fa = <a href="fungible_asset.md#0x1_fungible_asset_extract_aggregatable_coin">fungible_asset::extract_aggregatable_coin</a>(collected_storage_fees, refund);
    <b>let</b> metadata = <a href="fungible_asset.md#0x1_fungible_asset_metadata_from_asset">fungible_asset::metadata_from_asset</a>(&fa);
    <b>let</b> store = <a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store">primary_fungible_store::primary_store</a>(<a href="account.md#0x1_account">account</a>, metadata);
    <a href="fungible_asset.md#0x1_fungible_asset_deposit">fungible_asset::deposit</a>(store, fa);
}
</code></pre>



</details>

<a id="0x1_transaction_fee_collect_fee"></a>

## Function `collect_fee`

Collect transaction fees in epilogue.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_collect_fee">collect_fee</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>, fee: u128, storage_fee: u128): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_collect_fee">collect_fee</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>, fee: u128, storage_fee: u128): bool <b>acquires</b> <a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a> {
    <b>let</b> collected_fees = <b>borrow_global_mut</b>&lt;<a href="transaction_fee.md#0x1_transaction_fee_CollectedFeesPerBlock">CollectedFeesPerBlock</a>&gt;(@endless_framework);

    // Here, we are always optimistic and always collect fees. If the proposer is not set,
    // or we cannot redistribute fees later for some reason (e.g. <a href="account.md#0x1_account">account</a> cannot receive EndsCoin)
    // we burn them all at once. This way we avoid having a check for every transaction epilogue.
    <b>let</b> collected_amount = &<b>mut</b> collected_fees.amount;

    <b>let</b> metadata = <a href="fungible_asset.md#0x1_fungible_asset_metadata_from_aggregatable_coin">fungible_asset::metadata_from_aggregatable_coin</a>(collected_amount);
    // primary store <b>address</b> of <a href="account.md#0x1_account">account</a>
    <b>let</b> store_addr = <a href="primary_fungible_store.md#0x1_primary_fungible_store_primary_store_address">primary_fungible_store::primary_store_address</a>(<a href="account.md#0x1_account">account</a>, metadata);
    // does not <b>include</b> storage fee
    <b>let</b> success = <a href="fungible_asset.md#0x1_fungible_asset_collect_into_aggregatable_coin">fungible_asset::collect_into_aggregatable_coin</a>(store_addr, fee, collected_amount);
    <b>if</b> (!success) {
        <b>return</b> <b>false</b>
    };
    // storage fee
    <b>let</b> collected_storage_amount = &<b>mut</b> collected_fees.storage_fee;
    <a href="fungible_asset.md#0x1_fungible_asset_collect_into_aggregatable_coin">fungible_asset::collect_into_aggregatable_coin</a>(store_addr, storage_fee, collected_storage_amount)
}
</code></pre>



</details>

<a id="0x1_transaction_fee_store_endless_coin_burn_cap"></a>

## Function `store_endless_coin_burn_cap`

Only called during genesis.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_store_endless_coin_burn_cap">store_endless_coin_burn_cap</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, burn_cap: <a href="fungible_asset.md#0x1_fungible_asset_BurnRef">fungible_asset::BurnRef</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_store_endless_coin_burn_cap">store_endless_coin_burn_cap</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, burn_cap: BurnRef) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>move_to</b>(endless_framework, <a href="transaction_fee.md#0x1_transaction_fee_EndlessCoinCapabilities">EndlessCoinCapabilities</a> { burn_cap })
}
</code></pre>



</details>

<a id="0x1_transaction_fee_store_endless_coin_mint_cap"></a>

## Function `store_endless_coin_mint_cap`

Only called during genesis.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_store_endless_coin_mint_cap">store_endless_coin_mint_cap</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, mint_cap: <a href="fungible_asset.md#0x1_fungible_asset_MintRef">fungible_asset::MintRef</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_store_endless_coin_mint_cap">store_endless_coin_mint_cap</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, mint_cap: MintRef) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>move_to</b>(endless_framework, <a href="transaction_fee.md#0x1_transaction_fee_EndlessCoinMintCapability">EndlessCoinMintCapability</a> { mint_cap })
}
</code></pre>



</details>

<a id="0x1_transaction_fee_initialize_storage_refund"></a>

## Function `initialize_storage_refund`



<pre><code>#[deprecated]
<b>public</b> <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_initialize_storage_refund">initialize_storage_refund</a>(_: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_initialize_storage_refund">initialize_storage_refund</a>(_: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <b>abort</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_implemented">error::not_implemented</a>(<a href="transaction_fee.md#0x1_transaction_fee_ENO_LONGER_SUPPORTED">ENO_LONGER_SUPPORTED</a>)
}
</code></pre>



</details>

<a id="0x1_transaction_fee_emit_fee_statement"></a>

## Function `emit_fee_statement`



<pre><code><b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_emit_fee_statement">emit_fee_statement</a>(fee_statement: <a href="transaction_fee.md#0x1_transaction_fee_FeeStatement">transaction_fee::FeeStatement</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="transaction_fee.md#0x1_transaction_fee_emit_fee_statement">emit_fee_statement</a>(fee_statement: <a href="transaction_fee.md#0x1_transaction_fee_FeeStatement">FeeStatement</a>) {
    <a href="event.md#0x1_event_emit">event::emit</a>(fee_statement)
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

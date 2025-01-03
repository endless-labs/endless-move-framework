
<a id="0x1_faucet"></a>

# Module `0x1::faucet`

This module works with the <code>endless <a href="account.md#0x1_account">account</a> fund-<b>with</b>-<a href="faucet.md#0x1_faucet">faucet</a></code>, performing the function of faucet service.

The faucet function act as following:
- get signer of root account
- perform <code>mint</code> and <code>transfer</code>, fund to dest account

Note:
- current chain cannot be <code>mainnet</code>
- gas fee is charged from 0x1 (suppose 0x1 balance is sufficient to cover the gas charges)
- coins minted by root account
- 10 EDS can be claimed once
- Each account can only claim once every 24 hours
- Total claimed cannot above U64_MAX/4


-  [Resource `ClaimedInfo`](#0x1_faucet_ClaimedInfo)
-  [Constants](#@Constants_0)
-  [Function `fund`](#0x1_faucet_fund)


<pre><code><b>use</b> <a href="aggregator_v2.md#0x1_aggregator_v2">0x1::aggregator_v2</a>;
<b>use</b> <a href="chain_id.md#0x1_chain_id">0x1::chain_id</a>;
<b>use</b> <a href="create_signer.md#0x1_create_signer">0x1::create_signer</a>;
<b>use</b> <a href="endless_account.md#0x1_endless_account">0x1::endless_account</a>;
<b>use</b> <a href="endless_coin.md#0x1_endless_coin">0x1::endless_coin</a>;
<b>use</b> <a href="../../endless-stdlib/doc/table.md#0x1_table">0x1::table</a>;
<b>use</b> <a href="timestamp.md#0x1_timestamp">0x1::timestamp</a>;
</code></pre>



<a id="0x1_faucet_ClaimedInfo"></a>

## Resource `ClaimedInfo`



<pre><code><b>struct</b> <a href="faucet.md#0x1_faucet_ClaimedInfo">ClaimedInfo</a> <b>has</b> store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>claimed_accounts: <a href="../../endless-stdlib/doc/table.md#0x1_table_Table">table::Table</a>&lt;<b>address</b>, u64&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>total_claimed: <a href="aggregator_v2.md#0x1_aggregator_v2_Aggregator">aggregator_v2::Aggregator</a>&lt;u128&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_faucet_CLAIM_AMOUNT"></a>



<pre><code><b>const</b> <a href="faucet.md#0x1_faucet_CLAIM_AMOUNT">CLAIM_AMOUNT</a>: u128 = 10;
</code></pre>



<a id="0x1_faucet_E_CLAIM_RATE_LIMIT"></a>



<pre><code><b>const</b> <a href="faucet.md#0x1_faucet_E_CLAIM_RATE_LIMIT">E_CLAIM_RATE_LIMIT</a>: u64 = 2;
</code></pre>



<a id="0x1_faucet_E_WRONG_CHAIN"></a>



<pre><code><b>const</b> <a href="faucet.md#0x1_faucet_E_WRONG_CHAIN">E_WRONG_CHAIN</a>: u64 = 1;
</code></pre>



<a id="0x1_faucet_GAS_BUFFER"></a>



<pre><code><b>const</b> <a href="faucet.md#0x1_faucet_GAS_BUFFER">GAS_BUFFER</a>: u128 = 150000;
</code></pre>



<a id="0x1_faucet_MAINNET"></a>



<pre><code><b>const</b> <a href="faucet.md#0x1_faucet_MAINNET">MAINNET</a>: u8 = 220;
</code></pre>



<a id="0x1_faucet_ONE_EDS"></a>



<pre><code><b>const</b> <a href="faucet.md#0x1_faucet_ONE_EDS">ONE_EDS</a>: u128 = 100000000;
</code></pre>



<a id="0x1_faucet_U64_MAX"></a>



<pre><code><b>const</b> <a href="faucet.md#0x1_faucet_U64_MAX">U64_MAX</a>: u128 = 18446744073709551615;
</code></pre>



<a id="0x1_faucet_fund"></a>

## Function `fund`



<pre><code>entry <b>fun</b> <a href="faucet.md#0x1_faucet_fund">fund</a>(dst_addr: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry sponsored <b>fun</b> <a href="faucet.md#0x1_faucet_fund">fund</a>(dst_addr: <b>address</b>) <b>acquires</b> <a href="faucet.md#0x1_faucet_ClaimedInfo">ClaimedInfo</a> {
    // Cannot <b>apply</b> <b>to</b> mainnet
    <b>assert</b>!(<a href="chain_id.md#0x1_chain_id_get">chain_id::get</a>() != <a href="faucet.md#0x1_faucet_MAINNET">MAINNET</a>, <a href="faucet.md#0x1_faucet_E_WRONG_CHAIN">E_WRONG_CHAIN</a>);

    // create <a href="../../endless-stdlib/doc/table.md#0x1_table">table</a> <b>if</b> not exist
    <b>if</b> (!<b>exists</b>&lt;<a href="faucet.md#0x1_faucet_ClaimedInfo">ClaimedInfo</a>&gt;(@endless_framework)) {
        <b>let</b> framework = <a href="create_signer.md#0x1_create_signer">create_signer</a>(@endless_framework);
        <b>move_to</b>(&framework, <a href="faucet.md#0x1_faucet_ClaimedInfo">ClaimedInfo</a> {
            claimed_accounts: <a href="../../endless-stdlib/doc/table.md#0x1_table_new">table::new</a>(),
            total_claimed: <a href="aggregator_v2.md#0x1_aggregator_v2_create_aggregator">aggregator_v2::create_aggregator</a>&lt;u128&gt;(<a href="faucet.md#0x1_faucet_U64_MAX">U64_MAX</a> / 4),
        });
    };

    <b>let</b> claimed = <b>borrow_global</b>&lt;<a href="faucet.md#0x1_faucet_ClaimedInfo">ClaimedInfo</a>&gt;(@endless_framework);
    <b>if</b> (<a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(&claimed.claimed_accounts, dst_addr)) {
        <b>let</b> claimed_timestamp = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(&claimed.claimed_accounts, dst_addr);
        <b>assert</b>!((<a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>() - *claimed_timestamp) &gt; 24 * 3600, <a href="faucet.md#0x1_faucet_E_CLAIM_RATE_LIMIT">E_CLAIM_RATE_LIMIT</a>);
    };

    <b>let</b> fund_vein = <a href="faucet.md#0x1_faucet_CLAIM_AMOUNT">CLAIM_AMOUNT</a> * <a href="faucet.md#0x1_faucet_ONE_EDS">ONE_EDS</a>;
    <b>let</b> minter = <a href="create_signer.md#0x1_create_signer">create_signer</a>(@0x49dad7);

    // mint gas for 0x1, <b>to</b> cover gas fee
    <a href="endless_coin.md#0x1_endless_coin_mint">endless_coin::mint</a>(&minter, @endless_framework, <a href="faucet.md#0x1_faucet_GAS_BUFFER">GAS_BUFFER</a>);
    // mint and transfer, create funded <a href="account.md#0x1_account">account</a> on chain
    <a href="endless_coin.md#0x1_endless_coin_mint">endless_coin::mint</a>(&minter, @0x49dad7, fund_vein);
    <a href="endless_account.md#0x1_endless_account_transfer">endless_account::transfer</a>(&minter, dst_addr, fund_vein);

    <b>let</b> claimed_table = <b>borrow_global_mut</b>&lt;<a href="faucet.md#0x1_faucet_ClaimedInfo">ClaimedInfo</a>&gt;(@endless_framework);
    <a href="../../endless-stdlib/doc/table.md#0x1_table_upsert">table::upsert</a>(&<b>mut</b> claimed_table.claimed_accounts, dst_addr, <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>());
    <a href="aggregator_v2.md#0x1_aggregator_v2_add">aggregator_v2::add</a>(&<b>mut</b> claimed_table.total_claimed, <a href="faucet.md#0x1_faucet_CLAIM_AMOUNT">CLAIM_AMOUNT</a>);
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

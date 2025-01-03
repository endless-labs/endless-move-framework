
<a id="0x1_pe_locking_coin"></a>

# Module `0x1::pe_locking_coin`



-  [Struct `StakerInfo`](#0x1_pe_locking_coin_StakerInfo)
-  [Resource `StakingPool`](#0x1_pe_locking_coin_StakingPool)
-  [Resource `CapStore`](#0x1_pe_locking_coin_CapStore)
-  [Struct `UnlockAt`](#0x1_pe_locking_coin_UnlockAt)
-  [Struct `UnlockInfo`](#0x1_pe_locking_coin_UnlockInfo)
-  [Struct `Claim`](#0x1_pe_locking_coin_Claim)
-  [Constants](#@Constants_0)
-  [Function `total_locks`](#0x1_pe_locking_coin_total_locks)
-  [Function `staking_amount`](#0x1_pe_locking_coin_staking_amount)
-  [Function `get_unlock_info`](#0x1_pe_locking_coin_get_unlock_info)
-  [Function `pe_staking_config`](#0x1_pe_locking_coin_pe_staking_config)
-  [Function `start_pe_distribute_coins`](#0x1_pe_locking_coin_start_pe_distribute_coins)
-  [Function `distribut_pe_coins_with_config`](#0x1_pe_locking_coin_distribut_pe_coins_with_config)
-  [Function `setup_pool_resource`](#0x1_pe_locking_coin_setup_pool_resource)
-  [Function `distribute_coins`](#0x1_pe_locking_coin_distribute_coins)
-  [Function `claim`](#0x1_pe_locking_coin_claim)
-  [Function `do_claim`](#0x1_pe_locking_coin_do_claim)
-  [Function `calc_init_unlock`](#0x1_pe_locking_coin_calc_init_unlock)
-  [Function `calc_next_unlock`](#0x1_pe_locking_coin_calc_next_unlock)
-  [Function `calc_stable_unlock`](#0x1_pe_locking_coin_calc_stable_unlock)
-  [Function `calc_still_locked_amount`](#0x1_pe_locking_coin_calc_still_locked_amount)
-  [Function `get_addr_free_amount`](#0x1_pe_locking_coin_get_addr_free_amount)


<pre><code><b>use</b> <a href="account.md#0x1_account">0x1::account</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs">0x1::bcs</a>;
<b>use</b> <a href="endless_coin.md#0x1_endless_coin">0x1::endless_coin</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="event.md#0x1_event">0x1::event</a>;
<b>use</b> <a href="reconfiguration.md#0x1_reconfiguration">0x1::reconfiguration</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map">0x1::simple_map</a>;
<b>use</b> <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table">0x1::smart_table</a>;
<b>use</b> <a href="timestamp.md#0x1_timestamp">0x1::timestamp</a>;
</code></pre>



<a id="0x1_pe_locking_coin_StakerInfo"></a>

## Struct `StakerInfo`

When staking, token will move to resource account which create by staker address and init_staking will record
staking amount first time. Current amount of token still in staking record by curr_staking.


<pre><code><b>struct</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakerInfo">StakerInfo</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>resource_addr: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>init_staking: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>curr_staking: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_pe_locking_coin_StakingPool"></a>

## Resource `StakingPool`

StakingPool store all staking info of all stakers.


<pre><code><b>struct</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>stakers: <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_SmartTable">smart_table::SmartTable</a>&lt;<b>address</b>, <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakerInfo">pe_locking_coin::StakerInfo</a>&gt;</code>
</dt>
<dd>
 Map from recipient address => StakerInfo.
</dd>
<dt>
<code>total_locks: u64</code>
</dt>
<dd>
 Total amount of token in staking.
</dd>
<dt>
<code>first_unlock_epoch: u64</code>
</dt>
<dd>
 Firs epock to unlock token.
</dd>
</dl>


</details>

<a id="0x1_pe_locking_coin_CapStore"></a>

## Resource `CapStore`

Signer capability of resource address wrapped by CapStore will move to 0x1.


<pre><code><b>struct</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_CapStore">CapStore</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>signer_cap: <a href="account.md#0x1_account_SignerCapability">account::SignerCapability</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_pe_locking_coin_UnlockAt"></a>

## Struct `UnlockAt`

Unlock amount and when to unlock.


<pre><code><b>struct</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_UnlockAt">UnlockAt</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>epoch: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_pe_locking_coin_UnlockInfo"></a>

## Struct `UnlockInfo`

Unlocked token amount when and how much to unlock.


<pre><code><b>struct</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_UnlockInfo">UnlockInfo</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>unlocked: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>unlock_list: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_UnlockAt">pe_locking_coin::UnlockAt</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_pe_locking_coin_Claim"></a>

## Struct `Claim`

Event emitted when a recipient claims unlocked coins.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_Claim">Claim</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>recipient: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>claim_epoch: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>claimed_time_secs: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_pe_locking_coin_ADMINISTRATOR_ADDR"></a>



<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_ADMINISTRATOR_ADDR">ADMINISTRATOR_ADDR</a>: <b>address</b> = 0x1;
</code></pre>



<a id="0x1_pe_locking_coin_EACTIVE_LOCKS_EXIST"></a>

Cannot update the withdrawal address because there are still active/unclaimed locks.


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_EACTIVE_LOCKS_EXIST">EACTIVE_LOCKS_EXIST</a>: u64 = 5;
</code></pre>



<a id="0x1_pe_locking_coin_EADMIN_ACCOUNT_NOT_INITIALIZED"></a>

Sponsor account has not been set up to create locks for the specified CoinType yet.


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_EADMIN_ACCOUNT_NOT_INITIALIZED">EADMIN_ACCOUNT_NOT_INITIALIZED</a>: u64 = 4;
</code></pre>



<a id="0x1_pe_locking_coin_EINSUFFICIENT_ADMIN_BALANCE"></a>

admin has insufficient balance to disritute;


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_EINSUFFICIENT_ADMIN_BALANCE">EINSUFFICIENT_ADMIN_BALANCE</a>: u64 = 6;
</code></pre>



<a id="0x1_pe_locking_coin_ELOCKUP_HAS_NOT_EXPIRED"></a>

Lockup has not expired yet.


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_ELOCKUP_HAS_NOT_EXPIRED">ELOCKUP_HAS_NOT_EXPIRED</a>: u64 = 2;
</code></pre>



<a id="0x1_pe_locking_coin_ELOCK_ALREADY_EXISTS"></a>

Can only create one active lock per recipient at once.


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_ELOCK_ALREADY_EXISTS">ELOCK_ALREADY_EXISTS</a>: u64 = 3;
</code></pre>



<a id="0x1_pe_locking_coin_ELOCK_INFO_NOT_FOUND"></a>

No locked coins found to claim.


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_ELOCK_INFO_NOT_FOUND">ELOCK_INFO_NOT_FOUND</a>: u64 = 1;
</code></pre>



<a id="0x1_pe_locking_coin_ENOT_ADMINISDTATOR"></a>

Sender is not administrator


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_ENOT_ADMINISDTATOR">ENOT_ADMINISDTATOR</a>: u64 = 7;
</code></pre>



<a id="0x1_pe_locking_coin_ENOT_STAKER"></a>

Address not in staker list;


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_ENOT_STAKER">ENOT_STAKER</a>: u64 = 8;
</code></pre>



<a id="0x1_pe_locking_coin_ENO_CLAIM_AMONNT"></a>

No free amount to claim.


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_ENO_CLAIM_AMONNT">ENO_CLAIM_AMONNT</a>: u64 = 9;
</code></pre>



<a id="0x1_pe_locking_coin_ETESER_FAILED"></a>

Error code for unit test.


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_ETESER_FAILED">ETESER_FAILED</a>: u64 = 20;
</code></pre>



<a id="0x1_pe_locking_coin_FIRST_UNLOCK_PECENT"></a>

Unlock percent at first locking time;


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_FIRST_UNLOCK_PECENT">FIRST_UNLOCK_PECENT</a>: u64 = 20;
</code></pre>



<a id="0x1_pe_locking_coin_LOCK_EPOCH"></a>

Endless epoch is 2h, the first unlock time is 2 years


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_LOCK_EPOCH">LOCK_EPOCH</a>: u64 = 2;
</code></pre>



<a id="0x1_pe_locking_coin_STABLE_UNLOCK_INERVAL_EPOCHS"></a>

After first unlock, each unlock interval is 90 days


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_INERVAL_EPOCHS">STABLE_UNLOCK_INERVAL_EPOCHS</a>: u64 = 6;
</code></pre>



<a id="0x1_pe_locking_coin_STABLE_UNLOCK_PERIODS"></a>

In lastest 3 years after first unlock, it will unlock 12 times by every 90 days.


<pre><code><b>const</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_PERIODS">STABLE_UNLOCK_PERIODS</a>: u64 = 19;
</code></pre>



<a id="0x1_pe_locking_coin_total_locks"></a>

## Function `total_locks`

Total amount token still in staking.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_total_locks">total_locks</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_total_locks">total_locks</a>(): u64 <b>acquires</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a> {
    <b>borrow_global</b>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a>&gt;(<a href="pe_locking_coin.md#0x1_pe_locking_coin_ADMINISTRATOR_ADDR">ADMINISTRATOR_ADDR</a>).total_locks
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_staking_amount"></a>

## Function `staking_amount`

Total amount token still in staking of recipient.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_staking_amount">staking_amount</a>(recipient: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_staking_amount">staking_amount</a>(recipient: <b>address</b>): u64 <b>acquires</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a>&gt;(<a href="pe_locking_coin.md#0x1_pe_locking_coin_ADMINISTRATOR_ADDR">ADMINISTRATOR_ADDR</a>), <a href="pe_locking_coin.md#0x1_pe_locking_coin_EADMIN_ACCOUNT_NOT_INITIALIZED">EADMIN_ACCOUNT_NOT_INITIALIZED</a>);
    <b>let</b> stakings = <b>borrow_global</b>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a>&gt;(<a href="pe_locking_coin.md#0x1_pe_locking_coin_ADMINISTRATOR_ADDR">ADMINISTRATOR_ADDR</a>);
    <b>assert</b>!(<a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_contains">smart_table::contains</a>(&stakings.stakers, recipient), <a href="pe_locking_coin.md#0x1_pe_locking_coin_ELOCK_INFO_NOT_FOUND">ELOCK_INFO_NOT_FOUND</a>);
    <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(&stakings.stakers, recipient).curr_staking
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_get_unlock_info"></a>

## Function `get_unlock_info`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_get_unlock_info">get_unlock_info</a>(sender: <b>address</b>): <a href="pe_locking_coin.md#0x1_pe_locking_coin_UnlockInfo">pe_locking_coin::UnlockInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_get_unlock_info">get_unlock_info</a>(sender: <b>address</b>): <a href="pe_locking_coin.md#0x1_pe_locking_coin_UnlockInfo">UnlockInfo</a> <b>acquires</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a>&gt;(<a href="pe_locking_coin.md#0x1_pe_locking_coin_ADMINISTRATOR_ADDR">ADMINISTRATOR_ADDR</a>), <a href="pe_locking_coin.md#0x1_pe_locking_coin_EADMIN_ACCOUNT_NOT_INITIALIZED">EADMIN_ACCOUNT_NOT_INITIALIZED</a>);
    <b>let</b> stakings = <b>borrow_global</b>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a>&gt;(<a href="pe_locking_coin.md#0x1_pe_locking_coin_ADMINISTRATOR_ADDR">ADMINISTRATOR_ADDR</a>);
    <b>assert</b>!(<a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_contains">smart_table::contains</a>(&stakings.stakers, sender), <a href="pe_locking_coin.md#0x1_pe_locking_coin_ELOCK_INFO_NOT_FOUND">ELOCK_INFO_NOT_FOUND</a>);
    <b>let</b> info = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(&stakings.stakers, sender);
    <b>let</b> list = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_UnlockAt">UnlockAt</a>&gt;();


    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> list, <a href="pe_locking_coin.md#0x1_pe_locking_coin_UnlockAt">UnlockAt</a> {
        epoch: <a href="pe_locking_coin.md#0x1_pe_locking_coin_LOCK_EPOCH">LOCK_EPOCH</a>,
        amount:<a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_init_unlock">calc_init_unlock</a>(info.init_staking)}
    );

    for (epoch in 0..<a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_PERIODS">STABLE_UNLOCK_PERIODS</a>) {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> list,  <a href="pe_locking_coin.md#0x1_pe_locking_coin_UnlockAt">UnlockAt</a> {
            epoch: <a href="pe_locking_coin.md#0x1_pe_locking_coin_LOCK_EPOCH">LOCK_EPOCH</a> + <a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_INERVAL_EPOCHS">STABLE_UNLOCK_INERVAL_EPOCHS</a> * (epoch + 1),
            amount: <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_stable_unlock">calc_stable_unlock</a>(info.init_staking) }
        );
    };

    <b>let</b> free = info.curr_staking - <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_still_locked_amount">calc_still_locked_amount</a>(info.init_staking, stakings.first_unlock_epoch);

    <a href="pe_locking_coin.md#0x1_pe_locking_coin_UnlockInfo">UnlockInfo</a> {
        unlocked: free,
        unlock_list: list,
    }
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_pe_staking_config"></a>

## Function `pe_staking_config`

Staker address and token amount will hard-code here before genesis.


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_pe_staking_config">pe_staking_config</a>(): <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_SimpleMap">simple_map::SimpleMap</a>&lt;<b>address</b>, u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_pe_staking_config">pe_staking_config</a>(): SimpleMap&lt;<b>address</b>, u64&gt; {
    <b>let</b> <a href="staking_config.md#0x1_staking_config">staking_config</a> = <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_new">simple_map::new</a>&lt;<b>address</b>, u64&gt;();
    <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_add">simple_map::add</a>(&<b>mut</b> <a href="staking_config.md#0x1_staking_config">staking_config</a>, @0x27999c17fbd7b99286320bbf5a0f487d152e416c311debb0e277464598872762, 11_00000000_00000000);
    <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_add">simple_map::add</a>(&<b>mut</b> <a href="staking_config.md#0x1_staking_config">staking_config</a>, @0xa7114c42e8c07809ef640ebbe8adc943b15a7746e6ce6dcb915d1944538363ab, 5_00000000_00000000);
    <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_add">simple_map::add</a>(&<b>mut</b> <a href="staking_config.md#0x1_staking_config">staking_config</a>, @0x715c79b2e7e3efa0b1cd9d4b92e0091eee8be9fae924db8001bca37a5483da49, 3_00000000_00000000);
    <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_add">simple_map::add</a>(&<b>mut</b> <a href="staking_config.md#0x1_staking_config">staking_config</a>, @0xea673f5016fdebd6d08cb9ffbdb95f3935fab1b2251234d286171aaecbd2f3cd, 97000000_00000000);
    <a href="staking_config.md#0x1_staking_config">staking_config</a>
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_start_pe_distribute_coins"></a>

## Function `start_pe_distribute_coins`

Initialize function called at genesis epoch.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_start_pe_distribute_coins">start_pe_distribute_coins</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_start_pe_distribute_coins">start_pe_distribute_coins</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a> {
    <a href="pe_locking_coin.md#0x1_pe_locking_coin_distribut_pe_coins_with_config">distribut_pe_coins_with_config</a>(admin, <a href="pe_locking_coin.md#0x1_pe_locking_coin_pe_staking_config">pe_staking_config</a>());
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_distribut_pe_coins_with_config"></a>

## Function `distribut_pe_coins_with_config`



<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_distribut_pe_coins_with_config">distribut_pe_coins_with_config</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="staking_config.md#0x1_staking_config">staking_config</a>: <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_SimpleMap">simple_map::SimpleMap</a>&lt;<b>address</b>, u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_distribut_pe_coins_with_config">distribut_pe_coins_with_config</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="staking_config.md#0x1_staking_config">staking_config</a>: SimpleMap&lt;<b>address</b>, u64&gt;) <b>acquires</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a> {
    <a href="pe_locking_coin.md#0x1_pe_locking_coin_setup_pool_resource">setup_pool_resource</a>(admin);
    <a href="pe_locking_coin.md#0x1_pe_locking_coin_distribute_coins">distribute_coins</a>(admin, <a href="staking_config.md#0x1_staking_config">staking_config</a>);
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_setup_pool_resource"></a>

## Function `setup_pool_resource`

Initialize StakingPool and move it to 0x1.


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_setup_pool_resource">setup_pool_resource</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_setup_pool_resource">setup_pool_resource</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <b>move_to</b>(admin, <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a> {
        stakers: <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_new">smart_table::new</a>(),
        total_locks: 0,
        first_unlock_epoch: <a href="pe_locking_coin.md#0x1_pe_locking_coin_LOCK_EPOCH">LOCK_EPOCH</a>,
    })
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_distribute_coins"></a>

## Function `distribute_coins`

Create resource account for each staker and mint coin to related resource account.


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_distribute_coins">distribute_coins</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="staking_config.md#0x1_staking_config">staking_config</a>: <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_SimpleMap">simple_map::SimpleMap</a>&lt;<b>address</b>, u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_distribute_coins">distribute_coins</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="staking_config.md#0x1_staking_config">staking_config</a>: SimpleMap&lt;<b>address</b>, u64&gt;) <b>acquires</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a> {
    <b>let</b> addr_list = <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_keys">simple_map::keys</a>(&<a href="staking_config.md#0x1_staking_config">staking_config</a>);

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&addr_list, |pe_addr| {
        <b>let</b> amount = *<a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_borrow">simple_map::borrow</a>(&<a href="staking_config.md#0x1_staking_config">staking_config</a>, pe_addr);
        <b>let</b> (resource_signer, signer_cap) = <a href="account.md#0x1_account_create_resource_account">account::create_resource_account</a>(admin, <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(pe_addr));
        <b>let</b> resource_addr = address_of(&resource_signer);

        // <a href="endless_coin.md#0x1_endless_coin_mint">endless_coin::mint</a>(admin, resource_addr, amount);

        // Store singer capbility, this capbility is required when cliam coins.
        <b>let</b> cap_store = <a href="pe_locking_coin.md#0x1_pe_locking_coin_CapStore">CapStore</a> { signer_cap };
        <b>move_to</b>(&resource_signer, cap_store);

        <b>let</b> pool = <b>borrow_global_mut</b>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a>&gt;(address_of(admin));
        <b>let</b> stacking_info = <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakerInfo">StakerInfo</a> {
            resource_addr,
            init_staking: amount,
            curr_staking: amount,
        };

        // Increase total staking record.
        pool.total_locks = pool.total_locks + amount;

        // Store pe staking infomation in map.
        <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_add">smart_table::add</a>(&<b>mut</b> pool.stakers, *pe_addr, stacking_info);
    });
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_claim"></a>

## Function `claim`

Claim coins when recipient has free amount.


<pre><code><b>public</b> entry <b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_claim">claim</a>(sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_claim">claim</a>(sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a>, <a href="pe_locking_coin.md#0x1_pe_locking_coin_CapStore">CapStore</a> {
    <a href="pe_locking_coin.md#0x1_pe_locking_coin_do_claim">do_claim</a>(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(sender));
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_do_claim"></a>

## Function `do_claim`

Only staker in staking pool allow to call.


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_do_claim">do_claim</a>(recipient: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_do_claim">do_claim</a>(recipient: <b>address</b>) <b>acquires</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a>, <a href="pe_locking_coin.md#0x1_pe_locking_coin_CapStore">CapStore</a> {
    <b>let</b> pool = <b>borrow_global_mut</b>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a>&gt;(<a href="pe_locking_coin.md#0x1_pe_locking_coin_ADMINISTRATOR_ADDR">ADMINISTRATOR_ADDR</a>);
    <b>let</b> stakers = &<b>mut</b> pool.stakers;
    <b>assert</b>!(<a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_contains">smart_table::contains</a>(stakers, recipient), <a href="pe_locking_coin.md#0x1_pe_locking_coin_ENOT_STAKER">ENOT_STAKER</a>);

    <b>let</b> staker = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow_mut">smart_table::borrow_mut</a>(stakers, recipient);
    <b>let</b> locked = <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_still_locked_amount">calc_still_locked_amount</a>(staker.init_staking, pool.first_unlock_epoch);
    <b>assert</b>!((staker.curr_staking - locked) &gt; 0, <a href="pe_locking_coin.md#0x1_pe_locking_coin_ENO_CLAIM_AMONNT">ENO_CLAIM_AMONNT</a>);

    // Transfer unlocked coins <b>to</b> recipient.
    <b>let</b> free_amount = staker.curr_staking - locked;
    <b>let</b> store = <b>borrow_global</b>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_CapStore">CapStore</a>&gt;(staker.resource_addr);
    <b>let</b> singer = <a href="account.md#0x1_account_create_signer_with_capability">account::create_signer_with_capability</a>(&store.signer_cap);
    <a href="endless_coin.md#0x1_endless_coin_transfer">endless_coin::transfer</a>(&singer, recipient, free_amount);

    // Update staking infomation.
    staker.curr_staking = locked;
    pool.total_locks = pool.total_locks - free_amount;

    <a href="event.md#0x1_event_emit">event::emit</a>(<a href="pe_locking_coin.md#0x1_pe_locking_coin_Claim">Claim</a> {
        recipient,
        amount: free_amount,
        claim_epoch: <a href="reconfiguration.md#0x1_reconfiguration_current_epoch">reconfiguration::current_epoch</a>(),
        claimed_time_secs: <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>(),
    });
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_calc_init_unlock"></a>

## Function `calc_init_unlock`



<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_init_unlock">calc_init_unlock</a>(init_locked: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_init_unlock">calc_init_unlock</a>(init_locked: u64): u64 {
    init_locked - <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_stable_unlock">calc_stable_unlock</a>(init_locked) * <a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_PERIODS">STABLE_UNLOCK_PERIODS</a>
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_calc_next_unlock"></a>

## Function `calc_next_unlock`



<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_next_unlock">calc_next_unlock</a>(init_locked: u64, now_epoch: u64, first_unlock_epoch: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_next_unlock">calc_next_unlock</a>(init_locked: u64, now_epoch: u64, first_unlock_epoch: u64): u64 {
    <b>if</b> (now_epoch &lt;= first_unlock_epoch) {
        <b>return</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_init_unlock">calc_init_unlock</a>(init_locked)
    };

    <b>let</b> epoch = (now_epoch - first_unlock_epoch) / <a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_INERVAL_EPOCHS">STABLE_UNLOCK_INERVAL_EPOCHS</a>;
    <b>if</b> (epoch &lt;= <a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_PERIODS">STABLE_UNLOCK_PERIODS</a>) {
        <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_stable_unlock">calc_stable_unlock</a>(init_locked)
    } <b>else</b> {
        0
    }
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_calc_stable_unlock"></a>

## Function `calc_stable_unlock`

Unlock amount each stable unlock epoch.


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_stable_unlock">calc_stable_unlock</a>(init_locked: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_stable_unlock">calc_stable_unlock</a>(init_locked: u64): u64 {
    (init_locked - <a href="../../endless-stdlib/doc/math64.md#0x1_math64_mul_div">math64::mul_div</a>(init_locked, <a href="pe_locking_coin.md#0x1_pe_locking_coin_FIRST_UNLOCK_PECENT">FIRST_UNLOCK_PECENT</a>, 100_u64)) / <a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_PERIODS">STABLE_UNLOCK_PERIODS</a>
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_calc_still_locked_amount"></a>

## Function `calc_still_locked_amount`

Still locked until this time.


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_still_locked_amount">calc_still_locked_amount</a>(init_locked: u64, first_unlock_epoch: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_still_locked_amount">calc_still_locked_amount</a>(init_locked: u64, first_unlock_epoch: u64): u64 {
    <b>let</b> current = <a href="reconfiguration.md#0x1_reconfiguration_current_epoch">reconfiguration::current_epoch</a>();

    // All tokens locked.
    <b>if</b> (current &lt;= first_unlock_epoch) {
        <b>return</b> init_locked
    };

    // After first_unlock_epoch, period will increace 1 each time from 0 <b>to</b> 12
    // when <a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_INERVAL_EPOCHS">STABLE_UNLOCK_INERVAL_EPOCHS</a> expires.
    <b>let</b> period = (current - first_unlock_epoch) / <a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_INERVAL_EPOCHS">STABLE_UNLOCK_INERVAL_EPOCHS</a>;
    <b>if</b> (period &lt; <a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_PERIODS">STABLE_UNLOCK_PERIODS</a>) {
        <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_stable_unlock">calc_stable_unlock</a>(init_locked) * (<a href="pe_locking_coin.md#0x1_pe_locking_coin_STABLE_UNLOCK_PERIODS">STABLE_UNLOCK_PERIODS</a> - period)
    } <b>else</b> {
        0
    }
}
</code></pre>



</details>

<a id="0x1_pe_locking_coin_get_addr_free_amount"></a>

## Function `get_addr_free_amount`



<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_get_addr_free_amount">get_addr_free_amount</a>(user: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_get_addr_free_amount">get_addr_free_amount</a>(user: <b>address</b>): u64 <b>acquires</b> <a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a> {
    <b>let</b> pool = <b>borrow_global</b>&lt;<a href="pe_locking_coin.md#0x1_pe_locking_coin_StakingPool">StakingPool</a>&gt;(<a href="pe_locking_coin.md#0x1_pe_locking_coin_ADMINISTRATOR_ADDR">ADMINISTRATOR_ADDR</a>);

    <b>let</b> staker = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(&pool.stakers, user);
    staker.curr_staking - <a href="pe_locking_coin.md#0x1_pe_locking_coin_calc_still_locked_amount">calc_still_locked_amount</a>(staker.init_staking, pool.first_unlock_epoch)
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

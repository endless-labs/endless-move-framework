
<a id="0x1_locking_coin_ex"></a>

# Module `0x1::locking_coin_ex`



-  [Struct `LockingConfig`](#0x1_locking_coin_ex_LockingConfig)
-  [Struct `StakerInfo`](#0x1_locking_coin_ex_StakerInfo)
-  [Resource `LockingSystem`](#0x1_locking_coin_ex_LockingSystem)
-  [Struct `TokenPool`](#0x1_locking_coin_ex_TokenPool)
-  [Resource `CapStore`](#0x1_locking_coin_ex_CapStore)
-  [Struct `UnlockAt`](#0x1_locking_coin_ex_UnlockAt)
-  [Struct `UnlockInfo`](#0x1_locking_coin_ex_UnlockInfo)
-  [Struct `Claim`](#0x1_locking_coin_ex_Claim)
-  [Constants](#@Constants_0)
-  [Function `total_locks`](#0x1_locking_coin_ex_total_locks)
-  [Function `get_all_stakers`](#0x1_locking_coin_ex_get_all_stakers)
-  [Function `staking_amount`](#0x1_locking_coin_ex_staking_amount)
-  [Function `get_metadata`](#0x1_locking_coin_ex_get_metadata)
-  [Function `get_all_stakers_unlock_info`](#0x1_locking_coin_ex_get_all_stakers_unlock_info)
-  [Function `get_unlock_info`](#0x1_locking_coin_ex_get_unlock_info)
-  [Function `start_distribute_coins`](#0x1_locking_coin_ex_start_distribute_coins)
-  [Function `distribut_coins_with_config`](#0x1_locking_coin_ex_distribut_coins_with_config)
-  [Function `setup_pool_resource`](#0x1_locking_coin_ex_setup_pool_resource)
-  [Function `add_locking_plan_for_address`](#0x1_locking_coin_ex_add_locking_plan_for_address)
-  [Function `distribute_coins`](#0x1_locking_coin_ex_distribute_coins)
-  [Function `add_locking_plan_from_unlocked_balance`](#0x1_locking_coin_ex_add_locking_plan_from_unlocked_balance)
-  [Function `add_locking_plan`](#0x1_locking_coin_ex_add_locking_plan)
-  [Function `claim`](#0x1_locking_coin_ex_claim)
-  [Function `transfer_coin_from_unlocked_coin_to_recipient`](#0x1_locking_coin_ex_transfer_coin_from_unlocked_coin_to_recipient)
-  [Function `do_claim`](#0x1_locking_coin_ex_do_claim)
-  [Function `calc_init_unlock`](#0x1_locking_coin_ex_calc_init_unlock)
-  [Function `calc_next_unlock`](#0x1_locking_coin_ex_calc_next_unlock)
-  [Function `calc_stable_unlock`](#0x1_locking_coin_ex_calc_stable_unlock)
-  [Function `calc_still_locked_amount`](#0x1_locking_coin_ex_calc_still_locked_amount)
-  [Function `locking_config`](#0x1_locking_coin_ex_locking_config)
-  [Function `start_distribut_coins_test`](#0x1_locking_coin_ex_start_distribut_coins_test)
-  [Function `get_addr_free_amount`](#0x1_locking_coin_ex_get_addr_free_amount)


<pre><code><b>use</b> <a href="account.md#0x1_account">0x1::account</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs">0x1::bcs</a>;
<b>use</b> <a href="create_signer.md#0x1_create_signer">0x1::create_signer</a>;
<b>use</b> <a href="endless_coin.md#0x1_endless_coin">0x1::endless_coin</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="event.md#0x1_event">0x1::event</a>;
<b>use</b> <a href="fungible_asset.md#0x1_fungible_asset">0x1::fungible_asset</a>;
<b>use</b> <a href="object.md#0x1_object">0x1::object</a>;
<b>use</b> <a href="primary_fungible_store.md#0x1_primary_fungible_store">0x1::primary_fungible_store</a>;
<b>use</b> <a href="reconfiguration.md#0x1_reconfiguration">0x1::reconfiguration</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table">0x1::smart_table</a>;
<b>use</b> <a href="../../endless-stdlib/doc/table_with_length.md#0x1_table_with_length">0x1::table_with_length</a>;
<b>use</b> <a href="timestamp.md#0x1_timestamp">0x1::timestamp</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">0x1::vector</a>;
</code></pre>



<a id="0x1_locking_coin_ex_LockingConfig"></a>

## Struct `LockingConfig`



<pre><code><b>struct</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><b>address</b>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>total_coins: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>first_unlock_percent: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>first_unlock_epoch: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>stable_unlock_interval: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>stable_unlock_periods: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_locking_coin_ex_StakerInfo"></a>

## Struct `StakerInfo`

When staking, token will move to resource account which create by staker address and init_staking will record
staking amount first time. Current amount of token still in staking record by curr_staking.


<pre><code><b>struct</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_StakerInfo">StakerInfo</a> <b>has</b> <b>copy</b>, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>config: <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a></code>
</dt>
<dd>

</dd>
<dt>
<code>resource_addr: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>curr_balance: u128</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_locking_coin_ex_LockingSystem"></a>

## Resource `LockingSystem`

StakingPool store all staking info of all stakers.


<pre><code><b>struct</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>token_pools: <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_SmartTable">smart_table::SmartTable</a>&lt;<b>address</b>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_TokenPool">locking_coin_ex::TokenPool</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_locking_coin_ex_TokenPool"></a>

## Struct `TokenPool`



<pre><code><b>struct</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_TokenPool">TokenPool</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>stakers: <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_SmartTable">smart_table::SmartTable</a>&lt;<b>address</b>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_StakerInfo">locking_coin_ex::StakerInfo</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>total_locks: u128</code>
</dt>
<dd>
 Total amount of token in staking.
</dd>
</dl>


</details>

<a id="0x1_locking_coin_ex_CapStore"></a>

## Resource `CapStore`

Signer capability of resource address wrapped by CapStore will move to 0x1.


<pre><code><b>struct</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> <b>has</b> key
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

<a id="0x1_locking_coin_ex_UnlockAt"></a>

## Struct `UnlockAt`

Unlock amount and when to unlock.


<pre><code><b>struct</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockAt">UnlockAt</a> <b>has</b> drop
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
<code>amount: u128</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_locking_coin_ex_UnlockInfo"></a>

## Struct `UnlockInfo`

Unlocked token amount when and how much to unlock.


<pre><code><b>struct</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockInfo">UnlockInfo</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><b>address</b>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>unlocked: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>unlock_list: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockAt">locking_coin_ex::UnlockAt</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_locking_coin_ex_Claim"></a>

## Struct `Claim`

Event emitted when a recipient claims unlocked coins.


<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_Claim">Claim</a> <b>has</b> drop, store
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
<code>amount: u128</code>
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


<a id="0x1_locking_coin_ex_EINSUFFICIENT_BALANCE"></a>

admin has insufficient balance to disritute;


<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_EINSUFFICIENT_BALANCE">EINSUFFICIENT_BALANCE</a>: u64 = 6;
</code></pre>



<a id="0x1_locking_coin_ex_ADMINISTRATOR"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_ADMINISTRATOR">ADMINISTRATOR</a>: <b>address</b> = 0x1;
</code></pre>



<a id="0x1_locking_coin_ex_AIRDROP"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_AIRDROP">AIRDROP</a>: <b>address</b> = 0xbedaa6897c6dd3f016f112ce61340d1fe3271bd737607563ebc609fd6ebc879f;
</code></pre>



<a id="0x1_locking_coin_ex_COMMUNITY"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_COMMUNITY">COMMUNITY</a>: <b>address</b> = 0x8aaee7a286b042351410c8582deeaeafad1cf6d435a63eafb6ac313c9ad35322;
</code></pre>



<a id="0x1_locking_coin_ex_CONTRACT_NAME"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_CONTRACT_NAME">CONTRACT_NAME</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [108, 111, 99, 107, 105, 110, 103, 95, 99, 111, 105, 110, 95, 101, 120];
</code></pre>



<a id="0x1_locking_coin_ex_EACTIVE_LOCKS_EXIST"></a>

Cannot update the withdrawal address because there are still active/unclaimed locks.


<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_EACTIVE_LOCKS_EXIST">EACTIVE_LOCKS_EXIST</a>: u64 = 5;
</code></pre>



<a id="0x1_locking_coin_ex_EADMIN_ACCOUNT_NOT_INITIALIZED"></a>

Sponsor account has not been set up to create locks for the specified CoinType yet.


<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_EADMIN_ACCOUNT_NOT_INITIALIZED">EADMIN_ACCOUNT_NOT_INITIALIZED</a>: u64 = 4;
</code></pre>



<a id="0x1_locking_coin_ex_ECOLOGY"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_ECOLOGY">ECOLOGY</a>: <b>address</b> = 0xf19085487f9762fc34a270ec896991b661f3fdbe04ee566dffd963b6f7f7e0ba;
</code></pre>



<a id="0x1_locking_coin_ex_EINVALID_DATA"></a>

invalide data;


<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_EINVALID_DATA">EINVALID_DATA</a>: u64 = 10;
</code></pre>



<a id="0x1_locking_coin_ex_ELOCKUP_HAS_NOT_EXPIRED"></a>

Lockup has not expired yet.


<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_ELOCKUP_HAS_NOT_EXPIRED">ELOCKUP_HAS_NOT_EXPIRED</a>: u64 = 2;
</code></pre>



<a id="0x1_locking_coin_ex_ELOCK_ALREADY_EXISTS"></a>

Can only create one active lock per recipient at once.


<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_ELOCK_ALREADY_EXISTS">ELOCK_ALREADY_EXISTS</a>: u64 = 3;
</code></pre>



<a id="0x1_locking_coin_ex_ELOCK_INFO_NOT_FOUND"></a>

No locked coins found to claim.


<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_ELOCK_INFO_NOT_FOUND">ELOCK_INFO_NOT_FOUND</a>: u64 = 1;
</code></pre>



<a id="0x1_locking_coin_ex_ENOT_ADMINISDTATOR"></a>

Sender is not administrator


<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_ENOT_ADMINISDTATOR">ENOT_ADMINISDTATOR</a>: u64 = 7;
</code></pre>



<a id="0x1_locking_coin_ex_ENOT_STAKER"></a>

Address not in staker list;


<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_ENOT_STAKER">ENOT_STAKER</a>: u64 = 8;
</code></pre>



<a id="0x1_locking_coin_ex_ENO_CLAIM_AMONNT"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_ENO_CLAIM_AMONNT">ENO_CLAIM_AMONNT</a>: u64 = 9;
</code></pre>



<a id="0x1_locking_coin_ex_ETESER_FAILED"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_ETESER_FAILED">ETESER_FAILED</a>: u64 = 20;
</code></pre>



<a id="0x1_locking_coin_ex_FOUNDATION"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_FOUNDATION">FOUNDATION</a>: <b>address</b> = 0xf54658fcbd814921a0de824d8ce592731870c4b1af7c76bbd1462303c51fab26;
</code></pre>



<a id="0x1_locking_coin_ex_MARKET_PARTNERS"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_MARKET_PARTNERS">MARKET_PARTNERS</a>: <b>address</b> = 0x9e50caf6d9702f72e3dbd67c6f7336656ddd63b8ea594fafdb05c7b1388ebd81;
</code></pre>



<a id="0x1_locking_coin_ex_PE0"></a>

Addresses list


<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_PE0">PE0</a>: <b>address</b> = 0x27999c17fbd7b99286320bbf5a0f487d152e416c311debb0e277464598872762;
</code></pre>



<a id="0x1_locking_coin_ex_PE1"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_PE1">PE1</a>: <b>address</b> = 0xa7114c42e8c07809ef640ebbe8adc943b15a7746e6ce6dcb915d1944538363ab;
</code></pre>



<a id="0x1_locking_coin_ex_PE2"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_PE2">PE2</a>: <b>address</b> = 0x715c79b2e7e3efa0b1cd9d4b92e0091eee8be9fae924db8001bca37a5483da49;
</code></pre>



<a id="0x1_locking_coin_ex_PE3"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_PE3">PE3</a>: <b>address</b> = 0xea673f5016fdebd6d08cb9ffbdb95f3935fab1b2251234d286171aaecbd2f3cd;
</code></pre>



<a id="0x1_locking_coin_ex_SKAKINGS"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_SKAKINGS">SKAKINGS</a>: <b>address</b> = 0xc639dfe79882793f6ec6a4c91cc06de440386a062a58a14cf70d26b75e2bb349;
</code></pre>



<a id="0x1_locking_coin_ex_TEAM"></a>



<pre><code><b>const</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_TEAM">TEAM</a>: <b>address</b> = 0xc589165f31f7805965950a5af30b53455c147a98facdb42c4f8fd4e4c2733ca3;
</code></pre>



<a id="0x1_locking_coin_ex_total_locks"></a>

## Function `total_locks`

Total amount token still locked.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_total_locks">total_locks</a>(token_address: <b>address</b>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_total_locks">total_locks</a>(token_address: <b>address</b>): u128 <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a> {
    <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(&<b>borrow_global</b>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>&gt;(<a href="locking_coin_ex.md#0x1_locking_coin_ex_ADMINISTRATOR">ADMINISTRATOR</a>).token_pools, token_address).total_locks
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_get_all_stakers"></a>

## Function `get_all_stakers`

Total amount token still locked.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_all_stakers">get_all_stakers</a>(token_address: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_all_stakers">get_all_stakers</a>(token_address: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt; <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a> {
    <b>let</b> token_pools = &<b>borrow_global</b>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>&gt;(<a href="locking_coin_ex.md#0x1_locking_coin_ex_ADMINISTRATOR">ADMINISTRATOR</a>).token_pools;
    <b>let</b> stakers_ref = &<a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(token_pools, token_address).stakers;
    <b>let</b> all = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>&lt;<b>address</b>&gt;();
    <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_for_each_ref">smart_table::for_each_ref</a>(stakers_ref, |a, v| {
        <b>let</b> a = *a;
        <b>let</b> _ = v;
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> all, a);
    });

    all
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_staking_amount"></a>

## Function `staking_amount`

Total amount token still locked of recipient.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_staking_amount">staking_amount</a>(token_address: <b>address</b>, recipient: <b>address</b>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_staking_amount">staking_amount</a>(token_address: <b>address</b>, recipient: <b>address</b>): u128 <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>&gt;(<a href="locking_coin_ex.md#0x1_locking_coin_ex_ADMINISTRATOR">ADMINISTRATOR</a>), <a href="locking_coin_ex.md#0x1_locking_coin_ex_EADMIN_ACCOUNT_NOT_INITIALIZED">EADMIN_ACCOUNT_NOT_INITIALIZED</a>);
    <b>let</b> stakings = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(&<b>borrow_global</b>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>&gt;(<a href="locking_coin_ex.md#0x1_locking_coin_ex_ADMINISTRATOR">ADMINISTRATOR</a>).token_pools, token_address);
    <b>assert</b>!(<a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_contains">smart_table::contains</a>(&stakings.stakers, recipient), <a href="locking_coin_ex.md#0x1_locking_coin_ex_ELOCK_INFO_NOT_FOUND">ELOCK_INFO_NOT_FOUND</a>);
    <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(&stakings.stakers, recipient).curr_balance
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_get_metadata"></a>

## Function `get_metadata`

Return the address of the metadata that's created when this module is deployed.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_metadata">get_metadata</a>(token_address: <b>address</b>): <a href="object.md#0x1_object_Object">object::Object</a>&lt;<a href="fungible_asset.md#0x1_fungible_asset_Metadata">fungible_asset::Metadata</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_metadata">get_metadata</a>(token_address: <b>address</b>): Object&lt;Metadata&gt; {
    <a href="object.md#0x1_object_address_to_object">object::address_to_object</a>&lt;Metadata&gt;(token_address)
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_get_all_stakers_unlock_info"></a>

## Function `get_all_stakers_unlock_info`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_all_stakers_unlock_info">get_all_stakers_unlock_info</a>(token_address: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockInfo">locking_coin_ex::UnlockInfo</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_all_stakers_unlock_info">get_all_stakers_unlock_info</a>(token_address: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockInfo">UnlockInfo</a>&gt; <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a> {
    <b>let</b> all_stakers = <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_all_stakers">get_all_stakers</a>(token_address);
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_map">vector::map</a>(all_stakers, |staker| {
        <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_unlock_info">get_unlock_info</a>(token_address, staker)
    })
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_get_unlock_info"></a>

## Function `get_unlock_info`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_unlock_info">get_unlock_info</a>(token_address: <b>address</b>, sender: <b>address</b>): <a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockInfo">locking_coin_ex::UnlockInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_unlock_info">get_unlock_info</a>(token_address: <b>address</b>, sender: <b>address</b>): <a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockInfo">UnlockInfo</a> <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>&gt;(<a href="locking_coin_ex.md#0x1_locking_coin_ex_ADMINISTRATOR">ADMINISTRATOR</a>), <a href="locking_coin_ex.md#0x1_locking_coin_ex_EADMIN_ACCOUNT_NOT_INITIALIZED">EADMIN_ACCOUNT_NOT_INITIALIZED</a>);
    <b>let</b> token_pool = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(&<b>borrow_global</b>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>&gt;(<a href="locking_coin_ex.md#0x1_locking_coin_ex_ADMINISTRATOR">ADMINISTRATOR</a>).token_pools, token_address);
    <b>assert</b>!(<a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_contains">smart_table::contains</a>(&token_pool.stakers, sender), <a href="locking_coin_ex.md#0x1_locking_coin_ex_ELOCK_INFO_NOT_FOUND">ELOCK_INFO_NOT_FOUND</a>);
    <b>let</b> staker = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(&token_pool.stakers, sender);
    <b>let</b> c = &staker.config;
    <b>let</b> list = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockAt">UnlockAt</a>&gt;();


    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> list, <a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockAt">UnlockAt</a> {
        epoch: c.first_unlock_epoch,
        amount: <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_init_unlock">calc_init_unlock</a>(c)
    }
    );

    for (period in 0..c.stable_unlock_periods) {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> list, <a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockAt">UnlockAt</a> {
            epoch: c.first_unlock_epoch + c.stable_unlock_interval * (period + 1),
            amount: <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_stable_unlock">calc_stable_unlock</a>(c)
        }
        );
    };

    <b>let</b> free = staker.curr_balance - <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_still_locked_amount">calc_still_locked_amount</a>(c);

    <a href="locking_coin_ex.md#0x1_locking_coin_ex_UnlockInfo">UnlockInfo</a> {
        <b>address</b>: sender,
        unlocked: free,
        unlock_list: list,
    }
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_start_distribute_coins"></a>

## Function `start_distribute_coins`

Initialize function called at genesis epoch.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_start_distribute_coins">start_distribute_coins</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, configs: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_start_distribute_coins">start_distribute_coins</a>(
    admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    configs: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a>&gt;
) <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> {
    <a href="locking_coin_ex.md#0x1_locking_coin_ex_distribut_coins_with_config">distribut_coins_with_config</a>(admin, configs);
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_distribut_coins_with_config"></a>

## Function `distribut_coins_with_config`



<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_distribut_coins_with_config">distribut_coins_with_config</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="staking_config.md#0x1_staking_config">staking_config</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_distribut_coins_with_config">distribut_coins_with_config</a>(
    admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    <a href="staking_config.md#0x1_staking_config">staking_config</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a>&gt;
) <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> {
    <a href="locking_coin_ex.md#0x1_locking_coin_ex_setup_pool_resource">setup_pool_resource</a>(admin);
    <a href="locking_coin_ex.md#0x1_locking_coin_ex_distribute_coins">distribute_coins</a>(<a href="staking_config.md#0x1_staking_config">staking_config</a>);
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_setup_pool_resource"></a>

## Function `setup_pool_resource`

Initialize StakingPool and move it to 0x1.


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_setup_pool_resource">setup_pool_resource</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_setup_pool_resource">setup_pool_resource</a>(admin: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <b>move_to</b>(admin, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a> {
        token_pools: <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_new">smart_table::new</a>(),
    })
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_add_locking_plan_for_address"></a>

## Function `add_locking_plan_for_address`

If from_unlocked is true and it will transfer coin from sponser unlocked amount to repicient staking resource address,
else transfer from sponser account balance.


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_add_locking_plan_for_address">add_locking_plan_for_address</a>(sponser: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, token_address: <b>address</b>, c: <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a>, from_unlocked: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_add_locking_plan_for_address">add_locking_plan_for_address</a>(
    sponser: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    token_address: <b>address</b>,
    c: <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a>,
    from_unlocked: bool
) <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> {

    <b>assert</b>!(c.total_coins &gt; 0, <a href="locking_coin_ex.md#0x1_locking_coin_ex_EINVALID_DATA">EINVALID_DATA</a>);
    <b>assert</b>!(c.first_unlock_percent &lt;= 100, <a href="locking_coin_ex.md#0x1_locking_coin_ex_EINVALID_DATA">EINVALID_DATA</a>);
    <b>assert</b>!(c.first_unlock_percent &lt;= 100, <a href="locking_coin_ex.md#0x1_locking_coin_ex_EINVALID_DATA">EINVALID_DATA</a>);

    <b>let</b> seed = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(&c.<b>address</b>);
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_append">vector::append</a>(&<b>mut</b> seed, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CONTRACT_NAME">CONTRACT_NAME</a>);
    <b>let</b> (resource_signer, signer_cap) = <a href="account.md#0x1_account_create_resource_account">account::create_resource_account</a>(sponser, seed);
    <b>let</b> resource_addr = address_of(&resource_signer);


    // Store singer capbility, this capbility is required when cliam coins.
    <b>let</b> cap_store = <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> { signer_cap };
    <b>move_to</b>(&resource_signer, cap_store);

    <b>let</b> stacking_info = <a href="locking_coin_ex.md#0x1_locking_coin_ex_StakerInfo">StakerInfo</a> {
        config: c,
        resource_addr,
        curr_balance: c.total_coins,
    };

    <b>if</b> (from_unlocked) {
        // Transfer coin from sponser unlocked amount <b>to</b> repicient staking resource <b>address</b>.
        <a href="locking_coin_ex.md#0x1_locking_coin_ex_transfer_coin_from_unlocked_coin_to_recipient">transfer_coin_from_unlocked_coin_to_recipient</a>(sponser, token_address, resource_addr, c.total_coins);
    } <b>else</b> {
        // Transfer coin from sponser <b>address</b> <b>to</b> resource <a href="account.md#0x1_account">account</a>
        <a href="primary_fungible_store.md#0x1_primary_fungible_store_transfer">primary_fungible_store::transfer</a>(sponser, <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_metadata">get_metadata</a>(token_address), resource_addr, c.total_coins);
    };

    <b>let</b> token_pools = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>&gt;(<a href="locking_coin_ex.md#0x1_locking_coin_ex_ADMINISTRATOR">ADMINISTRATOR</a>).token_pools;

    // If no token pool for token_address, it means token is a new one, it will create token_pool and add <b>to</b> token_pools <a href="../../endless-stdlib/doc/table.md#0x1_table">table</a>.
    <b>if</b>(!<a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_contains">smart_table::contains</a>(token_pools, token_address)) {
        <b>let</b> pool = <a href="locking_coin_ex.md#0x1_locking_coin_ex_TokenPool">TokenPool</a> {
            stakers: <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_new">smart_table::new</a>(),
            total_locks: 0,
        };
        <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_add">smart_table::add</a>(token_pools, token_address, pool);
    };

    <b>let</b> pool = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow_mut">smart_table::borrow_mut</a>(token_pools, token_address);
    // Increase total staking record.
    pool.total_locks = pool.total_locks + c.total_coins;
    <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_add">smart_table::add</a>(&<b>mut</b> pool.stakers, c.<b>address</b>, stacking_info);
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_distribute_coins"></a>

## Function `distribute_coins`

Create resource account for each staker and mint coin to related resource account.


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_distribute_coins">distribute_coins</a>(staking_configs: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_distribute_coins">distribute_coins</a>(staking_configs: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a>&gt;) <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> {
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&staking_configs, |c| {
        <b>let</b> c: &<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> = c;
        // Transfer coin <b>to</b> resource <a href="account.md#0x1_account">account</a>
        <b>let</b> addr_signer = <a href="create_signer.md#0x1_create_signer_create_signer">create_signer::create_signer</a>(c.<b>address</b>);
        <a href="locking_coin_ex.md#0x1_locking_coin_ex_add_locking_plan_for_address">add_locking_plan_for_address</a>(&addr_signer, get_eds_token_address(), *c, <b>false</b>);
    });
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_add_locking_plan_from_unlocked_balance"></a>

## Function `add_locking_plan_from_unlocked_balance`

Send locking coin to another address from free amount and unlock by plan


<pre><code><b>public</b> entry <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_add_locking_plan_from_unlocked_balance">add_locking_plan_from_unlocked_balance</a>(sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, token_address: <b>address</b>, reciever: <b>address</b>, total_coins: u128, first_unlock_percent: u64, first_unlock_epoch: u64, stable_unlock_interval: u64, stable_unlock_periods: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_add_locking_plan_from_unlocked_balance">add_locking_plan_from_unlocked_balance</a>(
    sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    token_address: <b>address</b>,
    reciever: <b>address</b>,
    total_coins: u128,
    first_unlock_percent: u64,
    first_unlock_epoch: u64,
    stable_unlock_interval: u64,
    stable_unlock_periods: u64,
) <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> {
    <b>let</b> c = <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: reciever,
        total_coins,
        first_unlock_percent,
        first_unlock_epoch,
        stable_unlock_interval,
        stable_unlock_periods
    };

    <a href="locking_coin_ex.md#0x1_locking_coin_ex_add_locking_plan_for_address">add_locking_plan_for_address</a>(sender, token_address, c, <b>true</b>);
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_add_locking_plan"></a>

## Function `add_locking_plan`



<pre><code><b>public</b> entry <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_add_locking_plan">add_locking_plan</a>(sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, token_address: <b>address</b>, reciever: <b>address</b>, total_coins: u128, first_unlock_percent: u64, first_unlock_epoch: u64, stable_unlock_interval: u64, stable_unlock_periods: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_add_locking_plan">add_locking_plan</a>(
    sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    token_address: <b>address</b>,
    reciever: <b>address</b>,
    total_coins: u128,
    first_unlock_percent: u64,
    first_unlock_epoch: u64,
    stable_unlock_interval: u64,
    stable_unlock_periods: u64,
) <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> {
    <b>let</b> c = <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: reciever,
        total_coins,
        first_unlock_percent,
        first_unlock_epoch,
        stable_unlock_interval,
        stable_unlock_periods
    };

    <a href="locking_coin_ex.md#0x1_locking_coin_ex_add_locking_plan_for_address">add_locking_plan_for_address</a>(sender, token_address, c, <b>false</b>);
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_claim"></a>

## Function `claim`

Claim coins when recipient has free amount.


<pre><code><b>public</b> entry <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_claim">claim</a>(sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, token_address: <b>address</b>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_claim">claim</a>(sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, token_address: <b>address</b>, amount: u128) <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> {
    <a href="locking_coin_ex.md#0x1_locking_coin_ex_do_claim">do_claim</a>(token_address, sender, amount);
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_transfer_coin_from_unlocked_coin_to_recipient"></a>

## Function `transfer_coin_from_unlocked_coin_to_recipient`

// Transfer free amount to recipient account;


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_transfer_coin_from_unlocked_coin_to_recipient">transfer_coin_from_unlocked_coin_to_recipient</a>(sponser: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, token_address: <b>address</b>, recipient: <b>address</b>, amount: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_transfer_coin_from_unlocked_coin_to_recipient">transfer_coin_from_unlocked_coin_to_recipient</a>(
    sponser: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    token_address: <b>address</b>,
    recipient: <b>address</b>,
    amount: u128
): u128 <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> {
    <b>let</b> pool = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow_mut">smart_table::borrow_mut</a>(&<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>&gt;(<a href="locking_coin_ex.md#0x1_locking_coin_ex_ADMINISTRATOR">ADMINISTRATOR</a>).token_pools, token_address);
    <b>let</b> stakers = &<b>mut</b> pool.stakers;
    <b>assert</b>!(<a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_contains">smart_table::contains</a>(stakers, address_of(sponser)), <a href="locking_coin_ex.md#0x1_locking_coin_ex_ENOT_STAKER">ENOT_STAKER</a>);

    <b>let</b> staker = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow_mut">smart_table::borrow_mut</a>(stakers, address_of(sponser));
    <b>let</b> locked = <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_still_locked_amount">calc_still_locked_amount</a>(&staker.config);
    <b>if</b> (staker.curr_balance &lt;= locked) {
        <b>return</b> 0
    };

    // Transfer unlocked coins <b>to</b> recipient.
    <b>let</b> free_amount = staker.curr_balance - locked;
    <b>assert</b>!(free_amount &gt;= amount, <a href="locking_coin_ex.md#0x1_locking_coin_ex_EINSUFFICIENT_BALANCE">EINSUFFICIENT_BALANCE</a>);
    <b>let</b> store = <b>borrow_global</b>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a>&gt;(staker.resource_addr);
    <b>let</b> singer = <a href="account.md#0x1_account_create_signer_with_capability">account::create_signer_with_capability</a>(&store.signer_cap);

    <a href="primary_fungible_store.md#0x1_primary_fungible_store_transfer">primary_fungible_store::transfer</a>(&singer, <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_metadata">get_metadata</a>(token_address), recipient, amount);

    // Update staking infomation.
    staker.curr_balance = staker.curr_balance - amount;
    pool.total_locks = pool.total_locks - amount;

    amount
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_do_claim"></a>

## Function `do_claim`

Only user in locking pool allow to call.


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_do_claim">do_claim</a>(token_address: <b>address</b>, sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, amount: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_do_claim">do_claim</a>(token_address: <b>address</b>, sender: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, amount: u128): u128 <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> {
    // transfer coin from recipient free amount <b>to</b> recipient <a href="account.md#0x1_account">account</a>;
    <a href="locking_coin_ex.md#0x1_locking_coin_ex_transfer_coin_from_unlocked_coin_to_recipient">transfer_coin_from_unlocked_coin_to_recipient</a>(sender, token_address, address_of(sender), amount);
    <a href="event.md#0x1_event_emit">event::emit</a>(<a href="locking_coin_ex.md#0x1_locking_coin_ex_Claim">Claim</a> {
        recipient: address_of(sender),
        amount,
        claim_epoch: <a href="reconfiguration.md#0x1_reconfiguration_current_epoch">reconfiguration::current_epoch</a>(),
        claimed_time_secs: <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>(),
    });

    amount
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_calc_init_unlock"></a>

## Function `calc_init_unlock`



<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_init_unlock">calc_init_unlock</a>(c: &<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_init_unlock">calc_init_unlock</a>(c: &<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a>): u128 {
    c.total_coins - <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_stable_unlock">calc_stable_unlock</a>(c) * (c.stable_unlock_periods <b>as</b> u128)
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_calc_next_unlock"></a>

## Function `calc_next_unlock`



<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_next_unlock">calc_next_unlock</a>(c: &<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a>, now_epoch: u64): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_next_unlock">calc_next_unlock</a>(c: &<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a>, now_epoch: u64): u128 {
    <b>if</b> (now_epoch &lt;= c.first_unlock_epoch) {
        <b>return</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_init_unlock">calc_init_unlock</a>(c)
    };


    <b>let</b> period = (now_epoch - c.first_unlock_epoch) / c.stable_unlock_interval;
    <b>if</b> (period &lt;= c.stable_unlock_periods) {
        <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_stable_unlock">calc_stable_unlock</a>(c)
    } <b>else</b> {
        0
    }
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_calc_stable_unlock"></a>

## Function `calc_stable_unlock`

Unlock amount each stable unlock epoch.


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_stable_unlock">calc_stable_unlock</a>(config: &<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_stable_unlock">calc_stable_unlock</a>(config: &<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a>): u128 {
    <b>if</b> (config.stable_unlock_interval == 0 || config.stable_unlock_interval == 0) {
        0
    } <b>else</b> {
        (config.total_coins - <a href="../../endless-stdlib/doc/math128.md#0x1_math128_mul_div">math128::mul_div</a>(config.total_coins, (config.first_unlock_percent <b>as</b> u128), 100_u128))
            / (config.stable_unlock_periods <b>as</b> u128)
    }
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_calc_still_locked_amount"></a>

## Function `calc_still_locked_amount`



<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_still_locked_amount">calc_still_locked_amount</a>(config: &<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_still_locked_amount">calc_still_locked_amount</a>(config: &<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a>): u128 {
    <b>let</b> current = <a href="reconfiguration.md#0x1_reconfiguration_current_epoch">reconfiguration::current_epoch</a>();
    <b>if</b> (current &lt;= config.first_unlock_epoch) {
        <b>return</b> config.total_coins
    };


    <b>if</b> (config.stable_unlock_interval == 0 || config.stable_unlock_interval == 0) {
        <b>if</b> (current &lt; config.first_unlock_epoch) {
            config.total_coins
        } <b>else</b> {
            0
        }
    } <b>else</b> {
        // After first_unlock_epoch, period will increace 1 each time from 0 <b>to</b> 12
        // when STABLE_UNLOCK_INERVAL_EPOCHS expires.
        <b>let</b> period = (current - config.first_unlock_epoch) / config.stable_unlock_interval;
        <b>if</b> (period &lt; config.stable_unlock_periods) {
            <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_stable_unlock">calc_stable_unlock</a>(config) * ((config.stable_unlock_periods - period) <b>as</b> u128)
        } <b>else</b> {
            0
        }
    }
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_locking_config"></a>

## Function `locking_config`



<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_locking_config">locking_config</a>(): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_locking_config">locking_config</a>(): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a>&gt; {
    <b>let</b> locking_config = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a>&gt;();
    //
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_PE0">PE0</a>,
        total_coins: 11_00000000_00000000,
        first_unlock_percent: 100,
        first_unlock_epoch: 5,
        stable_unlock_interval: 2,
        stable_unlock_periods: 2
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_PE1">PE1</a>,
        total_coins: 5_00000000_00000000,
        first_unlock_percent: 10,
        first_unlock_epoch: 5,
        stable_unlock_interval: 17,
        stable_unlock_periods: 3
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_PE2">PE2</a>,
        total_coins: 3_00000000_00000000,
        first_unlock_percent: 0,
        first_unlock_epoch: 6,
        stable_unlock_interval: 17,
        stable_unlock_periods: 3
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_PE3">PE3</a>,
        total_coins: 97000000_00000000,
        first_unlock_percent: 0,
        first_unlock_epoch: 8,
        stable_unlock_interval: 17,
        stable_unlock_periods: 3
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_TEAM">TEAM</a>,
        total_coins: 15_03000000_00000000,
        first_unlock_percent: 10,
        first_unlock_epoch: 5,
        stable_unlock_interval: 17,
        stable_unlock_periods: 3
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_FOUNDATION">FOUNDATION</a>,
        total_coins: 20_00000000_00000000,
        first_unlock_percent: 10,
        first_unlock_epoch: 5,
        stable_unlock_interval: 7,
        stable_unlock_periods: 11
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_MARKET_PARTNERS">MARKET_PARTNERS</a>,
        total_coins: 8_90000000_00000000,
        first_unlock_percent: 20,
        first_unlock_epoch: 5,
        stable_unlock_interval: 2,
        stable_unlock_periods: 39
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_AIRDROP">AIRDROP</a>,
        total_coins: 3_10000000_00000000,
        first_unlock_percent: 20,
        first_unlock_epoch: 5,
        stable_unlock_interval: 6,
        stable_unlock_periods: 5
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_ECOLOGY">ECOLOGY</a>,
        total_coins: 18_30000000_00000000,
        first_unlock_percent: 20,
        first_unlock_epoch: 5,
        stable_unlock_interval: 10,
        stable_unlock_periods: 7
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_COMMUNITY">COMMUNITY</a>,
        total_coins: 3_05000000_00000000,
        first_unlock_percent: 20,
        first_unlock_epoch: 5,
        stable_unlock_interval: 6,
        stable_unlock_periods: 9
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> locking_config, <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> {
        <b>address</b>: <a href="locking_coin_ex.md#0x1_locking_coin_ex_SKAKINGS">SKAKINGS</a>,
        total_coins: 10_15000000_00000000,
        first_unlock_percent: 100,
        first_unlock_epoch: 5,
        stable_unlock_interval: 2,
        stable_unlock_periods: 2
    });

    locking_config
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_start_distribut_coins_test"></a>

## Function `start_distribut_coins_test`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_start_distribut_coins_test">start_distribut_coins_test</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_start_distribut_coins_test">start_distribut_coins_test</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>, <a href="locking_coin_ex.md#0x1_locking_coin_ex_CapStore">CapStore</a> {

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&<a href="locking_coin_ex.md#0x1_locking_coin_ex_locking_config">locking_config</a>(), |c| {
        <b>let</b> c: &<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">LockingConfig</a> = c;
        <a href="endless_coin.md#0x1_endless_coin_mint">endless_coin::mint</a>(endless_framework, c.<b>address</b>, c.total_coins);
    });

    <a href="locking_coin_ex.md#0x1_locking_coin_ex_distribut_coins_with_config">distribut_coins_with_config</a>(endless_framework, <a href="locking_coin_ex.md#0x1_locking_coin_ex_locking_config">locking_config</a>());
}
</code></pre>



</details>

<a id="0x1_locking_coin_ex_get_addr_free_amount"></a>

## Function `get_addr_free_amount`



<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_addr_free_amount">get_addr_free_amount</a>(user: <b>address</b>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_get_addr_free_amount">get_addr_free_amount</a>(user: <b>address</b>): u128 <b>acquires</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a> {
    <b>let</b> pool = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(&<b>borrow_global</b>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingSystem">LockingSystem</a>&gt;(<a href="locking_coin_ex.md#0x1_locking_coin_ex_ADMINISTRATOR">ADMINISTRATOR</a>).token_pools, get_eds_token_address());

    <b>let</b> staker = <a href="../../endless-stdlib/doc/smart_table.md#0x1_smart_table_borrow">smart_table::borrow</a>(&pool.stakers, user);
    staker.curr_balance - <a href="locking_coin_ex.md#0x1_locking_coin_ex_calc_still_locked_amount">calc_still_locked_amount</a>(&staker.config)
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

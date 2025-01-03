
<a id="0x1_stake"></a>

# Module `0x1::stake`


Validator lifecycle:
1. Prepare a validator node set up and call stake::initialize_validator
2. Once ready to deposit stake (or have funds assigned by a staking service in exchange for ownership capability),
call stake::add_stake (or *_with_cap versions if called from the staking service)
3. Call stake::join_validator_set (or _with_cap version) to join the active validator set. Changes are effective in
the next epoch.
4. Validate and gain rewards. The stake will automatically be locked up for a fixed duration (set by governance) and
automatically renewed at expiration.
5. At any point, if the validator operator wants to update the consensus key or network/fullnode addresses, they can
call stake::rotate_consensus_key and stake::update_network_and_fullnode_addresses. Similar to changes to stake, the
changes to consensus key/network/fullnode addresses are only effective in the next epoch.
6. Validator can request to unlock their stake at any time. However, their stake will only become withdrawable when
their current lockup expires. This can be at most as long as the fixed lockup duration.
7. After exiting, the validator can either explicitly leave the validator set by calling stake::leave_validator_set
or if their stake drops below the min required, they would get removed at the end of the epoch.
8. Validator can always rejoin the validator set by going through steps 2-3 again.
9. An owner can always switch operators by calling stake::set_operator.
10. An owner can always switch designated voter by calling stake::set_designated_voter.


-  [Resource `OwnerCapability`](#0x1_stake_OwnerCapability)
-  [Resource `StakePool`](#0x1_stake_StakePool)
-  [Resource `ValidatorConfig`](#0x1_stake_ValidatorConfig)
-  [Struct `ValidatorInfo`](#0x1_stake_ValidatorInfo)
-  [Resource `ValidatorSet`](#0x1_stake_ValidatorSet)
-  [Resource `EndlessCoinCapabilities`](#0x1_stake_EndlessCoinCapabilities)
-  [Struct `IndividualValidatorPerformance`](#0x1_stake_IndividualValidatorPerformance)
-  [Resource `ValidatorPerformance`](#0x1_stake_ValidatorPerformance)
-  [Struct `AccountShare`](#0x1_stake_AccountShare)
-  [Resource `BlockRewardShareInfo`](#0x1_stake_BlockRewardShareInfo)
-  [Struct `RegisterValidatorCandidateEvent`](#0x1_stake_RegisterValidatorCandidateEvent)
-  [Struct `SetOperatorEvent`](#0x1_stake_SetOperatorEvent)
-  [Struct `AddStakeEvent`](#0x1_stake_AddStakeEvent)
-  [Struct `ReactivateStakeEvent`](#0x1_stake_ReactivateStakeEvent)
-  [Struct `RotateConsensusKeyEvent`](#0x1_stake_RotateConsensusKeyEvent)
-  [Struct `UpdateNetworkAndFullnodeAddressesEvent`](#0x1_stake_UpdateNetworkAndFullnodeAddressesEvent)
-  [Struct `IncreaseLockupEvent`](#0x1_stake_IncreaseLockupEvent)
-  [Struct `JoinValidatorSetEvent`](#0x1_stake_JoinValidatorSetEvent)
-  [Struct `DistributeRewardsEvent`](#0x1_stake_DistributeRewardsEvent)
-  [Struct `UnlockStakeEvent`](#0x1_stake_UnlockStakeEvent)
-  [Struct `WithdrawStakeEvent`](#0x1_stake_WithdrawStakeEvent)
-  [Struct `LeaveValidatorSetEvent`](#0x1_stake_LeaveValidatorSetEvent)
-  [Resource `ValidatorFees`](#0x1_stake_ValidatorFees)
-  [Resource `AllowedValidators`](#0x1_stake_AllowedValidators)
-  [Constants](#@Constants_0)
-  [Function `initialize_validator_fees`](#0x1_stake_initialize_validator_fees)
-  [Function `add_transaction_fee`](#0x1_stake_add_transaction_fee)
-  [Function `deposit_to_pool`](#0x1_stake_deposit_to_pool)
-  [Function `get_lockup_secs`](#0x1_stake_get_lockup_secs)
-  [Function `get_remaining_lockup_secs`](#0x1_stake_get_remaining_lockup_secs)
-  [Function `get_stake`](#0x1_stake_get_stake)
-  [Function `get_validator_state`](#0x1_stake_get_validator_state)
-  [Function `get_current_epoch_voting_power`](#0x1_stake_get_current_epoch_voting_power)
-  [Function `get_delegated_voter`](#0x1_stake_get_delegated_voter)
-  [Function `get_operator`](#0x1_stake_get_operator)
-  [Function `get_owned_pool_address`](#0x1_stake_get_owned_pool_address)
-  [Function `get_validator_index`](#0x1_stake_get_validator_index)
-  [Function `get_current_epoch_proposal_counts`](#0x1_stake_get_current_epoch_proposal_counts)
-  [Function `get_validator_config`](#0x1_stake_get_validator_config)
-  [Function `stake_pool_exists`](#0x1_stake_stake_pool_exists)
-  [Function `initialize`](#0x1_stake_initialize)
-  [Function `initialize_reward_split`](#0x1_stake_initialize_reward_split)
-  [Function `store_endless_coin_cap`](#0x1_stake_store_endless_coin_cap)
-  [Function `remove_validators`](#0x1_stake_remove_validators)
-  [Function `initialize_stake_owner`](#0x1_stake_initialize_stake_owner)
-  [Function `initialize_validator`](#0x1_stake_initialize_validator)
-  [Function `initialize_owner`](#0x1_stake_initialize_owner)
-  [Function `extract_owner_cap`](#0x1_stake_extract_owner_cap)
-  [Function `deposit_owner_cap`](#0x1_stake_deposit_owner_cap)
-  [Function `destroy_owner_cap`](#0x1_stake_destroy_owner_cap)
-  [Function `set_operator`](#0x1_stake_set_operator)
-  [Function `set_operator_with_cap`](#0x1_stake_set_operator_with_cap)
-  [Function `set_delegated_voter`](#0x1_stake_set_delegated_voter)
-  [Function `set_delegated_voter_with_cap`](#0x1_stake_set_delegated_voter_with_cap)
-  [Function `add_stake`](#0x1_stake_add_stake)
-  [Function `add_stake_with_cap`](#0x1_stake_add_stake_with_cap)
-  [Function `reactivate_stake`](#0x1_stake_reactivate_stake)
-  [Function `reactivate_stake_with_cap`](#0x1_stake_reactivate_stake_with_cap)
-  [Function `rotate_consensus_key`](#0x1_stake_rotate_consensus_key)
-  [Function `update_network_and_fullnode_addresses`](#0x1_stake_update_network_and_fullnode_addresses)
-  [Function `increase_lockup`](#0x1_stake_increase_lockup)
-  [Function `increase_lockup_with_cap`](#0x1_stake_increase_lockup_with_cap)
-  [Function `join_validator_set`](#0x1_stake_join_validator_set)
-  [Function `join_validator_set_internal`](#0x1_stake_join_validator_set_internal)
-  [Function `unlock`](#0x1_stake_unlock)
-  [Function `unlock_with_cap`](#0x1_stake_unlock_with_cap)
-  [Function `withdraw`](#0x1_stake_withdraw)
-  [Function `withdraw_with_cap`](#0x1_stake_withdraw_with_cap)
-  [Function `leave_validator_set`](#0x1_stake_leave_validator_set)
-  [Function `is_current_epoch_validator`](#0x1_stake_is_current_epoch_validator)
-  [Function `update_performance_statistics`](#0x1_stake_update_performance_statistics)
-  [Function `on_new_epoch`](#0x1_stake_on_new_epoch)
-  [Function `cur_validator_consensus_infos`](#0x1_stake_cur_validator_consensus_infos)
-  [Function `next_validator_consensus_infos`](#0x1_stake_next_validator_consensus_infos)
-  [Function `validator_consensus_infos_from_validator_set`](#0x1_stake_validator_consensus_infos_from_validator_set)
-  [Function `addresses_from_validator_infos`](#0x1_stake_addresses_from_validator_infos)
-  [Function `update_stake_pool`](#0x1_stake_update_stake_pool)
-  [Function `get_reconfig_start_time_secs`](#0x1_stake_get_reconfig_start_time_secs)
-  [Function `calculate_rewards_amount`](#0x1_stake_calculate_rewards_amount)
-  [Function `distribute_rewards`](#0x1_stake_distribute_rewards)
-  [Function `append`](#0x1_stake_append)
-  [Function `find_validator`](#0x1_stake_find_validator)
-  [Function `generate_validator_info`](#0x1_stake_generate_validator_info)
-  [Function `get_next_epoch_voting_power`](#0x1_stake_get_next_epoch_voting_power)
-  [Function `update_voting_power_increase`](#0x1_stake_update_voting_power_increase)
-  [Function `assert_stake_pool_exists`](#0x1_stake_assert_stake_pool_exists)
-  [Function `configure_allowed_validators`](#0x1_stake_configure_allowed_validators)
-  [Function `is_allowed`](#0x1_stake_is_allowed)
-  [Function `assert_owner_cap_exists`](#0x1_stake_assert_owner_cap_exists)
-  [Function `assert_reconfig_not_in_progress`](#0x1_stake_assert_reconfig_not_in_progress)


<pre><code><b>use</b> <a href="../../endless-stdlib/doc/bls12381.md#0x1_bls12381">0x1::bls12381</a>;
<b>use</b> <a href="chain_status.md#0x1_chain_status">0x1::chain_status</a>;
<b>use</b> <a href="endless_coin.md#0x1_endless_coin">0x1::endless_coin</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="event.md#0x1_event">0x1::event</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features">0x1::features</a>;
<b>use</b> <a href="../../endless-stdlib/doc/fixed_point64.md#0x1_fixed_point64">0x1::fixed_point64</a>;
<b>use</b> <a href="fungible_asset.md#0x1_fungible_asset">0x1::fungible_asset</a>;
<b>use</b> <a href="../../endless-stdlib/doc/math128.md#0x1_math128">0x1::math128</a>;
<b>use</b> <a href="object.md#0x1_object">0x1::object</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="primary_fungible_store.md#0x1_primary_fungible_store">0x1::primary_fungible_store</a>;
<b>use</b> <a href="reconfiguration_state.md#0x1_reconfiguration_state">0x1::reconfiguration_state</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="staking_config.md#0x1_staking_config">0x1::staking_config</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
<b>use</b> <a href="../../endless-stdlib/doc/table.md#0x1_table">0x1::table</a>;
<b>use</b> <a href="timestamp.md#0x1_timestamp">0x1::timestamp</a>;
<b>use</b> <a href="validator_consensus_info.md#0x1_validator_consensus_info">0x1::validator_consensus_info</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">0x1::vector</a>;
</code></pre>



<a id="0x1_stake_OwnerCapability"></a>

## Resource `OwnerCapability`

Capability that represents ownership and can be used to control the validator and the associated stake pool.
Having this be separate from the signer for the account that the validator resources are hosted at allows
modules to have control over a validator.


<pre><code><b>struct</b> <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a> <b>has</b> store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_StakePool"></a>

## Resource `StakePool`

Each validator has a separate StakePool resource and can provide a stake.
Changes in stake for an active validator:
1. If a validator calls add_stake, the newly added stake is moved to pending_active.
2. If validator calls unlock, their stake is moved to pending_inactive.
2. When the next epoch starts, any pending_inactive stake is moved to inactive and can be withdrawn.
Any pending_active stake is moved to active and adds to the validator's voting power.

Changes in stake for an inactive validator:
1. If a validator calls add_stake, the newly added stake is moved directly to active.
2. If validator calls unlock, their stake is moved directly to inactive.
3. When the next epoch starts, the validator can be activated if their active stake is more than the minimum.


<pre><code><b>struct</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>active: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>inactive: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>pending_active: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>pending_inactive: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>locked_until_secs: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>operator_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>delegated_voter: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_ValidatorConfig"></a>

## Resource `ValidatorConfig`

Validator info stored in validator address.


<pre><code><b>struct</b> <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>consensus_pubkey: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>network_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>fullnode_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>validator_index: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_ValidatorInfo"></a>

## Struct `ValidatorInfo`

Consensus information per validator, stored in ValidatorSet.


<pre><code><b>struct</b> <a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>addr: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>voting_power: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>config: <a href="stake.md#0x1_stake_ValidatorConfig">stake::ValidatorConfig</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_ValidatorSet"></a>

## Resource `ValidatorSet`

Full ValidatorSet, stored in @endless_framework.
1. join_validator_set adds to pending_active queue.
2. leave_valdiator_set moves from active to pending_inactive queue.
3. on_new_epoch processes two pending queues and refresh ValidatorInfo from the owner's address.


<pre><code><b>struct</b> <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>consensus_scheme: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>active_validators: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_ValidatorInfo">stake::ValidatorInfo</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>pending_inactive: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_ValidatorInfo">stake::ValidatorInfo</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>pending_active: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_ValidatorInfo">stake::ValidatorInfo</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>total_voting_power: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>total_joining_power: u128</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_EndlessCoinCapabilities"></a>

## Resource `EndlessCoinCapabilities`

EndlessCoin capabilities, set during genesis and stored in @CoreResource account.
This allows the Stake module to mint rewards to stakers.


<pre><code><b>struct</b> <a href="stake.md#0x1_stake_EndlessCoinCapabilities">EndlessCoinCapabilities</a> <b>has</b> key
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

<a id="0x1_stake_IndividualValidatorPerformance"></a>

## Struct `IndividualValidatorPerformance`



<pre><code><b>struct</b> <a href="stake.md#0x1_stake_IndividualValidatorPerformance">IndividualValidatorPerformance</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>successful_proposals: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>failed_proposals: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_ValidatorPerformance"></a>

## Resource `ValidatorPerformance`



<pre><code><b>struct</b> <a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>validators: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_IndividualValidatorPerformance">stake::IndividualValidatorPerformance</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_AccountShare"></a>

## Struct `AccountShare`

account address and shares_of_percent


<pre><code><b>struct</b> <a href="stake.md#0x1_stake_AccountShare">AccountShare</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>account_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>percent: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_BlockRewardShareInfo"></a>

## Resource `BlockRewardShareInfo`

block reward split into [validator, other_accounts]


<pre><code><b>struct</b> <a href="stake.md#0x1_stake_BlockRewardShareInfo">BlockRewardShareInfo</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>accounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_AccountShare">stake::AccountShare</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_RegisterValidatorCandidateEvent"></a>

## Struct `RegisterValidatorCandidateEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_RegisterValidatorCandidateEvent">RegisterValidatorCandidateEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_SetOperatorEvent"></a>

## Struct `SetOperatorEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_SetOperatorEvent">SetOperatorEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>old_operator: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>new_operator: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_AddStakeEvent"></a>

## Struct `AddStakeEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_AddStakeEvent">AddStakeEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>amount_added: u128</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_ReactivateStakeEvent"></a>

## Struct `ReactivateStakeEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_ReactivateStakeEvent">ReactivateStakeEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
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

<a id="0x1_stake_RotateConsensusKeyEvent"></a>

## Struct `RotateConsensusKeyEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_RotateConsensusKeyEvent">RotateConsensusKeyEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>old_consensus_pubkey: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>new_consensus_pubkey: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_UpdateNetworkAndFullnodeAddressesEvent"></a>

## Struct `UpdateNetworkAndFullnodeAddressesEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_UpdateNetworkAndFullnodeAddressesEvent">UpdateNetworkAndFullnodeAddressesEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>old_network_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>new_network_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>old_fullnode_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>new_fullnode_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_IncreaseLockupEvent"></a>

## Struct `IncreaseLockupEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_IncreaseLockupEvent">IncreaseLockupEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>old_locked_until_secs: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>new_locked_until_secs: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_JoinValidatorSetEvent"></a>

## Struct `JoinValidatorSetEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_JoinValidatorSetEvent">JoinValidatorSetEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_DistributeRewardsEvent"></a>

## Struct `DistributeRewardsEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_DistributeRewardsEvent">DistributeRewardsEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>rewards_amount: u128</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_UnlockStakeEvent"></a>

## Struct `UnlockStakeEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_UnlockStakeEvent">UnlockStakeEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>amount_unlocked: u128</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_WithdrawStakeEvent"></a>

## Struct `WithdrawStakeEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_WithdrawStakeEvent">WithdrawStakeEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>amount_withdrawn: u128</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_LeaveValidatorSetEvent"></a>

## Struct `LeaveValidatorSetEvent`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="stake.md#0x1_stake_LeaveValidatorSetEvent">LeaveValidatorSetEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_ValidatorFees"></a>

## Resource `ValidatorFees`

Stores transaction fees assigned to validators. All fees are distributed to validators
at the end of the epoch.
The table is just for bookkeeping, not for FA store


<pre><code><b>struct</b> <a href="stake.md#0x1_stake_ValidatorFees">ValidatorFees</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>fees_table: <a href="../../endless-stdlib/doc/table.md#0x1_table_Table">table::Table</a>&lt;<b>address</b>, u128&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_stake_AllowedValidators"></a>

## Resource `AllowedValidators`

This provides an ACL for Testnet purposes. In testnet, everyone is a whale, a whale can be a validator.
This allows a testnet to bring additional entities into the validator set without compromising the
security of the testnet. This will NOT be enabled in Mainnet.


<pre><code><b>struct</b> <a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>accounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_stake_MAX_U64"></a>



<pre><code><b>const</b> <a href="stake.md#0x1_stake_MAX_U64">MAX_U64</a>: u128 = 18446744073709551615;
</code></pre>



<a id="0x1_stake_MAX_REWARDS_RATE"></a>

Limit the maximum value of <code>rewards_rate</code> in order to avoid any arithmetic overflow.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_MAX_REWARDS_RATE">MAX_REWARDS_RATE</a>: u64 = 1000000;
</code></pre>



<a id="0x1_stake_EALREADY_ACTIVE_VALIDATOR"></a>

Account is already a validator or pending validator.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EALREADY_ACTIVE_VALIDATOR">EALREADY_ACTIVE_VALIDATOR</a>: u64 = 4;
</code></pre>



<a id="0x1_stake_EALREADY_REGISTERED"></a>

Account is already registered as a validator candidate.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EALREADY_REGISTERED">EALREADY_REGISTERED</a>: u64 = 8;
</code></pre>



<a id="0x1_stake_EFEES_TABLE_ALREADY_EXISTS"></a>

Table to store collected transaction fees for each validator already exists.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EFEES_TABLE_ALREADY_EXISTS">EFEES_TABLE_ALREADY_EXISTS</a>: u64 = 19;
</code></pre>



<a id="0x1_stake_EINELIGIBLE_VALIDATOR"></a>

Validator is not defined in the ACL of entities allowed to be validators


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EINELIGIBLE_VALIDATOR">EINELIGIBLE_VALIDATOR</a>: u64 = 17;
</code></pre>



<a id="0x1_stake_EINVALID_LOCKUP"></a>

Cannot update stake pool's lockup to earlier than current lockup.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EINVALID_LOCKUP">EINVALID_LOCKUP</a>: u64 = 18;
</code></pre>



<a id="0x1_stake_EINVALID_PUBLIC_KEY"></a>

Invalid consensus public key


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EINVALID_PUBLIC_KEY">EINVALID_PUBLIC_KEY</a>: u64 = 11;
</code></pre>



<a id="0x1_stake_ELAST_VALIDATOR"></a>

Can't remove last validator.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_ELAST_VALIDATOR">ELAST_VALIDATOR</a>: u64 = 6;
</code></pre>



<a id="0x1_stake_ENOT_OPERATOR"></a>

Account does not have the right operator capability.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_ENOT_OPERATOR">ENOT_OPERATOR</a>: u64 = 9;
</code></pre>



<a id="0x1_stake_ENOT_VALIDATOR"></a>

Account is not a validator.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_ENOT_VALIDATOR">ENOT_VALIDATOR</a>: u64 = 5;
</code></pre>



<a id="0x1_stake_ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED"></a>

Validators cannot join or leave post genesis on this test network.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED">ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED</a>: u64 = 10;
</code></pre>



<a id="0x1_stake_EOWNER_CAP_ALREADY_EXISTS"></a>

An account cannot own more than one owner capability.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EOWNER_CAP_ALREADY_EXISTS">EOWNER_CAP_ALREADY_EXISTS</a>: u64 = 16;
</code></pre>



<a id="0x1_stake_EOWNER_CAP_NOT_FOUND"></a>

Owner capability does not exist at the provided account.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EOWNER_CAP_NOT_FOUND">EOWNER_CAP_NOT_FOUND</a>: u64 = 15;
</code></pre>



<a id="0x1_stake_ERECONFIGURATION_IN_PROGRESS"></a>

Validator set change temporarily disabled because of in-progress reconfiguration.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_ERECONFIGURATION_IN_PROGRESS">ERECONFIGURATION_IN_PROGRESS</a>: u64 = 20;
</code></pre>



<a id="0x1_stake_EREINVALID_FA_TYPE"></a>

Only support Endless FA as gas fee.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EREINVALID_FA_TYPE">EREINVALID_FA_TYPE</a>: u64 = 21;
</code></pre>



<a id="0x1_stake_ESHARES_ABOVE_LIMIT"></a>

split shares sum cannot above 100%


<pre><code><b>const</b> <a href="stake.md#0x1_stake_ESHARES_ABOVE_LIMIT">ESHARES_ABOVE_LIMIT</a>: u64 = 22;
</code></pre>



<a id="0x1_stake_ESTAKE_EXCEEDS_MAX"></a>

Total stake exceeds maximum allowed.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_ESTAKE_EXCEEDS_MAX">ESTAKE_EXCEEDS_MAX</a>: u64 = 7;
</code></pre>



<a id="0x1_stake_ESTAKE_POOL_DOES_NOT_EXIST"></a>

Stake pool does not exist at the provided pool address.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_ESTAKE_POOL_DOES_NOT_EXIST">ESTAKE_POOL_DOES_NOT_EXIST</a>: u64 = 14;
</code></pre>



<a id="0x1_stake_ESTAKE_TOO_HIGH"></a>

Too much stake to join validator set.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_ESTAKE_TOO_HIGH">ESTAKE_TOO_HIGH</a>: u64 = 3;
</code></pre>



<a id="0x1_stake_ESTAKE_TOO_LOW"></a>

Not enough stake to join validator set.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_ESTAKE_TOO_LOW">ESTAKE_TOO_LOW</a>: u64 = 2;
</code></pre>



<a id="0x1_stake_EVALIDATOR_CONFIG"></a>

Validator Config not published.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EVALIDATOR_CONFIG">EVALIDATOR_CONFIG</a>: u64 = 1;
</code></pre>



<a id="0x1_stake_EVALIDATOR_SET_TOO_LARGE"></a>

Validator set exceeds the limit


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EVALIDATOR_SET_TOO_LARGE">EVALIDATOR_SET_TOO_LARGE</a>: u64 = 12;
</code></pre>



<a id="0x1_stake_EVOTING_POWER_INCREASE_EXCEEDS_LIMIT"></a>

Voting power increase has exceeded the limit for this current epoch.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_EVOTING_POWER_INCREASE_EXCEEDS_LIMIT">EVOTING_POWER_INCREASE_EXCEEDS_LIMIT</a>: u64 = 13;
</code></pre>



<a id="0x1_stake_MAX_VALIDATOR_SET_SIZE"></a>

Limit the maximum size to u16::max, it's the current limit of the bitvec
https://github.com/Endless-labs/endless/blob/main/crates/endless-bitvec/src/lib.rs#L20


<pre><code><b>const</b> <a href="stake.md#0x1_stake_MAX_VALIDATOR_SET_SIZE">MAX_VALIDATOR_SET_SIZE</a>: u64 = 65536;
</code></pre>



<a id="0x1_stake_REWARD_DENOMINATOR"></a>



<pre><code><b>const</b> <a href="stake.md#0x1_stake_REWARD_DENOMINATOR">REWARD_DENOMINATOR</a>: u64 = 100;
</code></pre>



<a id="0x1_stake_VALIDATOR_STATUS_ACTIVE"></a>



<pre><code><b>const</b> <a href="stake.md#0x1_stake_VALIDATOR_STATUS_ACTIVE">VALIDATOR_STATUS_ACTIVE</a>: u64 = 2;
</code></pre>



<a id="0x1_stake_VALIDATOR_STATUS_INACTIVE"></a>



<pre><code><b>const</b> <a href="stake.md#0x1_stake_VALIDATOR_STATUS_INACTIVE">VALIDATOR_STATUS_INACTIVE</a>: u64 = 4;
</code></pre>



<a id="0x1_stake_VALIDATOR_STATUS_PENDING_ACTIVE"></a>

Validator status enum. We can switch to proper enum later once Move supports it.


<pre><code><b>const</b> <a href="stake.md#0x1_stake_VALIDATOR_STATUS_PENDING_ACTIVE">VALIDATOR_STATUS_PENDING_ACTIVE</a>: u64 = 1;
</code></pre>



<a id="0x1_stake_VALIDATOR_STATUS_PENDING_INACTIVE"></a>



<pre><code><b>const</b> <a href="stake.md#0x1_stake_VALIDATOR_STATUS_PENDING_INACTIVE">VALIDATOR_STATUS_PENDING_INACTIVE</a>: u64 = 3;
</code></pre>



<a id="0x1_stake_initialize_validator_fees"></a>

## Function `initialize_validator_fees`

Initializes the resource storing information about collected transaction fees per validator.
Used by <code><a href="transaction_fee.md#0x1_transaction_fee">transaction_fee</a>.<b>move</b></code> to initialize fee collection and distribution.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_initialize_validator_fees">initialize_validator_fees</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_initialize_validator_fees">initialize_validator_fees</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>assert</b>!(
        !<b>exists</b>&lt;<a href="stake.md#0x1_stake_ValidatorFees">ValidatorFees</a>&gt;(@endless_framework),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_already_exists">error::already_exists</a>(<a href="stake.md#0x1_stake_EFEES_TABLE_ALREADY_EXISTS">EFEES_TABLE_ALREADY_EXISTS</a>)
    );
    <b>move_to</b>(endless_framework, <a href="stake.md#0x1_stake_ValidatorFees">ValidatorFees</a> { fees_table: <a href="../../endless-stdlib/doc/table.md#0x1_table_new">table::new</a>() });
}
</code></pre>



</details>

<a id="0x1_stake_add_transaction_fee"></a>

## Function `add_transaction_fee`

Stores the transaction fee collected to the specified validator address.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_add_transaction_fee">add_transaction_fee</a>(validator_addr: <b>address</b>, fee: <a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_add_transaction_fee">add_transaction_fee</a>(validator_addr: <b>address</b>, fee: FungibleAsset) <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorFees">ValidatorFees</a> {
    <b>let</b> fees_table = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorFees">ValidatorFees</a>&gt;(@endless_framework).fees_table;
    <b>let</b> amount = <a href="fungible_asset.md#0x1_fungible_asset_amount">fungible_asset::amount</a>(&fee);

    // for now, only accept "EDS" FA <b>as</b> gas fee
    <b>assert</b>!(<a href="endless_coin.md#0x1_endless_coin_is_true_EDS">endless_coin::is_true_EDS</a>(&fee), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_EREINVALID_FA_TYPE">EREINVALID_FA_TYPE</a>));
    <b>if</b> (<a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(fees_table, validator_addr)) {
        <b>let</b> collected_fee = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow_mut">table::borrow_mut</a>(fees_table, validator_addr);
        *collected_fee = *collected_fee + amount;
    } <b>else</b> {
        <a href="../../endless-stdlib/doc/table.md#0x1_table_add">table::add</a>(fees_table, validator_addr, amount);
    };

    <a href="stake.md#0x1_stake_deposit_to_pool">deposit_to_pool</a>(fee);
}
</code></pre>



</details>

<a id="0x1_stake_deposit_to_pool"></a>

## Function `deposit_to_pool`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_deposit_to_pool">deposit_to_pool</a>(fee: <a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_deposit_to_pool">deposit_to_pool</a>(fee: FungibleAsset) {
    <b>let</b> pool_addr = <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(@endless_framework, <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>());
    <a href="fungible_asset.md#0x1_fungible_asset_deposit">fungible_asset::deposit</a>&lt;FungibleStore&gt;(pool_addr, fee);
}
</code></pre>



</details>

<a id="0x1_stake_get_lockup_secs"></a>

## Function `get_lockup_secs`

Return the lockup expiration of the stake pool at <code>pool_address</code>.
This will throw an error if there's no stake pool at <code>pool_address</code>.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_lockup_secs">get_lockup_secs</a>(pool_address: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_lockup_secs">get_lockup_secs</a>(pool_address: <b>address</b>): u64 <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address).locked_until_secs
}
</code></pre>



</details>

<a id="0x1_stake_get_remaining_lockup_secs"></a>

## Function `get_remaining_lockup_secs`

Return the remaining lockup of the stake pool at <code>pool_address</code>.
This will throw an error if there's no stake pool at <code>pool_address</code>.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_remaining_lockup_secs">get_remaining_lockup_secs</a>(pool_address: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_remaining_lockup_secs">get_remaining_lockup_secs</a>(pool_address: <b>address</b>): u64 <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> lockup_time = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address).locked_until_secs;
    <b>if</b> (lockup_time &lt;= <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>()) {
        0
    } <b>else</b> {
        lockup_time - <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>()
    }
}
</code></pre>



</details>

<a id="0x1_stake_get_stake"></a>

## Function `get_stake`

Return the different stake amounts for <code>pool_address</code> (whether the validator is active or not).
The returned amounts are for (active, inactive, pending_active, pending_inactive) stake respectively.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_stake">get_stake</a>(pool_address: <b>address</b>): (u128, u128, u128, u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_stake">get_stake</a>(pool_address: <b>address</b>): (u128, u128, u128, u128) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> stake_pool = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    (
        stake_pool.active,
        stake_pool.inactive,
        stake_pool.pending_active,
        stake_pool.pending_inactive,
    )
}
</code></pre>



</details>

<a id="0x1_stake_get_validator_state"></a>

## Function `get_validator_state`

Returns the validator's state.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_validator_state">get_validator_state</a>(pool_address: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_validator_state">get_validator_state</a>(pool_address: <b>address</b>): u64 <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <b>let</b> validator_set = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>&gt;(@endless_framework);
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&<a href="stake.md#0x1_stake_find_validator">find_validator</a>(&validator_set.pending_active, pool_address))) {
        <a href="stake.md#0x1_stake_VALIDATOR_STATUS_PENDING_ACTIVE">VALIDATOR_STATUS_PENDING_ACTIVE</a>
    } <b>else</b> <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&<a href="stake.md#0x1_stake_find_validator">find_validator</a>(&validator_set.active_validators, pool_address))) {
        <a href="stake.md#0x1_stake_VALIDATOR_STATUS_ACTIVE">VALIDATOR_STATUS_ACTIVE</a>
    } <b>else</b> <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&<a href="stake.md#0x1_stake_find_validator">find_validator</a>(&validator_set.pending_inactive, pool_address))) {
        <a href="stake.md#0x1_stake_VALIDATOR_STATUS_PENDING_INACTIVE">VALIDATOR_STATUS_PENDING_INACTIVE</a>
    } <b>else</b> {
        <a href="stake.md#0x1_stake_VALIDATOR_STATUS_INACTIVE">VALIDATOR_STATUS_INACTIVE</a>
    }
}
</code></pre>



</details>

<a id="0x1_stake_get_current_epoch_voting_power"></a>

## Function `get_current_epoch_voting_power`

Return the voting power of the validator in the current epoch.
This is the same as the validator's total active and pending_inactive stake.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_current_epoch_voting_power">get_current_epoch_voting_power</a>(pool_address: <b>address</b>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_current_epoch_voting_power">get_current_epoch_voting_power</a>(pool_address: <b>address</b>): u128 <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> validator_state = <a href="stake.md#0x1_stake_get_validator_state">get_validator_state</a>(pool_address);
    // Both active and pending inactive validators can still vote in the current epoch.
    <b>if</b> (validator_state == <a href="stake.md#0x1_stake_VALIDATOR_STATUS_ACTIVE">VALIDATOR_STATUS_ACTIVE</a> || validator_state == <a href="stake.md#0x1_stake_VALIDATOR_STATUS_PENDING_INACTIVE">VALIDATOR_STATUS_PENDING_INACTIVE</a>) {
        <b>let</b> active_stake = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address).active;
        <b>let</b> pending_inactive_stake = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address).pending_inactive;
        active_stake + pending_inactive_stake
    } <b>else</b> {
        0
    }
}
</code></pre>



</details>

<a id="0x1_stake_get_delegated_voter"></a>

## Function `get_delegated_voter`

Return the delegated voter of the validator at <code>pool_address</code>.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_delegated_voter">get_delegated_voter</a>(pool_address: <b>address</b>): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_delegated_voter">get_delegated_voter</a>(pool_address: <b>address</b>): <b>address</b> <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address).delegated_voter
}
</code></pre>



</details>

<a id="0x1_stake_get_operator"></a>

## Function `get_operator`

Return the operator of the validator at <code>pool_address</code>.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_operator">get_operator</a>(pool_address: <b>address</b>): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_operator">get_operator</a>(pool_address: <b>address</b>): <b>address</b> <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address).operator_address
}
</code></pre>



</details>

<a id="0x1_stake_get_owned_pool_address"></a>

## Function `get_owned_pool_address`

Return the pool address in <code>owner_cap</code>.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_owned_pool_address">get_owned_pool_address</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_owned_pool_address">get_owned_pool_address</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>): <b>address</b> {
    owner_cap.pool_address
}
</code></pre>



</details>

<a id="0x1_stake_get_validator_index"></a>

## Function `get_validator_index`

Return the validator index for <code>pool_address</code>.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_validator_index">get_validator_index</a>(pool_address: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_validator_index">get_validator_index</a>(pool_address: <b>address</b>): u64 <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a> {
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(pool_address).validator_index
}
</code></pre>



</details>

<a id="0x1_stake_get_current_epoch_proposal_counts"></a>

## Function `get_current_epoch_proposal_counts`

Return the number of successful and failed proposals for the proposal at the given validator index.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_current_epoch_proposal_counts">get_current_epoch_proposal_counts</a>(validator_index: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_current_epoch_proposal_counts">get_current_epoch_proposal_counts</a>(validator_index: u64): (u64, u64) <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a> {
    <b>let</b> validator_performances = &<b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a>&gt;(@endless_framework).validators;
    <b>let</b> validator_performance = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(validator_performances, validator_index);
    (validator_performance.successful_proposals, validator_performance.failed_proposals)
}
</code></pre>



</details>

<a id="0x1_stake_get_validator_config"></a>

## Function `get_validator_config`

Return the validator's config.


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_validator_config">get_validator_config</a>(pool_address: <b>address</b>): (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_get_validator_config">get_validator_config</a>(pool_address: <b>address</b>): (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;) <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a> {
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> validator_config = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(pool_address);
    (validator_config.consensus_pubkey, validator_config.network_addresses, validator_config.fullnode_addresses)
}
</code></pre>



</details>

<a id="0x1_stake_stake_pool_exists"></a>

## Function `stake_pool_exists`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_stake_pool_exists">stake_pool_exists</a>(addr: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_stake_pool_exists">stake_pool_exists</a>(addr: <b>address</b>): bool {
    <b>exists</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(addr)
}
</code></pre>



</details>

<a id="0x1_stake_initialize"></a>

## Function `initialize`

Initialize validator set to the core resource account.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);

    <b>move_to</b>(endless_framework, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
        consensus_scheme: 0,
        active_validators: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
        pending_active: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
        pending_inactive: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
        total_voting_power: 0,
        total_joining_power: 0,
    });

    <b>move_to</b>(endless_framework, <a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a> {
        validators: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
    });
}
</code></pre>



</details>

<a id="0x1_stake_initialize_reward_split"></a>

## Function `initialize_reward_split`

Initialize validator set to the core resource account.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_initialize_reward_split">initialize_reward_split</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, share_info: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_AccountShare">stake::AccountShare</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_initialize_reward_split">initialize_reward_split</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, share_info: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_AccountShare">AccountShare</a>&gt;) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);

    // guarantee all <a href="account.md#0x1_account">account</a> shares sum cannot above 100
    <b>let</b> all_shares = 0;
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&share_info, |info| {
        <b>let</b> share_info: &<a href="stake.md#0x1_stake_AccountShare">AccountShare</a> = info;
        all_shares = all_shares + share_info.percent;
    });
    <b>assert</b>!((all_shares &lt; <a href="stake.md#0x1_stake_REWARD_DENOMINATOR">REWARD_DENOMINATOR</a>), <a href="stake.md#0x1_stake_ESHARES_ABOVE_LIMIT">ESHARES_ABOVE_LIMIT</a>);

    <b>move_to</b>(endless_framework, <a href="stake.md#0x1_stake_BlockRewardShareInfo">BlockRewardShareInfo</a> {
        accounts: share_info,
    });
}
</code></pre>



</details>

<a id="0x1_stake_store_endless_coin_cap"></a>

## Function `store_endless_coin_cap`

This is only called during Genesis, which is where MintCapability<EndlessCoin> can be created.
Beyond genesis, no one can create EndlessCoin mint/burn capabilities.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_store_endless_coin_cap">store_endless_coin_cap</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, mint_cap: <a href="fungible_asset.md#0x1_fungible_asset_MintRef">fungible_asset::MintRef</a>, transfer_cap: <a href="fungible_asset.md#0x1_fungible_asset_TransferRef">fungible_asset::TransferRef</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_store_endless_coin_cap">store_endless_coin_cap</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, mint_cap: MintRef, transfer_cap: TransferRef) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>move_to</b>(endless_framework, <a href="stake.md#0x1_stake_EndlessCoinCapabilities">EndlessCoinCapabilities</a> { mint_cap, transfer_cap })
}
</code></pre>



</details>

<a id="0x1_stake_remove_validators"></a>

## Function `remove_validators`

Allow on chain governance to remove validators from the validator set.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_remove_validators">remove_validators</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, validators: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_remove_validators">remove_validators</a>(
    endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    validators: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
) <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>let</b> validator_set = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>&gt;(@endless_framework);
    <b>let</b> active_validators = &<b>mut</b> validator_set.active_validators;
    <b>let</b> pending_inactive = &<b>mut</b> validator_set.pending_inactive;
    <b>let</b> len_validators = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(validators);
    <b>let</b> i = 0;
    // Remove each validator from the validator set.
    <b>while</b> ({
        i &lt; len_validators
    }) {
        <b>let</b> validator = *<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(validators, i);
        <b>let</b> validator_index = <a href="stake.md#0x1_stake_find_validator">find_validator</a>(active_validators, validator);
        <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&validator_index)) {
            <b>let</b> validator_info = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_swap_remove">vector::swap_remove</a>(active_validators, *<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&validator_index));
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(pending_inactive, validator_info);
        };
        i = i + 1;
    };
}
</code></pre>



</details>

<a id="0x1_stake_initialize_stake_owner"></a>

## Function `initialize_stake_owner`

Initialize the validator account and give ownership to the signing account
except it leaves the ValidatorConfig to be set by another entity.
Note: this triggers setting the operator and owner, set it to the account's address
to set later.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_initialize_stake_owner">initialize_stake_owner</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, initial_stake_amount: u128, operator: <b>address</b>, voter: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_initialize_stake_owner">initialize_stake_owner</a>(
    owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    initial_stake_amount: u128,
    operator: <b>address</b>,
    voter: <b>address</b>,
) <b>acquires</b> <a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a>, <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <a href="stake.md#0x1_stake_initialize_owner">initialize_owner</a>(owner);
    <b>move_to</b>(owner, <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a> {
        consensus_pubkey: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
        network_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
        fullnode_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
        validator_index: 0,
    });

    <a href="stake.md#0x1_stake_add_stake">add_stake</a>(owner, initial_stake_amount);

    <b>let</b> account_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner);
    <b>if</b> (account_address != operator) {
        <a href="stake.md#0x1_stake_set_operator">set_operator</a>(owner, operator)
    };
    <b>if</b> (account_address != voter) {
        <a href="stake.md#0x1_stake_set_delegated_voter">set_delegated_voter</a>(owner, voter)
    };
}
</code></pre>



</details>

<a id="0x1_stake_initialize_validator"></a>

## Function `initialize_validator`

Initialize the validator account and give ownership to the signing account.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_initialize_validator">initialize_validator</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, consensus_pubkey: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, proof_of_possession: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, network_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, fullnode_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_initialize_validator">initialize_validator</a>(
    <a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    consensus_pubkey: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    proof_of_possession: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    network_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    fullnode_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) <b>acquires</b> <a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a> {
    // Checks the <b>public</b> key <b>has</b> a valid proof-of-possession <b>to</b> prevent rogue-key attacks.
    <b>let</b> pubkey_from_pop = &<b>mut</b> <a href="../../endless-stdlib/doc/bls12381.md#0x1_bls12381_public_key_from_bytes_with_pop">bls12381::public_key_from_bytes_with_pop</a>(
        consensus_pubkey,
        &proof_of_possession_from_bytes(proof_of_possession)
    );
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(pubkey_from_pop), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_EINVALID_PUBLIC_KEY">EINVALID_PUBLIC_KEY</a>));

    <a href="stake.md#0x1_stake_initialize_owner">initialize_owner</a>(<a href="account.md#0x1_account">account</a>);
    <b>move_to</b>(<a href="account.md#0x1_account">account</a>, <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a> {
        consensus_pubkey,
        network_addresses,
        fullnode_addresses,
        validator_index: 0,
    });
}
</code></pre>



</details>

<a id="0x1_stake_initialize_owner"></a>

## Function `initialize_owner`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_initialize_owner">initialize_owner</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_initialize_owner">initialize_owner</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a> {
    <b>let</b> owner_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner);
    <b>assert</b>!(<a href="stake.md#0x1_stake_is_allowed">is_allowed</a>(owner_address), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="stake.md#0x1_stake_EINELIGIBLE_VALIDATOR">EINELIGIBLE_VALIDATOR</a>));
    <b>assert</b>!(!<a href="stake.md#0x1_stake_stake_pool_exists">stake_pool_exists</a>(owner_address), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_already_exists">error::already_exists</a>(<a href="stake.md#0x1_stake_EALREADY_REGISTERED">EALREADY_REGISTERED</a>));

    <b>move_to</b>(owner, <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
        active: 0,
        pending_active: 0,
        pending_inactive: 0,
        inactive: 0,
        locked_until_secs: 0,
        operator_address: owner_address,
        delegated_voter: owner_address,
    });

    <b>move_to</b>(owner, <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a> { pool_address: owner_address });
}
</code></pre>



</details>

<a id="0x1_stake_extract_owner_cap"></a>

## Function `extract_owner_cap`

Extract and return owner capability from the signing account.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_extract_owner_cap">extract_owner_cap</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): <a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_extract_owner_cap">extract_owner_cap</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a> <b>acquires</b> <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a> {
    <b>let</b> owner_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner);
    <a href="stake.md#0x1_stake_assert_owner_cap_exists">assert_owner_cap_exists</a>(owner_address);
    <b>move_from</b>&lt;<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>&gt;(owner_address)
}
</code></pre>



</details>

<a id="0x1_stake_deposit_owner_cap"></a>

## Function `deposit_owner_cap`

Deposit <code>owner_cap</code> into <code><a href="account.md#0x1_account">account</a></code>. This requires <code><a href="account.md#0x1_account">account</a></code> to not already have ownership of another
staking pool.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_deposit_owner_cap">deposit_owner_cap</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, owner_cap: <a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_deposit_owner_cap">deposit_owner_cap</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, owner_cap: <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>) {
    <b>assert</b>!(!<b>exists</b>&lt;<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>&gt;(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner)), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="stake.md#0x1_stake_EOWNER_CAP_ALREADY_EXISTS">EOWNER_CAP_ALREADY_EXISTS</a>));
    <b>move_to</b>(owner, owner_cap);
}
</code></pre>



</details>

<a id="0x1_stake_destroy_owner_cap"></a>

## Function `destroy_owner_cap`

Destroy <code>owner_cap</code>.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_destroy_owner_cap">destroy_owner_cap</a>(owner_cap: <a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_destroy_owner_cap">destroy_owner_cap</a>(owner_cap: <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>) {
    <b>let</b> <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a> { pool_address: _ } = owner_cap;
}
</code></pre>



</details>

<a id="0x1_stake_set_operator"></a>

## Function `set_operator`

Allows an owner to change the operator of the stake pool.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_set_operator">set_operator</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_operator: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_set_operator">set_operator</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_operator: <b>address</b>) <b>acquires</b> <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <b>let</b> owner_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner);
    <a href="stake.md#0x1_stake_assert_owner_cap_exists">assert_owner_cap_exists</a>(owner_address);
    <b>let</b> ownership_cap = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>&gt;(owner_address);
    <a href="stake.md#0x1_stake_set_operator_with_cap">set_operator_with_cap</a>(ownership_cap, new_operator);
}
</code></pre>



</details>

<a id="0x1_stake_set_operator_with_cap"></a>

## Function `set_operator_with_cap`

Allows an account with ownership capability to change the operator of the stake pool.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_set_operator_with_cap">set_operator_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>, new_operator: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_set_operator_with_cap">set_operator_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, new_operator: <b>address</b>) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <b>let</b> pool_address = owner_cap.pool_address;
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    <b>let</b> old_operator = stake_pool.operator_address;
    stake_pool.operator_address = new_operator;

    <a href="event.md#0x1_event_emit">event::emit</a>(
        <a href="stake.md#0x1_stake_SetOperatorEvent">SetOperatorEvent</a> {
            pool_address,
            old_operator,
            new_operator,
        },
    );
}
</code></pre>



</details>

<a id="0x1_stake_set_delegated_voter"></a>

## Function `set_delegated_voter`

Allows an owner to change the delegated voter of the stake pool.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_set_delegated_voter">set_delegated_voter</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_voter: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_set_delegated_voter">set_delegated_voter</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_voter: <b>address</b>) <b>acquires</b> <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <b>let</b> owner_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner);
    <a href="stake.md#0x1_stake_assert_owner_cap_exists">assert_owner_cap_exists</a>(owner_address);
    <b>let</b> ownership_cap = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>&gt;(owner_address);
    <a href="stake.md#0x1_stake_set_delegated_voter_with_cap">set_delegated_voter_with_cap</a>(ownership_cap, new_voter);
}
</code></pre>



</details>

<a id="0x1_stake_set_delegated_voter_with_cap"></a>

## Function `set_delegated_voter_with_cap`

Allows an owner to change the delegated voter of the stake pool.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_set_delegated_voter_with_cap">set_delegated_voter_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>, new_voter: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_set_delegated_voter_with_cap">set_delegated_voter_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, new_voter: <b>address</b>) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <b>let</b> pool_address = owner_cap.pool_address;
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    stake_pool.delegated_voter = new_voter;
}
</code></pre>



</details>

<a id="0x1_stake_add_stake"></a>

## Function `add_stake`

Add <code>amount</code> of coins from the <code><a href="account.md#0x1_account">account</a></code> owning the StakePool.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_add_stake">add_stake</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_add_stake">add_stake</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, amount: u128) <b>acquires</b> <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <b>let</b> owner_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner);
    <a href="stake.md#0x1_stake_assert_owner_cap_exists">assert_owner_cap_exists</a>(owner_address);
    <b>if</b> (amount != 0) {
        <b>let</b> ownership_cap = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>&gt;(owner_address);
        <b>let</b> fa = <a href="endless_coin.md#0x1_endless_coin_withdraw">endless_coin::withdraw</a>(owner, amount);
        <a href="stake.md#0x1_stake_add_stake_with_cap">add_stake_with_cap</a>(ownership_cap, fa);
    }
}
</code></pre>



</details>

<a id="0x1_stake_add_stake_with_cap"></a>

## Function `add_stake_with_cap`

Add <code>coins</code> into <code>pool_address</code>. this requires the corresponding <code>owner_cap</code> to be passed in.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_add_stake_with_cap">add_stake_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>, fa: <a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_add_stake_with_cap">add_stake_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, fa: FungibleAsset) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    <b>let</b> pool_address = owner_cap.pool_address;
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    // for now, only accept "EDS" FA <b>as</b> gas fee
    <b>let</b> is_true_EDS = <a href="endless_coin.md#0x1_endless_coin_is_true_EDS">endless_coin::is_true_EDS</a>(&fa);
    <b>assert</b>!(is_true_EDS, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_EREINVALID_FA_TYPE">EREINVALID_FA_TYPE</a>));
    <b>let</b> amount = <a href="fungible_asset.md#0x1_fungible_asset_amount">fungible_asset::amount</a>(&fa);
    <b>if</b> ( amount == 0) {
        <a href="fungible_asset.md#0x1_fungible_asset_destroy_zero">fungible_asset::destroy_zero</a>(fa);
        <b>return</b>
    };

    // Only track and validate <a href="voting.md#0x1_voting">voting</a> power increase for active and pending_active validator.
    // Pending_inactive validator will be removed from the validator set in the next epoch.
    // Inactive validator's total <a href="stake.md#0x1_stake">stake</a> will be tracked when they join the validator set.
    <b>let</b> validator_set = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>&gt;(@endless_framework);
    // Search directly rather using get_validator_state <b>to</b> save on unnecessary loops.
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&<a href="stake.md#0x1_stake_find_validator">find_validator</a>(&validator_set.active_validators, pool_address)) ||
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&<a href="stake.md#0x1_stake_find_validator">find_validator</a>(&validator_set.pending_active, pool_address))) {
        <a href="stake.md#0x1_stake_update_voting_power_increase">update_voting_power_increase</a>(amount);
    };

    // desposit <b>to</b> <a href="stake.md#0x1_stake">stake</a> pool(actually under endless_framework)
    <a href="stake.md#0x1_stake_deposit_to_pool">deposit_to_pool</a>(fa);

    // Add <b>to</b> pending_active <b>if</b> it's a current validator because the <a href="stake.md#0x1_stake">stake</a> is not counted until the next epoch.
    // Otherwise, the delegation can be added <b>to</b> active directly <b>as</b> the validator is also activated in the epoch.
    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    <b>if</b> (<a href="stake.md#0x1_stake_is_current_epoch_validator">is_current_epoch_validator</a>(pool_address)) {
        stake_pool.pending_active = stake_pool.pending_active + amount;
    } <b>else</b> {
        stake_pool.active = stake_pool.active + amount;
    };

    <b>let</b> (_, maximum_stake) = <a href="staking_config.md#0x1_staking_config_get_required_stake">staking_config::get_required_stake</a>(&<a href="staking_config.md#0x1_staking_config_get">staking_config::get</a>());
    <b>let</b> voting_power = <a href="stake.md#0x1_stake_get_next_epoch_voting_power">get_next_epoch_voting_power</a>(stake_pool);
    <b>assert</b>!(voting_power &lt;= maximum_stake, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_ESTAKE_EXCEEDS_MAX">ESTAKE_EXCEEDS_MAX</a>));

    <a href="event.md#0x1_event_emit">event::emit</a>(
        <a href="stake.md#0x1_stake_AddStakeEvent">AddStakeEvent</a> {
            pool_address,
            amount_added: amount,
        },
    );
}
</code></pre>



</details>

<a id="0x1_stake_reactivate_stake"></a>

## Function `reactivate_stake`

Move <code>amount</code> of coins from pending_inactive to active.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_reactivate_stake">reactivate_stake</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_reactivate_stake">reactivate_stake</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, amount: u128) <b>acquires</b> <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    <b>let</b> owner_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner);
    <a href="stake.md#0x1_stake_assert_owner_cap_exists">assert_owner_cap_exists</a>(owner_address);
    <b>let</b> ownership_cap = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>&gt;(owner_address);
    <a href="stake.md#0x1_stake_reactivate_stake_with_cap">reactivate_stake_with_cap</a>(ownership_cap, amount);
}
</code></pre>



</details>

<a id="0x1_stake_reactivate_stake_with_cap"></a>

## Function `reactivate_stake_with_cap`



<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_reactivate_stake_with_cap">reactivate_stake_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_reactivate_stake_with_cap">reactivate_stake_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, amount: u128) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    <b>let</b> pool_address = owner_cap.pool_address;
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);

    // Cap the amount <b>to</b> reactivate by the amount in pending_inactive.
    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    <b>let</b> total_pending_inactive = stake_pool.pending_inactive;
    amount = <b>min</b>(amount, total_pending_inactive);

    // Since this does not count <b>as</b> a <a href="voting.md#0x1_voting">voting</a> power change (pending inactive still counts <b>as</b> <a href="voting.md#0x1_voting">voting</a> power in the
    // current epoch), <a href="stake.md#0x1_stake">stake</a> can be immediately moved from pending inactive <b>to</b> active.
    // We also don't need <b>to</b> check <a href="voting.md#0x1_voting">voting</a> power increase <b>as</b> there's none.
    stake_pool.pending_inactive = stake_pool.pending_inactive - amount;
    stake_pool.active = stake_pool.active + amount;

    <a href="event.md#0x1_event_emit">event::emit</a>(
        <a href="stake.md#0x1_stake_ReactivateStakeEvent">ReactivateStakeEvent</a> {
            pool_address,
            amount,
        },
    );
}
</code></pre>



</details>

<a id="0x1_stake_rotate_consensus_key"></a>

## Function `rotate_consensus_key`

Rotate the consensus key of the validator, it'll take effect in next epoch.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_rotate_consensus_key">rotate_consensus_key</a>(operator: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, pool_address: <b>address</b>, new_consensus_pubkey: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, proof_of_possession: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_rotate_consensus_key">rotate_consensus_key</a>(
    operator: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    pool_address: <b>address</b>,
    new_consensus_pubkey: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    proof_of_possession: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);

    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(operator) == stake_pool.operator_address, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_unauthenticated">error::unauthenticated</a>(<a href="stake.md#0x1_stake_ENOT_OPERATOR">ENOT_OPERATOR</a>));

    <b>assert</b>!(<b>exists</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(pool_address), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="stake.md#0x1_stake_EVALIDATOR_CONFIG">EVALIDATOR_CONFIG</a>));
    <b>let</b> validator_info = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(pool_address);
    <b>let</b> old_consensus_pubkey = validator_info.consensus_pubkey;
    // Checks the <b>public</b> key <b>has</b> a valid proof-of-possession <b>to</b> prevent rogue-key attacks.
    <b>let</b> pubkey_from_pop = &<b>mut</b> <a href="../../endless-stdlib/doc/bls12381.md#0x1_bls12381_public_key_from_bytes_with_pop">bls12381::public_key_from_bytes_with_pop</a>(
        new_consensus_pubkey,
        &proof_of_possession_from_bytes(proof_of_possession)
    );
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(pubkey_from_pop), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_EINVALID_PUBLIC_KEY">EINVALID_PUBLIC_KEY</a>));
    validator_info.consensus_pubkey = new_consensus_pubkey;

    <a href="event.md#0x1_event_emit">event::emit</a>(
        <a href="stake.md#0x1_stake_RotateConsensusKeyEvent">RotateConsensusKeyEvent</a> {
            pool_address,
            old_consensus_pubkey,
            new_consensus_pubkey,
        },
    );
}
</code></pre>



</details>

<a id="0x1_stake_update_network_and_fullnode_addresses"></a>

## Function `update_network_and_fullnode_addresses`

Update the network and full node addresses of the validator. This only takes effect in the next epoch.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_update_network_and_fullnode_addresses">update_network_and_fullnode_addresses</a>(operator: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, pool_address: <b>address</b>, new_network_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, new_fullnode_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_update_network_and_fullnode_addresses">update_network_and_fullnode_addresses</a>(
    operator: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    pool_address: <b>address</b>,
    new_network_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    new_fullnode_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(operator) == stake_pool.operator_address, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_unauthenticated">error::unauthenticated</a>(<a href="stake.md#0x1_stake_ENOT_OPERATOR">ENOT_OPERATOR</a>));
    <b>assert</b>!(<b>exists</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(pool_address), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="stake.md#0x1_stake_EVALIDATOR_CONFIG">EVALIDATOR_CONFIG</a>));
    <b>let</b> validator_info = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(pool_address);
    <b>let</b> old_network_addresses = validator_info.network_addresses;
    validator_info.network_addresses = new_network_addresses;
    <b>let</b> old_fullnode_addresses = validator_info.fullnode_addresses;
    validator_info.fullnode_addresses = new_fullnode_addresses;

    <a href="event.md#0x1_event_emit">event::emit</a>(
        <a href="stake.md#0x1_stake_UpdateNetworkAndFullnodeAddressesEvent">UpdateNetworkAndFullnodeAddressesEvent</a> {
            pool_address,
            old_network_addresses,
            new_network_addresses,
            old_fullnode_addresses,
            new_fullnode_addresses,
        },
    );
}
</code></pre>



</details>

<a id="0x1_stake_increase_lockup"></a>

## Function `increase_lockup`

Similar to increase_lockup_with_cap but will use ownership capability from the signing account.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_increase_lockup">increase_lockup</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_increase_lockup">increase_lockup</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) <b>acquires</b> <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <b>let</b> owner_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner);
    <a href="stake.md#0x1_stake_assert_owner_cap_exists">assert_owner_cap_exists</a>(owner_address);
    <b>let</b> ownership_cap = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>&gt;(owner_address);
    <a href="stake.md#0x1_stake_increase_lockup_with_cap">increase_lockup_with_cap</a>(ownership_cap);
}
</code></pre>



</details>

<a id="0x1_stake_increase_lockup_with_cap"></a>

## Function `increase_lockup_with_cap`

Unlock from active delegation, it's moved to pending_inactive if locked_until_secs < current_time or
directly inactive if it's not from an active validator.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_increase_lockup_with_cap">increase_lockup_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_increase_lockup_with_cap">increase_lockup_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <b>let</b> pool_address = owner_cap.pool_address;
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> config = <a href="staking_config.md#0x1_staking_config_get">staking_config::get</a>();

    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    <b>let</b> old_locked_until_secs = stake_pool.locked_until_secs;
    <b>let</b> new_locked_until_secs = <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>() + <a href="staking_config.md#0x1_staking_config_get_recurring_lockup_duration">staking_config::get_recurring_lockup_duration</a>(&config);
    <b>assert</b>!(old_locked_until_secs &lt; new_locked_until_secs, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_EINVALID_LOCKUP">EINVALID_LOCKUP</a>));
    stake_pool.locked_until_secs = new_locked_until_secs;

    <a href="event.md#0x1_event_emit">event::emit</a>(
        <a href="stake.md#0x1_stake_IncreaseLockupEvent">IncreaseLockupEvent</a> {
            pool_address,
            old_locked_until_secs,
            new_locked_until_secs,
        },
    );
}
</code></pre>



</details>

<a id="0x1_stake_join_validator_set"></a>

## Function `join_validator_set`

This can only called by the operator of the validator/staking pool.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_join_validator_set">join_validator_set</a>(operator: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, pool_address: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_join_validator_set">join_validator_set</a>(
    operator: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    pool_address: <b>address</b>
) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <b>assert</b>!(
        <a href="staking_config.md#0x1_staking_config_get_allow_validator_set_change">staking_config::get_allow_validator_set_change</a>(&<a href="staking_config.md#0x1_staking_config_get">staking_config::get</a>()),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED">ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED</a>),
    );

    <a href="stake.md#0x1_stake_join_validator_set_internal">join_validator_set_internal</a>(operator, pool_address);
}
</code></pre>



</details>

<a id="0x1_stake_join_validator_set_internal"></a>

## Function `join_validator_set_internal`

Request to have <code>pool_address</code> join the validator set. Can only be called after calling <code>initialize_validator</code>.
If the validator has the required stake (more than minimum and less than maximum allowed), they will be
added to the pending_active queue. All validators in this queue will be added to the active set when the next
epoch starts (eligibility will be rechecked).

This internal version can only be called by the Genesis module during Genesis.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_join_validator_set_internal">join_validator_set_internal</a>(operator: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, pool_address: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_join_validator_set_internal">join_validator_set_internal</a>(
    operator: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    pool_address: <b>address</b>
) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(operator) == stake_pool.operator_address, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_unauthenticated">error::unauthenticated</a>(<a href="stake.md#0x1_stake_ENOT_OPERATOR">ENOT_OPERATOR</a>));
    <b>assert</b>!(
        <a href="stake.md#0x1_stake_get_validator_state">get_validator_state</a>(pool_address) == <a href="stake.md#0x1_stake_VALIDATOR_STATUS_INACTIVE">VALIDATOR_STATUS_INACTIVE</a>,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="stake.md#0x1_stake_EALREADY_ACTIVE_VALIDATOR">EALREADY_ACTIVE_VALIDATOR</a>),
    );

    <b>let</b> config = <a href="staking_config.md#0x1_staking_config_get">staking_config::get</a>();
    <b>let</b> (minimum_stake, maximum_stake) = <a href="staking_config.md#0x1_staking_config_get_required_stake">staking_config::get_required_stake</a>(&config);
    <b>let</b> voting_power = <a href="stake.md#0x1_stake_get_next_epoch_voting_power">get_next_epoch_voting_power</a>(stake_pool);
    <b>assert</b>!(voting_power &gt;= minimum_stake, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_ESTAKE_TOO_LOW">ESTAKE_TOO_LOW</a>));
    <b>assert</b>!(voting_power &lt;= maximum_stake, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_ESTAKE_TOO_HIGH">ESTAKE_TOO_HIGH</a>));

    // Track and validate <a href="voting.md#0x1_voting">voting</a> power increase.
    <a href="stake.md#0x1_stake_update_voting_power_increase">update_voting_power_increase</a>(voting_power);

    // Add validator <b>to</b> pending_active, <b>to</b> be activated in the next epoch.
    <b>let</b> validator_config = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(pool_address);
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&validator_config.consensus_pubkey), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_EINVALID_PUBLIC_KEY">EINVALID_PUBLIC_KEY</a>));

    // Validate the current validator set size <b>has</b> not exceeded the limit.
    <b>let</b> validator_set = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>&gt;(@endless_framework);
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> validator_set.pending_active, <a href="stake.md#0x1_stake_generate_validator_info">generate_validator_info</a>(pool_address, stake_pool, *validator_config));
    <b>let</b> validator_set_size = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&validator_set.active_validators) + <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&validator_set.pending_active);
    <b>assert</b>!(validator_set_size &lt;= <a href="stake.md#0x1_stake_MAX_VALIDATOR_SET_SIZE">MAX_VALIDATOR_SET_SIZE</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_EVALIDATOR_SET_TOO_LARGE">EVALIDATOR_SET_TOO_LARGE</a>));

    <a href="event.md#0x1_event_emit">event::emit</a>(
        <a href="stake.md#0x1_stake_JoinValidatorSetEvent">JoinValidatorSetEvent</a> { pool_address },
    );
}
</code></pre>



</details>

<a id="0x1_stake_unlock"></a>

## Function `unlock`

Similar to unlock_with_cap but will use ownership capability from the signing account.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_unlock">unlock</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_unlock">unlock</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, amount: u128) <b>acquires</b> <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    <b>let</b> owner_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner);
    <a href="stake.md#0x1_stake_assert_owner_cap_exists">assert_owner_cap_exists</a>(owner_address);
    <b>let</b> ownership_cap = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>&gt;(owner_address);
    <a href="stake.md#0x1_stake_unlock_with_cap">unlock_with_cap</a>(amount, ownership_cap);
}
</code></pre>



</details>

<a id="0x1_stake_unlock_with_cap"></a>

## Function `unlock_with_cap`

Unlock <code>amount</code> from the active stake. Only possible if the lockup has expired.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_unlock_with_cap">unlock_with_cap</a>(amount: u128, owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_unlock_with_cap">unlock_with_cap</a>(amount: u128, owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    // Short-circuit <b>if</b> amount <b>to</b> unlock is 0 so we don't emit events.
    <b>if</b> (amount == 0) {
        <b>return</b>
    };

    // Unlocked coins are moved <b>to</b> pending_inactive. When the current lockup cycle expires, they will be moved into
    // inactive in the earliest possible epoch transition.
    <b>let</b> pool_address = owner_cap.pool_address;
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    // Cap amount <b>to</b> unlock by maximum active <a href="stake.md#0x1_stake">stake</a>.
    <b>let</b> amount = <b>min</b>(amount, stake_pool.active);
    stake_pool.active = stake_pool.active - amount;
    stake_pool.pending_inactive = stake_pool.pending_inactive + amount;

    <a href="event.md#0x1_event_emit">event::emit</a>(
        <a href="stake.md#0x1_stake_UnlockStakeEvent">UnlockStakeEvent</a> {
            pool_address,
            amount_unlocked: amount,
        },
    );
}
</code></pre>



</details>

<a id="0x1_stake_withdraw"></a>

## Function `withdraw`

Withdraw from <code><a href="account.md#0x1_account">account</a></code>'s inactive stake.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_withdraw">withdraw</a>(owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, withdraw_amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_withdraw">withdraw</a>(
    owner: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    withdraw_amount: u128
) <b>acquires</b> <a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>, <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>, <a href="stake.md#0x1_stake_EndlessCoinCapabilities">EndlessCoinCapabilities</a> {
    <b>let</b> owner_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(owner);
    <a href="stake.md#0x1_stake_assert_owner_cap_exists">assert_owner_cap_exists</a>(owner_address);
    <b>let</b> ownership_cap = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>&gt;(owner_address);
    <b>let</b> fa = <a href="stake.md#0x1_stake_withdraw_with_cap">withdraw_with_cap</a>(ownership_cap, withdraw_amount);
    <b>let</b> store = <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(owner_address, <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>());
    <a href="fungible_asset.md#0x1_fungible_asset_deposit">fungible_asset::deposit</a>&lt;FungibleStore&gt;(store, fa);
}
</code></pre>



</details>

<a id="0x1_stake_withdraw_with_cap"></a>

## Function `withdraw_with_cap`

Withdraw from <code>pool_address</code>'s inactive stake with the corresponding <code>owner_cap</code>.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_withdraw_with_cap">withdraw_with_cap</a>(owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">stake::OwnerCapability</a>, withdraw_amount: u128): <a href="fungible_asset.md#0x1_fungible_asset_FungibleAsset">fungible_asset::FungibleAsset</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_withdraw_with_cap">withdraw_with_cap</a>(
    owner_cap: &<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>,
    withdraw_amount: u128
): FungibleAsset <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>, <a href="stake.md#0x1_stake_EndlessCoinCapabilities">EndlessCoinCapabilities</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    <b>let</b> pool_address = owner_cap.pool_address;
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    // There's an edge case <b>where</b> a validator unlocks their <a href="stake.md#0x1_stake">stake</a> and leaves the validator set before
    // the <a href="stake.md#0x1_stake">stake</a> is fully unlocked (the current lockup cycle <b>has</b> not expired yet).
    // This can leave their <a href="stake.md#0x1_stake">stake</a> stuck in pending_inactive even after the current lockup cycle expires.
    // ???? WTF
    <b>if</b> (<a href="stake.md#0x1_stake_get_validator_state">get_validator_state</a>(pool_address) == <a href="stake.md#0x1_stake_VALIDATOR_STATUS_INACTIVE">VALIDATOR_STATUS_INACTIVE</a> &&
        <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>() &gt;= stake_pool.locked_until_secs) {
        <b>let</b> pending_inactive_stake = stake_pool.pending_inactive;
        stake_pool.pending_inactive = 0;
        stake_pool.inactive = stake_pool.inactive + pending_inactive_stake;
    };

    // Cap withdraw amount by total inactive coins.
    <b>let</b> new_withdraw_amount = <b>min</b>(withdraw_amount, stake_pool.inactive);
    <b>let</b> meta = <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>();
    <b>if</b> (new_withdraw_amount == 0) <b>return</b> <a href="fungible_asset.md#0x1_fungible_asset_zero">fungible_asset::zero</a>&lt;Metadata&gt;(meta);

    <b>let</b> store = <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(@endless_framework, <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>());
    <b>let</b> transfer_cap = &<b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(@endless_framework).transfer_cap;

    <b>let</b> fa = <a href="fungible_asset.md#0x1_fungible_asset_withdraw_with_ref">fungible_asset::withdraw_with_ref</a>(transfer_cap, store, new_withdraw_amount);
    stake_pool.inactive = stake_pool.inactive - new_withdraw_amount;

    <a href="event.md#0x1_event_emit">event::emit</a>(
        <a href="stake.md#0x1_stake_WithdrawStakeEvent">WithdrawStakeEvent</a> {
            pool_address,
            amount_withdrawn: new_withdraw_amount,
        },
    );
    fa
}
</code></pre>



</details>

<a id="0x1_stake_leave_validator_set"></a>

## Function `leave_validator_set`

Request to have <code>pool_address</code> leave the validator set. The validator is only actually removed from the set when
the next epoch starts.
The last validator in the set cannot leave. This is an edge case that should never happen as long as the network
is still operational.

Can only be called by the operator of the validator/staking pool.


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_leave_validator_set">leave_validator_set</a>(operator: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, pool_address: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="stake.md#0x1_stake_leave_validator_set">leave_validator_set</a>(
    operator: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    pool_address: <b>address</b>
) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>();
    <b>let</b> config = <a href="staking_config.md#0x1_staking_config_get">staking_config::get</a>();
    <b>assert</b>!(
        <a href="staking_config.md#0x1_staking_config_get_allow_validator_set_change">staking_config::get_allow_validator_set_change</a>(&config),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED">ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED</a>),
    );

    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    // Account <b>has</b> <b>to</b> be the operator.
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(operator) == stake_pool.operator_address, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_unauthenticated">error::unauthenticated</a>(<a href="stake.md#0x1_stake_ENOT_OPERATOR">ENOT_OPERATOR</a>));

    <b>let</b> validator_set = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>&gt;(@endless_framework);
    // If the validator is still pending_active, directly kick the validator out.
    <b>let</b> maybe_pending_active_index = <a href="stake.md#0x1_stake_find_validator">find_validator</a>(&validator_set.pending_active, pool_address);
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&maybe_pending_active_index)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_swap_remove">vector::swap_remove</a>(
            &<b>mut</b> validator_set.pending_active, <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_extract">option::extract</a>(&<b>mut</b> maybe_pending_active_index));

        // Decrease the <a href="voting.md#0x1_voting">voting</a> power increase <b>as</b> the pending validator's <a href="voting.md#0x1_voting">voting</a> power was added when they requested
        // <b>to</b> join. Now that they changed their mind, their <a href="voting.md#0x1_voting">voting</a> power should not affect the joining limit of this
        // epoch.
        <b>let</b> validator_stake = (<a href="stake.md#0x1_stake_get_next_epoch_voting_power">get_next_epoch_voting_power</a>(stake_pool) <b>as</b> u128);
        // total_joining_power should be larger than validator_stake but just in case there <b>has</b> been a small
        // rounding <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">error</a> somewhere that can lead <b>to</b> an underflow, we still want <b>to</b> allow this transaction <b>to</b>
        // succeed.
        <b>if</b> (validator_set.total_joining_power &gt; validator_stake) {
            validator_set.total_joining_power = validator_set.total_joining_power - validator_stake;
        } <b>else</b> {
            validator_set.total_joining_power = 0;
        };
    } <b>else</b> {
        // Validate that the validator is already part of the validator set.
        <b>let</b> maybe_active_index = <a href="stake.md#0x1_stake_find_validator">find_validator</a>(&validator_set.active_validators, pool_address);
        <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&maybe_active_index), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="stake.md#0x1_stake_ENOT_VALIDATOR">ENOT_VALIDATOR</a>));
        <b>let</b> validator_info = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_swap_remove">vector::swap_remove</a>(
            &<b>mut</b> validator_set.active_validators, <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_extract">option::extract</a>(&<b>mut</b> maybe_active_index));
        <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&validator_set.active_validators) &gt; 0, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="stake.md#0x1_stake_ELAST_VALIDATOR">ELAST_VALIDATOR</a>));
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> validator_set.pending_inactive, validator_info);

        <a href="event.md#0x1_event_emit">event::emit</a>(
            <a href="stake.md#0x1_stake_LeaveValidatorSetEvent">LeaveValidatorSetEvent</a> {
                pool_address,
            },
        );
    };
}
</code></pre>



</details>

<a id="0x1_stake_is_current_epoch_validator"></a>

## Function `is_current_epoch_validator`

Returns true if the current validator can still vote in the current epoch.
This includes validators that requested to leave but are still in the pending_inactive queue and will be removed
when the epoch starts.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_is_current_epoch_validator">is_current_epoch_validator</a>(pool_address: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_is_current_epoch_validator">is_current_epoch_validator</a>(pool_address: <b>address</b>): bool <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address);
    <b>let</b> validator_state = <a href="stake.md#0x1_stake_get_validator_state">get_validator_state</a>(pool_address);
    validator_state == <a href="stake.md#0x1_stake_VALIDATOR_STATUS_ACTIVE">VALIDATOR_STATUS_ACTIVE</a> || validator_state == <a href="stake.md#0x1_stake_VALIDATOR_STATUS_PENDING_INACTIVE">VALIDATOR_STATUS_PENDING_INACTIVE</a>
}
</code></pre>



</details>

<a id="0x1_stake_update_performance_statistics"></a>

## Function `update_performance_statistics`

Update the validator performance (proposal statistics). This is only called by block::prologue().
This function cannot abort.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_update_performance_statistics">update_performance_statistics</a>(proposer_index: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;, failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_update_performance_statistics">update_performance_statistics</a>(proposer_index: Option&lt;u64&gt;, failed_proposer_indices: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;) <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a> {
    // Validator set cannot change until the end of the epoch, so the validator index in arguments should
    // match <b>with</b> those of the validators in <a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a> resource.
    <b>let</b> validator_perf = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a>&gt;(@endless_framework);
    <b>let</b> validator_len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&validator_perf.validators);

    // proposer_index is an <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option">option</a> because it can be missing (for NilBlocks)
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&proposer_index)) {
        <b>let</b> cur_proposer_index = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_extract">option::extract</a>(&<b>mut</b> proposer_index);
        // Here, and in all other <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>, skip <a href="../../endless-stdlib/doc/any.md#0x1_any">any</a> validator indices that are out of bounds,
        // this <b>ensures</b> that this function doesn't <b>abort</b> <b>if</b> there are out of bounds errors.
        <b>if</b> (cur_proposer_index &lt; validator_len) {
            <b>let</b> validator = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow_mut">vector::borrow_mut</a>(&<b>mut</b> validator_perf.validators, cur_proposer_index);
            validator.successful_proposals = validator.successful_proposals + 1;
        };
    };

    <b>let</b> f = 0;
    <b>let</b> f_len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&failed_proposer_indices);
    <b>while</b> ({
        f &lt; f_len
    }) {
        <b>let</b> validator_index = *<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&failed_proposer_indices, f);
        <b>if</b> (validator_index &lt; validator_len) {
            <b>let</b> validator = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow_mut">vector::borrow_mut</a>(&<b>mut</b> validator_perf.validators, validator_index);
            validator.failed_proposals = validator.failed_proposals + 1;
        };
        f = f + 1;
    };
}
</code></pre>



</details>

<a id="0x1_stake_on_new_epoch"></a>

## Function `on_new_epoch`

Triggered during a reconfiguration. This function shouldn't abort.

1. Distribute transaction fees and rewards to stake pools of active and pending inactive validators (requested
to leave but not yet removed).
2. Officially move pending active stake to active and move pending inactive stake to inactive.
The staking pool's voting power in this new epoch will be updated to the total active stake.
3. Add pending active validators to the active set if they satisfy requirements so they can vote and remove
pending inactive validators so they no longer can vote.
4. The validator's voting power in the validator set is updated to be the corresponding staking pool's voting
power.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_on_new_epoch">on_new_epoch</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x1_stake_on_new_epoch">on_new_epoch</a>() <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_EndlessCoinCapabilities">EndlessCoinCapabilities</a>, <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>, <a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a>, <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>, <a href="stake.md#0x1_stake_ValidatorFees">ValidatorFees</a>, <a href="stake.md#0x1_stake_BlockRewardShareInfo">BlockRewardShareInfo</a> {
    <b>let</b> validator_set = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>&gt;(@endless_framework);
    <b>let</b> config = <a href="staking_config.md#0x1_staking_config_get">staking_config::get</a>();
    <b>let</b> validator_perf = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a>&gt;(@endless_framework);

    <b>let</b> total_stake_amount = 0;
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&validator_set.active_validators, |validator| {
        <b>let</b> validator: &<a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> = validator;
        <b>let</b> stake_pool = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(validator.addr);
        // total_stake_amount = total_stake_amount + stake_pool.active + stake_pool.pending_active + stake_pool.pending_inactive;
        total_stake_amount = total_stake_amount + stake_pool.active + stake_pool.pending_inactive;
    });
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&validator_set.pending_inactive, |validator| {
        <b>let</b> validator: &<a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> = validator;
        <b>let</b> stake_pool = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(validator.addr);
        // total_stake_amount = total_stake_amount + stake_pool.active + stake_pool.pending_active + stake_pool.pending_inactive;
        total_stake_amount = total_stake_amount + stake_pool.active + stake_pool.pending_inactive;
    });

    <b>let</b> eds_total_supply = <a href="endless_coin.md#0x1_endless_coin_supply">endless_coin::supply</a>();

    // Process pending <a href="stake.md#0x1_stake">stake</a> and distribute transaction fees and rewards for each currently active validator.
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&validator_set.active_validators, |validator| {
        <b>let</b> validator: &<a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> = validator;
        <a href="stake.md#0x1_stake_update_stake_pool">update_stake_pool</a>(validator_perf, validator.addr, &config, total_stake_amount, eds_total_supply);
    });

    // Process pending <a href="stake.md#0x1_stake">stake</a> and distribute transaction fees and rewards for each currently pending_inactive validator
    // (requested <b>to</b> leave but not removed yet).
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&validator_set.pending_inactive, |validator| {
        <b>let</b> validator: &<a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> = validator;
        <a href="stake.md#0x1_stake_update_stake_pool">update_stake_pool</a>(validator_perf, validator.addr, &config, total_stake_amount, eds_total_supply);
    });

    // Activate currently pending_active validators.
    <a href="stake.md#0x1_stake_append">append</a>(&<b>mut</b> validator_set.active_validators, &<b>mut</b> validator_set.pending_active);

    // Officially deactivate all pending_inactive validators. They will now no longer receive rewards.
    validator_set.pending_inactive = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();

    // Update active validator set so that network <b>address</b>/<b>public</b> key change takes effect.
    // Moreover, recalculate the total <a href="voting.md#0x1_voting">voting</a> power, and deactivate the validator whose
    // <a href="voting.md#0x1_voting">voting</a> power is less than the minimum required <a href="stake.md#0x1_stake">stake</a>.
    <b>let</b> next_epoch_validators = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();
    <b>let</b> (minimum_stake, _) = <a href="staking_config.md#0x1_staking_config_get_required_stake">staking_config::get_required_stake</a>(&config);
    <b>let</b> vlen = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&validator_set.active_validators);
    <b>let</b> total_voting_power = 0;
    <b>let</b> i = 0;
    <b>while</b> ({
        i &lt; vlen
    }) {
        <b>let</b> old_validator_info = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow_mut">vector::borrow_mut</a>(&<b>mut</b> validator_set.active_validators, i);
        <b>let</b> pool_address = old_validator_info.addr;
        <b>let</b> validator_config = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(pool_address);
        <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
        <b>let</b> new_validator_info = <a href="stake.md#0x1_stake_generate_validator_info">generate_validator_info</a>(pool_address, stake_pool, *validator_config);

        // A validator needs at least the <b>min</b> <a href="stake.md#0x1_stake">stake</a> required <b>to</b> join the validator set.
        <b>if</b> (new_validator_info.voting_power &gt;= minimum_stake) {
            total_voting_power = total_voting_power + (new_validator_info.voting_power <b>as</b> u128);
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> next_epoch_validators, new_validator_info);
        };
        i = i + 1;
    };

    validator_set.active_validators = next_epoch_validators;
    validator_set.total_voting_power = total_voting_power;
    validator_set.total_joining_power = 0;

    // Update validator indices, reset performance scores, and renew lockups.
    validator_perf.validators = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();
    <b>let</b> recurring_lockup_duration_secs = <a href="staking_config.md#0x1_staking_config_get_recurring_lockup_duration">staking_config::get_recurring_lockup_duration</a>(&config);
    <b>let</b> vlen = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&validator_set.active_validators);
    <b>let</b> validator_index = 0;
    <b>while</b> ({
        validator_index &lt; vlen
    }) {
        <b>let</b> validator_info = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow_mut">vector::borrow_mut</a>(&<b>mut</b> validator_set.active_validators, validator_index);
        validator_info.config.validator_index = validator_index;
        <b>let</b> validator_config = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(validator_info.addr);
        validator_config.validator_index = validator_index;

        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> validator_perf.validators, <a href="stake.md#0x1_stake_IndividualValidatorPerformance">IndividualValidatorPerformance</a> {
            successful_proposals: 0,
            failed_proposals: 0,
        });

        // Automatically renew a validator's lockup for validators that will still be in the validator set in the
        // next epoch.
        <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(validator_info.addr);
        <b>let</b> now_secs = <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>();
        <b>let</b> reconfig_start_secs = <b>if</b> (<a href="chain_status.md#0x1_chain_status_is_operating">chain_status::is_operating</a>()) {
            <a href="stake.md#0x1_stake_get_reconfig_start_time_secs">get_reconfig_start_time_secs</a>()
        } <b>else</b> {
            now_secs
        };
        <b>if</b> (stake_pool.locked_until_secs &lt;= reconfig_start_secs) {
            stake_pool.locked_until_secs = now_secs + recurring_lockup_duration_secs;
        };

        validator_index = validator_index + 1;
    };

    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_periodical_reward_rate_decrease_enabled">features::periodical_reward_rate_decrease_enabled</a>()) {
        // Update rewards rate after reward distribution.
        <a href="staking_config.md#0x1_staking_config_calculate_and_save_latest_epoch_rewards_rate">staking_config::calculate_and_save_latest_epoch_rewards_rate</a>();
    };
}
</code></pre>



</details>

<a id="0x1_stake_cur_validator_consensus_infos"></a>

## Function `cur_validator_consensus_infos`

Return the <code>ValidatorConsensusInfo</code> of each current validator, sorted by current validator index.


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_cur_validator_consensus_infos">cur_validator_consensus_infos</a>(): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="validator_consensus_info.md#0x1_validator_consensus_info_ValidatorConsensusInfo">validator_consensus_info::ValidatorConsensusInfo</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_cur_validator_consensus_infos">cur_validator_consensus_infos</a>(): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;ValidatorConsensusInfo&gt; <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <b>let</b> validator_set = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>&gt;(@endless_framework);
    <a href="stake.md#0x1_stake_validator_consensus_infos_from_validator_set">validator_consensus_infos_from_validator_set</a>(validator_set)
}
</code></pre>



</details>

<a id="0x1_stake_next_validator_consensus_infos"></a>

## Function `next_validator_consensus_infos`

TODO: check total_stake_amount


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_next_validator_consensus_infos">next_validator_consensus_infos</a>(): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="validator_consensus_info.md#0x1_validator_consensus_info_ValidatorConsensusInfo">validator_consensus_info::ValidatorConsensusInfo</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_next_validator_consensus_infos">next_validator_consensus_infos</a>(): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;ValidatorConsensusInfo&gt; <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>, <a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a>, <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_ValidatorFees">ValidatorFees</a>, <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a> {
    // Init.
    <b>let</b> cur_validator_set = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>&gt;(@endless_framework);
    <b>let</b> <a href="staking_config.md#0x1_staking_config">staking_config</a> = <a href="staking_config.md#0x1_staking_config_get">staking_config::get</a>();
    <b>let</b> validator_perf = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a>&gt;(@endless_framework);
    <b>let</b> (minimum_stake, _) = <a href="staking_config.md#0x1_staking_config_get_required_stake">staking_config::get_required_stake</a>(&<a href="staking_config.md#0x1_staking_config">staking_config</a>);
    <b>let</b> (rewards_rate, rewards_rate_denominator) = <a href="staking_config.md#0x1_staking_config_get_reward_rate">staking_config::get_reward_rate</a>(&<a href="staking_config.md#0x1_staking_config">staking_config</a>);

    // Compute new validator set.
    <b>let</b> new_active_validators = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[];
    <b>let</b> num_new_actives = 0;
    <b>let</b> new_total_power = 0;
    <b>let</b> num_cur_actives = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&cur_validator_set.active_validators);
    <b>let</b> num_cur_pending_actives = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&cur_validator_set.pending_active);
    <b>let</b> num_cur_pending_inactives = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&cur_validator_set.pending_inactive);
    <b>let</b> num_candidates = num_cur_actives + num_cur_pending_actives;

    <b>let</b> total_stake_amount = 0;
    <b>let</b> i = 0;
    <b>while</b> (i &lt; num_cur_actives) {
        <b>let</b> candidate = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&cur_validator_set.active_validators, i);
        <b>let</b> stake_pool = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(candidate.addr);
        total_stake_amount = total_stake_amount + stake_pool.active + stake_pool.pending_active + stake_pool.pending_inactive;
        i = i + 1;
    };

    <b>let</b> i = 0;
    <b>while</b> (i &lt; num_cur_pending_inactives) {
        <b>let</b> candidate = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&cur_validator_set.pending_inactive, i);
        <b>if</b> (!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_contains">vector::contains</a>(&cur_validator_set.active_validators, candidate)) {
            <b>let</b> stake_pool = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(candidate.addr);
            total_stake_amount = total_stake_amount + stake_pool.active + stake_pool.pending_active + stake_pool.pending_inactive;
        };
        i = i + 1;
    };

    <b>let</b> eds_total_supply = <a href="endless_coin.md#0x1_endless_coin_supply">endless_coin::supply</a>();

    <b>let</b> candidate_idx = 0;
    <b>while</b> ({
        candidate_idx &lt; num_candidates
    }) {
        <b>let</b> candidate_in_current_validator_set = candidate_idx &lt; num_cur_actives;
        <b>let</b> candidate = <b>if</b> (candidate_idx &lt; num_cur_actives) {
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&cur_validator_set.active_validators, candidate_idx)
        } <b>else</b> {
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&cur_validator_set.pending_active, candidate_idx - num_cur_actives)
        };
        <b>let</b> stake_pool = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(candidate.addr);
        <b>let</b> cur_active = stake_pool.active;
        <b>let</b> cur_pending_active = stake_pool.pending_active;
        <b>let</b> cur_pending_inactive = stake_pool.pending_inactive;

        <b>let</b> cur_reward = <b>if</b> (candidate_in_current_validator_set && cur_active &gt; 0) {
            <b>let</b> cur_perf = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&validator_perf.validators, candidate.config.validator_index);
            <a href="stake.md#0x1_stake_calculate_rewards_amount">calculate_rewards_amount</a>(cur_active, total_stake_amount,
                cur_perf.successful_proposals, cur_perf.successful_proposals + cur_perf.failed_proposals,
                rewards_rate, rewards_rate_denominator, eds_total_supply)
        } <b>else</b> {
            0
        };

        <b>let</b> cur_fee = 0_u128;
        <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_collect_and_distribute_gas_fees">features::collect_and_distribute_gas_fees</a>()) {
            <b>let</b> fees_table = &<b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_ValidatorFees">ValidatorFees</a>&gt;(@endless_framework).fees_table;
            <b>if</b> (<a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(fees_table, candidate.addr)) {
                <b>let</b> fee_coin = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow">table::borrow</a>(fees_table, candidate.addr);
                cur_fee = *fee_coin;
            }
        };

        <b>let</b> lockup_expired = <a href="stake.md#0x1_stake_get_reconfig_start_time_secs">get_reconfig_start_time_secs</a>() &gt;= stake_pool.locked_until_secs;
        <b>let</b> new_voting_power =
            cur_active
            + <b>if</b> (lockup_expired) { 0 } <b>else</b> { cur_pending_inactive }
            + cur_pending_active
            + cur_reward + cur_fee;

        <b>if</b> (new_voting_power &gt;= minimum_stake) {
            <b>let</b> config = *<b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(candidate.addr);
            config.validator_index = num_new_actives;
            <b>let</b> new_validator_info = <a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> {
                addr: candidate.addr,
                voting_power: new_voting_power,
                config,
            };

            // Update <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>.
            new_total_power = new_total_power + (new_voting_power <b>as</b> u128);
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> new_active_validators, new_validator_info);
            num_new_actives = num_new_actives + 1;

        };
        candidate_idx = candidate_idx + 1;
    };

    <b>let</b> new_validator_set = <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
        consensus_scheme: cur_validator_set.consensus_scheme,
        active_validators: new_active_validators,
        pending_inactive: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[],
        pending_active: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[],
        total_voting_power: new_total_power,
        total_joining_power: 0,
    };

    <a href="stake.md#0x1_stake_validator_consensus_infos_from_validator_set">validator_consensus_infos_from_validator_set</a>(&new_validator_set)
}
</code></pre>



</details>

<a id="0x1_stake_validator_consensus_infos_from_validator_set"></a>

## Function `validator_consensus_infos_from_validator_set`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_validator_consensus_infos_from_validator_set">validator_consensus_infos_from_validator_set</a>(validator_set: &<a href="stake.md#0x1_stake_ValidatorSet">stake::ValidatorSet</a>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="validator_consensus_info.md#0x1_validator_consensus_info_ValidatorConsensusInfo">validator_consensus_info::ValidatorConsensusInfo</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_validator_consensus_infos_from_validator_set">validator_consensus_infos_from_validator_set</a>(validator_set: &<a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;ValidatorConsensusInfo&gt; {
    <b>let</b> validator_consensus_infos = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[];

    <b>let</b> num_active = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&validator_set.active_validators);
    <b>let</b> num_pending_inactive = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&validator_set.pending_inactive);
    <b>let</b> total = num_active + num_pending_inactive;

    // Pre-fill the <b>return</b> value <b>with</b> dummy values.
    <b>let</b> idx = 0;
    <b>while</b> ({
        idx &lt; total
    }) {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> validator_consensus_infos, <a href="validator_consensus_info.md#0x1_validator_consensus_info_default">validator_consensus_info::default</a>());
        idx = idx + 1;
    };


    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&validator_set.active_validators, |obj| {
        <b>let</b> vi: &<a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> = obj;

        <b>let</b> vci = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow_mut">vector::borrow_mut</a>(&<b>mut</b> validator_consensus_infos, vi.config.validator_index);
        *vci = <a href="validator_consensus_info.md#0x1_validator_consensus_info_new">validator_consensus_info::new</a>(
            vi.addr,
            vi.config.consensus_pubkey,
            vi.voting_power
        );
    });

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&validator_set.pending_inactive, |obj| {
        <b>let</b> vi: &<a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> = obj;

        <b>let</b> vci = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow_mut">vector::borrow_mut</a>(&<b>mut</b> validator_consensus_infos, vi.config.validator_index);
        *vci = <a href="validator_consensus_info.md#0x1_validator_consensus_info_new">validator_consensus_info::new</a>(
            vi.addr,
            vi.config.consensus_pubkey,
            vi.voting_power
        );
    });

    validator_consensus_infos
}
</code></pre>



</details>

<a id="0x1_stake_addresses_from_validator_infos"></a>

## Function `addresses_from_validator_infos`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_addresses_from_validator_infos">addresses_from_validator_infos</a>(infos: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_ValidatorInfo">stake::ValidatorInfo</a>&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_addresses_from_validator_infos">addresses_from_validator_infos</a>(infos: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a>&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt; {
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_map_ref">vector::map_ref</a>(infos, |obj| {
        <b>let</b> info: &<a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> = obj;
        info.addr
    })
}
</code></pre>



</details>

<a id="0x1_stake_update_stake_pool"></a>

## Function `update_stake_pool`

Calculate the stake amount of a stake pool for the next epoch.
Update individual validator's stake pool if <code>commit == <b>true</b></code>.

1. distribute transaction fees to active/pending_inactive delegations
2. distribute rewards to active/pending_inactive delegations
3. process pending_active, pending_inactive correspondingly
This function shouldn't abort.


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_update_stake_pool">update_stake_pool</a>(validator_perf: &<a href="stake.md#0x1_stake_ValidatorPerformance">stake::ValidatorPerformance</a>, pool_address: <b>address</b>, <a href="staking_config.md#0x1_staking_config">staking_config</a>: &<a href="staking_config.md#0x1_staking_config_StakingConfig">staking_config::StakingConfig</a>, total_stake_amount: u128, eds_total_supply: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_update_stake_pool">update_stake_pool</a>(
    validator_perf: &<a href="stake.md#0x1_stake_ValidatorPerformance">ValidatorPerformance</a>,
    pool_address: <b>address</b>,
    <a href="staking_config.md#0x1_staking_config">staking_config</a>: &StakingConfig,
    total_stake_amount: u128,
    eds_total_supply: u128,
) <b>acquires</b> <a href="stake.md#0x1_stake_StakePool">StakePool</a>, <a href="stake.md#0x1_stake_EndlessCoinCapabilities">EndlessCoinCapabilities</a>, <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>, <a href="stake.md#0x1_stake_ValidatorFees">ValidatorFees</a>, <a href="stake.md#0x1_stake_BlockRewardShareInfo">BlockRewardShareInfo</a> {
    <b>let</b> stake_pool = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_StakePool">StakePool</a>&gt;(pool_address);
    <b>let</b> validator_config = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>&gt;(pool_address);
    <b>let</b> cur_validator_perf = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&validator_perf.validators, validator_config.validator_index);
    <b>let</b> num_successful_proposals = cur_validator_perf.successful_proposals;
    <b>spec</b> {
        // The following addition should not overflow because `num_total_proposals` cannot be larger than 86400,
        // the maximum number of proposals in a day (1 proposal per second).
        <b>assume</b> cur_validator_perf.successful_proposals + cur_validator_perf.failed_proposals &lt;= <a href="stake.md#0x1_stake_MAX_U64">MAX_U64</a>;
    };
    <b>let</b> num_total_proposals = cur_validator_perf.successful_proposals + cur_validator_perf.failed_proposals;
    <b>let</b> (rewards_rate, rewards_rate_denominator) = <a href="staking_config.md#0x1_staking_config_get_reward_rate">staking_config::get_reward_rate</a>(<a href="staking_config.md#0x1_staking_config">staking_config</a>);

    <b>let</b> rewards_active = <a href="stake.md#0x1_stake_distribute_rewards">distribute_rewards</a>(
        &<b>mut</b> stake_pool.active,
        total_stake_amount,
        num_successful_proposals,
        num_total_proposals,
        rewards_rate,
        rewards_rate_denominator,
        eds_total_supply
    );
    <b>let</b> rewards_pending_inactive = <a href="stake.md#0x1_stake_distribute_rewards">distribute_rewards</a>(
        &<b>mut</b> stake_pool.pending_inactive,
        total_stake_amount,
        num_successful_proposals,
        num_total_proposals,
        rewards_rate,
        rewards_rate_denominator,
        eds_total_supply
    );
    <b>let</b> rewards_amount = rewards_active + rewards_pending_inactive;
    // Pending active <a href="stake.md#0x1_stake">stake</a> can now be active.
    stake_pool.active = stake_pool.active + stake_pool.pending_active;
    stake_pool.pending_active = 0;

    // Additionally, distribute transaction fees.
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_collect_and_distribute_gas_fees">features::collect_and_distribute_gas_fees</a>()) {
        <b>let</b> fees_table = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorFees">ValidatorFees</a>&gt;(@endless_framework).fees_table;
        <b>if</b> (<a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(fees_table, pool_address)) {
            <b>let</b> coin = <a href="../../endless-stdlib/doc/table.md#0x1_table_remove">table::remove</a>(fees_table, pool_address);
            stake_pool.active = stake_pool.active +  coin;
        };
    };

    // Pending inactive <a href="stake.md#0x1_stake">stake</a> is only fully unlocked and moved into inactive <b>if</b> the current lockup cycle <b>has</b> expired
    <b>let</b> current_lockup_expiration = stake_pool.locked_until_secs;
    <b>if</b> (<a href="stake.md#0x1_stake_get_reconfig_start_time_secs">get_reconfig_start_time_secs</a>() &gt;= current_lockup_expiration) {
        <b>let</b> all_pending_inactive = stake_pool.pending_inactive;
        stake_pool.pending_inactive = 0;
        stake_pool.inactive = stake_pool.inactive + all_pending_inactive;
    };

    <a href="event.md#0x1_event_emit">event::emit</a>(
        <a href="stake.md#0x1_stake_DistributeRewardsEvent">DistributeRewardsEvent</a> {
            pool_address,
            rewards_amount,
        },
    );
}
</code></pre>



</details>

<a id="0x1_stake_get_reconfig_start_time_secs"></a>

## Function `get_reconfig_start_time_secs`

Assuming we are in a middle of a reconfiguration (no matter it is immediate or async), get its start time.


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_get_reconfig_start_time_secs">get_reconfig_start_time_secs</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_get_reconfig_start_time_secs">get_reconfig_start_time_secs</a>(): u64 {
    <b>if</b> (<a href="reconfiguration_state.md#0x1_reconfiguration_state_is_initialized">reconfiguration_state::is_initialized</a>()) {
        <a href="reconfiguration_state.md#0x1_reconfiguration_state_start_time_secs">reconfiguration_state::start_time_secs</a>()
    } <b>else</b> {
        <a href="timestamp.md#0x1_timestamp_now_seconds">timestamp::now_seconds</a>()
    }
}
</code></pre>



</details>

<a id="0x1_stake_calculate_rewards_amount"></a>

## Function `calculate_rewards_amount`

Calculate the rewards amount.


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_calculate_rewards_amount">calculate_rewards_amount</a>(stake_amount: u128, all_stake_amount: u128, num_successful_proposals: u64, num_total_proposals: u64, rewards_rate: u64, rewards_rate_denominator: u64, total_supply: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_calculate_rewards_amount">calculate_rewards_amount</a>(
    stake_amount: u128,
    all_stake_amount: u128,
    num_successful_proposals: u64,
    num_total_proposals: u64,
    rewards_rate: u64,
    rewards_rate_denominator: u64,
    total_supply: u128,
): u128 {
    <b>spec</b> {
        // The following condition must hold because
        // (1) num_successful_proposals &lt;= num_total_proposals, and
        // (2) `num_total_proposals` cannot be larger than 86400, the maximum number of proposals
        //     in a day (1 proposal per second), and `num_total_proposals` is reset <b>to</b> 0 every epoch.
        <b>assume</b> num_successful_proposals * <a href="stake.md#0x1_stake_MAX_REWARDS_RATE">MAX_REWARDS_RATE</a> &lt;= <a href="stake.md#0x1_stake_MAX_U64">MAX_U64</a>;
    };

    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_eds_supply_inflation_enabled">features::eds_supply_inflation_enabled</a>()) {
        <b>let</b> rewards_numerator = (stake_amount <b>as</b> u128) * (rewards_rate <b>as</b> u128) * (num_successful_proposals <b>as</b> u128);
        <b>let</b> rewards_denominator = (all_stake_amount <b>as</b> u128) * (rewards_rate_denominator <b>as</b> u128) * (num_total_proposals <b>as</b> u128);
        <b>if</b> (rewards_denominator &gt; 0) {
            // The rewards amount is equal <b>to</b> (EDS_supply * rewards rate * (<a href="stake.md#0x1_stake">stake</a> amount/all_stake_amount) * performance multiplier).
            // We do multiplication in u128 before division <b>to</b> avoid the overflow and minimize the rounding <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">error</a>.
            <b>let</b> result = std::math128::mul_div(total_supply, (rewards_numerator <b>as</b> u128), (rewards_denominator <b>as</b> u128));

            <b>return</b> result
        };
    } <b>else</b> {
        // The rewards amount is equal <b>to</b> (<a href="stake.md#0x1_stake">stake</a> amount * rewards rate * performance multiplier).
        <b>let</b> rewards_numerator = (stake_amount <b>as</b> u128) * (rewards_rate <b>as</b> u128) * (num_successful_proposals <b>as</b> u128);
        <b>let</b> rewards_denominator = (rewards_rate_denominator <b>as</b> u128) * (num_total_proposals <b>as</b> u128);
        <b>if</b> (rewards_denominator &gt; 0) {
            <b>let</b> result = (rewards_numerator / rewards_denominator);
            <b>return</b> result
        };
    };

    <b>return</b> 0
}
</code></pre>



</details>

<a id="0x1_stake_distribute_rewards"></a>

## Function `distribute_rewards`

Mint rewards corresponding to current epoch's <code><a href="stake.md#0x1_stake">stake</a></code> and <code>num_successful_votes</code>.
split rewards into three parts, validator_reward, reward_of_a, reward_of_b

return validator reward


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_distribute_rewards">distribute_rewards</a>(<a href="stake.md#0x1_stake">stake</a>: &<b>mut</b> u128, total_stake_amount: u128, num_successful_proposals: u64, num_total_proposals: u64, rewards_rate: u64, rewards_rate_denominator: u64, eds_total_supply: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_distribute_rewards">distribute_rewards</a>(
    <a href="stake.md#0x1_stake">stake</a>: &<b>mut</b> u128,
    total_stake_amount: u128,
    num_successful_proposals: u64,
    num_total_proposals: u64,
    rewards_rate: u64,
    rewards_rate_denominator: u64,
    eds_total_supply: u128,
): u128 <b>acquires</b> <a href="stake.md#0x1_stake_EndlessCoinCapabilities">EndlessCoinCapabilities</a>, <a href="stake.md#0x1_stake_BlockRewardShareInfo">BlockRewardShareInfo</a> {
    <b>let</b> stake_amount = *<a href="stake.md#0x1_stake">stake</a>;
    <b>let</b> rewards_amount = <b>if</b> (stake_amount &gt; 0) {
        <a href="stake.md#0x1_stake_calculate_rewards_amount">calculate_rewards_amount</a>(stake_amount, total_stake_amount, num_successful_proposals, num_total_proposals, rewards_rate, rewards_rate_denominator, eds_total_supply)
    } <b>else</b> {
        0
    };

    <b>if</b> (rewards_amount &gt; 0) {
        <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_reward_split_enabled">features::reward_split_enabled</a>() && <b>exists</b>&lt;<a href="stake.md#0x1_stake_BlockRewardShareInfo">BlockRewardShareInfo</a>&gt;(@endless_framework)) {
            // split total_reward into three parts: [validator, other_accounts]
            <b>let</b> shares_info = &<b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_BlockRewardShareInfo">BlockRewardShareInfo</a>&gt;(@endless_framework).accounts;
            <b>let</b> acc_shares_sum = 0;

            <b>let</b> mint_cap = &<b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(@endless_framework).mint_cap;

            // mint for other accounts
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(shares_info, |<a href="account.md#0x1_account">account</a>|{
                <b>let</b> acc: &<a href="stake.md#0x1_stake_AccountShare">AccountShare</a> = <a href="account.md#0x1_account">account</a>;
                <b>let</b> reward_of_acc = <a href="../../endless-stdlib/doc/math128.md#0x1_math128_mul_div">math128::mul_div</a>(rewards_amount, (acc.percent <b>as</b> u128), (<a href="stake.md#0x1_stake_REWARD_DENOMINATOR">REWARD_DENOMINATOR</a> <b>as</b> u128));
                <b>let</b> fa = <a href="fungible_asset.md#0x1_fungible_asset_mint">fungible_asset::mint</a>(mint_cap, reward_of_acc);
                <b>let</b> acc_a_store = <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(acc.account_address, <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>());
                <a href="fungible_asset.md#0x1_fungible_asset_deposit">fungible_asset::deposit</a>&lt;FungibleStore&gt;(acc_a_store, fa);

                acc_shares_sum = acc_shares_sum + acc.percent;
            });

            // 100 - other_accounts_shares =&gt; validator share
            // initialize function guarantees other_accounts_shares cannot above 100%
            <b>let</b> validator_nominator = <a href="stake.md#0x1_stake_REWARD_DENOMINATOR">REWARD_DENOMINATOR</a> - acc_shares_sum;
            <b>let</b> validator_reward = <a href="../../endless-stdlib/doc/math128.md#0x1_math128_mul_div">math128::mul_div</a>(rewards_amount, (validator_nominator <b>as</b> u128), (<a href="stake.md#0x1_stake_REWARD_DENOMINATOR">REWARD_DENOMINATOR</a> <b>as</b> u128));

            <b>let</b> rewards = <a href="fungible_asset.md#0x1_fungible_asset_mint">fungible_asset::mint</a>(mint_cap, validator_reward);
            <a href="stake.md#0x1_stake_deposit_to_pool">deposit_to_pool</a>(rewards);
            *<a href="stake.md#0x1_stake">stake</a> = *<a href="stake.md#0x1_stake">stake</a> + validator_reward;

            validator_reward
        } <b>else</b> {
            <b>let</b> validator_reward = rewards_amount;
            <b>let</b> mint_cap = &<b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_EndlessCoinCapabilities">EndlessCoinCapabilities</a>&gt;(@endless_framework).mint_cap;
            <b>let</b> rewards = <a href="fungible_asset.md#0x1_fungible_asset_mint">fungible_asset::mint</a>(mint_cap, validator_reward);
            <a href="stake.md#0x1_stake_deposit_to_pool">deposit_to_pool</a>(rewards);
            *<a href="stake.md#0x1_stake">stake</a> = *<a href="stake.md#0x1_stake">stake</a> + validator_reward;

            validator_reward
        }
    } <b>else</b> {
        0
    }
}
</code></pre>



</details>

<a id="0x1_stake_append"></a>

## Function `append`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_append">append</a>&lt;T&gt;(v1: &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;T&gt;, v2: &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_append">append</a>&lt;T&gt;(v1: &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;T&gt;, v2: &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;T&gt;) {
    <b>while</b> (!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(v2)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(v1, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>(v2));
    }
}
</code></pre>



</details>

<a id="0x1_stake_find_validator"></a>

## Function `find_validator`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_find_validator">find_validator</a>(v: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_ValidatorInfo">stake::ValidatorInfo</a>&gt;, addr: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_find_validator">find_validator</a>(v: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a>&gt;, addr: <b>address</b>): Option&lt;u64&gt; {
    <b>let</b> i = 0;
    <b>let</b> len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(v);
    <b>while</b> ({
        i &lt; len
    }) {
        <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(v, i).addr == addr) {
            <b>return</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(i)
        };
        i = i + 1;
    };
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
}
</code></pre>



</details>

<a id="0x1_stake_generate_validator_info"></a>

## Function `generate_validator_info`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_generate_validator_info">generate_validator_info</a>(addr: <b>address</b>, stake_pool: &<a href="stake.md#0x1_stake_StakePool">stake::StakePool</a>, config: <a href="stake.md#0x1_stake_ValidatorConfig">stake::ValidatorConfig</a>): <a href="stake.md#0x1_stake_ValidatorInfo">stake::ValidatorInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_generate_validator_info">generate_validator_info</a>(addr: <b>address</b>, stake_pool: &<a href="stake.md#0x1_stake_StakePool">StakePool</a>, config: <a href="stake.md#0x1_stake_ValidatorConfig">ValidatorConfig</a>): <a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> {
    <b>let</b> voting_power = <a href="stake.md#0x1_stake_get_next_epoch_voting_power">get_next_epoch_voting_power</a>(stake_pool);
    <a href="stake.md#0x1_stake_ValidatorInfo">ValidatorInfo</a> {
        addr,
        voting_power,
        config,
    }
}
</code></pre>



</details>

<a id="0x1_stake_get_next_epoch_voting_power"></a>

## Function `get_next_epoch_voting_power`

Returns validator's next epoch voting power, including pending_active, active, and pending_inactive stake.


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_get_next_epoch_voting_power">get_next_epoch_voting_power</a>(stake_pool: &<a href="stake.md#0x1_stake_StakePool">stake::StakePool</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_get_next_epoch_voting_power">get_next_epoch_voting_power</a>(stake_pool: &<a href="stake.md#0x1_stake_StakePool">StakePool</a>): u128 {
    <b>let</b> value_pending_active = stake_pool.pending_active;
    <b>let</b> value_active = stake_pool.active;
    <b>let</b> value_pending_inactive = stake_pool.pending_inactive;
    value_pending_active + value_active + value_pending_inactive
}
</code></pre>



</details>

<a id="0x1_stake_update_voting_power_increase"></a>

## Function `update_voting_power_increase`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_update_voting_power_increase">update_voting_power_increase</a>(increase_amount: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_update_voting_power_increase">update_voting_power_increase</a>(increase_amount: u128) <b>acquires</b> <a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a> {
    <b>let</b> validator_set = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_ValidatorSet">ValidatorSet</a>&gt;(@endless_framework);
    <b>let</b> voting_power_increase_limit =
        (<a href="staking_config.md#0x1_staking_config_get_voting_power_increase_limit">staking_config::get_voting_power_increase_limit</a>(&<a href="staking_config.md#0x1_staking_config_get">staking_config::get</a>()) <b>as</b> u128);
    validator_set.total_joining_power = validator_set.total_joining_power + (increase_amount <b>as</b> u128);

    // Only validator <a href="voting.md#0x1_voting">voting</a> power increase <b>if</b> the current validator set's <a href="voting.md#0x1_voting">voting</a> power &gt; 0.
    <b>if</b> (validator_set.total_voting_power &gt; 0) {
        <b>assert</b>!(
            validator_set.total_joining_power &lt;= validator_set.total_voting_power * voting_power_increase_limit / 100,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_EVOTING_POWER_INCREASE_EXCEEDS_LIMIT">EVOTING_POWER_INCREASE_EXCEEDS_LIMIT</a>),
        );
    }
}
</code></pre>



</details>

<a id="0x1_stake_assert_stake_pool_exists"></a>

## Function `assert_stake_pool_exists`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_assert_stake_pool_exists">assert_stake_pool_exists</a>(pool_address: <b>address</b>) {
    <b>assert</b>!(<a href="stake.md#0x1_stake_stake_pool_exists">stake_pool_exists</a>(pool_address), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="stake.md#0x1_stake_ESTAKE_POOL_DOES_NOT_EXIST">ESTAKE_POOL_DOES_NOT_EXIST</a>));
}
</code></pre>



</details>

<a id="0x1_stake_configure_allowed_validators"></a>

## Function `configure_allowed_validators`



<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_configure_allowed_validators">configure_allowed_validators</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, accounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="stake.md#0x1_stake_configure_allowed_validators">configure_allowed_validators</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, accounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;) <b>acquires</b> <a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a> {
    <b>let</b> endless_framework_address = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(endless_framework);
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>if</b> (!<b>exists</b>&lt;<a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a>&gt;(endless_framework_address)) {
        <b>move_to</b>(endless_framework, <a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a> { accounts });
    } <b>else</b> {
        <b>let</b> allowed = <b>borrow_global_mut</b>&lt;<a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a>&gt;(endless_framework_address);
        allowed.accounts = accounts;
    }
}
</code></pre>



</details>

<a id="0x1_stake_is_allowed"></a>

## Function `is_allowed`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_is_allowed">is_allowed</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_is_allowed">is_allowed</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): bool <b>acquires</b> <a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a> {
    <b>if</b> (!<b>exists</b>&lt;<a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a>&gt;(@endless_framework)) {
        <b>true</b>
    } <b>else</b> {
        <b>let</b> allowed = <b>borrow_global</b>&lt;<a href="stake.md#0x1_stake_AllowedValidators">AllowedValidators</a>&gt;(@endless_framework);
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_contains">vector::contains</a>(&allowed.accounts, &<a href="account.md#0x1_account">account</a>)
    }
}
</code></pre>



</details>

<a id="0x1_stake_assert_owner_cap_exists"></a>

## Function `assert_owner_cap_exists`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_assert_owner_cap_exists">assert_owner_cap_exists</a>(owner: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_assert_owner_cap_exists">assert_owner_cap_exists</a>(owner: <b>address</b>) {
    <b>assert</b>!(<b>exists</b>&lt;<a href="stake.md#0x1_stake_OwnerCapability">OwnerCapability</a>&gt;(owner), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="stake.md#0x1_stake_EOWNER_CAP_NOT_FOUND">EOWNER_CAP_NOT_FOUND</a>));
}
</code></pre>



</details>

<a id="0x1_stake_assert_reconfig_not_in_progress"></a>

## Function `assert_reconfig_not_in_progress`



<pre><code><b>fun</b> <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="stake.md#0x1_stake_assert_reconfig_not_in_progress">assert_reconfig_not_in_progress</a>() {
    <b>assert</b>!(!<a href="reconfiguration_state.md#0x1_reconfiguration_state_is_in_progress">reconfiguration_state::is_in_progress</a>(), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="stake.md#0x1_stake_ERECONFIGURATION_IN_PROGRESS">ERECONFIGURATION_IN_PROGRESS</a>));
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

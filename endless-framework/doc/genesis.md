
<a id="0x1_genesis"></a>

# Module `0x1::genesis`



-  [Struct `AccountMap`](#0x1_genesis_AccountMap)
-  [Struct `EmployeeAccountMap`](#0x1_genesis_EmployeeAccountMap)
-  [Struct `ValidatorConfiguration`](#0x1_genesis_ValidatorConfiguration)
-  [Struct `ValidatorConfigurationWithCommission`](#0x1_genesis_ValidatorConfigurationWithCommission)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_genesis_initialize)
-  [Function `initialize_endless_coin`](#0x1_genesis_initialize_endless_coin)
-  [Function `initialize_core_resources_and_endless_coin`](#0x1_genesis_initialize_core_resources_and_endless_coin)
-  [Function `create_accounts`](#0x1_genesis_create_accounts)
-  [Function `initialize_locking_coin_ex`](#0x1_genesis_initialize_locking_coin_ex)
-  [Function `initialize_reward_distribution`](#0x1_genesis_initialize_reward_distribution)
-  [Function `create_account`](#0x1_genesis_create_account)
-  [Function `create_employee_validators`](#0x1_genesis_create_employee_validators)
-  [Function `create_initialize_validators_with_commission`](#0x1_genesis_create_initialize_validators_with_commission)
-  [Function `create_initialize_validators`](#0x1_genesis_create_initialize_validators)
-  [Function `create_initialize_validator`](#0x1_genesis_create_initialize_validator)
-  [Function `initialize_validator`](#0x1_genesis_initialize_validator)
-  [Function `set_genesis_end`](#0x1_genesis_set_genesis_end)
-  [Function `initialize_for_verification`](#0x1_genesis_initialize_for_verification)


<pre><code><b>use</b> <a href="account.md#0x1_account">0x1::account</a>;
<b>use</b> <a href="aggregator_factory.md#0x1_aggregator_factory">0x1::aggregator_factory</a>;
<b>use</b> <a href="block.md#0x1_block">0x1::block</a>;
<b>use</b> <a href="chain_id.md#0x1_chain_id">0x1::chain_id</a>;
<b>use</b> <a href="chain_status.md#0x1_chain_status">0x1::chain_status</a>;
<b>use</b> <a href="consensus_config.md#0x1_consensus_config">0x1::consensus_config</a>;
<b>use</b> <a href="create_signer.md#0x1_create_signer">0x1::create_signer</a>;
<b>use</b> <a href="endless_coin.md#0x1_endless_coin">0x1::endless_coin</a>;
<b>use</b> <a href="endless_governance.md#0x1_endless_governance">0x1::endless_governance</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="execution_config.md#0x1_execution_config">0x1::execution_config</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features">0x1::features</a>;
<b>use</b> <a href="../../endless-stdlib/doc/fixed_point64.md#0x1_fixed_point64">0x1::fixed_point64</a>;
<b>use</b> <a href="fungible_asset.md#0x1_fungible_asset">0x1::fungible_asset</a>;
<b>use</b> <a href="gas_schedule.md#0x1_gas_schedule">0x1::gas_schedule</a>;
<b>use</b> <a href="locking_coin_ex.md#0x1_locking_coin_ex">0x1::locking_coin_ex</a>;
<b>use</b> <a href="object.md#0x1_object">0x1::object</a>;
<b>use</b> <a href="primary_fungible_store.md#0x1_primary_fungible_store">0x1::primary_fungible_store</a>;
<b>use</b> <a href="reconfiguration.md#0x1_reconfiguration">0x1::reconfiguration</a>;
<b>use</b> <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map">0x1::simple_map</a>;
<b>use</b> <a href="stake.md#0x1_stake">0x1::stake</a>;
<b>use</b> <a href="staking_config.md#0x1_staking_config">0x1::staking_config</a>;
<b>use</b> <a href="staking_contract.md#0x1_staking_contract">0x1::staking_contract</a>;
<b>use</b> <a href="state_storage.md#0x1_state_storage">0x1::state_storage</a>;
<b>use</b> <a href="storage_gas.md#0x1_storage_gas">0x1::storage_gas</a>;
<b>use</b> <a href="timestamp.md#0x1_timestamp">0x1::timestamp</a>;
<b>use</b> <a href="transaction_fee.md#0x1_transaction_fee">0x1::transaction_fee</a>;
<b>use</b> <a href="transaction_validation.md#0x1_transaction_validation">0x1::transaction_validation</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">0x1::vector</a>;
<b>use</b> <a href="version.md#0x1_version">0x1::version</a>;
<b>use</b> <a href="vesting.md#0x1_vesting">0x1::vesting</a>;
</code></pre>



<a id="0x1_genesis_AccountMap"></a>

## Struct `AccountMap`



<pre><code><b>struct</b> <a href="genesis.md#0x1_genesis_AccountMap">AccountMap</a> <b>has</b> drop
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
<code>balance: u128</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_genesis_EmployeeAccountMap"></a>

## Struct `EmployeeAccountMap`



<pre><code><b>struct</b> <a href="genesis.md#0x1_genesis_EmployeeAccountMap">EmployeeAccountMap</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>accounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>validator: <a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">genesis::ValidatorConfigurationWithCommission</a></code>
</dt>
<dd>

</dd>
<dt>
<code>vesting_schedule_numerator: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>vesting_schedule_denominator: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>beneficiary_resetter: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_genesis_ValidatorConfiguration"></a>

## Struct `ValidatorConfiguration`



<pre><code><b>struct</b> <a href="genesis.md#0x1_genesis_ValidatorConfiguration">ValidatorConfiguration</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>owner_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>operator_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>voter_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>stake_amount: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>consensus_pubkey: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>proof_of_possession: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>network_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>full_node_network_addresses: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_genesis_ValidatorConfigurationWithCommission"></a>

## Struct `ValidatorConfigurationWithCommission`



<pre><code><b>struct</b> <a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>validator_config: <a href="genesis.md#0x1_genesis_ValidatorConfiguration">genesis::ValidatorConfiguration</a></code>
</dt>
<dd>

</dd>
<dt>
<code>commission_percentage: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>join_during_genesis: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_genesis_EACCOUNT_DOES_NOT_EXIST"></a>



<pre><code><b>const</b> <a href="genesis.md#0x1_genesis_EACCOUNT_DOES_NOT_EXIST">EACCOUNT_DOES_NOT_EXIST</a>: u64 = 2;
</code></pre>



<a id="0x1_genesis_EDUPLICATE_ACCOUNT"></a>



<pre><code><b>const</b> <a href="genesis.md#0x1_genesis_EDUPLICATE_ACCOUNT">EDUPLICATE_ACCOUNT</a>: u64 = 1;
</code></pre>



<a id="0x1_genesis_initialize"></a>

## Function `initialize`

Genesis step 1: Initialize endless framework account and core modules on chain.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize">initialize</a>(<a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8, initial_version: u64, <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="execution_config.md#0x1_execution_config">execution_config</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, epoch_interval_microsecs: u64, minimum_stake: u128, maximum_stake: u128, recurring_lockup_duration_secs: u64, allow_validator_set_change: bool, rewards_rate: u64, rewards_rate_denominator: u64, voting_power_increase_limit: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize">initialize</a>(
    <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8,
    initial_version: u64,
    <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    <a href="execution_config.md#0x1_execution_config">execution_config</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    epoch_interval_microsecs: u64,
    minimum_stake: u128,
    maximum_stake: u128,
    recurring_lockup_duration_secs: u64,
    allow_validator_set_change: bool,
    rewards_rate: u64,
    rewards_rate_denominator: u64,
    voting_power_increase_limit: u64,
) {
    // Initialize the endless framework <a href="account.md#0x1_account">account</a>. This is the <a href="account.md#0x1_account">account</a> <b>where</b> system resources and modules will be
    // deployed <b>to</b>. This will be entirely managed by on-chain governance and no entities have the key or privileges
    // <b>to</b> <b>use</b> this <a href="account.md#0x1_account">account</a>.
    <b>let</b> (endless_framework_account, endless_framework_signer_cap) = <a href="account.md#0x1_account_create_framework_reserved_account">account::create_framework_reserved_account</a>(@endless_framework);
    // Initialize <a href="account.md#0x1_account">account</a> configs on endless framework <a href="account.md#0x1_account">account</a>.
    <a href="account.md#0x1_account_initialize">account::initialize</a>(&endless_framework_account);

    <a href="transaction_validation.md#0x1_transaction_validation_initialize">transaction_validation::initialize</a>(
        &endless_framework_account,
        b"script_prologue",
        b"multi_agent_script_prologue",
        b"epilogue",
    );

    // Give the decentralized on-chain governance control over the core framework <a href="account.md#0x1_account">account</a>.
    <a href="endless_governance.md#0x1_endless_governance_store_signer_cap">endless_governance::store_signer_cap</a>(&endless_framework_account, @endless_framework, endless_framework_signer_cap);

    // put reserved framework reserved accounts under endless governance
    <b>let</b> framework_reserved_addresses = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;[@0x2, @0x3, @0x4, @0x5, @0x6, @0x7, @0x8, @0x9, @0xa];
    <b>while</b> (!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&framework_reserved_addresses)) {
        <b>let</b> <b>address</b> = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>&lt;<b>address</b>&gt;(&<b>mut</b> framework_reserved_addresses);
        <b>let</b> (_, framework_signer_cap) = <a href="account.md#0x1_account_create_framework_reserved_account">account::create_framework_reserved_account</a>(<b>address</b>);
        <a href="endless_governance.md#0x1_endless_governance_store_signer_cap">endless_governance::store_signer_cap</a>(&endless_framework_account, <b>address</b>, framework_signer_cap);
    };

    <a href="consensus_config.md#0x1_consensus_config_initialize">consensus_config::initialize</a>(&endless_framework_account, <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>);
    <a href="execution_config.md#0x1_execution_config_set">execution_config::set</a>(&endless_framework_account, <a href="execution_config.md#0x1_execution_config">execution_config</a>);
    <a href="version.md#0x1_version_initialize">version::initialize</a>(&endless_framework_account, initial_version);
    <a href="stake.md#0x1_stake_initialize">stake::initialize</a>(&endless_framework_account);
    <a href="staking_config.md#0x1_staking_config_initialize">staking_config::initialize</a>(
        &endless_framework_account,
        minimum_stake,
        maximum_stake,
        recurring_lockup_duration_secs,
        allow_validator_set_change,
        rewards_rate,
        rewards_rate_denominator,
        voting_power_increase_limit,
    );
    <a href="storage_gas.md#0x1_storage_gas_initialize">storage_gas::initialize</a>(&endless_framework_account);
    <a href="gas_schedule.md#0x1_gas_schedule_initialize">gas_schedule::initialize</a>(&endless_framework_account, <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>);

    // Ensure we can create aggregators for supply, but not enable it for common <b>use</b> just yet.
    <a href="aggregator_factory.md#0x1_aggregator_factory_initialize_aggregator_factory">aggregator_factory::initialize_aggregator_factory</a>(&endless_framework_account);
    <a href="chain_id.md#0x1_chain_id_initialize">chain_id::initialize</a>(&endless_framework_account, <a href="chain_id.md#0x1_chain_id">chain_id</a>);
    <a href="reconfiguration.md#0x1_reconfiguration_initialize">reconfiguration::initialize</a>(&endless_framework_account);
    <a href="block.md#0x1_block_initialize">block::initialize</a>(&endless_framework_account, epoch_interval_microsecs);
    <a href="state_storage.md#0x1_state_storage_initialize">state_storage::initialize</a>(&endless_framework_account);
    <a href="timestamp.md#0x1_timestamp_set_time_has_started">timestamp::set_time_has_started</a>(&endless_framework_account);
    <a href="endless_governance.md#0x1_endless_governance_initialize_partial_voting">endless_governance::initialize_partial_voting</a>(&endless_framework_account);
}
</code></pre>



</details>

<a id="0x1_genesis_initialize_endless_coin"></a>

## Function `initialize_endless_coin`

Genesis step 2: Initialize Endless coin and transaction fee distribution.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_endless_coin">initialize_endless_coin</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_endless_coin">initialize_endless_coin</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <b>let</b> (mint_cap,burn_cap, transfer_cap) = <a href="endless_coin.md#0x1_endless_coin_initialize">endless_coin::initialize</a>(endless_framework);
    // Give <a href="stake.md#0x1_stake">stake</a> <b>module</b> MintCapability&lt;EndlessCoin&gt; so it can mint rewards.
    <a href="stake.md#0x1_stake_store_endless_coin_cap">stake::store_endless_coin_cap</a>(endless_framework, mint_cap, transfer_cap);
    // Give <a href="transaction_fee.md#0x1_transaction_fee">transaction_fee</a> <b>module</b> BurnCapability&lt;EndlessCoin&gt; so it can burn gas.
    <a href="transaction_fee.md#0x1_transaction_fee_store_endless_coin_burn_cap">transaction_fee::store_endless_coin_burn_cap</a>(endless_framework, burn_cap);
    // Give <a href="transaction_fee.md#0x1_transaction_fee">transaction_fee</a> <b>module</b> MintCapability&lt;EndlessCoin&gt; so it can mint refunds.
    <a href="transaction_fee.md#0x1_transaction_fee_store_endless_coin_mint_cap">transaction_fee::store_endless_coin_mint_cap</a>(endless_framework, mint_cap);
    // Enable collect tx fee and burn it all
    <a href="transaction_fee.md#0x1_transaction_fee_initialize_fee_collection_and_distribution">transaction_fee::initialize_fee_collection_and_distribution</a>(endless_framework, 100);
}
</code></pre>



</details>

<a id="0x1_genesis_initialize_core_resources_and_endless_coin"></a>

## Function `initialize_core_resources_and_endless_coin`

Only called for testnets and e2e tests.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_core_resources_and_endless_coin">initialize_core_resources_and_endless_coin</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, core_resources_auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, mint_to_core_resources: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_core_resources_and_endless_coin">initialize_core_resources_and_endless_coin</a>(
    endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    core_resources_auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    mint_to_core_resources: bool,
) {
    <b>let</b> (mint_cap, burn_cap, transfer_cap) = <a href="endless_coin.md#0x1_endless_coin_initialize">endless_coin::initialize</a>(endless_framework);
    // Give <a href="stake.md#0x1_stake">stake</a> <b>module</b> MintCapability&lt;EndlessCoin&gt; so it can mint rewards.
    <a href="stake.md#0x1_stake_store_endless_coin_cap">stake::store_endless_coin_cap</a>(endless_framework, mint_cap, transfer_cap);

    // delete
    // <a href="locking_coin_ex.md#0x1_locking_coin_ex_start_distribut_coins_test">locking_coin_ex::start_distribut_coins_test</a>(endless_framework);

    // Give <a href="transaction_fee.md#0x1_transaction_fee">transaction_fee</a> <b>module</b> BurnCapability&lt;EndlessCoin&gt; so it can burn gas.
    <a href="transaction_fee.md#0x1_transaction_fee_store_endless_coin_burn_cap">transaction_fee::store_endless_coin_burn_cap</a>(endless_framework, burn_cap);
    // Give <a href="transaction_fee.md#0x1_transaction_fee">transaction_fee</a> <b>module</b> MintCapability&lt;EndlessCoin&gt; so it can mint refunds.
    <a href="transaction_fee.md#0x1_transaction_fee_store_endless_coin_mint_cap">transaction_fee::store_endless_coin_mint_cap</a>(endless_framework, mint_cap);
    <a href="transaction_fee.md#0x1_transaction_fee_initialize_fee_collection_and_distribution">transaction_fee::initialize_fee_collection_and_distribution</a>(endless_framework, /*burn_percentage*/100);

    <b>let</b> core_resources = <a href="account.md#0x1_account_create_account">account::create_account</a>(@core_resources);
    <a href="account.md#0x1_account_rotate_authentication_key_internal">account::rotate_authentication_key_internal</a>(&core_resources, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[core_resources_auth_key]);
    <a href="endless_coin.md#0x1_endless_coin_configure_accounts_for_test">endless_coin::configure_accounts_for_test</a>(endless_framework, &core_resources, mint_cap, transfer_cap);

    <b>if</b> (mint_to_core_resources) {
        <a href="endless_coin.md#0x1_endless_coin_mint">endless_coin::mint</a>(&core_resources, @core_resources, 18446744073709551615);
    };
}
</code></pre>



</details>

<a id="0x1_genesis_create_accounts"></a>

## Function `create_accounts`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_accounts">create_accounts</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, accounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_AccountMap">genesis::AccountMap</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_accounts">create_accounts</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, accounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_AccountMap">AccountMap</a>&gt;) {
    <b>let</b> unique_accounts = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&accounts, |account_map| {
        <b>let</b> account_map: &<a href="genesis.md#0x1_genesis_AccountMap">AccountMap</a> = account_map;
        <b>assert</b>!(
            !<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_contains">vector::contains</a>(&unique_accounts, &account_map.account_address),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_already_exists">error::already_exists</a>(<a href="genesis.md#0x1_genesis_EDUPLICATE_ACCOUNT">EDUPLICATE_ACCOUNT</a>),
        );
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> unique_accounts, account_map.account_address);

        <a href="genesis.md#0x1_genesis_create_account">create_account</a>(
            endless_framework,
            account_map.account_address,
            account_map.balance,
        );
    });
}
</code></pre>



</details>

<a id="0x1_genesis_initialize_locking_coin_ex"></a>

## Function `initialize_locking_coin_ex`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_locking_coin_ex">initialize_locking_coin_ex</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, configs: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="locking_coin_ex.md#0x1_locking_coin_ex_LockingConfig">locking_coin_ex::LockingConfig</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_locking_coin_ex">initialize_locking_coin_ex</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, configs: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;LockingConfig&gt;) {
    <a href="locking_coin_ex.md#0x1_locking_coin_ex_start_distribute_coins">locking_coin_ex::start_distribute_coins</a>(endless_framework, configs);
}
</code></pre>



</details>

<a id="0x1_genesis_initialize_reward_distribution"></a>

## Function `initialize_reward_distribution`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_reward_distribution">initialize_reward_distribution</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, configs: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="stake.md#0x1_stake_AccountShare">stake::AccountShare</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_reward_distribution">initialize_reward_distribution</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, configs: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;AccountShare&gt;) {
    <a href="stake.md#0x1_stake_initialize_reward_split">stake::initialize_reward_split</a>(endless_framework, configs);
}
</code></pre>



</details>

<a id="0x1_genesis_create_account"></a>

## Function `create_account`

This creates an funds an account if it doesn't exist.
If it exists, it just returns the signer.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_account">create_account</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, account_address: <b>address</b>, balance: u128): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_account">create_account</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, account_address: <b>address</b>, balance: u128): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a> {
    <b>if</b> (<a href="account.md#0x1_account_exists_at">account::exists_at</a>(account_address)) {
        <a href="create_signer.md#0x1_create_signer">create_signer</a>(account_address)
    } <b>else</b> {
        <b>let</b> <a href="account.md#0x1_account">account</a> = <a href="account.md#0x1_account_create_account">account::create_account</a>(account_address);
        <b>if</b> (balance &gt; 0) {
            <a href="endless_coin.md#0x1_endless_coin_mint">endless_coin::mint</a>(endless_framework, account_address, balance);
        };
        <a href="account.md#0x1_account">account</a>
    }
}
</code></pre>



</details>

<a id="0x1_genesis_create_employee_validators"></a>

## Function `create_employee_validators`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_employee_validators">create_employee_validators</a>(employee_vesting_start: u64, employee_vesting_period_duration: u64, employees: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_EmployeeAccountMap">genesis::EmployeeAccountMap</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_employee_validators">create_employee_validators</a>(
    employee_vesting_start: u64,
    employee_vesting_period_duration: u64,
    employees: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_EmployeeAccountMap">EmployeeAccountMap</a>&gt;,
) {
    <b>let</b> unique_accounts = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&employees, |employee_group| {
        <b>let</b> j = 0;
        <b>let</b> employee_group: &<a href="genesis.md#0x1_genesis_EmployeeAccountMap">EmployeeAccountMap</a> = employee_group;
        <b>let</b> num_employees_in_group = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&employee_group.accounts);

        <b>let</b> buy_ins = <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_create">simple_map::create</a>();
        <b>let</b> all_buying_coins = <a href="endless_coin.md#0x1_endless_coin_zero">endless_coin::zero</a>();

        <b>while</b> (j &lt; num_employees_in_group) {
            <b>let</b> <a href="account.md#0x1_account">account</a> = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&employee_group.accounts, j);
            <b>assert</b>!(
                !<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_contains">vector::contains</a>(&unique_accounts, <a href="account.md#0x1_account">account</a>),
                <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_already_exists">error::already_exists</a>(<a href="genesis.md#0x1_genesis_EDUPLICATE_ACCOUNT">EDUPLICATE_ACCOUNT</a>),
            );
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> unique_accounts, *<a href="account.md#0x1_account">account</a>);

            <b>let</b> employee = <a href="create_signer.md#0x1_create_signer">create_signer</a>(*<a href="account.md#0x1_account">account</a>);
            <b>let</b> total = <a href="endless_coin.md#0x1_endless_coin_balance">endless_coin::balance</a>(*<a href="account.md#0x1_account">account</a>);
            <b>let</b> store = <a href="primary_fungible_store.md#0x1_primary_fungible_store_ensure_primary_store_exists">primary_fungible_store::ensure_primary_store_exists</a>(*<a href="account.md#0x1_account">account</a>, <a href="endless_coin.md#0x1_endless_coin_get_metadata">endless_coin::get_metadata</a>());
            <b>let</b> fa = <a href="fungible_asset.md#0x1_fungible_asset_withdraw">fungible_asset::withdraw</a>(&employee, store, total);
            <b>let</b> fa_amount = <a href="fungible_asset.md#0x1_fungible_asset_amount">fungible_asset::amount</a>(&fa);
            <a href="../../endless-stdlib/doc/simple_map.md#0x1_simple_map_add">simple_map::add</a>(&<b>mut</b> buy_ins, *<a href="account.md#0x1_account">account</a>, fa_amount);
            <a href="fungible_asset.md#0x1_fungible_asset_merge">fungible_asset::merge</a>(&<b>mut</b> all_buying_coins, fa);

            j = j + 1;
        };

        <b>let</b> j = 0;
        <b>let</b> num_vesting_events = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&employee_group.vesting_schedule_numerator);
        <b>let</b> schedule = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();

        <b>while</b> (j &lt; num_vesting_events) {
            <b>let</b> numerator = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&employee_group.vesting_schedule_numerator, j);
            <b>let</b> <a href="event.md#0x1_event">event</a> = <a href="../../endless-stdlib/doc/fixed_point64.md#0x1_fixed_point64_create_from_rational">fixed_point64::create_from_rational</a>((*numerator <b>as</b> u128), (employee_group.vesting_schedule_denominator <b>as</b> u128));
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> schedule, <a href="event.md#0x1_event">event</a>);

            j = j + 1;
        };

        <b>let</b> vesting_schedule = <a href="vesting.md#0x1_vesting_create_vesting_schedule">vesting::create_vesting_schedule</a>(
            schedule,
            employee_vesting_start,
            employee_vesting_period_duration,
        );

        <b>let</b> admin = employee_group.validator.validator_config.owner_address;
        <b>let</b> admin_signer = &<a href="create_signer.md#0x1_create_signer">create_signer</a>(admin);
        <b>let</b> contract_address = <a href="vesting.md#0x1_vesting_create_vesting_contract">vesting::create_vesting_contract</a>(
            admin_signer,
            &employee_group.accounts,
            buy_ins,
            all_buying_coins,
            vesting_schedule,
            admin,
            employee_group.validator.validator_config.operator_address,
            employee_group.validator.validator_config.voter_address,
            employee_group.validator.commission_percentage,
            x"",
        );
        <b>let</b> pool_address = <a href="vesting.md#0x1_vesting_stake_pool_address">vesting::stake_pool_address</a>(contract_address);

        <b>if</b> (employee_group.beneficiary_resetter != @0x0) {
            <a href="vesting.md#0x1_vesting_set_beneficiary_resetter">vesting::set_beneficiary_resetter</a>(admin_signer, contract_address, employee_group.beneficiary_resetter);
        };

        <b>let</b> validator = &employee_group.validator.validator_config;
        <b>assert</b>!(
            <a href="account.md#0x1_account_exists_at">account::exists_at</a>(validator.owner_address),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="genesis.md#0x1_genesis_EACCOUNT_DOES_NOT_EXIST">EACCOUNT_DOES_NOT_EXIST</a>),
        );
        <b>assert</b>!(
            <a href="account.md#0x1_account_exists_at">account::exists_at</a>(validator.operator_address),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="genesis.md#0x1_genesis_EACCOUNT_DOES_NOT_EXIST">EACCOUNT_DOES_NOT_EXIST</a>),
        );
        <b>assert</b>!(
            <a href="account.md#0x1_account_exists_at">account::exists_at</a>(validator.voter_address),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="genesis.md#0x1_genesis_EACCOUNT_DOES_NOT_EXIST">EACCOUNT_DOES_NOT_EXIST</a>),
        );
        <b>if</b> (employee_group.validator.join_during_genesis) {
            <a href="genesis.md#0x1_genesis_initialize_validator">initialize_validator</a>(pool_address, validator);
        };
    });
}
</code></pre>



</details>

<a id="0x1_genesis_create_initialize_validators_with_commission"></a>

## Function `create_initialize_validators_with_commission`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validators_with_commission">create_initialize_validators_with_commission</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, use_staking_contract: bool, validators: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">genesis::ValidatorConfigurationWithCommission</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validators_with_commission">create_initialize_validators_with_commission</a>(
    endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    use_staking_contract: bool,
    validators: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a>&gt;,
) {
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(&validators, |validator| {
        <b>let</b> validator: &<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a> = validator;
        <a href="genesis.md#0x1_genesis_create_initialize_validator">create_initialize_validator</a>(endless_framework, validator, use_staking_contract);
    });

    // Destroy the endless framework <a href="account.md#0x1_account">account</a>'s ability <b>to</b> mint coins now that we're done <b>with</b> setting up the initial
    // validators.
    <a href="endless_coin.md#0x1_endless_coin_destroy_coin_cap">endless_coin::destroy_coin_cap</a>(endless_framework);

    <a href="stake.md#0x1_stake_on_new_epoch">stake::on_new_epoch</a>();
}
</code></pre>



</details>

<a id="0x1_genesis_create_initialize_validators"></a>

## Function `create_initialize_validators`

Sets up the initial validator set for the network.
The validator "owner" accounts, and their authentication
Addresses (and keys) are encoded in the <code>owners</code>
Each validator signs consensus messages with the private key corresponding to the Ed25519
public key in <code>consensus_pubkeys</code>.
Finally, each validator must specify the network address
(see types/src/network_address/mod.rs) for itself and its full nodes.

Network address fields are a vector per account, where each entry is a vector of addresses
encoded in a single BCS byte array.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validators">create_initialize_validators</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, validators: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfiguration">genesis::ValidatorConfiguration</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validators">create_initialize_validators</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, validators: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfiguration">ValidatorConfiguration</a>&gt;) {
    <b>let</b> validators_with_commission = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_reverse">vector::for_each_reverse</a>(validators, |validator| {
        <b>let</b> validator_with_commission = <a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a> {
            validator_config: validator,
            commission_percentage: 0,
            join_during_genesis: <b>true</b>,
        };
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> validators_with_commission, validator_with_commission);
    });

    <a href="genesis.md#0x1_genesis_create_initialize_validators_with_commission">create_initialize_validators_with_commission</a>(endless_framework, <b>false</b>, validators_with_commission);
}
</code></pre>



</details>

<a id="0x1_genesis_create_initialize_validator"></a>

## Function `create_initialize_validator`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validator">create_initialize_validator</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, commission_config: &<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">genesis::ValidatorConfigurationWithCommission</a>, use_staking_contract: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validator">create_initialize_validator</a>(
    endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    commission_config: &<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a>,
    use_staking_contract: bool,
) {
    <b>let</b> validator = &commission_config.validator_config;

    <b>let</b> owner = &<a href="genesis.md#0x1_genesis_create_account">create_account</a>(endless_framework, validator.owner_address, validator.stake_amount);
    <a href="genesis.md#0x1_genesis_create_account">create_account</a>(endless_framework, validator.operator_address, 0);
    <a href="genesis.md#0x1_genesis_create_account">create_account</a>(endless_framework, validator.voter_address, 0);

    // Initialize the <a href="stake.md#0x1_stake">stake</a> pool and join the validator set.
    <b>let</b> pool_address = <b>if</b> (use_staking_contract) {
        <a href="staking_contract.md#0x1_staking_contract_create_staking_contract">staking_contract::create_staking_contract</a>(
            owner,
            validator.operator_address,
            validator.voter_address,
            validator.stake_amount,
            commission_config.commission_percentage,
            x"",
        );
        <a href="staking_contract.md#0x1_staking_contract_stake_pool_address">staking_contract::stake_pool_address</a>(validator.owner_address, validator.operator_address)
    } <b>else</b> {
        <a href="stake.md#0x1_stake_initialize_stake_owner">stake::initialize_stake_owner</a>(
            owner,
            validator.stake_amount,
            validator.operator_address,
            validator.voter_address,
        );
        validator.owner_address
    };

    <b>if</b> (commission_config.join_during_genesis) {
        <a href="genesis.md#0x1_genesis_initialize_validator">initialize_validator</a>(pool_address, validator);
    };
}
</code></pre>



</details>

<a id="0x1_genesis_initialize_validator"></a>

## Function `initialize_validator`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_validator">initialize_validator</a>(pool_address: <b>address</b>, validator: &<a href="genesis.md#0x1_genesis_ValidatorConfiguration">genesis::ValidatorConfiguration</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_validator">initialize_validator</a>(pool_address: <b>address</b>, validator: &<a href="genesis.md#0x1_genesis_ValidatorConfiguration">ValidatorConfiguration</a>) {
    <b>let</b> operator = &<a href="create_signer.md#0x1_create_signer">create_signer</a>(validator.operator_address);

    <a href="stake.md#0x1_stake_rotate_consensus_key">stake::rotate_consensus_key</a>(
        operator,
        pool_address,
        validator.consensus_pubkey,
        validator.proof_of_possession,
    );
    <a href="stake.md#0x1_stake_update_network_and_fullnode_addresses">stake::update_network_and_fullnode_addresses</a>(
        operator,
        pool_address,
        validator.network_addresses,
        validator.full_node_network_addresses,
    );
    <a href="stake.md#0x1_stake_join_validator_set_internal">stake::join_validator_set_internal</a>(operator, pool_address);
}
</code></pre>



</details>

<a id="0x1_genesis_set_genesis_end"></a>

## Function `set_genesis_end`

The last step of genesis.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_set_genesis_end">set_genesis_end</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_set_genesis_end">set_genesis_end</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <a href="chain_status.md#0x1_chain_status_set_genesis_end">chain_status::set_genesis_end</a>(endless_framework);
}
</code></pre>



</details>

<a id="0x1_genesis_initialize_for_verification"></a>

## Function `initialize_for_verification`



<pre><code>#[verify_only]
<b>fun</b> <a href="genesis.md#0x1_genesis_initialize_for_verification">initialize_for_verification</a>(<a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8, initial_version: u64, <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="execution_config.md#0x1_execution_config">execution_config</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, epoch_interval_microsecs: u64, minimum_stake: u128, maximum_stake: u128, recurring_lockup_duration_secs: u64, allow_validator_set_change: bool, rewards_rate: u64, rewards_rate_denominator: u64, voting_power_increase_limit: u64, endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, min_voting_threshold: u128, required_proposer_stake: u128, voting_duration_secs: u64, accounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_AccountMap">genesis::AccountMap</a>&gt;, employee_vesting_start: u64, employee_vesting_period_duration: u64, employees: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_EmployeeAccountMap">genesis::EmployeeAccountMap</a>&gt;, validators: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">genesis::ValidatorConfigurationWithCommission</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_for_verification">initialize_for_verification</a>(
    <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8,
    initial_version: u64,
    <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    <a href="execution_config.md#0x1_execution_config">execution_config</a>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    epoch_interval_microsecs: u64,
    minimum_stake: u128,
    maximum_stake: u128,
    recurring_lockup_duration_secs: u64,
    allow_validator_set_change: bool,
    rewards_rate: u64,
    rewards_rate_denominator: u64,
    voting_power_increase_limit: u64,
    endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    min_voting_threshold: u128,
    required_proposer_stake: u128,
    voting_duration_secs: u64,
    accounts: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_AccountMap">AccountMap</a>&gt;,
    employee_vesting_start: u64,
    employee_vesting_period_duration: u64,
    employees: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_EmployeeAccountMap">EmployeeAccountMap</a>&gt;,
    validators: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a>&gt;
) {
    <a href="genesis.md#0x1_genesis_initialize">initialize</a>(
        <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>,
        <a href="chain_id.md#0x1_chain_id">chain_id</a>,
        initial_version,
        <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>,
        <a href="execution_config.md#0x1_execution_config">execution_config</a>,
        epoch_interval_microsecs,
        minimum_stake,
        maximum_stake,
        recurring_lockup_duration_secs,
        allow_validator_set_change,
        rewards_rate,
        rewards_rate_denominator,
        voting_power_increase_limit
    );
    <a href="../../endless-stdlib/../move-stdlib/doc/features.md#0x1_features_change_feature_flags">features::change_feature_flags</a>(endless_framework, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2], <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[]);
    <a href="genesis.md#0x1_genesis_initialize_endless_coin">initialize_endless_coin</a>(endless_framework);
    <a href="endless_governance.md#0x1_endless_governance_initialize_for_verification">endless_governance::initialize_for_verification</a>(
        endless_framework,
        min_voting_threshold,
        required_proposer_stake,
        voting_duration_secs
    );
    <a href="genesis.md#0x1_genesis_create_accounts">create_accounts</a>(endless_framework, accounts);
    <a href="genesis.md#0x1_genesis_create_employee_validators">create_employee_validators</a>(employee_vesting_start, employee_vesting_period_duration, employees);
    <a href="genesis.md#0x1_genesis_create_initialize_validators_with_commission">create_initialize_validators_with_commission</a>(endless_framework, <b>true</b>, validators);
    <a href="genesis.md#0x1_genesis_set_genesis_end">set_genesis_end</a>(endless_framework);
}
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

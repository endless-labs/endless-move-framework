script {
    use endless_framework::endless_governance;
    use endless_framework::coin;
    use endless_framework::endless_coin::EndlessCoin;
    use endless_framework::staking_config;

    fun main(proposal_id: u64) {
        let framework_signer = endless_governance::resolve(proposal_id, @endless_framework);
        let one_endless_coin_with_decimals = 10 ** (coin::decimals<EndlessCoin>() as u64);
        // Change min to 1000 and max to 1M Endless coins.
        let new_min_stake = 1000 * one_endless_coin_with_decimals;
        let new_max_stake = 1000000 * one_endless_coin_with_decimals;
        staking_config::update_required_stake(&framework_signer, new_min_stake, new_max_stake);
    }
}

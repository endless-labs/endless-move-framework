script {
    use endless_framework::endless_governance;
    use endless_framework::staking_config;

    fun main(proposal_id: u64) {
        let framework_signer = endless_governance::resolve(proposal_id, @endless_framework);
        // Update voting power increase limit to 10%.
        staking_config::update_voting_power_increase_limit(&framework_signer, 10);
    }
}

/// Reconfiguration with DKG helper functions.
module endless_framework::reconfiguration_with_dkg {
    use std::features;
    use std::option;
    use endless_framework::consensus_config;
    use endless_framework::dkg;
    use endless_framework::execution_config;
    use endless_framework::gas_schedule;
    use endless_framework::jwk_consensus_config;
    use endless_framework::jwks;
    use endless_framework::randomness_config;
    use endless_framework::reconfiguration;
    use endless_framework::reconfiguration_state;
    use endless_framework::stake;
    friend endless_framework::block;
    friend endless_framework::endless_governance;

    /// Trigger a reconfiguration with DKG.
    /// Do nothing if one is already in progress.
    public(friend) fun try_start() {
        let incomplete_dkg_session = dkg::incomplete_session();
        if (option::is_some(&incomplete_dkg_session)) {
            let session = option::borrow(&incomplete_dkg_session);
            if (dkg::session_dealer_epoch(session) == reconfiguration::current_epoch()) {
                return
            }
        };
        reconfiguration_state::on_reconfig_start();
        let cur_epoch = reconfiguration::current_epoch();
        dkg::start(
            cur_epoch,
            randomness_config::current(),
            stake::cur_validator_consensus_infos(),
            stake::next_validator_consensus_infos(),
        );
    }

    /// Clear incomplete DKG session, if it exists.
    /// Apply buffered on-chain configs (except for ValidatorSet, which is done inside `reconfiguration::reconfigure()`).
    /// Re-enable validator set changes.
    /// Run the default reconfiguration to enter the new epoch.
    public(friend) fun finish(account: &signer) {
        dkg::try_clear_incomplete_session(account);
        consensus_config::on_new_epoch();
        execution_config::on_new_epoch();
        gas_schedule::on_new_epoch();
        std::version::on_new_epoch(account);
        jwk_consensus_config::on_new_epoch();
        jwks::on_new_epoch();
        features::on_new_epoch(account);
        randomness_config::on_new_epoch(account);
        reconfiguration::reconfigure();
    }

    /// Complete the current reconfiguration with DKG.
    /// Abort if no DKG is in progress.
    fun finish_with_dkg_result(account: &signer, dkg_result: vector<u8>) {
        dkg::finish(dkg_result);
        finish(account);
    }
}

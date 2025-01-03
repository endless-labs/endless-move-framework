spec endless_framework::dkg {

    spec module {
        use endless_framework::chain_status;
        invariant [suspendable] chain_status::is_operating() ==> exists<DKGState>(@endless_framework);
    }

    spec initialize(endless_framework: &signer) {
        use std::signer;
        let endless_framework_addr = signer::address_of(endless_framework);
        aborts_if endless_framework_addr != @endless_framework;
        aborts_if exists<DKGState>(@endless_framework);
    }

    spec start(
        dealer_epoch: u64,
        randomness_config: RandomnessConfig,
        dealer_validator_set: vector<ValidatorConsensusInfo>,
        target_validator_set: vector<ValidatorConsensusInfo>,
    ) {
        use std::option;
        aborts_if !exists<DKGState>(@endless_framework);
        aborts_if option::is_some(global<DKGState>(@endless_framework).in_progress);
        aborts_if !exists<timestamp::CurrentTimeMicroseconds>(@endless_framework);
    }

    spec finish(transcript: vector<u8>) {
        use std::option;
        aborts_if !exists<DKGState>(@endless_framework);
        aborts_if option::is_none(global<DKGState>(@endless_framework).in_progress);
    }

    spec fun spec_in_progress(): bool {
        if (exists<DKGState>(@endless_framework)) {
            option::spec_is_some(global<DKGState>(@endless_framework).in_progress)
        } else {
            false
        }
    }

}

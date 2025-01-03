/// Define the GovernanceProposal that will be used as part of on-chain governance by EndlessGovernance.
///
/// This is separate from the EndlessGovernance module to avoid circular dependency between EndlessGovernance and Stake.
module endless_framework::governance_proposal {
    friend endless_framework::endless_governance;

    struct GovernanceProposal has store, drop {}

    /// Create and return a GovernanceProposal resource. Can only be called by EndlessGovernance
    public(friend) fun create_proposal(): GovernanceProposal {
        GovernanceProposal {}
    }

    /// Useful for EndlessGovernance to create an empty proposal as proof.
    public(friend) fun create_empty_proposal(): GovernanceProposal {
        create_proposal()
    }

    #[test_only]
    public fun create_test_proposal(): GovernanceProposal {
        create_empty_proposal()
    }
}

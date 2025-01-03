/// Maintains the version number for the blockchain.
module endless_framework::version {
    use std::error;
    use std::signer;
    use endless_framework::config_buffer;
    use endless_framework::system_addresses;

    friend endless_framework::genesis;
    friend endless_framework::reconfiguration_with_dkg;

    struct Version has drop, key, store {
        major: u64,
    }

    struct SetVersionCapability has key {}

    /// Specified major version number must be greater than current version number.
    const EINVALID_MAJOR_VERSION_NUMBER: u64 = 1;
    /// Account is not authorized to make this change.
    const ENOT_AUTHORIZED: u64 = 2;

    /// Only called during genesis.
    /// Publishes the Version config.
    public(friend) fun initialize(endless_framework: &signer, initial_version: u64) {
        system_addresses::assert_endless_framework(endless_framework);

        move_to(endless_framework, Version { major: initial_version });
        // Give endless framework account capability to call set version. This allows on chain governance to do it through
        // control of the endless framework account.
        move_to(endless_framework, SetVersionCapability {});
    }

    /// Used in on-chain governances to update the major version for the next epoch.
    /// Example usage:
    /// - `endless_framework::version::set_for_next_epoch(&framework_signer, new_version);`
    /// - `endless_framework::endless_governance::reconfigure(&framework_signer);`
    public entry fun set_for_next_epoch(account: &signer, major: u64) acquires Version {
        assert!(exists<SetVersionCapability>(signer::address_of(account)), error::permission_denied(ENOT_AUTHORIZED));
        let old_major = borrow_global<Version>(@endless_framework).major;
        assert!(old_major < major, error::invalid_argument(EINVALID_MAJOR_VERSION_NUMBER));
        config_buffer::upsert(Version {major});
    }

    /// Only used in reconfigurations to apply the pending `Version`, if there is any.
    public(friend) fun on_new_epoch(framework: &signer) acquires Version {
        system_addresses::assert_endless_framework(framework);
        if (config_buffer::does_exist<Version>()) {
            let new_value = config_buffer::extract<Version>();
            if (exists<Version>(@endless_framework)) {
                *borrow_global_mut<Version>(@endless_framework) = new_value;
            } else {
                move_to(framework, new_value);
            }
        }
    }

    /// Only called in tests and testnets. This allows the core resources account, which only exists in tests/testnets,
    /// to update the version.
    fun initialize_for_test(core_resources: &signer) {
        system_addresses::assert_core_resource(core_resources);
        move_to(core_resources, SetVersionCapability {});
    }

    #[test(endless_framework = @endless_framework)]
    public entry fun test_set_version(endless_framework: signer) acquires Version {
        initialize(&endless_framework, 1);
        config_buffer::initialize(&endless_framework);
        assert!(borrow_global<Version>(@endless_framework).major == 1, 0);
        set_for_next_epoch(&endless_framework, 2);
        on_new_epoch(&endless_framework);
        assert!(borrow_global<Version>(@endless_framework).major == 2, 1);
    }

    #[test(endless_framework = @endless_framework, core_resources = @core_resources)]
    public entry fun test_set_version_core_resources(
        endless_framework: signer,
        core_resources: signer,
    ) acquires Version {
        initialize(&endless_framework, 1);
        config_buffer::initialize(&endless_framework);
        assert!(borrow_global<Version>(@endless_framework).major == 1, 0);
        initialize_for_test(&core_resources);
        set_for_next_epoch(&core_resources, 2);
        on_new_epoch(&endless_framework);
        assert!(borrow_global<Version>(@endless_framework).major == 2, 1);
    }

    #[test(endless_framework = @endless_framework, random_account = @0x123)]
    #[expected_failure(abort_code = 327682, location = Self)]
    public entry fun test_set_version_unauthorized_should_fail(
        endless_framework: signer,
        random_account: signer,
    ) acquires Version {
        initialize(&endless_framework, 1);
        config_buffer::initialize(&endless_framework);
        set_for_next_epoch(&random_account, 2);
    }
}

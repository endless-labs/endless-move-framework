spec endless_framework::config_buffer {
    spec module {
        pragma verify = true;
    }

    spec initialize(endless_framework: &signer) {
        use std::signer;
        aborts_if exists<PendingConfigs>(signer::address_of(endless_framework));
    }

    spec does_exist<T: store>(): bool {
        aborts_if false;
        let type_name = type_info::type_name<T>();
        ensures result == spec_fun_does_exist<T>(type_name);
    }

    spec fun spec_fun_does_exist<T: store>(type_name: String): bool {
        if (exists<PendingConfigs>(@endless_framework)) {
            let config = global<PendingConfigs>(@endless_framework);
            simple_map::spec_contains_key(config.configs, type_name)
        } else {
            false
        }
    }

    spec upsert<T: drop + store>(config: T) {
        aborts_if !exists<PendingConfigs>(@endless_framework);
    }

    spec extract<T: store>(): T {
        aborts_if !exists<PendingConfigs>(@endless_framework);
        include ExtractAbortsIf<T>;
    }

    spec schema ExtractAbortsIf<T> {
        let configs = global<PendingConfigs>(@endless_framework);
        let key = type_info::type_name<T>();
        aborts_if !simple_map::spec_contains_key(configs.configs, key);
        include any::UnpackAbortsIf<T> {
            x: simple_map::spec_get(configs.configs, key)
        };
    }

    spec schema SetForNextEpochAbortsIf {
        account: &signer;
        config: vector<u8>;
        let account_addr = std::signer::address_of(account);
        aborts_if account_addr != @endless_framework;
        aborts_if len(config) == 0;
        aborts_if !exists<PendingConfigs>(@endless_framework);
    }

    spec schema OnNewEpochAbortsIf<T> {
        use endless_std::type_info;
        let type_name = type_info::type_name<T>();
        aborts_if spec_fun_does_exist<T>(type_name) && !exists<T>(@endless_framework);
        let configs = global<PendingConfigs>(@endless_framework);
        // TODO(#12015)
        include spec_fun_does_exist<T>(type_name) ==> any::UnpackAbortsIf<T> {
            x: simple_map::spec_get(configs.configs, type_name)
        };
    }

    spec schema OnNewEpochRequirement<T> {
        use endless_std::type_info;
        let type_name = type_info::type_name<T>();
        requires spec_fun_does_exist<T>(type_name) ==> exists<T>(@endless_framework);
        let configs = global<PendingConfigs>(@endless_framework);
        // TODO(#12015)
        include spec_fun_does_exist<T>(type_name) ==> any::UnpackRequirement<T> {
            x: simple_map::spec_get(configs.configs, type_name)
        };
    }

}

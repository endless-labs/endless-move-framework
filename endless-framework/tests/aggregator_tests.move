#[test_only]
module endless_framework::aggregator_tests {

    use endless_framework::aggregator;
    use endless_framework::aggregator_factory;

    #[test(account = @endless_framework)]
    fun test_can_add_and_sub_and_read(account: signer) {
        aggregator_factory::initialize_aggregator_factory_for_test(&account);
        let aggregator = aggregator_factory::create_aggregator(&account, 1000);

        aggregator::add(&mut aggregator, 12);
        assert!(aggregator::read(&aggregator) == 12, 0);

        aggregator::add(&mut aggregator, 3);
        assert!(aggregator::read(&aggregator) == 15, 0);

        aggregator::add(&mut aggregator, 3);
        aggregator::add(&mut aggregator, 2);
        aggregator::sub(&mut aggregator, 20);
        assert!(aggregator::read(&aggregator) == 0, 0);

        aggregator::add(&mut aggregator, 1000);
        aggregator::sub(&mut aggregator, 1000);

        aggregator::destroy(aggregator);
    }

    #[test(account = @endless_framework)]
    #[expected_failure(abort_code = 0x020001, location = endless_framework::aggregator)]
    fun test_overflow(account: signer) {
        aggregator_factory::initialize_aggregator_factory_for_test(&account);
        let aggregator = aggregator_factory::create_aggregator(&account, 10);

        // Overflow!
        aggregator::add(&mut aggregator, 12);

        aggregator::destroy(aggregator);
    }

    #[test(account = @endless_framework)]
    #[expected_failure(abort_code = 0x020002, location = endless_framework::aggregator)]
    fun test_underflow(account: signer) {
        aggregator_factory::initialize_aggregator_factory_for_test(&account);
        let aggregator = aggregator_factory::create_aggregator(&account, 10);

        // Underflow!
        aggregator::sub(&mut aggregator, 100);
        aggregator::add(&mut aggregator, 100);

        aggregator::destroy(aggregator);
    }
}

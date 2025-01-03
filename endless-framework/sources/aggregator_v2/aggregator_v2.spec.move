spec endless_framework::aggregator_v2 {
    spec create_aggregator {
        // TODO: temporary mockup.
        pragma opaque;
    }

    spec create_unbounded_aggregator {
        // TODO: temporary mockup.
        pragma opaque;
    }

    spec try_add {
        // TODO: temporary mockup.
        pragma opaque;
    }

    spec try_sub {
        // TODO: temporary mockup.
        pragma opaque;
    }

    spec less_than {
        // TODO: temporary mockup.
        pragma opaque;
    }
    spec less_than_or_equal {
        // TODO: temporary mockup.
        pragma opaque;
    }
    spec greater_than {
        // TODO: temporary mockup.
        pragma opaque;
    }
    spec greater_than_or_equal {
        // TODO: temporary mockup.
        pragma opaque;
    }

    spec read {
        // TODO: temporary mockup.
        pragma opaque;
        aborts_if false;
        ensures result == spec_read(aggregator);
    }

    spec snapshot {
        // TODO: temporary mockup.
        pragma opaque;
    }

    spec create_snapshot {
        // TODO: temporary mockup.
        pragma opaque;
    }

    spec fun spec_read<IntElement>(aggregator: Aggregator<IntElement>): IntElement;
    spec fun spec_get_limit<IntElement>(a: Aggregator<IntElement>): IntElement {
        a.max_value
    }
}

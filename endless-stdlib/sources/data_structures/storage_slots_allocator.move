/// Abstraction to having "addressable" storage slots (i.e. items) in global storage.
/// Addresses are local u64 values (unique within a single StorageSlotsAllocator instance,
/// but can and do overlap across instances).
///
/// Allows optionally to initialize slots (and pay for them upfront), and then reuse them,
/// providing predictable storage costs.
///
/// If we need to mutate multiple slots at the same time, we can workaround borrow_mut preventing us from that,
/// via provided pair of `remove_and_reserve` and `fill_reserved_slot` methods, to do so in non-conflicting manner.
///
/// Similarly allows getting an address upfront via `reserve_slot`, for a slot created
/// later (i.e. if we need address to initialize the value itself).
///
/// In the future, more sophisticated strategies can be added, without breaking/modifying callers,
/// for example:
/// * inlining some nodes
/// * having a fee-payer for any storage creation operations
module endless_std::storage_slots_allocator {
    use std::error;
    use endless_std::table_with_length::{Self, TableWithLength};
    use std::option::{Self, Option};

    const EINVALID_ARGUMENT: u64 = 1;
    const ECANNOT_HAVE_SPARES_WITHOUT_REUSE: u64 = 2;
    const EINTERNAL_INVARIANT_BROKEN: u64 = 7;

    const NULL_INDEX: u64 = 0;
    const FIRST_INDEX: u64 = 10; // keeping space for usecase-specific values

    struct OccupiedData<T: store> has store {
        value: T,
    }

    struct VacantData has store {
        next: u64,
    }

    /// Data stored in an individual slot
    struct Link<T: store> has store {
        tag: u8,
        /// Variant that stores actual data
        Occupied : Option<OccupiedData<T>>,
        /// Empty variant (that keeps storage item from being deleted)
        /// and represents a node in a linked list of empty slots.
        Vacant: Option<VacantData>,
    }

    struct StorageSlotsAllocatorV1Data<T: store> has store{
        slots: Option<TableWithLength<u64, Link<T>>>, // Lazily create slots table only when needed
        new_slot_index: u64,
        should_reuse: bool,
        reuse_head_index: u64,
        reuse_spare_count: u32,
    }     

    struct StorageSlotsAllocator<T: store> has store {
        tag: u8,
        // V1 is sequential - any two operations on the StorageSlotsAllocator will conflict.
        // In general, StorageSlotsAllocator is invoked on less frequent operations, so
        // that shouldn't be a big issue.
        V1 : Option<StorageSlotsAllocatorV1Data<T>>,
    }

    public fun get_should_reuse<T: store>(
        self: &StorageSlotsAllocator<T>,
    ): bool {
        if (option::is_some(&self.V1)) {
            option::borrow(&self.V1).should_reuse
        } else {
            false
        }
    }

    /// Handle to a reserved slot within a transaction.
    /// Not copy/drop/store-able, to guarantee reservation
    /// is used or released within the transaction.
    struct ReservedSlot {
        slot_index: u64,
    }

    /// Ownership handle to a slot.
    /// Not copy/drop-able to make sure slots are released when not needed,
    /// and there is unique owner for each slot.
    struct StoredSlot has store {
        slot_index: u64,
    }

    public fun new<T: store>(should_reuse: bool): StorageSlotsAllocator<T> {

        // let t :TableWithLength<u64, Link<T>> = table_with_length::new();

        // let d = StorageSlotsAllocatorV1Data{
        //     slots: option::some(t), // Lazily create slots table only when needed
        //     new_slot_index: 0,
        //     should_reuse,
        //     reuse_head_index: 0,
        //     reuse_spare_count: 0,
        // };

        let d = StorageSlotsAllocatorV1Data{
            slots: option::none(), // Lazily create slots table only when needed
            new_slot_index: FIRST_INDEX,
            should_reuse,
            reuse_head_index: NULL_INDEX,
            reuse_spare_count: 0,
        };

        StorageSlotsAllocator<T> {
            tag: 1,
            V1: option::some(d)
        }
        // StorageSlotsAllocator::V1 {
        //     slots: option::none(),
        //     new_slot_index: FIRST_INDEX,
        //     should_reuse,
        //     reuse_head_index: NULL_INDEX,
        //     reuse_spare_count: 0,
        // }
    }

    public fun allocate_spare_slots<T: store>(self: &mut StorageSlotsAllocator<T>, num_to_allocate: u64) {
        let v1_data = option::borrow(&self.V1);
        assert!(v1_data.should_reuse, error::invalid_argument(ECANNOT_HAVE_SPARES_WITHOUT_REUSE));
        allocate_spare_slots_helper(self, num_to_allocate);
    }

    fun allocate_spare_slots_helper<T: store>(self: &mut StorageSlotsAllocator<T>, num_remaining: u64) {
        if (num_remaining == 0) {
            return
        };
        let slot_index = next_slot_index(self);
        maybe_push_to_reuse_queue(self, slot_index);
        allocate_spare_slots_helper(self, num_remaining - 1)
    }

    public fun get_num_spare_slot_count<T: store>(self: &StorageSlotsAllocator<T>): u32 {
        if (option::is_some(&self.V1)) {
            let v1_data = option::borrow(&self.V1);
            assert!(v1_data.should_reuse, error::invalid_argument(ECANNOT_HAVE_SPARES_WITHOUT_REUSE));
            v1_data.reuse_spare_count
        } else {
            abort error::invalid_argument(ECANNOT_HAVE_SPARES_WITHOUT_REUSE)
        }
    }

    public fun add<T: store>(self: &mut StorageSlotsAllocator<T>, val: T): StoredSlot {
        let (stored_slot, reserved_slot) = reserve_slot(self);
        fill_reserved_slot(self, reserved_slot, val);
        stored_slot
    }

    public fun remove<T: store>(self: &mut StorageSlotsAllocator<T>, slot: StoredSlot): T {
        let (reserved_slot, value) = remove_and_reserve(self, stored_to_index(&slot));
        free_reserved_slot(self, reserved_slot, slot);
        value
    }

    public fun destroy_empty<T: store>(self: StorageSlotsAllocator<T>) {
        // First, clear all nodes from the reuse queue
        let self_mut = self;
        loop {
            let reuse_index = maybe_pop_from_reuse_queue(&mut self_mut);
            if (reuse_index == NULL_INDEX) {
                break
            };
        };

        let StorageSlotsAllocator { tag: _, V1: v1 } = self_mut;
        let StorageSlotsAllocatorV1Data {
            slots,
            new_slot_index: _,
            should_reuse: _,
            reuse_head_index,
            reuse_spare_count: _,
        } = option::destroy_some(v1);

        assert!(reuse_head_index == NULL_INDEX, EINTERNAL_INVARIANT_BROKEN);
        if (option::is_some(&slots)) {
            table_with_length::destroy_empty(option::destroy_some(slots));
        } else {
            option::destroy_none(slots);
        }
    }

    public fun borrow<T: store>(self: &StorageSlotsAllocator<T>, slot_index: u64): &T {
        let v1_data = option::borrow(&self.V1);
        let slots = option::borrow(&v1_data.slots);
        let link = table_with_length::borrow(slots, slot_index);
        &option::borrow(&link.Occupied).value
    }

    public fun borrow_mut<T: store>(self: &mut StorageSlotsAllocator<T>, slot_index: u64): &mut T {
        let v1_data = option::borrow_mut(&mut self.V1);
        let slots = option::borrow_mut(&mut v1_data.slots);
        let link = table_with_length::borrow_mut(slots, slot_index);
        &mut option::borrow_mut(&mut link.Occupied).value
    }

    // We also provide here operations where `add()` is split into `reserve_slot`,
    // and then doing fill_reserved_slot later.

    // Similarly we have `remove_and_reserve`, and then `fill_reserved_slot` later.

    public fun reserve_slot<T: store>(self: &mut StorageSlotsAllocator<T>): (StoredSlot, ReservedSlot) {
        let slot_index_from_reuse = maybe_pop_from_reuse_queue(self);
        let slot_index = if (slot_index_from_reuse == NULL_INDEX) {
            next_slot_index(self)
        } else {
            slot_index_from_reuse
        };

        (
            StoredSlot { slot_index },
            ReservedSlot { slot_index },
        )
    }

    public fun fill_reserved_slot<T: store>(self: &mut StorageSlotsAllocator<T>, slot: ReservedSlot, val: T) {
        let ReservedSlot { slot_index } = slot;
        let link = Link {
            tag: 1,
            Occupied: option::some(OccupiedData { value: val }),
            Vacant: option::none(),
        };
        add_link(self, slot_index, link);
    }

    /// Remove storage slot, but reserve it for later.
    public fun remove_and_reserve<T: store>(self: &mut StorageSlotsAllocator<T>, slot_index: u64): (ReservedSlot, T) {
        let Link { tag: _, Occupied: occupied, Vacant: vacant } = remove_link(self, slot_index);
        option::destroy_none(vacant);
        let OccupiedData { value } = option::destroy_some(occupied);
        (ReservedSlot { slot_index }, value)
    }

    public fun free_reserved_slot<T: store>(self: &mut StorageSlotsAllocator<T>, reserved_slot: ReservedSlot, stored_slot: StoredSlot) {
        let ReservedSlot { slot_index } = reserved_slot;
        assert!(slot_index == stored_slot.slot_index, EINVALID_ARGUMENT);
        let StoredSlot { slot_index: _ } = stored_slot;
        maybe_push_to_reuse_queue(self, slot_index);
    }

    // ========== Section for methods handling references ========

    public fun reserved_to_index(self: &ReservedSlot): u64 {
        self.slot_index
    }

    public fun stored_to_index(self: &StoredSlot): u64 {
        self.slot_index
    }

    public fun is_null_index(slot_index: u64): bool {
        slot_index == NULL_INDEX
    }

    public fun is_special_unused_index(slot_index: u64): bool {
        slot_index != NULL_INDEX && slot_index < FIRST_INDEX
    }

    // ========== Section for private internal utility methods ========

    fun maybe_pop_from_reuse_queue<T: store>(self: &mut StorageSlotsAllocator<T>): u64 {
        let v1_data = option::borrow_mut(&mut self.V1);
        let slot_index = v1_data.reuse_head_index;
        if (slot_index != NULL_INDEX) {
            let Link { tag: _, Occupied: occupied, Vacant: vacant } = remove_link(self, slot_index);
            option::destroy_none(occupied);
            let VacantData { next } = option::destroy_some(vacant);
            let v1_data_mut = option::borrow_mut(&mut self.V1);
            v1_data_mut.reuse_head_index = next;
            v1_data_mut.reuse_spare_count = v1_data_mut.reuse_spare_count - 1;
        };
        slot_index
    }

    fun maybe_push_to_reuse_queue<T: store>(self: &mut StorageSlotsAllocator<T>, slot_index: u64) {
        let v1_data = option::borrow(&self.V1);
        if (v1_data.should_reuse) {
            let reuse_head = v1_data.reuse_head_index;
            let link = Link {
                tag: 2,
                Occupied: option::none(),
                Vacant: option::some(VacantData { next: reuse_head }),
            };
            add_link(self, slot_index, link);
            let v1_data_mut = option::borrow_mut(&mut self.V1);
            v1_data_mut.reuse_head_index = slot_index;
            v1_data_mut.reuse_spare_count = v1_data_mut.reuse_spare_count + 1;
        };
    }

    fun next_slot_index<T: store>(self: &mut StorageSlotsAllocator<T>): u64 {
        let v1_data = option::borrow_mut(&mut self.V1);
        let slot_index = v1_data.new_slot_index;
        v1_data.new_slot_index = v1_data.new_slot_index + 1;
        if (option::is_none(&v1_data.slots)) {
            option::fill(&mut v1_data.slots, table_with_length::new<u64, Link<T>>());
        };
        slot_index
    }

    fun add_link<T: store>(self: &mut StorageSlotsAllocator<T>, slot_index: u64, link: Link<T>) {
        let v1_data = option::borrow_mut(&mut self.V1);
        let slots = option::borrow_mut(&mut v1_data.slots);
        table_with_length::add(slots, slot_index, link);
    }

    fun remove_link<T: store>(self: &mut StorageSlotsAllocator<T>, slot_index: u64): Link<T> {
        let v1_data = option::borrow_mut(&mut self.V1);
        let slots = option::borrow_mut(&mut v1_data.slots);
        table_with_length::remove(slots, slot_index)
    }

    // ============================= Tests ====================================

    #[test]
    fun test_add_and_remove_without_reuse() {
        let allocator = new<u64>(false);
        let stored_slot = add(&mut allocator, 10);
        let slot_index = stored_to_index(&stored_slot);
        assert!(slot_index == FIRST_INDEX, 0);
        assert!(*borrow(&allocator, slot_index) == 10, 1);

        let value_ref = borrow_mut(&mut allocator, slot_index);
        *value_ref = 42;
        let removed = remove(&mut allocator, stored_slot);
        assert!(removed == 42, 2);

        destroy_empty(allocator);
    }

    #[test]
    fun test_reuse_queue_flow() {
        let allocator = new<u64>(true);
        allocate_spare_slots(&mut allocator, 2);
        assert!(get_num_spare_slot_count(&allocator) == 2, 0);

        let stored_slot = add(&mut allocator, 7);
        let reused_index = stored_to_index(&stored_slot);
        assert!(reused_index == FIRST_INDEX + 1, 1);
        assert!(get_num_spare_slot_count(&allocator) == 1, 2);

        let removed_value = remove(&mut allocator, stored_slot);
        assert!(removed_value == 7, 3);
        assert!(get_num_spare_slot_count(&allocator) == 2, 4);

        loop {
            let popped = maybe_pop_from_reuse_queue(&mut allocator);
            if (popped == NULL_INDEX) {
                break
            };
        };
        destroy_empty(allocator);
    }

    spec module {
        pragma verify = false;
    }
}

/// This module provides an implementation for an big ordered map.
/// Big means that it is stored across multiple resources, and doesn't have an
/// upper limit on number of elements it can contain.
///
/// Keys point to values, and each key in the map must be unique.
///
/// Currently, one implementation is provided - BPlusTreeMap, backed by a B+Tree,
/// with each node being a separate resource, internally containing OrderedMap.
///
/// BPlusTreeMap is chosen since the biggest (performance and gast)
/// costs are reading resources, and it:
/// * reduces number of resource accesses
/// * reduces number of rebalancing operations, and makes each rebalancing
///   operation touch only few resources
/// * it allows for parallelism for keys that are not close to each other,
///   once it contains enough keys
///
/// Note: Default configuration (used in `new_with_config(0, 0, false)`) allows for keys and values of up to 5KB,
/// or 100 times the first (key, value), to satisfy general needs.
/// If you need larger, use other constructor methods.
/// Based on initial configuration, BigOrderedMap will always accept insertion of keys and values
/// up to the allowed size, and will abort with EKEY_BYTES_TOO_LARGE or EARGUMENT_BYTES_TOO_LARGE.
///
/// Warning: All iterator functions need to be carefully used, because they are just pointers into the
/// structure, and modification of the map invalidates them (without compiler being able to catch it).
/// Type is also named IteratorPtr, so that Iterator is free to use later.
/// Better guarantees would need future Move improvements that will allow references to be part of the struct,
/// allowing cleaner iterator APIs.
///
/// That's why all functions returning iterators are prefixed with "internal_", to clarify nuances needed to make
/// sure usage is correct.
/// A set of inline utility methods is provided instead, to provide guaranteed valid usage to iterators.
module endless_std::big_ordered_map {
    use std::error;
    use std::vector;
    use std::option::{Self as option, Option};
    use std::bcs;
    use endless_std::ordered_map::{Self, OrderedMap};
    use endless_std::cmp;
    use endless_std::storage_slots_allocator::{Self, StorageSlotsAllocator, StoredSlot};
    use endless_std::math64::{max, min};

    // Error constants shared with ordered_map (so try using same values)

    /// Map key already exists
    const EKEY_ALREADY_EXISTS: u64 = 1;
    /// Map key is not found
    const EKEY_NOT_FOUND: u64 = 2;
    /// Trying to do an operation on an IteratorPtr that would go out of bounds
    const EITER_OUT_OF_BOUNDS: u64 = 3;

    // Error constants specific to big_ordered_map

    /// The provided configuration parameter is invalid.
    const EINVALID_CONFIG_PARAMETER: u64 = 11;
    /// Map isn't empty
    const EMAP_NOT_EMPTY: u64 = 12;
    /// Trying to insert too large of an (key, value) into the map.
    const EARGUMENT_BYTES_TOO_LARGE: u64 = 13;
    /// borrow_mut requires that key and value types have constant size
    /// (otherwise it wouldn't be able to guarantee size requirements are not violated)
    /// Use remove() + add() combo instead.
    const EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE: u64 = 14;
    /// Trying to insert too large of a key into the map.
    const EKEY_BYTES_TOO_LARGE: u64 = 15;

    /// Cannot use new/new_with_reusable with variable-sized types.
    /// Use `new_with_type_size_hints()` or `new_with_config()` instead if your types have variable sizes.
    /// `new_with_config(0, 0, false)` tries to work reasonably well for variety of sizes
    /// (allows keys or values of at least 5KB and 100x larger than the first inserted)
    const ECANNOT_USE_NEW_WITH_VARIABLE_SIZED_TYPES: u64 = 16;

    // Errors that should never be thrown

    /// Internal errors.
    const EINTERNAL_INVARIANT_BROKEN: u64 = 20;

    // Internal constants.

    // Bounds on degrees:

    /// Smallest allowed degree on inner nodes.
    const INNER_MIN_DEGREE: u64 = 4;
    /// Smallest allowed degree on leaf nodes.
    ///
    /// We rely on 1 being valid size only for root node,
    /// so this cannot be below 3 (unless that is changed)
    const LEAF_MIN_DEGREE: u64 = 3;
    /// Largest degree allowed (both for inner and leaf nodes)
    const MAX_DEGREE: u64 = 4096;

    // Bounds on serialized sizes:

    /// Largest size all keys for inner nodes or key-value pairs for leaf nodes can have.
    /// Node itself can be a bit larger, due to few other accounting fields.
    /// This is a bit conservative, a bit less than half of the resource limit (which is 1MB)
    const MAX_NODE_BYTES: u64 = 400 * 1024;
    /// Target node size, from efficiency perspective.
    const DEFAULT_TARGET_NODE_SIZE: u64 = 4096;

    /// When using default constructors (new() / new_with_reusable() / new_with_config(0, 0, _))
    /// making sure key or value of this size (5KB) will be accepted, which should satisfy most cases
    /// If you need keys/values that are larger, use other constructors.
    const DEFAULT_MAX_KEY_OR_VALUE_SIZE: u64 = 5 * 1024; // 5KB

    /// Target max node size, when using hints (via new_with_type_size_hints).
    /// Smaller than MAX_NODE_BYTES, to improve performence, as large nodes are innefficient.
    const HINT_MAX_NODE_BYTES: u64 = 128 * 1024;

    // Constants aligned with storage_slots_allocator
    const NULL_INDEX: u64 = 0;
    const ROOT_INDEX: u64 = 1;

    /// A node of the BigOrderedMap.
    ///
    /// Inner node will have all children be Child::Inner, pointing to the child nodes.
    /// Leaf node will have all children be Child::Leaf.
    /// Basically - Leaf node is a single-resource OrderedMap, containing as much key/value entries, as can fit.
    /// So Leaf node contains multiple values, not just one.
    struct Node<K: store, V: store> has store {
        // Whether this node is a leaf node.
        is_leaf: bool,
        // The children of the node.
        children: OrderedMap<K, Child<V>>,
        // Index of the previous node on the same level, or NULL_INDEX.
        prev: u64,
        // Index of the next node on the same level, or NULL_INDEX.
        next: u64,
    }

    /// Data for the Inner variant of Child
    struct ChildInnerData has store {
        // The node index of it's child
        node_index: StoredSlot,
    }

    /// Data for the Leaf variant of Child
    struct ChildLeafData<V: store> has store {
        // Value associated with the leaf node.
        value: V,
    }

    /// Contents of a child node.
    struct Child<V: store> has store {
        tag: u8,
        Inner: Option<ChildInnerData>,
        Leaf: Option<ChildLeafData<V>>,
    }

    /// Data for the Some variant of IteratorPtr
    struct IteratorPtrSomeData<K> has copy, drop {
        /// The node index of the iterator pointing to.
        node_index: u64,

        /// Child iter it is pointing to
        child_iter: ordered_map::IteratorPtr,

        /// `key` to which `(node_index, child_iter)` are pointing to
        /// cache to not require borrowing global resources to fetch again
        key: K,
    }

    /// An iterator to iterate all keys in the BigOrderedMap.
    ///
    /// TODO: Once fields can be (mutable) references, this class will be deprecated.
    struct IteratorPtr<K> has copy, drop {
        tag: u8,
        End: Option<bool>,
        Some: Option<IteratorPtrSomeData<K>>,
    }

    struct IteratorPtrWithPath<K> has copy, drop {
        iterator: IteratorPtr<K>,
        path: vector<u64>,
    }

    /// The BigOrderedMap data structure.
    struct BigOrderedMap<K: store, V: store> has store {
        tag: u8,
        /// Root node stored directly inside the resource.
        root: Node<K, V>,
        /// Storage of all non-root nodes. They are stored in separate storage slots.
        nodes: StorageSlotsAllocator<Node<K, V>>,
        /// The node index of the leftmost node.
        min_leaf_index: u64,
        /// The node index of the rightmost node.
        max_leaf_index: u64,
        /// Whether Key and Value have constant serialized size.
        constant_kv_size: bool,
        /// The max number of children an inner node can have.
        inner_max_degree: u64,
        /// The max number of children a leaf node can have.
        leaf_max_degree: u64,
    }

    // ======================= Constructors && Destructors ====================

    /// Returns a new BigOrderedMap with the default configuration.
    ///
    /// Cannot be used with variable-sized types.
    /// Use `new_with_type_size_hints()` or `new_with_config()` instead if your types have variable sizes.
    /// `new_with_config(0, 0, false)` tries to work reasonably well for variety of sizes
    /// (allows keys or values of at least 5KB and 100x larger than the first inserted)
    public fun new<K: store, V: store>(): BigOrderedMap<K, V> {
        assert!(
            option::is_some(&bcs::constant_serialized_size<K>()) && option::is_some(&bcs::constant_serialized_size<V>()),
            error::invalid_argument(ECANNOT_USE_NEW_WITH_VARIABLE_SIZED_TYPES)
        );
        new_with_config(0, 0, false)
    }

    /// Returns a new BigOrderedMap with with reusable storage slots.
    ///
    /// Cannot be used with variable-sized types.
    /// Use `new_with_type_size_hints()` or `new_with_config()` instead if your types have variable sizes.
    /// `new_with_config(0, 0, false)` tries to work reasonably well for variety of sizes
    /// (allows keys or values of at least 5KB and 100x larger than the first inserted)
    public fun new_with_reusable<K: store, V: store>(): BigOrderedMap<K, V> {
        assert!(
            option::is_some(&bcs::constant_serialized_size<K>()) && option::is_some(&bcs::constant_serialized_size<V>()),
            error::invalid_argument(ECANNOT_USE_NEW_WITH_VARIABLE_SIZED_TYPES)
        );
        new_with_config(0, 0, true)
    }

    /// Returns a new BigOrderedMap, configured based on passed key and value serialized size hints.
    public fun new_with_type_size_hints<K: store, V: store>(avg_key_bytes: u64, max_key_bytes: u64, avg_value_bytes: u64, max_value_bytes: u64): BigOrderedMap<K, V> {
        assert!(avg_key_bytes <= max_key_bytes, error::invalid_argument(EINVALID_CONFIG_PARAMETER));
        assert!(avg_value_bytes <= max_value_bytes, error::invalid_argument(EINVALID_CONFIG_PARAMETER));

        let inner_max_degree_from_avg = max(min(MAX_DEGREE, DEFAULT_TARGET_NODE_SIZE / avg_key_bytes), INNER_MIN_DEGREE);
        let inner_max_degree_from_max = HINT_MAX_NODE_BYTES / max_key_bytes;
        assert!(inner_max_degree_from_max >= INNER_MIN_DEGREE, error::invalid_argument(EINVALID_CONFIG_PARAMETER));

        let avg_entry_size = avg_key_bytes + avg_value_bytes;
        let max_entry_size = max_key_bytes + max_value_bytes;

        let leaf_max_degree_from_avg = max(min(MAX_DEGREE, DEFAULT_TARGET_NODE_SIZE / avg_entry_size), LEAF_MIN_DEGREE);
        let leaf_max_degree_from_max = HINT_MAX_NODE_BYTES / max_entry_size;
        assert!(leaf_max_degree_from_max >= INNER_MIN_DEGREE, error::invalid_argument(EINVALID_CONFIG_PARAMETER));

        new_with_config(
            min(inner_max_degree_from_avg, inner_max_degree_from_max),
            min(leaf_max_degree_from_avg, leaf_max_degree_from_max),
            false,
        )
    }

    /// Returns a new BigOrderedMap with the provided max degree consts (the maximum # of children a node can have, both inner and leaf).
    ///
    /// If 0 is passed, then it is dynamically computed based on size of first key and value.
    /// WIth 0 it is configured to accept keys and values up to 5KB in size,
    /// or as large as 100x the size of the first insert. (100 = MAX_NODE_BYTES / DEFAULT_TARGET_NODE_SIZE)
    ///
    /// Sizes of all elements must respect (or their additions will be rejected):
    ///   `key_size * inner_max_degree <= MAX_NODE_BYTES`
    ///   `entry_size * leaf_max_degree <= MAX_NODE_BYTES`
    /// If keys or values have variable size, and first element could be non-representative in size (i.e. smaller than future ones),
    /// it is important to compute and pass inner_max_degree and leaf_max_degree based on the largest element you want to be able to insert.
    ///
    /// `reuse_slots` means that removing elements from the map doesn't free the storage slots and returns the refund.
    /// Together with `allocate_spare_slots`, it allows to preallocate slots and have inserts have predictable gas costs.
    /// (otherwise, inserts that require map to add new nodes, cost significantly more, compared to the rest)
    public fun new_with_config<K: store, V: store>(inner_max_degree: u64, leaf_max_degree: u64, reuse_slots: bool): BigOrderedMap<K, V> {
        assert!(inner_max_degree == 0 || (inner_max_degree >= INNER_MIN_DEGREE && inner_max_degree <= MAX_DEGREE), error::invalid_argument(EINVALID_CONFIG_PARAMETER));
        assert!(leaf_max_degree == 0 || (leaf_max_degree >= LEAF_MIN_DEGREE && leaf_max_degree <= MAX_DEGREE), error::invalid_argument(EINVALID_CONFIG_PARAMETER));

        // Assert that storage_slots_allocator special indices are aligned:
        assert!(storage_slots_allocator::is_null_index(NULL_INDEX), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        assert!(storage_slots_allocator::is_special_unused_index(ROOT_INDEX), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

        let nodes = storage_slots_allocator::new(reuse_slots);

        let self = BigOrderedMap {
            tag: 1,
            root: new_node(/*is_leaf=*/true),
            nodes: nodes,
            min_leaf_index: ROOT_INDEX,
            max_leaf_index: ROOT_INDEX,
            constant_kv_size: false, // Will be initialized in validate_static_size_and_init_max_degrees below.
            inner_max_degree: inner_max_degree,
            leaf_max_degree: leaf_max_degree,
        };
        validate_static_size_and_init_max_degrees(&mut self);
        self
    }

    /// Create a BigOrderedMap from a vector of keys and values, with default configuration.
    /// Aborts with EKEY_ALREADY_EXISTS if duplicate keys are passed in.
    public fun new_from<K: drop + copy + store, V: store>(keys: vector<K>, values: vector<V>): BigOrderedMap<K, V> {
        let map = new();
        add_all(&mut map, keys, values);
        map
    }

    /// Destroys the map if it's empty, otherwise aborts.
    /// Note: If the map was created with reuse_slots=true, this will fail if there are
    /// nodes in the reuse list. Use destroy with a lambda instead, or create the map with reuse_slots=false.
    public fun destroy_empty<K: store, V: store>(self: BigOrderedMap<K, V>) {
        let BigOrderedMap { tag: _, root, nodes, min_leaf_index: _, max_leaf_index: _, constant_kv_size: _, inner_max_degree: _, leaf_max_degree: _ } = self;
        destroy_empty_node(root);
        // If root node is empty, then we know that no storage slots are used,
        // and so we can safely destroy all nodes.
        storage_slots_allocator::destroy_empty(nodes);
    }

    /// Map was created with reuse_slots=true, you can allocate spare slots, to pay storage fee now, to
    /// allow future insertions to not require any storage slot creation - making their gas more predictable
    /// and better bounded/fair.
    /// (otherwsie, unlucky inserts create new storage slots and are charge more for it)
    public fun allocate_spare_slots<K: store, V: store>(self: &mut BigOrderedMap<K, V>, num_to_allocate: u64) {
        storage_slots_allocator::allocate_spare_slots(&mut self.nodes, num_to_allocate)
    }

    /// Returns true iff the BigOrderedMap is empty.
    public fun is_empty<K: store, V: store>(self: &BigOrderedMap<K, V>): bool {
        let root = &self.root;
        if (root.is_leaf) {
            ordered_map::is_empty(&root.children)
        } else {
            false
        }
    }

    /// Returns the number of elements in the BigOrderedMap.
    /// This is an expensive function, as it goes through all the leaves to compute it.
    public fun compute_length<K: store, V: store>(self: &BigOrderedMap<K, V>): u64 {
        let size = 0;
        for_each_leaf_node_children_ref(self, |children| {
            size = size + ordered_map::length(children);
        });
        size
    }

    // ======================= Section with Modifiers =========================

    /// Inserts the key/value into the BigOrderedMap.
    /// Aborts if the key is already in the map.
    public fun add<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, key: K, value: V) {
        option::destroy_none(add_or_upsert_impl(self, key, value, false))
    }

    /// If the key doesn't exist in the map, inserts the key/value, and returns none.
    /// Otherwise updates the value under the given key, and returns the old value.
    public fun upsert<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, key: K, value: V): Option<V> {
        let result = add_or_upsert_impl(self, key, value, true);
        if (option::is_some(&result)) {
            let child = option::destroy_some(result);
            let Child { tag: _, Inner: inner, Leaf: leaf } = child;
            option::destroy_none(inner);
            let ChildLeafData { value: old_value } = option::destroy_some(leaf);
            option::some(old_value)
        } else {
            option::destroy_none(result);
            option::none()
        }
    }

    /// Removes the entry from BigOrderedMap and returns the value which `key` maps to.
    /// Aborts if there is no entry for `key`.
    public fun remove<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, key: &K): V {
        // Optimize case where only root node exists
        // (optimizes out borrowing and path creation in `find_leaf_path`)
        let root = &self.root;
        if (root.is_leaf) {
            let root_mut = &mut self.root;
            let child = ordered_map::remove(&mut root_mut.children, key);
            let Child { tag: _, Inner: inner, Leaf: leaf } = child;
            option::destroy_none(inner);
            let ChildLeafData { value } = option::destroy_some(leaf);
            return value
        };

        let path_to_leaf = find_leaf_path(self, key);
        

        assert!(!vector::is_empty(&path_to_leaf), error::invalid_argument(EKEY_NOT_FOUND));
        // assert!(!vector::is_empty(&path_to_leaf), error::invalid_argument(EKEY_NOT_FOUND));

        let child = remove_at(self, path_to_leaf, key);
        let Child { tag: _, Inner: inner, Leaf: leaf } = child;
        option::destroy_none(inner);
        let ChildLeafData { value } = option::destroy_some(leaf);
        value
    }

    /// Removes the entry from BigOrderedMap and returns the value which `key` maps to.
    /// Returns none if there is no entry for `key`.
    public fun remove_or_none<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, key: &K): Option<V> {
        // Optimize case where only root node exists
        // (optimizes out borrowing and path creation in `find_leaf_path`)
        let root = &self.root;
        if (root.is_leaf) {
            let root_mut = &mut self.root;
            let value_option = ordered_map::remove_or_none(&mut root_mut.children, key);
            if (option::is_some(&value_option)) {
                let child = option::destroy_some(value_option);
                let Child { tag: _, Inner: inner, Leaf: leaf } = child;
                option::destroy_none(inner);
                let ChildLeafData { value } = option::destroy_some(leaf);
                return option::some(value)
            } else {
                option::destroy_none(value_option);
                return option::none()
            }
        };

        let path_to_leaf = find_leaf_path(self, key);

        if (vector::is_empty(&path_to_leaf)) {
            option::none()
        } else {
            let child = remove_at(self, path_to_leaf, key);
            let Child { tag: _, Inner: inner, Leaf: leaf } = child;
            option::destroy_none(inner);
            let ChildLeafData { value } = option::destroy_some(leaf);
            option::some(value)
        }
    }

    /// Modifies the element in the map via calling f.
    /// Aborts if element doesn't exist
    public inline fun modify<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, key: &K, f: |&mut V|) {
        modify_and_return(self, key, |v| { f(v); true});
    }

    /// Modifies the element in the map via calling f, and propagates the return value of the function.
    /// Aborts if element doesn't exist
    ///
    /// This function cannot be inline, due to iter_modify requiring actual function value.
    /// This also is why we return a value
    public inline fun modify_and_return<K: drop + copy + store, V: store, R>(self: &mut BigOrderedMap<K, V>, key: &K, f: |&mut V|R): R {
        let iter = internal_find(self, key);
        assert!(!iter_is_end(&iter, self), error::invalid_argument(EKEY_NOT_FOUND));
        iter_modify(iter, self, |v| f(v))
    }

    /// Modifies element by calling modify_f if it exists, or calling add_f to add if it doesn't.
    /// Returns true if element already existed.
    public inline fun modify_or_add<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, key: &K, modify_f: |&mut V|, add_f: ||V): bool {
        let exists = modify_if_present(self, key, |v| modify_f(v));
        if (!exists) {
            add(self, *key, add_f());
        };
        exists
    }

    public inline fun modify_if_present<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, key: &K, modify_f: |&mut V|): bool {
        let result = modify_if_present_and_return(self, key, |v| { modify_f(v); true });
        let exists = option::is_some(&result);
        if (exists) {
            option::destroy_some(result);
        } else {
            option::destroy_none(result);
        };
        exists
    }

    /// Modifies the element in the map via calling modify_f, and propagates the return value of the function.
    /// Returns None if not present.
    ///
    /// Function value cannot be inlined, due to iter_modify requiring actual function value.
    /// This also is why we return a value
    public inline fun modify_if_present_and_return<K: drop + copy + store, V: store, R>(self: &mut BigOrderedMap<K, V>, key: &K, modify_f: |&mut V|R): Option<R> {
        let iter = internal_find(self, key);
        if (iter_is_end(&iter, self)) {
            option::none()
        } else {
            option::some(iter_modify(iter, self, |v| modify_f(v)))
        }
    }

    // /// If value exists, calls modify_f on it, which returns tuple (to_keep, result).
    // /// If to_keep is false, value is deleted from the map, and option::some(result) is returned.
    // /// This function cannot be inline, due to iter_modify requiring actual function value.
    // /// This also is why we return a value
    // public fun modify_or_remove_if_present_and_return<K: drop + copy + store, V: store, R>(self: &mut BigOrderedMap<K, V>, key: &K, modify_f: |&mut V|(R, bool) has drop): Option<R> {
    //     let iter = find(self, key);
    //     if (iter_is_end(&iter, self)) {
    //         option::none()
    //     } else {
    //         let (result, keep) = iter_modify(iter, self, modify_f);
    //         if (!keep) {
    //             iter_remove(iter, self);
    //         };
    //         option::some(result)
    //     }
    // }

    /// Add multiple key/value pairs to the map. The keys must not already exist.
    /// Aborts with EKEY_ALREADY_EXISTS if key already exist, or duplicate keys are passed in.
    public fun add_all<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, keys: vector<K>, values: vector<V>) {
        // TODO: Can be optimized, both in insertion order (largest first, then from smallest),
        // as well as on initializing inner_max_degree/leaf_max_degree better
        vector::zip(keys, values, |key, value| {
            add(self, key, value);
        });
    }

    public fun pop_front<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>): (K, V) {
        let it = internal_new_begin_iter(self);
        let k = *iter_borrow_key(&it);
        let v = remove(self, &k);
        (k, v)
    }

    public fun pop_back<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>): (K, V) {
        let it = iter_prev(internal_new_end_iter(self), self);
        let k = *iter_borrow_key(&it);
        let v = remove(self, &k);
        (k, v)
    }

    // ============================= Accessors ================================

    /// Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
    /// For direct usage of this method, check Warning at the top of the file corresponding to iterators.
    ///
    /// Returns an iterator pointing to the first element that is greater or equal to the provided
    /// key, or an end iterator if such element doesn't exist.
    public fun internal_lower_bound<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, key: &K): IteratorPtr<K> {
        let leaf = find_leaf(self, key);
        if (leaf == NULL_INDEX) {
            return internal_new_end_iter(self)
        };

        let node = borrow_node(self, leaf);
        assert!(node.is_leaf, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

        let child_lower_bound = ordered_map::internal_lower_bound(&node.children, key);
        if (ordered_map::iter_is_end(&child_lower_bound, &node.children)) {
            internal_new_end_iter(self)
        } else {
            let iter_key = *ordered_map::iter_borrow_key(&child_lower_bound, &node.children);
            new_iter(leaf, child_lower_bound, iter_key)
        }
    }

    /// Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
    /// For direct usage of this method, check Warning at the top of the file corresponding to iterators.
    ///
    /// Returns an iterator pointing to the element that equals to the provided key, or an end
    /// iterator if the key is not found.
    public fun internal_find<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, key: &K): IteratorPtr<K> {
        let internal_lower_bound = internal_lower_bound(self, key);
        if (iter_is_end(&internal_lower_bound, self)) {
            internal_lower_bound
        } else {
            let iter_key = iter_borrow_key(&internal_lower_bound);
            if (iter_key == key) {
                internal_lower_bound
            } else {
                internal_new_end_iter(self)
            }
        }
    }

    /// Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
    /// For direct usage of this method, check Warning at the top of the file corresponding to iterators.
    ///
    public fun internal_find_with_path<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, key: &K): IteratorPtrWithPath<K> {
        let leaf_path = find_leaf_path(self, key);
        if (vector::is_empty(&leaf_path)) {
            return IteratorPtrWithPath { iterator: internal_new_end_iter(self), path: vector::empty() }
        };

        let leaf_index = vector::length(&leaf_path) - 1;
        let leaf = *vector::borrow(&leaf_path, leaf_index);
        let node = borrow_node(self, leaf);
        assert!(node.is_leaf, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

        let child_lower_bound = ordered_map::internal_lower_bound(&node.children, key);
        if (ordered_map::iter_is_end(&child_lower_bound, &node.children)) {
            IteratorPtrWithPath { iterator: internal_new_end_iter(self), path: vector::empty() }
        } else {
            let iter_key = *ordered_map::iter_borrow_key(&child_lower_bound, &node.children);

            if (&iter_key == key) {
                IteratorPtrWithPath { iterator: new_iter(leaf, child_lower_bound, iter_key), path: leaf_path }
            } else {
                IteratorPtrWithPath { iterator: internal_new_end_iter(self), path: vector::empty() }
            }
        }
    }

    public fun iter_with_path_get_iter<K: drop + copy + store>(self: &IteratorPtrWithPath<K>): IteratorPtr<K> {
        self.iterator
    }

    /// Returns true iff the key exists in the map.
    public fun contains<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, key: &K): bool {
        let internal_lower_bound = internal_lower_bound(self, key);
        if (iter_is_end(&internal_lower_bound, self)) {
            false
        } else {
            let iter_key = iter_borrow_key(&internal_lower_bound);
            iter_key == key
        }
    }

    /// Returns a reference to the element with its key, aborts if the key is not found.
    public fun borrow<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, key: &K): &V {
        let iter = internal_find(self, key);
        assert!(!iter_is_end(&iter, self), error::invalid_argument(EKEY_NOT_FOUND));

        iter_borrow(iter, self)
    }

    public fun get<K: drop + copy + store, V: copy + store>(self: &BigOrderedMap<K, V>, key: &K): Option<V> {
        let iter = internal_find(self, key);
        if (iter_is_end(&iter, self)) {
            option::none()
        } else {
            option::some(*iter_borrow(iter, self))
        }
    }

    public inline fun get_and_map<K: drop + copy + store, V: copy + store, R>(self: &BigOrderedMap<K, V>, key: &K, f: |&V|R): Option<R> {
        let iter = internal_find(self, key);
        if (iter_is_end(&iter, self)) {
            option::none()
        } else {
            option::some(f(iter_borrow(iter, self)))
        }
    }

    /// Returns a mutable reference to the element with its key at the given index, aborts if the key is not found.
    /// Aborts with EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE if KV size doesn't have constant size,
    /// because if it doesn't we cannot assert invariants on the size.
    /// In case of variable size, use either `borrow`, `copy` then `upsert`, or `remove` and `add` instead of mutable borrow.
    public fun borrow_mut<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, key: &K): &mut V {
        let iter = internal_find(self, key);
        assert!(!iter_is_end(&iter, self), error::invalid_argument(EKEY_NOT_FOUND));
        iter_borrow_mut(iter, self)
    }
    public fun borrow_front<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>): (K, &V) {
        let it = internal_new_begin_iter(self);
        let key = *iter_borrow_key(&it);
        (key, iter_borrow(it, self))
    }

    public fun borrow_back<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>): (K, &V) {
        let it = iter_prev(internal_new_end_iter(self), self);
        let key = *iter_borrow_key(&it);
        (key, iter_borrow(it, self))
    }

    public fun prev_key<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, key: &K): Option<K> {
        let it = internal_lower_bound(self, key);
        if (iter_is_begin(&it, self)) {
            option::none()
        } else {
            let prev_it = iter_prev(it, self);
            option::some(*iter_borrow_key(&prev_it))
        }
    }

    public fun next_key<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, key: &K): Option<K> {
        let it = internal_lower_bound(self, key);
        if (iter_is_end(&it, self)) {
            option::none()
        } else {
            let cur_key = iter_borrow_key(&it);
            if (key == cur_key) {
                let next_it = iter_next(it, self);
                if (iter_is_end(&next_it, self)) {
                    option::none()
                } else {
                    option::some(*iter_borrow_key(&next_it))
                }
            } else {
                option::some(*cur_key)
            }
        }
    }

    // =========================== Views and Traversals ==============================

    /// Convert a BigOrderedMap to an OrderedMap, which is supposed to be called mostly by view functions to get an atomic
    /// view of the whole map.
    /// Disclaimer: This function may be costly as the BigOrderedMap may be huge in size. Use it at your own discretion.
    public fun to_ordered_map<K: drop + copy + store, V: copy + store>(self: &BigOrderedMap<K, V>): OrderedMap<K, V> {
        let result = ordered_map::new();
        let result_ref = &mut result;
        for_each_ref(self, |k, v| {
            let iter = ordered_map::internal_new_end_iter(result_ref);
            ordered_map::iter_add(iter, result_ref, *k, *v);
        });
        result
    }

    /// Get all keys.
    ///
    /// For a large enough BigOrderedMap this function will fail due to execution gas limits,
    /// use iterartor or next_key/prev_key to iterate over across portion of the map.
    public fun keys<K: store + copy + drop, V: store + copy>(self: &BigOrderedMap<K, V>): vector<K> {
        let result = vector[];
        for_each_ref(self, |k, _v| {
            vector::push_back(&mut result, *k);
        });
        result
    }

    /// Apply the function to each element in the vector, consuming it, leaving the map empty.
    ///
    /// Current implementation is O(n * log(n)). After function values will be optimized
    /// to O(n).
    public inline fun for_each_and_clear<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, f: |K, V|) {
        // TODO - this can be done more efficiently, by destroying the leaves directly
        // but that requires more complicated code and testing.
        while (!is_empty(self)) {
            let (k, v) = pop_front(self);
            f(k, v);
        };
    }

    /// Apply the function to each element in the vector, consuming it, and consuming the map
    ///
    /// Current implementation is O(n * log(n)). After function values will be optimized
    /// to O(n).
    public inline fun for_each<K: drop + copy + store, V: store>(self: BigOrderedMap<K, V>, f: |K, V|) {
        // TODO - this can be done more efficiently, by destroying the leaves directly
        // but that requires more complicated code and testing.
        let map_mut = self;
        for_each_and_clear(&mut map_mut, |k, v| f(k, v));
        destroy_empty(map_mut)
    }

    /// Apply the function to a reference of each element in the vector.
    public inline fun for_each_ref<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, f: |&K, &V|) {
        for_each_leaf_node_children_ref(self, |children| {
            ordered_map::for_each_ref(children, |k, v| {
                f(k, internal_leaf_borrow_value(v));
            });
        })
    }

    /// Calls given function on a tuple (key, self[key], other[key]) for all keys present in both maps.
    public inline fun intersection_zip_for_each_ref<K: drop + copy + store, V1: store, V2: store>(self: &BigOrderedMap<K, V1>, other: &BigOrderedMap<K, V2>, f: |&K, &V1, &V2|) {
        // only roots can have empty children, if maps are not empty, we
        // never need to check on child_iter.iter_is_end on a new iterator.
        if (!is_empty(self) && !is_empty(other)) {
            let iter1 = internal_leaf_new_begin_iter(self);
            let iter2 = internal_leaf_new_begin_iter(other);
            let (children1, iter1) = internal_leaf_iter_borrow_entries_and_next_leaf_index(iter1, self);
            let (children2, iter2) = internal_leaf_iter_borrow_entries_and_next_leaf_index(iter2, other);

            let child_iter1 = ordered_map::internal_new_begin_iter(children1);
            let child_iter2 = ordered_map::internal_new_begin_iter(children2);

            loop {
                let key1 = ordered_map::iter_borrow_key(&child_iter1, children1);
                let key2 = ordered_map::iter_borrow_key(&child_iter2, children2);
                let ordering = cmp::compare(key1, key2);
                let inc1 = false;
                let inc2 = false;
                if (cmp::is_lt(&ordering)) {
                    inc1 = true;
                } else if (cmp::is_gt(&ordering)) {
                    inc2 = true;
                } else {
                    f(key1, internal_leaf_borrow_value(ordered_map::iter_borrow(copy child_iter1, children1)), internal_leaf_borrow_value(ordered_map::iter_borrow(copy child_iter2, children2)));
                    inc1 = true;
                    inc2 = true;
                };
                if (inc1) {
                    child_iter1 = ordered_map::iter_next(child_iter1, children1);
                    if (ordered_map::iter_is_end(&child_iter1, children1)) {
                        if (internal_leaf_iter_is_end(&iter1)) {
                            break
                        };
                        let (new_children, new_iter) = internal_leaf_iter_borrow_entries_and_next_leaf_index(iter1, self);
                        iter1 = new_iter;
                        children1 = new_children;
                        child_iter1 = ordered_map::internal_new_begin_iter(children1);
                    };
                };
                if (inc2) {
                    child_iter2 = ordered_map::iter_next(child_iter2, children2);
                    if (ordered_map::iter_is_end(&child_iter2, children2)) {
                        if (internal_leaf_iter_is_end(&iter2)) {
                            break
                        };
                        let (new_children, new_iter) = internal_leaf_iter_borrow_entries_and_next_leaf_index(iter2, other);
                        iter2 = new_iter;
                        children2 = new_children;
                        child_iter2 = ordered_map::internal_new_begin_iter(children2);
                    };
                };
            }
        }
    }

    /// Apply the function to a mutable reference of each key-value pair in the map.
    public inline fun for_each_mut<K: copy + drop + store, V: store>(self: &mut BigOrderedMap<K, V>, f: |&K, &mut V|) {
        let iter = internal_new_begin_iter(self);
        while (!iter_is_end(&iter, self)) {
            let key = *iter_borrow_key(&iter);
            f(&key, iter_borrow_mut(iter, self));
            iter = iter_next(iter, self);
        }
    }

    /// Destroy a map, by destroying elements individually.
    ///
    /// Current implementation is O(n * log(n)). After function values will be optimized
    /// to O(n).
    public inline fun destroy<K: drop + copy + store, V: store>(self: BigOrderedMap<K, V>, dv: |V|) {
        for_each(self, |_k, v| {
            dv(v);
        });
    }

    // ========================= IteratorPtr functions ===========================

    /// Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
    /// For direct usage of this method, check Warning at the top of the file corresponding to iterators.
    ///
    /// Returns the begin iterator.
    public fun internal_new_begin_iter<K: copy + store, V: store>(self: &BigOrderedMap<K, V>): IteratorPtr<K> {
        if (is_empty(self)) {
            return IteratorPtr {
                tag: 1,
                End: option::some(true),
                Some: option::none(),
            }
        };

        let node = borrow_node(self, self.min_leaf_index);
        assert!(!ordered_map::is_empty(&node.children), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        let begin_child_iter = ordered_map::internal_new_begin_iter(&node.children);
        let begin_child_key = *ordered_map::iter_borrow_key(&begin_child_iter, &node.children);
        new_iter(self.min_leaf_index, begin_child_iter, begin_child_key)
    }

    /// Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
    /// For direct usage of this method, check Warning at the top of the file corresponding to iterators.
    ///
    /// Returns the end iterator.
    public fun internal_new_end_iter<K: copy + store, V: store>(_self: &BigOrderedMap<K, V>): IteratorPtr<K> {
        IteratorPtr {
            tag: 1,
            End: option::some(true),
            Some: option::none(),
        }
    }

    // Returns true iff the iterator is a begin iterator.
    public fun iter_is_begin<K: store, V: store>(self: &IteratorPtr<K>, map: &BigOrderedMap<K, V>): bool {
        if (option::is_some(&self.End)) {
            is_empty(map)
        } else {
            let some_data = option::borrow(&self.Some);
            (some_data.node_index == map.min_leaf_index && ordered_map::iter_is_begin_from_non_empty(&some_data.child_iter))
        }
    }

    // Returns true iff the iterator is an end iterator.
    public fun iter_is_end<K: store, V: store>(self: &IteratorPtr<K>, _map: &BigOrderedMap<K, V>): bool {
        option::is_some(&self.End)
    }

    /// Borrows the key given iterator points to.
    /// Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
    /// Note: Requires that the map is not changed after the input iterator is generated.
    public fun iter_borrow_key<K>(self: &IteratorPtr<K>): &K {
        assert!(!option::is_some(&self.End), error::invalid_argument(EITER_OUT_OF_BOUNDS));
        let some_data = option::borrow(&self.Some);
        &some_data.key
    }

    /// Borrows the value given iterator points to.
    /// Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
    /// Note: Requires that the map is not changed after the input iterator is generated.
    public fun iter_borrow<K: drop + store, V: store>(self: IteratorPtr<K>, map: &BigOrderedMap<K, V>): &V {
        assert!(!iter_is_end(&self, map), error::invalid_argument(EITER_OUT_OF_BOUNDS));
        let some_data = option::borrow(&self.Some);
        let node = borrow_node(map, some_data.node_index);
        let child = ordered_map::iter_borrow(some_data.child_iter, &node.children);
        let leaf_data = option::borrow(&child.Leaf);
        &leaf_data.value
    }

    /// Mutably borrows the value iterator points to.
    /// Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
    /// Aborts with EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE if KV size doesn't have constant size,
    /// because if it doesn't we cannot assert invariants on the size.
    /// In case of variable size, use either `borrow`, `copy` then `upsert`, or `remove` and `add` instead of mutable borrow.
    ///
    /// Note: Requires that the map is not changed after the input iterator is generated.
    public fun iter_borrow_mut<K: drop + store, V: store>(self: IteratorPtr<K>, map: &mut BigOrderedMap<K, V>): &mut V {
        let value_size_opt = bcs::constant_serialized_size<V>();
        let has_const_value = option::is_some(&value_size_opt);
        if (has_const_value) {
            option::destroy_some(value_size_opt);
        } else {
            option::destroy_none(value_size_opt);
        };
        assert!(map.constant_kv_size || has_const_value, error::invalid_argument(EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE));
        assert!(!iter_is_end(&self, map), error::invalid_argument(EITER_OUT_OF_BOUNDS));
        let some_data = option::borrow(&self.Some);
        let node = borrow_node_mut(map, some_data.node_index);
        let child = ordered_map::iter_borrow_mut(some_data.child_iter, &mut node.children);
        let leaf_data = option::borrow_mut(&mut child.Leaf);
        &mut leaf_data.value
    }

    public inline fun iter_modify<K: drop + copy + store, V: store, R>(self: IteratorPtr<K>, map: &mut BigOrderedMap<K, V>, f: |&mut V|R): R {
        assert!(!iter_is_end(&self, map), error::invalid_argument(EITER_OUT_OF_BOUNDS));
        let key = *iter_borrow_key(&self);
        let value_mut = iter_borrow_mut(self, map);
        let result = f(value_mut);

        if (map.constant_kv_size) {
            return result
        };

        // validate that after modifications size invariants hold
        let key_size = bcs::serialized_size(&key);
        let value_size = bcs::serialized_size(value_mut);
        validate_size_and_init_max_degrees(map, key_size, value_size);
        result
    }

    /// Removes the entry from BigOrderedMap and returns the value which `key` maps to.
    /// Aborts if there is no entry for `key`.
    public fun iter_remove<K: drop + copy + store, V: store>(self: IteratorPtrWithPath<K>, map: &mut BigOrderedMap<K, V>): V {
        let IteratorPtrWithPath { iterator: iter, path: path_to_leaf } = self;
        assert!(!iter_is_end(&iter, map), error::invalid_argument(EITER_OUT_OF_BOUNDS));
        let some_data = option::borrow(&iter.Some);
        let child_iter = some_data.child_iter;
        let key = some_data.key;

        // Optimize case where only root node exists
        // (optimizes out borrowing and path creation in `find_leaf_path`)
        let root = &map.root;
        if (root.is_leaf) {
            let root_mut = &mut map.root;
            let child = ordered_map::iter_remove(child_iter, &mut root_mut.children);
            let Child { tag: _, Inner: inner, Leaf: leaf } = child;
            option::destroy_none(inner);
            let ChildLeafData { value } = option::destroy_some(leaf);
            return value
        };

        assert!(!vector::is_empty(&path_to_leaf), error::invalid_argument(EKEY_NOT_FOUND));

        let child = remove_at(map, path_to_leaf, &key);
        let Child { tag: _, Inner: inner, Leaf: leaf } = child;
        option::destroy_none(inner);
        let ChildLeafData { value } = option::destroy_some(leaf);
        value
    }

    /// Returns the next iterator.
    /// Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
    /// Requires the map is not changed after the input iterator is generated.
    public fun iter_next<K: drop + copy + store, V: store>(self: IteratorPtr<K>, map: &BigOrderedMap<K, V>): IteratorPtr<K> {
        assert!(!option::is_some(&self.End), error::invalid_argument(EITER_OUT_OF_BOUNDS));

        let some_data = option::borrow(&self.Some);
        let node_index = some_data.node_index;
        let node = borrow_node(map, node_index);

        let child_iter = ordered_map::iter_next(some_data.child_iter, &node.children);
        if (!ordered_map::iter_is_end(&child_iter, &node.children)) {
            // next is in the same leaf node
            let iter_key = *ordered_map::iter_borrow_key(&child_iter, &node.children);
            return new_iter(node_index, child_iter, iter_key)
        };

        // next is in a different leaf node
        let next_index = node.next;
        if (next_index != NULL_INDEX) {
            let next_node = borrow_node(map, next_index);
            let child_iter = ordered_map::internal_new_begin_iter(&next_node.children);
            assert!(!ordered_map::iter_is_end(&child_iter, &next_node.children), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
            let iter_key = *ordered_map::iter_borrow_key(&child_iter, &next_node.children);
            return new_iter(next_index, child_iter, iter_key)
        };

        internal_new_end_iter(map)
    }

    /// Returns the previous iterator.
    /// Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the beginning.
    /// Requires the map is not changed after the input iterator is generated.
    public fun iter_prev<K: drop + copy + store, V: store>(self: IteratorPtr<K>, map: &BigOrderedMap<K, V>): IteratorPtr<K> {
        let prev_index = if (option::is_some(&self.End)) {
            map.max_leaf_index
        } else {
            let some_data = option::borrow(&self.Some);
            let node_index = some_data.node_index;
            let node = borrow_node(map, node_index);

            if (!ordered_map::iter_is_begin(&some_data.child_iter, &node.children)) {
                // next is in the same leaf node
                let child_iter = ordered_map::iter_prev(some_data.child_iter, &node.children);
                let key = *ordered_map::iter_borrow_key(&child_iter, &node.children);
                return new_iter(node_index, child_iter, key)
            };
            node.prev
        };

        assert!(prev_index != NULL_INDEX, error::invalid_argument(EITER_OUT_OF_BOUNDS));

        // next is in a different leaf node
        let prev_node = borrow_node(map, prev_index);
        let prev_children = &prev_node.children;
        let end_iter = ordered_map::internal_new_end_iter(prev_children);
        let child_iter = ordered_map::iter_prev(end_iter, prev_children);
        let iter_key = *ordered_map::iter_borrow_key(&child_iter, prev_children);
        new_iter(prev_index, child_iter, iter_key)
    }

    // ====================== Internal Implementations ========================

    /// Data for the NodeIndex variant of LeafNodeIteratorPtr
    struct LeafNodeIteratorPtrNodeIndexData has copy, drop {
        /// The node index of the iterator pointing to.
        /// NULL_INDEX if end iterator
        node_index: u64,
    }

    struct LeafNodeIteratorPtr has copy, drop {
        tag: u8,
        NodeIndex: Option<LeafNodeIteratorPtrNodeIndexData>,
    }

    public fun internal_leaf_new_begin_iter<K: store, V: store>(self: &BigOrderedMap<K, V>): LeafNodeIteratorPtr {
        LeafNodeIteratorPtr {
            tag: 1,
            NodeIndex: option::some(LeafNodeIteratorPtrNodeIndexData { node_index: self.min_leaf_index }),
        }
    }

    public fun internal_leaf_iter_is_end(self: &LeafNodeIteratorPtr): bool {
        let node_index_data = option::borrow(&self.NodeIndex);
        node_index_data.node_index == NULL_INDEX
    }

    public fun internal_leaf_borrow_value<V: store>(self: &Child<V>): &V {
        let leaf_data = option::borrow(&self.Leaf);
        &leaf_data.value
    }

    public fun internal_leaf_iter_borrow_entries_and_next_leaf_index<K: store, V: store>(self: LeafNodeIteratorPtr, map: &BigOrderedMap<K, V>): (&OrderedMap<K, Child<V>>, LeafNodeIteratorPtr) {
        let node_index_data = option::borrow(&self.NodeIndex);
        assert!(node_index_data.node_index != NULL_INDEX, EITER_OUT_OF_BOUNDS);

        let node = borrow_node(map, node_index_data.node_index);
        assert!(node.is_leaf, EINTERNAL_INVARIANT_BROKEN);
        let new_iter = LeafNodeIteratorPtr {
            tag: 1,
            NodeIndex: option::some(LeafNodeIteratorPtrNodeIndexData { node_index: node.next }),
        };
        (&node.children, new_iter)
    }

    inline fun for_each_leaf_node_children_ref<K: store, V: store>(self: &BigOrderedMap<K, V>, f: |&OrderedMap<K, Child<V>>|) {
        let iter = internal_leaf_new_begin_iter(self);

        while (!internal_leaf_iter_is_end(&iter)) {
            let (node, next_iter) = internal_leaf_iter_borrow_entries_and_next_leaf_index(iter, self);
            f(node);
            iter = next_iter;
        }
    }

    /// Borrow a node, given an index. Works for both root (i.e. inline) node and separately stored nodes
    inline fun borrow_node<K: store, V: store>(self: &BigOrderedMap<K, V>, node_index: u64): &Node<K, V> {
        if (node_index == ROOT_INDEX) {
            &self.root
        } else {
            storage_slots_allocator::borrow(&self.nodes, node_index)
        }
    }

    /// Borrow a node mutably, given an index. Works for both root (i.e. inline) node and separately stored nodes
    inline fun borrow_node_mut<K: store, V: store>(self: &mut BigOrderedMap<K, V>, node_index: u64): &mut Node<K, V> {
        if (node_index == ROOT_INDEX) {
            &mut self.root
        } else {
            storage_slots_allocator::borrow_mut(&mut self.nodes, node_index)
        }
    }

    fun add_or_upsert_impl<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, key: K, value: V, allow_overwrite: bool): Option<Child<V>> {
        if (!self.constant_kv_size) {
            validate_dynamic_size_and_init_max_degrees(self, &key, &value);
        };

        // Optimize case where only root node exists
        // (optimizes out borrowing and path creation in `find_leaf_path`)
        if (self.root.is_leaf) {
            let leaf_max_degree = self.leaf_max_degree;
            let root_mut = &mut self.root;
            let children = &mut root_mut.children;
            let degree = ordered_map::length(children);

            if (degree < leaf_max_degree) {
                let result = ordered_map::upsert(children, key, new_leaf_child(value));
                assert!(allow_overwrite || option::is_none(&result), error::invalid_argument(EKEY_ALREADY_EXISTS));
                return result
            };
        };

        let path_to_leaf = find_leaf_path(self, &key);

        if (vector::is_empty(&path_to_leaf)) {
            // In this case, the key is greater than all keys in the map.
            // So we need to update `key` in the pointers to the last (rightmost) child
            // on every level, to maintain the invariant of `add_at`
            // we also create a path_to_leaf to the rightmost leaf.
            let current = ROOT_INDEX;

            loop {
                vector::push_back(&mut path_to_leaf, current);

                let current_node = borrow_node_mut(self, current);
                if (current_node.is_leaf) {
                    break
                };
                let last_iter = ordered_map::iter_prev(
                    ordered_map::internal_new_end_iter(&current_node.children),
                    &current_node.children,
                );
                let last_value = ordered_map::iter_remove(last_iter, &mut current_node.children);
                let inner_data = option::borrow(&last_value.Inner);
                current = storage_slots_allocator::stored_to_index(&inner_data.node_index);
                ordered_map::add(&mut current_node.children, key, last_value);
            };
        };

        add_at(self, path_to_leaf, key, new_leaf_child(value), allow_overwrite)
    }

    fun validate_dynamic_size_and_init_max_degrees<K: store, V: store>(self: &mut BigOrderedMap<K, V>, key: &K, value: &V) {
        let key_size = bcs::serialized_size(key);
        let value_size = bcs::serialized_size(value);
        validate_size_and_init_max_degrees(self, key_size, value_size)
    }

    fun validate_static_size_and_init_max_degrees<K: store, V: store>(self: &mut BigOrderedMap<K, V>) {
        let key_size_opt = bcs::constant_serialized_size<K>();

        if (option::is_some(&key_size_opt)) {
            let key_size = option::destroy_some(key_size_opt);
            if (self.inner_max_degree == 0) {
                self.inner_max_degree = max(min(MAX_DEGREE, DEFAULT_TARGET_NODE_SIZE / key_size), INNER_MIN_DEGREE);
            };
            assert!(key_size * self.inner_max_degree <= MAX_NODE_BYTES, error::invalid_argument(EKEY_BYTES_TOO_LARGE));

            let value_size_opt = bcs::constant_serialized_size<V>();
            if (option::is_some(&value_size_opt)) {
                let value_size = option::destroy_some(value_size_opt);
                let entry_size = key_size + value_size;

                if (self.leaf_max_degree == 0) {
                    self.leaf_max_degree = max(min(MAX_DEGREE, DEFAULT_TARGET_NODE_SIZE / entry_size), LEAF_MIN_DEGREE);
                };
                assert!(entry_size * self.leaf_max_degree <= MAX_NODE_BYTES, error::invalid_argument(EARGUMENT_BYTES_TOO_LARGE));

                self.constant_kv_size = true;
            } else {
                option::destroy_none(value_size_opt);
            };
        } else {
            option::destroy_none(key_size_opt);
        }
    }

    fun validate_size_and_init_max_degrees<K: store, V: store>(self: &mut BigOrderedMap<K, V>, key_size: u64, value_size: u64) {
        let entry_size = key_size + value_size;

        if (self.inner_max_degree == 0) {
            let default_max_degree = min(MAX_DEGREE, MAX_NODE_BYTES / DEFAULT_MAX_KEY_OR_VALUE_SIZE);
            self.inner_max_degree = max(min(default_max_degree, DEFAULT_TARGET_NODE_SIZE / key_size), INNER_MIN_DEGREE);
        };

        if (self.leaf_max_degree == 0) {
            let default_max_degree = min(MAX_DEGREE, MAX_NODE_BYTES / DEFAULT_MAX_KEY_OR_VALUE_SIZE / 2);
            self.leaf_max_degree = max(min(default_max_degree, DEFAULT_TARGET_NODE_SIZE / entry_size), LEAF_MIN_DEGREE);
        };

        // Make sure that no nodes can exceed the upper size limit.
        assert!(key_size * self.inner_max_degree <= MAX_NODE_BYTES, error::invalid_argument(EKEY_BYTES_TOO_LARGE));
        assert!(entry_size * self.leaf_max_degree <= MAX_NODE_BYTES, error::invalid_argument(EARGUMENT_BYTES_TOO_LARGE));
    }

    fun destroy_inner_child<V: store>(self: Child<V>): StoredSlot {
        let Child { tag: _, Inner: inner, Leaf: leaf } = self;
        option::destroy_none(leaf);
        let ChildInnerData { node_index } = option::destroy_some(inner);
        node_index
    }

    fun destroy_empty_node<K: store, V: store>(self: Node<K, V>) {
        let Node { is_leaf: _, children, prev: _, next: _ } = self;
        assert!(ordered_map::is_empty(&children), error::invalid_argument(EMAP_NOT_EMPTY));
        ordered_map::destroy_empty(children);
    }

    fun new_node<K: store, V: store>(is_leaf: bool): Node<K, V> {
        Node {
            is_leaf: is_leaf,
            children: ordered_map::new(),
            prev: NULL_INDEX,
            next: NULL_INDEX,
        }
    }

    fun new_node_with_children<K: store, V: store>(is_leaf: bool, children: OrderedMap<K, Child<V>>): Node<K, V> {
        Node {
            is_leaf: is_leaf,
            children: children,
            prev: NULL_INDEX,
            next: NULL_INDEX,
        }
    }

    fun new_inner_child<V: store>(node_index: StoredSlot): Child<V> {
        Child {
            tag: 1,
            Inner: option::some(ChildInnerData { node_index: node_index }),
            Leaf: option::none(),
        }
    }

    fun new_leaf_child<V: store>(value: V): Child<V> {
        Child {
            tag: 2,
            Inner: option::none(),
            Leaf: option::some(ChildLeafData { value: value }),
        }
    }

    fun new_iter<K>(node_index: u64, child_iter: ordered_map::IteratorPtr, key: K): IteratorPtr<K> {
        IteratorPtr {
            tag: 2,
            End: option::none(),
            Some: option::some(IteratorPtrSomeData {
                node_index: node_index,
                child_iter: child_iter,
                key: key,
            }),
        }
    }

    /// Find leaf where the given key would fall in.
    /// So the largest leaf with its `max_key <= key`.
    /// return NULL_INDEX if `key` is larger than any key currently stored in the map.
    fun find_leaf<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, key: &K): u64 {
        let current = ROOT_INDEX;
        loop {
            let node = borrow_node(self, current);
            if (node.is_leaf) {
                return current
            };
            let children = &node.children;
            let child_iter = ordered_map::internal_lower_bound(children, key);
            if (ordered_map::iter_is_end(&child_iter, children)) {
                return NULL_INDEX
            } else {
                let child = ordered_map::iter_borrow(child_iter, children);
                let inner_data = option::borrow(&child.Inner);
                current = storage_slots_allocator::stored_to_index(&inner_data.node_index);
            };
        }
    }

    /// Find leaf where the given key would fall in.
    /// So the largest leaf with it's `max_key <= key`.
    /// Returns the path from root to that leaf (including the leaf itself)
    /// Returns empty path if `key` is larger than any key currently stored in the map.
    fun find_leaf_path<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, key: &K): vector<u64> {
        let vec = vector::empty();

        let current = ROOT_INDEX;
        loop {
            vector::push_back(&mut vec, current);

            let node = borrow_node(self, current);
            if (node.is_leaf) {
                return vec
            };
            let children = &node.children;
            let child_iter = ordered_map::internal_lower_bound(children, key);
            if (ordered_map::iter_is_end(&child_iter, children)) {
                return vector::empty()
            } else {
                let child = ordered_map::iter_borrow(child_iter, children);
                let inner_data = option::borrow(&child.Inner);
                current = storage_slots_allocator::stored_to_index(&inner_data.node_index);
            };
        }
    }

    fun get_max_degree<K: store, V: store>(self: &BigOrderedMap<K, V>, leaf: bool): u64 {
        if (leaf) {
            self.leaf_max_degree
        } else {
            self.inner_max_degree
        }
    }

    fun replace_root<K: store, V: store>(self: &mut BigOrderedMap<K, V>, new_root: Node<K, V>): Node<K, V> {
        let root = &mut self.root;
        let tmp_is_leaf = root.is_leaf;
        root.is_leaf = new_root.is_leaf;
        new_root.is_leaf = tmp_is_leaf;

        assert!(root.prev == NULL_INDEX, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        assert!(root.next == NULL_INDEX, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        assert!(new_root.prev == NULL_INDEX, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        assert!(new_root.next == NULL_INDEX, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

        // let tmp_prev = root.prev;
        // root.prev = new_root.prev;
        // new_root.prev = tmp_prev;

        // let tmp_next = root.next;
        // root.next = new_root.next;
        // new_root.next = tmp_next;

        let tmp_children = ordered_map::trim(&mut root.children, 0);
        let new_root_children_trimmed = ordered_map::trim(&mut new_root.children, 0);
        ordered_map::append_disjoint(&mut root.children, new_root_children_trimmed);
        ordered_map::append_disjoint(&mut new_root.children, tmp_children);

        new_root
    }

    /// Add a given child to a given node (last in the `path_to_node`), and update/rebalance the tree as necessary.
    /// It is required that `key` pointers to the child node, on the `path_to_node` are greater or equal to the given key.
    /// That means if we are adding a `key` larger than any currently existing in the map - we needed
    /// to update `key` pointers on the `path_to_node` to include it, before calling this method.
    ///
    /// Returns Child previously associated with the given key.
    /// If `allow_overwrite` is not set, function will abort if `key` is already present.
    fun add_at<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, path_to_node: vector<u64>, key: K, child: Child<V>, allow_overwrite: bool): Option<Child<V>> {
        // Last node in the path is one where we need to add the child to.
        let node_index = vector::pop_back(&mut path_to_node);
        {
            // First check if we can perform this operation, without changing structure of the tree (i.e. without adding any nodes).

            // For that we can just borrow the single node
            let node = borrow_node_mut(self, node_index);
            let children = &mut node.children;
            let degree = ordered_map::length(children);

            // Compute directly, as we cannot use get_max_degree(), as self is already mutably borrowed.
            let max_degree = if (node.is_leaf) {
                self.leaf_max_degree
            } else {
                self.inner_max_degree
            };

            if (degree < max_degree) {
                // Adding a child to a current node doesn't exceed the size, so we can just do that.
                let old_child = ordered_map::upsert(children, key, child);

                if (node.is_leaf) {
                    assert!(allow_overwrite || option::is_none(&old_child), error::invalid_argument(EKEY_ALREADY_EXISTS));
                    return old_child
                } else {
                    assert!(!allow_overwrite && option::is_none(&old_child), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
                    return old_child
                }
            };

            // If we cannot add more nodes without exceeding the size,
            // but node with `key` already exists, we either need to replace or abort.
            let iter = ordered_map::internal_find(children, &key);
            if (!ordered_map::iter_is_end(&iter, children)) {
                assert!(node.is_leaf, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
                assert!(allow_overwrite, error::invalid_argument(EKEY_ALREADY_EXISTS));

                return option::some(ordered_map::iter_replace(iter, children, child))
            }
        };

        // # of children in the current node exceeds the threshold, need to split into two nodes.

        // If we are at the root, we need to move root node to become a child and have a new root node,
        // in order to be able to split the node on the level it is.
        let (reserved_slot, node) = if (node_index == ROOT_INDEX) {
            assert!(vector::is_empty(&path_to_node), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

            // Splitting root now, need to create a new root.
            // Since root is stored direclty in the resource, we will swap-in the new node there.
            let new_root_node = new_node<K, V>(/*is_leaf=*/false);

            // Reserve a slot where the current root will be moved to.
            let (replacement_node_slot, replacement_node_reserved_slot) = storage_slots_allocator::reserve_slot(&mut self.nodes);

            let max_key = {
                let root_children = &self.root.children;
                let end_iter = ordered_map::internal_new_end_iter(root_children);
                let prev_iter = ordered_map::iter_prev(end_iter, root_children);
                let last_key = *ordered_map::iter_borrow_key(&prev_iter, root_children);
                if (cmp::is_lt(&cmp::compare(&last_key, &key))) {
                    key
                } else {
                    last_key
                }
            };
            // New root will have start with a single child - the existing root (which will be at replacement location).
            ordered_map::add(&mut new_root_node.children, max_key, new_inner_child(replacement_node_slot));
            let node = replace_root(self, new_root_node);

            // we moved the currently processing node one level down, so we need to update the path
            vector::push_back(&mut path_to_node, ROOT_INDEX);

            let replacement_index = storage_slots_allocator::reserved_to_index(&replacement_node_reserved_slot);
            if (node.is_leaf) {
                // replacement node is the only leaf, so we update the pointers:
                self.min_leaf_index = replacement_index;
                self.max_leaf_index = replacement_index;
            };
            (replacement_node_reserved_slot, node)
        } else {
            // In order to work on multiple nodes at the same time, we cannot borrow_mut, and need to be
            // remove_and_reserve existing node.
            let (cur_node_reserved_slot, node) = storage_slots_allocator::remove_and_reserve(&mut self.nodes, node_index);
            (cur_node_reserved_slot, node)
        };

        // move node_index out of scope, to make sure we don't accidentally access it, as we are done with it.
        // (i.e. we should be using `reserved_slot` instead).
        move node_index;

        // Now we can perform the split at the current level, as we know we are not at the root level.
        assert!(!vector::is_empty(&path_to_node), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

        // Parent has a reference under max key to the current node, so existing index
        // needs to be the right node.
        // Since ordered_map::trim moves from the end (i.e. smaller keys stay),
        // we are going to put the contents of the current node on the left side,
        // and create a new right node.
        // So if we had before (node_index, node), we will change that to end up having:
        // (new_left_node_index, node trimmed off) and (node_index, new node with trimmed off children)
        //
        // So let's rename variables cleanly:
        let right_node_reserved_slot = reserved_slot;
        let left_node = node;

        let is_leaf = left_node.is_leaf;
        let left_children = &mut left_node.children;

        let right_node_index = storage_slots_allocator::reserved_to_index(&right_node_reserved_slot);
        let left_next = &mut left_node.next;
        let left_prev = &mut left_node.prev;

        // Compute directly, as we cannot use get_max_degree(), as self is already mutably borrowed.
        let max_degree = if (is_leaf) {
            self.leaf_max_degree
        } else {
            self.inner_max_degree
        };
        // compute the target size for the left node:
        let target_size = (max_degree + 1) / 2;

        // Add child (which will exceed the size), and then trim off to create two sets of children of correct sizes.
        ordered_map::add(left_children, key, child);
        let right_node_children = ordered_map::trim(left_children, target_size);

        assert!(ordered_map::length(left_children) <= max_degree, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        assert!(ordered_map::length(&right_node_children) <= max_degree, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

        let right_node = new_node_with_children(is_leaf, right_node_children);

        let (left_node_slot, left_node_reserved_slot) = storage_slots_allocator::reserve_slot(&mut self.nodes);
        let left_node_index = storage_slots_allocator::stored_to_index(&left_node_slot);

        // right nodes next is the node that was next of the left (previous) node, and next of left node is the right node.
        right_node.next = *left_next;
        *left_next = right_node_index;

        // right node's prev becomes current left node
        right_node.prev = left_node_index;
        // Since the previously used index is going to the right node, `prev` pointer of the next node is correct,
        // and we need to update next pointer of the previous node (if exists)
        if (*left_prev != NULL_INDEX) {
            storage_slots_allocator::borrow_mut(&mut self.nodes, *left_prev).next = left_node_index;
            assert!(right_node_index != self.min_leaf_index, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        } else if (right_node_index == self.min_leaf_index) {
            // Otherwise, if we were the smallest node on the level. if this is the leaf level, update the pointer.
            assert!(is_leaf, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
            self.min_leaf_index = left_node_index;
        };

        // Largest left key is the split key.
        let max_left_key = {
            let end_iter = ordered_map::internal_new_end_iter(left_children);
            let prev_iter = ordered_map::iter_prev(end_iter, left_children);
            *ordered_map::iter_borrow_key(&prev_iter, left_children)
        };

        storage_slots_allocator::fill_reserved_slot(&mut self.nodes, left_node_reserved_slot, left_node);
        storage_slots_allocator::fill_reserved_slot(&mut self.nodes, right_node_reserved_slot, right_node);

        // Add new Child (i.e. pointer to the left node) in the parent.
        option::destroy_none(add_at(self, path_to_node, max_left_key, new_inner_child(left_node_slot), false));
        option::none()
    }

    /// Given a path to node (excluding the node itself), which is currently stored under "old_key", update "old_key" to "new_key".
    fun update_key<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, path_to_node: vector<u64>, old_key: &K, new_key: K) {
        while (!vector::is_empty(&path_to_node)) {
            let node_index = vector::pop_back(&mut path_to_node);
            let node = borrow_node_mut(self, node_index);
            let children = &mut node.children;
            ordered_map::replace_key_inplace(children, old_key, new_key);

            // If we were not updating the largest child, we don't need to continue.
            let end_iter = ordered_map::internal_new_end_iter(children);
            let prev_iter = ordered_map::iter_prev(end_iter, children);
            if (ordered_map::iter_borrow_key(&prev_iter, children) != &new_key) {
                return
            };
        }
    }

    fun remove_at<K: drop + copy + store, V: store>(self: &mut BigOrderedMap<K, V>, path_to_node: vector<u64>, key: &K): Child<V> {
        // Last node in the path is one where we need to remove the child from.
        let node_index = vector::pop_back(&mut path_to_node);
        let old_child = {
            // First check if we can perform this operation, without changing structure of the tree (i.e. without rebalancing any nodes).

            // For that we can just borrow the single node
            let node = borrow_node_mut(self, node_index);

            let children = &mut node.children;
            let is_leaf = node.is_leaf;

            let old_child = ordered_map::remove(children, key);
            if (node_index == ROOT_INDEX) {
                // If current node is root, lower limit of max_degree/2 nodes doesn't apply.
                // So we can adjust internally

                assert!(vector::is_empty(&path_to_node), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

                if (!is_leaf && ordered_map::length(children) == 1) {
                    // If root is not leaf, but has a single child, promote only child to root,
                    // and drop current root. Since root is stored directly in the resource, we
                    // "move" the child into the root.

                    let inner_child_slot = {
                        let end_iter = ordered_map::internal_new_end_iter(children);
                        let prev_iter = ordered_map::iter_prev(end_iter, children);
                        destroy_inner_child(ordered_map::iter_remove(prev_iter, children))
                    };

                    let inner_child = storage_slots_allocator::remove(&mut self.nodes, inner_child_slot);
                    if (inner_child.is_leaf) {
                        self.min_leaf_index = ROOT_INDEX;
                        self.max_leaf_index = ROOT_INDEX;
                    };

                    destroy_empty_node(replace_root(self, inner_child));
                };
                return old_child
            };

            // Compute directly, as we cannot use get_max_degree(), as self is already mutably borrowed.
            let max_degree = if (is_leaf) {
                self.leaf_max_degree
            } else {
                self.inner_max_degree
            };
            let degree = ordered_map::length(children);

            // See if the node is big enough, or we need to merge it with another node on this level.
            let big_enough = degree * 2 >= max_degree;

            let new_max_key = {
                let end_iter = ordered_map::internal_new_end_iter(children);
                let prev_iter = ordered_map::iter_prev(end_iter, children);
                *ordered_map::iter_borrow_key(&prev_iter, children)
            };

            // See if max key was updated for the current node, and if so - update it on the path.
            let max_key_updated = cmp::is_lt(&cmp::compare(&new_max_key, key));
            if (max_key_updated) {
                assert!(degree >= 1, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

                update_key(self, path_to_node, key, new_max_key);
            };

            // If node is big enough after removal, we are done.
            if (big_enough) {
                return old_child
            };

            old_child
        };

        // Children size is below threshold, we need to rebalance with a neighbor on the same level.

        // In order to work on multiple nodes at the same time, we cannot borrow_mut, and need to be
        // remove_and_reserve existing node.
        let (node_slot, node) = storage_slots_allocator::remove_and_reserve(&mut self.nodes, node_index);

        let is_leaf = node.is_leaf;
        let max_degree = get_max_degree(self, is_leaf);
        let prev = node.prev;
        let next = node.next;

        // index of the node we will rebalance with.
        let sibling_index = {
            let parent_children = &borrow_node(self, *vector::borrow(&path_to_node, vector::length(&path_to_node) - 1)).children;
            assert!(ordered_map::length(parent_children) >= 2, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
            // If we are the largest node from the parent, we merge with the `prev`
            // (which is then guaranteed to have the same parent, as any node has >1 children),
            // otherwise we merge with `next`.
            let prev_child = ordered_map::iter_borrow(
                ordered_map::iter_prev(ordered_map::internal_new_end_iter(parent_children), parent_children),
                parent_children,
            );
            let inner_data = option::borrow(&prev_child.Inner);
            let prev_index = storage_slots_allocator::stored_to_index(&inner_data.node_index);
            if (prev_index == node_index) {
                prev
            } else {
                next
            }
        };

        let children = &mut node.children;

        let (sibling_slot, sibling_node) = storage_slots_allocator::remove_and_reserve(&mut self.nodes, sibling_index);
        assert!(is_leaf == sibling_node.is_leaf, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        let sibling_children = &mut sibling_node.children;

        if ((ordered_map::length(sibling_children) - 1) * 2 >= max_degree) {
            // The sibling node has enough elements, we can just borrow an element from the sibling node.
            if (sibling_index == next) {
                // if sibling is the node with larger keys, we remove a child from the start
                let old_max_key = {
                    let end_iter = ordered_map::internal_new_end_iter(children);
                    let prev_iter = ordered_map::iter_prev(end_iter, children);
                    *ordered_map::iter_borrow_key(&prev_iter, children)
                };
                let sibling_begin_iter = ordered_map::internal_new_begin_iter(sibling_children);
                let borrowed_max_key = *ordered_map::iter_borrow_key(&sibling_begin_iter, sibling_children);
                let borrowed_element = ordered_map::iter_remove(sibling_begin_iter, sibling_children);

                let end_iter = ordered_map::internal_new_end_iter(children);
                ordered_map::iter_add(end_iter, children, borrowed_max_key, borrowed_element);

                // max_key of the current node changed, so update
                update_key(self, path_to_node, &old_max_key, borrowed_max_key);
            } else {
                // if sibling is the node with smaller keys, we remove a child from the end
                let sibling_end_iter = ordered_map::iter_prev(
                    ordered_map::internal_new_end_iter(sibling_children),
                    sibling_children,
                );
                let borrowed_max_key = *ordered_map::iter_borrow_key(&sibling_end_iter, sibling_children);
                let borrowed_element = ordered_map::iter_remove(sibling_end_iter, sibling_children);

                ordered_map::add(children, borrowed_max_key, borrowed_element);

                // max_key of the sibling node changed, so update
                let sibling_new_max_key = {
                    let end_iter = ordered_map::internal_new_end_iter(sibling_children);
                    let prev_iter = ordered_map::iter_prev(end_iter, sibling_children);
                    *ordered_map::iter_borrow_key(&prev_iter, sibling_children)
                };
                update_key(self, path_to_node, &borrowed_max_key, sibling_new_max_key);
            };

            storage_slots_allocator::fill_reserved_slot(&mut self.nodes, node_slot, node);
            storage_slots_allocator::fill_reserved_slot(&mut self.nodes, sibling_slot, sibling_node);
            return old_child
        };

        // The sibling node doesn't have enough elements to borrow, merge with the sibling node.
        // Keep the slot of the node with larger keys of the two, to not require updating key on the parent nodes.
        // But append to the node with smaller keys, as ordered_map::append is more efficient when adding to the end.
        let (key_to_remove, reserved_slot_to_remove) = if (sibling_index == next) {
            // destroying larger sibling node, keeping sibling_slot.
            let Node { is_leaf: _, children: sibling_children, prev: _, next: sibling_next } = sibling_node;
            let key_to_remove = {
                let end_iter = ordered_map::internal_new_end_iter(children);
                let prev_iter = ordered_map::iter_prev(end_iter, children);
                *ordered_map::iter_borrow_key(&prev_iter, children)
            };
            ordered_map::append_disjoint(children, sibling_children);
            node.next = sibling_next;

            if (node.next != NULL_INDEX) {
                assert!(storage_slots_allocator::borrow_mut(&mut self.nodes, node.next).prev == sibling_index, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
            };

            // we are removing node_index, which previous's node's next was pointing to,
            // so update the pointer
            if (node.prev != NULL_INDEX) {
                storage_slots_allocator::borrow_mut(&mut self.nodes, node.prev).next = sibling_index;
            };
            // Otherwise, we were the smallest node on the level. if this is the leaf level, update the pointer.
            if (self.min_leaf_index == node_index) {
                assert!(is_leaf, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
                self.min_leaf_index = sibling_index;
            };

            storage_slots_allocator::fill_reserved_slot(&mut self.nodes, sibling_slot, node);

            (key_to_remove, node_slot)
        } else {
            // destroying larger current node, keeping node_slot
            let Node { is_leaf: _, children: node_children, prev: _, next: node_next } = node;
            let key_to_remove = {
                let end_iter = ordered_map::internal_new_end_iter(sibling_children);
                let prev_iter = ordered_map::iter_prev(end_iter, sibling_children);
                *ordered_map::iter_borrow_key(&prev_iter, sibling_children)
            };
            ordered_map::append_disjoint(sibling_children, node_children);
            sibling_node.next = node_next;

            if (sibling_node.next != NULL_INDEX) {
                assert!(storage_slots_allocator::borrow_mut(&mut self.nodes, sibling_node.next).prev == node_index, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
            };
            // we are removing sibling node_index, which previous's node's next was pointing to,
            // so update the pointer
            if (sibling_node.prev != NULL_INDEX) {
                storage_slots_allocator::borrow_mut(&mut self.nodes, sibling_node.prev).next = node_index;
            };
            // Otherwise, sibling was the smallest node on the level. if this is the leaf level, update the pointer.
            if (self.min_leaf_index == sibling_index) {
                assert!(is_leaf, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
                self.min_leaf_index = node_index;
            };

            storage_slots_allocator::fill_reserved_slot(&mut self.nodes, node_slot, sibling_node);

            (key_to_remove, sibling_slot)
        };

        assert!(!vector::is_empty(&path_to_node), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        let slot_to_remove = destroy_inner_child(remove_at(self, path_to_node, &key_to_remove));
        storage_slots_allocator::free_reserved_slot(&mut self.nodes, reserved_slot_to_remove, slot_to_remove);

        old_child
    }

    // ===== spec ===========

    spec module {
        pragma verify = false;
    }

    spec native fun spec_len<K, V>(map: BigOrderedMap<K, V>): num;
    spec native fun spec_contains_key<K, V>(map: BigOrderedMap<K, V>, key: K): bool;
    spec native fun spec_get<K, V>(map: BigOrderedMap<K, V>, key: K): V;

    // recursive functions need to be marked opaque

    spec add_at {
        pragma opaque;
    }

    spec remove_at {
        pragma opaque;
    }

    // ============================= Tests ====================================

    #[test_only]
    fun print_map<K: store, V: store>(_self: &BigOrderedMap<K, V>) {
        // uncomment to debug:
        // endless_std::debug::print(&std::string::utf8(b"print map"));
        // endless_std::debug::print(_self);
        // print_map_for_node(_self, ROOT_INDEX, 0);
    }

    #[test_only]
    fun print_map_for_node<K: store + copy + drop, V: store>(self: &BigOrderedMap<K, V>, node_index: u64, level: u64) {
        let node = borrow_node(self, node_index);

        endless_std::debug::print(&level);
        endless_std::debug::print(&node_index);
        endless_std::debug::print(node);

        if (!node.is_leaf) {
            let it = ordered_map::internal_new_begin_iter(&node.children);
            loop {
                if (ordered_map::iter_is_end(&it, &node.children)) {
                    break
                };
                let child: &Child<V> = ordered_map::iter_borrow(it, &node.children);
                let inner: &ChildInnerData = option::borrow(&child.Inner);
                print_map_for_node(self, storage_slots_allocator::stored_to_index(&inner.node_index), level + 1);
                it = ordered_map::iter_next(it, &node.children);
            };
        };
    }

    #[test_only]
    fun destroy_and_validate<K: drop + copy + store, V: drop + store>(self: BigOrderedMap<K, V>) {
        let map = self;
        while (!is_empty(&map)) {
            let iter = internal_new_begin_iter(&map);
            let key_ref = iter_borrow_key(&iter);
            remove(&mut map, key_ref);
            validate_map(&map);
        };
        destroy_empty(map);
    }

    #[test_only]
    fun validate_iteration<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>) {
        let expected_num_elements = compute_length(self);
        assert!((expected_num_elements == 0) == is_empty(self), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        let mut_num_elements = 0;
        let it = internal_new_begin_iter(self);
        while (!iter_is_end(&it, self)) {
            mut_num_elements = mut_num_elements + 1;
            it = iter_next(it, self);
        };

        assert!(mut_num_elements == expected_num_elements, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

        let mut_num_elements = 0;
        let it = internal_new_end_iter(self);
        while (!iter_is_begin(&it, self)) {
            it = iter_prev(it, self);
            mut_num_elements = mut_num_elements + 1;
        };
        assert!(mut_num_elements == expected_num_elements, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

        let it = internal_new_end_iter(self);
        if (!iter_is_begin(&it, self)) {
            it = iter_prev(it, self);
            assert!(option::borrow(&it.Some).node_index == self.max_leaf_index, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        } else {
            assert!(expected_num_elements == 0, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        };
    }

    #[test_only]
    fun validate_subtree<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>, node_index: u64, expected_lower_bound_key: Option<K>, expected_max_key: Option<K>) {
        let node = borrow_node(self, node_index);
        let len = ordered_map::length(&node.children);
        assert!(len <= get_max_degree(self, node.is_leaf), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));

        if (node_index != ROOT_INDEX) {
            assert!(len >= 1, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
            assert!(len * 2 >= get_max_degree(self, node.is_leaf) || node_index == ROOT_INDEX, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        };

        ordered_map::validate_ordered(&node.children);

        let previous_max_key = expected_lower_bound_key;
        let it = ordered_map::internal_new_begin_iter(&node.children);
        loop {
            if (ordered_map::iter_is_end(&it, &node.children)) {
                break
            };
            let key: &K = ordered_map::iter_borrow_key(&it, &node.children);
            let child: &Child<V> = ordered_map::iter_borrow(it, &node.children);
            if (!node.is_leaf) {
                let inner: &ChildInnerData = option::borrow(&child.Inner);
                validate_subtree(self, storage_slots_allocator::stored_to_index(&inner.node_index), previous_max_key, option::some(*key));
            } else {
                assert!(option::is_some<ChildLeafData<V>>(&child.Leaf), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
            };
            previous_max_key = option::some(*key);
            it = ordered_map::iter_next(it, &node.children);
        };

        if (option::is_some(&expected_max_key)) {
            let expected_max_key = option::destroy_some(expected_max_key);
            let end_iter = ordered_map::internal_new_end_iter(&node.children);
            let prev_iter = ordered_map::iter_prev(end_iter, &node.children);
            let max_key_ref = ordered_map::iter_borrow_key(&prev_iter, &node.children);
            assert!(&expected_max_key == max_key_ref, error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        } else {
            option::destroy_none(expected_max_key);
        };

        if (option::is_some(&expected_lower_bound_key)) {
            let expected_lower_bound_key = option::destroy_some(expected_lower_bound_key);
            let begin_iter = ordered_map::internal_new_begin_iter(&node.children);
            let min_key_ref = ordered_map::iter_borrow_key(&begin_iter, &node.children);
            assert!(cmp::is_lt(&cmp::compare(&expected_lower_bound_key, min_key_ref)), error::invalid_state(EINTERNAL_INVARIANT_BROKEN));
        } else {
            option::destroy_none(expected_lower_bound_key);
        };
    }

    #[test_only]
    fun validate_map<K: drop + copy + store, V: store>(self: &BigOrderedMap<K, V>) {
        validate_subtree(self, ROOT_INDEX, option::none(), option::none());
        validate_iteration(self);
    }

    #[test]
    fun test_small_example() {
        let map = new_with_config(5, 3, true);
        allocate_spare_slots(&mut map, 2);
        print_map(&map); validate_map(&map);
        add(&mut map, 1, 1); print_map(&map); validate_map(&map);
        add(&mut map, 2, 2); print_map(&map); validate_map(&map);
        let r1 = upsert(&mut map, 3, 3); print_map(&map); validate_map(&map);
        assert!(r1 == option::none(), 1);
        add(&mut map, 4, 4); print_map(&map); validate_map(&map);
        let r2 = upsert(&mut map, 4, 8); print_map(&map); validate_map(&map);
        assert!(r2 == option::some(4), 2);
        add(&mut map, 5, 5); print_map(&map); validate_map(&map);
        add(&mut map, 6, 6); print_map(&map); validate_map(&map);

        let expected_keys = vector[1, 2, 3, 4, 5, 6];
        let expected_values = vector[1, 2, 3, 8, 5, 6];

        let index = 0;
        for_each_ref(&map, |k, v| {
            assert!(k == vector::borrow(&expected_keys, index), *k + 100);
            assert!(v == vector::borrow(&expected_values, index), *k + 200);
            index = index + 1;
        });

        let index = 0;
        for_each_ref(&map, |k, v| {
            assert!(k == vector::borrow(&expected_keys, index), *k + 100);
            assert!(v == vector::borrow(&expected_values, index), *k + 200);
            index = index + 1;
        });

        vector::zip(expected_keys, expected_values, |key, value| {
            assert!(borrow(&map, &key) == &value, key + 300);
            assert!(borrow_mut(&mut map, &key) == &value, key + 400);
        });

        remove(&mut map, &5); print_map(&map); validate_map(&map);
        remove(&mut map, &4); print_map(&map); validate_map(&map);
        remove(&mut map, &1); print_map(&map); validate_map(&map);
        remove(&mut map, &3); print_map(&map); validate_map(&map);
        remove(&mut map, &2); print_map(&map); validate_map(&map);
        remove(&mut map, &6); print_map(&map); validate_map(&map);

        destroy_empty(map);
    }

    #[test]
    fun test_for_each() {
        let map = new_with_config<u64, u64>(4, 3, false);
        add_all(&mut map, vector[1, 3, 6, 2, 9, 5, 7, 4, 8], vector[1, 3, 6, 2, 9, 5, 7, 4, 8]);

        let expected = vector[1, 2, 3, 4, 5, 6, 7, 8, 9];
        let index = 0;
        for_each(map, |k, v| {
            assert!(k == *vector::borrow(&expected, index), k + 100);
            assert!(v == *vector::borrow(&expected, index), k + 200);
            index = index + 1;
        });
    }

    #[test]
    fun test_for_each_ref() {
        let map = new_with_config<u64, u64>(4, 3, false);
        add_all(&mut map, vector[1, 3, 6, 2, 9, 5, 7, 4, 8], vector[1, 3, 6, 2, 9, 5, 7, 4, 8]);

        let expected = vector[1, 2, 3, 4, 5, 6, 7, 8, 9];
        let index = 0;
        for_each_ref(&map, |k, v| {
            assert!(*k == *vector::borrow(&expected, index), *k + 100);
            assert!(*v == *vector::borrow(&expected, index), *k + 200);
            index = index + 1;
        });

        destroy(map, |_v| {});
    }

    #[test]
    fun test_for_each_variants() {
        let keys = vector[1, 3, 5];
        let values = vector[10, 30, 50];
        let map = new_from(keys, values);

        let index = 0;
        for_each_ref(&map, |k, v| {
            assert!(*vector::borrow(&keys, index) == *k, 0);
            assert!(*vector::borrow(&values, index) == *v, 0);
            index = index + 1;
        });

        let index = 0;
        for_each_mut(&mut map, |k, v| {
            assert!(*vector::borrow(&keys, index) == *k, 0);
            let expected_value = *vector::borrow(&values, index);
            let new_value = expected_value + 1;
            *v = new_value;
            index = index + 1;
        });

        let index = 0;
        for_each(map, |k, v| {
            assert!(*vector::borrow(&keys, index) == k, 0);
            assert!(*vector::borrow(&values, index) + 1 == v, 0);
            index = index + 1;
        });
    }

    #[test]
    fun test_zip_for_each_ref() {
        let map1 = new_with_config<u64, u64>(4, 3, false);
        add_all(&mut map1, vector[1, 2, 4, 8, 9], vector[1, 2, 4, 8, 9]);

        let map2 = new_with_config<u64, u64>(4, 3, false);
        add_all(&mut map2, vector[2, 3, 4, 6, 8, 10, 12, 14], vector[2, 3, 4, 6, 8, 10, 12, 14]);

        let result = new();
        intersection_zip_for_each_ref(&map1, &map2, |k, v1, v2| {
            assert!(v1 == v2, 0);
            upsert(&mut result, *k, *v1);
        });

        let result_ordered = to_ordered_map(&result);
        let expected_ordered = ordered_map::new_from(vector[2, 4, 8], vector[2, 4, 8]);
        ordered_map::print_map(&result_ordered);
        ordered_map::print_map(&expected_ordered);
        assert!(expected_ordered == result_ordered, 0);

        let map_empty = new_with_config<u64, u64>(4, 3, false);
        intersection_zip_for_each_ref(&map1, &map_empty, |_k, _v1, _v2| {
            abort 1;
        });

        intersection_zip_for_each_ref(&map_empty, &map2, |_k, _v1, _v2| {
            abort 1;
        });

        destroy(map1, |_v| {});
        destroy(map2, |_v| {});
        destroy(result, |_v| {});
        destroy_empty(map_empty);
    }

    #[test]
    fun test_variable_size() {
        let map = new_with_config<vector<u64>, vector<u64>>(0, 0, false);
        print_map(&map); validate_map(&map);
        add(&mut map, vector[1], vector[1]); print_map(&map); validate_map(&map);
        add(&mut map, vector[2], vector[2]); print_map(&map); validate_map(&map);
        let r1 = upsert(&mut map, vector[3], vector[3]); print_map(&map); validate_map(&map);
        assert!(r1 == option::none(), 1);
        add(&mut map, vector[4], vector[4]); print_map(&map); validate_map(&map);
        let r2 = upsert(&mut map, vector[4], vector[8, 8, 8]); print_map(&map); validate_map(&map);
        assert!(r2 == option::some(vector[4]), 2);
        add(&mut map, vector[5], vector[5]); print_map(&map); validate_map(&map);
        add(&mut map, vector[6], vector[6]); print_map(&map); validate_map(&map);

        vector::zip(vector[1, 2, 3, 4, 5, 6], vector[1, 2, 3, 8, 5, 6], |key, value| {
            assert!(*vector::borrow(borrow(&map, &vector[key]), 0) == value, key + 100);
        });

        remove(&mut map, &vector[5]); print_map(&map); validate_map(&map);
        remove(&mut map, &vector[4]); print_map(&map); validate_map(&map);
        remove(&mut map, &vector[1]); print_map(&map); validate_map(&map);
        remove(&mut map, &vector[3]); print_map(&map); validate_map(&map);
        remove(&mut map, &vector[2]); print_map(&map); validate_map(&map);
        remove(&mut map, &vector[6]); print_map(&map); validate_map(&map);

        destroy_empty(map);
    }
    #[test]
    fun test_deleting_and_creating_nodes() {
        let map = new_with_config(4, 3, true);
        allocate_spare_slots(&mut map, 2);

        for (i in 0..25) {
            upsert(&mut map, i, i);
            validate_map(&map);
        };

        for (i in 0..20) {
            remove(&mut map, &i);
            validate_map(&map);
        };

        for (i in 25..50) {
            upsert(&mut map, i, i);
            validate_map(&map);
        };

        for (i in 25..45) {
            remove(&mut map, &i);
            validate_map(&map);
        };

        for (i in 50..75) {
            upsert(&mut map, i, i);
            validate_map(&map);
        };

        for (i in 50..75) {
            remove(&mut map, &i);
            validate_map(&map);
        };

        for (i in 20..25) {
            remove(&mut map, &i);
            validate_map(&map);
        };

        for (i in 45..50) {
            remove(&mut map, &i);
            validate_map(&map);
        };

        destroy_empty(map);
    }

    #[test]
    fun test_iterator() {
        let map = new_with_config(5, 5, true);
        allocate_spare_slots(&mut map, 2);

        let data = vector[1, 7, 5, 8, 4, 2, 6, 3, 9, 0];
        while (vector::length(&data) != 0) {
            let element = vector::pop_back(&mut data);
            add(&mut map, element, element);
        };

        let it = internal_new_begin_iter(&map);

        let i = 0;
        while (!iter_is_end(&it, &map)) {
            assert!(i == *iter_borrow_key(&it), i);
            assert!(iter_borrow(it, &map) == &i, i);
            assert!(iter_borrow_mut(it, &mut map) == &i, i);
            i = i + 1;
            it = iter_next(it, &map);
        };

        destroy(map, |_v| {});
    }

    #[test]
    fun test_find() {
        let map = new_with_config(5, 5, true);
        allocate_spare_slots(&mut map, 2);

        let data = vector[11, 1, 7, 5, 8, 2, 6, 3, 0, 10];
        add_all(&mut map, data, data);

        let i = 0;
        while (i < vector::length(&data)) {
            let element = vector::borrow(&data, i);
            let it = internal_find(&map, element);
            assert!(!iter_is_end(&it, &map), i);
            assert!(iter_borrow_key(&it) == element, i);
            i = i + 1;
        };

        let iter_4 = internal_find(&map, &4);
        assert!(iter_is_end(&iter_4, &map), 0);
        let iter_9 = internal_find(&map, &9);
        assert!(iter_is_end(&iter_9, &map), 1);

        destroy(map, |_v| {});
    }

    #[test]
    fun test_lower_bound() {
        let map = new_with_config(5, 5, true);
        allocate_spare_slots(&mut map, 2);

        let data = vector[11, 1, 7, 5, 8, 2, 6, 3, 12, 10];
        add_all(&mut map, data, data);

        let i = 0;
        while (i < vector::length(&data)) {
            let element = *vector::borrow(&data, i);
            let it = internal_lower_bound(&map, &element);
            assert!(!iter_is_end(&it, &map), i);
            assert!(*iter_borrow_key(&it) == element, i);
            i = i + 1;
        };

        let lb0 = internal_lower_bound(&map, &0);
        assert!(*iter_borrow_key(&lb0) == 1, 0);
        let lb4 = internal_lower_bound(&map, &4);
        assert!(*iter_borrow_key(&lb4) == 5, 1);
        let lb9 = internal_lower_bound(&map, &9);
        assert!(*iter_borrow_key(&lb9) == 10, 2);
        let lb_13 = internal_lower_bound(&map, &13);
        assert!(iter_is_end(&lb_13, &map), 3);

        remove(&mut map, &3);
        let lb_after3 = internal_lower_bound(&map, &3);
        assert!(*iter_borrow_key(&lb_after3) == 5, 4);
        remove(&mut map, &5);
        let lb_after5 = internal_lower_bound(&map, &3);
        assert!(*iter_borrow_key(&lb_after5) == 6, 5);
        let lb_ordered = internal_lower_bound(&map, &4);
        assert!(*iter_borrow_key(&lb_ordered) == 6, 6);

        destroy(map, |_v| {});
    }

    #[test]
    fun test_modify_and_get() {
        let map = new_with_config(4, 3, false);
        add_all(&mut map, vector[1, 2, 3], vector[1, 2, 3]);
        // Test modify - use workaround for borrow checker limitation
        let old_value = option::destroy_some(get(&map, &2));
        *borrow_mut(&mut map, &2) = old_value + 10;
        assert!(get(&map, &2) == option::some(12), 0);
        assert!(get(&map, &4) == option::none(), 0);

        assert!(get_and_map(&map, &2, |v| *v + 5) == option::some(17), 0);
        assert!(get_and_map(&map, &4, |v| *v + 5) == option::none(), 0);

        // Test modify_or_add
        let old_value = option::destroy_some(get(&map, &3));
        *borrow_mut(&mut map, &3) = old_value + 10;
        assert!(get(&map, &3) == option::some(13), 0);
        upsert(&mut map, 4, 20);
        assert!(get(&map, &4) == option::some(20), 0);

        // Test modify_if_present_and_return - workaround for borrow checker
        let old_value = option::destroy_some(get(&map, &4));
        *borrow_mut(&mut map, &4) = old_value + 10;
        assert!(get(&map, &4) == option::some(30), 0);

        // Test with non-existent key - should not modify
        assert!(get(&map, &5) == option::none(), 0);

        destroy(map, |_v| {});
    }

    #[test]
    fun test_contains() {
        let map = new_with_config(4, 3, false);
        let data = vector[3, 1, 9, 7, 5];
        add_all(&mut map, vector[3, 1, 9, 7, 5], vector[3, 1, 9, 7, 5]);

        vector::for_each_ref(&data, |i| assert!(contains(&map, i), *i));

        let missing = vector[0, 2, 4, 6, 8, 10];
        vector::for_each_ref(&missing, |i| assert!(!contains(&map, i), *i));

        destroy(map, |_v| {});
    }

    #[test]
    fun test_non_iterator_ordering() {
        let map = new_from(vector[1, 2, 3], vector[10, 20, 30]);
        assert!(option::is_none(&prev_key(&map, &1)), 1);
        assert!(next_key(&map, &1) == option::some(2), 1);

        assert!(prev_key(&map, &2) == option::some(1), 2);
        assert!(next_key(&map, &2) == option::some(3), 3);

        assert!(prev_key(&map, &3) == option::some(2), 4);
        assert!(option::is_none(&next_key(&map, &3)), 5);

        let (front_k, front_v) = borrow_front(&map);
        assert!(front_k == 1, 6);
        assert!(front_v == &10, 7);

        let (back_k, back_v) = borrow_back(&map);
        assert!(back_k == 3, 8);
        assert!(back_v == &30, 9);

        let (front_k, front_v) = pop_front(&mut map);
        assert!(front_k == 1, 10);
        assert!(front_v == 10, 11);

        let (back_k, back_v) = pop_back(&mut map);
        assert!(back_k == 3, 12);
        assert!(back_v == 30, 13);

        destroy(map, |_v| {});
    }

    #[test]
    #[expected_failure(abort_code = 0x1000B, location = Self)] /// EINVALID_CONFIG_PARAMETER
    fun test_inner_max_degree_too_large() {
        let map = new_with_config<u8, u8>(4097, 0, false);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x1000B, location = Self)] /// EINVALID_CONFIG_PARAMETER
    fun test_inner_max_degree_too_small() {
        let map = new_with_config<u8, u8>(3, 0, false);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x1000B, location = Self)] /// EINVALID_CONFIG_PARAMETER
    fun test_leaf_max_degree_too_small() {
        let map = new_with_config<u8, u8>(0, 2, false);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10001, location = Self)] /// EKEY_ALREADY_EXISTS
    fun test_abort_add_existing_value() {
        let map = new_from(vector[1], vector[1]);
        add(&mut map, 1, 2);
        destroy_and_validate(map);
    }

    #[test_only]
    fun vector_range(from: u64, to: u64): vector<u64> {
        let result = vector[];
        for (i in from..to) {
            vector::push_back(&mut result, i);
        };
        result
    }

    #[test_only]
    fun vector_bytes_range(from: u64, to: u64): vector<u8> {
        let result = vector[];
        for (i in from..to) {
            vector::push_back(&mut result, ((i % 128) as u8));
        };
        result
    }

    #[test]
    #[expected_failure(abort_code = 0x10001, location = Self)] /// EKEY_ALREADY_EXISTS
    fun test_abort_add_existing_value_to_non_leaf() {
        let map = new_with_config(4, 4, false);
        add_all(&mut map, vector_range(1, 10), vector_range(1, 10));
        add(&mut map, 3, 3);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10002, location = endless_std::ordered_map)] /// EKEY_NOT_FOUND
    fun test_abort_remove_missing_value() {
        let map = new_from(vector[1], vector[1]);
        remove(&mut map, &2);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10002, location = endless_std::ordered_map)] /// EKEY_NOT_FOUND
    fun test_abort_remove_missing_value_to_non_leaf() {
        let map = new_with_config(4, 4, false);
        add_all(&mut map, vector_range(1, 10), vector_range(1, 10));
        remove(&mut map, &4);
        remove(&mut map, &4);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10002, location = Self)] /// EKEY_NOT_FOUND
    fun test_abort_remove_largest_missing_value_to_non_leaf() {
        let map = new_with_config(4, 4, false);
        add_all(&mut map, vector_range(1, 10), vector_range(1, 10));
        remove(&mut map, &11);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10002, location = Self)] /// EKEY_NOT_FOUND
    fun test_abort_borrow_missing() {
        let map = new_from(vector[1], vector[1]);
        borrow(&map, &2);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10002, location = Self)] /// EKEY_NOT_FOUND
    fun test_abort_borrow_mut_missing() {
        let map = new_from(vector[1], vector[1]);
        borrow_mut(&mut map, &2);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x1000E, location = Self)] /// EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE
    fun test_abort_borrow_mut_requires_constant_value_size() {
        let map = new_with_config(0, 0, false);
        add(&mut map, 1, vector[1]);
        borrow_mut(&mut map, &1);
        destroy_and_validate(map);
    }

    #[test]
    fun test_borrow_mut_allows_variable_key_size() {
        let map = new_with_config(0, 0, false);
        add(&mut map, vector[1], 1);
        borrow_mut(&mut map, &vector[1]);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
    fun test_abort_iter_borrow_key_missing() {
        let map = new_from(vector[1], vector[1]);
        let iter = internal_new_end_iter(&map);
        iter_borrow_key(&iter);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
    fun test_abort_iter_borrow_missing() {
        let map = new_from(vector[1], vector[1]);
        iter_borrow(internal_new_end_iter(&map), &map);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
    fun test_abort_iter_borrow_mut_missing() {
        let map = new_from(vector[1], vector[1]);
        iter_borrow_mut(internal_new_end_iter(&map), &mut map);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x1000E, location = Self)] /// EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE
    fun test_abort_iter_borrow_mut_requires_constant_kv_size() {
        let map = new_with_config(0, 0, false);
        add(&mut map, 1, vector[1]);
        iter_borrow_mut(internal_new_begin_iter(&map), &mut map);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
    fun test_abort_end_iter_next() {
        let map = new_from(vector[1, 2, 3], vector[1, 2, 3]);
        iter_next(internal_new_end_iter(&map), &map);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
    fun test_abort_begin_iter_prev() {
        let map = new_from(vector[1, 2, 3], vector[1, 2, 3]);
        iter_prev(internal_new_begin_iter(&map), &map);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x1000C, location = Self)] /// EMAP_NOT_EMPTY
    fun test_abort_fail_to_destroy_non_empty() {
        let map = new_from(vector[1], vector[1]);
        destroy_empty(map);
    }

    #[test]
    fun test_default_allows_5kb() {
        let map = new_with_config(0, 0, false);
        add(&mut map, vector[1u8], 1);
        // default guarantees key up to 5KB
        add(&mut map, vector_bytes_range(0, 5000), 1);
        destroy_and_validate(map);

        let map = new_with_config(0, 0, false);
        // default guarantees (key, value) pair up to 10KB
        add(&mut map, 1, vector[1u8]);
        add(&mut map, 2, vector_bytes_range(0, 10000));
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x1000F, location = Self)] /// EKEY_BYTES_TOO_LARGE
    fun test_adding_key_too_large() {
        let map = new_with_config(0, 0, false);
        add(&mut map, vector[1u8], 1);
        // default guarantees key up to 5KB
        add(&mut map, vector_bytes_range(0, 5200), 1);
        destroy_and_validate(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x1000D, location = Self)] /// EARGUMENT_BYTES_TOO_LARGE
    fun test_adding_value_too_large() {
        let map = new_with_config(0, 0, false);
        // default guarantees (key, value) pair up to 10KB
        add(&mut map, 1, vector[1u8]);
        add(&mut map, 2, vector_bytes_range(0, 12000));
        destroy_and_validate(map);
    }

    #[test_only]
    inline fun comparison_test(repeats: u64, inner_max_degree: u16, leaf_max_degree: u16, reuse_slots: bool, next_1: ||u64, next_2: ||u64) {
        let big_map = new_with_config((inner_max_degree as u64), (leaf_max_degree as u64), reuse_slots);
        if (reuse_slots) {
            allocate_spare_slots(&mut big_map, 4);
        };
        let small_map = ordered_map::new();
        for (i in 0..repeats) {
            let is_insert = if (2 * i < repeats) {
                i % 3 != 2
            } else {
                i % 3 == 0
            };
            if (is_insert) {
                let v = next_1();
                assert!(upsert(&mut big_map, v, v) == ordered_map::upsert(&mut small_map, v, v), i);
            } else {
                let v = next_2();
                assert!(remove(&mut big_map, &v) == ordered_map::remove(&mut small_map, &v), i);
            };
            if ((i + 1) % 50 == 0) {
                validate_map(&big_map);

                let big_iter = internal_new_begin_iter(&big_map);
                let small_iter = ordered_map::internal_new_begin_iter(&small_map);
                while (!iter_is_end(&big_iter, &big_map) || !ordered_map::iter_is_end(&small_iter, &small_map)) {
                    assert!(iter_borrow_key(&big_iter) == ordered_map::iter_borrow_key(&small_iter, &small_map), i);
                    assert!(iter_borrow(big_iter, &big_map) == ordered_map::iter_borrow(small_iter, &small_map), i);
                    big_iter = iter_next(big_iter, &big_map);
                    small_iter = ordered_map::iter_next(small_iter, &small_map);
                };
            };
        };
        destroy_and_validate(big_map);
    }

    #[test_only]
    const OFFSET: u64 = 270001;
    #[test_only]
    const MOD: u64 = 1000000;

    #[test]
    fun test_comparison_random() {
        let x = 1234;
        let y = 1234;
        comparison_test(500, 5, 5, false,
            || {
                x = x + OFFSET;
                if (x > MOD) { x = x - MOD};
                x
            },
            || {
                y = y + OFFSET;
                if (y > MOD) { y = y - MOD};
                y
            },
        );
    }

    #[test]
    fun test_comparison_increasing() {
        let x = 0;
        let y = 0;
        comparison_test(500, 5, 5, false,
            || {
                x = x + 1;
                x
            },
            || {
                y = y + 1;
                y
            },
        );
    }

    #[test]
    fun test_comparison_decreasing() {
        let x = 100000;
        let y = 100000;
        comparison_test(500, 5, 5, false,
            || {
                x = x - 1;
                x
            },
            || {
                y = y - 1;
                y
            },
        );
    }

    #[test_only]
    fun test_large_data_set_helper(inner_max_degree: u16, leaf_max_degree: u16, reuse_slots: bool) {
        use std::vector;

        let map = new_with_config((inner_max_degree as u64), (leaf_max_degree as u64), reuse_slots);
        if (reuse_slots) {
            allocate_spare_slots(&mut map, 4);
        };
        let data = ordered_map::large_dataset();
        let shuffled_data = ordered_map::large_dataset_shuffled();

        let len = vector::length(&data);
        for (i in 0..len) {
            let element = *vector::borrow(&data, i);
            upsert(&mut map, element, element);
            if (i % 7 == 0) {
                validate_map(&map);
            }
        };

        for (i in 0..len) {
            let element = vector::borrow(&shuffled_data, i);
            let it = internal_find(&map, element);
            assert!(!iter_is_end(&it, &map), i);
            assert!(iter_borrow_key(&it) == element, i);

            // endless_std::debug::print(&it);

            let it_next = iter_next(it, &map);
            let it_after = internal_lower_bound(&map, &(*element + 1));

            // endless_std::debug::print(&it_next);
            // endless_std::debug::print(&it_after);
            // endless_std::debug::print(&std::string::utf8(b"bla"));

            assert!(it_next == it_after, i);
        };

        let removed = vector::empty();
        for (i in 0..len) {
            let element = vector::borrow(&shuffled_data, i);
            if (!vector::contains(&removed, element)) {
                vector::push_back(&mut removed, *element);
                remove(&mut map, element);
                if (i % 7 == 1) {
                    validate_map(&map);

                }
            } else {
                assert!(!contains(&map, element), 0);
            };
        };

        destroy_empty(map);
    }

    // Currently ignored long / more extensive tests.

    // #[test]
    // fun test_large_data_set_order_5_false() {
    //     test_large_data_set_helper(5, 5, false);
    // }

    // #[test]
    // fun test_large_data_set_order_5_true() {
    //     test_large_data_set_helper(5, 5, true);
    // }

    // #[test]
    // fun test_large_data_set_order_4_3_false() {
    //     test_large_data_set_helper(4, 3, false);
    // }

    // #[test]
    // fun test_large_data_set_order_4_3_true() {
    //     test_large_data_set_helper(4, 3, true);
    // }

    // #[test]
    // fun test_large_data_set_order_4_4_false() {
    //     test_large_data_set_helper(4, 4, false);
    // }

    // #[test]
    // fun test_large_data_set_order_4_4_true() {
    //     test_large_data_set_helper(4, 4, true);
    // }

    // #[test]
    // fun test_large_data_set_order_6_false() {
    //     test_large_data_set_helper(6, 6, false);
    // }

    // #[test]
    // fun test_large_data_set_order_6_true() {
    //     test_large_data_set_helper(6, 6, true);
    // }

    // #[test]
    // fun test_large_data_set_order_6_3_false() {
    //     test_large_data_set_helper(6, 3, false);
    // }

    #[test]
    fun test_large_data_set_order_6_3_true() {
        test_large_data_set_helper(6, 3, true);
    }

    #[test]
    fun test_large_data_set_order_4_6_false() {
        test_large_data_set_helper(4, 6, false);
    }

    // #[test]
    // fun test_large_data_set_order_4_6_true() {
    //     test_large_data_set_helper(4, 6, true);
    // }

    // #[test]
    // fun test_large_data_set_order_16_false() {
    //     test_large_data_set_helper(16, 16, false);
    // }

    // #[test]
    // fun test_large_data_set_order_16_true() {
    //     test_large_data_set_helper(16, 16, true);
    // }

    // #[test]
    // fun test_large_data_set_order_31_false() {
    //     test_large_data_set_helper(31, 31, false);
    // }

    // #[test]
    // fun test_large_data_set_order_31_true() {
    //     test_large_data_set_helper(31, 31, true);
    // }

    // #[test]
    // fun test_large_data_set_order_31_3_false() {
    //     test_large_data_set_helper(31, 3, false);
    // }

    // #[test]
    // fun test_large_data_set_order_31_3_true() {
    //     test_large_data_set_helper(31, 3, true);
    // }

    // #[test]
    // fun test_large_data_set_order_31_5_false() {
    //     test_large_data_set_helper(31, 5, false);
    // }

    // #[test]
    // fun test_large_data_set_order_31_5_true() {
    //     test_large_data_set_helper(31, 5, true);
    // }

    // #[test]
    // fun test_large_data_set_order_32_false() {
    //     test_large_data_set_helper(32, 32, false);
    // }

    // #[test]
    // fun test_large_data_set_order_32_true() {
    //     test_large_data_set_helper(32, 32, true);
    // }

    #[verify_only]
    fun test_verify_borrow_front_key() {
        let keys: vector<u64> = vector[1, 2, 3];
        let values: vector<u64> = vector[4, 5, 6];
        let map = new_from(keys, values);
        let (_key, _value) = {
            let (key_val, value_ref) = borrow_front(&map);
            (key_val, *value_ref)
        };
        spec {
            assert keys[0] == 1;
            assert vector::spec_contains(keys, 1);
            assert spec_contains_key(map, _key);
            assert spec_get(map, _key) == _value;
            assert _key == 1;
        };
        destroy(map, |_v| {});
    }

    spec test_verify_borrow_front_key {
        pragma verify = true;
    }

    #[verify_only]
    fun test_verify_borrow_back_key() {
        let keys: vector<u64> = vector[1, 2, 3];
        let values: vector<u64> = vector[4, 5, 6];
        let map = new_from(keys, values);
        let (key, value) = {
            let (key_val, value_ref) = borrow_back(&map);
            (key_val, *value_ref)
        };
        spec {
            assert keys[2] == 3;
            assert vector::spec_contains(keys, 3);
            assert spec_contains_key(map, key);
            assert spec_get(map, key) == value;
            assert key == 3;
        };
        destroy(map, |_v| {});
    }

    spec test_verify_borrow_back_key {
        pragma verify = true;
    }

    #[verify_only]
    fun test_verify_upsert() {
        let keys: vector<u64> = vector[1, 2, 3];
        let values: vector<u64> = vector[4, 5, 6];
        let map = new_from(keys, values);
        let (_key, _value) = borrow_back(&map);
        let result_1 = upsert(&mut map, 4, 5);
        spec {
            assert spec_contains_key(map, 4);
            assert spec_get(map, 4) == 5;
            assert option::is_none(result_1);
        };
        let result_2 = upsert(&mut map, 4, 6);
        spec {
            assert spec_contains_key(map, 4);
            assert spec_get(map, 4) == 6;
            assert option::is_some(result_2);
            assert option::borrow(result_2) == 5;
            assert !spec_contains_key(map, 10);
        };
        spec {
            assert keys[0] == 1;
            assert spec_contains_key(map, 1);
            assert spec_get(map, 1) == 4;
        };
        let v = remove(&mut map, &1);
        spec {
            assert v == 4;
        };
        remove(&mut map, &2);
        remove(&mut map, &3);
        remove(&mut map, &4);
        spec {
            assert !spec_contains_key(map, 1);
            assert !spec_contains_key(map, 2);
            assert !spec_contains_key(map, 3);
            assert !spec_contains_key(map, 4);
            assert spec_len(map) == 0;
        };
        destroy_empty(map);
    }

    spec test_verify_upsert {
        pragma verify = true;
    }

    #[verify_only]
    fun test_verify_next_key() {
        let keys: vector<u64> = vector[1, 2, 3];
        let values: vector<u64> = vector[4, 5, 6];
        let map = new_from(keys, values);
        let result_1 = next_key(&map, &3);
        spec {
            assert option::is_none(result_1);
        };
        let result_2 = next_key(&map, &1);
        spec {
            assert keys[0] == 1;
            assert spec_contains_key(map, 1);
            assert keys[1] == 2;
            assert spec_contains_key(map, 2);
            assert option::is_some(result_2);
            assert option::borrow(result_2) == 2;
        };
        remove(&mut map, &1);
        remove(&mut map, &2);
        remove(&mut map, &3);
        destroy_empty(map);
    }

    spec test_verify_next_key {
        pragma verify = true;
    }

    #[verify_only]
    fun test_verify_prev_key() {
        let keys: vector<u64> = vector[1, 2, 3];
        let values: vector<u64> = vector[4, 5, 6];
        let map = new_from(keys, values);
        let result_1 = prev_key(&map, &1);
        spec {
            assert option::is_none(result_1);
        };
        let result_2 = prev_key(&map, &3);
        spec {
            assert keys[0] == 1;
            assert spec_contains_key(map, 1);
            assert keys[1] == 2;
            assert spec_contains_key(map, 2);
            assert option::is_some(result_2);
        };
        remove(&mut map, &1);
        remove(&mut map, &2);
        remove(&mut map, &3);
        destroy_empty(map);
    }

    spec test_verify_prev_key {
        pragma verify = true;
    }

    #[verify_only]
    fun test_verify_remove() {
        let keys: vector<u64> = vector[1, 2, 3];
        let values: vector<u64> = vector[4, 5, 6];
        let map = new_from(keys, values);
        spec {
            assert keys[1] == 2;
            assert vector::spec_contains(keys, 2);
            assert spec_contains_key(map, 2);
            assert spec_get(map, 2) == 5;
            assert spec_len(map) == 3;
        };
        let v = remove(&mut map, &1);
        spec {
            assert v == 4;
            assert spec_contains_key(map, 2);
            assert spec_get(map, 2) == 5;
            assert spec_len(map) == 2;
            assert !spec_contains_key(map, 1);
        };
        remove(&mut map, &2);
        remove(&mut map, &3);
        destroy_empty(map);
    }

    spec test_verify_remove {
        pragma verify = true;
    }

     #[verify_only]
     fun test_aborts_if_new_from_1(): BigOrderedMap<u64, u64> {
        let keys: vector<u64> = vector[1, 2, 3, 1];
        let values: vector<u64> = vector[4, 5, 6, 7];
        spec {
            assert keys[0] == 1;
            assert keys[3] == 1;
        };
        let map = new_from(keys, values);
        map
     }

     spec test_aborts_if_new_from_1 {
        pragma verify = true;
        aborts_if true;
     }

     #[verify_only]
     fun test_aborts_if_new_from_2(keys: vector<u64>, values: vector<u64>): BigOrderedMap<u64, u64> {
        let map = new_from(keys, values);
        map
     }

     spec test_aborts_if_new_from_2 {
        pragma verify = true;
        aborts_if exists i in 0..len(keys), j in 0..len(keys) where i != j : keys[i] == keys[j];
        aborts_if len(keys) != len(values);
     }

     #[verify_only]
     fun test_aborts_if_remove(map: &mut BigOrderedMap<u64, u64>) {
        remove(map, &1);
     }

     spec test_aborts_if_remove {
        pragma verify = true;
        aborts_if !spec_contains_key(map, 1);
     }

}

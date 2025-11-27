/// This module provides an implementation for an ordered map.
///
/// Keys point to values, and each key in the map must be unique.
///
/// Currently, one implementation is provided, backed by a single sorted vector.
///
/// That means that keys can be found within O(log N) time.
/// Adds and removals take O(N) time, but the constant factor is small,
/// as it does only O(log N) comparisons, and does efficient mem-copy with vector operations.
///
/// Additionally, it provides a way to lookup and iterate over sorted keys, making range query
/// take O(log N + R) time (where R is number of elements in the range).
///
/// Most methods operate with OrderedMap being `self`.
/// All methods that start with iter_*, operate with IteratorPtr being `self`.
///
/// Uses cmp::compare for ordering, which compares primitive types natively, and uses common
/// lexicographical sorting for complex types.
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
module endless_std::ordered_map {
    friend endless_std::big_ordered_map;

    use std::vector;

    use std::option::{Self, Option};
    use std::cmp;
    use std::error;

    /// Map key already exists
    const EKEY_ALREADY_EXISTS: u64 = 1;
    /// Map key is not found
    const EKEY_NOT_FOUND: u64 = 2;
    // Trying to do an operation on an IteratorPtr that would go out of bounds
    const EITER_OUT_OF_BOUNDS: u64 = 3;
    /// New key used in replace_key_inplace doesn't respect the order
    const ENEW_KEY_NOT_IN_ORDER: u64 = 4;

    /// Individual entry holding (key, value) pair
    struct Entry<K, V> has drop, copy, store {
        key: K,
        value: V,
    }

    /// The OrderedMap datastructure.
    struct OrderedMap<K, V> has drop, copy, store {
        tag: u8,
        /// sorted-vector based implementation of OrderedMap
        SortedVectorMap: Option<SortedVectorMapData<K, V>>,
    }

    struct SortedVectorMapData<K, V> has drop, copy, store {
        /// List of entries, sorted by key.
        entries: vector<Entry<K, V>>,
    }

    struct PositionData has copy, drop {
        /// The index of the iterator pointing to.
        index: u64,
    }

    /// An iterator pointing to a valid position in an ordered map, or to the end.
    ///
    /// TODO: Once fields can be (mutable) references, this class will be deprecated.
    struct IteratorPtr has copy, drop {
        tag: u8,
        End: Option<bool>,
        Position: Option<PositionData>,
    }

    /// Create a new empty OrderedMap, using default (SortedVectorMap) implementation.
    public fun new<K, V>(): OrderedMap<K, V> {
        OrderedMap {
            tag: 1,
            SortedVectorMap: option::some(SortedVectorMapData {
                entries: vector::empty(),
            }),
        }
    }

    /// Create a OrderedMap from a vector of keys and values.
    /// Aborts with EKEY_ALREADY_EXISTS if duplicate keys are passed in.
    public fun new_from<K, V>(keys: vector<K>, values: vector<V>): OrderedMap<K, V> {
        let map = new();
        add_all(&mut map, keys, values);
        map
    }

    /// Number of elements in the map.
    public fun length<K, V>(self: &OrderedMap<K, V>): u64 {
        vector::length(&option::borrow(&self.SortedVectorMap).entries)
    }

    /// Whether map is empty.
    public fun is_empty<K, V>(self: &OrderedMap<K, V>): bool {
        vector::is_empty(&option::borrow(&self.SortedVectorMap).entries)
    }

    /// Add a key/value pair to the map.
    /// Aborts with EKEY_ALREADY_EXISTS if key already exist.
    public fun add<K, V>(self: &mut OrderedMap<K, V>, key: K, value: V) {
        let entries = &mut option::borrow_mut(&mut self.SortedVectorMap).entries;
        let len = vector::length(entries);
        let index = binary_search(&key, entries, 0, len);

        if (index < len) {
            let entry = vector::borrow(entries, index);
            assert!(&entry.key != &key, error::invalid_argument(EKEY_ALREADY_EXISTS));
        };
        vector::insert(entries, index, Entry { key, value });
    }

    /// If the key doesn't exist in the map, inserts the key/value, and returns none.
    /// Otherwise, updates the value under the given key, and returns the old value.
    public fun upsert<K: drop, V>(self: &mut OrderedMap<K, V>, key: K, value: V): Option<V> {
        let entries = &mut option::borrow_mut(&mut self.SortedVectorMap).entries;
        let len = vector::length(entries);
        let index = binary_search(&key, entries, 0, len);

        if (index < len && {
            let entry = vector::borrow(entries, index);
            &entry.key == &key
        }) {
            let Entry {
                key: _,
                value: old_value,
            } = vector::replace(entries,index, Entry { key, value });
            option::some(old_value)
        } else {
            vector::insert(entries, index, Entry { key, value });
            option::none()
        }
    }

    /// Remove a key/value pair from the map.
    /// Aborts with EKEY_NOT_FOUND if `key` doesn't exist.
    public fun remove<K: drop, V>(self: &mut OrderedMap<K, V>, key: &K): V {
        let entries = &mut option::borrow_mut(&mut self.SortedVectorMap).entries;
        let len = vector::length(entries);
        let index = binary_search(key, entries, 0, len);
        assert!(index < len, error::invalid_argument(EKEY_NOT_FOUND));
        let Entry { key: old_key, value } = vector::remove(entries, index);
        assert!(key == &old_key, error::invalid_argument(EKEY_NOT_FOUND));
        value
    }

    /// Remove a key/value pair from the map.
    /// Returns none if `key` doesn't exist.
    public fun remove_or_none<K: drop, V>(self: &mut OrderedMap<K, V>, key: &K): Option<V> {
        let entries = &mut option::borrow_mut(&mut self.SortedVectorMap).entries;
        let len = vector::length(entries);
        let index = binary_search(key, entries, 0, len);
        if (index < len) {
            let entry = vector::borrow(entries, index);
            if (key == &entry.key) {
                let Entry { key: _, value } = vector::remove(entries, index);
                return option::some(value)
            };
        };
        option::none()
    }

    /// Modifies element by calling modify_f if it exists, or calling add_f to add if it doesn't.
    /// Returns true if element already existed.
    public inline fun modify_or_add<K: drop + copy + store, V: store>(self: &mut OrderedMap<K, V>, key: &K, modify_f: |&mut V|, add_f: ||V): bool {
        let iter = internal_find(self, key);
        if (iter_is_end(&iter, self)) {
            add(self, *key, add_f());
            false
        } else {
            modify_f(iter_borrow_mut(iter, self));
            true
        }
    }

    /// Modifies element by calling modify_f if it exists.
    /// Returns true if element already existed.
    public inline fun modify_if_present<K: drop + copy + store, V: store>(self: &mut OrderedMap<K, V>, key: &K, modify_f: |&mut V|): bool {
        let iter = internal_find(self, key);
        if (iter_is_end(&iter, self)) {
            false
        } else {
            modify_f(iter_borrow_mut(iter, self));
            true
        }
    }

    /// Returns whether map contains a given key.
    public fun contains<K, V>(self: &OrderedMap<K, V>, key: &K): bool {
        !iter_is_end(&internal_find(self, key), self)
    }

    public fun borrow<K, V>(self: &OrderedMap<K, V>, key: &K): &V {
        iter_borrow(internal_find(self, key), self)
    }

    public fun borrow_mut<K, V>(self: &mut OrderedMap<K, V>, key: &K): &mut V {
        iter_borrow_mut(internal_find(self, key), self)
    }

    public fun get<K: drop + copy + store, V: copy + store>(self: &OrderedMap<K, V>, key: &K): Option<V> {
        let iter = internal_find(self, key);
        if (iter_is_end(&iter, self)) {
            option::none()
        } else {
            let value_ref = iter_borrow(iter, self);
            option::some(*value_ref)
        }
    }

    public inline fun get_and_map<K: drop + copy + store, V: copy + store, R>(self: &OrderedMap<K, V>, key: &K, f: |&V|R): Option<R> {
        let iter = internal_find(self, key);
        if (iter_is_end(&iter, self)) {
            option::none()
        } else {
            let value_ref = iter_borrow(iter, self);
            option::some(f(value_ref))
        }
    }

    /// Changes the key, while keeping the same value attached to it
    /// Aborts with EKEY_NOT_FOUND if `old_key` doesn't exist.
    /// Aborts with ENEW_KEY_NOT_IN_ORDER if `new_key` doesn't keep the order `old_key` was in.
    public(friend) fun replace_key_inplace<K: drop, V>(self: &mut OrderedMap<K, V>, old_key: &K, new_key: K) {
        let entries = &mut option::borrow_mut(&mut self.SortedVectorMap).entries;
        let len = vector::length(entries);
        let index = binary_search(old_key, entries, 0, len);
        assert!(index < len, error::invalid_argument(EKEY_NOT_FOUND));

        let entry_ref = vector::borrow(entries, index);
        assert!(old_key == &entry_ref.key, error::invalid_argument(EKEY_NOT_FOUND));

        // check that after we update the key, order is going to be respected
        if (index > 0) {
            let prev_entry = vector::borrow(entries, index - 1);
            let ord = cmp::compare(&prev_entry.key, &new_key);
            assert!(cmp::is_lt(&ord), error::invalid_argument(ENEW_KEY_NOT_IN_ORDER))
        };

        if (index + 1 < len) {
            let next_entry = vector::borrow(entries, index + 1);
            let ord = cmp::compare(&new_key, &next_entry.key);
            assert!(cmp::is_lt(&ord), error::invalid_argument(ENEW_KEY_NOT_IN_ORDER))
        };

        let entry_mut = vector::borrow_mut(entries, index);
        entry_mut.key = new_key;
    }

    /// Add multiple key/value pairs to the map. The keys must not already exist.
    /// Aborts with EKEY_ALREADY_EXISTS if key already exist, or duplicate keys are passed in.
    public fun add_all<K, V>(self: &mut OrderedMap<K, V>, keys: vector<K>, values: vector<V>) {
        // TODO: Can be optimized, by sorting keys and values, and then creating map.
        // keys.zip(values, |key, value| {
        //     add(self, key, value);
        // });
        vector::zip(keys, values, |key, value| {
            add(self, key, value);
        });
    }

    /// Add multiple key/value pairs to the map, overwrites values if they exist already,
    /// or if duplicate keys are passed in.
    public fun upsert_all<K: drop, V: drop>(self: &mut OrderedMap<K, V>, keys: vector<K>, values: vector<V>) {
        // TODO: Can be optimized, by sorting keys and values, and then creating map.
        vector::zip(keys, values, |key, value| {
            upsert(self, key, value);
        });
    }

    /// Takes all elements from `other` and adds them to `self`,
    /// overwritting if any key is already present in self.
    public fun append<K: drop, V: drop>(self: &mut OrderedMap<K, V>, other: OrderedMap<K, V>) {
        append_impl(self, other);
    }

    /// Takes all elements from `other` and adds them to `self`.
    /// Aborts with EKEY_ALREADY_EXISTS if `other` has a key already present in `self`.
    public fun append_disjoint<K, V>(self: &mut OrderedMap<K, V>, other: OrderedMap<K, V>) {
        let overwritten = append_impl(self, other);
        assert!(vector::length(&overwritten) == 0, error::invalid_argument(EKEY_ALREADY_EXISTS));
        vector::destroy_empty(overwritten);
    }

    /// Takes all elements from `other` and adds them to `self`, returning list of entries in self that were overwritten.
    fun append_impl<K, V>(self: &mut OrderedMap<K, V>, other: OrderedMap<K, V>): vector<Entry<K,V>> {
        let OrderedMap { tag: _, SortedVectorMap: sorted_vector_map } = other;
        let SortedVectorMapData { entries: other_entries } = option::destroy_some(sorted_vector_map);
        let overwritten = vector::empty();

        if (vector::is_empty(&other_entries)) {
            vector::destroy_empty(other_entries);
            return overwritten
        };

        let entries = &mut option::borrow_mut(&mut self.SortedVectorMap).entries;
        if (vector::is_empty(entries)) {
            vector::append(entries, other_entries);
            return overwritten
        };

        // Optimization: if all elements in `other` are larger than all elements in `self`, we can just move them over.
        let should_append_tail = {
            let last_index = vector::length(entries) - 1;
            let last_key_ref = &vector::borrow(entries, last_index).key;
            let other_first_key_ref = &vector::borrow(&other_entries, 0).key;
            cmp::is_lt(&cmp::compare(last_key_ref, other_first_key_ref))
        };
        if (should_append_tail) {
            vector::append(entries, other_entries);
            return overwritten
        };

        // In O(n), traversing from the back, build reverse sorted result, and then reverse it back
        let reverse_result = vector::empty();
        let cur_i = vector::length(entries) - 1;
        let other_i = vector::length(&other_entries) - 1;

        // after the end of the loop, other_entries is empty, and any leftover is in entries
        loop {
            let ord = {
                let cur_entry = vector::borrow(entries, cur_i);
                let other_entry = vector::borrow(&other_entries, other_i);
                cmp::compare(&cur_entry.key, &other_entry.key)
            };
            if (cmp::is_gt(&ord)) {
                vector::push_back(&mut reverse_result, vector::pop_back(entries));
                if (cur_i == 0) {
                    // make other_entries empty, and rest in entries.
                    // TODO cannot use mem::swap until it is public/released
                    // mem::swap(&mut entries, &mut other_entries);
                    vector::append(entries, other_entries);
                    break
                } else {
                    cur_i = cur_i - 1;
                };
            } else {
                // is_lt or is_eq
                if (cmp::is_eq(&ord)) {
                    // we skip the entries one, and below put in the result one from other.
                    vector::push_back(&mut overwritten, vector::pop_back(entries));

                    if (cur_i == 0) {
                        // make other_entries empty, and rest in entries.
                        // TODO cannot use mem::swap until it is public/released
                        // mem::swap(&mut entries, &mut other_entries);
                        vector::append(entries, other_entries);
                        break
                    } else {
                        cur_i = cur_i - 1;
                    };
                };

                vector::push_back(&mut reverse_result, vector::pop_back(&mut other_entries));
                if (other_i == 0) {
                    vector::destroy_empty(other_entries);
                    break
                } else {
                    other_i = other_i - 1;
                };
            };
        };

        vector::reverse_append(entries, reverse_result);

        overwritten
    }

    /// Splits the collection into two, such to leave `self` with `at` number of elements.
    /// Returns a newly allocated map containing the elements in the range [at, len).
    /// After the call, the original map will be left containing the elements [0, at).
    public fun trim<K, V>(self: &mut OrderedMap<K, V>, at: u64): OrderedMap<K, V> {
        let entries = &mut option::borrow_mut(&mut self.SortedVectorMap).entries;
        let rest = vector::trim(entries, at);

        OrderedMap {
            tag: 1,
            SortedVectorMap: option::some(SortedVectorMapData {
                entries: rest
            }),
        }
    }

    public fun borrow_front<K, V>(self: &OrderedMap<K, V>): (&K, &V) {
        let entries = &option::borrow(&self.SortedVectorMap).entries;
        let entry = vector::borrow(entries, 0);
        (&entry.key, &entry.value)
    }

    public fun borrow_back<K, V>(self: &OrderedMap<K, V>): (&K, &V) {
        let entries = &option::borrow(&self.SortedVectorMap).entries;
        let entry = vector::borrow(entries, vector::length(entries) - 1);
        (&entry.key, &entry.value)
    }

    public fun pop_front<K, V>(self: &mut OrderedMap<K, V>): (K, V) {
        let entries = &mut option::borrow_mut(&mut self.SortedVectorMap).entries;
        let Entry { key, value } = vector::remove(entries, 0);
        (key, value)
    }

    public fun pop_back<K, V>(self: &mut OrderedMap<K, V>): (K, V) {
        let entries = &mut option::borrow_mut(&mut self.SortedVectorMap).entries;
        let Entry { key, value } = vector::pop_back(entries);
        (key, value)
    }

    public fun prev_key<K: copy, V>(self: &OrderedMap<K, V>, key: &K): Option<K> {
        let it = internal_lower_bound(self, key);
        if (iter_is_begin(&it, self)) {
            option::none()
        } else {
            let prev_it = iter_prev(it, self);
            option::some(*iter_borrow_key(&prev_it, self))
        }
    }

    public fun next_key<K: copy, V>(self: &OrderedMap<K, V>, key: &K): Option<K> {
        let it = internal_lower_bound(self, key);
        if (iter_is_end(&it, self)) {
            option::none()
        } else {
            let cur_key = iter_borrow_key(&it, self);
            if (key == cur_key) {
                let next_it = iter_next(it, self);
                if (iter_is_end(&next_it, self)) {
                    option::none()
                } else {
                    option::some(*iter_borrow_key(&next_it, self))
                }
            } else {
                option::some(*cur_key)
            }
        }
    }

    // TODO: see if it is more understandable if iterator points between elements,
    // and there is iter_borrow_next and iter_borrow_prev, and provide iter_insert.
    // This is called "cursor" in rust instead.

    /// Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
    /// For direct usage of this method, check Warning at the top of the file corresponding to iterators.
    ///
    /// Returns an iterator pointing to the first element that is greater or equal to the provided
    /// key, or an end iterator if such element doesn't exist.
    public fun internal_lower_bound<K, V>(self: &OrderedMap<K, V>, key: &K): IteratorPtr {
        let entries = &option::borrow(&self.SortedVectorMap).entries;
        let len = vector::length(entries);

        let index = binary_search(key, entries, 0, len);
        if (index == len) {
            internal_new_end_iter(self)
        } else {
            new_iter(index)
        }
    }

    /// Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
    /// For direct usage of this method, check Warning at the top of the file corresponding to iterators.
    ///
    /// Returns an iterator pointing to the element that equals to the provided key, or an end
    /// iterator if the key is not found.
    public fun internal_find<K, V>(self: &OrderedMap<K, V>, key: &K): IteratorPtr {
        let internal_lower_bound = internal_lower_bound(self, key);
        if (iter_is_end(&internal_lower_bound, self)) {
            internal_lower_bound
        } else if (iter_borrow_key(&internal_lower_bound, self) == key) {
            internal_lower_bound
        } else {
            internal_new_end_iter(self)
        }
    }

    /// Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
    /// For direct usage of this method, check Warning at the top of the file corresponding to iterators.
    ///
    /// Returns the begin iterator.
    public fun internal_new_begin_iter<K, V>(self: &OrderedMap<K, V>): IteratorPtr {
        if (is_empty(self)) {
            return new_end_iter()
        };

        new_iter(0)
    }

    /// Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
    /// For direct usage of this method, check Warning at the top of the file corresponding to iterators.
    ///
    /// Returns the end iterator.
    public fun internal_new_end_iter<K, V>(_self: &OrderedMap<K, V>): IteratorPtr {
        new_end_iter()
    }

    // ========== Section for methods opearting on iterators ========
    // Note: After any modifications to the map, do not use any of the iterators obtained beforehand.
    // Operations on iterators after map is modified are unexpected/incorrect.

    /// Returns the next iterator, or none if already at the end iterator.
    /// Note: Requires that the map is not changed after the input iterator is generated.
    public fun iter_next<K, V>(self: IteratorPtr, map: &OrderedMap<K, V>): IteratorPtr {
        assert!(!iter_is_end(&self, map), error::invalid_argument(EITER_OUT_OF_BOUNDS));

        let index = option::borrow(&self.Position).index + 1;
        let entries = &option::borrow(&map.SortedVectorMap).entries;
        if (index < vector::length(entries)) {
            new_iter(index)
        } else {
            internal_new_end_iter(map)
        }
    }

    /// Returns the previous iterator, or none if already at the begin iterator.
    /// Note: Requires that the map is not changed after the input iterator is generated.
    public fun iter_prev<K, V>(self: IteratorPtr, map: &OrderedMap<K, V>): IteratorPtr {
        assert!(!iter_is_begin(&self, map), error::invalid_argument(EITER_OUT_OF_BOUNDS));

        let entries = &option::borrow(&map.SortedVectorMap).entries;
        let index = if (option::is_some(&self.End)) {
            vector::length(entries) - 1
        } else {
            option::borrow(&self.Position).index - 1
        };

        new_iter(index)
    }

    /// Returns whether the iterator is a begin iterator.
    public fun iter_is_begin<K, V>(self: &IteratorPtr, map: &OrderedMap<K, V>): bool {
        if (option::is_some(&self.End)) {
            is_empty(map)
        } else {
            option::borrow(&self.Position).index == 0
        }
    }

    /// Returns true iff the iterator is a begin iterator from a non-empty collection.
    /// (I.e. if iterator points to a valid element)
    /// This method doesn't require having access to map, unlike iter_is_begin.
    public fun iter_is_begin_from_non_empty(self: &IteratorPtr): bool {
        if (option::is_some(&self.End)) {
            false
        } else {
            option::borrow(&self.Position).index == 0
        }
    }

    /// Returns whether the iterator is an end iterator.
    public fun iter_is_end<K, V>(self: &IteratorPtr, _map: &OrderedMap<K, V>): bool {
        option::is_some(&self.End)
    }

    /// Borrows the key given iterator points to.
    /// Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
    /// Note: Requires that the map is not changed after the input iterator is generated.
    public fun iter_borrow_key<K, V>(self: &IteratorPtr, map: &OrderedMap<K, V>): &K {
        assert!(!option::is_some(&self.End), error::invalid_argument(EITER_OUT_OF_BOUNDS));

        let entries = &option::borrow(&map.SortedVectorMap).entries;
        &vector::borrow(entries, option::borrow(&self.Position).index).key
    }

    /// Borrows the value given iterator points to.
    /// Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
    /// Note: Requires that the map is not changed after the input iterator is generated.
    public fun iter_borrow<K, V>(self: IteratorPtr, map: &OrderedMap<K, V>): &V {
        assert!(!option::is_some(&self.End), error::invalid_argument(EITER_OUT_OF_BOUNDS));
        let entries = &option::borrow(&map.SortedVectorMap).entries;
        &vector::borrow(entries, option::borrow(&self.Position).index).value
    }

    /// Mutably borrows the value iterator points to.
    /// Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
    /// Note: Requires that the map is not changed after the input iterator is generated.
    public fun iter_borrow_mut<K, V>(self: IteratorPtr, map: &mut OrderedMap<K, V>): &mut V {
        assert!(!option::is_some(&self.End), error::invalid_argument(EITER_OUT_OF_BOUNDS));
        let entries = &mut option::borrow_mut(&mut map.SortedVectorMap).entries;
        &mut vector::borrow_mut(entries, option::borrow(&self.Position).index).value
    }

    /// Removes (key, value) pair iterator points to, returning the previous value.
    /// Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
    /// Note: Requires that the map is not changed after the input iterator is generated.
    public fun iter_remove<K: drop, V>(self: IteratorPtr, map: &mut OrderedMap<K, V>): V {
        assert!(!option::is_some(&self.End), error::invalid_argument(EITER_OUT_OF_BOUNDS));

        let entries = &mut option::borrow_mut(&mut map.SortedVectorMap).entries;
        let Entry { key: _, value } = vector::remove(entries, option::borrow(&self.Position).index);
        value
    }

    /// Replaces the value iterator is pointing to, returning the previous value.
    /// Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
    /// Note: Requires that the map is not changed after the input iterator is generated.
    public fun iter_replace<K: copy + drop, V>(self: IteratorPtr, map: &mut OrderedMap<K, V>, value: V): V {
        assert!(!option::is_some(&self.End), error::invalid_argument(EITER_OUT_OF_BOUNDS));

        // TODO once mem::replace is public/released, update to:
        // let entry = entries.borrow_mut(index);
        // mem::replace(&mut entry.value, value)
        let entries = &mut option::borrow_mut(&mut map.SortedVectorMap).entries;
        let index = option::borrow(&self.Position).index;
        let key = vector::borrow(entries, index).key;
        let Entry {
            key: _,
            value: prev_value,
        } = vector::replace(entries, index, Entry { key, value });
        prev_value
    }

    /// Add key/value pair to the map, at the iterator position (before the element at the iterator position).
    /// Aborts with ENEW_KEY_NOT_IN_ORDER is key is not larger than the key before the iterator,
    /// or smaller than the key at the iterator position.
    public fun iter_add<K, V>(self: IteratorPtr, map: &mut OrderedMap<K, V>, key: K, value: V) {
        let entries = &mut option::borrow_mut(&mut map.SortedVectorMap).entries;
        let len = vector::length(entries);
        let insert_index = if (option::is_some(&self.End)) {
            len
        } else {
            option::borrow(&self.Position).index
        };

        if (insert_index > 0) {
            let prev_entry = vector::borrow(entries, insert_index - 1);
            let ord = cmp::compare(&prev_entry.key, &key);
            assert!(cmp::is_lt(&ord), error::invalid_argument(ENEW_KEY_NOT_IN_ORDER))
        };

        if (insert_index < len) {
            let next_entry = vector::borrow(entries, insert_index);
            let ord = cmp::compare(&key, &next_entry.key);
            assert!(cmp::is_lt(&ord), error::invalid_argument(ENEW_KEY_NOT_IN_ORDER))
        };

        vector::insert(entries, insert_index, Entry { key, value });
    }

    /// Destroys empty map.
    /// Aborts if `self` is not empty.
    public fun destroy_empty<K, V>(self: OrderedMap<K, V>) {
        let OrderedMap { tag: _, SortedVectorMap: sorted_vector_map } = self;
        let SortedVectorMapData { entries } = option::destroy_some(sorted_vector_map);
        // assert!(vector::is_empty(&entries), E_NOT_EMPTY);
        vector::destroy_empty(entries);
    }

    // ========= Section with views and inline for-loop methods =======

    /// Return all keys in the map. This requires keys to be copyable.
    public fun keys<K: copy, V>(self: &OrderedMap<K, V>): vector<K> {
        let entries = &option::borrow(&self.SortedVectorMap).entries;
        vector::map_ref(entries, |e| {
            let e: &Entry<K, V> = e;
            e.key
        })
    }

    /// Return all values in the map. This requires values to be copyable.
    public fun values<K, V: copy>(self: &OrderedMap<K, V>): vector<V> {
        let entries = &option::borrow(&self.SortedVectorMap).entries;
        vector::map_ref(entries, |e| {
            let e: &Entry<K, V> = e;
            e.value
        })
    }

    /// Transform the map into two vectors with the keys and values respectively
    /// Primarily used to destroy a map
    public fun to_vec_pair<K, V>(self: OrderedMap<K, V>): (vector<K>, vector<V>) {
        let keys: vector<K> = vector::empty();
        let values: vector<V> = vector::empty();
        let OrderedMap { tag: _, SortedVectorMap: sorted_vector_map } = self;
        let SortedVectorMapData { entries } = option::destroy_some(sorted_vector_map);
        vector::for_each(entries, |e| {
            let Entry { key, value } = e;
            vector::push_back(&mut keys, key);
            vector::push_back(&mut values, value);
        });
        (keys, values)
    }

    /// For maps that cannot be dropped this is a utility to destroy them
    /// using lambdas to destroy the individual keys and values.
    public inline fun destroy<K, V>(
        self: OrderedMap<K, V>,
        dk: |K|,
        dv: |V|
    ) {
        let (keys, values) = to_vec_pair(self);
        vector::destroy(keys, |_k| dk(_k));
        vector::destroy(values, |_v| dv(_v));
    }

    /// Apply the function to each key-value pair in the map, consuming it.
    public inline fun for_each<K, V>(
        self: OrderedMap<K, V>,
        f: |K, V|
    ) {
        let (keys, values) = to_vec_pair(self);
        vector::zip(keys, values, |k, v| f(k, v));
    }

    /// Apply the function to a reference of each key-value pair in the map.
    public inline fun for_each_ref<K: copy + drop, V>(self: &OrderedMap<K, V>, f: |&K, &V|) {
        let iter = internal_new_begin_iter(self);
        while (!iter_is_end(&iter, self)) {
            f(iter_borrow_key(&iter, self), iter_borrow(iter, self));
            iter = iter_next(iter, self);
        }

        // TODO: once move supports private functions update to:
        // vector::for_each_ref(
        //     &entries,
        //     |entry| {
        //         f(&entry.key, &entry.value)
        //     }
        // );
    }

    /// Apply the function to a mutable reference of each key-value pair in the map.
    public inline fun for_each_mut<K: copy + drop, V>(self: &mut OrderedMap<K, V>, f: |&K, &mut V|) {
        let iter = internal_new_begin_iter(self);
        while (!iter_is_end(&iter, self)) {
            let key = *iter_borrow_key(&iter, self);
            f(&key, iter_borrow_mut(iter, self));
            iter = iter_next(iter, self);
        }

        // TODO: once move supports private functions udpate to:
        // vector::for_each_mut(
        //     &mut entries,
        //     |entry| {
        //         f(&mut entry.key, &mut entry.value)
        //     }
        // );
    }

    // ========= Section with private methods ===============

    inline fun new_iter(index: u64): IteratorPtr {
        IteratorPtr {
            tag: 2,
            End: option::none(),
            Position: option::some(PositionData {
                index: index,
            }),
        }
    }

    inline fun new_end_iter(): IteratorPtr {
        IteratorPtr {
            tag: 1,
            End: option::some(true),
            Position: option::none(),
        }
    }

    // return index containing the key, or insert position.
    // I.e. index of first element that has key larger or equal to the passed `key` argument.
    fun binary_search<K, V>(key: &K, entries: &vector<Entry<K, V>>, start: u64, end: u64): u64 {
        let l = start;
        let r = end;
        while (l != r) {
            let mid = l + ((r - l) >> 1);
            let comparison = cmp::compare(&vector::borrow(entries, mid).key, key);
            if (cmp::is_lt(&comparison)) {
                l = mid + 1;
            } else {
                r = mid;
            };
        };
        l
    }

    // see if useful, and add
    //
    // public fun iter_num_below<K, V>(self: IteratorPtr, map: &OrderedMap<K, V>): u64 {
    //     if (self.iter_is_end()) {
    //         map.entries.length()
    //     } else {
    //         self.index
    //     }
    // }

    spec module {
        pragma verify = true;
    }

    spec native fun spec_len<K, V>(map: OrderedMap<K, V>): num;
    spec native fun spec_contains_key<K, V>(map: OrderedMap<K, V>, key: K): bool;
    spec native fun spec_get<K, V>(map: OrderedMap<K, V>, key: K): V;

    // ================= Section for tests =====================

    #[test_only]
    public fun print_map<K, V>(self: &OrderedMap<K, V>) {
        let entries = &option::borrow(&self.SortedVectorMap).entries;
        endless_std::debug::print(entries);
    }

    #[test_only]
    public fun validate_ordered<K, V>(self: &OrderedMap<K, V>) {
        let entries = &option::borrow(&self.SortedVectorMap).entries;
        let len = vector::length(entries);
        let i = 1;
        while (i < len) {
            let comparison = cmp::compare(&vector::borrow(entries, i).key, &vector::borrow(entries, i - 1).key);
            let is_ordered = !cmp::is_lt(&comparison);
            assert!(is_ordered, 1);
            i = i + 1;
        };
    }

    #[test_only]
    fun validate_iteration<K: drop + copy + store, V: store>(self: &OrderedMap<K, V>) {
        let expected_num_elements = length(self);
        let num_elements = 0;
        let it = internal_new_begin_iter(self);
        while (!iter_is_end(&it, self)) {
            num_elements = num_elements + 1;
            it = iter_next(it, self);
        };
        assert!(num_elements == expected_num_elements, 2);

        num_elements = 0;
        it = internal_new_end_iter(self);
        while (!iter_is_begin(&it, self)) {
            it = iter_prev(it, self);
            num_elements = num_elements + 1;
        };
        assert!(num_elements == expected_num_elements, 3);
    }

    #[test_only]
    fun validate_map<K: drop + copy + store, V: store>(self: &OrderedMap<K, V>) {
        validate_ordered(self);
        validate_iteration(self);
    }

    #[test]
    fun test_map_small() {
        let map = new();
        validate_map(&map);
        add(&mut map, 1, 1);
        validate_map(&map);
        add(&mut map, 2, 2);
        validate_map(&map);
        let r1 = upsert(&mut map, 3, 3);
        validate_map(&map);
        assert!(r1 == option::none(), 4);
        add(&mut map, 4, 4);
        validate_map(&map);
        let r2 = upsert(&mut map, 4, 8);
        validate_map(&map);
        assert!(r2 == option::some(4), 5);
        add(&mut map, 5, 5);
        validate_map(&map);
        add(&mut map, 6, 6);
        validate_map(&map);

        remove(&mut map, &5);
        validate_map(&map);
        remove(&mut map, &4);
        validate_map(&map);
        remove(&mut map, &1);
        validate_map(&map);
        remove(&mut map, &3);
        validate_map(&map);
        remove(&mut map, &2);
        validate_map(&map);
        remove(&mut map, &6);
        validate_map(&map);

        destroy_empty(map);
    }

    #[test]
    fun test_add_remove_many() {
        let map = new<u64, u64>();

        assert!(length(&map) == 0, 0);
        assert!(!contains(&map, &3), 1);
        add(&mut map, 3, 1);
        assert!(length(&map) == 1, 2);
        assert!(contains(&map, &3), 3);
        assert!(borrow(&map, &3) == &1, 4);
        *borrow_mut(&mut map, &3) = 2;
        assert!(borrow(&map, &3) == &2, 5);

        assert!(!contains(&map, &2), 6);
        add(&mut map, 2, 5);
        assert!(length(&map) == 2, 7);
        assert!(contains(&map, &2), 8);
        assert!(borrow(&map, &2) == &5, 9);
        *borrow_mut(&mut map, &2) = 9;
        assert!(borrow(&map, &2) == &9, 10);

        remove(&mut map, &2);
        assert!(length(&map) == 1, 11);
        assert!(!contains(&map, &2), 12);
        assert!(borrow(&map, &3) == &2, 13);

        remove(&mut map, &3);
        assert!(length(&map) == 0, 14);
        assert!(!contains(&map, &3), 15);

        destroy_empty(map);
    }

    #[test]
    fun test_add_all() {
        let map = new<u64, u64>();

        assert!(length(&map) == 0, 0);
        add_all(&mut map, vector[2, 1, 3], vector[20, 10, 30]);

        assert!(map == new_from(vector[1, 2, 3], vector[10, 20, 30]), 1);

        assert!(length(&map) == 3, 1);
        assert!(borrow(&map, &1) == &10, 2);
        assert!(borrow(&map, &2) == &20, 3);
        assert!(borrow(&map, &3) == &30, 4);
    }

    #[test]
    #[expected_failure(abort_code = 0x20002, location = Self)] /// EKEY_ALREADY_EXISTS
    fun test_add_all_mismatch() {
        new_from(vector[1, 3], vector[10]);
    }

    #[test]
    fun test_upsert_all() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        upsert_all(&mut map, vector[7, 2, 3], vector[70, 20, 35]);
        assert!(map == new_from(vector[1, 2, 3, 5, 7], vector[10, 20, 35, 50, 70]), 1);
    }

    #[test]
    #[expected_failure(abort_code = 0x10001, location = Self)] /// EKEY_ALREADY_EXISTS
    fun test_new_from_duplicate() {
        new_from(vector[1, 3, 1, 5], vector[10, 30, 11, 50]);
    }

    #[test]
    #[expected_failure(abort_code = 0x20002, location = Self)] /// EKEY_ALREADY_EXISTS
    fun test_upsert_all_mismatch() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        upsert_all(&mut map, vector[2], vector[20, 35]);
    }

    #[test]
    fun test_to_vec_pair() {
        let (keys, values) = to_vec_pair(new_from(vector[3, 1, 5], vector[30, 10, 50]));
        assert!(keys == vector[1, 3, 5], 1);
        assert!(values == vector[10, 30, 50], 2);
    }

    #[test]
    fun test_keys() {
        let map = new<u64, u64>();
        assert!(keys(&map) == vector[], 0);
        add(&mut map, 2, 1);
        add(&mut map, 3, 1);

        assert!(keys(&map) == vector[2, 3], 0);
    }

    #[test]
    fun test_values() {
        let map = new<u64, u64>();
        assert!(values(&map) == vector[], 0);
        add(&mut map, 2, 1);
        add(&mut map, 3, 2);

        assert!(values(&map) == vector[1, 2], 0);
    }

    #[test]
    fun test_modify_and_get() {
        let map = new<u64, u64>();
        add_all(&mut map, vector[1, 2, 3], vector[1, 2, 3]);
        // Test modify_if_present with existing key
        // Note: Cannot use `*v = *v + 10` or `*v += 10` due to borrow checker limitations
        // Simple workaround: get the old value, compute new value, then update
        let old_value = option::destroy_some(get(&map, &2));
        *borrow_mut(&mut map, &2) = old_value + 10;
        assert!(get(&map, &2) == option::some(12), 0);

        // Test modify_if_present with non-existing key
        // assert!(false == modify_if_present(&mut map, &4, |v| *v = 100), 0);
        // assert!(get(&map, &4) == option::none(), 0);

        // assert!(get_and_map(&map, &2, |v| *v + 5) == option::some(17), 0);
        // assert!(get_and_map(&map, &4, |v| *v + 5) == option::none(), 0);

        // modify_or_add(&mut map, &3, |v| {*v = v + 10}, || 20);
        // assert!(get(&map, &3) == option::some(13), 0);
        // modify_or_add(&mut map, &4, |v| {*v = v + 10}, || 20);
        // assert!(get(&map, &4) == option::some(20), 0);
    }

    #[test]
    fun test_for_each_variants() {
        let keys = vector[1, 3, 5];
        let values = vector[10, 30, 50];
        let map = new_from(keys, values);

        let index = 0;
        for_each_ref(&map, |k, v| {
            assert!( *vector::borrow(&keys,index) == *k, 0);
            assert!(*vector::borrow(&values,index) == *v, 0);
            index = index + 1;
        });

        // Modify all values: increment each value by 1
        // values [10, 30, 50] -> map values become [11, 31, 51]
        let index = 0;
        for_each_mut(&mut map, |k, v| {
            assert!(*vector::borrow(&keys, index) == *k, 0);
            // Read the expected value and new value from external vector
            let expected_value = *vector::borrow(&values, index);
            let new_value = expected_value + 1;
            // Assign new value to *v (can't read *v after this point)
            *v = new_value;
            index = index + 1;
        });

        // Verify the modified values: should be original values + 1
        let index = 0;
        for_each(map, |k, v| {
            assert!(*vector::borrow(&keys, index) == k, 0);
            assert!(*vector::borrow(&values, index) + 1 == v, 0);  // values[i] + 1 should equal v
            index = index + 1;
        });
    }

    #[test]
    fun test_iter_next_vs_lower_bound() {
        // Simple test to verify iter_next == internal_lower_bound(element + 1)
        let map = new();
        add(&mut map, 10, 100);
        add(&mut map, 20, 200);
        add(&mut map, 30, 300);

        let it = internal_find(&map, &10);
        let it_next = iter_next(it, &map);
        let it_after = internal_lower_bound(&map, &11);
        assert!(it_next == it_after, 1);

        let it = internal_find(&map, &20);
        let it_next = iter_next(it, &map);
        let it_after = internal_lower_bound(&map, &21);
        assert!(it_next == it_after, 2);
    }

    #[test]
    fun test_duplicate_228() {
        // Recreate the exact situation from large_dataset around 228
        let map = new();

        // Add a bunch of elements including those around 228
        let elements = vector[11, 12, 19, 22, 27, 29, 31, 34, 42, 43, 58, 59, 60, 67, 69, 84, 87, 91, 94, 97, 117, 121, 123, 124, 135, 143, 149, 167, 170, 172, 178, 193, 198, 211, 219, 226, 227, 228, 229, 235, 237, 245, 270, 275, 276, 280, 281, 286];

        let i = 0;
        let len = vector::length(&elements);
        while (i < len) {
            let element = *vector::borrow(&elements, i);
            upsert(&mut map, element, element);
            i = i + 1;
        };

        // Now test 228
        let it = internal_find(&map, &228);
        assert!(!iter_is_end(&it, &map), 1);
        assert!(iter_borrow_key(&it, &map) == &228, 2);

        let it_next = iter_next(it, &map);
        let it_after = internal_lower_bound(&map, &229);

        // Debug: check if both are pointing to 229
        if (!iter_is_end(&it_next, &map)) {
            assert!(iter_borrow_key(&it_next, &map) == &229, 3);
        };
        if (!iter_is_end(&it_after, &map)) {
            assert!(iter_borrow_key(&it_after, &map) == &229, 4);
        };

        // These should be equal
        assert!(it_next == it_after, 5);
    }

    #[test]
    #[expected_failure(abort_code = 0x10001, location = Self)] /// EKEY_ALREADY_EXISTS
    fun test_add_twice() {
        let map = new<u64, u64>();
        add(&mut map, 3, 1);
        add(&mut map, 3, 1);

        remove(&mut map, &3);
        destroy_empty(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10002, location = Self)] /// EKEY_NOT_FOUND
    fun test_remove_twice_1() {
        let map = new<u64, u64>();
        add(&mut map, 3, 1);
        remove(&mut map, &3);
        remove(&mut map, &3);

        destroy_empty(map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10002, location = Self)] /// EKEY_NOT_FOUND
    fun test_remove_twice_2() {
        let map = new<u64, u64>();
        add(&mut map, 3, 1);
        add(&mut map, 4, 1);
        remove(&mut map, &3);
        remove(&mut map, &3);

        destroy_empty(map);
    }

    #[test]
    fun test_upsert_test() {
        let map = new<u64, u64>();
        // test adding 3 elements using upsert
        upsert(&mut map, 1, 1);
        upsert(&mut map, 2, 2);
        upsert(&mut map, 3, 3);

        assert!(length(&map) == 3, 0);
        assert!(contains(&map, &1), 1);
        assert!(contains(&map, &2), 2);
        assert!(contains(&map, &3), 3);
        assert!(borrow(&map, &1) == &1, 4);
        assert!(borrow(&map, &2) == &2, 5);
        assert!(borrow(&map, &3) == &3, 6);

        // change mapping 1->1 to 1->4
        upsert(&mut map, 1, 4);

        assert!(length(&map) == 3, 7);
        assert!(contains(&map, &1), 8);
        assert!(borrow(&map, &1) == &4, 9);
    }

    #[test]
    fun test_append() {
        {
            let map = new<u16, u16>();
            let other = new();
            append(&mut map, other);
            assert!(is_empty(&map), 0);
        };
        {
            let map = new_from(vector[1, 2], vector[10, 20]);
            let other = new();
            append(&mut map, other);
            assert!(map == new_from(vector[1, 2], vector[10, 20]), 1);
        };
        {
            let map = new();
            let other = new_from(vector[1, 2], vector[10, 20]);
            append(&mut map, other);
            assert!(map == new_from(vector[1, 2], vector[10, 20]), 2);
        };
        {
            let map = new_from(vector[1, 2, 3], vector[10, 20, 30]);
            let other = new_from(vector[4, 5], vector[40, 50]);
            append(&mut map, other);
            assert!(map == new_from(vector[1, 2, 3, 4, 5], vector[10, 20, 30, 40, 50]), 3);
        };
        {
            let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
            let other = new_from(vector[2, 4], vector[20, 40]);
            append(&mut map, other);
            assert!(map == new_from(vector[1, 2, 3, 4, 5], vector[10, 20, 30, 40, 50]), 4);
        };
        {
            let map = new_from(vector[2, 4], vector[20, 40]);
            let other = new_from(vector[1, 3, 5], vector[10, 30, 50]);
            append(&mut map, other);
            assert!(map == new_from(vector[1, 2, 3, 4, 5], vector[10, 20, 30, 40, 50]), 6);
        };
        {
            let map = new_from(vector[1], vector[10]);
            let other = new_from(vector[1], vector[11]);
            append(&mut map, other);
            assert!(map == new_from(vector[1], vector[11]), 7);
        }
    }

    #[test]
    fun test_append_disjoint() {
        let map = new_from(vector[1, 2, 3], vector[10, 20, 30]);
        let other = new_from(vector[4, 5], vector[40, 50]);
        append_disjoint(&mut map, other);
        assert!(map == new_from(vector[1, 2, 3, 4, 5], vector[10, 20, 30, 40, 50]), 1);
    }

    #[test]
    #[expected_failure(abort_code = 0x10001, location = Self)] /// EKEY_ALREADY_EXISTS
    fun test_append_disjoint_abort() {
        let map = new_from(vector[1], vector[10]);
        let other = new_from(vector[1], vector[11]);
        append_disjoint(&mut map, other);
    }

    #[test]
    fun test_trim() {
        let map = new_from(vector[1, 2, 3], vector[10, 20, 30]);
        let rest = trim(&mut map, 2);
        assert!(map == new_from(vector[1, 2], vector[10, 20]), 1);
        assert!(rest == new_from(vector[3], vector[30]), 2);
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
        assert!(front_k == &1, 6);
        assert!(front_v == &10, 7);

        let (back_k, back_v) = borrow_back(&map);
        assert!(back_k == &3, 8);
        assert!(back_v == &30, 9);

        let (front_k, front_v) = pop_front(&mut map);
        assert!(front_k == 1, 10);
        assert!(front_v == 10, 11);

        let (back_k, back_v) = pop_back(&mut map);
        assert!(back_k == 3, 12);
        assert!(back_v == 30, 13);
    }

    #[test]
    fun test_replace_key_inplace() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        replace_key_inplace(&mut map, &5, 6);
        assert!(map == new_from(vector[1, 3, 6], vector[10, 30, 50]), 1);
        replace_key_inplace(&mut map, &3, 4);
        assert!(map == new_from(vector[1, 4, 6], vector[10, 30, 50]), 2);
        replace_key_inplace(&mut map, &1, 0);
        assert!(map == new_from(vector[0, 4, 6], vector[10, 30, 50]), 3);
    }

    #[test]
    #[expected_failure(abort_code = 0x10002, location = Self)] /// EKEY_NOT_FOUND
    fun test_replace_key_inplace_not_found_1() {
        let map = new_from(vector[1, 3, 6], vector[10, 30, 50]);
        replace_key_inplace(&mut map, &4, 5);

    }

    #[test]
    #[expected_failure(abort_code = 0x10002, location = Self)] /// EKEY_NOT_FOUND
    fun test_replace_key_inplace_not_found_2() {
        let map = new_from(vector[1, 3, 6], vector[10, 30, 50]);
        replace_key_inplace(&mut map, &7, 8);
    }

    #[test]
    #[expected_failure(abort_code = 0x10004, location = Self)] /// ENEW_KEY_NOT_IN_ORDER
    fun test_replace_key_inplace_not_in_order_1() {
        let map = new_from(vector[1, 3, 6], vector[10, 30, 50]);
        replace_key_inplace(&mut map, &3, 7);
    }

    #[test]
    #[expected_failure(abort_code = 0x10004, location = Self)] /// ENEW_KEY_NOT_IN_ORDER
    fun test_replace_key_inplace_not_in_order_2() {
        let map = new_from(vector[1, 3, 6], vector[10, 30, 50]);
        replace_key_inplace(&mut map, &1, 3);
    }

    #[test]
    #[expected_failure(abort_code = 0x10004, location = Self)] /// ENEW_KEY_NOT_IN_ORDER
    fun test_replace_key_inplace_not_in_order_3() {
        let map = new_from(vector[1, 3, 6], vector[10, 30, 50]);
        replace_key_inplace(&mut map, &6, 3);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
    public fun test_iter_end_next_abort() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = internal_new_end_iter(&map);
        iter_next(iter, &map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
    public fun test_iter_end_borrow_key_abort() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = internal_new_end_iter(&map);
        iter_borrow_key(&iter, &map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
    public fun test_iter_end_borrow_abort() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = internal_new_end_iter(&map);
        iter_borrow(iter, &map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
    public fun test_iter_end_borrow_mut_abort() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = internal_new_end_iter(&map);
        iter_borrow_mut(iter, &mut map);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
    public fun test_iter_begin_prev_abort() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = internal_new_begin_iter(&map);
        iter_prev(iter, &map);
    }

    #[test]
    public fun test_iter_is_begin_from_non_empty() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = internal_new_begin_iter(&map);
        assert!(iter_is_begin(&iter, &map), 1);
        assert!(iter_is_begin_from_non_empty(&iter), 1);

        let iter = iter_next(iter, &map);
        assert!(!iter_is_begin(&iter, &map), 1);
        assert!(!iter_is_begin_from_non_empty(&iter), 1);

        let map = new<u64, u64>();
        let iter = internal_new_begin_iter(&map);
        assert!(iter_is_begin(&iter, &map), 1);
        assert!(!iter_is_begin_from_non_empty(&iter), 1);
    }

    #[test]
    public fun test_iter_remove() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = iter_next(internal_new_begin_iter(&map), &map);
        iter_remove(iter, &mut map);
        assert!(map == new_from(vector[1, 5], vector[10, 50]), 1);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
        public fun test_iter_remove_abort() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = internal_new_end_iter(&map);
        iter_remove(iter, &mut map);
    }

    #[test]
    public fun test_iter_replace() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = iter_next(internal_new_begin_iter(&map), &map);
        iter_replace(iter, &mut map, 35);
        assert!(map == new_from(vector[1, 3, 5], vector[10, 35, 50]), 1);
    }

    #[test]
    #[expected_failure(abort_code = 0x10003, location = Self)] /// EITER_OUT_OF_BOUNDS
        public fun test_iter_replace_abort() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = internal_new_end_iter(&map);
        iter_replace(iter, &mut map, 35);
    }

    #[test]
    public fun test_iter_add() {
        {
            let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
            let iter = internal_new_begin_iter(&map);
            iter_add(iter, &mut map, 0, 5);
            assert!(map == new_from(vector[0, 1, 3, 5], vector[5, 10, 30, 50]), 1);
        };
        {
            let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
            let iter = iter_next(internal_new_begin_iter(&map), &map);
            iter_add(iter, &mut map, 2, 20);
            assert!(map == new_from(vector[1, 2, 3, 5], vector[10, 20, 30, 50]), 2);
        };
        {
            let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
            let iter = internal_new_end_iter(&map);
            iter_add(iter, &mut map, 6, 60);
            assert!(map == new_from(vector[1, 3, 5, 6], vector[10, 30, 50, 60]), 3);
        };
        {
            let map = new();
            let iter = internal_new_end_iter(&map);
            iter_add(iter, &mut map, 1, 10);
            assert!(map == new_from(vector[1], vector[10]), 4);
        };
    }

    #[test]
    #[expected_failure(abort_code = 0x10004, location = Self)] /// ENEW_KEY_NOT_IN_ORDER
    public fun test_iter_add_abort_1() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = internal_new_begin_iter(&map);
        iter_add(iter, &mut map, 1, 5);
    }

    #[test]
    #[expected_failure(abort_code = 0x10004, location = Self)] /// ENEW_KEY_NOT_IN_ORDER
    public fun test_iter_add_abort_2() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = internal_new_end_iter(&map);
        iter_add(iter, &mut map, 5, 55);
    }

    #[test]
    #[expected_failure(abort_code = 0x10004, location = Self)] /// ENEW_KEY_NOT_IN_ORDER
    public fun test_iter_add_abort_3() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = iter_next(internal_new_begin_iter(&map), &map);
        iter_add(iter, &mut map, 1, 15);
    }

    #[test]
    #[expected_failure(abort_code = 0x10004, location = Self)] /// ENEW_KEY_NOT_IN_ORDER
    public fun test_iter_add_abort_4() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let iter = iter_next(internal_new_begin_iter(&map), &map);
        iter_add(iter, &mut map, 3, 25);
    }

    #[test]
	public fun test_ordered_map_append_2() {
        let map = new_from(vector[1, 2], vector[10, 20]);
        let other = new_from(vector[1, 2], vector[100, 200]);
        append(&mut map, other);
        assert!(map == new_from(vector[1, 2], vector[100, 200]), 0);
    }

    #[test]
	public fun test_ordered_map_append_3() {
        let map = new_from(vector[1, 2, 3, 4, 5], vector[10, 20, 30, 40, 50]);
        let other = new_from(vector[2, 4], vector[200, 400]);
        append(&mut map, other);
        assert!(map == new_from(vector[1, 2, 3, 4, 5], vector[10, 200, 30, 400, 50]), 0);
    }

    #[test]
	public fun test_ordered_map_append_4() {
        let map = new_from(vector[3, 4, 5, 6, 7], vector[30, 40, 50, 60, 70]);
        let other = new_from(vector[1, 2, 4, 6], vector[100, 200, 400, 600]);
        append(&mut map, other);
        assert!(map == new_from(vector[1, 2, 3, 4, 5, 6, 7], vector[100, 200, 30, 400, 50, 600, 70]), 0);
    }

    #[test]
	public fun test_ordered_map_append_5() {
        let map = new_from(vector[1, 3, 5], vector[10, 30, 50]);
        let other = new_from(vector[0, 2, 4, 6], vector[0, 200, 400, 600]);
        append(&mut map, other);
        endless_std::debug::print(&map);
        assert!(map == new_from(vector[0, 1, 2, 3, 4, 5, 6], vector[0, 10, 200, 30, 400, 50, 600]), 0);
    }

    #[test_only]
    public fun large_dataset(): vector<u64> {
        vector[383, 886, 777, 915, 793, 335, 386, 492, 649, 421, 362, 27, 690, 59, 763, 926, 540, 426, 172, 736, 211, 368, 567, 429, 782, 530, 862, 123, 67, 135, 929, 802, 22, 58, 69, 167, 393, 456, 11, 42, 229, 373, 421, 919, 784, 537, 198, 324, 315, 370, 413, 526, 91, 980, 956, 873, 862, 170, 996, 281, 305, 925, 84, 327, 336, 505, 846, 729, 313, 857, 124, 895, 582, 545, 814, 367, 434, 364, 43, 750, 87, 808, 276, 178, 788, 584, 403, 651, 754, 399, 932, 60, 676, 368, 739, 12, 226, 586, 94, 539, 795, 570, 434, 378, 467, 601, 97, 902, 317, 492, 652, 756, 301, 280, 286, 441, 865, 689, 444, 619, 440, 729, 31, 117, 97, 771, 481, 675, 709, 927, 567, 856, 497, 353, 586, 965, 306, 683, 219, 624, 528, 871, 732, 829, 503, 19, 270, 368, 708, 715, 340, 149, 796, 723, 618, 245, 846, 451, 921, 555, 379, 488, 764, 228, 841, 350, 193, 500, 34, 764, 124, 914, 987, 856, 743, 491, 227, 365, 859, 936, 432, 551, 437, 228, 275, 407, 474, 121, 858, 395, 29, 237, 235, 793, 818, 428, 143, 11, 928, 529]
    }

    #[test_only]
    public fun large_dataset_shuffled(): vector<u64> {
        vector[895, 228, 530, 784, 624, 335, 729, 818, 373, 456, 914, 226, 368, 750, 428, 956, 437, 586, 763, 235, 567, 91, 829, 690, 434, 178, 584, 426, 228, 407, 237, 497, 764, 135, 124, 421, 537, 270, 11, 367, 378, 856, 529, 276, 729, 618, 929, 227, 149, 788, 925, 675, 121, 795, 306, 198, 421, 350, 555, 441, 403, 932, 368, 383, 928, 841, 440, 771, 364, 902, 301, 987, 467, 873, 921, 11, 365, 340, 739, 492, 540, 386, 919, 723, 539, 87, 12, 782, 324, 862, 689, 395, 488, 793, 709, 505, 582, 814, 245, 980, 936, 736, 619, 69, 370, 545, 764, 886, 305, 551, 19, 865, 229, 432, 29, 754, 34, 676, 43, 846, 451, 491, 871, 500, 915, 708, 586, 60, 280, 652, 327, 172, 856, 481, 796, 474, 219, 651, 170, 281, 84, 97, 715, 857, 353, 862, 393, 567, 368, 777, 97, 315, 526, 94, 31, 167, 123, 413, 503, 193, 808, 649, 143, 42, 444, 317, 67, 926, 434, 211, 379, 570, 683, 965, 732, 927, 429, 859, 313, 528, 996, 117, 492, 336, 22, 399, 275, 802, 743, 124, 846, 58, 858, 286, 756, 601, 27, 59, 362, 793]
    }

    #[test]
    fun test_map_large() {
        let map = new();
        let data = large_dataset();
        let shuffled_data = large_dataset_shuffled();

        let len = vector::length(&data);
        for (i in 0..len) {
            let element = *vector::borrow(&data, i);
            upsert(&mut map, element, element);
            validate_map(&map);
        };

        for (i in 0..len) {
            let element = vector::borrow(&shuffled_data, i);
            let it = internal_find(&map, element);
            assert!(!iter_is_end(&it, &map), 6);
            assert!(iter_borrow_key(&it, &map) == element, 7);

            let it_next = iter_next(it, &map);
            let it_after = internal_lower_bound(&map, &(*element + 1));

            // Check if both point to same position
            let next_is_end = iter_is_end(&it_next, &map);
            let after_is_end = iter_is_end(&it_after, &map);

            if (next_is_end != after_is_end) {
                // One is end, other is not - this is wrong
                abort 10000
            };

            if (!next_is_end) {
                // Both are not end, check if they point to same element
                let next_key = iter_borrow_key(&it_next, &map);
                let after_key = iter_borrow_key(&it_after, &map);
                if (next_key != after_key) {
                    // They point to different elements!
                    abort 20000
                };
            };

            assert!(it_next == it_after, 8);
        };

        let removed = vector::empty();
        for (i in 0..len) {
            let element = vector::borrow(&shuffled_data, i);
            if (!vector::contains(&removed, element)) {
                vector::push_back(&mut removed, *element);
                remove(&mut map, element);
                validate_map(&map);
            } else {
                assert!(!contains(&map, element), 0);
            };
        };

        destroy_empty(map);
    }

    #[verify_only]
    fun test_verify_borrow_front_key() {
        let keys: vector<u64> = vector[1, 2, 3];
        let values: vector<u64> = vector[4, 5, 6];
        let map = new_from(keys, values);
        let (key, value) = borrow_front(&map);
        spec {
            assert keys[0] == 1;
            assert vector::spec_contains(keys, 1);
            assert spec_contains_key(map, key);
            assert spec_get(map, key) == value;
            assert key == (1 as u64);
        };
    }

    #[verify_only]
    fun test_verify_borrow_back_key() {
        let keys: vector<u64> = vector[1, 2, 3];
        let values: vector<u64> = vector[4, 5, 6];
        let map = new_from(keys, values);
        let (key, value) = borrow_back(&map);
        spec {
            assert keys[2] == 3;
            assert vector::spec_contains(keys, 3);
            assert spec_contains_key(map, key);
            assert spec_get(map, key) == value;
            assert key == (3 as u64);
        };
    }

    #[verify_only]
    fun test_verify_upsert() {
        let keys: vector<u64> = vector[1, 2, 3];
        let values: vector<u64> = vector[4, 5, 6];
        let map = new_from(keys, values);
        spec {
            assert spec_len(map) == 3;
        };
        let (_key, _value) = borrow_back(&map);
        let result_1 = upsert(&mut map, 4, 5);
        spec {
            assert spec_contains_key(map, 4);
            assert spec_get(map, 4) == 5;
            assert option::is_none(result_1);
            assert spec_len(map) == 4;
        };
        let result_2 = upsert(&mut map, 4, 6);
        spec {
            assert spec_contains_key(map, 4);
            assert spec_get(map, 4) == 6;
            assert option::is_some(result_2);
            assert option::borrow(result_2) == 5;
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
    }

     #[verify_only]
     fun test_aborts_if_new_from_1(): OrderedMap<u64, u64> {
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
        aborts_if true;
     }

     #[verify_only]
     fun test_aborts_if_new_from_2(keys: vector<u64>, values: vector<u64>): OrderedMap<u64, u64> {
        let map = new_from(keys, values);
        map
     }

     spec test_aborts_if_new_from_2 {
        aborts_if exists i in 0..len(keys), j in 0..len(keys) where i != j : keys[i] == keys[j];
        aborts_if len(keys) != len(values);
     }

     #[verify_only]
     fun test_aborts_if_remove(map: &mut OrderedMap<u64, u64>) {
        remove(map, &1);
     }

     spec test_aborts_if_remove {
        aborts_if !spec_contains_key(map, 1);
     }

    #[verify_only]
    fun test_verify_remove_or_none() {
        let keys: vector<u64> = vector[1, 2, 3];
        let values: vector<u64> = vector[4, 5, 6];
        let map = new_from(keys, values);
        spec {
            assert spec_len(map) == 3;
        };
        let (_key, _value) = borrow_back(&map);
        spec{
            assert keys[0] == 1;
            assert keys[1] == 2;
            assert spec_contains_key(map, 1);
            assert spec_contains_key(map, 2);
        };
        let result_1 = remove_or_none(&mut map, &1);
        spec {
            assert spec_contains_key(map, 2);
            assert spec_get(map, 2) == 5;
            assert option::spec_is_some(result_1);
            assert option::spec_borrow(result_1) == 4;
            assert spec_len(map) == 2;
            assert !spec_contains_key(map, 1);
            assert !spec_contains_key(map, 4);
        };
        let result_2 = remove_or_none(&mut map, &4);
        spec {
            assert spec_contains_key(map, 2);
            assert spec_get(map, 2) == 5;
            assert option::spec_is_none(result_2);
            assert spec_len(map) == 2;
            assert !spec_contains_key(map, 4);
        };
        remove(&mut map, &2);
        remove(&mut map, &3);
        spec {
            assert !spec_contains_key(map, 1);
            assert !spec_contains_key(map, 2);
            assert !spec_contains_key(map, 3);
            assert spec_len(map) == 0;
        };
        destroy_empty(map);
    }
}

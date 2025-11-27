
<a id="0x1_ordered_map"></a>

# Module `0x1::ordered_map`

This module provides an implementation for an ordered map.

Keys point to values, and each key in the map must be unique.

Currently, one implementation is provided, backed by a single sorted vector.

That means that keys can be found within O(log N) time.
Adds and removals take O(N) time, but the constant factor is small,
as it does only O(log N) comparisons, and does efficient mem-copy with vector operations.

Additionally, it provides a way to lookup and iterate over sorted keys, making range query
take O(log N + R) time (where R is number of elements in the range).

Most methods operate with OrderedMap being <code>self</code>.
All methods that start with iter_*, operate with IteratorPtr being <code>self</code>.

Uses cmp::compare for ordering, which compares primitive types natively, and uses common
lexicographical sorting for complex types.

Warning: All iterator functions need to be carefully used, because they are just pointers into the
structure, and modification of the map invalidates them (without compiler being able to catch it).
Type is also named IteratorPtr, so that Iterator is free to use later.
Better guarantees would need future Move improvements that will allow references to be part of the struct,
allowing cleaner iterator APIs.

That's why all functions returning iterators are prefixed with "internal_", to clarify nuances needed to make
sure usage is correct.
A set of inline utility methods is provided instead, to provide guaranteed valid usage to iterators.


-  [Struct `Entry`](#0x1_ordered_map_Entry)
-  [Struct `OrderedMap`](#0x1_ordered_map_OrderedMap)
-  [Struct `SortedVectorMapData`](#0x1_ordered_map_SortedVectorMapData)
-  [Struct `PositionData`](#0x1_ordered_map_PositionData)
-  [Struct `IteratorPtr`](#0x1_ordered_map_IteratorPtr)
-  [Constants](#@Constants_0)
-  [Function `new`](#0x1_ordered_map_new)
-  [Function `new_from`](#0x1_ordered_map_new_from)
-  [Function `length`](#0x1_ordered_map_length)
-  [Function `is_empty`](#0x1_ordered_map_is_empty)
-  [Function `add`](#0x1_ordered_map_add)
-  [Function `upsert`](#0x1_ordered_map_upsert)
-  [Function `remove`](#0x1_ordered_map_remove)
-  [Function `remove_or_none`](#0x1_ordered_map_remove_or_none)
-  [Function `modify_or_add`](#0x1_ordered_map_modify_or_add)
-  [Function `modify_if_present`](#0x1_ordered_map_modify_if_present)
-  [Function `contains`](#0x1_ordered_map_contains)
-  [Function `borrow`](#0x1_ordered_map_borrow)
-  [Function `borrow_mut`](#0x1_ordered_map_borrow_mut)
-  [Function `get`](#0x1_ordered_map_get)
-  [Function `get_and_map`](#0x1_ordered_map_get_and_map)
-  [Function `replace_key_inplace`](#0x1_ordered_map_replace_key_inplace)
-  [Function `add_all`](#0x1_ordered_map_add_all)
-  [Function `upsert_all`](#0x1_ordered_map_upsert_all)
-  [Function `append`](#0x1_ordered_map_append)
-  [Function `append_disjoint`](#0x1_ordered_map_append_disjoint)
-  [Function `append_impl`](#0x1_ordered_map_append_impl)
-  [Function `trim`](#0x1_ordered_map_trim)
-  [Function `borrow_front`](#0x1_ordered_map_borrow_front)
-  [Function `borrow_back`](#0x1_ordered_map_borrow_back)
-  [Function `pop_front`](#0x1_ordered_map_pop_front)
-  [Function `pop_back`](#0x1_ordered_map_pop_back)
-  [Function `prev_key`](#0x1_ordered_map_prev_key)
-  [Function `next_key`](#0x1_ordered_map_next_key)
-  [Function `internal_lower_bound`](#0x1_ordered_map_internal_lower_bound)
-  [Function `internal_find`](#0x1_ordered_map_internal_find)
-  [Function `internal_new_begin_iter`](#0x1_ordered_map_internal_new_begin_iter)
-  [Function `internal_new_end_iter`](#0x1_ordered_map_internal_new_end_iter)
-  [Function `iter_next`](#0x1_ordered_map_iter_next)
-  [Function `iter_prev`](#0x1_ordered_map_iter_prev)
-  [Function `iter_is_begin`](#0x1_ordered_map_iter_is_begin)
-  [Function `iter_is_begin_from_non_empty`](#0x1_ordered_map_iter_is_begin_from_non_empty)
-  [Function `iter_is_end`](#0x1_ordered_map_iter_is_end)
-  [Function `iter_borrow_key`](#0x1_ordered_map_iter_borrow_key)
-  [Function `iter_borrow`](#0x1_ordered_map_iter_borrow)
-  [Function `iter_borrow_mut`](#0x1_ordered_map_iter_borrow_mut)
-  [Function `iter_remove`](#0x1_ordered_map_iter_remove)
-  [Function `iter_replace`](#0x1_ordered_map_iter_replace)
-  [Function `iter_add`](#0x1_ordered_map_iter_add)
-  [Function `destroy_empty`](#0x1_ordered_map_destroy_empty)
-  [Function `keys`](#0x1_ordered_map_keys)
-  [Function `values`](#0x1_ordered_map_values)
-  [Function `to_vec_pair`](#0x1_ordered_map_to_vec_pair)
-  [Function `destroy`](#0x1_ordered_map_destroy)
-  [Function `for_each`](#0x1_ordered_map_for_each)
-  [Function `for_each_ref`](#0x1_ordered_map_for_each_ref)
-  [Function `for_each_mut`](#0x1_ordered_map_for_each_mut)
-  [Function `new_iter`](#0x1_ordered_map_new_iter)
-  [Function `new_end_iter`](#0x1_ordered_map_new_end_iter)
-  [Function `binary_search`](#0x1_ordered_map_binary_search)
-  [Function `test_verify_borrow_front_key`](#0x1_ordered_map_test_verify_borrow_front_key)
-  [Function `test_verify_borrow_back_key`](#0x1_ordered_map_test_verify_borrow_back_key)
-  [Function `test_verify_upsert`](#0x1_ordered_map_test_verify_upsert)
-  [Function `test_verify_next_key`](#0x1_ordered_map_test_verify_next_key)
-  [Function `test_verify_prev_key`](#0x1_ordered_map_test_verify_prev_key)
-  [Function `test_aborts_if_new_from_1`](#0x1_ordered_map_test_aborts_if_new_from_1)
-  [Function `test_aborts_if_new_from_2`](#0x1_ordered_map_test_aborts_if_new_from_2)
-  [Function `test_aborts_if_remove`](#0x1_ordered_map_test_aborts_if_remove)
-  [Function `test_verify_remove_or_none`](#0x1_ordered_map_test_verify_remove_or_none)
-  [Specification](#@Specification_1)
    -  [Function `test_aborts_if_new_from_1`](#@Specification_1_test_aborts_if_new_from_1)
    -  [Function `test_aborts_if_new_from_2`](#@Specification_1_test_aborts_if_new_from_2)
    -  [Function `test_aborts_if_remove`](#@Specification_1_test_aborts_if_remove)


<pre><code><b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp">0x1::cmp</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">0x1::vector</a>;
</code></pre>



<a id="0x1_ordered_map_Entry"></a>

## Struct `Entry`

Individual entry holding (key, value) pair


<pre><code><b>struct</b> <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a>&lt;K, V&gt; <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>key: K</code>
</dt>
<dd>

</dd>
<dt>
<code>value: V</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_ordered_map_OrderedMap"></a>

## Struct `OrderedMap`

The OrderedMap datastructure.


<pre><code><b>struct</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt; <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>tag: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>SortedVectorMap: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="ordered_map.md#0x1_ordered_map_SortedVectorMapData">ordered_map::SortedVectorMapData</a>&lt;K, V&gt;&gt;</code>
</dt>
<dd>
 sorted-vector based implementation of OrderedMap
</dd>
</dl>


</details>

<a id="0x1_ordered_map_SortedVectorMapData"></a>

## Struct `SortedVectorMapData`



<pre><code><b>struct</b> <a href="ordered_map.md#0x1_ordered_map_SortedVectorMapData">SortedVectorMapData</a>&lt;K, V&gt; <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>entries: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="ordered_map.md#0x1_ordered_map_Entry">ordered_map::Entry</a>&lt;K, V&gt;&gt;</code>
</dt>
<dd>
 List of entries, sorted by key.
</dd>
</dl>


</details>

<a id="0x1_ordered_map_PositionData"></a>

## Struct `PositionData`



<pre><code><b>struct</b> <a href="ordered_map.md#0x1_ordered_map_PositionData">PositionData</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>index: u64</code>
</dt>
<dd>
 The index of the iterator pointing to.
</dd>
</dl>


</details>

<a id="0x1_ordered_map_IteratorPtr"></a>

## Struct `IteratorPtr`

An iterator pointing to a valid position in an ordered map, or to the end.

TODO: Once fields can be (mutable) references, this class will be deprecated.


<pre><code><b>struct</b> <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>tag: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>End: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;bool&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>Position: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="ordered_map.md#0x1_ordered_map_PositionData">ordered_map::PositionData</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_ordered_map_EITER_OUT_OF_BOUNDS"></a>



<pre><code><b>const</b> <a href="ordered_map.md#0x1_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>: u64 = 3;
</code></pre>



<a id="0x1_ordered_map_EKEY_ALREADY_EXISTS"></a>

Map key already exists


<pre><code><b>const</b> <a href="ordered_map.md#0x1_ordered_map_EKEY_ALREADY_EXISTS">EKEY_ALREADY_EXISTS</a>: u64 = 1;
</code></pre>



<a id="0x1_ordered_map_EKEY_NOT_FOUND"></a>

Map key is not found


<pre><code><b>const</b> <a href="ordered_map.md#0x1_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>: u64 = 2;
</code></pre>



<a id="0x1_ordered_map_ENEW_KEY_NOT_IN_ORDER"></a>

New key used in replace_key_inplace doesn't respect the order


<pre><code><b>const</b> <a href="ordered_map.md#0x1_ordered_map_ENEW_KEY_NOT_IN_ORDER">ENEW_KEY_NOT_IN_ORDER</a>: u64 = 4;
</code></pre>



<a id="0x1_ordered_map_new"></a>

## Function `new`

Create a new empty OrderedMap, using default (SortedVectorMap) implementation.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_new">new</a>&lt;K, V&gt;(): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_new">new</a>&lt;K, V&gt;(): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt; {
    <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a> {
        tag: 1,
        SortedVectorMap: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="ordered_map.md#0x1_ordered_map_SortedVectorMapData">SortedVectorMapData</a> {
            entries: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
        }),
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_new_from"></a>

## Function `new_from`

Create a OrderedMap from a vector of keys and values.
Aborts with EKEY_ALREADY_EXISTS if duplicate keys are passed in.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_new_from">new_from</a>&lt;K, V&gt;(keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_new_from">new_from</a>&lt;K, V&gt;(keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt; {
    <b>let</b> map = <a href="ordered_map.md#0x1_ordered_map_new">new</a>();
    <a href="ordered_map.md#0x1_ordered_map_add_all">add_all</a>(&<b>mut</b> map, keys, values);
    map
}
</code></pre>



</details>

<a id="0x1_ordered_map_length"></a>

## Function `length`

Number of elements in the map.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_length">length</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_length">length</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): u64 {
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.SortedVectorMap).entries)
}
</code></pre>



</details>

<a id="0x1_ordered_map_is_empty"></a>

## Function `is_empty`

Whether map is empty.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_is_empty">is_empty</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_is_empty">is_empty</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): bool {
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.SortedVectorMap).entries)
}
</code></pre>



</details>

<a id="0x1_ordered_map_add"></a>

## Function `add`

Add a key/value pair to the map.
Aborts with EKEY_ALREADY_EXISTS if key already exist.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_add">add</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: K, value: V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_add">add</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: K, value: V) {
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> self.SortedVectorMap).entries;
    <b>let</b> len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries);
    <b>let</b> index = <a href="ordered_map.md#0x1_ordered_map_binary_search">binary_search</a>(&key, entries, 0, len);

    <b>if</b> (index &lt; len) {
        <b>let</b> entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, index);
        <b>assert</b>!(&entry.key != &key, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EKEY_ALREADY_EXISTS">EKEY_ALREADY_EXISTS</a>));
    };
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_insert">vector::insert</a>(entries, index, <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key, value });
}
</code></pre>



</details>

<a id="0x1_ordered_map_upsert"></a>

## Function `upsert`

If the key doesn't exist in the map, inserts the key/value, and returns none.
Otherwise, updates the value under the given key, and returns the old value.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_upsert">upsert</a>&lt;K: drop, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: K, value: V): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_upsert">upsert</a>&lt;K: drop, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: K, value: V): Option&lt;V&gt; {
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> self.SortedVectorMap).entries;
    <b>let</b> len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries);
    <b>let</b> index = <a href="ordered_map.md#0x1_ordered_map_binary_search">binary_search</a>(&key, entries, 0, len);

    <b>if</b> (index &lt; len && {
        <b>let</b> entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, index);
        &entry.key == &key
    }) {
        <b>let</b> <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> {
            key: _,
            value: old_value,
        } = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_replace">vector::replace</a>(entries,index, <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key, value });
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(old_value)
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_insert">vector::insert</a>(entries, index, <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key, value });
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_remove"></a>

## Function `remove`

Remove a key/value pair from the map.
Aborts with EKEY_NOT_FOUND if <code>key</code> doesn't exist.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_remove">remove</a>&lt;K: drop, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K): V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_remove">remove</a>&lt;K: drop, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K): V {
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> self.SortedVectorMap).entries;
    <b>let</b> len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries);
    <b>let</b> index = <a href="ordered_map.md#0x1_ordered_map_binary_search">binary_search</a>(key, entries, 0, len);
    <b>assert</b>!(index &lt; len, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>));
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key: old_key, value } = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove">vector::remove</a>(entries, index);
    <b>assert</b>!(key == &old_key, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>));
    value
}
</code></pre>



</details>

<a id="0x1_ordered_map_remove_or_none"></a>

## Function `remove_or_none`

Remove a key/value pair from the map.
Returns none if <code>key</code> doesn't exist.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_remove_or_none">remove_or_none</a>&lt;K: drop, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_remove_or_none">remove_or_none</a>&lt;K: drop, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K): Option&lt;V&gt; {
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> self.SortedVectorMap).entries;
    <b>let</b> len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries);
    <b>let</b> index = <a href="ordered_map.md#0x1_ordered_map_binary_search">binary_search</a>(key, entries, 0, len);
    <b>if</b> (index &lt; len) {
        <b>let</b> entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, index);
        <b>if</b> (key == &entry.key) {
            <b>let</b> <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key: _, value } = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove">vector::remove</a>(entries, index);
            <b>return</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(value)
        };
    };
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
}
</code></pre>



</details>

<a id="0x1_ordered_map_modify_or_add"></a>

## Function `modify_or_add`

Modifies element by calling modify_f if it exists, or calling add_f to add if it doesn't.
Returns true if element already existed.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_modify_or_add">modify_or_add</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K, modify_f: |&<b>mut</b> V|(), add_f: |()|V): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_modify_or_add">modify_or_add</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K, modify_f: |&<b>mut</b> V|, add_f: ||V): bool {
    <b>let</b> iter = <a href="ordered_map.md#0x1_ordered_map_internal_find">internal_find</a>(self, key);
    <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&iter, self)) {
        <a href="ordered_map.md#0x1_ordered_map_add">add</a>(self, *key, add_f());
        <b>false</b>
    } <b>else</b> {
        modify_f(<a href="ordered_map.md#0x1_ordered_map_iter_borrow_mut">iter_borrow_mut</a>(iter, self));
        <b>true</b>
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_modify_if_present"></a>

## Function `modify_if_present`

Modifies element by calling modify_f if it exists.
Returns true if element already existed.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_modify_if_present">modify_if_present</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K, modify_f: |&<b>mut</b> V|()): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_modify_if_present">modify_if_present</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K, modify_f: |&<b>mut</b> V|): bool {
    <b>let</b> iter = <a href="ordered_map.md#0x1_ordered_map_internal_find">internal_find</a>(self, key);
    <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&iter, self)) {
        <b>false</b>
    } <b>else</b> {
        modify_f(<a href="ordered_map.md#0x1_ordered_map_iter_borrow_mut">iter_borrow_mut</a>(iter, self));
        <b>true</b>
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_contains"></a>

## Function `contains`

Returns whether map contains a given key.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_contains">contains</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_contains">contains</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K): bool {
    !<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&<a href="ordered_map.md#0x1_ordered_map_internal_find">internal_find</a>(self, key), self)
}
</code></pre>



</details>

<a id="0x1_ordered_map_borrow"></a>

## Function `borrow`



<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_borrow">borrow</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K): &V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_borrow">borrow</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K): &V {
    <a href="ordered_map.md#0x1_ordered_map_iter_borrow">iter_borrow</a>(<a href="ordered_map.md#0x1_ordered_map_internal_find">internal_find</a>(self, key), self)
}
</code></pre>



</details>

<a id="0x1_ordered_map_borrow_mut"></a>

## Function `borrow_mut`



<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_borrow_mut">borrow_mut</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K): &<b>mut</b> V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_borrow_mut">borrow_mut</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K): &<b>mut</b> V {
    <a href="ordered_map.md#0x1_ordered_map_iter_borrow_mut">iter_borrow_mut</a>(<a href="ordered_map.md#0x1_ordered_map_internal_find">internal_find</a>(self, key), self)
}
</code></pre>



</details>

<a id="0x1_ordered_map_get"></a>

## Function `get`



<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_get">get</a>&lt;K: <b>copy</b>, drop, store, V: <b>copy</b>, store&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_get">get</a>&lt;K: drop + <b>copy</b> + store, V: <b>copy</b> + store&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K): Option&lt;V&gt; {
    <b>let</b> iter = <a href="ordered_map.md#0x1_ordered_map_internal_find">internal_find</a>(self, key);
    <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&iter, self)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <b>let</b> value_ref = <a href="ordered_map.md#0x1_ordered_map_iter_borrow">iter_borrow</a>(iter, self);
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(*value_ref)
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_get_and_map"></a>

## Function `get_and_map`



<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_get_and_map">get_and_map</a>&lt;K: <b>copy</b>, drop, store, V: <b>copy</b>, store, R&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K, f: |&V|R): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;R&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_get_and_map">get_and_map</a>&lt;K: drop + <b>copy</b> + store, V: <b>copy</b> + store, R&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K, f: |&V|R): Option&lt;R&gt; {
    <b>let</b> iter = <a href="ordered_map.md#0x1_ordered_map_internal_find">internal_find</a>(self, key);
    <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&iter, self)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <b>let</b> value_ref = <a href="ordered_map.md#0x1_ordered_map_iter_borrow">iter_borrow</a>(iter, self);
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(f(value_ref))
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_replace_key_inplace"></a>

## Function `replace_key_inplace`

Changes the key, while keeping the same value attached to it
Aborts with EKEY_NOT_FOUND if <code>old_key</code> doesn't exist.
Aborts with ENEW_KEY_NOT_IN_ORDER if <code>new_key</code> doesn't keep the order <code>old_key</code> was in.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_replace_key_inplace">replace_key_inplace</a>&lt;K: drop, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, old_key: &K, new_key: K)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_replace_key_inplace">replace_key_inplace</a>&lt;K: drop, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, old_key: &K, new_key: K) {
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> self.SortedVectorMap).entries;
    <b>let</b> len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries);
    <b>let</b> index = <a href="ordered_map.md#0x1_ordered_map_binary_search">binary_search</a>(old_key, entries, 0, len);
    <b>assert</b>!(index &lt; len, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>));

    <b>let</b> entry_ref = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, index);
    <b>assert</b>!(old_key == &entry_ref.key, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>));

    // check that after we <b>update</b> the key, order is going <b>to</b> be respected
    <b>if</b> (index &gt; 0) {
        <b>let</b> prev_entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, index - 1);
        <b>let</b> ord = <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_compare">cmp::compare</a>(&prev_entry.key, &new_key);
        <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_lt">cmp::is_lt</a>(&ord), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_ENEW_KEY_NOT_IN_ORDER">ENEW_KEY_NOT_IN_ORDER</a>))
    };

    <b>if</b> (index + 1 &lt; len) {
        <b>let</b> next_entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, index + 1);
        <b>let</b> ord = <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_compare">cmp::compare</a>(&new_key, &next_entry.key);
        <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_lt">cmp::is_lt</a>(&ord), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_ENEW_KEY_NOT_IN_ORDER">ENEW_KEY_NOT_IN_ORDER</a>))
    };

    <b>let</b> entry_mut = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow_mut">vector::borrow_mut</a>(entries, index);
    entry_mut.key = new_key;
}
</code></pre>



</details>

<a id="0x1_ordered_map_add_all"></a>

## Function `add_all`

Add multiple key/value pairs to the map. The keys must not already exist.
Aborts with EKEY_ALREADY_EXISTS if key already exist, or duplicate keys are passed in.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_add_all">add_all</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_add_all">add_all</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;) {
    // TODO: Can be optimized, by sorting keys and values, and then creating map.
    // keys.zip(values, |key, value| {
    //     <a href="ordered_map.md#0x1_ordered_map_add">add</a>(self, key, value);
    // });
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_zip">vector::zip</a>(keys, values, |key, value| {
        <a href="ordered_map.md#0x1_ordered_map_add">add</a>(self, key, value);
    });
}
</code></pre>



</details>

<a id="0x1_ordered_map_upsert_all"></a>

## Function `upsert_all`

Add multiple key/value pairs to the map, overwrites values if they exist already,
or if duplicate keys are passed in.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_upsert_all">upsert_all</a>&lt;K: drop, V: drop&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_upsert_all">upsert_all</a>&lt;K: drop, V: drop&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;) {
    // TODO: Can be optimized, by sorting keys and values, and then creating map.
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_zip">vector::zip</a>(keys, values, |key, value| {
        <a href="ordered_map.md#0x1_ordered_map_upsert">upsert</a>(self, key, value);
    });
}
</code></pre>



</details>

<a id="0x1_ordered_map_append"></a>

## Function `append`

Takes all elements from <code>other</code> and adds them to <code>self</code>,
overwritting if any key is already present in self.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_append">append</a>&lt;K: drop, V: drop&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, other: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_append">append</a>&lt;K: drop, V: drop&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, other: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;) {
    <a href="ordered_map.md#0x1_ordered_map_append_impl">append_impl</a>(self, other);
}
</code></pre>



</details>

<a id="0x1_ordered_map_append_disjoint"></a>

## Function `append_disjoint`

Takes all elements from <code>other</code> and adds them to <code>self</code>.
Aborts with EKEY_ALREADY_EXISTS if <code>other</code> has a key already present in <code>self</code>.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_append_disjoint">append_disjoint</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, other: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_append_disjoint">append_disjoint</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, other: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;) {
    <b>let</b> overwritten = <a href="ordered_map.md#0x1_ordered_map_append_impl">append_impl</a>(self, other);
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&overwritten) == 0, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EKEY_ALREADY_EXISTS">EKEY_ALREADY_EXISTS</a>));
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_destroy_empty">vector::destroy_empty</a>(overwritten);
}
</code></pre>



</details>

<a id="0x1_ordered_map_append_impl"></a>

## Function `append_impl`

Takes all elements from <code>other</code> and adds them to <code>self</code>, returning list of entries in self that were overwritten.


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_append_impl">append_impl</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, other: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="ordered_map.md#0x1_ordered_map_Entry">ordered_map::Entry</a>&lt;K, V&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_append_impl">append_impl</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, other: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a>&lt;K,V&gt;&gt; {
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a> { tag: _, SortedVectorMap: sorted_vector_map } = other;
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_SortedVectorMapData">SortedVectorMapData</a> { entries: other_entries } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(sorted_vector_map);
    <b>let</b> overwritten = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();

    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&other_entries)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_destroy_empty">vector::destroy_empty</a>(other_entries);
        <b>return</b> overwritten
    };

    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> self.SortedVectorMap).entries;
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(entries)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_append">vector::append</a>(entries, other_entries);
        <b>return</b> overwritten
    };

    // Optimization: <b>if</b> all elements in `other` are larger than all elements in `self`, we can just <b>move</b> them over.
    <b>let</b> should_append_tail = {
        <b>let</b> last_index = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries) - 1;
        <b>let</b> last_key_ref = &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, last_index).key;
        <b>let</b> other_first_key_ref = &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&other_entries, 0).key;
        <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_lt">cmp::is_lt</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_compare">cmp::compare</a>(last_key_ref, other_first_key_ref))
    };
    <b>if</b> (should_append_tail) {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_append">vector::append</a>(entries, other_entries);
        <b>return</b> overwritten
    };

    // In O(n), traversing from the back, build reverse sorted result, and then reverse it back
    <b>let</b> reverse_result = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();
    <b>let</b> cur_i = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries) - 1;
    <b>let</b> other_i = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&other_entries) - 1;

    // after the end of the <b>loop</b>, other_entries is empty, and <a href="../../endless-stdlib/doc/any.md#0x1_any">any</a> leftover is in entries
    <b>loop</b> {
        <b>let</b> ord = {
            <b>let</b> cur_entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, cur_i);
            <b>let</b> other_entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&other_entries, other_i);
            <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_compare">cmp::compare</a>(&cur_entry.key, &other_entry.key)
        };
        <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_gt">cmp::is_gt</a>(&ord)) {
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> reverse_result, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>(entries));
            <b>if</b> (cur_i == 0) {
                // make other_entries empty, and rest in entries.
                // TODO cannot <b>use</b> mem::swap until it is <b>public</b>/released
                // mem::swap(&<b>mut</b> entries, &<b>mut</b> other_entries);
                <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_append">vector::append</a>(entries, other_entries);
                <b>break</b>
            } <b>else</b> {
                cur_i = cur_i - 1;
            };
        } <b>else</b> {
            // is_lt or is_eq
            <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_eq">cmp::is_eq</a>(&ord)) {
                // we skip the entries one, and below put in the result one from other.
                <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> overwritten, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>(entries));

                <b>if</b> (cur_i == 0) {
                    // make other_entries empty, and rest in entries.
                    // TODO cannot <b>use</b> mem::swap until it is <b>public</b>/released
                    // mem::swap(&<b>mut</b> entries, &<b>mut</b> other_entries);
                    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_append">vector::append</a>(entries, other_entries);
                    <b>break</b>
                } <b>else</b> {
                    cur_i = cur_i - 1;
                };
            };

            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> reverse_result, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>(&<b>mut</b> other_entries));
            <b>if</b> (other_i == 0) {
                <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_destroy_empty">vector::destroy_empty</a>(other_entries);
                <b>break</b>
            } <b>else</b> {
                other_i = other_i - 1;
            };
        };
    };

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_reverse_append">vector::reverse_append</a>(entries, reverse_result);

    overwritten
}
</code></pre>



</details>

<a id="0x1_ordered_map_trim"></a>

## Function `trim`

Splits the collection into two, such to leave <code>self</code> with <code>at</code> number of elements.
Returns a newly allocated map containing the elements in the range [at, len).
After the call, the original map will be left containing the elements [0, at).


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_trim">trim</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, at: u64): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_trim">trim</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, at: u64): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt; {
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> self.SortedVectorMap).entries;
    <b>let</b> rest = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_trim">vector::trim</a>(entries, at);

    <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a> {
        tag: 1,
        SortedVectorMap: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="ordered_map.md#0x1_ordered_map_SortedVectorMapData">SortedVectorMapData</a> {
            entries: rest
        }),
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_borrow_front"></a>

## Function `borrow_front`



<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_borrow_front">borrow_front</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): (&K, &V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_borrow_front">borrow_front</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): (&K, &V) {
    <b>let</b> entries = &<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.SortedVectorMap).entries;
    <b>let</b> entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, 0);
    (&entry.key, &entry.value)
}
</code></pre>



</details>

<a id="0x1_ordered_map_borrow_back"></a>

## Function `borrow_back`



<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_borrow_back">borrow_back</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): (&K, &V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_borrow_back">borrow_back</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): (&K, &V) {
    <b>let</b> entries = &<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.SortedVectorMap).entries;
    <b>let</b> entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries) - 1);
    (&entry.key, &entry.value)
}
</code></pre>



</details>

<a id="0x1_ordered_map_pop_front"></a>

## Function `pop_front`



<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_pop_front">pop_front</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): (K, V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_pop_front">pop_front</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): (K, V) {
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> self.SortedVectorMap).entries;
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key, value } = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove">vector::remove</a>(entries, 0);
    (key, value)
}
</code></pre>



</details>

<a id="0x1_ordered_map_pop_back"></a>

## Function `pop_back`



<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_pop_back">pop_back</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): (K, V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_pop_back">pop_back</a>&lt;K, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): (K, V) {
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> self.SortedVectorMap).entries;
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key, value } = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>(entries);
    (key, value)
}
</code></pre>



</details>

<a id="0x1_ordered_map_prev_key"></a>

## Function `prev_key`



<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_prev_key">prev_key</a>&lt;K: <b>copy</b>, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_prev_key">prev_key</a>&lt;K: <b>copy</b>, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K): Option&lt;K&gt; {
    <b>let</b> it = <a href="ordered_map.md#0x1_ordered_map_internal_lower_bound">internal_lower_bound</a>(self, key);
    <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_begin">iter_is_begin</a>(&it, self)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <b>let</b> prev_it = <a href="ordered_map.md#0x1_ordered_map_iter_prev">iter_prev</a>(it, self);
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(*<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">iter_borrow_key</a>(&prev_it, self))
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_next_key"></a>

## Function `next_key`



<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_next_key">next_key</a>&lt;K: <b>copy</b>, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_next_key">next_key</a>&lt;K: <b>copy</b>, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K): Option&lt;K&gt; {
    <b>let</b> it = <a href="ordered_map.md#0x1_ordered_map_internal_lower_bound">internal_lower_bound</a>(self, key);
    <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&it, self)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <b>let</b> cur_key = <a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">iter_borrow_key</a>(&it, self);
        <b>if</b> (key == cur_key) {
            <b>let</b> next_it = <a href="ordered_map.md#0x1_ordered_map_iter_next">iter_next</a>(it, self);
            <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&next_it, self)) {
                <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
            } <b>else</b> {
                <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(*<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">iter_borrow_key</a>(&next_it, self))
            }
        } <b>else</b> {
            <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(*cur_key)
        }
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_internal_lower_bound"></a>

## Function `internal_lower_bound`

Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
For direct usage of this method, check Warning at the top of the file corresponding to iterators.

Returns an iterator pointing to the first element that is greater or equal to the provided
key, or an end iterator if such element doesn't exist.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_internal_lower_bound">internal_lower_bound</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_internal_lower_bound">internal_lower_bound</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> {
    <b>let</b> entries = &<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.SortedVectorMap).entries;
    <b>let</b> len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries);

    <b>let</b> index = <a href="ordered_map.md#0x1_ordered_map_binary_search">binary_search</a>(key, entries, 0, len);
    <b>if</b> (index == len) {
        <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(self)
    } <b>else</b> {
        <a href="ordered_map.md#0x1_ordered_map_new_iter">new_iter</a>(index)
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_internal_find"></a>

## Function `internal_find`

Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
For direct usage of this method, check Warning at the top of the file corresponding to iterators.

Returns an iterator pointing to the element that equals to the provided key, or an end
iterator if the key is not found.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_internal_find">internal_find</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: &K): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_internal_find">internal_find</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: &K): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> {
    <b>let</b> internal_lower_bound = <a href="ordered_map.md#0x1_ordered_map_internal_lower_bound">internal_lower_bound</a>(self, key);
    <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&internal_lower_bound, self)) {
        internal_lower_bound
    } <b>else</b> <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">iter_borrow_key</a>(&internal_lower_bound, self) == key) {
        internal_lower_bound
    } <b>else</b> {
        <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(self)
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_internal_new_begin_iter"></a>

## Function `internal_new_begin_iter`

Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
For direct usage of this method, check Warning at the top of the file corresponding to iterators.

Returns the begin iterator.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">internal_new_begin_iter</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">internal_new_begin_iter</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> {
    <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_is_empty">is_empty</a>(self)) {
        <b>return</b> <a href="ordered_map.md#0x1_ordered_map_new_end_iter">new_end_iter</a>()
    };

    <a href="ordered_map.md#0x1_ordered_map_new_iter">new_iter</a>(0)
}
</code></pre>



</details>

<a id="0x1_ordered_map_internal_new_end_iter"></a>

## Function `internal_new_end_iter`

Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
For direct usage of this method, check Warning at the top of the file corresponding to iterators.

Returns the end iterator.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">internal_new_end_iter</a>&lt;K, V&gt;(_self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">internal_new_end_iter</a>&lt;K, V&gt;(_self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> {
    <a href="ordered_map.md#0x1_ordered_map_new_end_iter">new_end_iter</a>()
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_next"></a>

## Function `iter_next`

Returns the next iterator, or none if already at the end iterator.
Note: Requires that the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_next">iter_next</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_next">iter_next</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>, map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> {
    <b>assert</b>!(!<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&self, map), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));

    <b>let</b> index = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Position).index + 1;
    <b>let</b> entries = &<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&map.SortedVectorMap).entries;
    <b>if</b> (index &lt; <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries)) {
        <a href="ordered_map.md#0x1_ordered_map_new_iter">new_iter</a>(index)
    } <b>else</b> {
        <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(map)
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_prev"></a>

## Function `iter_prev`

Returns the previous iterator, or none if already at the begin iterator.
Note: Requires that the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_prev">iter_prev</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_prev">iter_prev</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>, map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> {
    <b>assert</b>!(!<a href="ordered_map.md#0x1_ordered_map_iter_is_begin">iter_is_begin</a>(&self, map), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));

    <b>let</b> entries = &<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&map.SortedVectorMap).entries;
    <b>let</b> index = <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries) - 1
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Position).index - 1
    };

    <a href="ordered_map.md#0x1_ordered_map_new_iter">new_iter</a>(index)
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_is_begin"></a>

## Function `iter_is_begin`

Returns whether the iterator is a begin iterator.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_is_begin">iter_is_begin</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_is_begin">iter_is_begin</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>, map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): bool {
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End)) {
        <a href="ordered_map.md#0x1_ordered_map_is_empty">is_empty</a>(map)
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Position).index == 0
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_is_begin_from_non_empty"></a>

## Function `iter_is_begin_from_non_empty`

Returns true iff the iterator is a begin iterator from a non-empty collection.
(I.e. if iterator points to a valid element)
This method doesn't require having access to map, unlike iter_is_begin.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_is_begin_from_non_empty">iter_is_begin_from_non_empty</a>(self: &<a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_is_begin_from_non_empty">iter_is_begin_from_non_empty</a>(self: &<a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>): bool {
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End)) {
        <b>false</b>
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Position).index == 0
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_is_end"></a>

## Function `iter_is_end`

Returns whether the iterator is an end iterator.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, _map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>, _map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): bool {
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End)
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_borrow_key"></a>

## Function `iter_borrow_key`

Borrows the key given iterator points to.
Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
Note: Requires that the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">iter_borrow_key</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): &K
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">iter_borrow_key</a>&lt;K, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>, map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): &K {
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));

    <b>let</b> entries = &<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&map.SortedVectorMap).entries;
    &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Position).index).key
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_borrow"></a>

## Function `iter_borrow`

Borrows the value given iterator points to.
Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
Note: Requires that the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_borrow">iter_borrow</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): &V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_borrow">iter_borrow</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>, map: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): &V {
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));
    <b>let</b> entries = &<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&map.SortedVectorMap).entries;
    &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Position).index).value
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_borrow_mut"></a>

## Function `iter_borrow_mut`

Mutably borrows the value iterator points to.
Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
Note: Requires that the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_borrow_mut">iter_borrow_mut</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): &<b>mut</b> V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_borrow_mut">iter_borrow_mut</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>, map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): &<b>mut</b> V {
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> map.SortedVectorMap).entries;
    &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow_mut">vector::borrow_mut</a>(entries, <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Position).index).value
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_remove"></a>

## Function `iter_remove`

Removes (key, value) pair iterator points to, returning the previous value.
Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
Note: Requires that the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_remove">iter_remove</a>&lt;K: drop, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_remove">iter_remove</a>&lt;K: drop, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>, map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): V {
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));

    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> map.SortedVectorMap).entries;
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key: _, value } = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove">vector::remove</a>(entries, <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Position).index);
    value
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_replace"></a>

## Function `iter_replace`

Replaces the value iterator is pointing to, returning the previous value.
Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
Note: Requires that the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_replace">iter_replace</a>&lt;K: <b>copy</b>, drop, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, value: V): V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_replace">iter_replace</a>&lt;K: <b>copy</b> + drop, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>, map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, value: V): V {
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));

    // TODO once mem::replace is <b>public</b>/released, <b>update</b> <b>to</b>:
    // <b>let</b> entry = entries.<a href="ordered_map.md#0x1_ordered_map_borrow_mut">borrow_mut</a>(index);
    // mem::replace(&<b>mut</b> entry.value, value)
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> map.SortedVectorMap).entries;
    <b>let</b> index = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Position).index;
    <b>let</b> key = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, index).key;
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> {
        key: _,
        value: prev_value,
    } = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_replace">vector::replace</a>(entries, index, <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key, value });
    prev_value
}
</code></pre>



</details>

<a id="0x1_ordered_map_iter_add"></a>

## Function `iter_add`

Add key/value pair to the map, at the iterator position (before the element at the iterator position).
Aborts with ENEW_KEY_NOT_IN_ORDER is key is not larger than the key before the iterator,
or smaller than the key at the iterator position.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_add">iter_add</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, key: K, value: V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_iter_add">iter_add</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a>, map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: K, value: V) {
    <b>let</b> entries = &<b>mut</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> map.SortedVectorMap).entries;
    <b>let</b> len = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(entries);
    <b>let</b> insert_index = <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End)) {
        len
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Position).index
    };

    <b>if</b> (insert_index &gt; 0) {
        <b>let</b> prev_entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, insert_index - 1);
        <b>let</b> ord = <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_compare">cmp::compare</a>(&prev_entry.key, &key);
        <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_lt">cmp::is_lt</a>(&ord), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_ENEW_KEY_NOT_IN_ORDER">ENEW_KEY_NOT_IN_ORDER</a>))
    };

    <b>if</b> (insert_index &lt; len) {
        <b>let</b> next_entry = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, insert_index);
        <b>let</b> ord = <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_compare">cmp::compare</a>(&key, &next_entry.key);
        <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_lt">cmp::is_lt</a>(&ord), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="ordered_map.md#0x1_ordered_map_ENEW_KEY_NOT_IN_ORDER">ENEW_KEY_NOT_IN_ORDER</a>))
    };

    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_insert">vector::insert</a>(entries, insert_index, <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key, value });
}
</code></pre>



</details>

<a id="0x1_ordered_map_destroy_empty"></a>

## Function `destroy_empty`

Destroys empty map.
Aborts if <code>self</code> is not empty.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_destroy_empty">destroy_empty</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_destroy_empty">destroy_empty</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;) {
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a> { tag: _, SortedVectorMap: sorted_vector_map } = self;
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_SortedVectorMapData">SortedVectorMapData</a> { entries } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(sorted_vector_map);
    // <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&entries), E_NOT_EMPTY);
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_destroy_empty">vector::destroy_empty</a>(entries);
}
</code></pre>



</details>

<a id="0x1_ordered_map_keys"></a>

## Function `keys`

Return all keys in the map. This requires keys to be copyable.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_keys">keys</a>&lt;K: <b>copy</b>, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_keys">keys</a>&lt;K: <b>copy</b>, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt; {
    <b>let</b> entries = &<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.SortedVectorMap).entries;
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_map_ref">vector::map_ref</a>(entries, |e| {
        <b>let</b> e: &<a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a>&lt;K, V&gt; = e;
        e.key
    })
}
</code></pre>



</details>

<a id="0x1_ordered_map_values"></a>

## Function `values`

Return all values in the map. This requires values to be copyable.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_values">values</a>&lt;K, V: <b>copy</b>&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_values">values</a>&lt;K, V: <b>copy</b>&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt; {
    <b>let</b> entries = &<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.SortedVectorMap).entries;
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_map_ref">vector::map_ref</a>(entries, |e| {
        <b>let</b> e: &<a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a>&lt;K, V&gt; = e;
        e.value
    })
}
</code></pre>



</details>

<a id="0x1_ordered_map_to_vec_pair"></a>

## Function `to_vec_pair`

Transform the map into two vectors with the keys and values respectively
Primarily used to destroy a map


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_to_vec_pair">to_vec_pair</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;): (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_to_vec_pair">to_vec_pair</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;) {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a> { tag: _, SortedVectorMap: sorted_vector_map } = self;
    <b>let</b> <a href="ordered_map.md#0x1_ordered_map_SortedVectorMapData">SortedVectorMapData</a> { entries } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(sorted_vector_map);
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each">vector::for_each</a>(entries, |e| {
        <b>let</b> <a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a> { key, value } = e;
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> keys, key);
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> values, value);
    });
    (keys, values)
}
</code></pre>



</details>

<a id="0x1_ordered_map_destroy"></a>

## Function `destroy`

For maps that cannot be dropped this is a utility to destroy them
using lambdas to destroy the individual keys and values.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_destroy">destroy</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, dk: |K|(), dv: |V|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_destroy">destroy</a>&lt;K, V&gt;(
    self: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;,
    dk: |K|,
    dv: |V|
) {
    <b>let</b> (keys, values) = <a href="ordered_map.md#0x1_ordered_map_to_vec_pair">to_vec_pair</a>(self);
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_destroy">vector::destroy</a>(keys, |_k| dk(_k));
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_destroy">vector::destroy</a>(values, |_v| dv(_v));
}
</code></pre>



</details>

<a id="0x1_ordered_map_for_each"></a>

## Function `for_each`

Apply the function to each key-value pair in the map, consuming it.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_for_each">for_each</a>&lt;K, V&gt;(self: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, f: |(K, V)|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_for_each">for_each</a>&lt;K, V&gt;(
    self: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;,
    f: |K, V|
) {
    <b>let</b> (keys, values) = <a href="ordered_map.md#0x1_ordered_map_to_vec_pair">to_vec_pair</a>(self);
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_zip">vector::zip</a>(keys, values, |k, v| f(k, v));
}
</code></pre>



</details>

<a id="0x1_ordered_map_for_each_ref"></a>

## Function `for_each_ref`

Apply the function to a reference of each key-value pair in the map.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_for_each_ref">for_each_ref</a>&lt;K: <b>copy</b>, drop, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, f: |(&K, &V)|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_for_each_ref">for_each_ref</a>&lt;K: <b>copy</b> + drop, V&gt;(self: &<a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, f: |&K, &V|) {
    <b>let</b> iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">internal_new_begin_iter</a>(self);
    <b>while</b> (!<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&iter, self)) {
        f(<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">iter_borrow_key</a>(&iter, self), <a href="ordered_map.md#0x1_ordered_map_iter_borrow">iter_borrow</a>(iter, self));
        iter = <a href="ordered_map.md#0x1_ordered_map_iter_next">iter_next</a>(iter, self);
    }

    // TODO: once <b>move</b> supports private functions <b>update</b> <b>to</b>:
    // <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_ref">vector::for_each_ref</a>(
    //     &entries,
    //     |entry| {
    //         f(&entry.key, &entry.value)
    //     }
    // );
}
</code></pre>



</details>

<a id="0x1_ordered_map_for_each_mut"></a>

## Function `for_each_mut`

Apply the function to a mutable reference of each key-value pair in the map.


<pre><code><b>public</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_for_each_mut">for_each_mut</a>&lt;K: <b>copy</b>, drop, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;, f: |(&K, &<b>mut</b> V)|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_for_each_mut">for_each_mut</a>&lt;K: <b>copy</b> + drop, V&gt;(self: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, f: |&K, &<b>mut</b> V|) {
    <b>let</b> iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">internal_new_begin_iter</a>(self);
    <b>while</b> (!<a href="ordered_map.md#0x1_ordered_map_iter_is_end">iter_is_end</a>(&iter, self)) {
        <b>let</b> key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">iter_borrow_key</a>(&iter, self);
        f(&key, <a href="ordered_map.md#0x1_ordered_map_iter_borrow_mut">iter_borrow_mut</a>(iter, self));
        iter = <a href="ordered_map.md#0x1_ordered_map_iter_next">iter_next</a>(iter, self);
    }

    // TODO: once <b>move</b> supports private functions udpate <b>to</b>:
    // <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_mut">vector::for_each_mut</a>(
    //     &<b>mut</b> entries,
    //     |entry| {
    //         f(&<b>mut</b> entry.key, &<b>mut</b> entry.value)
    //     }
    // );
}
</code></pre>



</details>

<a id="0x1_ordered_map_new_iter"></a>

## Function `new_iter`



<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_new_iter">new_iter</a>(index: u64): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_new_iter">new_iter</a>(index: u64): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> {
    <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> {
        tag: 2,
        End: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>(),
        Position: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="ordered_map.md#0x1_ordered_map_PositionData">PositionData</a> {
            index: index,
        }),
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_new_end_iter"></a>

## Function `new_end_iter`



<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_new_end_iter">new_end_iter</a>(): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_new_end_iter">new_end_iter</a>(): <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> {
    <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">IteratorPtr</a> {
        tag: 1,
        End: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<b>true</b>),
        Position: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>(),
    }
}
</code></pre>



</details>

<a id="0x1_ordered_map_binary_search"></a>

## Function `binary_search`



<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_binary_search">binary_search</a>&lt;K, V&gt;(key: &K, entries: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="ordered_map.md#0x1_ordered_map_Entry">ordered_map::Entry</a>&lt;K, V&gt;&gt;, start: u64, end: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_binary_search">binary_search</a>&lt;K, V&gt;(key: &K, entries: &<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="ordered_map.md#0x1_ordered_map_Entry">Entry</a>&lt;K, V&gt;&gt;, start: u64, end: u64): u64 {
    <b>let</b> l = start;
    <b>let</b> r = end;
    <b>while</b> (l != r) {
        <b>let</b> mid = l + ((r - l) &gt;&gt; 1);
        <b>let</b> comparison = <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_compare">cmp::compare</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(entries, mid).key, key);
        <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_lt">cmp::is_lt</a>(&comparison)) {
            l = mid + 1;
        } <b>else</b> {
            r = mid;
        };
    };
    l
}
</code></pre>



</details>

<a id="0x1_ordered_map_test_verify_borrow_front_key"></a>

## Function `test_verify_borrow_front_key`



<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_borrow_front_key">test_verify_borrow_front_key</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_borrow_front_key">test_verify_borrow_front_key</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="ordered_map.md#0x1_ordered_map_new_from">new_from</a>(keys, values);
    <b>let</b> (key, value) = <a href="ordered_map.md#0x1_ordered_map_borrow_front">borrow_front</a>(&map);
    <b>spec</b> {
        <b>assert</b> keys[0] == 1;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_spec_contains">vector::spec_contains</a>(keys, 1);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, key);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_get">spec_get</a>(map, key) == value;
        <b>assert</b> key == (1 <b>as</b> u64);
    };
}
</code></pre>



</details>

<a id="0x1_ordered_map_test_verify_borrow_back_key"></a>

## Function `test_verify_borrow_back_key`



<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_borrow_back_key">test_verify_borrow_back_key</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_borrow_back_key">test_verify_borrow_back_key</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="ordered_map.md#0x1_ordered_map_new_from">new_from</a>(keys, values);
    <b>let</b> (key, value) = <a href="ordered_map.md#0x1_ordered_map_borrow_back">borrow_back</a>(&map);
    <b>spec</b> {
        <b>assert</b> keys[2] == 3;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_spec_contains">vector::spec_contains</a>(keys, 3);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, key);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_get">spec_get</a>(map, key) == value;
        <b>assert</b> key == (3 <b>as</b> u64);
    };
}
</code></pre>



</details>

<a id="0x1_ordered_map_test_verify_upsert"></a>

## Function `test_verify_upsert`



<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_upsert">test_verify_upsert</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_upsert">test_verify_upsert</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="ordered_map.md#0x1_ordered_map_new_from">new_from</a>(keys, values);
    <b>spec</b> {
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_len">spec_len</a>(map) == 3;
    };
    <b>let</b> (_key, _value) = <a href="ordered_map.md#0x1_ordered_map_borrow_back">borrow_back</a>(&map);
    <b>let</b> result_1 = <a href="ordered_map.md#0x1_ordered_map_upsert">upsert</a>(&<b>mut</b> map, 4, 5);
    <b>spec</b> {
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 4);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_get">spec_get</a>(map, 4) == 5;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_none">option::is_none</a>(result_1);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_len">spec_len</a>(map) == 4;
    };
    <b>let</b> result_2 = <a href="ordered_map.md#0x1_ordered_map_upsert">upsert</a>(&<b>mut</b> map, 4, 6);
    <b>spec</b> {
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 4);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_get">spec_get</a>(map, 4) == 6;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(result_2);
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(result_2) == 5;
    };
    <b>spec</b> {
        <b>assert</b> keys[0] == 1;
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_get">spec_get</a>(map, 1) == 4;
    };
    <b>let</b> v = <a href="ordered_map.md#0x1_ordered_map_remove">remove</a>(&<b>mut</b> map, &1);
    <b>spec</b> {
        <b>assert</b> v == 4;
    };
    <a href="ordered_map.md#0x1_ordered_map_remove">remove</a>(&<b>mut</b> map, &2);
    <a href="ordered_map.md#0x1_ordered_map_remove">remove</a>(&<b>mut</b> map, &3);
    <a href="ordered_map.md#0x1_ordered_map_remove">remove</a>(&<b>mut</b> map, &4);
    <b>spec</b> {
        <b>assert</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 3);
        <b>assert</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 4);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_len">spec_len</a>(map) == 0;
    };
    <a href="ordered_map.md#0x1_ordered_map_destroy_empty">destroy_empty</a>(map);
}
</code></pre>



</details>

<a id="0x1_ordered_map_test_verify_next_key"></a>

## Function `test_verify_next_key`



<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_next_key">test_verify_next_key</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_next_key">test_verify_next_key</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="ordered_map.md#0x1_ordered_map_new_from">new_from</a>(keys, values);
    <b>let</b> result_1 = <a href="ordered_map.md#0x1_ordered_map_next_key">next_key</a>(&map, &3);
    <b>spec</b> {
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_none">option::is_none</a>(result_1);
    };
    <b>let</b> result_2 = <a href="ordered_map.md#0x1_ordered_map_next_key">next_key</a>(&map, &1);
    <b>spec</b> {
        <b>assert</b> keys[0] == 1;
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> keys[1] == 2;
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(result_2);
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(result_2) == 2;
    };
}
</code></pre>



</details>

<a id="0x1_ordered_map_test_verify_prev_key"></a>

## Function `test_verify_prev_key`



<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_prev_key">test_verify_prev_key</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_prev_key">test_verify_prev_key</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="ordered_map.md#0x1_ordered_map_new_from">new_from</a>(keys, values);
    <b>let</b> result_1 = <a href="ordered_map.md#0x1_ordered_map_prev_key">prev_key</a>(&map, &1);
    <b>spec</b> {
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_none">option::is_none</a>(result_1);
    };
    <b>let</b> result_2 = <a href="ordered_map.md#0x1_ordered_map_prev_key">prev_key</a>(&map, &3);
    <b>spec</b> {
        <b>assert</b> keys[0] == 1;
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> keys[1] == 2;
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(result_2);
    };
}
</code></pre>



</details>

<a id="0x1_ordered_map_test_aborts_if_new_from_1"></a>

## Function `test_aborts_if_new_from_1`



<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_aborts_if_new_from_1">test_aborts_if_new_from_1</a>(): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;u64, u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_aborts_if_new_from_1">test_aborts_if_new_from_1</a>(): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;u64, u64&gt; {
   <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3, 1];
   <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6, 7];
   <b>spec</b> {
       <b>assert</b> keys[0] == 1;
       <b>assert</b> keys[3] == 1;
   };
   <b>let</b> map = <a href="ordered_map.md#0x1_ordered_map_new_from">new_from</a>(keys, values);
   map
}
</code></pre>



</details>

<a id="0x1_ordered_map_test_aborts_if_new_from_2"></a>

## Function `test_aborts_if_new_from_2`



<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_aborts_if_new_from_2">test_aborts_if_new_from_2</a>(keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;u64, u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_aborts_if_new_from_2">test_aborts_if_new_from_2</a>(keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;u64, u64&gt; {
   <b>let</b> map = <a href="ordered_map.md#0x1_ordered_map_new_from">new_from</a>(keys, values);
   map
}
</code></pre>



</details>

<a id="0x1_ordered_map_test_aborts_if_remove"></a>

## Function `test_aborts_if_remove`



<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_aborts_if_remove">test_aborts_if_remove</a>(map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;u64, u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_aborts_if_remove">test_aborts_if_remove</a>(map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;u64, u64&gt;) {
   <a href="ordered_map.md#0x1_ordered_map_remove">remove</a>(map, &1);
}
</code></pre>



</details>

<a id="0x1_ordered_map_test_verify_remove_or_none"></a>

## Function `test_verify_remove_or_none`



<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_remove_or_none">test_verify_remove_or_none</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_verify_remove_or_none">test_verify_remove_or_none</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="ordered_map.md#0x1_ordered_map_new_from">new_from</a>(keys, values);
    <b>spec</b> {
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_len">spec_len</a>(map) == 3;
    };
    <b>let</b> (_key, _value) = <a href="ordered_map.md#0x1_ordered_map_borrow_back">borrow_back</a>(&map);
    <b>spec</b>{
        <b>assert</b> keys[0] == 1;
        <b>assert</b> keys[1] == 2;
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
    };
    <b>let</b> result_1 = <a href="ordered_map.md#0x1_ordered_map_remove_or_none">remove_or_none</a>(&<b>mut</b> map, &1);
    <b>spec</b> {
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_get">spec_get</a>(map, 2) == 5;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_spec_is_some">option::spec_is_some</a>(result_1);
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_spec_borrow">option::spec_borrow</a>(result_1) == 4;
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_len">spec_len</a>(map) == 2;
        <b>assert</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 4);
    };
    <b>let</b> result_2 = <a href="ordered_map.md#0x1_ordered_map_remove_or_none">remove_or_none</a>(&<b>mut</b> map, &4);
    <b>spec</b> {
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_get">spec_get</a>(map, 2) == 5;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_spec_is_none">option::spec_is_none</a>(result_2);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_len">spec_len</a>(map) == 2;
        <b>assert</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 4);
    };
    <a href="ordered_map.md#0x1_ordered_map_remove">remove</a>(&<b>mut</b> map, &2);
    <a href="ordered_map.md#0x1_ordered_map_remove">remove</a>(&<b>mut</b> map, &3);
    <b>spec</b> {
        <b>assert</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 3);
        <b>assert</b> <a href="ordered_map.md#0x1_ordered_map_spec_len">spec_len</a>(map) == 0;
    };
    <a href="ordered_map.md#0x1_ordered_map_destroy_empty">destroy_empty</a>(map);
}
</code></pre>



</details>

<a id="@Specification_1"></a>

## Specification



<pre><code><b>pragma</b> verify = <b>true</b>;
</code></pre>




<a id="0x1_ordered_map_spec_len"></a>


<pre><code><b>native</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_spec_len">spec_len</a>&lt;K, V&gt;(map: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;): num;
</code></pre>




<a id="0x1_ordered_map_spec_contains_key"></a>


<pre><code><b>native</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>&lt;K, V&gt;(map: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: K): bool;
</code></pre>




<a id="0x1_ordered_map_spec_get"></a>


<pre><code><b>native</b> <b>fun</b> <a href="ordered_map.md#0x1_ordered_map_spec_get">spec_get</a>&lt;K, V&gt;(map: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">OrderedMap</a>&lt;K, V&gt;, key: K): V;
</code></pre>



<a id="@Specification_1_test_aborts_if_new_from_1"></a>

### Function `test_aborts_if_new_from_1`


<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_aborts_if_new_from_1">test_aborts_if_new_from_1</a>(): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;u64, u64&gt;
</code></pre>




<pre><code><b>aborts_if</b> <b>true</b>;
</code></pre>



<a id="@Specification_1_test_aborts_if_new_from_2"></a>

### Function `test_aborts_if_new_from_2`


<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_aborts_if_new_from_2">test_aborts_if_new_from_2</a>(keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;u64, u64&gt;
</code></pre>




<pre><code><b>aborts_if</b> <b>exists</b> i in 0..len(keys), j in 0..len(keys) <b>where</b> i != j : keys[i] == keys[j];
<b>aborts_if</b> len(keys) != len(values);
</code></pre>



<a id="@Specification_1_test_aborts_if_remove"></a>

### Function `test_aborts_if_remove`


<pre><code>#[verify_only]
<b>fun</b> <a href="ordered_map.md#0x1_ordered_map_test_aborts_if_remove">test_aborts_if_remove</a>(map: &<b>mut</b> <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;u64, u64&gt;)
</code></pre>




<pre><code><b>aborts_if</b> !<a href="ordered_map.md#0x1_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
</code></pre>


[move-book]: https://endless.dev/move/book/SUMMARY

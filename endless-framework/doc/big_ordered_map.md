
<a id="0x1_big_ordered_map"></a>

# Module `0x1::big_ordered_map`

This module provides an implementation for an big ordered map.
Big means that it is stored across multiple resources, and doesn't have an
upper limit on number of elements it can contain.

Keys point to values, and each key in the map must be unique.

Currently, one implementation is provided - BPlusTreeMap, backed by a B+Tree,
with each node being a separate resource, internally containing OrderedMap.

BPlusTreeMap is chosen since the biggest (performance and gast)
costs are reading resources, and it:
* reduces number of resource accesses
* reduces number of rebalancing operations, and makes each rebalancing
operation touch only few resources
* it allows for parallelism for keys that are not close to each other,
once it contains enough keys

Note: Default configuration (used in <code><a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>(0, 0, <b>false</b>)</code>) allows for keys and values of up to 5KB,
or 100 times the first (key, value), to satisfy general needs.
If you need larger, use other constructor methods.
Based on initial configuration, BigOrderedMap will always accept insertion of keys and values
up to the allowed size, and will abort with EKEY_BYTES_TOO_LARGE or EARGUMENT_BYTES_TOO_LARGE.

Warning: All iterator functions need to be carefully used, because they are just pointers into the
structure, and modification of the map invalidates them (without compiler being able to catch it).
Type is also named IteratorPtr, so that Iterator is free to use later.
Better guarantees would need future Move improvements that will allow references to be part of the struct,
allowing cleaner iterator APIs.

That's why all functions returning iterators are prefixed with "internal_", to clarify nuances needed to make
sure usage is correct.
A set of inline utility methods is provided instead, to provide guaranteed valid usage to iterators.


-  [Struct `Node`](#0x1_big_ordered_map_Node)
-  [Struct `ChildInnerData`](#0x1_big_ordered_map_ChildInnerData)
-  [Struct `ChildLeafData`](#0x1_big_ordered_map_ChildLeafData)
-  [Struct `Child`](#0x1_big_ordered_map_Child)
-  [Struct `IteratorPtrSomeData`](#0x1_big_ordered_map_IteratorPtrSomeData)
-  [Struct `IteratorPtr`](#0x1_big_ordered_map_IteratorPtr)
-  [Struct `IteratorPtrWithPath`](#0x1_big_ordered_map_IteratorPtrWithPath)
-  [Struct `BigOrderedMap`](#0x1_big_ordered_map_BigOrderedMap)
-  [Struct `LeafNodeIteratorPtrNodeIndexData`](#0x1_big_ordered_map_LeafNodeIteratorPtrNodeIndexData)
-  [Struct `LeafNodeIteratorPtr`](#0x1_big_ordered_map_LeafNodeIteratorPtr)
-  [Constants](#@Constants_0)
-  [Function `new`](#0x1_big_ordered_map_new)
-  [Function `new_with_reusable`](#0x1_big_ordered_map_new_with_reusable)
-  [Function `new_with_type_size_hints`](#0x1_big_ordered_map_new_with_type_size_hints)
-  [Function `new_with_config`](#0x1_big_ordered_map_new_with_config)
-  [Function `new_from`](#0x1_big_ordered_map_new_from)
-  [Function `destroy_empty`](#0x1_big_ordered_map_destroy_empty)
-  [Function `allocate_spare_slots`](#0x1_big_ordered_map_allocate_spare_slots)
-  [Function `is_empty`](#0x1_big_ordered_map_is_empty)
-  [Function `compute_length`](#0x1_big_ordered_map_compute_length)
-  [Function `add`](#0x1_big_ordered_map_add)
-  [Function `upsert`](#0x1_big_ordered_map_upsert)
-  [Function `remove`](#0x1_big_ordered_map_remove)
-  [Function `remove_or_none`](#0x1_big_ordered_map_remove_or_none)
-  [Function `modify`](#0x1_big_ordered_map_modify)
-  [Function `modify_and_return`](#0x1_big_ordered_map_modify_and_return)
-  [Function `modify_or_add`](#0x1_big_ordered_map_modify_or_add)
-  [Function `modify_if_present`](#0x1_big_ordered_map_modify_if_present)
-  [Function `modify_if_present_and_return`](#0x1_big_ordered_map_modify_if_present_and_return)
-  [Function `add_all`](#0x1_big_ordered_map_add_all)
-  [Function `pop_front`](#0x1_big_ordered_map_pop_front)
-  [Function `pop_back`](#0x1_big_ordered_map_pop_back)
-  [Function `internal_lower_bound`](#0x1_big_ordered_map_internal_lower_bound)
-  [Function `internal_find`](#0x1_big_ordered_map_internal_find)
-  [Function `internal_find_with_path`](#0x1_big_ordered_map_internal_find_with_path)
-  [Function `iter_with_path_get_iter`](#0x1_big_ordered_map_iter_with_path_get_iter)
-  [Function `contains`](#0x1_big_ordered_map_contains)
-  [Function `borrow`](#0x1_big_ordered_map_borrow)
-  [Function `get`](#0x1_big_ordered_map_get)
-  [Function `get_and_map`](#0x1_big_ordered_map_get_and_map)
-  [Function `borrow_mut`](#0x1_big_ordered_map_borrow_mut)
-  [Function `borrow_front`](#0x1_big_ordered_map_borrow_front)
-  [Function `borrow_back`](#0x1_big_ordered_map_borrow_back)
-  [Function `prev_key`](#0x1_big_ordered_map_prev_key)
-  [Function `next_key`](#0x1_big_ordered_map_next_key)
-  [Function `to_ordered_map`](#0x1_big_ordered_map_to_ordered_map)
-  [Function `keys`](#0x1_big_ordered_map_keys)
-  [Function `for_each_and_clear`](#0x1_big_ordered_map_for_each_and_clear)
-  [Function `for_each`](#0x1_big_ordered_map_for_each)
-  [Function `for_each_ref`](#0x1_big_ordered_map_for_each_ref)
-  [Function `intersection_zip_for_each_ref`](#0x1_big_ordered_map_intersection_zip_for_each_ref)
-  [Function `for_each_mut`](#0x1_big_ordered_map_for_each_mut)
-  [Function `destroy`](#0x1_big_ordered_map_destroy)
-  [Function `internal_new_begin_iter`](#0x1_big_ordered_map_internal_new_begin_iter)
-  [Function `internal_new_end_iter`](#0x1_big_ordered_map_internal_new_end_iter)
-  [Function `iter_is_begin`](#0x1_big_ordered_map_iter_is_begin)
-  [Function `iter_is_end`](#0x1_big_ordered_map_iter_is_end)
-  [Function `iter_borrow_key`](#0x1_big_ordered_map_iter_borrow_key)
-  [Function `iter_borrow`](#0x1_big_ordered_map_iter_borrow)
-  [Function `iter_borrow_mut`](#0x1_big_ordered_map_iter_borrow_mut)
-  [Function `iter_modify`](#0x1_big_ordered_map_iter_modify)
-  [Function `iter_remove`](#0x1_big_ordered_map_iter_remove)
-  [Function `iter_next`](#0x1_big_ordered_map_iter_next)
-  [Function `iter_prev`](#0x1_big_ordered_map_iter_prev)
-  [Function `internal_leaf_new_begin_iter`](#0x1_big_ordered_map_internal_leaf_new_begin_iter)
-  [Function `internal_leaf_iter_is_end`](#0x1_big_ordered_map_internal_leaf_iter_is_end)
-  [Function `internal_leaf_borrow_value`](#0x1_big_ordered_map_internal_leaf_borrow_value)
-  [Function `internal_leaf_iter_borrow_entries_and_next_leaf_index`](#0x1_big_ordered_map_internal_leaf_iter_borrow_entries_and_next_leaf_index)
-  [Function `for_each_leaf_node_children_ref`](#0x1_big_ordered_map_for_each_leaf_node_children_ref)
-  [Function `borrow_node`](#0x1_big_ordered_map_borrow_node)
-  [Function `borrow_node_mut`](#0x1_big_ordered_map_borrow_node_mut)
-  [Function `add_or_upsert_impl`](#0x1_big_ordered_map_add_or_upsert_impl)
-  [Function `validate_dynamic_size_and_init_max_degrees`](#0x1_big_ordered_map_validate_dynamic_size_and_init_max_degrees)
-  [Function `validate_static_size_and_init_max_degrees`](#0x1_big_ordered_map_validate_static_size_and_init_max_degrees)
-  [Function `validate_size_and_init_max_degrees`](#0x1_big_ordered_map_validate_size_and_init_max_degrees)
-  [Function `destroy_inner_child`](#0x1_big_ordered_map_destroy_inner_child)
-  [Function `destroy_empty_node`](#0x1_big_ordered_map_destroy_empty_node)
-  [Function `new_node`](#0x1_big_ordered_map_new_node)
-  [Function `new_node_with_children`](#0x1_big_ordered_map_new_node_with_children)
-  [Function `new_inner_child`](#0x1_big_ordered_map_new_inner_child)
-  [Function `new_leaf_child`](#0x1_big_ordered_map_new_leaf_child)
-  [Function `new_iter`](#0x1_big_ordered_map_new_iter)
-  [Function `find_leaf`](#0x1_big_ordered_map_find_leaf)
-  [Function `find_leaf_path`](#0x1_big_ordered_map_find_leaf_path)
-  [Function `get_max_degree`](#0x1_big_ordered_map_get_max_degree)
-  [Function `replace_root`](#0x1_big_ordered_map_replace_root)
-  [Function `add_at`](#0x1_big_ordered_map_add_at)
-  [Function `update_key`](#0x1_big_ordered_map_update_key)
-  [Function `remove_at`](#0x1_big_ordered_map_remove_at)
-  [Function `test_verify_borrow_front_key`](#0x1_big_ordered_map_test_verify_borrow_front_key)
-  [Function `test_verify_borrow_back_key`](#0x1_big_ordered_map_test_verify_borrow_back_key)
-  [Function `test_verify_upsert`](#0x1_big_ordered_map_test_verify_upsert)
-  [Function `test_verify_next_key`](#0x1_big_ordered_map_test_verify_next_key)
-  [Function `test_verify_prev_key`](#0x1_big_ordered_map_test_verify_prev_key)
-  [Function `test_verify_remove`](#0x1_big_ordered_map_test_verify_remove)
-  [Function `test_aborts_if_new_from_1`](#0x1_big_ordered_map_test_aborts_if_new_from_1)
-  [Function `test_aborts_if_new_from_2`](#0x1_big_ordered_map_test_aborts_if_new_from_2)
-  [Function `test_aborts_if_remove`](#0x1_big_ordered_map_test_aborts_if_remove)
-  [Specification](#@Specification_1)
    -  [Function `add_at`](#@Specification_1_add_at)
    -  [Function `remove_at`](#@Specification_1_remove_at)
    -  [Function `test_verify_borrow_front_key`](#@Specification_1_test_verify_borrow_front_key)
    -  [Function `test_verify_borrow_back_key`](#@Specification_1_test_verify_borrow_back_key)
    -  [Function `test_verify_upsert`](#@Specification_1_test_verify_upsert)
    -  [Function `test_verify_next_key`](#@Specification_1_test_verify_next_key)
    -  [Function `test_verify_prev_key`](#@Specification_1_test_verify_prev_key)
    -  [Function `test_verify_remove`](#@Specification_1_test_verify_remove)
    -  [Function `test_aborts_if_new_from_1`](#@Specification_1_test_aborts_if_new_from_1)
    -  [Function `test_aborts_if_new_from_2`](#@Specification_1_test_aborts_if_new_from_2)
    -  [Function `test_aborts_if_remove`](#@Specification_1_test_aborts_if_remove)


<pre><code><b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs">0x1::bcs</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp">0x1::cmp</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="../../endless-stdlib/doc/math64.md#0x1_math64">0x1::math64</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="ordered_map.md#0x1_ordered_map">0x1::ordered_map</a>;
<b>use</b> <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator">0x1::storage_slots_allocator</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">0x1::vector</a>;
</code></pre>



<a id="0x1_big_ordered_map_Node"></a>

## Struct `Node`

A node of the BigOrderedMap.

Inner node will have all children be Child::Inner, pointing to the child nodes.
Leaf node will have all children be Child::Leaf.
Basically - Leaf node is a single-resource OrderedMap, containing as much key/value entries, as can fit.
So Leaf node contains multiple values, not just one.


<pre><code><b>struct</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a>&lt;K: store, V: store&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>is_leaf: bool</code>
</dt>
<dd>

</dd>
<dt>
<code>children: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>prev: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>next: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_big_ordered_map_ChildInnerData"></a>

## Struct `ChildInnerData`

Data for the Inner variant of Child


<pre><code><b>struct</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ChildInnerData">ChildInnerData</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node_index: <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_StoredSlot">storage_slots_allocator::StoredSlot</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_big_ordered_map_ChildLeafData"></a>

## Struct `ChildLeafData`

Data for the Leaf variant of Child


<pre><code><b>struct</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ChildLeafData">ChildLeafData</a>&lt;V: store&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>value: V</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_big_ordered_map_Child"></a>

## Struct `Child`

Contents of a child node.


<pre><code><b>struct</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V: store&gt; <b>has</b> store
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
<code>Inner: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="big_ordered_map.md#0x1_big_ordered_map_ChildInnerData">big_ordered_map::ChildInnerData</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>Leaf: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="big_ordered_map.md#0x1_big_ordered_map_ChildLeafData">big_ordered_map::ChildLeafData</a>&lt;V&gt;&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_big_ordered_map_IteratorPtrSomeData"></a>

## Struct `IteratorPtrSomeData`

Data for the Some variant of IteratorPtr


<pre><code><b>struct</b> <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrSomeData">IteratorPtrSomeData</a>&lt;K&gt; <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node_index: u64</code>
</dt>
<dd>
 The node index of the iterator pointing to.
</dd>
<dt>
<code>child_iter: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a></code>
</dt>
<dd>
 Child iter it is pointing to
</dd>
<dt>
<code>key: K</code>
</dt>
<dd>
 <code>key</code> to which <code>(node_index, child_iter)</code> are pointing to
 cache to not require borrowing global resources to fetch again
</dd>
</dl>


</details>

<a id="0x1_big_ordered_map_IteratorPtr"></a>

## Struct `IteratorPtr`

An iterator to iterate all keys in the BigOrderedMap.

TODO: Once fields can be (mutable) references, this class will be deprecated.


<pre><code><b>struct</b> <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt; <b>has</b> <b>copy</b>, drop
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
<code>Some: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrSomeData">big_ordered_map::IteratorPtrSomeData</a>&lt;K&gt;&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_big_ordered_map_IteratorPtrWithPath"></a>

## Struct `IteratorPtrWithPath`



<pre><code><b>struct</b> <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">IteratorPtrWithPath</a>&lt;K&gt; <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>iterator: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>path: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_big_ordered_map_BigOrderedMap"></a>

## Struct `BigOrderedMap`

The BigOrderedMap data structure.


<pre><code><b>struct</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K: store, V: store&gt; <b>has</b> store
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
<code>root: <a href="big_ordered_map.md#0x1_big_ordered_map_Node">big_ordered_map::Node</a>&lt;K, V&gt;</code>
</dt>
<dd>
 Root node stored directly inside the resource.
</dd>
<dt>
<code>nodes: <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_StorageSlotsAllocator">storage_slots_allocator::StorageSlotsAllocator</a>&lt;<a href="big_ordered_map.md#0x1_big_ordered_map_Node">big_ordered_map::Node</a>&lt;K, V&gt;&gt;</code>
</dt>
<dd>
 Storage of all non-root nodes. They are stored in separate storage slots.
</dd>
<dt>
<code>min_leaf_index: u64</code>
</dt>
<dd>
 The node index of the leftmost node.
</dd>
<dt>
<code>max_leaf_index: u64</code>
</dt>
<dd>
 The node index of the rightmost node.
</dd>
<dt>
<code>constant_kv_size: bool</code>
</dt>
<dd>
 Whether Key and Value have constant serialized size.
</dd>
<dt>
<code>inner_max_degree: u64</code>
</dt>
<dd>
 The max number of children an inner node can have.
</dd>
<dt>
<code>leaf_max_degree: u64</code>
</dt>
<dd>
 The max number of children a leaf node can have.
</dd>
</dl>


</details>

<a id="0x1_big_ordered_map_LeafNodeIteratorPtrNodeIndexData"></a>

## Struct `LeafNodeIteratorPtrNodeIndexData`

Data for the NodeIndex variant of LeafNodeIteratorPtr


<pre><code><b>struct</b> <a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtrNodeIndexData">LeafNodeIteratorPtrNodeIndexData</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node_index: u64</code>
</dt>
<dd>
 The node index of the iterator pointing to.
 NULL_INDEX if end iterator
</dd>
</dl>


</details>

<a id="0x1_big_ordered_map_LeafNodeIteratorPtr"></a>

## Struct `LeafNodeIteratorPtr`



<pre><code><b>struct</b> <a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">LeafNodeIteratorPtr</a> <b>has</b> <b>copy</b>, drop
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
<code>NodeIndex: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtrNodeIndexData">big_ordered_map::LeafNodeIteratorPtrNodeIndexData</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN"></a>

Internal errors.


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>: u64 = 20;
</code></pre>



<a id="0x1_big_ordered_map_NULL_INDEX"></a>



<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>: u64 = 0;
</code></pre>



<a id="0x1_big_ordered_map_EITER_OUT_OF_BOUNDS"></a>

Trying to do an operation on an IteratorPtr that would go out of bounds


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>: u64 = 3;
</code></pre>



<a id="0x1_big_ordered_map_EKEY_ALREADY_EXISTS"></a>

Map key already exists


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_ALREADY_EXISTS">EKEY_ALREADY_EXISTS</a>: u64 = 1;
</code></pre>



<a id="0x1_big_ordered_map_EKEY_NOT_FOUND"></a>

Map key is not found


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>: u64 = 2;
</code></pre>



<a id="0x1_big_ordered_map_DEFAULT_MAX_KEY_OR_VALUE_SIZE"></a>

When using default constructors (new() / new_with_reusable() / new_with_config(0, 0, _))
making sure key or value of this size (5KB) will be accepted, which should satisfy most cases
If you need keys/values that are larger, use other constructors.


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_DEFAULT_MAX_KEY_OR_VALUE_SIZE">DEFAULT_MAX_KEY_OR_VALUE_SIZE</a>: u64 = 5120;
</code></pre>



<a id="0x1_big_ordered_map_DEFAULT_TARGET_NODE_SIZE"></a>

Target node size, from efficiency perspective.


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_DEFAULT_TARGET_NODE_SIZE">DEFAULT_TARGET_NODE_SIZE</a>: u64 = 4096;
</code></pre>



<a id="0x1_big_ordered_map_EARGUMENT_BYTES_TOO_LARGE"></a>

Trying to insert too large of an (key, value) into the map.


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_EARGUMENT_BYTES_TOO_LARGE">EARGUMENT_BYTES_TOO_LARGE</a>: u64 = 13;
</code></pre>



<a id="0x1_big_ordered_map_EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE"></a>

borrow_mut requires that key and value types have constant size
(otherwise it wouldn't be able to guarantee size requirements are not violated)
Use remove() + add() combo instead.


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE">EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE</a>: u64 = 14;
</code></pre>



<a id="0x1_big_ordered_map_ECANNOT_USE_NEW_WITH_VARIABLE_SIZED_TYPES"></a>

Cannot use new/new_with_reusable with variable-sized types.
Use <code><a href="big_ordered_map.md#0x1_big_ordered_map_new_with_type_size_hints">new_with_type_size_hints</a>()</code> or <code><a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>()</code> instead if your types have variable sizes.
<code><a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>(0, 0, <b>false</b>)</code> tries to work reasonably well for variety of sizes
(allows keys or values of at least 5KB and 100x larger than the first inserted)


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ECANNOT_USE_NEW_WITH_VARIABLE_SIZED_TYPES">ECANNOT_USE_NEW_WITH_VARIABLE_SIZED_TYPES</a>: u64 = 16;
</code></pre>



<a id="0x1_big_ordered_map_EINVALID_CONFIG_PARAMETER"></a>

The provided configuration parameter is invalid.


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_EINVALID_CONFIG_PARAMETER">EINVALID_CONFIG_PARAMETER</a>: u64 = 11;
</code></pre>



<a id="0x1_big_ordered_map_EKEY_BYTES_TOO_LARGE"></a>

Trying to insert too large of a key into the map.


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_BYTES_TOO_LARGE">EKEY_BYTES_TOO_LARGE</a>: u64 = 15;
</code></pre>



<a id="0x1_big_ordered_map_EMAP_NOT_EMPTY"></a>

Map isn't empty


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_EMAP_NOT_EMPTY">EMAP_NOT_EMPTY</a>: u64 = 12;
</code></pre>



<a id="0x1_big_ordered_map_HINT_MAX_NODE_BYTES"></a>

Target max node size, when using hints (via new_with_type_size_hints).
Smaller than MAX_NODE_BYTES, to improve performence, as large nodes are innefficient.


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_HINT_MAX_NODE_BYTES">HINT_MAX_NODE_BYTES</a>: u64 = 131072;
</code></pre>



<a id="0x1_big_ordered_map_INNER_MIN_DEGREE"></a>

Smallest allowed degree on inner nodes.


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_INNER_MIN_DEGREE">INNER_MIN_DEGREE</a>: u64 = 4;
</code></pre>



<a id="0x1_big_ordered_map_LEAF_MIN_DEGREE"></a>

Smallest allowed degree on leaf nodes.

We rely on 1 being valid size only for root node,
so this cannot be below 3 (unless that is changed)


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_LEAF_MIN_DEGREE">LEAF_MIN_DEGREE</a>: u64 = 3;
</code></pre>



<a id="0x1_big_ordered_map_MAX_DEGREE"></a>

Largest degree allowed (both for inner and leaf nodes)


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_DEGREE">MAX_DEGREE</a>: u64 = 4096;
</code></pre>



<a id="0x1_big_ordered_map_MAX_NODE_BYTES"></a>

Largest size all keys for inner nodes or key-value pairs for leaf nodes can have.
Node itself can be a bit larger, due to few other accounting fields.
This is a bit conservative, a bit less than half of the resource limit (which is 1MB)


<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_NODE_BYTES">MAX_NODE_BYTES</a>: u64 = 409600;
</code></pre>



<a id="0x1_big_ordered_map_ROOT_INDEX"></a>



<pre><code><b>const</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>: u64 = 1;
</code></pre>



<a id="0x1_big_ordered_map_new"></a>

## Function `new`

Returns a new BigOrderedMap with the default configuration.

Cannot be used with variable-sized types.
Use <code><a href="big_ordered_map.md#0x1_big_ordered_map_new_with_type_size_hints">new_with_type_size_hints</a>()</code> or <code><a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>()</code> instead if your types have variable sizes.
<code><a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>(0, 0, <b>false</b>)</code> tries to work reasonably well for variety of sizes
(allows keys or values of at least 5KB and 100x larger than the first inserted)


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new">new</a>&lt;K: store, V: store&gt;(): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new">new</a>&lt;K: store, V: store&gt;(): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt; {
    <b>assert</b>!(
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_constant_serialized_size">bcs::constant_serialized_size</a>&lt;K&gt;()) && <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_constant_serialized_size">bcs::constant_serialized_size</a>&lt;V&gt;()),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_ECANNOT_USE_NEW_WITH_VARIABLE_SIZED_TYPES">ECANNOT_USE_NEW_WITH_VARIABLE_SIZED_TYPES</a>)
    );
    <a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>(0, 0, <b>false</b>)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_new_with_reusable"></a>

## Function `new_with_reusable`

Returns a new BigOrderedMap with with reusable storage slots.

Cannot be used with variable-sized types.
Use <code><a href="big_ordered_map.md#0x1_big_ordered_map_new_with_type_size_hints">new_with_type_size_hints</a>()</code> or <code><a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>()</code> instead if your types have variable sizes.
<code><a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>(0, 0, <b>false</b>)</code> tries to work reasonably well for variety of sizes
(allows keys or values of at least 5KB and 100x larger than the first inserted)


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_with_reusable">new_with_reusable</a>&lt;K: store, V: store&gt;(): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_with_reusable">new_with_reusable</a>&lt;K: store, V: store&gt;(): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt; {
    <b>assert</b>!(
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_constant_serialized_size">bcs::constant_serialized_size</a>&lt;K&gt;()) && <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_constant_serialized_size">bcs::constant_serialized_size</a>&lt;V&gt;()),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_ECANNOT_USE_NEW_WITH_VARIABLE_SIZED_TYPES">ECANNOT_USE_NEW_WITH_VARIABLE_SIZED_TYPES</a>)
    );
    <a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>(0, 0, <b>true</b>)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_new_with_type_size_hints"></a>

## Function `new_with_type_size_hints`

Returns a new BigOrderedMap, configured based on passed key and value serialized size hints.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_with_type_size_hints">new_with_type_size_hints</a>&lt;K: store, V: store&gt;(avg_key_bytes: u64, max_key_bytes: u64, avg_value_bytes: u64, max_value_bytes: u64): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_with_type_size_hints">new_with_type_size_hints</a>&lt;K: store, V: store&gt;(avg_key_bytes: u64, max_key_bytes: u64, avg_value_bytes: u64, max_value_bytes: u64): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt; {
    <b>assert</b>!(avg_key_bytes &lt;= max_key_bytes, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINVALID_CONFIG_PARAMETER">EINVALID_CONFIG_PARAMETER</a>));
    <b>assert</b>!(avg_value_bytes &lt;= max_value_bytes, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINVALID_CONFIG_PARAMETER">EINVALID_CONFIG_PARAMETER</a>));

    <b>let</b> inner_max_degree_from_avg = max(<b>min</b>(<a href="big_ordered_map.md#0x1_big_ordered_map_MAX_DEGREE">MAX_DEGREE</a>, <a href="big_ordered_map.md#0x1_big_ordered_map_DEFAULT_TARGET_NODE_SIZE">DEFAULT_TARGET_NODE_SIZE</a> / avg_key_bytes), <a href="big_ordered_map.md#0x1_big_ordered_map_INNER_MIN_DEGREE">INNER_MIN_DEGREE</a>);
    <b>let</b> inner_max_degree_from_max = <a href="big_ordered_map.md#0x1_big_ordered_map_HINT_MAX_NODE_BYTES">HINT_MAX_NODE_BYTES</a> / max_key_bytes;
    <b>assert</b>!(inner_max_degree_from_max &gt;= <a href="big_ordered_map.md#0x1_big_ordered_map_INNER_MIN_DEGREE">INNER_MIN_DEGREE</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINVALID_CONFIG_PARAMETER">EINVALID_CONFIG_PARAMETER</a>));

    <b>let</b> avg_entry_size = avg_key_bytes + avg_value_bytes;
    <b>let</b> max_entry_size = max_key_bytes + max_value_bytes;

    <b>let</b> leaf_max_degree_from_avg = max(<b>min</b>(<a href="big_ordered_map.md#0x1_big_ordered_map_MAX_DEGREE">MAX_DEGREE</a>, <a href="big_ordered_map.md#0x1_big_ordered_map_DEFAULT_TARGET_NODE_SIZE">DEFAULT_TARGET_NODE_SIZE</a> / avg_entry_size), <a href="big_ordered_map.md#0x1_big_ordered_map_LEAF_MIN_DEGREE">LEAF_MIN_DEGREE</a>);
    <b>let</b> leaf_max_degree_from_max = <a href="big_ordered_map.md#0x1_big_ordered_map_HINT_MAX_NODE_BYTES">HINT_MAX_NODE_BYTES</a> / max_entry_size;
    <b>assert</b>!(leaf_max_degree_from_max &gt;= <a href="big_ordered_map.md#0x1_big_ordered_map_INNER_MIN_DEGREE">INNER_MIN_DEGREE</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINVALID_CONFIG_PARAMETER">EINVALID_CONFIG_PARAMETER</a>));

    <a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>(
        <b>min</b>(inner_max_degree_from_avg, inner_max_degree_from_max),
        <b>min</b>(leaf_max_degree_from_avg, leaf_max_degree_from_max),
        <b>false</b>,
    )
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_new_with_config"></a>

## Function `new_with_config`

Returns a new BigOrderedMap with the provided max degree consts (the maximum # of children a node can have, both inner and leaf).

If 0 is passed, then it is dynamically computed based on size of first key and value.
WIth 0 it is configured to accept keys and values up to 5KB in size,
or as large as 100x the size of the first insert. (100 = MAX_NODE_BYTES / DEFAULT_TARGET_NODE_SIZE)

Sizes of all elements must respect (or their additions will be rejected):
<code>key_size * inner_max_degree &lt;= <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_NODE_BYTES">MAX_NODE_BYTES</a></code>
<code>entry_size * leaf_max_degree &lt;= <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_NODE_BYTES">MAX_NODE_BYTES</a></code>
If keys or values have variable size, and first element could be non-representative in size (i.e. smaller than future ones),
it is important to compute and pass inner_max_degree and leaf_max_degree based on the largest element you want to be able to insert.

<code>reuse_slots</code> means that removing elements from the map doesn't free the storage slots and returns the refund.
Together with <code>allocate_spare_slots</code>, it allows to preallocate slots and have inserts have predictable gas costs.
(otherwise, inserts that require map to add new nodes, cost significantly more, compared to the rest)


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>&lt;K: store, V: store&gt;(inner_max_degree: u64, leaf_max_degree: u64, reuse_slots: bool): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_with_config">new_with_config</a>&lt;K: store, V: store&gt;(inner_max_degree: u64, leaf_max_degree: u64, reuse_slots: bool): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt; {
    <b>assert</b>!(inner_max_degree == 0 || (inner_max_degree &gt;= <a href="big_ordered_map.md#0x1_big_ordered_map_INNER_MIN_DEGREE">INNER_MIN_DEGREE</a> && inner_max_degree &lt;= <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_DEGREE">MAX_DEGREE</a>), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINVALID_CONFIG_PARAMETER">EINVALID_CONFIG_PARAMETER</a>));
    <b>assert</b>!(leaf_max_degree == 0 || (leaf_max_degree &gt;= <a href="big_ordered_map.md#0x1_big_ordered_map_LEAF_MIN_DEGREE">LEAF_MIN_DEGREE</a> && leaf_max_degree &lt;= <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_DEGREE">MAX_DEGREE</a>), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINVALID_CONFIG_PARAMETER">EINVALID_CONFIG_PARAMETER</a>));

    // Assert that <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator">storage_slots_allocator</a> special indices are aligned:
    <b>assert</b>!(<a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_is_null_index">storage_slots_allocator::is_null_index</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
    <b>assert</b>!(<a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_is_special_unused_index">storage_slots_allocator::is_special_unused_index</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));

    <b>let</b> nodes = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_new">storage_slots_allocator::new</a>(reuse_slots);

    <b>let</b> self = <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a> {
        tag: 1,
        root: <a href="big_ordered_map.md#0x1_big_ordered_map_new_node">new_node</a>(/*is_leaf=*/<b>true</b>),
        nodes: nodes,
        min_leaf_index: <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>,
        max_leaf_index: <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>,
        constant_kv_size: <b>false</b>, // Will be initialized in validate_static_size_and_init_max_degrees below.
        inner_max_degree: inner_max_degree,
        leaf_max_degree: leaf_max_degree,
    };
    <a href="big_ordered_map.md#0x1_big_ordered_map_validate_static_size_and_init_max_degrees">validate_static_size_and_init_max_degrees</a>(&<b>mut</b> self);
    self
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_new_from"></a>

## Function `new_from`

Create a BigOrderedMap from a vector of keys and values, with default configuration.
Aborts with EKEY_ALREADY_EXISTS if duplicate keys are passed in.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_from">new_from</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_from">new_from</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt; {
    <b>let</b> map = <a href="big_ordered_map.md#0x1_big_ordered_map_new">new</a>();
    <a href="big_ordered_map.md#0x1_big_ordered_map_add_all">add_all</a>(&<b>mut</b> map, keys, values);
    map
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_destroy_empty"></a>

## Function `destroy_empty`

Destroys the map if it's empty, otherwise aborts.
Note: If the map was created with reuse_slots=true, this will fail if there are
nodes in the reuse list. Use destroy with a lambda instead, or create the map with reuse_slots=false.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty">destroy_empty</a>&lt;K: store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty">destroy_empty</a>&lt;K: store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;) {
    <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a> { tag: _, root, nodes, min_leaf_index: _, max_leaf_index: _, constant_kv_size: _, inner_max_degree: _, leaf_max_degree: _ } = self;
    <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty_node">destroy_empty_node</a>(root);
    // If root node is empty, then we know that no storage slots are used,
    // and so we can safely destroy all nodes.
    <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_destroy_empty">storage_slots_allocator::destroy_empty</a>(nodes);
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_allocate_spare_slots"></a>

## Function `allocate_spare_slots`

Map was created with reuse_slots=true, you can allocate spare slots, to pay storage fee now, to
allow future insertions to not require any storage slot creation - making their gas more predictable
and better bounded/fair.
(otherwsie, unlucky inserts create new storage slots and are charge more for it)


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_allocate_spare_slots">allocate_spare_slots</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, num_to_allocate: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_allocate_spare_slots">allocate_spare_slots</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, num_to_allocate: u64) {
    <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_allocate_spare_slots">storage_slots_allocator::allocate_spare_slots</a>(&<b>mut</b> self.nodes, num_to_allocate)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_is_empty"></a>

## Function `is_empty`

Returns true iff the BigOrderedMap is empty.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_is_empty">is_empty</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_is_empty">is_empty</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): bool {
    <b>let</b> root = &self.root;
    <b>if</b> (root.is_leaf) {
        <a href="ordered_map.md#0x1_ordered_map_is_empty">ordered_map::is_empty</a>(&root.children)
    } <b>else</b> {
        <b>false</b>
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_compute_length"></a>

## Function `compute_length`

Returns the number of elements in the BigOrderedMap.
This is an expensive function, as it goes through all the leaves to compute it.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_compute_length">compute_length</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_compute_length">compute_length</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): u64 {
    <b>let</b> size = 0;
    <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_leaf_node_children_ref">for_each_leaf_node_children_ref</a>(self, |children| {
        size = size + <a href="ordered_map.md#0x1_ordered_map_length">ordered_map::length</a>(children);
    });
    size
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_add"></a>

## Function `add`

Inserts the key/value into the BigOrderedMap.
Aborts if the key is already in the map.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_add">add</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: K, value: V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_add">add</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: K, value: V) {
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_add_or_upsert_impl">add_or_upsert_impl</a>(self, key, value, <b>false</b>))
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_upsert"></a>

## Function `upsert`

If the key doesn't exist in the map, inserts the key/value, and returns none.
Otherwise updates the value under the given key, and returns the old value.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_upsert">upsert</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: K, value: V): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_upsert">upsert</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: K, value: V): Option&lt;V&gt; {
    <b>let</b> result = <a href="big_ordered_map.md#0x1_big_ordered_map_add_or_upsert_impl">add_or_upsert_impl</a>(self, key, value, <b>true</b>);
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&result)) {
        <b>let</b> child = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(result);
        <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> { tag: _, Inner: inner, Leaf: leaf } = child;
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(inner);
        <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ChildLeafData">ChildLeafData</a> { value: old_value } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(leaf);
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(old_value)
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(result);
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_remove"></a>

## Function `remove`

Removes the entry from BigOrderedMap and returns the value which <code>key</code> maps to.
Aborts if there is no entry for <code>key</code>.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): V {
    // Optimize case <b>where</b> only root node <b>exists</b>
    // (optimizes out borrowing and path creation in `find_leaf_path`)
    <b>let</b> root = &self.root;
    <b>if</b> (root.is_leaf) {
        <b>let</b> root_mut = &<b>mut</b> self.root;
        <b>let</b> child = <a href="ordered_map.md#0x1_ordered_map_remove">ordered_map::remove</a>(&<b>mut</b> root_mut.children, key);
        <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> { tag: _, Inner: inner, Leaf: leaf } = child;
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(inner);
        <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ChildLeafData">ChildLeafData</a> { value } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(leaf);
        <b>return</b> value
    };

    <b>let</b> path_to_leaf = <a href="big_ordered_map.md#0x1_big_ordered_map_find_leaf_path">find_leaf_path</a>(self, key);


    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&path_to_leaf), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>));
    // <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&path_to_leaf), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>));

    <b>let</b> child = <a href="big_ordered_map.md#0x1_big_ordered_map_remove_at">remove_at</a>(self, path_to_leaf, key);
    <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> { tag: _, Inner: inner, Leaf: leaf } = child;
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(inner);
    <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ChildLeafData">ChildLeafData</a> { value } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(leaf);
    value
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_remove_or_none"></a>

## Function `remove_or_none`

Removes the entry from BigOrderedMap and returns the value which <code>key</code> maps to.
Returns none if there is no entry for <code>key</code>.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_remove_or_none">remove_or_none</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_remove_or_none">remove_or_none</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): Option&lt;V&gt; {
    // Optimize case <b>where</b> only root node <b>exists</b>
    // (optimizes out borrowing and path creation in `find_leaf_path`)
    <b>let</b> root = &self.root;
    <b>if</b> (root.is_leaf) {
        <b>let</b> root_mut = &<b>mut</b> self.root;
        <b>let</b> value_option = <a href="ordered_map.md#0x1_ordered_map_remove_or_none">ordered_map::remove_or_none</a>(&<b>mut</b> root_mut.children, key);
        <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&value_option)) {
            <b>let</b> child = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(value_option);
            <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> { tag: _, Inner: inner, Leaf: leaf } = child;
            <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(inner);
            <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ChildLeafData">ChildLeafData</a> { value } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(leaf);
            <b>return</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(value)
        } <b>else</b> {
            <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(value_option);
            <b>return</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
        }
    };

    <b>let</b> path_to_leaf = <a href="big_ordered_map.md#0x1_big_ordered_map_find_leaf_path">find_leaf_path</a>(self, key);

    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&path_to_leaf)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <b>let</b> child = <a href="big_ordered_map.md#0x1_big_ordered_map_remove_at">remove_at</a>(self, path_to_leaf, key);
        <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> { tag: _, Inner: inner, Leaf: leaf } = child;
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(inner);
        <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ChildLeafData">ChildLeafData</a> { value } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(leaf);
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(value)
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_modify"></a>

## Function `modify`

Modifies the element in the map via calling f.
Aborts if element doesn't exist


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_modify">modify</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K, f: |&<b>mut</b> V|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_modify">modify</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K, f: |&<b>mut</b> V|) {
    <a href="big_ordered_map.md#0x1_big_ordered_map_modify_and_return">modify_and_return</a>(self, key, |v| { f(v); <b>true</b>});
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_modify_and_return"></a>

## Function `modify_and_return`

Modifies the element in the map via calling f, and propagates the return value of the function.
Aborts if element doesn't exist

This function cannot be inline, due to iter_modify requiring actual function value.
This also is why we return a value


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_modify_and_return">modify_and_return</a>&lt;K: <b>copy</b>, drop, store, V: store, R&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K, f: |&<b>mut</b> V|R): R
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_modify_and_return">modify_and_return</a>&lt;K: drop + <b>copy</b> + store, V: store, R&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K, f: |&<b>mut</b> V|R): R {
    <b>let</b> iter = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_find">internal_find</a>(self, key);
    <b>assert</b>!(!<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&iter, self), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>));
    <a href="big_ordered_map.md#0x1_big_ordered_map_iter_modify">iter_modify</a>(iter, self, |v| f(v))
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_modify_or_add"></a>

## Function `modify_or_add`

Modifies element by calling modify_f if it exists, or calling add_f to add if it doesn't.
Returns true if element already existed.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_modify_or_add">modify_or_add</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K, modify_f: |&<b>mut</b> V|(), add_f: |()|V): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_modify_or_add">modify_or_add</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K, modify_f: |&<b>mut</b> V|, add_f: ||V): bool {
    <b>let</b> <b>exists</b> = <a href="big_ordered_map.md#0x1_big_ordered_map_modify_if_present">modify_if_present</a>(self, key, |v| modify_f(v));
    <b>if</b> (!<b>exists</b>) {
        <a href="big_ordered_map.md#0x1_big_ordered_map_add">add</a>(self, *key, add_f());
    };
    <b>exists</b>
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_modify_if_present"></a>

## Function `modify_if_present`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_modify_if_present">modify_if_present</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K, modify_f: |&<b>mut</b> V|()): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_modify_if_present">modify_if_present</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K, modify_f: |&<b>mut</b> V|): bool {
    <b>let</b> result = <a href="big_ordered_map.md#0x1_big_ordered_map_modify_if_present_and_return">modify_if_present_and_return</a>(self, key, |v| { modify_f(v); <b>true</b> });
    <b>let</b> <b>exists</b> = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&result);
    <b>if</b> (<b>exists</b>) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(result);
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(result);
    };
    <b>exists</b>
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_modify_if_present_and_return"></a>

## Function `modify_if_present_and_return`

Modifies the element in the map via calling modify_f, and propagates the return value of the function.
Returns None if not present.

Function value cannot be inlined, due to iter_modify requiring actual function value.
This also is why we return a value


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_modify_if_present_and_return">modify_if_present_and_return</a>&lt;K: <b>copy</b>, drop, store, V: store, R&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K, modify_f: |&<b>mut</b> V|R): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;R&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_modify_if_present_and_return">modify_if_present_and_return</a>&lt;K: drop + <b>copy</b> + store, V: store, R&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K, modify_f: |&<b>mut</b> V|R): Option&lt;R&gt; {
    <b>let</b> iter = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_find">internal_find</a>(self, key);
    <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&iter, self)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_iter_modify">iter_modify</a>(iter, self, |v| modify_f(v)))
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_add_all"></a>

## Function `add_all`

Add multiple key/value pairs to the map. The keys must not already exist.
Aborts with EKEY_ALREADY_EXISTS if key already exist, or duplicate keys are passed in.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_add_all">add_all</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_add_all">add_all</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;V&gt;) {
    // TODO: Can be optimized, both in insertion order (largest first, then from smallest),
    // <b>as</b> well <b>as</b> on initializing inner_max_degree/leaf_max_degree better
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_zip">vector::zip</a>(keys, values, |key, value| {
        <a href="big_ordered_map.md#0x1_big_ordered_map_add">add</a>(self, key, value);
    });
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_pop_front"></a>

## Function `pop_front`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_pop_front">pop_front</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): (K, V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_pop_front">pop_front</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): (K, V) {
    <b>let</b> it = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_begin_iter">internal_new_begin_iter</a>(self);
    <b>let</b> k = *<a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&it);
    <b>let</b> v = <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(self, &k);
    (k, v)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_pop_back"></a>

## Function `pop_back`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_pop_back">pop_back</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): (K, V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_pop_back">pop_back</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): (K, V) {
    <b>let</b> it = <a href="big_ordered_map.md#0x1_big_ordered_map_iter_prev">iter_prev</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(self), self);
    <b>let</b> k = *<a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&it);
    <b>let</b> v = <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(self, &k);
    (k, v)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_internal_lower_bound"></a>

## Function `internal_lower_bound`

Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
For direct usage of this method, check Warning at the top of the file corresponding to iterators.

Returns an iterator pointing to the first element that is greater or equal to the provided
key, or an end iterator if such element doesn't exist.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_lower_bound">internal_lower_bound</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_lower_bound">internal_lower_bound</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt; {
    <b>let</b> leaf = <a href="big_ordered_map.md#0x1_big_ordered_map_find_leaf">find_leaf</a>(self, key);
    <b>if</b> (leaf == <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>) {
        <b>return</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(self)
    };

    <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(self, leaf);
    <b>assert</b>!(node.is_leaf, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));

    <b>let</b> child_lower_bound = <a href="ordered_map.md#0x1_ordered_map_internal_lower_bound">ordered_map::internal_lower_bound</a>(&node.children, key);
    <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">ordered_map::iter_is_end</a>(&child_lower_bound, &node.children)) {
        <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(self)
    } <b>else</b> {
        <b>let</b> iter_key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&child_lower_bound, &node.children);
        <a href="big_ordered_map.md#0x1_big_ordered_map_new_iter">new_iter</a>(leaf, child_lower_bound, iter_key)
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_internal_find"></a>

## Function `internal_find`

Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
For direct usage of this method, check Warning at the top of the file corresponding to iterators.

Returns an iterator pointing to the element that equals to the provided key, or an end
iterator if the key is not found.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_find">internal_find</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_find">internal_find</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt; {
    <b>let</b> internal_lower_bound = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_lower_bound">internal_lower_bound</a>(self, key);
    <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&internal_lower_bound, self)) {
        internal_lower_bound
    } <b>else</b> {
        <b>let</b> iter_key = <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&internal_lower_bound);
        <b>if</b> (iter_key == key) {
            internal_lower_bound
        } <b>else</b> {
            <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(self)
        }
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_internal_find_with_path"></a>

## Function `internal_find_with_path`

Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
For direct usage of this method, check Warning at the top of the file corresponding to iterators.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_find_with_path">internal_find_with_path</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">big_ordered_map::IteratorPtrWithPath</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_find_with_path">internal_find_with_path</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">IteratorPtrWithPath</a>&lt;K&gt; {
    <b>let</b> leaf_path = <a href="big_ordered_map.md#0x1_big_ordered_map_find_leaf_path">find_leaf_path</a>(self, key);
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&leaf_path)) {
        <b>return</b> <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">IteratorPtrWithPath</a> { iterator: <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(self), path: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>() }
    };

    <b>let</b> leaf_index = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&leaf_path) - 1;
    <b>let</b> leaf = *<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&leaf_path, leaf_index);
    <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(self, leaf);
    <b>assert</b>!(node.is_leaf, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));

    <b>let</b> child_lower_bound = <a href="ordered_map.md#0x1_ordered_map_internal_lower_bound">ordered_map::internal_lower_bound</a>(&node.children, key);
    <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">ordered_map::iter_is_end</a>(&child_lower_bound, &node.children)) {
        <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">IteratorPtrWithPath</a> { iterator: <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(self), path: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>() }
    } <b>else</b> {
        <b>let</b> iter_key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&child_lower_bound, &node.children);

        <b>if</b> (&iter_key == key) {
            <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">IteratorPtrWithPath</a> { iterator: <a href="big_ordered_map.md#0x1_big_ordered_map_new_iter">new_iter</a>(leaf, child_lower_bound, iter_key), path: leaf_path }
        } <b>else</b> {
            <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">IteratorPtrWithPath</a> { iterator: <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(self), path: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>() }
        }
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_iter_with_path_get_iter"></a>

## Function `iter_with_path_get_iter`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_with_path_get_iter">iter_with_path_get_iter</a>&lt;K: <b>copy</b>, drop, store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">big_ordered_map::IteratorPtrWithPath</a>&lt;K&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_with_path_get_iter">iter_with_path_get_iter</a>&lt;K: drop + <b>copy</b> + store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">IteratorPtrWithPath</a>&lt;K&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt; {
    self.iterator
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_contains"></a>

## Function `contains`

Returns true iff the key exists in the map.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_contains">contains</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_contains">contains</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): bool {
    <b>let</b> internal_lower_bound = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_lower_bound">internal_lower_bound</a>(self, key);
    <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&internal_lower_bound, self)) {
        <b>false</b>
    } <b>else</b> {
        <b>let</b> iter_key = <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&internal_lower_bound);
        iter_key == key
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_borrow"></a>

## Function `borrow`

Returns a reference to the element with its key, aborts if the key is not found.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow">borrow</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): &V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow">borrow</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): &V {
    <b>let</b> iter = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_find">internal_find</a>(self, key);
    <b>assert</b>!(!<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&iter, self), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>));

    <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow">iter_borrow</a>(iter, self)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_get"></a>

## Function `get`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_get">get</a>&lt;K: <b>copy</b>, drop, store, V: <b>copy</b>, store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_get">get</a>&lt;K: drop + <b>copy</b> + store, V: <b>copy</b> + store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): Option&lt;V&gt; {
    <b>let</b> iter = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_find">internal_find</a>(self, key);
    <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&iter, self)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(*<a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow">iter_borrow</a>(iter, self))
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_get_and_map"></a>

## Function `get_and_map`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_get_and_map">get_and_map</a>&lt;K: <b>copy</b>, drop, store, V: <b>copy</b>, store, R&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K, f: |&V|R): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;R&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_get_and_map">get_and_map</a>&lt;K: drop + <b>copy</b> + store, V: <b>copy</b> + store, R&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K, f: |&V|R): Option&lt;R&gt; {
    <b>let</b> iter = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_find">internal_find</a>(self, key);
    <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&iter, self)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(f(<a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow">iter_borrow</a>(iter, self)))
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_borrow_mut"></a>

## Function `borrow_mut`

Returns a mutable reference to the element with its key at the given index, aborts if the key is not found.
Aborts with EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE if KV size doesn't have constant size,
because if it doesn't we cannot assert invariants on the size.
In case of variable size, use either <code>borrow</code>, <code><b>copy</b></code> then <code>upsert</code>, or <code>remove</code> and <code>add</code> instead of mutable borrow.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_mut">borrow_mut</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): &<b>mut</b> V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_mut">borrow_mut</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): &<b>mut</b> V {
    <b>let</b> iter = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_find">internal_find</a>(self, key);
    <b>assert</b>!(!<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&iter, self), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>));
    <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_mut">iter_borrow_mut</a>(iter, self)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_borrow_front"></a>

## Function `borrow_front`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_front">borrow_front</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): (K, &V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_front">borrow_front</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): (K, &V) {
    <b>let</b> it = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_begin_iter">internal_new_begin_iter</a>(self);
    <b>let</b> key = *<a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&it);
    (key, <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow">iter_borrow</a>(it, self))
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_borrow_back"></a>

## Function `borrow_back`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_back">borrow_back</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): (K, &V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_back">borrow_back</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): (K, &V) {
    <b>let</b> it = <a href="big_ordered_map.md#0x1_big_ordered_map_iter_prev">iter_prev</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(self), self);
    <b>let</b> key = *<a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&it);
    (key, <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow">iter_borrow</a>(it, self))
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_prev_key"></a>

## Function `prev_key`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_prev_key">prev_key</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_prev_key">prev_key</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): Option&lt;K&gt; {
    <b>let</b> it = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_lower_bound">internal_lower_bound</a>(self, key);
    <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_begin">iter_is_begin</a>(&it, self)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <b>let</b> prev_it = <a href="big_ordered_map.md#0x1_big_ordered_map_iter_prev">iter_prev</a>(it, self);
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(*<a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&prev_it))
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_next_key"></a>

## Function `next_key`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_next_key">next_key</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_next_key">next_key</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): Option&lt;K&gt; {
    <b>let</b> it = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_lower_bound">internal_lower_bound</a>(self, key);
    <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&it, self)) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
    } <b>else</b> {
        <b>let</b> cur_key = <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&it);
        <b>if</b> (key == cur_key) {
            <b>let</b> next_it = <a href="big_ordered_map.md#0x1_big_ordered_map_iter_next">iter_next</a>(it, self);
            <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&next_it, self)) {
                <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
            } <b>else</b> {
                <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(*<a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&next_it))
            }
        } <b>else</b> {
            <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(*cur_key)
        }
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_to_ordered_map"></a>

## Function `to_ordered_map`

Convert a BigOrderedMap to an OrderedMap, which is supposed to be called mostly by view functions to get an atomic
view of the whole map.
Disclaimer: This function may be costly as the BigOrderedMap may be huge in size. Use it at your own discretion.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_to_ordered_map">to_ordered_map</a>&lt;K: <b>copy</b>, drop, store, V: <b>copy</b>, store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_to_ordered_map">to_ordered_map</a>&lt;K: drop + <b>copy</b> + store, V: <b>copy</b> + store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): OrderedMap&lt;K, V&gt; {
    <b>let</b> result = <a href="ordered_map.md#0x1_ordered_map_new">ordered_map::new</a>();
    <b>let</b> result_ref = &<b>mut</b> result;
    <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_ref">for_each_ref</a>(self, |k, v| {
        <b>let</b> iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(result_ref);
        <a href="ordered_map.md#0x1_ordered_map_iter_add">ordered_map::iter_add</a>(iter, result_ref, *k, *v);
    });
    result
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_keys"></a>

## Function `keys`

Get all keys.

For a large enough BigOrderedMap this function will fail due to execution gas limits,
use iterartor or next_key/prev_key to iterate over across portion of the map.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_keys">keys</a>&lt;K: <b>copy</b>, drop, store, V: <b>copy</b>, store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_keys">keys</a>&lt;K: store + <b>copy</b> + drop, V: store + <b>copy</b>&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;K&gt; {
    <b>let</b> result = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[];
    <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_ref">for_each_ref</a>(self, |k, _v| {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> result, *k);
    });
    result
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_for_each_and_clear"></a>

## Function `for_each_and_clear`

Apply the function to each element in the vector, consuming it, leaving the map empty.

Current implementation is O(n * log(n)). After function values will be optimized
to O(n).


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_and_clear">for_each_and_clear</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, f: |(K, V)|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_and_clear">for_each_and_clear</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, f: |K, V|) {
    // TODO - this can be done more efficiently, by destroying the leaves directly
    // but that <b>requires</b> more complicated <a href="code.md#0x1_code">code</a> and testing.
    <b>while</b> (!<a href="big_ordered_map.md#0x1_big_ordered_map_is_empty">is_empty</a>(self)) {
        <b>let</b> (k, v) = <a href="big_ordered_map.md#0x1_big_ordered_map_pop_front">pop_front</a>(self);
        f(k, v);
    };
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_for_each"></a>

## Function `for_each`

Apply the function to each element in the vector, consuming it, and consuming the map

Current implementation is O(n * log(n)). After function values will be optimized
to O(n).


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_for_each">for_each</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, f: |(K, V)|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_for_each">for_each</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, f: |K, V|) {
    // TODO - this can be done more efficiently, by destroying the leaves directly
    // but that <b>requires</b> more complicated <a href="code.md#0x1_code">code</a> and testing.
    <b>let</b> map_mut = self;
    <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_and_clear">for_each_and_clear</a>(&<b>mut</b> map_mut, |k, v| f(k, v));
    <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty">destroy_empty</a>(map_mut)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_for_each_ref"></a>

## Function `for_each_ref`

Apply the function to a reference of each element in the vector.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_ref">for_each_ref</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, f: |(&K, &V)|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_ref">for_each_ref</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, f: |&K, &V|) {
    <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_leaf_node_children_ref">for_each_leaf_node_children_ref</a>(self, |children| {
        <a href="ordered_map.md#0x1_ordered_map_for_each_ref">ordered_map::for_each_ref</a>(children, |k, v| {
            f(k, <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_borrow_value">internal_leaf_borrow_value</a>(v));
        });
    })
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_intersection_zip_for_each_ref"></a>

## Function `intersection_zip_for_each_ref`

Calls given function on a tuple (key, self[key], other[key]) for all keys present in both maps.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_intersection_zip_for_each_ref">intersection_zip_for_each_ref</a>&lt;K: <b>copy</b>, drop, store, V1: store, V2: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V1&gt;, other: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V2&gt;, f: |(&K, &V1, &V2)|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_intersection_zip_for_each_ref">intersection_zip_for_each_ref</a>&lt;K: drop + <b>copy</b> + store, V1: store, V2: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V1&gt;, other: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V2&gt;, f: |&K, &V1, &V2|) {
    // only roots can have empty children, <b>if</b> maps are not empty, we
    // never need <b>to</b> check on child_iter.iter_is_end on a new iterator.
    <b>if</b> (!<a href="big_ordered_map.md#0x1_big_ordered_map_is_empty">is_empty</a>(self) && !<a href="big_ordered_map.md#0x1_big_ordered_map_is_empty">is_empty</a>(other)) {
        <b>let</b> iter1 = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_new_begin_iter">internal_leaf_new_begin_iter</a>(self);
        <b>let</b> iter2 = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_new_begin_iter">internal_leaf_new_begin_iter</a>(other);
        <b>let</b> (children1, iter1) = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_borrow_entries_and_next_leaf_index">internal_leaf_iter_borrow_entries_and_next_leaf_index</a>(iter1, self);
        <b>let</b> (children2, iter2) = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_borrow_entries_and_next_leaf_index">internal_leaf_iter_borrow_entries_and_next_leaf_index</a>(iter2, other);

        <b>let</b> child_iter1 = <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">ordered_map::internal_new_begin_iter</a>(children1);
        <b>let</b> child_iter2 = <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">ordered_map::internal_new_begin_iter</a>(children2);

        <b>loop</b> {
            <b>let</b> key1 = <a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&child_iter1, children1);
            <b>let</b> key2 = <a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&child_iter2, children2);
            <b>let</b> ordering = <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_compare">cmp::compare</a>(key1, key2);
            <b>let</b> inc1 = <b>false</b>;
            <b>let</b> inc2 = <b>false</b>;
            <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_lt">cmp::is_lt</a>(&ordering)) {
                inc1 = <b>true</b>;
            } <b>else</b> <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_gt">cmp::is_gt</a>(&ordering)) {
                inc2 = <b>true</b>;
            } <b>else</b> {
                f(key1, <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_borrow_value">internal_leaf_borrow_value</a>(<a href="ordered_map.md#0x1_ordered_map_iter_borrow">ordered_map::iter_borrow</a>(<b>copy</b> child_iter1, children1)), <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_borrow_value">internal_leaf_borrow_value</a>(<a href="ordered_map.md#0x1_ordered_map_iter_borrow">ordered_map::iter_borrow</a>(<b>copy</b> child_iter2, children2)));
                inc1 = <b>true</b>;
                inc2 = <b>true</b>;
            };
            <b>if</b> (inc1) {
                child_iter1 = <a href="ordered_map.md#0x1_ordered_map_iter_next">ordered_map::iter_next</a>(child_iter1, children1);
                <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">ordered_map::iter_is_end</a>(&child_iter1, children1)) {
                    <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_is_end">internal_leaf_iter_is_end</a>(&iter1)) {
                        <b>break</b>
                    };
                    <b>let</b> (new_children, new_iter) = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_borrow_entries_and_next_leaf_index">internal_leaf_iter_borrow_entries_and_next_leaf_index</a>(iter1, self);
                    iter1 = new_iter;
                    children1 = new_children;
                    child_iter1 = <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">ordered_map::internal_new_begin_iter</a>(children1);
                };
            };
            <b>if</b> (inc2) {
                child_iter2 = <a href="ordered_map.md#0x1_ordered_map_iter_next">ordered_map::iter_next</a>(child_iter2, children2);
                <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">ordered_map::iter_is_end</a>(&child_iter2, children2)) {
                    <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_is_end">internal_leaf_iter_is_end</a>(&iter2)) {
                        <b>break</b>
                    };
                    <b>let</b> (new_children, new_iter) = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_borrow_entries_and_next_leaf_index">internal_leaf_iter_borrow_entries_and_next_leaf_index</a>(iter2, other);
                    iter2 = new_iter;
                    children2 = new_children;
                    child_iter2 = <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">ordered_map::internal_new_begin_iter</a>(children2);
                };
            };
        }
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_for_each_mut"></a>

## Function `for_each_mut`

Apply the function to a mutable reference of each key-value pair in the map.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_mut">for_each_mut</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, f: |(&K, &<b>mut</b> V)|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_mut">for_each_mut</a>&lt;K: <b>copy</b> + drop + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, f: |&K, &<b>mut</b> V|) {
    <b>let</b> iter = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_begin_iter">internal_new_begin_iter</a>(self);
    <b>while</b> (!<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&iter, self)) {
        <b>let</b> key = *<a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&iter);
        f(&key, <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_mut">iter_borrow_mut</a>(iter, self));
        iter = <a href="big_ordered_map.md#0x1_big_ordered_map_iter_next">iter_next</a>(iter, self);
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_destroy"></a>

## Function `destroy`

Destroy a map, by destroying elements individually.

Current implementation is O(n * log(n)). After function values will be optimized
to O(n).


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_destroy">destroy</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, dv: |V|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_destroy">destroy</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, dv: |V|) {
    <a href="big_ordered_map.md#0x1_big_ordered_map_for_each">for_each</a>(self, |_k, v| {
        dv(v);
    });
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_internal_new_begin_iter"></a>

## Function `internal_new_begin_iter`

Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
For direct usage of this method, check Warning at the top of the file corresponding to iterators.

Returns the begin iterator.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_begin_iter">internal_new_begin_iter</a>&lt;K: <b>copy</b>, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_begin_iter">internal_new_begin_iter</a>&lt;K: <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt; {
    <b>if</b> (<a href="big_ordered_map.md#0x1_big_ordered_map_is_empty">is_empty</a>(self)) {
        <b>return</b> <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a> {
            tag: 1,
            End: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<b>true</b>),
            Some: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>(),
        }
    };

    <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(self, self.min_leaf_index);
    <b>assert</b>!(!<a href="ordered_map.md#0x1_ordered_map_is_empty">ordered_map::is_empty</a>(&node.children), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
    <b>let</b> begin_child_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">ordered_map::internal_new_begin_iter</a>(&node.children);
    <b>let</b> begin_child_key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&begin_child_iter, &node.children);
    <a href="big_ordered_map.md#0x1_big_ordered_map_new_iter">new_iter</a>(self.min_leaf_index, begin_child_iter, begin_child_key)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_internal_new_end_iter"></a>

## Function `internal_new_end_iter`

Warning: Marked as internal, as it is safer to utilize provided inline functions instead.
For direct usage of this method, check Warning at the top of the file corresponding to iterators.

Returns the end iterator.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>&lt;K: <b>copy</b>, store, V: store&gt;(_self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>&lt;K: <b>copy</b> + store, V: store&gt;(_self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt; {
    <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a> {
        tag: 1,
        End: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<b>true</b>),
        Some: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>(),
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_iter_is_begin"></a>

## Function `iter_is_begin`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_begin">iter_is_begin</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;, map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_begin">iter_is_begin</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt;, map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): bool {
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End)) {
        <a href="big_ordered_map.md#0x1_big_ordered_map_is_empty">is_empty</a>(map)
    } <b>else</b> {
        <b>let</b> some_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Some);
        (some_data.node_index == map.min_leaf_index && <a href="ordered_map.md#0x1_ordered_map_iter_is_begin_from_non_empty">ordered_map::iter_is_begin_from_non_empty</a>(&some_data.child_iter))
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_iter_is_end"></a>

## Function `iter_is_end`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;, _map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt;, _map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): bool {
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_iter_borrow_key"></a>

## Function `iter_borrow_key`

Borrows the key given iterator points to.
Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
Note: Requires that the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>&lt;K&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;): &K
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>&lt;K&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt;): &K {
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));
    <b>let</b> some_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Some);
    &some_data.key
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_iter_borrow"></a>

## Function `iter_borrow`

Borrows the value given iterator points to.
Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
Note: Requires that the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow">iter_borrow</a>&lt;K: drop, store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;, map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): &V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow">iter_borrow</a>&lt;K: drop + store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt;, map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): &V {
    <b>assert</b>!(!<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&self, map), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));
    <b>let</b> some_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Some);
    <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(map, some_data.node_index);
    <b>let</b> child = <a href="ordered_map.md#0x1_ordered_map_iter_borrow">ordered_map::iter_borrow</a>(some_data.child_iter, &node.children);
    <b>let</b> leaf_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&child.Leaf);
    &leaf_data.value
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_iter_borrow_mut"></a>

## Function `iter_borrow_mut`

Mutably borrows the value iterator points to.
Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
Aborts with EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE if KV size doesn't have constant size,
because if it doesn't we cannot assert invariants on the size.
In case of variable size, use either <code>borrow</code>, <code><b>copy</b></code> then <code>upsert</code>, or <code>remove</code> and <code>add</code> instead of mutable borrow.

Note: Requires that the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_mut">iter_borrow_mut</a>&lt;K: drop, store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;, map: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): &<b>mut</b> V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_mut">iter_borrow_mut</a>&lt;K: drop + store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt;, map: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): &<b>mut</b> V {
    <b>let</b> value_size_opt = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_constant_serialized_size">bcs::constant_serialized_size</a>&lt;V&gt;();
    <b>let</b> has_const_value = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&value_size_opt);
    <b>if</b> (has_const_value) {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(value_size_opt);
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(value_size_opt);
    };
    <b>assert</b>!(map.constant_kv_size || has_const_value, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE">EBORROW_MUT_REQUIRES_CONSTANT_VALUE_SIZE</a>));
    <b>assert</b>!(!<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&self, map), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));
    <b>let</b> some_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Some);
    <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node_mut">borrow_node_mut</a>(map, some_data.node_index);
    <b>let</b> child = <a href="ordered_map.md#0x1_ordered_map_iter_borrow_mut">ordered_map::iter_borrow_mut</a>(some_data.child_iter, &<b>mut</b> node.children);
    <b>let</b> leaf_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow_mut">option::borrow_mut</a>(&<b>mut</b> child.Leaf);
    &<b>mut</b> leaf_data.value
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_iter_modify"></a>

## Function `iter_modify`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_modify">iter_modify</a>&lt;K: <b>copy</b>, drop, store, V: store, R&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;, map: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, f: |&<b>mut</b> V|R): R
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_modify">iter_modify</a>&lt;K: drop + <b>copy</b> + store, V: store, R&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt;, map: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, f: |&<b>mut</b> V|R): R {
    <b>assert</b>!(!<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&self, map), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));
    <b>let</b> key = *<a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_key">iter_borrow_key</a>(&self);
    <b>let</b> value_mut = <a href="big_ordered_map.md#0x1_big_ordered_map_iter_borrow_mut">iter_borrow_mut</a>(self, map);
    <b>let</b> result = f(value_mut);

    <b>if</b> (map.constant_kv_size) {
        <b>return</b> result
    };

    // validate that after modifications size invariants hold
    <b>let</b> key_size = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_serialized_size">bcs::serialized_size</a>(&key);
    <b>let</b> value_size = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_serialized_size">bcs::serialized_size</a>(value_mut);
    <a href="big_ordered_map.md#0x1_big_ordered_map_validate_size_and_init_max_degrees">validate_size_and_init_max_degrees</a>(map, key_size, value_size);
    result
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_iter_remove"></a>

## Function `iter_remove`

Removes the entry from BigOrderedMap and returns the value which <code>key</code> maps to.
Aborts if there is no entry for <code>key</code>.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_remove">iter_remove</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">big_ordered_map::IteratorPtrWithPath</a>&lt;K&gt;, map: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_remove">iter_remove</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">IteratorPtrWithPath</a>&lt;K&gt;, map: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): V {
    <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrWithPath">IteratorPtrWithPath</a> { iterator: iter, path: path_to_leaf } = self;
    <b>assert</b>!(!<a href="big_ordered_map.md#0x1_big_ordered_map_iter_is_end">iter_is_end</a>(&iter, map), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));
    <b>let</b> some_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&iter.Some);
    <b>let</b> child_iter = some_data.child_iter;
    <b>let</b> key = some_data.key;

    // Optimize case <b>where</b> only root node <b>exists</b>
    // (optimizes out borrowing and path creation in `find_leaf_path`)
    <b>let</b> root = &map.root;
    <b>if</b> (root.is_leaf) {
        <b>let</b> root_mut = &<b>mut</b> map.root;
        <b>let</b> child = <a href="ordered_map.md#0x1_ordered_map_iter_remove">ordered_map::iter_remove</a>(child_iter, &<b>mut</b> root_mut.children);
        <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> { tag: _, Inner: inner, Leaf: leaf } = child;
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(inner);
        <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ChildLeafData">ChildLeafData</a> { value } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(leaf);
        <b>return</b> value
    };

    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&path_to_leaf), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_NOT_FOUND">EKEY_NOT_FOUND</a>));

    <b>let</b> child = <a href="big_ordered_map.md#0x1_big_ordered_map_remove_at">remove_at</a>(map, path_to_leaf, &key);
    <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> { tag: _, Inner: inner, Leaf: leaf } = child;
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(inner);
    <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ChildLeafData">ChildLeafData</a> { value } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(leaf);
    value
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_iter_next"></a>

## Function `iter_next`

Returns the next iterator.
Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the end.
Requires the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_next">iter_next</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;, map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_next">iter_next</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt;, map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt; {
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));

    <b>let</b> some_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Some);
    <b>let</b> node_index = some_data.node_index;
    <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(map, node_index);

    <b>let</b> child_iter = <a href="ordered_map.md#0x1_ordered_map_iter_next">ordered_map::iter_next</a>(some_data.child_iter, &node.children);
    <b>if</b> (!<a href="ordered_map.md#0x1_ordered_map_iter_is_end">ordered_map::iter_is_end</a>(&child_iter, &node.children)) {
        // next is in the same leaf node
        <b>let</b> iter_key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&child_iter, &node.children);
        <b>return</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_iter">new_iter</a>(node_index, child_iter, iter_key)
    };

    // next is in a different leaf node
    <b>let</b> next_index = node.next;
    <b>if</b> (next_index != <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>) {
        <b>let</b> next_node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(map, next_index);
        <b>let</b> child_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">ordered_map::internal_new_begin_iter</a>(&next_node.children);
        <b>assert</b>!(!<a href="ordered_map.md#0x1_ordered_map_iter_is_end">ordered_map::iter_is_end</a>(&child_iter, &next_node.children), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
        <b>let</b> iter_key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&child_iter, &next_node.children);
        <b>return</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_iter">new_iter</a>(next_index, child_iter, iter_key)
    };

    <a href="big_ordered_map.md#0x1_big_ordered_map_internal_new_end_iter">internal_new_end_iter</a>(map)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_iter_prev"></a>

## Function `iter_prev`

Returns the previous iterator.
Aborts with EITER_OUT_OF_BOUNDS if iterator is pointing to the beginning.
Requires the map is not changed after the input iterator is generated.


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_prev">iter_prev</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;, map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_iter_prev">iter_prev</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt;, map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt; {
    <b>let</b> prev_index = <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&self.End)) {
        map.max_leaf_index
    } <b>else</b> {
        <b>let</b> some_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Some);
        <b>let</b> node_index = some_data.node_index;
        <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(map, node_index);

        <b>if</b> (!<a href="ordered_map.md#0x1_ordered_map_iter_is_begin">ordered_map::iter_is_begin</a>(&some_data.child_iter, &node.children)) {
            // next is in the same leaf node
            <b>let</b> child_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(some_data.child_iter, &node.children);
            <b>let</b> key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&child_iter, &node.children);
            <b>return</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_iter">new_iter</a>(node_index, child_iter, key)
        };
        node.prev
    };

    <b>assert</b>!(prev_index != <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>));

    // next is in a different leaf node
    <b>let</b> prev_node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(map, prev_index);
    <b>let</b> prev_children = &prev_node.children;
    <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(prev_children);
    <b>let</b> child_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(end_iter, prev_children);
    <b>let</b> iter_key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&child_iter, prev_children);
    <a href="big_ordered_map.md#0x1_big_ordered_map_new_iter">new_iter</a>(prev_index, child_iter, iter_key)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_internal_leaf_new_begin_iter"></a>

## Function `internal_leaf_new_begin_iter`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_new_begin_iter">internal_leaf_new_begin_iter</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">big_ordered_map::LeafNodeIteratorPtr</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_new_begin_iter">internal_leaf_new_begin_iter</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">LeafNodeIteratorPtr</a> {
    <a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">LeafNodeIteratorPtr</a> {
        tag: 1,
        NodeIndex: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtrNodeIndexData">LeafNodeIteratorPtrNodeIndexData</a> { node_index: self.min_leaf_index }),
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_internal_leaf_iter_is_end"></a>

## Function `internal_leaf_iter_is_end`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_is_end">internal_leaf_iter_is_end</a>(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">big_ordered_map::LeafNodeIteratorPtr</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_is_end">internal_leaf_iter_is_end</a>(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">LeafNodeIteratorPtr</a>): bool {
    <b>let</b> node_index_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.NodeIndex);
    node_index_data.node_index == <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_internal_leaf_borrow_value"></a>

## Function `internal_leaf_borrow_value`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_borrow_value">internal_leaf_borrow_value</a>&lt;V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;): &V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_borrow_value">internal_leaf_borrow_value</a>&lt;V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt;): &V {
    <b>let</b> leaf_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.Leaf);
    &leaf_data.value
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_internal_leaf_iter_borrow_entries_and_next_leaf_index"></a>

## Function `internal_leaf_iter_borrow_entries_and_next_leaf_index`



<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_borrow_entries_and_next_leaf_index">internal_leaf_iter_borrow_entries_and_next_leaf_index</a>&lt;K: store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">big_ordered_map::LeafNodeIteratorPtr</a>, map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;): (&<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;&gt;, <a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">big_ordered_map::LeafNodeIteratorPtr</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_borrow_entries_and_next_leaf_index">internal_leaf_iter_borrow_entries_and_next_leaf_index</a>&lt;K: store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">LeafNodeIteratorPtr</a>, map: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): (&OrderedMap&lt;K, <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt;&gt;, <a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">LeafNodeIteratorPtr</a>) {
    <b>let</b> node_index_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&self.NodeIndex);
    <b>assert</b>!(node_index_data.node_index != <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>, <a href="big_ordered_map.md#0x1_big_ordered_map_EITER_OUT_OF_BOUNDS">EITER_OUT_OF_BOUNDS</a>);

    <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(map, node_index_data.node_index);
    <b>assert</b>!(node.is_leaf, <a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>);
    <b>let</b> new_iter = <a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtr">LeafNodeIteratorPtr</a> {
        tag: 1,
        NodeIndex: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_LeafNodeIteratorPtrNodeIndexData">LeafNodeIteratorPtrNodeIndexData</a> { node_index: node.next }),
    };
    (&node.children, new_iter)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_for_each_leaf_node_children_ref"></a>

## Function `for_each_leaf_node_children_ref`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_leaf_node_children_ref">for_each_leaf_node_children_ref</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, f: |&<a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;&gt;|())
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_for_each_leaf_node_children_ref">for_each_leaf_node_children_ref</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, f: |&OrderedMap&lt;K, <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt;&gt;|) {
    <b>let</b> iter = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_new_begin_iter">internal_leaf_new_begin_iter</a>(self);

    <b>while</b> (!<a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_is_end">internal_leaf_iter_is_end</a>(&iter)) {
        <b>let</b> (node, next_iter) = <a href="big_ordered_map.md#0x1_big_ordered_map_internal_leaf_iter_borrow_entries_and_next_leaf_index">internal_leaf_iter_borrow_entries_and_next_leaf_index</a>(iter, self);
        f(node);
        iter = next_iter;
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_borrow_node"></a>

## Function `borrow_node`

Borrow a node, given an index. Works for both root (i.e. inline) node and separately stored nodes


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, node_index: u64): &<a href="big_ordered_map.md#0x1_big_ordered_map_Node">big_ordered_map::Node</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, node_index: u64): &<a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a>&lt;K, V&gt; {
    <b>if</b> (node_index == <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>) {
        &self.root
    } <b>else</b> {
        <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_borrow">storage_slots_allocator::borrow</a>(&self.nodes, node_index)
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_borrow_node_mut"></a>

## Function `borrow_node_mut`

Borrow a node mutably, given an index. Works for both root (i.e. inline) node and separately stored nodes


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node_mut">borrow_node_mut</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, node_index: u64): &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Node">big_ordered_map::Node</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>inline <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node_mut">borrow_node_mut</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, node_index: u64): &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a>&lt;K, V&gt; {
    <b>if</b> (node_index == <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>) {
        &<b>mut</b> self.root
    } <b>else</b> {
        <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_borrow_mut">storage_slots_allocator::borrow_mut</a>(&<b>mut</b> self.nodes, node_index)
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_add_or_upsert_impl"></a>

## Function `add_or_upsert_impl`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_add_or_upsert_impl">add_or_upsert_impl</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: K, value: V, allow_overwrite: bool): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_add_or_upsert_impl">add_or_upsert_impl</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: K, value: V, allow_overwrite: bool): Option&lt;<a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt;&gt; {
    <b>if</b> (!self.constant_kv_size) {
        <a href="big_ordered_map.md#0x1_big_ordered_map_validate_dynamic_size_and_init_max_degrees">validate_dynamic_size_and_init_max_degrees</a>(self, &key, &value);
    };

    // Optimize case <b>where</b> only root node <b>exists</b>
    // (optimizes out borrowing and path creation in `find_leaf_path`)
    <b>if</b> (self.root.is_leaf) {
        <b>let</b> leaf_max_degree = self.leaf_max_degree;
        <b>let</b> root_mut = &<b>mut</b> self.root;
        <b>let</b> children = &<b>mut</b> root_mut.children;
        <b>let</b> degree = <a href="ordered_map.md#0x1_ordered_map_length">ordered_map::length</a>(children);

        <b>if</b> (degree &lt; leaf_max_degree) {
            <b>let</b> result = <a href="ordered_map.md#0x1_ordered_map_upsert">ordered_map::upsert</a>(children, key, <a href="big_ordered_map.md#0x1_big_ordered_map_new_leaf_child">new_leaf_child</a>(value));
            <b>assert</b>!(allow_overwrite || <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_none">option::is_none</a>(&result), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_ALREADY_EXISTS">EKEY_ALREADY_EXISTS</a>));
            <b>return</b> result
        };
    };

    <b>let</b> path_to_leaf = <a href="big_ordered_map.md#0x1_big_ordered_map_find_leaf_path">find_leaf_path</a>(self, &key);

    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&path_to_leaf)) {
        // In this case, the key is greater than all keys in the map.
        // So we need <b>to</b> <b>update</b> `key` in the pointers <b>to</b> the last (rightmost) child
        // on every level, <b>to</b> maintain the <b>invariant</b> of `add_at`
        // we also create a path_to_leaf <b>to</b> the rightmost leaf.
        <b>let</b> current = <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>;

        <b>loop</b> {
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> path_to_leaf, current);

            <b>let</b> current_node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node_mut">borrow_node_mut</a>(self, current);
            <b>if</b> (current_node.is_leaf) {
                <b>break</b>
            };
            <b>let</b> last_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(
                <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(&current_node.children),
                &current_node.children,
            );
            <b>let</b> last_value = <a href="ordered_map.md#0x1_ordered_map_iter_remove">ordered_map::iter_remove</a>(last_iter, &<b>mut</b> current_node.children);
            <b>let</b> inner_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&last_value.Inner);
            current = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_stored_to_index">storage_slots_allocator::stored_to_index</a>(&inner_data.node_index);
            <a href="ordered_map.md#0x1_ordered_map_add">ordered_map::add</a>(&<b>mut</b> current_node.children, key, last_value);
        };
    };

    <a href="big_ordered_map.md#0x1_big_ordered_map_add_at">add_at</a>(self, path_to_leaf, key, <a href="big_ordered_map.md#0x1_big_ordered_map_new_leaf_child">new_leaf_child</a>(value), allow_overwrite)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_validate_dynamic_size_and_init_max_degrees"></a>

## Function `validate_dynamic_size_and_init_max_degrees`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_validate_dynamic_size_and_init_max_degrees">validate_dynamic_size_and_init_max_degrees</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K, value: &V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_validate_dynamic_size_and_init_max_degrees">validate_dynamic_size_and_init_max_degrees</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K, value: &V) {
    <b>let</b> key_size = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_serialized_size">bcs::serialized_size</a>(key);
    <b>let</b> value_size = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_serialized_size">bcs::serialized_size</a>(value);
    <a href="big_ordered_map.md#0x1_big_ordered_map_validate_size_and_init_max_degrees">validate_size_and_init_max_degrees</a>(self, key_size, value_size)
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_validate_static_size_and_init_max_degrees"></a>

## Function `validate_static_size_and_init_max_degrees`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_validate_static_size_and_init_max_degrees">validate_static_size_and_init_max_degrees</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_validate_static_size_and_init_max_degrees">validate_static_size_and_init_max_degrees</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;) {
    <b>let</b> key_size_opt = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_constant_serialized_size">bcs::constant_serialized_size</a>&lt;K&gt;();

    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&key_size_opt)) {
        <b>let</b> key_size = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(key_size_opt);
        <b>if</b> (self.inner_max_degree == 0) {
            self.inner_max_degree = max(<b>min</b>(<a href="big_ordered_map.md#0x1_big_ordered_map_MAX_DEGREE">MAX_DEGREE</a>, <a href="big_ordered_map.md#0x1_big_ordered_map_DEFAULT_TARGET_NODE_SIZE">DEFAULT_TARGET_NODE_SIZE</a> / key_size), <a href="big_ordered_map.md#0x1_big_ordered_map_INNER_MIN_DEGREE">INNER_MIN_DEGREE</a>);
        };
        <b>assert</b>!(key_size * self.inner_max_degree &lt;= <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_NODE_BYTES">MAX_NODE_BYTES</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_BYTES_TOO_LARGE">EKEY_BYTES_TOO_LARGE</a>));

        <b>let</b> value_size_opt = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_constant_serialized_size">bcs::constant_serialized_size</a>&lt;V&gt;();
        <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(&value_size_opt)) {
            <b>let</b> value_size = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(value_size_opt);
            <b>let</b> entry_size = key_size + value_size;

            <b>if</b> (self.leaf_max_degree == 0) {
                self.leaf_max_degree = max(<b>min</b>(<a href="big_ordered_map.md#0x1_big_ordered_map_MAX_DEGREE">MAX_DEGREE</a>, <a href="big_ordered_map.md#0x1_big_ordered_map_DEFAULT_TARGET_NODE_SIZE">DEFAULT_TARGET_NODE_SIZE</a> / entry_size), <a href="big_ordered_map.md#0x1_big_ordered_map_LEAF_MIN_DEGREE">LEAF_MIN_DEGREE</a>);
            };
            <b>assert</b>!(entry_size * self.leaf_max_degree &lt;= <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_NODE_BYTES">MAX_NODE_BYTES</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EARGUMENT_BYTES_TOO_LARGE">EARGUMENT_BYTES_TOO_LARGE</a>));

            self.constant_kv_size = <b>true</b>;
        } <b>else</b> {
            <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(value_size_opt);
        };
    } <b>else</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(key_size_opt);
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_validate_size_and_init_max_degrees"></a>

## Function `validate_size_and_init_max_degrees`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_validate_size_and_init_max_degrees">validate_size_and_init_max_degrees</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key_size: u64, value_size: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_validate_size_and_init_max_degrees">validate_size_and_init_max_degrees</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key_size: u64, value_size: u64) {
    <b>let</b> entry_size = key_size + value_size;

    <b>if</b> (self.inner_max_degree == 0) {
        <b>let</b> default_max_degree = <b>min</b>(<a href="big_ordered_map.md#0x1_big_ordered_map_MAX_DEGREE">MAX_DEGREE</a>, <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_NODE_BYTES">MAX_NODE_BYTES</a> / <a href="big_ordered_map.md#0x1_big_ordered_map_DEFAULT_MAX_KEY_OR_VALUE_SIZE">DEFAULT_MAX_KEY_OR_VALUE_SIZE</a>);
        self.inner_max_degree = max(<b>min</b>(default_max_degree, <a href="big_ordered_map.md#0x1_big_ordered_map_DEFAULT_TARGET_NODE_SIZE">DEFAULT_TARGET_NODE_SIZE</a> / key_size), <a href="big_ordered_map.md#0x1_big_ordered_map_INNER_MIN_DEGREE">INNER_MIN_DEGREE</a>);
    };

    <b>if</b> (self.leaf_max_degree == 0) {
        <b>let</b> default_max_degree = <b>min</b>(<a href="big_ordered_map.md#0x1_big_ordered_map_MAX_DEGREE">MAX_DEGREE</a>, <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_NODE_BYTES">MAX_NODE_BYTES</a> / <a href="big_ordered_map.md#0x1_big_ordered_map_DEFAULT_MAX_KEY_OR_VALUE_SIZE">DEFAULT_MAX_KEY_OR_VALUE_SIZE</a> / 2);
        self.leaf_max_degree = max(<b>min</b>(default_max_degree, <a href="big_ordered_map.md#0x1_big_ordered_map_DEFAULT_TARGET_NODE_SIZE">DEFAULT_TARGET_NODE_SIZE</a> / entry_size), <a href="big_ordered_map.md#0x1_big_ordered_map_LEAF_MIN_DEGREE">LEAF_MIN_DEGREE</a>);
    };

    // Make sure that no nodes can exceed the upper size limit.
    <b>assert</b>!(key_size * self.inner_max_degree &lt;= <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_NODE_BYTES">MAX_NODE_BYTES</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_BYTES_TOO_LARGE">EKEY_BYTES_TOO_LARGE</a>));
    <b>assert</b>!(entry_size * self.leaf_max_degree &lt;= <a href="big_ordered_map.md#0x1_big_ordered_map_MAX_NODE_BYTES">MAX_NODE_BYTES</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EARGUMENT_BYTES_TOO_LARGE">EARGUMENT_BYTES_TOO_LARGE</a>));
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_destroy_inner_child"></a>

## Function `destroy_inner_child`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_inner_child">destroy_inner_child</a>&lt;V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;): <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_StoredSlot">storage_slots_allocator::StoredSlot</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_inner_child">destroy_inner_child</a>&lt;V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt;): StoredSlot {
    <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> { tag: _, Inner: inner, Leaf: leaf } = self;
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(leaf);
    <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_ChildInnerData">ChildInnerData</a> { node_index } = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_some">option::destroy_some</a>(inner);
    node_index
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_destroy_empty_node"></a>

## Function `destroy_empty_node`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty_node">destroy_empty_node</a>&lt;K: store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_Node">big_ordered_map::Node</a>&lt;K, V&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty_node">destroy_empty_node</a>&lt;K: store, V: store&gt;(self: <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a>&lt;K, V&gt;) {
    <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a> { is_leaf: _, children, prev: _, next: _ } = self;
    <b>assert</b>!(<a href="ordered_map.md#0x1_ordered_map_is_empty">ordered_map::is_empty</a>(&children), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EMAP_NOT_EMPTY">EMAP_NOT_EMPTY</a>));
    <a href="ordered_map.md#0x1_ordered_map_destroy_empty">ordered_map::destroy_empty</a>(children);
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_new_node"></a>

## Function `new_node`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_node">new_node</a>&lt;K: store, V: store&gt;(is_leaf: bool): <a href="big_ordered_map.md#0x1_big_ordered_map_Node">big_ordered_map::Node</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_node">new_node</a>&lt;K: store, V: store&gt;(is_leaf: bool): <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a>&lt;K, V&gt; {
    <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a> {
        is_leaf: is_leaf,
        children: <a href="ordered_map.md#0x1_ordered_map_new">ordered_map::new</a>(),
        prev: <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>,
        next: <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>,
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_new_node_with_children"></a>

## Function `new_node_with_children`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_node_with_children">new_node_with_children</a>&lt;K: store, V: store&gt;(is_leaf: bool, children: <a href="ordered_map.md#0x1_ordered_map_OrderedMap">ordered_map::OrderedMap</a>&lt;K, <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_Node">big_ordered_map::Node</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_node_with_children">new_node_with_children</a>&lt;K: store, V: store&gt;(is_leaf: bool, children: OrderedMap&lt;K, <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt;&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a>&lt;K, V&gt; {
    <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a> {
        is_leaf: is_leaf,
        children: children,
        prev: <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>,
        next: <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>,
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_new_inner_child"></a>

## Function `new_inner_child`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_inner_child">new_inner_child</a>&lt;V: store&gt;(node_index: <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_StoredSlot">storage_slots_allocator::StoredSlot</a>): <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_inner_child">new_inner_child</a>&lt;V: store&gt;(node_index: StoredSlot): <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt; {
    <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> {
        tag: 1,
        Inner: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_ChildInnerData">ChildInnerData</a> { node_index: node_index }),
        Leaf: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>(),
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_new_leaf_child"></a>

## Function `new_leaf_child`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_leaf_child">new_leaf_child</a>&lt;V: store&gt;(value: V): <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_leaf_child">new_leaf_child</a>&lt;V: store&gt;(value: V): <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt; {
    <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> {
        tag: 2,
        Inner: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>(),
        Leaf: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_ChildLeafData">ChildLeafData</a> { value: value }),
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_new_iter"></a>

## Function `new_iter`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_iter">new_iter</a>&lt;K&gt;(node_index: u64, child_iter: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, key: K): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">big_ordered_map::IteratorPtr</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_new_iter">new_iter</a>&lt;K&gt;(node_index: u64, child_iter: <a href="ordered_map.md#0x1_ordered_map_IteratorPtr">ordered_map::IteratorPtr</a>, key: K): <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a>&lt;K&gt; {
    <a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtr">IteratorPtr</a> {
        tag: 2,
        End: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>(),
        Some: <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_IteratorPtrSomeData">IteratorPtrSomeData</a> {
            node_index: node_index,
            child_iter: child_iter,
            key: key,
        }),
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_find_leaf"></a>

## Function `find_leaf`

Find leaf where the given key would fall in.
So the largest leaf with its <code>max_key &lt;= key</code>.
return NULL_INDEX if <code>key</code> is larger than any key currently stored in the map.


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_find_leaf">find_leaf</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_find_leaf">find_leaf</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): u64 {
    <b>let</b> current = <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>;
    <b>loop</b> {
        <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(self, current);
        <b>if</b> (node.is_leaf) {
            <b>return</b> current
        };
        <b>let</b> children = &node.children;
        <b>let</b> child_iter = <a href="ordered_map.md#0x1_ordered_map_internal_lower_bound">ordered_map::internal_lower_bound</a>(children, key);
        <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">ordered_map::iter_is_end</a>(&child_iter, children)) {
            <b>return</b> <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>
        } <b>else</b> {
            <b>let</b> child = <a href="ordered_map.md#0x1_ordered_map_iter_borrow">ordered_map::iter_borrow</a>(child_iter, children);
            <b>let</b> inner_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&child.Inner);
            current = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_stored_to_index">storage_slots_allocator::stored_to_index</a>(&inner_data.node_index);
        };
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_find_leaf_path"></a>

## Function `find_leaf_path`

Find leaf where the given key would fall in.
So the largest leaf with it's <code>max_key &lt;= key</code>.
Returns the path from root to that leaf (including the leaf itself)
Returns empty path if <code>key</code> is larger than any key currently stored in the map.


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_find_leaf_path">find_leaf_path</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_find_leaf_path">find_leaf_path</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: &K): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; {
    <b>let</b> vec = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>();

    <b>let</b> current = <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>;
    <b>loop</b> {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> vec, current);

        <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(self, current);
        <b>if</b> (node.is_leaf) {
            <b>return</b> vec
        };
        <b>let</b> children = &node.children;
        <b>let</b> child_iter = <a href="ordered_map.md#0x1_ordered_map_internal_lower_bound">ordered_map::internal_lower_bound</a>(children, key);
        <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_is_end">ordered_map::iter_is_end</a>(&child_iter, children)) {
            <b>return</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_empty">vector::empty</a>()
        } <b>else</b> {
            <b>let</b> child = <a href="ordered_map.md#0x1_ordered_map_iter_borrow">ordered_map::iter_borrow</a>(child_iter, children);
            <b>let</b> inner_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&child.Inner);
            current = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_stored_to_index">storage_slots_allocator::stored_to_index</a>(&inner_data.node_index);
        };
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_get_max_degree"></a>

## Function `get_max_degree`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_get_max_degree">get_max_degree</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, leaf: bool): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_get_max_degree">get_max_degree</a>&lt;K: store, V: store&gt;(self: &<a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, leaf: bool): u64 {
    <b>if</b> (leaf) {
        self.leaf_max_degree
    } <b>else</b> {
        self.inner_max_degree
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_replace_root"></a>

## Function `replace_root`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_replace_root">replace_root</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, new_root: <a href="big_ordered_map.md#0x1_big_ordered_map_Node">big_ordered_map::Node</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_Node">big_ordered_map::Node</a>&lt;K, V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_replace_root">replace_root</a>&lt;K: store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, new_root: <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a>&lt;K, V&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a>&lt;K, V&gt; {
    <b>let</b> root = &<b>mut</b> self.root;
    <b>let</b> tmp_is_leaf = root.is_leaf;
    root.is_leaf = new_root.is_leaf;
    new_root.is_leaf = tmp_is_leaf;

    <b>assert</b>!(root.prev == <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
    <b>assert</b>!(root.next == <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
    <b>assert</b>!(new_root.prev == <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
    <b>assert</b>!(new_root.next == <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));

    // <b>let</b> tmp_prev = root.prev;
    // root.prev = new_root.prev;
    // new_root.prev = tmp_prev;

    // <b>let</b> tmp_next = root.next;
    // root.next = new_root.next;
    // new_root.next = tmp_next;

    <b>let</b> tmp_children = <a href="ordered_map.md#0x1_ordered_map_trim">ordered_map::trim</a>(&<b>mut</b> root.children, 0);
    <b>let</b> new_root_children_trimmed = <a href="ordered_map.md#0x1_ordered_map_trim">ordered_map::trim</a>(&<b>mut</b> new_root.children, 0);
    <a href="ordered_map.md#0x1_ordered_map_append_disjoint">ordered_map::append_disjoint</a>(&<b>mut</b> root.children, new_root_children_trimmed);
    <a href="ordered_map.md#0x1_ordered_map_append_disjoint">ordered_map::append_disjoint</a>(&<b>mut</b> new_root.children, tmp_children);

    new_root
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_add_at"></a>

## Function `add_at`

Add a given child to a given node (last in the <code>path_to_node</code>), and update/rebalance the tree as necessary.
It is required that <code>key</code> pointers to the child node, on the <code>path_to_node</code> are greater or equal to the given key.
That means if we are adding a <code>key</code> larger than any currently existing in the map - we needed
to update <code>key</code> pointers on the <code>path_to_node</code> to include it, before calling this method.

Returns Child previously associated with the given key.
If <code>allow_overwrite</code> is not set, function will abort if <code>key</code> is already present.


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_add_at">add_at</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, path_to_node: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, key: K, child: <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;, allow_overwrite: bool): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_add_at">add_at</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, path_to_node: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, key: K, child: <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt;, allow_overwrite: bool): Option&lt;<a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt;&gt; {
    // Last node in the path is one <b>where</b> we need <b>to</b> add the child <b>to</b>.
    <b>let</b> node_index = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>(&<b>mut</b> path_to_node);
    {
        // First check <b>if</b> we can perform this operation, without changing structure of the tree (i.e. without adding <a href="../../endless-stdlib/doc/any.md#0x1_any">any</a> nodes).

        // For that we can just borrow the single node
        <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node_mut">borrow_node_mut</a>(self, node_index);
        <b>let</b> children = &<b>mut</b> node.children;
        <b>let</b> degree = <a href="ordered_map.md#0x1_ordered_map_length">ordered_map::length</a>(children);

        // Compute directly, <b>as</b> we cannot <b>use</b> <a href="big_ordered_map.md#0x1_big_ordered_map_get_max_degree">get_max_degree</a>(), <b>as</b> self is already mutably borrowed.
        <b>let</b> max_degree = <b>if</b> (node.is_leaf) {
            self.leaf_max_degree
        } <b>else</b> {
            self.inner_max_degree
        };

        <b>if</b> (degree &lt; max_degree) {
            // Adding a child <b>to</b> a current node doesn't exceed the size, so we can just do that.
            <b>let</b> old_child = <a href="ordered_map.md#0x1_ordered_map_upsert">ordered_map::upsert</a>(children, key, child);

            <b>if</b> (node.is_leaf) {
                <b>assert</b>!(allow_overwrite || <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_none">option::is_none</a>(&old_child), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_ALREADY_EXISTS">EKEY_ALREADY_EXISTS</a>));
                <b>return</b> old_child
            } <b>else</b> {
                <b>assert</b>!(!allow_overwrite && <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_none">option::is_none</a>(&old_child), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
                <b>return</b> old_child
            }
        };

        // If we cannot add more nodes without exceeding the size,
        // but node <b>with</b> `key` already <b>exists</b>, we either need <b>to</b> replace or <b>abort</b>.
        <b>let</b> iter = <a href="ordered_map.md#0x1_ordered_map_internal_find">ordered_map::internal_find</a>(children, &key);
        <b>if</b> (!<a href="ordered_map.md#0x1_ordered_map_iter_is_end">ordered_map::iter_is_end</a>(&iter, children)) {
            <b>assert</b>!(node.is_leaf, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
            <b>assert</b>!(allow_overwrite, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EKEY_ALREADY_EXISTS">EKEY_ALREADY_EXISTS</a>));

            <b>return</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_some">option::some</a>(<a href="ordered_map.md#0x1_ordered_map_iter_replace">ordered_map::iter_replace</a>(iter, children, child))
        }
    };

    // # of children in the current node exceeds the threshold, need <b>to</b> split into two nodes.

    // If we are at the root, we need <b>to</b> <b>move</b> root node <b>to</b> become a child and have a new root node,
    // in order <b>to</b> be able <b>to</b> split the node on the level it is.
    <b>let</b> (reserved_slot, node) = <b>if</b> (node_index == <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>) {
        <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&path_to_node), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));

        // Splitting root now, need <b>to</b> create a new root.
        // Since root is stored direclty in the resource, we will swap-in the new node there.
        <b>let</b> new_root_node = <a href="big_ordered_map.md#0x1_big_ordered_map_new_node">new_node</a>&lt;K, V&gt;(/*is_leaf=*/<b>false</b>);

        // Reserve a slot <b>where</b> the current root will be moved <b>to</b>.
        <b>let</b> (replacement_node_slot, replacement_node_reserved_slot) = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_reserve_slot">storage_slots_allocator::reserve_slot</a>(&<b>mut</b> self.nodes);

        <b>let</b> max_key = {
            <b>let</b> root_children = &self.root.children;
            <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(root_children);
            <b>let</b> prev_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(end_iter, root_children);
            <b>let</b> last_key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&prev_iter, root_children);
            <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_lt">cmp::is_lt</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_compare">cmp::compare</a>(&last_key, &key))) {
                key
            } <b>else</b> {
                last_key
            }
        };
        // New root will have start <b>with</b> a single child - the existing root (which will be at replacement location).
        <a href="ordered_map.md#0x1_ordered_map_add">ordered_map::add</a>(&<b>mut</b> new_root_node.children, max_key, <a href="big_ordered_map.md#0x1_big_ordered_map_new_inner_child">new_inner_child</a>(replacement_node_slot));
        <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_replace_root">replace_root</a>(self, new_root_node);

        // we moved the currently processing node one level down, so we need <b>to</b> <b>update</b> the path
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> path_to_node, <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>);

        <b>let</b> replacement_index = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_reserved_to_index">storage_slots_allocator::reserved_to_index</a>(&replacement_node_reserved_slot);
        <b>if</b> (node.is_leaf) {
            // replacement node is the only leaf, so we <b>update</b> the pointers:
            self.min_leaf_index = replacement_index;
            self.max_leaf_index = replacement_index;
        };
        (replacement_node_reserved_slot, node)
    } <b>else</b> {
        // In order <b>to</b> work on multiple nodes at the same time, we cannot borrow_mut, and need <b>to</b> be
        // remove_and_reserve existing node.
        <b>let</b> (cur_node_reserved_slot, node) = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_remove_and_reserve">storage_slots_allocator::remove_and_reserve</a>(&<b>mut</b> self.nodes, node_index);
        (cur_node_reserved_slot, node)
    };

    // <b>move</b> node_index out of scope, <b>to</b> make sure we don't accidentally access it, <b>as</b> we are done <b>with</b> it.
    // (i.e. we should be using `reserved_slot` instead).
    <b>move</b> node_index;

    // Now we can perform the split at the current level, <b>as</b> we know we are not at the root level.
    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&path_to_node), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));

    // Parent <b>has</b> a reference under max key <b>to</b> the current node, so existing index
    // needs <b>to</b> be the right node.
    // Since <a href="ordered_map.md#0x1_ordered_map_trim">ordered_map::trim</a> moves from the end (i.e. smaller keys stay),
    // we are going <b>to</b> put the contents of the current node on the left side,
    // and create a new right node.
    // So <b>if</b> we had before (node_index, node), we will change that <b>to</b> end up having:
    // (new_left_node_index, node trimmed off) and (node_index, new node <b>with</b> trimmed off children)
    //
    // So <b>let</b>'s rename variables cleanly:
    <b>let</b> right_node_reserved_slot = reserved_slot;
    <b>let</b> left_node = node;

    <b>let</b> is_leaf = left_node.is_leaf;
    <b>let</b> left_children = &<b>mut</b> left_node.children;

    <b>let</b> right_node_index = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_reserved_to_index">storage_slots_allocator::reserved_to_index</a>(&right_node_reserved_slot);
    <b>let</b> left_next = &<b>mut</b> left_node.next;
    <b>let</b> left_prev = &<b>mut</b> left_node.prev;

    // Compute directly, <b>as</b> we cannot <b>use</b> <a href="big_ordered_map.md#0x1_big_ordered_map_get_max_degree">get_max_degree</a>(), <b>as</b> self is already mutably borrowed.
    <b>let</b> max_degree = <b>if</b> (is_leaf) {
        self.leaf_max_degree
    } <b>else</b> {
        self.inner_max_degree
    };
    // compute the target size for the left node:
    <b>let</b> target_size = (max_degree + 1) / 2;

    // Add child (which will exceed the size), and then trim off <b>to</b> create two sets of children of correct sizes.
    <a href="ordered_map.md#0x1_ordered_map_add">ordered_map::add</a>(left_children, key, child);
    <b>let</b> right_node_children = <a href="ordered_map.md#0x1_ordered_map_trim">ordered_map::trim</a>(left_children, target_size);

    <b>assert</b>!(<a href="ordered_map.md#0x1_ordered_map_length">ordered_map::length</a>(left_children) &lt;= max_degree, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
    <b>assert</b>!(<a href="ordered_map.md#0x1_ordered_map_length">ordered_map::length</a>(&right_node_children) &lt;= max_degree, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));

    <b>let</b> right_node = <a href="big_ordered_map.md#0x1_big_ordered_map_new_node_with_children">new_node_with_children</a>(is_leaf, right_node_children);

    <b>let</b> (left_node_slot, left_node_reserved_slot) = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_reserve_slot">storage_slots_allocator::reserve_slot</a>(&<b>mut</b> self.nodes);
    <b>let</b> left_node_index = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_stored_to_index">storage_slots_allocator::stored_to_index</a>(&left_node_slot);

    // right nodes next is the node that was next of the left (previous) node, and next of left node is the right node.
    right_node.next = *left_next;
    *left_next = right_node_index;

    // right node's prev becomes current left node
    right_node.prev = left_node_index;
    // Since the previously used index is going <b>to</b> the right node, `prev` pointer of the next node is correct,
    // and we need <b>to</b> <b>update</b> next pointer of the previous node (<b>if</b> <b>exists</b>)
    <b>if</b> (*left_prev != <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>) {
        <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_borrow_mut">storage_slots_allocator::borrow_mut</a>(&<b>mut</b> self.nodes, *left_prev).next = left_node_index;
        <b>assert</b>!(right_node_index != self.min_leaf_index, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
    } <b>else</b> <b>if</b> (right_node_index == self.min_leaf_index) {
        // Otherwise, <b>if</b> we were the smallest node on the level. <b>if</b> this is the leaf level, <b>update</b> the pointer.
        <b>assert</b>!(is_leaf, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
        self.min_leaf_index = left_node_index;
    };

    // Largest left key is the split key.
    <b>let</b> max_left_key = {
        <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(left_children);
        <b>let</b> prev_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(end_iter, left_children);
        *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&prev_iter, left_children)
    };

    <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_fill_reserved_slot">storage_slots_allocator::fill_reserved_slot</a>(&<b>mut</b> self.nodes, left_node_reserved_slot, left_node);
    <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_fill_reserved_slot">storage_slots_allocator::fill_reserved_slot</a>(&<b>mut</b> self.nodes, right_node_reserved_slot, right_node);

    // Add new <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a> (i.e. pointer <b>to</b> the left node) in the parent.
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_destroy_none">option::destroy_none</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_add_at">add_at</a>(self, path_to_node, max_left_key, <a href="big_ordered_map.md#0x1_big_ordered_map_new_inner_child">new_inner_child</a>(left_node_slot), <b>false</b>));
    <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_none">option::none</a>()
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_update_key"></a>

## Function `update_key`

Given a path to node (excluding the node itself), which is currently stored under "old_key", update "old_key" to "new_key".


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_update_key">update_key</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, path_to_node: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, old_key: &K, new_key: K)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_update_key">update_key</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, path_to_node: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, old_key: &K, new_key: K) {
    <b>while</b> (!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&path_to_node)) {
        <b>let</b> node_index = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>(&<b>mut</b> path_to_node);
        <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node_mut">borrow_node_mut</a>(self, node_index);
        <b>let</b> children = &<b>mut</b> node.children;
        <a href="ordered_map.md#0x1_ordered_map_replace_key_inplace">ordered_map::replace_key_inplace</a>(children, old_key, new_key);

        // If we were not updating the largest child, we don't need <b>to</b> <b>continue</b>.
        <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(children);
        <b>let</b> prev_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(end_iter, children);
        <b>if</b> (<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&prev_iter, children) != &new_key) {
            <b>return</b>
        };
    }
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_remove_at"></a>

## Function `remove_at`



<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_remove_at">remove_at</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, path_to_node: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, key: &K): <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_remove_at">remove_at</a>&lt;K: drop + <b>copy</b> + store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, path_to_node: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, key: &K): <a href="big_ordered_map.md#0x1_big_ordered_map_Child">Child</a>&lt;V&gt; {
    // Last node in the path is one <b>where</b> we need <b>to</b> remove the child from.
    <b>let</b> node_index = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>(&<b>mut</b> path_to_node);
    <b>let</b> old_child = {
        // First check <b>if</b> we can perform this operation, without changing structure of the tree (i.e. without rebalancing <a href="../../endless-stdlib/doc/any.md#0x1_any">any</a> nodes).

        // For that we can just borrow the single node
        <b>let</b> node = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node_mut">borrow_node_mut</a>(self, node_index);

        <b>let</b> children = &<b>mut</b> node.children;
        <b>let</b> is_leaf = node.is_leaf;

        <b>let</b> old_child = <a href="ordered_map.md#0x1_ordered_map_remove">ordered_map::remove</a>(children, key);
        <b>if</b> (node_index == <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>) {
            // If current node is root, lower limit of max_degree/2 nodes doesn't <b>apply</b>.
            // So we can adjust internally

            <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&path_to_node), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));

            <b>if</b> (!is_leaf && <a href="ordered_map.md#0x1_ordered_map_length">ordered_map::length</a>(children) == 1) {
                // If root is not leaf, but <b>has</b> a single child, promote only child <b>to</b> root,
                // and drop current root. Since root is stored directly in the resource, we
                // "<b>move</b>" the child into the root.

                <b>let</b> inner_child_slot = {
                    <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(children);
                    <b>let</b> prev_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(end_iter, children);
                    <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_inner_child">destroy_inner_child</a>(<a href="ordered_map.md#0x1_ordered_map_iter_remove">ordered_map::iter_remove</a>(prev_iter, children))
                };

                <b>let</b> inner_child = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_remove">storage_slots_allocator::remove</a>(&<b>mut</b> self.nodes, inner_child_slot);
                <b>if</b> (inner_child.is_leaf) {
                    self.min_leaf_index = <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>;
                    self.max_leaf_index = <a href="big_ordered_map.md#0x1_big_ordered_map_ROOT_INDEX">ROOT_INDEX</a>;
                };

                <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty_node">destroy_empty_node</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_replace_root">replace_root</a>(self, inner_child));
            };
            <b>return</b> old_child
        };

        // Compute directly, <b>as</b> we cannot <b>use</b> <a href="big_ordered_map.md#0x1_big_ordered_map_get_max_degree">get_max_degree</a>(), <b>as</b> self is already mutably borrowed.
        <b>let</b> max_degree = <b>if</b> (is_leaf) {
            self.leaf_max_degree
        } <b>else</b> {
            self.inner_max_degree
        };
        <b>let</b> degree = <a href="ordered_map.md#0x1_ordered_map_length">ordered_map::length</a>(children);

        // See <b>if</b> the node is big enough, or we need <b>to</b> merge it <b>with</b> another node on this level.
        <b>let</b> big_enough = degree * 2 &gt;= max_degree;

        <b>let</b> new_max_key = {
            <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(children);
            <b>let</b> prev_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(end_iter, children);
            *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&prev_iter, children)
        };

        // See <b>if</b> max key was updated for the current node, and <b>if</b> so - <b>update</b> it on the path.
        <b>let</b> max_key_updated = <a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_is_lt">cmp::is_lt</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/cmp.md#0x1_cmp_compare">cmp::compare</a>(&new_max_key, key));
        <b>if</b> (max_key_updated) {
            <b>assert</b>!(degree &gt;= 1, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));

            <a href="big_ordered_map.md#0x1_big_ordered_map_update_key">update_key</a>(self, path_to_node, key, new_max_key);
        };

        // If node is big enough after removal, we are done.
        <b>if</b> (big_enough) {
            <b>return</b> old_child
        };

        old_child
    };

    // Children size is below threshold, we need <b>to</b> rebalance <b>with</b> a neighbor on the same level.

    // In order <b>to</b> work on multiple nodes at the same time, we cannot borrow_mut, and need <b>to</b> be
    // remove_and_reserve existing node.
    <b>let</b> (node_slot, node) = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_remove_and_reserve">storage_slots_allocator::remove_and_reserve</a>(&<b>mut</b> self.nodes, node_index);

    <b>let</b> is_leaf = node.is_leaf;
    <b>let</b> max_degree = <a href="big_ordered_map.md#0x1_big_ordered_map_get_max_degree">get_max_degree</a>(self, is_leaf);
    <b>let</b> prev = node.prev;
    <b>let</b> next = node.next;

    // index of the node we will rebalance <b>with</b>.
    <b>let</b> sibling_index = {
        <b>let</b> parent_children = &<a href="big_ordered_map.md#0x1_big_ordered_map_borrow_node">borrow_node</a>(self, *<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&path_to_node, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&path_to_node) - 1)).children;
        <b>assert</b>!(<a href="ordered_map.md#0x1_ordered_map_length">ordered_map::length</a>(parent_children) &gt;= 2, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
        // If we are the largest node from the parent, we merge <b>with</b> the `prev`
        // (which is then guaranteed <b>to</b> have the same parent, <b>as</b> <a href="../../endless-stdlib/doc/any.md#0x1_any">any</a> node <b>has</b> &gt;1 children),
        // otherwise we merge <b>with</b> `next`.
        <b>let</b> prev_child = <a href="ordered_map.md#0x1_ordered_map_iter_borrow">ordered_map::iter_borrow</a>(
            <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(<a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(parent_children), parent_children),
            parent_children,
        );
        <b>let</b> inner_data = <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(&prev_child.Inner);
        <b>let</b> prev_index = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_stored_to_index">storage_slots_allocator::stored_to_index</a>(&inner_data.node_index);
        <b>if</b> (prev_index == node_index) {
            prev
        } <b>else</b> {
            next
        }
    };

    <b>let</b> children = &<b>mut</b> node.children;

    <b>let</b> (sibling_slot, sibling_node) = <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_remove_and_reserve">storage_slots_allocator::remove_and_reserve</a>(&<b>mut</b> self.nodes, sibling_index);
    <b>assert</b>!(is_leaf == sibling_node.is_leaf, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
    <b>let</b> sibling_children = &<b>mut</b> sibling_node.children;

    <b>if</b> ((<a href="ordered_map.md#0x1_ordered_map_length">ordered_map::length</a>(sibling_children) - 1) * 2 &gt;= max_degree) {
        // The sibling node <b>has</b> enough elements, we can just borrow an element from the sibling node.
        <b>if</b> (sibling_index == next) {
            // <b>if</b> sibling is the node <b>with</b> larger keys, we remove a child from the start
            <b>let</b> old_max_key = {
                <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(children);
                <b>let</b> prev_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(end_iter, children);
                *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&prev_iter, children)
            };
            <b>let</b> sibling_begin_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_begin_iter">ordered_map::internal_new_begin_iter</a>(sibling_children);
            <b>let</b> borrowed_max_key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&sibling_begin_iter, sibling_children);
            <b>let</b> borrowed_element = <a href="ordered_map.md#0x1_ordered_map_iter_remove">ordered_map::iter_remove</a>(sibling_begin_iter, sibling_children);

            <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(children);
            <a href="ordered_map.md#0x1_ordered_map_iter_add">ordered_map::iter_add</a>(end_iter, children, borrowed_max_key, borrowed_element);

            // max_key of the current node changed, so <b>update</b>
            <a href="big_ordered_map.md#0x1_big_ordered_map_update_key">update_key</a>(self, path_to_node, &old_max_key, borrowed_max_key);
        } <b>else</b> {
            // <b>if</b> sibling is the node <b>with</b> smaller keys, we remove a child from the end
            <b>let</b> sibling_end_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(
                <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(sibling_children),
                sibling_children,
            );
            <b>let</b> borrowed_max_key = *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&sibling_end_iter, sibling_children);
            <b>let</b> borrowed_element = <a href="ordered_map.md#0x1_ordered_map_iter_remove">ordered_map::iter_remove</a>(sibling_end_iter, sibling_children);

            <a href="ordered_map.md#0x1_ordered_map_add">ordered_map::add</a>(children, borrowed_max_key, borrowed_element);

            // max_key of the sibling node changed, so <b>update</b>
            <b>let</b> sibling_new_max_key = {
                <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(sibling_children);
                <b>let</b> prev_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(end_iter, sibling_children);
                *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&prev_iter, sibling_children)
            };
            <a href="big_ordered_map.md#0x1_big_ordered_map_update_key">update_key</a>(self, path_to_node, &borrowed_max_key, sibling_new_max_key);
        };

        <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_fill_reserved_slot">storage_slots_allocator::fill_reserved_slot</a>(&<b>mut</b> self.nodes, node_slot, node);
        <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_fill_reserved_slot">storage_slots_allocator::fill_reserved_slot</a>(&<b>mut</b> self.nodes, sibling_slot, sibling_node);
        <b>return</b> old_child
    };

    // The sibling node doesn't have enough elements <b>to</b> borrow, merge <b>with</b> the sibling node.
    // Keep the slot of the node <b>with</b> larger keys of the two, <b>to</b> not require updating key on the parent nodes.
    // But append <b>to</b> the node <b>with</b> smaller keys, <b>as</b> <a href="ordered_map.md#0x1_ordered_map_append">ordered_map::append</a> is more efficient when adding <b>to</b> the end.
    <b>let</b> (key_to_remove, reserved_slot_to_remove) = <b>if</b> (sibling_index == next) {
        // destroying larger sibling node, keeping sibling_slot.
        <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a> { is_leaf: _, children: sibling_children, prev: _, next: sibling_next } = sibling_node;
        <b>let</b> key_to_remove = {
            <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(children);
            <b>let</b> prev_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(end_iter, children);
            *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&prev_iter, children)
        };
        <a href="ordered_map.md#0x1_ordered_map_append_disjoint">ordered_map::append_disjoint</a>(children, sibling_children);
        node.next = sibling_next;

        <b>if</b> (node.next != <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>) {
            <b>assert</b>!(<a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_borrow_mut">storage_slots_allocator::borrow_mut</a>(&<b>mut</b> self.nodes, node.next).prev == sibling_index, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
        };

        // we are removing node_index, which previous's node's next was pointing <b>to</b>,
        // so <b>update</b> the pointer
        <b>if</b> (node.prev != <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>) {
            <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_borrow_mut">storage_slots_allocator::borrow_mut</a>(&<b>mut</b> self.nodes, node.prev).next = sibling_index;
        };
        // Otherwise, we were the smallest node on the level. <b>if</b> this is the leaf level, <b>update</b> the pointer.
        <b>if</b> (self.min_leaf_index == node_index) {
            <b>assert</b>!(is_leaf, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
            self.min_leaf_index = sibling_index;
        };

        <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_fill_reserved_slot">storage_slots_allocator::fill_reserved_slot</a>(&<b>mut</b> self.nodes, sibling_slot, node);

        (key_to_remove, node_slot)
    } <b>else</b> {
        // destroying larger current node, keeping node_slot
        <b>let</b> <a href="big_ordered_map.md#0x1_big_ordered_map_Node">Node</a> { is_leaf: _, children: node_children, prev: _, next: node_next } = node;
        <b>let</b> key_to_remove = {
            <b>let</b> end_iter = <a href="ordered_map.md#0x1_ordered_map_internal_new_end_iter">ordered_map::internal_new_end_iter</a>(sibling_children);
            <b>let</b> prev_iter = <a href="ordered_map.md#0x1_ordered_map_iter_prev">ordered_map::iter_prev</a>(end_iter, sibling_children);
            *<a href="ordered_map.md#0x1_ordered_map_iter_borrow_key">ordered_map::iter_borrow_key</a>(&prev_iter, sibling_children)
        };
        <a href="ordered_map.md#0x1_ordered_map_append_disjoint">ordered_map::append_disjoint</a>(sibling_children, node_children);
        sibling_node.next = node_next;

        <b>if</b> (sibling_node.next != <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>) {
            <b>assert</b>!(<a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_borrow_mut">storage_slots_allocator::borrow_mut</a>(&<b>mut</b> self.nodes, sibling_node.next).prev == node_index, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
        };
        // we are removing sibling node_index, which previous's node's next was pointing <b>to</b>,
        // so <b>update</b> the pointer
        <b>if</b> (sibling_node.prev != <a href="big_ordered_map.md#0x1_big_ordered_map_NULL_INDEX">NULL_INDEX</a>) {
            <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_borrow_mut">storage_slots_allocator::borrow_mut</a>(&<b>mut</b> self.nodes, sibling_node.prev).next = node_index;
        };
        // Otherwise, sibling was the smallest node on the level. <b>if</b> this is the leaf level, <b>update</b> the pointer.
        <b>if</b> (self.min_leaf_index == sibling_index) {
            <b>assert</b>!(is_leaf, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
            self.min_leaf_index = node_index;
        };

        <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_fill_reserved_slot">storage_slots_allocator::fill_reserved_slot</a>(&<b>mut</b> self.nodes, node_slot, sibling_node);

        (key_to_remove, sibling_slot)
    };

    <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&path_to_node), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_EINTERNAL_INVARIANT_BROKEN">EINTERNAL_INVARIANT_BROKEN</a>));
    <b>let</b> slot_to_remove = <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_inner_child">destroy_inner_child</a>(<a href="big_ordered_map.md#0x1_big_ordered_map_remove_at">remove_at</a>(self, path_to_node, &key_to_remove));
    <a href="../../endless-stdlib/doc/storage_slots_allocator.md#0x1_storage_slots_allocator_free_reserved_slot">storage_slots_allocator::free_reserved_slot</a>(&<b>mut</b> self.nodes, reserved_slot_to_remove, slot_to_remove);

    old_child
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_test_verify_borrow_front_key"></a>

## Function `test_verify_borrow_front_key`



<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_borrow_front_key">test_verify_borrow_front_key</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_borrow_front_key">test_verify_borrow_front_key</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="big_ordered_map.md#0x1_big_ordered_map_new_from">new_from</a>(keys, values);
    <b>let</b> (_key, _value) = {
        <b>let</b> (key_val, value_ref) = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_front">borrow_front</a>(&map);
        (key_val, *value_ref)
    };
    <b>spec</b> {
        <b>assert</b> keys[0] == 1;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_spec_contains">vector::spec_contains</a>(keys, 1);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, _key);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_get">spec_get</a>(map, _key) == _value;
        <b>assert</b> _key == 1;
    };
    <a href="big_ordered_map.md#0x1_big_ordered_map_destroy">destroy</a>(map, |_v| {});
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_test_verify_borrow_back_key"></a>

## Function `test_verify_borrow_back_key`



<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_borrow_back_key">test_verify_borrow_back_key</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_borrow_back_key">test_verify_borrow_back_key</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="big_ordered_map.md#0x1_big_ordered_map_new_from">new_from</a>(keys, values);
    <b>let</b> (key, value) = {
        <b>let</b> (key_val, value_ref) = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_back">borrow_back</a>(&map);
        (key_val, *value_ref)
    };
    <b>spec</b> {
        <b>assert</b> keys[2] == 3;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_spec_contains">vector::spec_contains</a>(keys, 3);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, key);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_get">spec_get</a>(map, key) == value;
        <b>assert</b> key == 3;
    };
    <a href="big_ordered_map.md#0x1_big_ordered_map_destroy">destroy</a>(map, |_v| {});
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_test_verify_upsert"></a>

## Function `test_verify_upsert`



<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_upsert">test_verify_upsert</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_upsert">test_verify_upsert</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="big_ordered_map.md#0x1_big_ordered_map_new_from">new_from</a>(keys, values);
    <b>let</b> (_key, _value) = <a href="big_ordered_map.md#0x1_big_ordered_map_borrow_back">borrow_back</a>(&map);
    <b>let</b> result_1 = <a href="big_ordered_map.md#0x1_big_ordered_map_upsert">upsert</a>(&<b>mut</b> map, 4, 5);
    <b>spec</b> {
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 4);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_get">spec_get</a>(map, 4) == 5;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_none">option::is_none</a>(result_1);
    };
    <b>let</b> result_2 = <a href="big_ordered_map.md#0x1_big_ordered_map_upsert">upsert</a>(&<b>mut</b> map, 4, 6);
    <b>spec</b> {
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 4);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_get">spec_get</a>(map, 4) == 6;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(result_2);
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(result_2) == 5;
        <b>assert</b> !<a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 10);
    };
    <b>spec</b> {
        <b>assert</b> keys[0] == 1;
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_get">spec_get</a>(map, 1) == 4;
    };
    <b>let</b> v = <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &1);
    <b>spec</b> {
        <b>assert</b> v == 4;
    };
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &2);
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &3);
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &4);
    <b>spec</b> {
        <b>assert</b> !<a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> !<a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> !<a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 3);
        <b>assert</b> !<a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 4);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_len">spec_len</a>(map) == 0;
    };
    <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty">destroy_empty</a>(map);
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_test_verify_next_key"></a>

## Function `test_verify_next_key`



<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_next_key">test_verify_next_key</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_next_key">test_verify_next_key</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="big_ordered_map.md#0x1_big_ordered_map_new_from">new_from</a>(keys, values);
    <b>let</b> result_1 = <a href="big_ordered_map.md#0x1_big_ordered_map_next_key">next_key</a>(&map, &3);
    <b>spec</b> {
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_none">option::is_none</a>(result_1);
    };
    <b>let</b> result_2 = <a href="big_ordered_map.md#0x1_big_ordered_map_next_key">next_key</a>(&map, &1);
    <b>spec</b> {
        <b>assert</b> keys[0] == 1;
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> keys[1] == 2;
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(result_2);
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_borrow">option::borrow</a>(result_2) == 2;
    };
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &1);
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &2);
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &3);
    <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty">destroy_empty</a>(map);
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_test_verify_prev_key"></a>

## Function `test_verify_prev_key`



<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_prev_key">test_verify_prev_key</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_prev_key">test_verify_prev_key</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="big_ordered_map.md#0x1_big_ordered_map_new_from">new_from</a>(keys, values);
    <b>let</b> result_1 = <a href="big_ordered_map.md#0x1_big_ordered_map_prev_key">prev_key</a>(&map, &1);
    <b>spec</b> {
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_none">option::is_none</a>(result_1);
    };
    <b>let</b> result_2 = <a href="big_ordered_map.md#0x1_big_ordered_map_prev_key">prev_key</a>(&map, &3);
    <b>spec</b> {
        <b>assert</b> keys[0] == 1;
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
        <b>assert</b> keys[1] == 2;
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_is_some">option::is_some</a>(result_2);
    };
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &1);
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &2);
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &3);
    <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty">destroy_empty</a>(map);
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_test_verify_remove"></a>

## Function `test_verify_remove`



<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_remove">test_verify_remove</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_remove">test_verify_remove</a>() {
    <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3];
    <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6];
    <b>let</b> map = <a href="big_ordered_map.md#0x1_big_ordered_map_new_from">new_from</a>(keys, values);
    <b>spec</b> {
        <b>assert</b> keys[1] == 2;
        <b>assert</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_spec_contains">vector::spec_contains</a>(keys, 2);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_get">spec_get</a>(map, 2) == 5;
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_len">spec_len</a>(map) == 3;
    };
    <b>let</b> v = <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &1);
    <b>spec</b> {
        <b>assert</b> v == 4;
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 2);
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_get">spec_get</a>(map, 2) == 5;
        <b>assert</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_len">spec_len</a>(map) == 2;
        <b>assert</b> !<a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
    };
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &2);
    <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(&<b>mut</b> map, &3);
    <a href="big_ordered_map.md#0x1_big_ordered_map_destroy_empty">destroy_empty</a>(map);
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_test_aborts_if_new_from_1"></a>

## Function `test_aborts_if_new_from_1`



<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_aborts_if_new_from_1">test_aborts_if_new_from_1</a>(): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;u64, u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_aborts_if_new_from_1">test_aborts_if_new_from_1</a>(): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;u64, u64&gt; {
   <b>let</b> keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[1, 2, 3, 1];
   <b>let</b> values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt; = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[4, 5, 6, 7];
   <b>spec</b> {
       <b>assert</b> keys[0] == 1;
       <b>assert</b> keys[3] == 1;
   };
   <b>let</b> map = <a href="big_ordered_map.md#0x1_big_ordered_map_new_from">new_from</a>(keys, values);
   map
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_test_aborts_if_new_from_2"></a>

## Function `test_aborts_if_new_from_2`



<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_aborts_if_new_from_2">test_aborts_if_new_from_2</a>(keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;u64, u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_aborts_if_new_from_2">test_aborts_if_new_from_2</a>(keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;u64, u64&gt; {
   <b>let</b> map = <a href="big_ordered_map.md#0x1_big_ordered_map_new_from">new_from</a>(keys, values);
   map
}
</code></pre>



</details>

<a id="0x1_big_ordered_map_test_aborts_if_remove"></a>

## Function `test_aborts_if_remove`



<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_aborts_if_remove">test_aborts_if_remove</a>(map: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;u64, u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_aborts_if_remove">test_aborts_if_remove</a>(map: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;u64, u64&gt;) {
   <a href="big_ordered_map.md#0x1_big_ordered_map_remove">remove</a>(map, &1);
}
</code></pre>



</details>

<a id="@Specification_1"></a>

## Specification



<pre><code><b>pragma</b> verify = <b>false</b>;
</code></pre>




<a id="0x1_big_ordered_map_spec_len"></a>


<pre><code><b>native</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_len">spec_len</a>&lt;K, V&gt;(map: <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;): num;
</code></pre>




<a id="0x1_big_ordered_map_spec_contains_key"></a>


<pre><code><b>native</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>&lt;K, V&gt;(map: <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: K): bool;
</code></pre>




<a id="0x1_big_ordered_map_spec_get"></a>


<pre><code><b>native</b> <b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_spec_get">spec_get</a>&lt;K, V&gt;(map: <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">BigOrderedMap</a>&lt;K, V&gt;, key: K): V;
</code></pre>



<a id="@Specification_1_add_at"></a>

### Function `add_at`


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_add_at">add_at</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, path_to_node: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, key: K, child: <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;, allow_overwrite: bool): <a href="../../endless-stdlib/../move-stdlib/doc/option.md#0x1_option_Option">option::Option</a>&lt;<a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;&gt;
</code></pre>




<pre><code><b>pragma</b> opaque;
</code></pre>



<a id="@Specification_1_remove_at"></a>

### Function `remove_at`


<pre><code><b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_remove_at">remove_at</a>&lt;K: <b>copy</b>, drop, store, V: store&gt;(self: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;K, V&gt;, path_to_node: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, key: &K): <a href="big_ordered_map.md#0x1_big_ordered_map_Child">big_ordered_map::Child</a>&lt;V&gt;
</code></pre>




<pre><code><b>pragma</b> opaque;
</code></pre>



<a id="@Specification_1_test_verify_borrow_front_key"></a>

### Function `test_verify_borrow_front_key`


<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_borrow_front_key">test_verify_borrow_front_key</a>()
</code></pre>




<pre><code><b>pragma</b> verify = <b>true</b>;
</code></pre>



<a id="@Specification_1_test_verify_borrow_back_key"></a>

### Function `test_verify_borrow_back_key`


<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_borrow_back_key">test_verify_borrow_back_key</a>()
</code></pre>




<pre><code><b>pragma</b> verify = <b>true</b>;
</code></pre>



<a id="@Specification_1_test_verify_upsert"></a>

### Function `test_verify_upsert`


<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_upsert">test_verify_upsert</a>()
</code></pre>




<pre><code><b>pragma</b> verify = <b>true</b>;
</code></pre>



<a id="@Specification_1_test_verify_next_key"></a>

### Function `test_verify_next_key`


<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_next_key">test_verify_next_key</a>()
</code></pre>




<pre><code><b>pragma</b> verify = <b>true</b>;
</code></pre>



<a id="@Specification_1_test_verify_prev_key"></a>

### Function `test_verify_prev_key`


<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_prev_key">test_verify_prev_key</a>()
</code></pre>




<pre><code><b>pragma</b> verify = <b>true</b>;
</code></pre>



<a id="@Specification_1_test_verify_remove"></a>

### Function `test_verify_remove`


<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_verify_remove">test_verify_remove</a>()
</code></pre>




<pre><code><b>pragma</b> verify = <b>true</b>;
</code></pre>



<a id="@Specification_1_test_aborts_if_new_from_1"></a>

### Function `test_aborts_if_new_from_1`


<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_aborts_if_new_from_1">test_aborts_if_new_from_1</a>(): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;u64, u64&gt;
</code></pre>




<pre><code><b>pragma</b> verify = <b>true</b>;
<b>aborts_if</b> <b>true</b>;
</code></pre>



<a id="@Specification_1_test_aborts_if_new_from_2"></a>

### Function `test_aborts_if_new_from_2`


<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_aborts_if_new_from_2">test_aborts_if_new_from_2</a>(keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, values: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;): <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;u64, u64&gt;
</code></pre>




<pre><code><b>pragma</b> verify = <b>true</b>;
<b>aborts_if</b> <b>exists</b> i in 0..len(keys), j in 0..len(keys) <b>where</b> i != j : keys[i] == keys[j];
<b>aborts_if</b> len(keys) != len(values);
</code></pre>



<a id="@Specification_1_test_aborts_if_remove"></a>

### Function `test_aborts_if_remove`


<pre><code>#[verify_only]
<b>fun</b> <a href="big_ordered_map.md#0x1_big_ordered_map_test_aborts_if_remove">test_aborts_if_remove</a>(map: &<b>mut</b> <a href="big_ordered_map.md#0x1_big_ordered_map_BigOrderedMap">big_ordered_map::BigOrderedMap</a>&lt;u64, u64&gt;)
</code></pre>




<pre><code><b>pragma</b> verify = <b>true</b>;
<b>aborts_if</b> !<a href="big_ordered_map.md#0x1_big_ordered_map_spec_contains_key">spec_contains_key</a>(map, 1);
</code></pre>


[move-book]: https://endless.dev/move/book/SUMMARY

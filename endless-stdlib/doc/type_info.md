
<a id="0x1_type_info"></a>

# Module `0x1::type_info`



-  [Struct `TypeInfo`](#0x1_type_info_TypeInfo)
-  [Constants](#@Constants_0)
-  [Function `account_address`](#0x1_type_info_account_address)
-  [Function `module_name`](#0x1_type_info_module_name)
-  [Function `struct_name`](#0x1_type_info_struct_name)
-  [Function `chain_id`](#0x1_type_info_chain_id)
-  [Function `type_of`](#0x1_type_info_type_of)
-  [Function `type_name`](#0x1_type_info_type_name)
-  [Function `chain_id_internal`](#0x1_type_info_chain_id_internal)
-  [Function `size_of_val`](#0x1_type_info_size_of_val)
-  [Function `verify_type_of`](#0x1_type_info_verify_type_of)
-  [Function `verify_type_of_generic`](#0x1_type_info_verify_type_of_generic)
-  [Specification](#@Specification_1)
    -  [Function `chain_id`](#@Specification_1_chain_id)
    -  [Function `type_of`](#@Specification_1_type_of)
    -  [Function `type_name`](#@Specification_1_type_name)
    -  [Function `chain_id_internal`](#@Specification_1_chain_id_internal)
    -  [Function `size_of_val`](#@Specification_1_size_of_val)
    -  [Function `verify_type_of_generic`](#@Specification_1_verify_type_of_generic)


<pre><code><b>use</b> <a href="../../move-stdlib/doc/bcs.md#0x1_bcs">0x1::bcs</a>;
<b>use</b> <a href="../../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="../../move-stdlib/doc/features.md#0x1_features">0x1::features</a>;
<b>use</b> <a href="../../move-stdlib/doc/string.md#0x1_string">0x1::string</a>;
</code></pre>



<a id="0x1_type_info_TypeInfo"></a>

## Struct `TypeInfo`



<pre><code><b>struct</b> <a href="type_info.md#0x1_type_info_TypeInfo">TypeInfo</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>account_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>module_name: <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>struct_name: <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_type_info_E_NATIVE_FUN_NOT_AVAILABLE"></a>



<pre><code><b>const</b> <a href="type_info.md#0x1_type_info_E_NATIVE_FUN_NOT_AVAILABLE">E_NATIVE_FUN_NOT_AVAILABLE</a>: u64 = 1;
</code></pre>



<a id="0x1_type_info_account_address"></a>

## Function `account_address`



<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_account_address">account_address</a>(<a href="type_info.md#0x1_type_info">type_info</a>: &<a href="type_info.md#0x1_type_info_TypeInfo">type_info::TypeInfo</a>): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_account_address">account_address</a>(<a href="type_info.md#0x1_type_info">type_info</a>: &<a href="type_info.md#0x1_type_info_TypeInfo">TypeInfo</a>): <b>address</b> {
    <a href="type_info.md#0x1_type_info">type_info</a>.account_address
}
</code></pre>



</details>

<a id="0x1_type_info_module_name"></a>

## Function `module_name`



<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_module_name">module_name</a>(<a href="type_info.md#0x1_type_info">type_info</a>: &<a href="type_info.md#0x1_type_info_TypeInfo">type_info::TypeInfo</a>): <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_module_name">module_name</a>(<a href="type_info.md#0x1_type_info">type_info</a>: &<a href="type_info.md#0x1_type_info_TypeInfo">TypeInfo</a>): <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt; {
    <a href="type_info.md#0x1_type_info">type_info</a>.module_name
}
</code></pre>



</details>

<a id="0x1_type_info_struct_name"></a>

## Function `struct_name`



<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_struct_name">struct_name</a>(<a href="type_info.md#0x1_type_info">type_info</a>: &<a href="type_info.md#0x1_type_info_TypeInfo">type_info::TypeInfo</a>): <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_struct_name">struct_name</a>(<a href="type_info.md#0x1_type_info">type_info</a>: &<a href="type_info.md#0x1_type_info_TypeInfo">TypeInfo</a>): <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt; {
    <a href="type_info.md#0x1_type_info">type_info</a>.struct_name
}
</code></pre>



</details>

<a id="0x1_type_info_chain_id"></a>

## Function `chain_id`

Returns the current chain ID, mirroring what <code>endless_framework::chain_id::get()</code> would return, except in <code>#[test]</code>
functions, where this will always return <code>4u8</code> as the chain ID, whereas <code>endless_framework::chain_id::get()</code> will
return whichever ID was passed to <code>endless_framework::chain_id::initialize_for_test()</code>.


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_chain_id">chain_id</a>(): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_chain_id">chain_id</a>(): u8 {
    <b>if</b> (!<a href="../../move-stdlib/doc/features.md#0x1_features_endless_stdlib_chain_id_enabled">features::endless_stdlib_chain_id_enabled</a>()) {
        <b>abort</b>(std::error::invalid_state(<a href="type_info.md#0x1_type_info_E_NATIVE_FUN_NOT_AVAILABLE">E_NATIVE_FUN_NOT_AVAILABLE</a>))
    };

    <a href="type_info.md#0x1_type_info_chain_id_internal">chain_id_internal</a>()
}
</code></pre>



</details>

<a id="0x1_type_info_type_of"></a>

## Function `type_of`

Return the <code><a href="type_info.md#0x1_type_info_TypeInfo">TypeInfo</a></code> struct containing  for the type <code>T</code>.


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_type_of">type_of</a>&lt;T&gt;(): <a href="type_info.md#0x1_type_info_TypeInfo">type_info::TypeInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>native</b> <b>fun</b> <a href="type_info.md#0x1_type_info_type_of">type_of</a>&lt;T&gt;(): <a href="type_info.md#0x1_type_info_TypeInfo">TypeInfo</a>;
</code></pre>



</details>

<a id="0x1_type_info_type_name"></a>

## Function `type_name`

Return the human readable string for the type, including the address, module name, and any type arguments.
Example: 0x1::coin::CoinStore<0x1::endless_coin::EndlessCoin>
Or: 0x1::table::Table<0x1::string::String, 0x1::string::String>


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_type_name">type_name</a>&lt;T&gt;(): <a href="../../move-stdlib/doc/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>native</b> <b>fun</b> <a href="type_info.md#0x1_type_info_type_name">type_name</a>&lt;T&gt;(): String;
</code></pre>



</details>

<a id="0x1_type_info_chain_id_internal"></a>

## Function `chain_id_internal`



<pre><code><b>fun</b> <a href="type_info.md#0x1_type_info_chain_id_internal">chain_id_internal</a>(): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>native</b> <b>fun</b> <a href="type_info.md#0x1_type_info_chain_id_internal">chain_id_internal</a>(): u8;
</code></pre>



</details>

<a id="0x1_type_info_size_of_val"></a>

## Function `size_of_val`

Return the BCS size, in bytes, of value at <code>val_ref</code>.

See the [BCS spec](https://github.com/diem/bcs)

See <code>test_size_of_val()</code> for an analysis of common types and
nesting patterns, as well as <code>test_size_of_val_vectors()</code> for an
analysis of vector size dynamism.


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_size_of_val">size_of_val</a>&lt;T&gt;(val_ref: &T): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_size_of_val">size_of_val</a>&lt;T&gt;(val_ref: &T): u64 {
    // Return <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a> length of vectorized BCS representation.
    <a href="../../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&<a href="../../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(val_ref))
}
</code></pre>



</details>

<a id="0x1_type_info_verify_type_of"></a>

## Function `verify_type_of`



<pre><code>#[verify_only]
<b>fun</b> <a href="type_info.md#0x1_type_info_verify_type_of">verify_type_of</a>()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="type_info.md#0x1_type_info_verify_type_of">verify_type_of</a>() {
    <b>let</b> <a href="type_info.md#0x1_type_info">type_info</a> = <a href="type_info.md#0x1_type_info_type_of">type_of</a>&lt;<a href="type_info.md#0x1_type_info_TypeInfo">TypeInfo</a>&gt;();
    <b>let</b> account_address = <a href="type_info.md#0x1_type_info_account_address">account_address</a>(&<a href="type_info.md#0x1_type_info">type_info</a>);
    <b>let</b> module_name = <a href="type_info.md#0x1_type_info_module_name">module_name</a>(&<a href="type_info.md#0x1_type_info">type_info</a>);
    <b>let</b> struct_name = <a href="type_info.md#0x1_type_info_struct_name">struct_name</a>(&<a href="type_info.md#0x1_type_info">type_info</a>);
    <b>spec</b> {
        <b>assert</b> account_address == @endless_std;
        <b>assert</b> module_name == b"<a href="type_info.md#0x1_type_info">type_info</a>";
        <b>assert</b> struct_name == b"<a href="type_info.md#0x1_type_info_TypeInfo">TypeInfo</a>";
    };
}
</code></pre>



</details>

<a id="0x1_type_info_verify_type_of_generic"></a>

## Function `verify_type_of_generic`



<pre><code>#[verify_only]
<b>fun</b> <a href="type_info.md#0x1_type_info_verify_type_of_generic">verify_type_of_generic</a>&lt;T&gt;()
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="type_info.md#0x1_type_info_verify_type_of_generic">verify_type_of_generic</a>&lt;T&gt;() {
    <b>let</b> <a href="type_info.md#0x1_type_info">type_info</a> = <a href="type_info.md#0x1_type_info_type_of">type_of</a>&lt;T&gt;();
    <b>let</b> account_address = <a href="type_info.md#0x1_type_info_account_address">account_address</a>(&<a href="type_info.md#0x1_type_info">type_info</a>);
    <b>let</b> module_name = <a href="type_info.md#0x1_type_info_module_name">module_name</a>(&<a href="type_info.md#0x1_type_info">type_info</a>);
    <b>let</b> struct_name = <a href="type_info.md#0x1_type_info_struct_name">struct_name</a>(&<a href="type_info.md#0x1_type_info">type_info</a>);
    <b>spec</b> {
        <b>assert</b> account_address == <a href="type_info.md#0x1_type_info_type_of">type_of</a>&lt;T&gt;().account_address;
        <b>assert</b> module_name == <a href="type_info.md#0x1_type_info_type_of">type_of</a>&lt;T&gt;().module_name;
        <b>assert</b> struct_name == <a href="type_info.md#0x1_type_info_type_of">type_of</a>&lt;T&gt;().struct_name;
    };
}
</code></pre>



</details>

<a id="@Specification_1"></a>

## Specification


<a id="@Specification_1_chain_id"></a>

### Function `chain_id`


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_chain_id">chain_id</a>(): u8
</code></pre>




<pre><code><b>aborts_if</b> !<a href="../../move-stdlib/doc/features.md#0x1_features_spec_is_enabled">features::spec_is_enabled</a>(<a href="../../move-stdlib/doc/features.md#0x1_features_ENDLESS_STD_CHAIN_ID_NATIVES">features::ENDLESS_STD_CHAIN_ID_NATIVES</a>);
<b>ensures</b> result == <a href="type_info.md#0x1_type_info_spec_chain_id_internal">spec_chain_id_internal</a>();
</code></pre>



<a id="@Specification_1_type_of"></a>

### Function `type_of`


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_type_of">type_of</a>&lt;T&gt;(): <a href="type_info.md#0x1_type_info_TypeInfo">type_info::TypeInfo</a>
</code></pre>




<a id="@Specification_1_type_name"></a>

### Function `type_name`


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_type_name">type_name</a>&lt;T&gt;(): <a href="../../move-stdlib/doc/string.md#0x1_string_String">string::String</a>
</code></pre>




<a id="@Specification_1_chain_id_internal"></a>

### Function `chain_id_internal`


<pre><code><b>fun</b> <a href="type_info.md#0x1_type_info_chain_id_internal">chain_id_internal</a>(): u8
</code></pre>




<pre><code><b>pragma</b> opaque;
<b>aborts_if</b> <b>false</b>;
<b>ensures</b> result == <a href="type_info.md#0x1_type_info_spec_chain_id_internal">spec_chain_id_internal</a>();
</code></pre>




<a id="0x1_type_info_spec_chain_id_internal"></a>


<pre><code><b>fun</b> <a href="type_info.md#0x1_type_info_spec_chain_id_internal">spec_chain_id_internal</a>(): u8;
</code></pre>




<a id="0x1_type_info_spec_size_of_val"></a>


<pre><code><b>fun</b> <a href="type_info.md#0x1_type_info_spec_size_of_val">spec_size_of_val</a>&lt;T&gt;(val_ref: T): u64 {
   len(std::bcs::serialize(val_ref))
}
</code></pre>



<a id="@Specification_1_size_of_val"></a>

### Function `size_of_val`


<pre><code><b>public</b> <b>fun</b> <a href="type_info.md#0x1_type_info_size_of_val">size_of_val</a>&lt;T&gt;(val_ref: &T): u64
</code></pre>




<pre><code><b>aborts_if</b> <b>false</b>;
<b>ensures</b> result == <a href="type_info.md#0x1_type_info_spec_size_of_val">spec_size_of_val</a>&lt;T&gt;(val_ref);
</code></pre>



<a id="@Specification_1_verify_type_of_generic"></a>

### Function `verify_type_of_generic`


<pre><code>#[verify_only]
<b>fun</b> <a href="type_info.md#0x1_type_info_verify_type_of_generic">verify_type_of_generic</a>&lt;T&gt;()
</code></pre>




<pre><code><b>aborts_if</b> !<a href="type_info.md#0x1_type_info_spec_is_struct">spec_is_struct</a>&lt;T&gt;();
</code></pre>




<a id="0x1_type_info_spec_is_struct"></a>


<pre><code><b>native</b> <b>fun</b> <a href="type_info.md#0x1_type_info_spec_is_struct">spec_is_struct</a>&lt;T&gt;(): bool;
</code></pre>


[move-book]: https://endless.dev/move/book/SUMMARY

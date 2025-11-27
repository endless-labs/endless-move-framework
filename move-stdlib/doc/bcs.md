
<a id="0x1_bcs"></a>

# Module `0x1::bcs`

Utility for converting a Move value to its binary representation in BCS (Binary Canonical
Serialization). BCS is the binary encoding for Move resources and other non-module values
published on-chain. See https://github.com/endless-labs/bcs#binary-canonical-serialization-bcs for more
details on BCS.


-  [Function `to_bytes`](#0x1_bcs_to_bytes)
-  [Function `serialized_size`](#0x1_bcs_serialized_size)
-  [Function `constant_serialized_size`](#0x1_bcs_constant_serialized_size)
-  [Specification](#@Specification_0)


<pre><code><b>use</b> <a href="option.md#0x1_option">0x1::option</a>;
</code></pre>



<a id="0x1_bcs_to_bytes"></a>

## Function `to_bytes`

Return the binary representation of <code>v</code> in BCS (Binary Canonical Serialization) format


<pre><code><b>public</b> <b>fun</b> <a href="bcs.md#0x1_bcs_to_bytes">to_bytes</a>&lt;MoveValue&gt;(v: &MoveValue): <a href="vector.md#0x1_vector">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>native</b> <b>public</b> <b>fun</b> <a href="bcs.md#0x1_bcs_to_bytes">to_bytes</a>&lt;MoveValue&gt;(v: &MoveValue): <a href="vector.md#0x1_vector">vector</a>&lt;u8&gt;;
</code></pre>



</details>

<a id="0x1_bcs_serialized_size"></a>

## Function `serialized_size`

Return the size of the binary representation of <code>v</code> in BCS format


<pre><code><b>public</b> <b>fun</b> <a href="bcs.md#0x1_bcs_serialized_size">serialized_size</a>&lt;MoveValue&gt;(v: &MoveValue): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="bcs.md#0x1_bcs_serialized_size">serialized_size</a>&lt;MoveValue&gt;(v: &MoveValue): u64 {
    std::vector::length(&<a href="bcs.md#0x1_bcs_to_bytes">to_bytes</a>(v))
}
</code></pre>



</details>

<a id="0x1_bcs_constant_serialized_size"></a>

## Function `constant_serialized_size`

Return the constant size of the binary representation of type <code>MoveValue</code> in BCS format
Returns Some(size) if the type has a constant size, None otherwise


<pre><code><b>public</b> <b>fun</b> <a href="bcs.md#0x1_bcs_constant_serialized_size">constant_serialized_size</a>&lt;MoveValue&gt;(): <a href="option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>native</b> <b>public</b> <b>fun</b> <a href="bcs.md#0x1_bcs_constant_serialized_size">constant_serialized_size</a>&lt;MoveValue&gt;(): Option&lt;u64&gt;;
</code></pre>



</details>

<a id="@Specification_0"></a>

## Specification



Native function which is defined in the prover's prelude.


<a id="0x1_bcs_serialize"></a>


<pre><code><b>native</b> <b>fun</b> <a href="bcs.md#0x1_bcs_serialize">serialize</a>&lt;MoveValue&gt;(v: &MoveValue): <a href="vector.md#0x1_vector">vector</a>&lt;u8&gt;;
</code></pre>


[move-book]: https://endless.dev/move/book/SUMMARY

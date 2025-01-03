
<a id="0x1_poly_commit_ipa"></a>

# Module `0x1::poly_commit_ipa`



-  [Function `verify_proof_native`](#0x1_poly_commit_ipa_verify_proof_native)


<pre><code></code></pre>



<a id="0x1_poly_commit_ipa_verify_proof_native"></a>

## Function `verify_proof_native`



<pre><code><b>public</b> <b>fun</b> <a href="poly_commit_ipa.md#0x1_poly_commit_ipa_verify_proof_native">verify_proof_native</a>(multiproof: <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, commitment: <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, points_x: <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;, points_y: <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, domain_size: u64): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>native</b> <b>fun</b> <a href="poly_commit_ipa.md#0x1_poly_commit_ipa_verify_proof_native">verify_proof_native</a>(
    multiproof: <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    commitment: <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    points_x: <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;,
    points_y: <a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;,
    domain_size: u64,
): bool;
</code></pre>



</details>


[move-book]: https://endless.dev/move/book/SUMMARY

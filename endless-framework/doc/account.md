
<a id="0x1_account"></a>

# Module `0x1::account`



-  [Struct `AddAuthenticationKey`](#0x1_account_AddAuthenticationKey)
-  [Struct `RemoveAuthenticationKey`](#0x1_account_RemoveAuthenticationKey)
-  [Struct `UpdateSignaturesRequired`](#0x1_account_UpdateSignaturesRequired)
-  [Resource `Account`](#0x1_account_Account)
-  [Struct `SignerCapability`](#0x1_account_SignerCapability)
-  [Resource `OriginatingAddress`](#0x1_account_OriginatingAddress)
-  [Struct `RotationProofChallenge`](#0x1_account_RotationProofChallenge)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_account_initialize)
-  [Function `create_account_if_does_not_exist`](#0x1_account_create_account_if_does_not_exist)
-  [Function `create_account`](#0x1_account_create_account)
-  [Function `create_account_unchecked`](#0x1_account_create_account_unchecked)
-  [Function `exists_at`](#0x1_account_exists_at)
-  [Function `get_guid_next_creation_num`](#0x1_account_get_guid_next_creation_num)
-  [Function `get_sequence_number`](#0x1_account_get_sequence_number)
-  [Function `increment_sequence_number`](#0x1_account_increment_sequence_number)
-  [Function `num_signatures_required`](#0x1_account_num_signatures_required)
-  [Function `get_authentication_key`](#0x1_account_get_authentication_key)
-  [Function `check_authentication_key`](#0x1_account_check_authentication_key)
-  [Function `is_original_account`](#0x1_account_is_original_account)
-  [Function `check_duplication`](#0x1_account_check_duplication)
-  [Function `rotate_authentication_key_internal`](#0x1_account_rotate_authentication_key_internal)
-  [Function `add_authentication_key`](#0x1_account_add_authentication_key)
-  [Function `batch_add_authentication_key`](#0x1_account_batch_add_authentication_key)
-  [Function `create_multisig_account`](#0x1_account_create_multisig_account)
-  [Function `create_multisig_account_public`](#0x1_account_create_multisig_account_public)
-  [Function `swap_authentication_key`](#0x1_account_swap_authentication_key)
-  [Function `remove_authentication_key`](#0x1_account_remove_authentication_key)
-  [Function `batch_remove_authentication_key`](#0x1_account_batch_remove_authentication_key)
-  [Function `set_num_signatures_required`](#0x1_account_set_num_signatures_required)
-  [Function `vector_diff`](#0x1_account_vector_diff)
-  [Function `update_auth_key_and_originating_address_table`](#0x1_account_update_auth_key_and_originating_address_table)
-  [Function `create_resource_address`](#0x1_account_create_resource_address)
-  [Function `create_resource_account`](#0x1_account_create_resource_account)
-  [Function `create_framework_reserved_account`](#0x1_account_create_framework_reserved_account)
-  [Function `create_guid`](#0x1_account_create_guid)
-  [Function `new_event_handle`](#0x1_account_new_event_handle)
-  [Function `create_signer_with_capability`](#0x1_account_create_signer_with_capability)
-  [Function `get_signer_capability_address`](#0x1_account_get_signer_capability_address)
-  [Function `verify_signed_message`](#0x1_account_verify_signed_message)
-  [Function `verify_signed_message_unauthenised_pubkey`](#0x1_account_verify_signed_message_unauthenised_pubkey)
-  [Specification](#@Specification_1)
    -  [High-level Requirements](#high-level-req)
    -  [Module-level Specification](#module-level-spec)
    -  [Function `initialize`](#@Specification_1_initialize)
    -  [Function `create_account_if_does_not_exist`](#@Specification_1_create_account_if_does_not_exist)
    -  [Function `create_account`](#@Specification_1_create_account)
    -  [Function `create_account_unchecked`](#@Specification_1_create_account_unchecked)
    -  [Function `exists_at`](#@Specification_1_exists_at)
    -  [Function `get_guid_next_creation_num`](#@Specification_1_get_guid_next_creation_num)
    -  [Function `get_sequence_number`](#@Specification_1_get_sequence_number)
    -  [Function `increment_sequence_number`](#@Specification_1_increment_sequence_number)
    -  [Function `get_authentication_key`](#@Specification_1_get_authentication_key)
    -  [Function `rotate_authentication_key_internal`](#@Specification_1_rotate_authentication_key_internal)
    -  [Function `update_auth_key_and_originating_address_table`](#@Specification_1_update_auth_key_and_originating_address_table)
    -  [Function `create_resource_address`](#@Specification_1_create_resource_address)
    -  [Function `create_resource_account`](#@Specification_1_create_resource_account)
    -  [Function `create_framework_reserved_account`](#@Specification_1_create_framework_reserved_account)
    -  [Function `create_guid`](#@Specification_1_create_guid)
    -  [Function `create_signer_with_capability`](#@Specification_1_create_signer_with_capability)
    -  [Function `verify_signed_message`](#@Specification_1_verify_signed_message)


<pre><code><b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs">0x1::bcs</a>;
<b>use</b> <a href="create_signer.md#0x1_create_signer">0x1::create_signer</a>;
<b>use</b> <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519">0x1::ed25519</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="event.md#0x1_event">0x1::event</a>;
<b>use</b> <a href="../../endless-stdlib/doc/from_bcs.md#0x1_from_bcs">0x1::from_bcs</a>;
<b>use</b> <a href="guid.md#0x1_guid">0x1::guid</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash">0x1::hash</a>;
<b>use</b> <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519">0x1::multi_ed25519</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
<b>use</b> <a href="../../endless-stdlib/doc/table.md#0x1_table">0x1::table</a>;
<b>use</b> <a href="transaction_context.md#0x1_transaction_context">0x1::transaction_context</a>;
<b>use</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">0x1::vector</a>;
</code></pre>



<a id="0x1_account_AddAuthenticationKey"></a>

## Struct `AddAuthenticationKey`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="account.md#0x1_account_AddAuthenticationKey">AddAuthenticationKey</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="account.md#0x1_account">account</a>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>auth_keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_account_RemoveAuthenticationKey"></a>

## Struct `RemoveAuthenticationKey`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="account.md#0x1_account_RemoveAuthenticationKey">RemoveAuthenticationKey</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="account.md#0x1_account">account</a>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>auth_keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_account_UpdateSignaturesRequired"></a>

## Struct `UpdateSignaturesRequired`



<pre><code>#[<a href="event.md#0x1_event">event</a>]
<b>struct</b> <a href="account.md#0x1_account_UpdateSignaturesRequired">UpdateSignaturesRequired</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="account.md#0x1_account">account</a>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>old_num_signatures_required: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>new_num_signatures_required: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_account_Account"></a>

## Resource `Account`

Resource representing an account.


<pre><code><b>struct</b> <a href="account.md#0x1_account_Account">Account</a> <b>has</b> store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>authentication_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>sequence_number: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>guid_creation_num: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>num_signatures_required: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_account_SignerCapability"></a>

## Struct `SignerCapability`



<pre><code><b>struct</b> <a href="account.md#0x1_account_SignerCapability">SignerCapability</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="account.md#0x1_account">account</a>: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_account_OriginatingAddress"></a>

## Resource `OriginatingAddress`

It is easy to fetch the authentication key of an address by simply reading it from the <code><a href="account.md#0x1_account_Account">Account</a></code> struct at that address.
The table in this struct makes it possible to do a reverse lookup: it maps an authentication key, to the address of the account which has that authentication key set.

This mapping is needed when recovering wallets for accounts whose authentication key has been rotated.

For example, imagine a freshly-created wallet with address <code>a</code> and thus also with authentication key <code>a</code>, derived from a PK <code>pk_a</code> with corresponding SK <code>sk_a</code>.
It is easy to recover such a wallet given just the secret key <code>sk_a</code>, since the PK can be derived from the SK, the authentication key can then be derived from the PK, and the address equals the authentication key (since there was no key rotation).

However, if such a wallet rotates its authentication key to <code>b</code> derived from a different PK <code>pk_b</code> with SK <code>sk_b</code>, how would account recovery work?
The recovered address would no longer be 'a'; it would be <code>b</code>, which is incorrect.
This struct solves this problem by mapping the new authentication key <code>b</code> to the original address <code>a</code> and thus helping the wallet software during recovery find the correct address.


<pre><code><b>struct</b> <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>address_map: <a href="../../endless-stdlib/doc/table.md#0x1_table_Table">table::Table</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="0x1_account_RotationProofChallenge"></a>

## Struct `RotationProofChallenge`

This structs stores the challenge message that should be signed during key rotation. First, this struct is
signed by the account owner's current public key, which proves possession of a capability to rotate the key.
Second, this struct is signed by the new public key that the account owner wants to rotate to, which proves
knowledge of this new public key's associated secret key. These two signatures cannot be replayed in another
context because they include the TXN's unique sequence number.


<pre><code><b>struct</b> <a href="account.md#0x1_account_RotationProofChallenge">RotationProofChallenge</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>sequence_number: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>originator: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>current_auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>new_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a id="@Constants_0"></a>

## Constants


<a id="0x1_account_MAX_U64"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_MAX_U64">MAX_U64</a>: u128 = 18446744073709551615;
</code></pre>



<a id="0x1_account_DERIVE_RESOURCE_ACCOUNT_SCHEME"></a>

Scheme identifier used when hashing an account's address together with a seed to derive the address (not the
authentication key) of a resource account. This is an abuse of the notion of a scheme identifier which, for now,
serves to domain separate hashes used to derive resource account addresses from hashes used to derive
authentication keys. Without such separation, an adversary could create (and get a signer for) a resource account
whose address matches an existing address of a MultiEd25519 wallet.


<pre><code><b>const</b> <a href="account.md#0x1_account_DERIVE_RESOURCE_ACCOUNT_SCHEME">DERIVE_RESOURCE_ACCOUNT_SCHEME</a>: u8 = 255;
</code></pre>



<a id="0x1_account_EACCOUNT_ALREADY_EXISTS"></a>

Account already exists


<pre><code><b>const</b> <a href="account.md#0x1_account_EACCOUNT_ALREADY_EXISTS">EACCOUNT_ALREADY_EXISTS</a>: u64 = 1;
</code></pre>



<a id="0x1_account_EACCOUNT_ALREADY_USED"></a>

An attempt to create a resource account on an account that has a committed transaction


<pre><code><b>const</b> <a href="account.md#0x1_account_EACCOUNT_ALREADY_USED">EACCOUNT_ALREADY_USED</a>: u64 = 16;
</code></pre>



<a id="0x1_account_EACCOUNT_DOES_NOT_EXIST"></a>

Account does not exist


<pre><code><b>const</b> <a href="account.md#0x1_account_EACCOUNT_DOES_NOT_EXIST">EACCOUNT_DOES_NOT_EXIST</a>: u64 = 2;
</code></pre>



<a id="0x1_account_EACCOUNT_IS_NOT_ORIGINAL"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_EACCOUNT_IS_NOT_ORIGINAL">EACCOUNT_IS_NOT_ORIGINAL</a>: u64 = 26;
</code></pre>



<a id="0x1_account_ECANNOT_RESERVED_ADDRESS"></a>

Cannot create account because address is reserved


<pre><code><b>const</b> <a href="account.md#0x1_account_ECANNOT_RESERVED_ADDRESS">ECANNOT_RESERVED_ADDRESS</a>: u64 = 5;
</code></pre>



<a id="0x1_account_ED25519_SCHEME"></a>

Scheme identifier for Ed25519 signatures used to derive authentication keys for Ed25519 public keys.


<pre><code><b>const</b> <a href="account.md#0x1_account_ED25519_SCHEME">ED25519_SCHEME</a>: u8 = 0;
</code></pre>



<a id="0x1_account_EDUPLICATE_AUTHENTICATION_KEY"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_EDUPLICATE_AUTHENTICATION_KEY">EDUPLICATE_AUTHENTICATION_KEY</a>: u64 = 23;
</code></pre>



<a id="0x1_account_EEXCEEDED_MAX_GUID_CREATION_NUM"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_EEXCEEDED_MAX_GUID_CREATION_NUM">EEXCEEDED_MAX_GUID_CREATION_NUM</a>: u64 = 20;
</code></pre>



<a id="0x1_account_EINVALID_ACCEPT_ROTATION_CAPABILITY"></a>

The caller does not have a valid rotation capability offer from the other account


<pre><code><b>const</b> <a href="account.md#0x1_account_EINVALID_ACCEPT_ROTATION_CAPABILITY">EINVALID_ACCEPT_ROTATION_CAPABILITY</a>: u64 = 10;
</code></pre>



<a id="0x1_account_EINVALID_AUTHENTICATION_KEY"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_EINVALID_AUTHENTICATION_KEY">EINVALID_AUTHENTICATION_KEY</a>: u64 = 24;
</code></pre>



<a id="0x1_account_EINVALID_AUTHENTICATION_KEY_COUNT"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_EINVALID_AUTHENTICATION_KEY_COUNT">EINVALID_AUTHENTICATION_KEY_COUNT</a>: u64 = 22;
</code></pre>



<a id="0x1_account_EINVALID_NUM_SIGNATURES_REQUIRED"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_EINVALID_NUM_SIGNATURES_REQUIRED">EINVALID_NUM_SIGNATURES_REQUIRED</a>: u64 = 25;
</code></pre>



<a id="0x1_account_EINVALID_ORIGINATING_ADDRESS"></a>

Abort the transaction if the expected originating address is different from the originating address on-chain


<pre><code><b>const</b> <a href="account.md#0x1_account_EINVALID_ORIGINATING_ADDRESS">EINVALID_ORIGINATING_ADDRESS</a>: u64 = 13;
</code></pre>



<a id="0x1_account_EINVALID_PROOF_OF_KNOWLEDGE"></a>

Specified proof of knowledge required to prove ownership of a public key is invalid


<pre><code><b>const</b> <a href="account.md#0x1_account_EINVALID_PROOF_OF_KNOWLEDGE">EINVALID_PROOF_OF_KNOWLEDGE</a>: u64 = 8;
</code></pre>



<a id="0x1_account_EINVALID_SCHEME"></a>

Specified scheme required to proceed with the smart contract operation - can only be ED25519_SCHEME(0) OR MULTI_ED25519_SCHEME(1)


<pre><code><b>const</b> <a href="account.md#0x1_account_EINVALID_SCHEME">EINVALID_SCHEME</a>: u64 = 12;
</code></pre>



<a id="0x1_account_EMALFORMED_AUTHENTICATION_KEY"></a>

The provided authentication key has an invalid length


<pre><code><b>const</b> <a href="account.md#0x1_account_EMALFORMED_AUTHENTICATION_KEY">EMALFORMED_AUTHENTICATION_KEY</a>: u64 = 4;
</code></pre>



<a id="0x1_account_ENO_CAPABILITY"></a>

The caller does not have a digital-signature-based capability to call this function


<pre><code><b>const</b> <a href="account.md#0x1_account_ENO_CAPABILITY">ENO_CAPABILITY</a>: u64 = 9;
</code></pre>



<a id="0x1_account_ENO_SIGNER_CAPABILITY_OFFERED"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_ENO_SIGNER_CAPABILITY_OFFERED">ENO_SIGNER_CAPABILITY_OFFERED</a>: u64 = 19;
</code></pre>



<a id="0x1_account_ENO_SUCH_ROTATION_CAPABILITY_OFFER"></a>

The specified rotation capablity offer does not exist at the specified offerer address


<pre><code><b>const</b> <a href="account.md#0x1_account_ENO_SUCH_ROTATION_CAPABILITY_OFFER">ENO_SUCH_ROTATION_CAPABILITY_OFFER</a>: u64 = 18;
</code></pre>



<a id="0x1_account_ENO_SUCH_SIGNER_CAPABILITY"></a>

The signer capability offer doesn't exist at the given address


<pre><code><b>const</b> <a href="account.md#0x1_account_ENO_SUCH_SIGNER_CAPABILITY">ENO_SUCH_SIGNER_CAPABILITY</a>: u64 = 14;
</code></pre>



<a id="0x1_account_ENO_VALID_FRAMEWORK_RESERVED_ADDRESS"></a>

Address to create is not a valid reserved address for Endless framework


<pre><code><b>const</b> <a href="account.md#0x1_account_ENO_VALID_FRAMEWORK_RESERVED_ADDRESS">ENO_VALID_FRAMEWORK_RESERVED_ADDRESS</a>: u64 = 11;
</code></pre>



<a id="0x1_account_EOFFERER_ADDRESS_DOES_NOT_EXIST"></a>

Offerer address doesn't exist


<pre><code><b>const</b> <a href="account.md#0x1_account_EOFFERER_ADDRESS_DOES_NOT_EXIST">EOFFERER_ADDRESS_DOES_NOT_EXIST</a>: u64 = 17;
</code></pre>



<a id="0x1_account_EOUT_OF_GAS"></a>

Transaction exceeded its allocated max gas


<pre><code><b>const</b> <a href="account.md#0x1_account_EOUT_OF_GAS">EOUT_OF_GAS</a>: u64 = 6;
</code></pre>



<a id="0x1_account_ERESOURCE_ACCCOUNT_EXISTS"></a>

An attempt to create a resource account on a claimed account


<pre><code><b>const</b> <a href="account.md#0x1_account_ERESOURCE_ACCCOUNT_EXISTS">ERESOURCE_ACCCOUNT_EXISTS</a>: u64 = 15;
</code></pre>



<a id="0x1_account_ESEQUENCE_NUMBER_TOO_BIG"></a>

Sequence number exceeds the maximum value for a u64


<pre><code><b>const</b> <a href="account.md#0x1_account_ESEQUENCE_NUMBER_TOO_BIG">ESEQUENCE_NUMBER_TOO_BIG</a>: u64 = 3;
</code></pre>



<a id="0x1_account_EUNEXPECTED"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_EUNEXPECTED">EUNEXPECTED</a>: u64 = 21;
</code></pre>



<a id="0x1_account_EWRONG_CURRENT_PUBLIC_KEY"></a>

Specified current public key is not correct


<pre><code><b>const</b> <a href="account.md#0x1_account_EWRONG_CURRENT_PUBLIC_KEY">EWRONG_CURRENT_PUBLIC_KEY</a>: u64 = 7;
</code></pre>



<a id="0x1_account_MAX_AUTH_KEY_SIZE"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_MAX_AUTH_KEY_SIZE">MAX_AUTH_KEY_SIZE</a>: u64 = 16;
</code></pre>



<a id="0x1_account_MAX_GUID_CREATION_NUM"></a>

Explicitly separate the GUID space between Object and Account to prevent accidental overlap.


<pre><code><b>const</b> <a href="account.md#0x1_account_MAX_GUID_CREATION_NUM">MAX_GUID_CREATION_NUM</a>: u64 = 1125899906842624;
</code></pre>



<a id="0x1_account_MAX_MAP_SIZE"></a>



<pre><code><b>const</b> <a href="account.md#0x1_account_MAX_MAP_SIZE">MAX_MAP_SIZE</a>: u64 = 100;
</code></pre>



<a id="0x1_account_MULTI_ED25519_SCHEME"></a>

Scheme identifier for MultiEd25519 signatures used to derive authentication keys for MultiEd25519 public keys.


<pre><code><b>const</b> <a href="account.md#0x1_account_MULTI_ED25519_SCHEME">MULTI_ED25519_SCHEME</a>: u8 = 1;
</code></pre>



<a id="0x1_account_initialize"></a>

## Function `initialize`

Only called during genesis to initialize system resources for this module.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <a href="system_addresses.md#0x1_system_addresses_assert_endless_framework">system_addresses::assert_endless_framework</a>(endless_framework);
    <b>move_to</b>(endless_framework, <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
        address_map: <a href="../../endless-stdlib/doc/table.md#0x1_table_new">table::new</a>(),
    });
}
</code></pre>



</details>

<a id="0x1_account_create_account_if_does_not_exist"></a>

## Function `create_account_if_does_not_exist`



<pre><code><b>fun</b> <a href="account.md#0x1_account_create_account_if_does_not_exist">create_account_if_does_not_exist</a>(account_address: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="account.md#0x1_account_create_account_if_does_not_exist">create_account_if_does_not_exist</a>(account_address: <b>address</b>) {
    <b>if</b> (!<b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(account_address)) {
        <a href="account.md#0x1_account_create_account">create_account</a>(account_address);
    }
}
</code></pre>



</details>

<a id="0x1_account_create_account"></a>

## Function `create_account`

Publishes a new <code><a href="account.md#0x1_account_Account">Account</a></code> resource under <code>new_address</code>. A signer representing <code>new_address</code>
is returned. This way, the caller of this function can publish additional resources under
<code>new_address</code>.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_create_account">create_account</a>(new_address: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_create_account">create_account</a>(new_address: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a> {
    // there cannot be an <a href="account.md#0x1_account_Account">Account</a> resource under new_addr already.
    <b>assert</b>!(!<b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(new_address), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_already_exists">error::already_exists</a>(<a href="account.md#0x1_account_EACCOUNT_ALREADY_EXISTS">EACCOUNT_ALREADY_EXISTS</a>));

    // NOTE: @core_resources gets created via a `create_account` call, so we do not <b>include</b> it below.
    <b>assert</b>!(
        new_address != @vm_reserved && new_address != @endless_framework && new_address != @endless_token,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_ECANNOT_RESERVED_ADDRESS">ECANNOT_RESERVED_ADDRESS</a>)
    );

    <a href="account.md#0x1_account_create_account_unchecked">create_account_unchecked</a>(new_address)
}
</code></pre>



</details>

<a id="0x1_account_create_account_unchecked"></a>

## Function `create_account_unchecked`



<pre><code><b>fun</b> <a href="account.md#0x1_account_create_account_unchecked">create_account_unchecked</a>(new_address: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="account.md#0x1_account_create_account_unchecked">create_account_unchecked</a>(new_address: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a> {
    <b>let</b> new_account = <a href="create_signer.md#0x1_create_signer">create_signer</a>(new_address);
    <b>let</b> authentication_key = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(&new_address);
    <b>assert</b>!(
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&authentication_key) == 32,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EMALFORMED_AUTHENTICATION_KEY">EMALFORMED_AUTHENTICATION_KEY</a>)
    );
    <b>let</b> guid_creation_num = 0;

    <b>move_to</b>(
        &new_account,
        <a href="account.md#0x1_account_Account">Account</a> {
            authentication_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[authentication_key],
            sequence_number: 0,
            guid_creation_num,
            num_signatures_required: 1,
        }
    );

    new_account
}
</code></pre>



</details>

<a id="0x1_account_exists_at"></a>

## Function `exists_at`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_exists_at">exists_at</a>(addr: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_exists_at">exists_at</a>(addr: <b>address</b>): bool {
    <b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr)
}
</code></pre>



</details>

<a id="0x1_account_get_guid_next_creation_num"></a>

## Function `get_guid_next_creation_num`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_guid_next_creation_num">get_guid_next_creation_num</a>(addr: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_guid_next_creation_num">get_guid_next_creation_num</a>(addr: <b>address</b>): u64 <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).guid_creation_num
}
</code></pre>



</details>

<a id="0x1_account_get_sequence_number"></a>

## Function `get_sequence_number`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_sequence_number">get_sequence_number</a>(addr: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_sequence_number">get_sequence_number</a>(addr: <b>address</b>): u64 <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).sequence_number
}
</code></pre>



</details>

<a id="0x1_account_increment_sequence_number"></a>

## Function `increment_sequence_number`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_increment_sequence_number">increment_sequence_number</a>(addr: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_increment_sequence_number">increment_sequence_number</a>(addr: <b>address</b>) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <b>let</b> sequence_number = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).sequence_number;

    <b>assert</b>!(
        (*sequence_number <b>as</b> u128) &lt; <a href="account.md#0x1_account_MAX_U64">MAX_U64</a>,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_out_of_range">error::out_of_range</a>(<a href="account.md#0x1_account_ESEQUENCE_NUMBER_TOO_BIG">ESEQUENCE_NUMBER_TOO_BIG</a>)
    );

    *sequence_number = *sequence_number + 1;
}
</code></pre>



</details>

<a id="0x1_account_num_signatures_required"></a>

## Function `num_signatures_required`

Return the number of signatures required


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_num_signatures_required">num_signatures_required</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_num_signatures_required">num_signatures_required</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): u64 <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(<a href="account.md#0x1_account">account</a>).num_signatures_required
}
</code></pre>



</details>

<a id="0x1_account_get_authentication_key"></a>

## Function `get_authentication_key`

Return the authentication key


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_authentication_key">get_authentication_key</a>(addr: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_authentication_key">get_authentication_key</a>(addr: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt; <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).authentication_key
}
</code></pre>



</details>

<a id="0x1_account_check_authentication_key"></a>

## Function `check_authentication_key`

Check the authentication key, return true if
1. every key in auth_key is in authentication_key
2. the number of keys in auth_key is at least num_signatures_required


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_check_authentication_key">check_authentication_key</a>(addr: <b>address</b>, auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_check_authentication_key">check_authentication_key</a>(addr: <b>address</b>, auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;): bool <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <b>let</b> resource = <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
    <b>let</b> authentication_key = resource.authentication_key;
    <b>let</b> size = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&auth_key);
    // Requirements not met
    <b>if</b> (size &lt; resource.num_signatures_required) {
        <b>return</b> <b>false</b>
    };
    <b>let</b> total = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&authentication_key);
    // Too many auth key
    <b>if</b> (size &gt; total) {
        <b>return</b> <b>false</b>
    };
    <b>while</b> (size &gt; 0) {
        <b>let</b> key = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>(&<b>mut</b> auth_key);
        // Do not <b>use</b> `contains` <b>to</b> check, because auth key maybe have duplicate key
        <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove_value">vector::remove_value</a>(&<b>mut</b> authentication_key, &key))) {
            <b>return</b> <b>false</b>
        };
        size = size - 1;
    };
    <b>true</b>
}
</code></pre>



</details>

<a id="0x1_account_is_original_account"></a>

## Function `is_original_account`

Check is the account is original, return true if
1. the <code><a href="account.md#0x1_account_Account">Account</a></code> resource under <code><a href="account.md#0x1_account">account</a></code> exists
2. there is only one key in authentication_key
3. the only key in authentication_key is <code><a href="account.md#0x1_account">account</a></code> self


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_is_original_account">is_original_account</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_is_original_account">is_original_account</a>(<a href="account.md#0x1_account">account</a>: <b>address</b>): bool <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <b>if</b> (!<a href="account.md#0x1_account_exists_at">exists_at</a>(<a href="account.md#0x1_account">account</a>)) {
        <b>return</b> <b>false</b>
    };

    <b>let</b> authentication_key = <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(<a href="account.md#0x1_account">account</a>).authentication_key;
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&authentication_key) != 1) {
        <b>return</b> <b>false</b>
    };
    *<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&authentication_key, 0) == <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(&<a href="account.md#0x1_account">account</a>)
}
</code></pre>



</details>

<a id="0x1_account_check_duplication"></a>

## Function `check_duplication`



<pre><code><b>fun</b> <a href="account.md#0x1_account_check_duplication">check_duplication</a>(vec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="account.md#0x1_account_check_duplication">check_duplication</a>(vec: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;) {
    <b>let</b> new_vec = <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[];
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_reverse">vector::for_each_reverse</a>(vec, |v| {
        <b>assert</b>!(!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_contains">vector::contains</a>(&new_vec, &v), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EDUPLICATE_AUTHENTICATION_KEY">EDUPLICATE_AUTHENTICATION_KEY</a>));
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> new_vec, v);
    });
}
</code></pre>



</details>

<a id="0x1_account_rotate_authentication_key_internal"></a>

## Function `rotate_authentication_key_internal`

This function is used to rotate a resource account's authentication key to <code>new_auth_key</code>. This is done in
many contexts:
1. During normal key rotation via <code>rotate_authentication_key</code> or <code>rotate_authentication_key_call</code>
2. During resource account initialization so that no private key can control the resource account
3. During multisig_v2 account creation


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_rotate_authentication_key_internal">rotate_authentication_key_internal</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_rotate_authentication_key_internal">rotate_authentication_key_internal</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a>, <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
    // Check duplication for `new_auth_key`
    <a href="account.md#0x1_account_check_duplication">check_duplication</a>(new_auth_key);
    <b>assert</b>!(<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&new_auth_key) &lt;= <a href="account.md#0x1_account_MAX_AUTH_KEY_SIZE">MAX_AUTH_KEY_SIZE</a>, <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_AUTHENTICATION_KEY_COUNT">EINVALID_AUTHENTICATION_KEY_COUNT</a>));
    <b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>);
    <b>assert</b>!(<a href="account.md#0x1_account_exists_at">exists_at</a>(addr), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_not_found">error::not_found</a>(<a href="account.md#0x1_account_EACCOUNT_DOES_NOT_EXIST">EACCOUNT_DOES_NOT_EXIST</a>));
    <b>let</b> account_resource = <b>borrow_global_mut</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
    <a href="account.md#0x1_account_update_auth_key_and_originating_address_table">update_auth_key_and_originating_address_table</a>(addr, account_resource, new_auth_key);
}
</code></pre>



</details>

<a id="0x1_account_add_authentication_key"></a>

## Function `add_authentication_key`

Add <code>new_author</code> to the account's <code>authentication_key</code>.


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_add_authentication_key">add_authentication_key</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_author: &auth)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_add_authentication_key">add_authentication_key</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_author: &auth) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a>, <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
    <b>let</b> new_auth_key = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(new_author);
    <b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>);
    <b>let</b> authentication_key = <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).authentication_key;
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_contains">vector::contains</a>(&authentication_key, &new_auth_key)) {
        <b>return</b>
    };
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> authentication_key, new_auth_key);
    <a href="account.md#0x1_account_rotate_authentication_key_internal">rotate_authentication_key_internal</a>(<a href="account.md#0x1_account">account</a>, authentication_key);
}
</code></pre>



</details>

<a id="0x1_account_batch_add_authentication_key"></a>

## Function `batch_add_authentication_key`

Similar to <code>add_authentication_key</code> but batch adding
And can set <code>num_signatures_required</code>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_batch_add_authentication_key">batch_add_authentication_key</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_authors: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;auth&gt;, num_signatures_required: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_batch_add_authentication_key">batch_add_authentication_key</a>(
    <a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    new_authors: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;auth&gt;,
    num_signatures_required: u64,
) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a>, <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
    <b>let</b> authentication_key = <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>)).authentication_key;
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each">vector::for_each</a>(new_authors, |author| {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> authentication_key, <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(&author));
    });
    <a href="account.md#0x1_account_rotate_authentication_key_internal">rotate_authentication_key_internal</a>(<a href="account.md#0x1_account">account</a>, authentication_key);
    <a href="account.md#0x1_account_set_num_signatures_required">set_num_signatures_required</a>(<a href="account.md#0x1_account">account</a>, num_signatures_required);
}
</code></pre>



</details>

<a id="0x1_account_create_multisig_account"></a>

## Function `create_multisig_account`

Create a multisig account which owned by <code>owners</code>
Note that <code>creator</code> is not included unless it is one of <code>owners</code>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_create_multisig_account">create_multisig_account</a>(creator: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, owners: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;auth&gt;, num_signatures_required: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_create_multisig_account">create_multisig_account</a>(
    creator: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    owners: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;auth&gt;,
    num_signatures_required: u64
) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a>, <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
    <a href="account.md#0x1_account_create_multisig_account_public">create_multisig_account_public</a>(creator, owners, num_signatures_required);
}
</code></pre>



</details>

<a id="0x1_account_create_multisig_account_public"></a>

## Function `create_multisig_account_public`

See <code>create_multisig_account</code> and return the multisig account address


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_multisig_account_public">create_multisig_account_public</a>(_creator: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, owners: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;auth&gt;, num_signatures_required: u64): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_multisig_account_public">create_multisig_account_public</a>(
    _creator: <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    owners: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;auth&gt;,
    num_signatures_required: u64
): <b>address</b> <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a>, <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
    <b>let</b> unique_address = <a href="transaction_context.md#0x1_transaction_context_generate_auid_address">transaction_context::generate_auid_address</a>();
    <b>assert</b>!(!<a href="account.md#0x1_account_exists_at">exists_at</a>(unique_address), <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EACCOUNT_ALREADY_EXISTS">EACCOUNT_ALREADY_EXISTS</a>));
    <b>let</b> <a href="account.md#0x1_account">account</a> = <a href="account.md#0x1_account_create_account_unchecked">create_account_unchecked</a>(unique_address);
    <a href="account.md#0x1_account_batch_add_authentication_key">batch_add_authentication_key</a>(&<a href="account.md#0x1_account">account</a>, owners, num_signatures_required);
    // Remove multisig <a href="account.md#0x1_account">account</a> self auth key
    <a href="account.md#0x1_account_remove_authentication_key">remove_authentication_key</a>(&<a href="account.md#0x1_account">account</a>, <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(&unique_address));
    unique_address
}
</code></pre>



</details>

<a id="0x1_account_swap_authentication_key"></a>

## Function `swap_authentication_key`

Replace <code>old_auth_key</code> with <code>new_auth</code>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_swap_authentication_key">swap_authentication_key</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_auth: &auth, old_auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_swap_authentication_key">swap_authentication_key</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_auth: &auth, old_auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a>, <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
    <b>let</b> new_auth_key = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(new_auth);
    <b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>);
    <b>let</b> authentication_key = <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).authentication_key;
    // If `old_auth_key` is not in `authentication_key`, do nothing.
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove_value">vector::remove_value</a>(&<b>mut</b> authentication_key, &old_auth_key);
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> authentication_key, new_auth_key);
    <a href="account.md#0x1_account_rotate_authentication_key_internal">rotate_authentication_key_internal</a>(<a href="account.md#0x1_account">account</a>, authentication_key);
}
</code></pre>



</details>

<a id="0x1_account_remove_authentication_key"></a>

## Function `remove_authentication_key`

Remove <code>auth_key</code> from the account's <code>authentication_key</code>.
If the <code>auth_key</code> is not in the account's <code>authentication_key</code>, this function will do nothing.
If the <code>authentication_key</code>'s length less than <code>num_signatures_required</code> after remove, it will fail


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_remove_authentication_key">remove_authentication_key</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_remove_authentication_key">remove_authentication_key</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a>, <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
    <b>assert</b>!(
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&auth_key) == 32,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EMALFORMED_AUTHENTICATION_KEY">EMALFORMED_AUTHENTICATION_KEY</a>)
    );
    <b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>);
    <b>let</b> resource = <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
    <b>let</b> authentication_key = resource.authentication_key;
    // Not exist
    <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove_value">vector::remove_value</a>(&<b>mut</b> authentication_key, &auth_key))) {
        <b>return</b>
    };
    <b>assert</b>!(
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&authentication_key) &gt;= resource.num_signatures_required,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_AUTHENTICATION_KEY_COUNT">EINVALID_AUTHENTICATION_KEY_COUNT</a>)
    );
    <a href="account.md#0x1_account_rotate_authentication_key_internal">rotate_authentication_key_internal</a>(<a href="account.md#0x1_account">account</a>, authentication_key);
}
</code></pre>



</details>

<a id="0x1_account_batch_remove_authentication_key"></a>

## Function `batch_remove_authentication_key`

Similar to <code>remove_authentication_key</code> but batch removing
And can update <code>num_signatures_required</code>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_batch_remove_authentication_key">batch_remove_authentication_key</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, auth_keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, num_signatures_required: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_batch_remove_authentication_key">batch_remove_authentication_key</a>(
    <a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>,
    auth_keys: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;,
    num_signatures_required: u64,
) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a>, <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
    <b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>);
    <b>let</b> authentication_key = <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).authentication_key;
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each">vector::for_each</a>(auth_keys, |k| {
        <b>assert</b>!(
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&k) == 32,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EMALFORMED_AUTHENTICATION_KEY">EMALFORMED_AUTHENTICATION_KEY</a>)
        );
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove_value">vector::remove_value</a>(&<b>mut</b> authentication_key, &k);
    });
    <a href="account.md#0x1_account_rotate_authentication_key_internal">rotate_authentication_key_internal</a>(<a href="account.md#0x1_account">account</a>, authentication_key);
    <a href="account.md#0x1_account_set_num_signatures_required">set_num_signatures_required</a>(<a href="account.md#0x1_account">account</a>, num_signatures_required);
}
</code></pre>



</details>

<a id="0x1_account_set_num_signatures_required"></a>

## Function `set_num_signatures_required`

Update the number of signatures required, it will fail if
1. <code>num_signatures_required</code> is 0
2. <code>num_signatures_required</code> is greater than the number of keys in <code>authentication_key</code>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_set_num_signatures_required">set_num_signatures_required</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, num_signatures_required: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="account.md#0x1_account_set_num_signatures_required">set_num_signatures_required</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, num_signatures_required: u64) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <b>assert</b>!(
        num_signatures_required &gt; 0,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_NUM_SIGNATURES_REQUIRED">EINVALID_NUM_SIGNATURES_REQUIRED</a>)
    );
    <b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>);
    <b>let</b> resource = <b>borrow_global_mut</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
    <b>assert</b>!(
        <a href="account.md#0x1_account_num_signatures_required">num_signatures_required</a> &lt;= <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(&resource.authentication_key),
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_NUM_SIGNATURES_REQUIRED">EINVALID_NUM_SIGNATURES_REQUIRED</a>)
    );
    <b>if</b> (resource.num_signatures_required == num_signatures_required) {
        <b>return</b>
    };
    <a href="event.md#0x1_event_emit">event::emit</a>(<a href="account.md#0x1_account_UpdateSignaturesRequired">UpdateSignaturesRequired</a> {
        <a href="account.md#0x1_account">account</a>: addr,
        old_num_signatures_required: resource.num_signatures_required,
        new_num_signatures_required: num_signatures_required,
    });
    resource.num_signatures_required = num_signatures_required;
}
</code></pre>



</details>

<a id="0x1_account_vector_diff"></a>

## Function `vector_diff`

Compare <code><b>old</b></code> and <code>new</code>, return added and removed
example:
old = [1, 2, 3]
new = [2, 3, 4]
return ([4], [1])


<pre><code><b>fun</b> <a href="account.md#0x1_account_vector_diff">vector_diff</a>(<b>old</b>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, new: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;): (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="account.md#0x1_account_vector_diff">vector_diff</a>(<b>old</b>: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, new: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;): (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;) {
    <b>let</b> added = new;
    <b>let</b> removed = <b>old</b>;
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_reverse">vector::for_each_reverse</a>(<b>old</b>, |v| {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove_value">vector::remove_value</a>(&<b>mut</b> added, &v);
    });
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_reverse">vector::for_each_reverse</a>(new, |v| {
        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove_value">vector::remove_value</a>(&<b>mut</b> removed, &v);
    });
    (added, removed)
}
</code></pre>



</details>

<a id="0x1_account_update_auth_key_and_originating_address_table"></a>

## Function `update_auth_key_and_originating_address_table`

Update the <code><a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a></code> table, so that we can find the originating address using the latest address
in the event of key recovery.


<pre><code><b>fun</b> <a href="account.md#0x1_account_update_auth_key_and_originating_address_table">update_auth_key_and_originating_address_table</a>(originating_addr: <b>address</b>, account_resource: &<b>mut</b> <a href="account.md#0x1_account_Account">account::Account</a>, new_auth_key_vector: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="account.md#0x1_account_update_auth_key_and_originating_address_table">update_auth_key_and_originating_address_table</a>(
    originating_addr: <b>address</b>,
    account_resource: &<b>mut</b> <a href="account.md#0x1_account_Account">Account</a>,
    new_auth_key_vector: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;,
) <b>acquires</b> <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
    <b>if</b> (<b>exists</b>&lt;<a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a>&gt;(@endless_framework)) {
        <b>let</b> address_map = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a>&gt;(@endless_framework).address_map;
        <b>let</b> old_authentication_key = account_resource.authentication_key;
        <b>let</b> (added, removed) = <a href="account.md#0x1_account_vector_diff">vector_diff</a>(old_authentication_key, new_auth_key_vector);

        <b>if</b> (!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&added)) {
            <a href="event.md#0x1_event_emit">event::emit</a>(<a href="account.md#0x1_account_AddAuthenticationKey">AddAuthenticationKey</a> {
                <a href="account.md#0x1_account">account</a>: originating_addr,
                auth_keys: added,
            });
        };

        <b>if</b> (!<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&removed)) {
            <a href="event.md#0x1_event_emit">event::emit</a>(<a href="account.md#0x1_account_RemoveAuthenticationKey">RemoveAuthenticationKey</a> {
                <a href="account.md#0x1_account">account</a>: originating_addr,
                auth_keys: removed,
            });
        };

        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_reverse">vector::for_each_reverse</a>(removed, |v| {
            <b>if</b> (<a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(address_map, v)) {
                <b>let</b> list = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow_mut">table::borrow_mut</a>(address_map, v);
                <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_remove_value">vector::remove_value</a>(list, &originating_addr);
                // Remove <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a> when it's empty
                <b>if</b> (<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(list)) {
                    <a href="../../endless-stdlib/doc/table.md#0x1_table_remove">table::remove</a>(address_map, v);
                };
            }
        });

        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_for_each_reverse">vector::for_each_reverse</a>(added, |v| {
            <b>let</b> added_addr = <a href="../../endless-stdlib/doc/from_bcs.md#0x1_from_bcs_to_address">from_bcs::to_address</a>(v);
            <b>if</b> (added_addr != originating_addr) {
                <b>if</b> (<a href="../../endless-stdlib/doc/table.md#0x1_table_contains">table::contains</a>(address_map, v)) {
                    <b>let</b> list = <a href="../../endless-stdlib/doc/table.md#0x1_table_borrow_mut">table::borrow_mut</a>(address_map, v);
                    <b>assert</b>!(
                        // If already exist, there is a bug
                        !<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_contains">vector::contains</a>(list, &originating_addr),
                        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_internal">error::internal</a>(<a href="account.md#0x1_account_EUNEXPECTED">EUNEXPECTED</a>)
                    );
                    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(list, originating_addr);
                    <b>assert</b>!(
                        <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(list) &lt;= <a href="account.md#0x1_account_MAX_MAP_SIZE">MAX_MAP_SIZE</a>,
                        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_AUTHENTICATION_KEY_COUNT">EINVALID_AUTHENTICATION_KEY_COUNT</a>)
                    );
                } <b>else</b> {
                    <a href="../../endless-stdlib/doc/table.md#0x1_table_add">table::add</a>(address_map, v, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[originating_addr]);
                };
            };
        });
    };

    // Update the <a href="account.md#0x1_account">account</a> resource's authentication key.
    account_resource.authentication_key = new_auth_key_vector;
}
</code></pre>



</details>

<a id="0x1_account_create_resource_address"></a>

## Function `create_resource_address`

Basic account creation methods.
This is a helper function to compute resource addresses. Computation of the address
involves the use of a cryptographic hash operation and should be use thoughtfully.


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_resource_address">create_resource_address</a>(source: &<b>address</b>, seed: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_resource_address">create_resource_address</a>(source: &<b>address</b>, seed: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): <b>address</b> {
    <b>let</b> bytes = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(source);
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_append">vector::append</a>(&<b>mut</b> bytes, seed);
    <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> bytes, <a href="account.md#0x1_account_DERIVE_RESOURCE_ACCOUNT_SCHEME">DERIVE_RESOURCE_ACCOUNT_SCHEME</a>);
    <a href="../../endless-stdlib/doc/from_bcs.md#0x1_from_bcs_to_address">from_bcs::to_address</a>(<a href="../../endless-stdlib/../move-stdlib/doc/hash.md#0x1_hash_sha3_256">hash::sha3_256</a>(bytes))
}
</code></pre>



</details>

<a id="0x1_account_create_resource_account"></a>

## Function `create_resource_account`

A resource account is used to manage resources independent of an account managed by a user.
In Endless a resource account is created based upon the sha3 256 of the source's address and additional seed data.
A resource account can only be created once, this is designated by setting the
<code>Account::signer_capability_offer::for</code> to the address of the resource account. While an entity may call
<code>create_account</code> to attempt to claim an account ahead of the creation of a resource account, if found Endless will
transition ownership of the account over to the resource account. This is done by validating that the account has
yet to execute any transactions and that the <code>Account::signer_capability_offer::for</code> is none. The probability of a
collision where someone has legitimately produced a private key that maps to a resource account address is less
than <code>(1/2)^(256)</code>.


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_resource_account">create_resource_account</a>(source: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, seed: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): (<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="account.md#0x1_account_SignerCapability">account::SignerCapability</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_resource_account">create_resource_account</a>(source: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, seed: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): (<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="account.md#0x1_account_SignerCapability">SignerCapability</a>) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a>, <a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a> {
    <b>let</b> resource_addr = <a href="account.md#0x1_account_create_resource_address">create_resource_address</a>(&<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(source), seed);
    <b>let</b> resource = <b>if</b> (<a href="account.md#0x1_account_exists_at">exists_at</a>(resource_addr)) {
        <b>let</b> <a href="account.md#0x1_account">account</a> = <b>borrow_global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(resource_addr);
        <b>assert</b>!(
            <a href="account.md#0x1_account">account</a>.sequence_number == 0,
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_state">error::invalid_state</a>(<a href="account.md#0x1_account_EACCOUNT_ALREADY_USED">EACCOUNT_ALREADY_USED</a>),
        );
        <a href="create_signer.md#0x1_create_signer">create_signer</a>(resource_addr)
    } <b>else</b> {
        <a href="account.md#0x1_account_create_account_unchecked">create_account_unchecked</a>(resource_addr)
    };

    // By default, only the <a href="account.md#0x1_account_SignerCapability">SignerCapability</a> should have control over the resource <a href="account.md#0x1_account">account</a> and not the auth key.
    // If the source <a href="account.md#0x1_account">account</a> wants direct control via auth key, they would need <b>to</b> explicitly rotate the auth key
    // of the resource <a href="account.md#0x1_account">account</a> using the <a href="account.md#0x1_account_SignerCapability">SignerCapability</a>.
    <a href="account.md#0x1_account_rotate_authentication_key_internal">rotate_authentication_key_internal</a>(&resource, <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>[]);

    <b>let</b> signer_cap = <a href="account.md#0x1_account_SignerCapability">SignerCapability</a> { <a href="account.md#0x1_account">account</a>: resource_addr };
    (resource, signer_cap)
}
</code></pre>



</details>

<a id="0x1_account_create_framework_reserved_account"></a>

## Function `create_framework_reserved_account`

create the account for system reserved addresses


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_create_framework_reserved_account">create_framework_reserved_account</a>(addr: <b>address</b>): (<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="account.md#0x1_account_SignerCapability">account::SignerCapability</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_create_framework_reserved_account">create_framework_reserved_account</a>(addr: <b>address</b>): (<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="account.md#0x1_account_SignerCapability">SignerCapability</a>) {
    <b>assert</b>!(
        addr == @0x1 ||
            addr == @0x2 ||
            addr == @0x3 ||
            addr == @0x4 ||
            addr == @0x5 ||
            addr == @0x6 ||
            addr == @0x7 ||
            addr == @0x8 ||
            addr == @0x9 ||
            addr == @0xa,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_permission_denied">error::permission_denied</a>(<a href="account.md#0x1_account_ENO_VALID_FRAMEWORK_RESERVED_ADDRESS">ENO_VALID_FRAMEWORK_RESERVED_ADDRESS</a>),
    );
    <b>let</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a> = <a href="account.md#0x1_account_create_account_unchecked">create_account_unchecked</a>(addr);
    <b>let</b> signer_cap = <a href="account.md#0x1_account_SignerCapability">SignerCapability</a> { <a href="account.md#0x1_account">account</a>: addr };
    (<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, signer_cap)
}
</code></pre>



</details>

<a id="0x1_account_create_guid"></a>

## Function `create_guid`

GUID management methods.


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_guid">create_guid</a>(account_signer: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): <a href="guid.md#0x1_guid_GUID">guid::GUID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_guid">create_guid</a>(account_signer: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): <a href="guid.md#0x1_guid_GUID">guid::GUID</a> <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(account_signer);
    <b>let</b> <a href="account.md#0x1_account">account</a> = <b>borrow_global_mut</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
    <b>let</b> <a href="guid.md#0x1_guid">guid</a> = <a href="guid.md#0x1_guid_create">guid::create</a>(addr, &<b>mut</b> <a href="account.md#0x1_account">account</a>.guid_creation_num);
    <b>assert</b>!(
        <a href="account.md#0x1_account">account</a>.guid_creation_num &lt; <a href="account.md#0x1_account_MAX_GUID_CREATION_NUM">MAX_GUID_CREATION_NUM</a>,
        <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_out_of_range">error::out_of_range</a>(<a href="account.md#0x1_account_EEXCEEDED_MAX_GUID_CREATION_NUM">EEXCEEDED_MAX_GUID_CREATION_NUM</a>),
    );
    <a href="guid.md#0x1_guid">guid</a>
}
</code></pre>



</details>

<a id="0x1_account_new_event_handle"></a>

## Function `new_event_handle`

GUID management methods.


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_new_event_handle">new_event_handle</a>&lt;T: drop, store&gt;(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): <a href="event.md#0x1_event_EventHandle">event::EventHandle</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_new_event_handle">new_event_handle</a>&lt;T: drop + store&gt;(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): EventHandle&lt;T&gt; <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <a href="event.md#0x1_event_new_event_handle">event::new_event_handle</a>(<a href="account.md#0x1_account_create_guid">create_guid</a>(<a href="account.md#0x1_account">account</a>))
}
</code></pre>



</details>

<a id="0x1_account_create_signer_with_capability"></a>

## Function `create_signer_with_capability`

Capability based functions for efficient use.


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_signer_with_capability">create_signer_with_capability</a>(capability: &<a href="account.md#0x1_account_SignerCapability">account::SignerCapability</a>): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_signer_with_capability">create_signer_with_capability</a>(capability: &<a href="account.md#0x1_account_SignerCapability">SignerCapability</a>): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a> {
    <b>let</b> addr = &capability.<a href="account.md#0x1_account">account</a>;
    <a href="create_signer.md#0x1_create_signer">create_signer</a>(*addr)
}
</code></pre>



</details>

<a id="0x1_account_get_signer_capability_address"></a>

## Function `get_signer_capability_address`



<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_signer_capability_address">get_signer_capability_address</a>(capability: &<a href="account.md#0x1_account_SignerCapability">account::SignerCapability</a>): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_signer_capability_address">get_signer_capability_address</a>(capability: &<a href="account.md#0x1_account_SignerCapability">SignerCapability</a>): <b>address</b> {
    capability.<a href="account.md#0x1_account">account</a>
}
</code></pre>



</details>

<a id="0x1_account_verify_signed_message"></a>

## Function `verify_signed_message`



<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_verify_signed_message">verify_signed_message</a>&lt;T: drop&gt;(<a href="account.md#0x1_account">account</a>: <b>address</b>, account_scheme: u8, account_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, signed_message_bytes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, message: T)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_verify_signed_message">verify_signed_message</a>&lt;T: drop&gt;(
    <a href="account.md#0x1_account">account</a>: <b>address</b>,
    account_scheme: u8,
    account_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    signed_message_bytes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    message: T,
) <b>acquires</b> <a href="account.md#0x1_account_Account">Account</a> {
    <b>let</b> account_resource = <b>borrow_global_mut</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(<a href="account.md#0x1_account">account</a>);
    // Verify that the `SignerCapabilityOfferProofChallengeV2` <b>has</b> the right information and is signed by the <a href="account.md#0x1_account">account</a> owner's key
    <b>if</b> (account_scheme == <a href="account.md#0x1_account_ED25519_SCHEME">ED25519_SCHEME</a>) {
        <b>let</b> pubkey = <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519_new_unvalidated_public_key_from_bytes">ed25519::new_unvalidated_public_key_from_bytes</a>(account_public_key);
        <b>let</b> expected_auth_key = <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519_unvalidated_public_key_to_authentication_key">ed25519::unvalidated_public_key_to_authentication_key</a>(&pubkey);
        <b>assert</b>!(
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_contains">vector::contains</a>(&account_resource.authentication_key, &expected_auth_key),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EWRONG_CURRENT_PUBLIC_KEY">EWRONG_CURRENT_PUBLIC_KEY</a>),
        );

        <b>let</b> signer_capability_sig = <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519_new_signature_from_bytes">ed25519::new_signature_from_bytes</a>(signed_message_bytes);
        <b>assert</b>!(
            <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519_signature_verify_strict_t">ed25519::signature_verify_strict_t</a>(&signer_capability_sig, &pubkey, message),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_PROOF_OF_KNOWLEDGE">EINVALID_PROOF_OF_KNOWLEDGE</a>),
        );
    } <b>else</b> <b>if</b> (account_scheme == <a href="account.md#0x1_account_MULTI_ED25519_SCHEME">MULTI_ED25519_SCHEME</a>) {
        <b>let</b> pubkey = <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519_new_unvalidated_public_key_from_bytes">multi_ed25519::new_unvalidated_public_key_from_bytes</a>(account_public_key);
        <b>let</b> expected_auth_key = <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519_unvalidated_public_key_to_authentication_key">multi_ed25519::unvalidated_public_key_to_authentication_key</a>(&pubkey);
        <b>assert</b>!(
            <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_contains">vector::contains</a>(&account_resource.authentication_key, &expected_auth_key),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EWRONG_CURRENT_PUBLIC_KEY">EWRONG_CURRENT_PUBLIC_KEY</a>),
        );

        <b>let</b> signer_capability_sig = <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519_new_signature_from_bytes">multi_ed25519::new_signature_from_bytes</a>(signed_message_bytes);
        <b>assert</b>!(
            <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519_signature_verify_strict_t">multi_ed25519::signature_verify_strict_t</a>(&signer_capability_sig, &pubkey, message),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_PROOF_OF_KNOWLEDGE">EINVALID_PROOF_OF_KNOWLEDGE</a>),
        );
    } <b>else</b> {
        <b>abort</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_SCHEME">EINVALID_SCHEME</a>)
    };
}
</code></pre>



</details>

<a id="0x1_account_verify_signed_message_unauthenised_pubkey"></a>

## Function `verify_signed_message_unauthenised_pubkey`



<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_verify_signed_message_unauthenised_pubkey">verify_signed_message_unauthenised_pubkey</a>&lt;T: drop&gt;(account_scheme: u8, account_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, signed_message_bytes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, message: T)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_verify_signed_message_unauthenised_pubkey">verify_signed_message_unauthenised_pubkey</a>&lt;T: drop&gt;(
    account_scheme: u8,
    account_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    signed_message_bytes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    message: T,
) {
    // Verify that the `SignerCapabilityOfferProofChallengeV2` <b>has</b> the right information and is signed by the <a href="account.md#0x1_account">account</a> owner's key
    <b>if</b> (account_scheme == <a href="account.md#0x1_account_ED25519_SCHEME">ED25519_SCHEME</a>) {
        <b>let</b> pubkey = <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519_new_unvalidated_public_key_from_bytes">ed25519::new_unvalidated_public_key_from_bytes</a>(account_public_key);

        <b>let</b> signer_capability_sig = <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519_new_signature_from_bytes">ed25519::new_signature_from_bytes</a>(signed_message_bytes);
        <b>assert</b>!(
            <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519_signature_verify_strict_t">ed25519::signature_verify_strict_t</a>(&signer_capability_sig, &pubkey, message),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_PROOF_OF_KNOWLEDGE">EINVALID_PROOF_OF_KNOWLEDGE</a>),
        );
    } <b>else</b> <b>if</b> (account_scheme == <a href="account.md#0x1_account_MULTI_ED25519_SCHEME">MULTI_ED25519_SCHEME</a>) {
        <b>let</b> pubkey = <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519_new_unvalidated_public_key_from_bytes">multi_ed25519::new_unvalidated_public_key_from_bytes</a>(account_public_key);

        <b>let</b> signer_capability_sig = <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519_new_signature_from_bytes">multi_ed25519::new_signature_from_bytes</a>(signed_message_bytes);
        <b>assert</b>!(
            <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519_signature_verify_strict_t">multi_ed25519::signature_verify_strict_t</a>(&signer_capability_sig, &pubkey, message),
            <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_PROOF_OF_KNOWLEDGE">EINVALID_PROOF_OF_KNOWLEDGE</a>),
        );
    } <b>else</b> {
        <b>abort</b> <a href="../../endless-stdlib/../move-stdlib/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="account.md#0x1_account_EINVALID_SCHEME">EINVALID_SCHEME</a>)
    };
}
</code></pre>



</details>

<a id="@Specification_1"></a>

## Specification




<a id="high-level-req"></a>

### High-level Requirements

<table>
<tr>
<th>No.</th><th>Requirement</th><th>Criticality</th><th>Implementation</th><th>Enforcement</th>
</tr>

<tr>
<td>1</td>
<td>The initialization of the account module should result in the proper system initialization with valid and consistent resources.</td>
<td>High</td>
<td>Initialization of the account module creates a valid address_map table and moves the resources to the OriginatingAddress under the endless_framework account.</td>
<td>Audited that the address_map table is created and populated correctly with the expected initial values.</td>
</tr>

<tr>
<td>2</td>
<td>After successfully creating an account, the account resources should initialize with the default data, ensuring the proper initialization of the account state.</td>
<td>High</td>
<td>Creating an account via the create_account function validates the state and moves a new account resource under new_address.</td>
<td>Formally verified via <a href="#high-level-req-2">create_account</a>.</td>
</tr>

<tr>
<td>3</td>
<td>Checking the existence of an account under a given address never results in an abort.</td>
<td>Low</td>
<td>The exists_at function returns a boolean value indicating the existence of an account under the given address.</td>
<td>Formally verified by the <a href="#high-level-req-3">aborts_if</a> condition.</td>
</tr>

<tr>
<td>4</td>
<td>The account module maintains bounded sequence numbers for all accounts, guaranteeing they remain within the specified limit.</td>
<td>Medium</td>
<td>The sequence number of an account may only increase up to MAX_U64 in a succeeding manner.</td>
<td>Formally verified via <a href="#high-level-req-4">increment_sequence_number</a> that it remains within the defined boundary of MAX_U64.</td>
</tr>

<tr>
<td>5</td>
<td>Only the ed25519 and multied25519 signature schemes are permissible.</td>
<td>Low</td>
<td>Exclusively perform key rotation using either the ed25519 or multied25519 signature schemes. Currently restricts the offering of rotation/signing capabilities to the ed25519 or multied25519 schemes.</td>
<td>Formally Verified: <a href="#high-level-req-5.1">rotate_authentication_key</a>, <a href="#high-level-req-5.2">offer_rotation_capability</a>, and <a href="#high-level-req-5.3">offer_signer_capability</a>. Verified that it aborts if the account_scheme is not ED25519_SCHEME and not MULTI_ED25519_SCHEME. Audited that the scheme enums correspond correctly to signature logic.</td>
</tr>

<tr>
<td>6</td>
<td>Exclusively permit the rotation of the authentication key of an account for the account owner or any user who possesses rotation capabilities associated with that account.</td>
<td>Critical</td>
<td>In the rotate_authentication_key function, the authentication key derived from the from_public_key_bytes should match the signer's current authentication key. Only the delegate_signer granted the rotation capabilities may invoke the rotate_authentication_key_with_rotation_capability function.</td>
<td>Formally Verified via <a href="#high-level-req-6.1">rotate_authentication_key</a> and <a href="#high-level-req-6.2">rotate_authentication_key_with_rotation_capability</a>.</td>
</tr>

<tr>
<td>7</td>
<td>Only the owner of an account may offer or revoke the following capabilities: (1) offer_rotation_capability, (2) offer_signer_capability, (3) revoke_rotation_capability, and (4) revoke_signer_capability.</td>
<td>Critical</td>
<td>An account resource may only be modified by the owner of the account utilizing: rotation_capability_offer, signer_capability_offer.</td>
<td>Formally verified via <a href="#high-level-req-7.1">offer_rotation_capability</a>, <a href="#high-level-req-7.2">offer_signer_capability</a>, and <a href="#high-level-req-7.3">revoke_rotation_capability</a>. and <a href="#high-level-req-7.4">revoke_signer_capability</a>.</td>
</tr>

<tr>
<td>8</td>
<td>The capability to create a signer for the account is exclusively reserved for either the account owner or the account that has been granted the signing capabilities.</td>
<td>Critical</td>
<td>Signer creation for the account may only be successfully executed by explicitly granting the signing capabilities with the create_authorized_signer function.</td>
<td>Formally verified via <a href="#high-level-req-8">create_authorized_signer</a>.</td>
</tr>

<tr>
<td>9</td>
<td>Rotating the authentication key requires two valid signatures. With the private key of the current authentication key. With the private key of the new authentication key.</td>
<td>Critical</td>
<td>The rotate_authentication_key verifies two signatures (current and new) before rotating to the new key. The first signature ensures the user has the intended capability, and the second signature ensures that the user owns the new key.</td>
<td>Formally verified via <a href="#high-level-req-9.1">rotate_authentication_key</a> and <a href="#high-level-req-9.2">rotate_authentication_key_with_rotation_capability</a>.</td>
</tr>

<tr>
<td>10</td>
<td>The rotation of the authentication key updates the account's authentication key with the newly supplied one.</td>
<td>High</td>
<td>The auth_key may only update to the provided new_auth_key after verifying the signature.</td>
<td>Formally Verified in <a href="#high-level-req-10">rotate_authentication_key_internal</a> that the authentication key of an account is modified to the provided authentication key if the signature verification was successful.</td>
</tr>

<tr>
<td>11</td>
<td>The creation number is monotonically increasing.</td>
<td>Low</td>
<td>The guid_creation_num in the Account structure is monotonically increasing.</td>
<td>Formally Verified via <a href="#high-level-req-11">guid_creation_num</a>.</td>
</tr>

<tr>
<td>12</td>
<td>The Account resource is persistent.</td>
<td>Low</td>
<td>The Account structure assigned to the address should be persistent.</td>
<td>Audited that the Account structure is persistent.</td>
</tr>

</table>




<a id="module-level-spec"></a>

### Module-level Specification


<pre><code><b>pragma</b> verify = <b>true</b>;
<b>pragma</b> aborts_if_is_strict;
</code></pre>



<a id="@Specification_1_initialize"></a>

### Function `initialize`


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_initialize">initialize</a>(endless_framework: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>


Only the address <code>@endless_framework</code> can call.
OriginatingAddress does not exist under <code>@endless_framework</code> before the call.


<pre><code><b>let</b> endless_addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(endless_framework);
<b>aborts_if</b> !<a href="system_addresses.md#0x1_system_addresses_is_endless_framework_address">system_addresses::is_endless_framework_address</a>(endless_addr);
<b>aborts_if</b> <b>exists</b>&lt;<a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a>&gt;(endless_addr);
<b>ensures</b> <b>exists</b>&lt;<a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a>&gt;(endless_addr);
</code></pre>



<a id="@Specification_1_create_account_if_does_not_exist"></a>

### Function `create_account_if_does_not_exist`


<pre><code><b>fun</b> <a href="account.md#0x1_account_create_account_if_does_not_exist">create_account_if_does_not_exist</a>(account_address: <b>address</b>)
</code></pre>


Ensure that the account exists at the end of the call.


<pre><code><b>let</b> authentication_key = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(account_address);
<b>aborts_if</b> !<b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(account_address) && (
    account_address == @vm_reserved
    || account_address == @endless_framework
    || account_address == @endless_token
    || !(len(authentication_key) == 32)
);
<b>ensures</b> <b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(account_address);
</code></pre>



<a id="@Specification_1_create_account"></a>

### Function `create_account`


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_create_account">create_account</a>(new_address: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>
</code></pre>


Check if the bytes of the new address is 32.
The Account does not exist under the new address before creating the account.
Limit the new account address is not @vm_reserved / @endless_framework / @endless_toke.


<pre><code><b>include</b> <a href="account.md#0x1_account_CreateAccountAbortsIf">CreateAccountAbortsIf</a> {addr: new_address};
<b>aborts_if</b> new_address == @vm_reserved || new_address == @endless_framework || new_address == @endless_token;
<b>ensures</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(result) == new_address;
// This enforces <a id="high-level-req-2" href="#high-level-req">high-level requirement 2</a>:
<b>ensures</b> <b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(new_address);
</code></pre>



<a id="@Specification_1_create_account_unchecked"></a>

### Function `create_account_unchecked`


<pre><code><b>fun</b> <a href="account.md#0x1_account_create_account_unchecked">create_account_unchecked</a>(new_address: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>
</code></pre>


Check if the bytes of the new address is 32.
The Account does not exist under the new address before creating the account.


<pre><code><b>include</b> <a href="account.md#0x1_account_CreateAccountAbortsIf">CreateAccountAbortsIf</a> {addr: new_address};
<b>ensures</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(result) == new_address;
<b>ensures</b> <b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(new_address);
</code></pre>



<a id="@Specification_1_exists_at"></a>

### Function `exists_at`


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_exists_at">exists_at</a>(addr: <b>address</b>): bool
</code></pre>




<pre><code>// This enforces <a id="high-level-req-3" href="#high-level-req">high-level requirement 3</a>:
<b>aborts_if</b> <b>false</b>;
</code></pre>




<a id="0x1_account_CreateAccountAbortsIf"></a>


<pre><code><b>schema</b> <a href="account.md#0x1_account_CreateAccountAbortsIf">CreateAccountAbortsIf</a> {
    addr: <b>address</b>;
    <b>let</b> authentication_key = <a href="../../endless-stdlib/../move-stdlib/doc/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(addr);
    <b>aborts_if</b> len(authentication_key) != 32;
    <b>aborts_if</b> <b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
    <b>ensures</b> len(authentication_key) == 32;
}
</code></pre>



<a id="@Specification_1_get_guid_next_creation_num"></a>

### Function `get_guid_next_creation_num`


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_guid_next_creation_num">get_guid_next_creation_num</a>(addr: <b>address</b>): u64
</code></pre>




<pre><code><b>aborts_if</b> !<b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
<b>ensures</b> result == <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).guid_creation_num;
</code></pre>



<a id="@Specification_1_get_sequence_number"></a>

### Function `get_sequence_number`


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_sequence_number">get_sequence_number</a>(addr: <b>address</b>): u64
</code></pre>




<pre><code><b>aborts_if</b> !<b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
<b>ensures</b> result == <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).sequence_number;
</code></pre>



<a id="@Specification_1_increment_sequence_number"></a>

### Function `increment_sequence_number`


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_increment_sequence_number">increment_sequence_number</a>(addr: <b>address</b>)
</code></pre>


The Account existed under the address.
The sequence_number of the Account is up to MAX_U64.


<pre><code><b>let</b> sequence_number = <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).sequence_number;
<b>aborts_if</b> !<b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
// This enforces <a id="high-level-req-4" href="#high-level-req">high-level requirement 4</a>:
<b>aborts_if</b> sequence_number == <a href="account.md#0x1_account_MAX_U64">MAX_U64</a>;
<b>modifies</b> <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
<b>let</b> <b>post</b> post_sequence_number = <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).sequence_number;
<b>ensures</b> post_sequence_number == sequence_number + 1;
</code></pre>



<a id="@Specification_1_get_authentication_key"></a>

### Function `get_authentication_key`


<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="account.md#0x1_account_get_authentication_key">get_authentication_key</a>(addr: <b>address</b>): <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;
</code></pre>




<pre><code><b>aborts_if</b> !<b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
<b>ensures</b> result == <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).authentication_key;
</code></pre>



<a id="@Specification_1_rotate_authentication_key_internal"></a>

### Function `rotate_authentication_key_internal`


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_rotate_authentication_key_internal">rotate_authentication_key_internal</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, new_auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;)
</code></pre>


The Account existed under the signer before the call.
The length of new_auth_key is 32.


<pre><code><b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(<a href="account.md#0x1_account">account</a>);
// This enforces <a id="high-level-req-10" href="#high-level-req">high-level requirement 10</a>:
<b>let</b> <b>post</b> account_resource = <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
<b>aborts_if</b> !<b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
<b>aborts_if</b> <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(new_auth_key) != 32;
<b>modifies</b> <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
<b>ensures</b> account_resource.authentication_key == new_auth_key;
</code></pre>



<a id="@Specification_1_update_auth_key_and_originating_address_table"></a>

### Function `update_auth_key_and_originating_address_table`


<pre><code><b>fun</b> <a href="account.md#0x1_account_update_auth_key_and_originating_address_table">update_auth_key_and_originating_address_table</a>(originating_addr: <b>address</b>, account_resource: &<b>mut</b> <a href="account.md#0x1_account_Account">account::Account</a>, new_auth_key_vector: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;)
</code></pre>




<pre><code><b>modifies</b> <b>global</b>&lt;<a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a>&gt;(@endless_framework);
<b>include</b> <a href="account.md#0x1_account_UpdateAuthKeyAndOriginatingAddressTableAbortsIf">UpdateAuthKeyAndOriginatingAddressTableAbortsIf</a>;
</code></pre>




<a id="0x1_account_UpdateAuthKeyAndOriginatingAddressTableAbortsIf"></a>


<pre><code><b>schema</b> <a href="account.md#0x1_account_UpdateAuthKeyAndOriginatingAddressTableAbortsIf">UpdateAuthKeyAndOriginatingAddressTableAbortsIf</a> {
    originating_addr: <b>address</b>;
    account_resource: <a href="account.md#0x1_account_Account">Account</a>;
    new_auth_key_vector: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;;
    <b>let</b> address_map = <b>global</b>&lt;<a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a>&gt;(@endless_framework).address_map;
    <b>aborts_if</b> !<b>exists</b>&lt;<a href="account.md#0x1_account_OriginatingAddress">OriginatingAddress</a>&gt;(@endless_framework);
}
</code></pre>



<a id="@Specification_1_create_resource_address"></a>

### Function `create_resource_address`


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_resource_address">create_resource_address</a>(source: &<b>address</b>, seed: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): <b>address</b>
</code></pre>


The Account existed under the signer
The authentication scheme is ED25519_SCHEME and MULTI_ED25519_SCHEME
The Account existed under the signer
The value of signer_capability_offer.for of Account resource under the signer is to_be_revoked_address


<pre><code><b>pragma</b> opaque;
<b>pragma</b> aborts_if_is_strict = <b>false</b>;
<b>aborts_if</b> [abstract] <b>false</b>;
<b>ensures</b> [abstract] result == <a href="account.md#0x1_account_spec_create_resource_address">spec_create_resource_address</a>(source, seed);
</code></pre>




<a id="0x1_account_spec_create_resource_address"></a>


<pre><code><b>fun</b> <a href="account.md#0x1_account_spec_create_resource_address">spec_create_resource_address</a>(source: <b>address</b>, seed: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): <b>address</b>;
</code></pre>



<a id="@Specification_1_create_resource_account"></a>

### Function `create_resource_account`


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_resource_account">create_resource_account</a>(source: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, seed: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;): (<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="account.md#0x1_account_SignerCapability">account::SignerCapability</a>)
</code></pre>




<pre><code><b>let</b> source_addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(source);
<b>let</b> resource_addr = <a href="account.md#0x1_account_spec_create_resource_address">spec_create_resource_address</a>(source_addr, seed);
<b>include</b> <a href="account.md#0x1_account_exists_at">exists_at</a>(resource_addr) ==&gt; <a href="account.md#0x1_account_CreateResourceAccountAbortsIf">CreateResourceAccountAbortsIf</a>;
<b>include</b> !<a href="account.md#0x1_account_exists_at">exists_at</a>(resource_addr) ==&gt; <a href="account.md#0x1_account_CreateAccountAbortsIf">CreateAccountAbortsIf</a> {addr: resource_addr};
<b>ensures</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(result_1) == resource_addr;
<b>ensures</b> result_2 == <a href="account.md#0x1_account_SignerCapability">SignerCapability</a> { <a href="account.md#0x1_account">account</a>: resource_addr };
</code></pre>



<a id="@Specification_1_create_framework_reserved_account"></a>

### Function `create_framework_reserved_account`


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="account.md#0x1_account_create_framework_reserved_account">create_framework_reserved_account</a>(addr: <b>address</b>): (<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <a href="account.md#0x1_account_SignerCapability">account::SignerCapability</a>)
</code></pre>


Check if the bytes of the new address is 32.
The Account does not exist under the new address before creating the account.
The system reserved addresses is @0x1 / @0x2 / @0x3 / @0x4 / @0x5  / @0x6 / @0x7 / @0x8 / @0x9 / @0xa.


<pre><code><b>aborts_if</b> <a href="account.md#0x1_account_spec_is_framework_address">spec_is_framework_address</a>(addr);
<b>include</b> <a href="account.md#0x1_account_CreateAccountAbortsIf">CreateAccountAbortsIf</a> {addr};
<b>ensures</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(result_1) == addr;
<b>ensures</b> result_2 == <a href="account.md#0x1_account_SignerCapability">SignerCapability</a> { <a href="account.md#0x1_account">account</a>: addr };
</code></pre>




<a id="0x1_account_spec_is_framework_address"></a>


<pre><code><b>fun</b> <a href="account.md#0x1_account_spec_is_framework_address">spec_is_framework_address</a>(addr: <b>address</b>): bool{
   addr != @0x1 &&
   addr != @0x2 &&
   addr != @0x3 &&
   addr != @0x4 &&
   addr != @0x5 &&
   addr != @0x6 &&
   addr != @0x7 &&
   addr != @0x8 &&
   addr != @0x9 &&
   addr != @0xa
}
</code></pre>



<a id="@Specification_1_create_guid"></a>

### Function `create_guid`


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_guid">create_guid</a>(account_signer: &<a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>): <a href="guid.md#0x1_guid_GUID">guid::GUID</a>
</code></pre>


The Account existed under the signer.
The guid_creation_num of the ccount resource is up to MAX_U64.


<pre><code><b>let</b> addr = <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(account_signer);
<b>modifies</b> <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr);
// This enforces <a id="high-level-req-11" href="#high-level-req">high-level requirement 11</a>:
<b>ensures</b> <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).guid_creation_num == <b>old</b>(<b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).guid_creation_num) + 1;
</code></pre>



<a id="@Specification_1_create_signer_with_capability"></a>

### Function `create_signer_with_capability`


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_create_signer_with_capability">create_signer_with_capability</a>(capability: &<a href="account.md#0x1_account_SignerCapability">account::SignerCapability</a>): <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>
</code></pre>




<pre><code><b>let</b> addr = capability.<a href="account.md#0x1_account">account</a>;
<b>ensures</b> <a href="../../endless-stdlib/../move-stdlib/doc/signer.md#0x1_signer_address_of">signer::address_of</a>(result) == addr;
</code></pre>




<a id="0x1_account_CreateResourceAccountAbortsIf"></a>


<pre><code><b>schema</b> <a href="account.md#0x1_account_CreateResourceAccountAbortsIf">CreateResourceAccountAbortsIf</a> {
    resource_addr: <b>address</b>;
    <b>let</b> <a href="account.md#0x1_account">account</a> = <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(resource_addr);
    <b>aborts_if</b> <a href="account.md#0x1_account">account</a>.sequence_number != 0;
}
</code></pre>



<a id="@Specification_1_verify_signed_message"></a>

### Function `verify_signed_message`


<pre><code><b>public</b> <b>fun</b> <a href="account.md#0x1_account_verify_signed_message">verify_signed_message</a>&lt;T: drop&gt;(<a href="account.md#0x1_account">account</a>: <b>address</b>, account_scheme: u8, account_public_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, signed_message_bytes: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, message: T)
</code></pre>




<pre><code><b>pragma</b> aborts_if_is_partial;
<b>modifies</b> <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(<a href="account.md#0x1_account">account</a>);
<b>let</b> account_resource = <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(<a href="account.md#0x1_account">account</a>);
<b>aborts_if</b> !<b>exists</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(<a href="account.md#0x1_account">account</a>);
<b>include</b> account_scheme == <a href="account.md#0x1_account_ED25519_SCHEME">ED25519_SCHEME</a> ==&gt; <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519_NewUnvalidatedPublicKeyFromBytesAbortsIf">ed25519::NewUnvalidatedPublicKeyFromBytesAbortsIf</a> { bytes: account_public_key };
<b>aborts_if</b> account_scheme == <a href="account.md#0x1_account_ED25519_SCHEME">ED25519_SCHEME</a> && ({
    <b>let</b> expected_auth_key = <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519_spec_public_key_bytes_to_authentication_key">ed25519::spec_public_key_bytes_to_authentication_key</a>(account_public_key);
    !<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_spec_contains">vector::spec_contains</a>(account_resource.authentication_key, expected_auth_key)
});
<b>include</b> account_scheme == <a href="account.md#0x1_account_MULTI_ED25519_SCHEME">MULTI_ED25519_SCHEME</a> ==&gt; <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519_NewUnvalidatedPublicKeyFromBytesAbortsIf">multi_ed25519::NewUnvalidatedPublicKeyFromBytesAbortsIf</a> { bytes: account_public_key };
<b>aborts_if</b> account_scheme == <a href="account.md#0x1_account_MULTI_ED25519_SCHEME">MULTI_ED25519_SCHEME</a> && ({
    <b>let</b> expected_auth_key = <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519_spec_public_key_bytes_to_authentication_key">multi_ed25519::spec_public_key_bytes_to_authentication_key</a>(account_public_key);
    !<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_spec_contains">vector::spec_contains</a>(account_resource.authentication_key, expected_auth_key)
});
<b>include</b> account_scheme == <a href="account.md#0x1_account_ED25519_SCHEME">ED25519_SCHEME</a> ==&gt; <a href="../../endless-stdlib/doc/ed25519.md#0x1_ed25519_NewSignatureFromBytesAbortsIf">ed25519::NewSignatureFromBytesAbortsIf</a> { bytes: signed_message_bytes };
<b>include</b> account_scheme == <a href="account.md#0x1_account_MULTI_ED25519_SCHEME">MULTI_ED25519_SCHEME</a> ==&gt; <a href="../../endless-stdlib/doc/multi_ed25519.md#0x1_multi_ed25519_NewSignatureFromBytesAbortsIf">multi_ed25519::NewSignatureFromBytesAbortsIf</a> { bytes: signed_message_bytes };
<b>aborts_if</b> account_scheme != <a href="account.md#0x1_account_ED25519_SCHEME">ED25519_SCHEME</a> && account_scheme != <a href="account.md#0x1_account_MULTI_ED25519_SCHEME">MULTI_ED25519_SCHEME</a>;
</code></pre>




<a id="0x1_account_spec_check_authentication_key"></a>


<pre><code><b>fun</b> <a href="account.md#0x1_account_spec_check_authentication_key">spec_check_authentication_key</a>(addr: <b>address</b>, auth_key: <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;&gt;): bool {
   <b>let</b> authentication_key = <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).authentication_key;
   <b>let</b> num_signatures_required = <b>global</b>&lt;<a href="account.md#0x1_account_Account">Account</a>&gt;(addr).num_signatures_required;
   <a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_length">vector::length</a>(auth_key) &gt;= num_signatures_required
       && !(<b>exists</b> k in auth_key: !<a href="../../endless-stdlib/../move-stdlib/doc/vector.md#0x1_vector_spec_contains">vector::spec_contains</a>(authentication_key, k))
}
</code></pre>


[move-book]: https://endless.dev/move/book/SUMMARY

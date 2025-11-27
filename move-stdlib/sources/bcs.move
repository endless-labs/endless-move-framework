/// Utility for converting a Move value to its binary representation in BCS (Binary Canonical
/// Serialization). BCS is the binary encoding for Move resources and other non-module values
/// published on-chain. See https://github.com/endless-labs/bcs#binary-canonical-serialization-bcs for more
/// details on BCS.
module std::bcs {
    use std::option::Option;

    /// Return the binary representation of `v` in BCS (Binary Canonical Serialization) format
    native public fun to_bytes<MoveValue>(v: &MoveValue): vector<u8>;

    /// Return the size of the binary representation of `v` in BCS format
    public fun serialized_size<MoveValue>(v: &MoveValue): u64 {
        std::vector::length(&to_bytes(v))
    }

    /// Return the constant size of the binary representation of type `MoveValue` in BCS format
    /// Returns Some(size) if the type has a constant size, None otherwise
    native public fun constant_serialized_size<MoveValue>(): Option<u64>;

    // ==============================
    // Module Specification
    spec module {} // switch to module documentation context

    spec module {
        /// Native function which is defined in the prover's prelude.
        native fun serialize<MoveValue>(v: &MoveValue): vector<u8>;
    }
}

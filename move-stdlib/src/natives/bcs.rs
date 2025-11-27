// Copyright © Endless
// Copyright © Aptos Foundation

// Copyright (c) The Diem Core Contributors
// Copyright (c) The Move Contributors
// SPDX-License-Identifier: Apache-2.0

use endless_gas_schedule::gas_params::natives::move_stdlib::*;
use endless_native_interface::{
    safely_pop_arg, RawSafeNative, SafeNativeBuilder, SafeNativeContext, SafeNativeError,
    SafeNativeResult,
};
use move_core_types::{
    gas_algebra::NumBytes,
    value::{MoveStructLayout, MoveTypeLayout},
    vm_status::sub_status::NFE_BCS_SERIALIZATION_FAILURE,
};
use move_vm_runtime::native_functions::NativeFunction;
use move_vm_types::{
    loaded_data::runtime_types::Type,
    values::{values_impl::Reference, Struct, Value},
};
use smallvec::{smallvec, SmallVec};
use std::collections::VecDeque;

/// Helper function to compute the constant serialized size of a type layout
/// Returns Some(size) if the type has a constant size, None otherwise
fn compute_constant_size(layout: &MoveTypeLayout) -> Option<usize> {
    match layout {
        MoveTypeLayout::Bool => Some(1),
        MoveTypeLayout::U8 => Some(1),
        MoveTypeLayout::U16 => Some(2),
        MoveTypeLayout::U32 => Some(4),
        MoveTypeLayout::U64 => Some(8),
        MoveTypeLayout::U128 => Some(16),
        MoveTypeLayout::U256 => Some(32),
        MoveTypeLayout::Address => Some(32), // AccountAddress is 32 bytes
        MoveTypeLayout::Signer => Some(32),  // Signer is also 32 bytes
        MoveTypeLayout::Vector(_) => None,   // Vectors have variable size
        MoveTypeLayout::Struct(s) => {
            // Only handle Runtime variant
            match s {
                MoveStructLayout::Runtime(fields) => {
                    let mut total_size = 0;
                    for field_layout in fields {
                        match compute_constant_size(field_layout) {
                            Some(size) => total_size += size,
                            None => return None,
                        }
                    }
                    Some(total_size)
                },
                _ => None, // WithFields, WithTypes, and other variants are not constant size
            }
        },
        MoveTypeLayout::Native(_, inner) => compute_constant_size(inner),
        MoveTypeLayout::Auth => Some(32), // Auth is 32 bytes like Address
    }
}

/***************************************************************************************************
 * native fun to_bytes
 *
 *   gas cost: size_of(val_type) * input_unit_cost +        | get type layout
 *             size_of(val) * input_unit_cost +             | serialize value
 *             max(size_of(output), 1) * output_unit_cost
 *
 *             If any of the first two steps fails, a partial cost + an additional failure_cost
 *             will be charged.
 *
 **************************************************************************************************/
/// Rust implementation of Move's `native public fun to_bytes<T>(&T): vector<u8>`
#[inline]
fn native_to_bytes(
    context: &mut SafeNativeContext,
    mut ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> SafeNativeResult<SmallVec<[Value; 1]>> {
    debug_assert!(ty_args.len() == 1);
    debug_assert!(args.len() == 1);

    // pop type and value
    let ref_to_val = safely_pop_arg!(args, Reference);
    let arg_type = ty_args.pop().unwrap();

    // get type layout
    let layout = match context.type_to_type_layout(&arg_type) {
        Ok(layout) => layout,
        Err(_) => {
            context.charge(BCS_TO_BYTES_FAILURE)?;
            return Err(SafeNativeError::Abort {
                abort_code: NFE_BCS_SERIALIZATION_FAILURE,
            });
        },
    };

    // serialize value
    let val = ref_to_val.read_ref()?;
    let serialized_value = match val.simple_serialize(&layout) {
        Some(serialized_value) => serialized_value,
        None => {
            context.charge(BCS_TO_BYTES_FAILURE)?;
            return Err(SafeNativeError::Abort {
                abort_code: NFE_BCS_SERIALIZATION_FAILURE,
            });
        },
    };
    context
        .charge(BCS_TO_BYTES_PER_BYTE_SERIALIZED * NumBytes::new(serialized_value.len() as u64))?;

    Ok(smallvec![Value::vector_u8(serialized_value)])
}

/***************************************************************************************************
 * native fun constant_serialized_size
 *
 *   gas cost: minimal cost for type layout computation
 *
 **************************************************************************************************/
/// Rust implementation of Move's `native public fun constant_serialized_size<MoveValue>(): Option<u64>`
#[inline]
fn native_constant_serialized_size(
    context: &mut SafeNativeContext,
    mut ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> SafeNativeResult<SmallVec<[Value; 1]>> {
    debug_assert!(ty_args.len() == 1);
    debug_assert!(args.is_empty());

    // Charge a minimal gas cost
    context.charge(BCS_TO_BYTES_FAILURE)?;

    let arg_type = ty_args.pop().unwrap();

    // Get type layout
    let layout = match context.type_to_type_layout(&arg_type) {
        Ok(layout) => layout,
        Err(_) => {
            // If we can't get the layout, return None
            // Option<u64> is represented as Option { vec: vector<u64> }
            return Ok(smallvec![Value::struct_(Struct::pack(vec![
                Value::vector_u64(vec![]) // Empty vector for None
            ]))]);
        },
    };

    // Check if the type has a constant size using our helper function
    match compute_constant_size(&layout) {
        Some(size) => {
            // Return Some(size)
            // Option<u64> is represented as Option { vec: vector<u64> }
            Ok(smallvec![Value::struct_(Struct::pack(vec![
                Value::vector_u64(vec![size as u64]) // Vector with one element for Some
            ]))])
        },
        None => {
            // Type has variable size, return None
            // Option<u64> is represented as Option { vec: vector<u64> }
            Ok(smallvec![Value::struct_(Struct::pack(vec![
                Value::vector_u64(vec![]) // Empty vector for None
            ]))])
        },
    }
}

/***************************************************************************************************
 * module
 **************************************************************************************************/
pub fn make_all(
    builder: &SafeNativeBuilder,
) -> impl Iterator<Item = (String, NativeFunction)> + '_ {
    let funcs = [
        ("to_bytes", native_to_bytes as RawSafeNative),
        (
            "constant_serialized_size",
            native_constant_serialized_size as RawSafeNative,
        ),
    ];

    builder.make_named_natives(funcs)
}

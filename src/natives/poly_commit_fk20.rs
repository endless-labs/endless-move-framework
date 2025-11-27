use crate_crypto_internal_eth_kzg_bls12_381::{ff::PrimeField, G1Point, Scalar};
use endless_crypto::poly_commit::{
    fk20::{
        commit_key::CommitKey,
        opening_key::OpeningKey,
        prove::{compute_multi_opening, verify_multi_opening},
    },
    util::trusted_setup::TrustedSetup,
};
use endless_native_interface::{
    safely_pop_arg, RawSafeNative, SafeNativeBuilder, SafeNativeContext, SafeNativeResult,
};
use itertools::Itertools;
use move_core_types::u256::U256;
use move_vm_runtime::native_functions::NativeFunction;
use move_vm_types::{loaded_data::runtime_types::Type, values::Value};
use once_cell::sync::Lazy;
use smallvec::{smallvec, SmallVec};
use std::collections::VecDeque;

// 4096
pub const MAX_COMMIT_DATA_LENGTH: u64 = 4096;

pub static TRUST_SETUP: Lazy<TrustedSetup> = Lazy::new(TrustedSetup::default);
pub static COMMIT_KEY: Lazy<CommitKey> = Lazy::new(|| TRUST_SETUP.to_commit_key());
pub static OPEN_KEY: Lazy<OpeningKey> = Lazy::new(|| TRUST_SETUP.to_opening_key());

pub fn generate_commitment_native_test(
    _context: &mut SafeNativeContext,
    _ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> SafeNativeResult<SmallVec<[Value; 1]>> {
    debug_assert!(args.len() == 1);

    let mut polynomial = vec![];
    for d in safely_pop_arg!(args, Vec<Value>) {
        let v = d.value_as::<Vec<u8>>()?;
        polynomial.push(Scalar::from_u128(
            bcs::from_bytes::<u128>(v.as_slice()).unwrap(),
        ));
    }

    let commitment = COMMIT_KEY.commit_g1(&polynomial).to_compressed();

    Ok(smallvec![Value::vector_u8(commitment.to_vec())])
}

pub fn generate_proof_native_test(
    _context: &mut SafeNativeContext,
    _ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> SafeNativeResult<SmallVec<[Value; 1]>> {
    debug_assert!(args.len() == 3);

    let points: Vec<u64> = safely_pop_arg!(args, Vec<u64>);

    let mut polynomial = vec![];
    for d in safely_pop_arg!(args, Vec<Value>) {
        let v = d.value_as::<Vec<u8>>()?;
        polynomial.push(Scalar::from_u128(
            bcs::from_bytes::<u128>(v.as_slice()).unwrap(),
        ));
    }

    let _commitment = safely_pop_arg!(args, Vec<u8>);

    let points = points.iter().map(|p| Scalar::from(*p)).collect_vec();
    let (proof, output_points) = compute_multi_opening(&COMMIT_KEY, &polynomial, points.as_slice());
    let output_points_u256_vec = output_points
        .iter()
        .map(|p| bcs::from_bytes::<U256>(&p.to_bytes_le()).unwrap())
        .collect_vec();

    Ok(smallvec![
        Value::vector_u8(proof.to_compressed().as_ref().to_vec(),),
        Value::vector_u256(output_points_u256_vec),
    ])
}

pub fn verify_proof_native(
    _context: &mut SafeNativeContext,
    _ty_args: Vec<Type>,
    mut arguments: VecDeque<Value>,
) -> SafeNativeResult<SmallVec<[Value; 1]>> {
    debug_assert!(_ty_args.is_empty());
    debug_assert!(arguments.len() == 5);

    let domain_size = safely_pop_arg!(arguments, u64);

    assert!(domain_size <= MAX_COMMIT_DATA_LENGTH);

    let output_points: Vec<Value> = safely_pop_arg!(arguments, Vec<Value>);
    let mut output_points_scalar: Vec<_> = vec![];
    for v in output_points {
        let data_vec_u8 = v.value_as::<Vec<u8>>()?;
        let data_scalar =
            Scalar::from_bytes_le(<&[u8; 32]>::try_from(data_vec_u8.as_slice()).unwrap()).unwrap();
        output_points_scalar.push(data_scalar);
    }

    let point_x_list: Vec<_> = safely_pop_arg!(arguments, Vec<u64>);
    let commitment: Vec<_> = safely_pop_arg!(arguments, Vec<u8>);
    let proof: Vec<_> = safely_pop_arg!(arguments, Vec<u8>);

    let point_x_list = point_x_list.iter().map(|v| Scalar::from(*v)).collect_vec();
    let quotient_commitment =
        G1Point::from_compressed(<&[u8; 48]>::try_from(proof.as_slice()).unwrap()).unwrap();
    let commitment =
        G1Point::from_compressed(<&[u8; 48]>::try_from(commitment.as_slice()).unwrap()).unwrap();

    let verify_result = verify_multi_opening(
        quotient_commitment,
        &OPEN_KEY,
        commitment,
        &point_x_list,
        &output_points_scalar,
    );

    Ok(smallvec![Value::bool(verify_result)])
}

#[test]
pub fn multi_opening_fk20() {
    let degree: u64 = 16;
    let trust_setup = TrustedSetup::default();
    let (commit_key, opening_key) = (trust_setup.to_commit_key(), trust_setup.to_opening_key());

    let input_usize: [u64; 4] = [1, 2, 3, 4];

    let polynomial: Vec<_> = (0..degree).map(|i| Scalar::from(i * 2)).collect();
    let values: Vec<_> = input_usize
        .iter()
        .map(|p| polynomial.get(*p as usize).unwrap())
        .collect();
    println!("values {:?}", values);

    let input_points: Vec<_> = input_usize.iter().map(|i| Scalar::from(*i)).collect();

    let commitment = commit_key.commit_g1(&polynomial).to_compressed();

    println!("commitment {:?}", hex::encode(commitment),);

    let (quotient_proof, output_points) =
        compute_multi_opening(&commit_key, &polynomial, &input_points);

    println!("output_points {:?}", output_points);
    println!(
        "quotient_proof {:?}",
        hex::encode(quotient_proof.to_compressed())
    );

    let proof_valid = verify_multi_opening(
        quotient_proof,
        &opening_key,
        G1Point::from_compressed(<&[u8; 48]>::try_from(commitment.as_slice()).unwrap()).unwrap(),
        &input_points,
        &output_points,
    );
    assert!(proof_valid);
}

pub fn make_all(
    builder: &SafeNativeBuilder,
) -> impl Iterator<Item = (String, NativeFunction)> + '_ {
    let natives = [
        (
            "generate_commitment_native_test",
            generate_commitment_native_test as RawSafeNative,
        ),
        (
            "generate_proof_native_test",
            generate_proof_native_test as RawSafeNative,
        ),
        ("verify_proof_native", verify_proof_native as RawSafeNative),
    ];

    builder.make_named_natives(natives)
}

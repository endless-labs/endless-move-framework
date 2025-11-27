use endless_crypto::poly_commit::{
    ipa,
    ipa::{
        banderwagon::{Element, Fr},
        ipa_multipoint::multiproof::{MultiPointProof, VerifierQuery},
    },
};
use endless_native_interface::{
    safely_pop_arg, RawSafeNative, SafeNativeBuilder, SafeNativeContext, SafeNativeResult,
};
use itertools::Itertools;
use move_vm_runtime::native_functions::NativeFunction;
use move_vm_types::{loaded_data::runtime_types::Type, values::Value};
use smallvec::{smallvec, SmallVec};
use std::collections::VecDeque;

pub fn generate_commitment_native_test(
    _context: &mut SafeNativeContext,
    _ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> SafeNativeResult<SmallVec<[Value; 1]>> {
    debug_assert!(args.len() == 1);

    let mut datas = vec![];
    for d in safely_pop_arg!(args, Vec<Value>) {
        let v = d.value_as::<Vec<u8>>()?;
        datas.push(Fr::from(bcs::from_bytes::<u128>(v.as_slice()).unwrap()));
    }

    let commitment = ipa::generate_commitment(datas);

    Ok(smallvec![Value::vector_u8(commitment.to_bytes().to_vec())])
}

pub fn generate_proof_native_test(
    _context: &mut SafeNativeContext,
    _ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> SafeNativeResult<SmallVec<[Value; 1]>> {
    debug_assert!(args.len() == 3);

    let points = safely_pop_arg!(args, Vec<u64>);

    let mut datas = vec![];
    for d in safely_pop_arg!(args, Vec<Value>) {
        let v = d.value_as::<Vec<u8>>()?;
        datas.push(Fr::from(bcs::from_bytes::<u128>(v.as_slice()).unwrap()));
    }

    let commitment = safely_pop_arg!(args, Vec<u8>);
    let (proof, _) = ipa::generate_proof(Element::from_bytes(&commitment).unwrap(), datas, points);

    Ok(smallvec![Value::vector_u8(
        proof.to_bytes().unwrap().to_vec()
    ),])
}

pub fn verify_proof_native(
    _context: &mut SafeNativeContext,
    _ty_args: Vec<Type>,
    mut arguments: VecDeque<Value>,
) -> SafeNativeResult<SmallVec<[Value; 1]>> {
    debug_assert!(_ty_args.is_empty());
    debug_assert!(arguments.len() == 5);

    let domain_size = safely_pop_arg!(arguments, u64);

    let mut point_y_list = vec![];
    for y_value in safely_pop_arg!(arguments, Vec<Value>) {
        let y_bytes = y_value.value_as::<Vec<u8>>()?;
        point_y_list.push(Fr::from(
            bcs::from_bytes::<u128>(y_bytes.as_slice()).unwrap(),
        ));
    }

    let point_x_list = safely_pop_arg!(arguments, Vec<u64>);
    let commitment = safely_pop_arg!(arguments, Vec<u8>);
    let multiproof = safely_pop_arg!(arguments, Vec<u8>);

    let verifier_querys = point_y_list
        .iter()
        .zip(point_x_list)
        .map(|(point_y, point_x)| VerifierQuery {
            commitment: Element::from_bytes(&commitment).unwrap(),
            point: Fr::from(point_x),
            result: *point_y,
        })
        .collect_vec();

    let multi_point_proof =
        MultiPointProof::from_bytes(multiproof.as_slice(), domain_size as usize).unwrap();
    let verify_result = ipa::verify_proof(multi_point_proof, verifier_querys, domain_size as usize);

    Ok(smallvec![Value::bool(verify_result)])
}

#[test]
fn test() {
    let datas = (0..32).map(Fr::from).collect::<Vec<Fr>>();

    let commitment = ipa::generate_commitment(datas.clone());
    println!("commitment: {:?}", hex::encode(commitment.to_bytes()));

    let (multiproof, verifier_querys) =
        ipa::generate_proof(commitment, datas.clone(), vec![5, 6, 7, 8]);
    println!(
        "multiproof.open_proof: L_vec {:?} L_vec {:?}",
        multiproof.open_proof.L_vec.len(),
        multiproof.open_proof.R_vec.len()
    );
    println!(
        "multiproof.open_proof: {:?}\n",
        multiproof.to_bytes().unwrap().len()
    );
    let multiproof0 =
        MultiPointProof::from_bytes(multiproof.to_bytes().unwrap().as_slice(), datas.len())
            .unwrap();

    let check_time = ark_std::start_timer!(|| "Verify proof");
    assert!(ipa::verify_proof(multiproof0, verifier_querys, datas.len()));
    ark_std::end_timer!(check_time, || "End".to_string());
}

pub fn make_all(
    builder: &SafeNativeBuilder,
) -> impl Iterator<Item = (String, NativeFunction)> + '_ {
    let natives = [
        ("verify_proof_native", verify_proof_native as RawSafeNative),
        (
            "generate_proof_native_test",
            generate_proof_native_test as RawSafeNative,
        ),
        (
            "generate_commitment_native_test",
            generate_commitment_native_test as RawSafeNative,
        ),
    ];

    builder.make_named_natives(natives)
}

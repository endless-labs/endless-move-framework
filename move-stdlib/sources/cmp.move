module std::cmp {
    #[test_only]
    use std::option::Option;

    const LESS: u8 = 0;
    const EQUAL: u8 = 1;
    const GREATER: u8 = 2;

    struct Ordering has copy, drop {
        tag: u8,
    }

    fun new_less(): Ordering {
        Ordering { tag: LESS }
    }

    fun new_equal(): Ordering {
        Ordering { tag: EQUAL }
    }

    fun new_greater(): Ordering {
        Ordering { tag: GREATER }
    }

    /// Compares two values with the natural ordering:
    /// - native types are compared identically to `<` and other operators
    /// - complex types
    ///   - Structs and vectors - are compared lexicographically - first field/element is compared first,
    ///     and if equal we proceed to the next.
    ///   - enum's are compared first by their variant, and if equal - they are compared as structs are.
    native public fun compare<T>(first: &T, second: &T): Ordering;

    public fun is_eq(self: &Ordering): bool {
        self.tag == EQUAL
    }

    public fun is_ne(self: &Ordering): bool {
        self.tag != EQUAL
    }

    public fun is_lt(self: &Ordering): bool {
        self.tag == LESS
    }

    public fun is_le(self: &Ordering): bool {
        self.tag != GREATER
    }

    public fun is_gt(self: &Ordering): bool {
        self.tag == GREATER
    }

    public fun is_ge(self: &Ordering): bool {
        self.tag != LESS
    }

    spec compare {
        pragma intrinsic;
    }

    spec Ordering {
        pragma intrinsic;
    }

    spec is_eq {
        pragma intrinsic;
        pragma opaque;
        pragma verify = false;
    }

    spec is_ne {
        pragma intrinsic;
        pragma opaque;
        pragma verify = false;
    }

    spec is_lt {
        pragma intrinsic;
        pragma opaque;
        pragma verify = false;
    }

    spec is_le {
        pragma intrinsic;
        pragma opaque;
        pragma verify = false;
    }

    spec is_gt {
        pragma intrinsic;
        pragma opaque;
        pragma verify = false;
    }

    spec is_ge {
        pragma intrinsic;
        pragma opaque;
        pragma verify = false;
    }

    #[test_only]
    struct SomeStruct has drop {
        field_1: u64,
        field_2: u64,
    }

    #[test_only]
    struct SimpleEnumVData has drop {
        field: u64,
    }

    #[test_only]
    struct SimpleEnum has drop {
        tag: u8,
        V: Option<SimpleEnumVData>,
    }

    #[test_only]
    struct SomeEnumV1Data has drop {
        field_1: u64,
    }

    #[test_only]
    struct SomeEnumV2Data has drop {
        field_2: u64,
    }

    #[test_only]
    struct SomeEnumV3Data has drop {
        field_3: SomeStruct,
    }

    #[test_only]
    struct SomeEnumV4Data has drop {
        field_4: vector<u64>,
    }

    #[test_only]
    struct SomeEnumV5Data has drop {
        field_5: SimpleEnum,
    }

    #[test_only]
    struct SomeEnum has drop {
        tag: u8,
        V1: Option<SomeEnumV1Data>,
        V2: Option<SomeEnumV2Data>,
        V3: Option<SomeEnumV3Data>,
        V4: Option<SomeEnumV4Data>,
        V5: Option<SomeEnumV5Data>,
    }

    #[test]
    fun test_compare_numbers() {
        assert!(is_ne(&compare(&1, &5)), 0);
        assert!(!is_eq(&compare(&1, &5)), 0);
        assert!(is_lt(&compare(&1, &5)), 1);
        assert!(is_le(&compare(&1, &5)), 2);
        assert!(is_eq(&compare(&5, &5)), 3);
        assert!(!is_ne(&compare(&5, &5)), 3);
        assert!(!is_lt(&compare(&5, &5)), 4);
        assert!(is_le(&compare(&5, &5)), 5);
        assert!(!is_eq(&compare(&7, &5)), 6);
        assert!(is_ne(&compare(&7, &5)), 6);
        assert!(!is_lt(&compare(&7, &5)), 7);
        assert!(!is_le(&compare(&7, &5)), 8);

        assert!(!is_eq(&compare(&1, &5)), 0);
        assert!(is_ne(&compare(&1, &5)), 0);
        assert!(is_lt(&compare(&1, &5)), 1);
        assert!(is_le(&compare(&1, &5)), 2);
        assert!(!is_gt(&compare(&1, &5)), 1);
        assert!(!is_ge(&compare(&1, &5)), 1);
        assert!(is_eq(&compare(&5, &5)), 3);
        assert!(!is_ne(&compare(&5, &5)), 3);
        assert!(!is_lt(&compare(&5, &5)), 4);
        assert!(is_le(&compare(&5, &5)), 5);
        assert!(!is_gt(&compare(&5, &5)), 5);
        assert!(is_ge(&compare(&5, &5)), 5);
        assert!(!is_eq(&compare(&7, &5)), 6);
        assert!(is_ne(&compare(&7, &5)), 6);
        assert!(!is_lt(&compare(&7, &5)), 7);
        assert!(!is_le(&compare(&7, &5)), 8);
        assert!(is_gt(&compare(&7, &5)), 7);
        assert!(is_ge(&compare(&7, &5)), 8);
    }

    #[test]
    fun test_compare_vectors() {
        let empty = vector[]; // here for typing, for the second line
        assert!(is_lt(&compare(&empty, &vector[1])), 0);
        assert!(is_eq(&compare(&empty, &vector[])), 1);
        assert!(is_gt(&compare(&vector[1], &vector[])), 2);
        assert!(is_eq(&compare(&vector[1, 2], &vector[1, 2])), 3);
        assert!(is_lt(&compare(&vector[1, 2, 3], &vector[5])), 4);
        assert!(is_lt(&compare(&vector[1, 2, 3], &vector[5, 6, 7])), 5);
        assert!(is_lt(&compare(&vector[1, 2, 3], &vector[1, 2, 7])), 6);
    }

    #[test]
    fun test_compare_structs() {
        assert!(is_eq(&compare(&SomeStruct { field_1: 1, field_2: 2}, &SomeStruct { field_1: 1, field_2: 2})), 0);
        assert!(is_lt(&compare(&SomeStruct { field_1: 1, field_2: 2}, &SomeStruct { field_1: 1, field_2: 3})), 1);
        assert!(is_gt(&compare(&SomeStruct { field_1: 1, field_2: 2}, &SomeStruct { field_1: 1, field_2: 1})), 2);
        assert!(is_gt(&compare(&SomeStruct { field_1: 2, field_2: 1}, &SomeStruct { field_1: 1, field_2: 2})), 3);
    }

    #[test]
    fun test_compare_vector_of_structs() {
        assert!(is_lt(&compare(&vector[SomeStruct { field_1: 1, field_2: 2}, SomeStruct { field_1: 3, field_2: 4}], &vector[SomeStruct { field_1: 1, field_2: 3}])), 0);
        assert!(is_gt(&compare(&vector[SomeStruct { field_1: 1, field_2: 2}, SomeStruct { field_1: 3, field_2: 4}], &vector[SomeStruct { field_1: 1, field_2: 2}, SomeStruct { field_1: 1, field_2: 3}])), 1);
    }

    #[test]
    fun test_compare_enums() {
        // Skipping enum tests since we don't have enum support
    }

//     #[verify_only]
//     fun test_verify_compare_preliminary_types() {
//         spec {
//             assert compare(1, 5).is_ne();
//             assert !compare(1, 5).is_eq();
//             assert compare(1, 5).is_lt();
//             assert compare(1, 5).is_le();
//             assert compare(5, 5).is_eq();
//             assert !compare(5, 5).is_ne();
//             assert !compare(5, 5).is_lt();
//             assert compare(5, 5).is_le();
//             assert !compare(7, 5).is_eq();
//             assert compare(7, 5).is_ne();
//             assert !compare(7, 5).is_lt();
//             assert !compare(7, 5).is_le();
//             assert compare(false, true).is_ne();
//             assert compare(false, true).is_lt();
//             assert compare(true, false).is_ge();
//             assert compare(true, true).is_eq();
//         };
//     }

//     #[verify_only]
//     fun test_verify_compare_vectors() {
//         let empty: vector<u64> = vector[];
//         let v1 = vector[1 as u64];
//         let v8 = vector[1 as u8, 2];
//         let v32_1 = vector[1 as u32, 2, 3];
//         let v32_2 = vector[5 as u32];
//         spec {
//             assert compare(empty, v1).tag == LESS;
//             assert compare(empty, empty).tag == EQUAL;
//             assert compare(v1, empty).tag == GREATER;
//             assert compare(v8, v8).tag == EQUAL;
//             assert compare(v32_1, v32_2).tag == LESS;
//             assert compare(v32_2, v32_1).tag == GREATER;
//         };
//     }
// 
//     #[verify_only]
//     struct SomeStruct has drop {
//         field_1: u64,
//         field_2: u64,
//     }
// 
//     #[verify_only]
//     fun test_verify_compare_structs() {
//         let s1 = SomeStruct { field_1: 1, field_2: 2};
//         let s2 = SomeStruct { field_1: 1, field_2: 3};
//         let s3 = SomeStruct { field_1: 1, field_2: 1};
//         let s4 = SomeStruct { field_1: 2, field_2: 1};
//         spec {
//             assert compare(s1, s1).tag == EQUAL;
//             assert compare(s1, s2).tag == LESS;
//             assert compare(s1, s3).tag == GREATER;
//             assert compare(s4, s1).tag == GREATER;
//         };
//     }
// 
//     #[verify_only]
//     fun test_verify_compare_vector_of_structs() {
//         let v1 = vector[SomeStruct { field_1: 1, field_2: 2}];
//         let v2 = vector[SomeStruct { field_1: 1, field_2: 3}];
//         spec {
//             assert compare(v1, v2).tag == LESS;
//             assert compare(v1, v1).tag == EQUAL;
//         };
//     }
// 
//     #[verify_only]
//     struct SomeStruct_BV has copy,drop {
//         field: u64
//     }
// 
//     spec SomeStruct_BV  {
//         pragma bv=b"0";
//     }
// 
//     #[verify_only]
//     fun test_compare_bv() {
//         let a = 1;
//         let b = 5;
//         let se_a = SomeStruct_BV { field: a};
//         let se_b = SomeStruct_BV { field: b};
//         let v_a = vector[a];
//         let v_b = vector[b];
//         spec {
//             assert compare(a, b).tag == LESS;
//             assert compare(se_a, se_b).tag == LESS;
//             assert compare(v_a, v_b).tag == LESS;
//         };
//     }
// 
}

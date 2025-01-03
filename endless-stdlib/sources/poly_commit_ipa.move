module std::poly_commit_ipa {


    #[test_only]
    public native fun generate_commitment_native_test(data: vector<vector<u8>>): (vector<u8>);

    #[test_only]
    /// proof, point_y
    public native fun generate_proof_native_test(
        commitmnet: vector<u8>,
        data: vector<vector<u8>>,
        points_x: vector<u64>,
    ): vector<u8>;

    public native fun verify_proof_native(
        multiproof: vector<u8>,
        commitment: vector<u8>,
        points_x: vector<u64>,
        points_y: vector<vector<u8>>,
        domain_size: u64,
    ): bool;
}

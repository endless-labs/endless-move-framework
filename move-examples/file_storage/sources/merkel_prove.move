module file_storage::merkel_prove {

    use std::hash::sha3_256;
    use std::vector;
    use endless_std::math64;
    #[test_only]
    use std::fixed_point32;
    #[test_only]
    use std::string;

    const E_MERKEL_VERIFY_FAILED: u64 = 1;
    const E_TEST_FAILED: u64 = 10;

    /// Merkel tree hash node.
    struct MerkelNode has drop {
        hash: vector<u8>,

        // Left sibling if true. else right sibling.
        is_left: bool,
    }

    public fun calculate_merkel_root_by_offset_from_leaf(
        path_hashes: vector<vector<u8>>,
        prove_leaf_offset: u64,
        leaf: vector<u8>,
    ): vector<u8> {
        let path_nodes = convert_merkel_path_and_offset_to_nodes(path_hashes, prove_leaf_offset);
        calculate_merkel_root_from_leaf(leaf, path_nodes)
    }

    public fun calculate_merkel_root_by_tag_from_hash(
        path_hashes: vector<vector<u8>>,
        path_tag: vector<bool>,
        node_hash: vector<u8>,
    ): vector<u8> {
        let path_nodes = convert_merkel_path_and_tag_to_nodes(path_hashes, path_tag);
        calculate_merkel_root_from_hash(node_hash, path_nodes)
    }

    public fun calculate_merkel_root_from_hash(node_hash: vector<u8>, path: vector<MerkelNode>): vector<u8> {
        let calc_root = vector::fold(path, node_hash, |h, node| {
            let node: MerkelNode = node;
            let node_hash = node.hash;
            if (node.is_left) {
                vector::append(&mut node_hash, h);
                sha3_256(node_hash)
            } else {
                vector::append(&mut h, node_hash);
                sha3_256(h)
            }
        });

        calc_root
    }

    /// Calculate merkel root by leaf data and it's path nodes.
    /// `data`: Leaf data need to be verified.
    /// `path`: Sibling hash node from bottom to top.
    public fun calculate_merkel_root_from_leaf(leaf: vector<u8>, path: vector<MerkelNode>): vector<u8> {
        let calc_root = vector::fold(path, sha3_256(leaf), |h, node| {
            let node: MerkelNode = node;
            let node_hash = node.hash;
            if (node.is_left) {
                vector::append(&mut node_hash, h);
                sha3_256(node_hash)
            } else {
                vector::append(&mut h, node_hash);
                sha3_256(h)
            }
        });

        calc_root
    }

    /// Convert `path_hashes` to proof path nodes by adding some tag values.
    public fun convert_merkel_path_and_offset_to_nodes(
        path_hashes: vector<vector<u8>>,
        prove_leaf_offset: u64
    ): vector<MerkelNode> {
        let path = vector::empty<MerkelNode>();
        let path_len = vector::length(&path_hashes);
        assert!(prove_leaf_offset < math64::pow(2, path_len), E_TEST_FAILED);

        let node_index = prove_leaf_offset;
        vector::for_each(path_hashes, |hash| {
            vector::push_back(&mut path, MerkelNode {
                is_left: node_index % 2 == 1,
                hash
            });

            node_index = node_index / 2;
        });

        path
    }


    #[test_only]
    /// Tree is a b-tree, bottom is N leaf node hashes, tree height is H = (lg(N) + 1), leaf nodes store at first n element
    /// in tree vector, followed by H -1 layer node hashes, and so on. root hash is store and end of vector.
    public fun generate_merkel_proof_path(
        tree: &vector<vector<u8>>,
        leaf_offset: u64
    ): (vector<vector<u8>>, vector<bool>) {
        let leaf_num = (vector::length(tree) + 1) / 2;
        let floor_log_2_leaf_num = fixed_point32::floor(math64::log2(leaf_num));
        assert!(leaf_num == math64::pow(2, floor_log_2_leaf_num), E_TEST_FAILED);

        let height = floor_log_2_leaf_num + 1;

        let path_hashes = vector::empty();
        let path_tags = vector::empty();

        let level_node_index = leaf_offset;
        let level_node_num = leaf_num;
        let level_start_offset_in_tree = 0;
        for (_level in 0.. (height - 1)) {

            let is_left = level_node_index % 2 == 1;
            let sibling_node_pos_in_tree;
            if (is_left) {
                sibling_node_pos_in_tree = level_start_offset_in_tree + level_node_index - 1;
            } else {
                sibling_node_pos_in_tree = level_start_offset_in_tree + level_node_index + 1;
            };

            let sibling_hash = vector::borrow(tree, sibling_node_pos_in_tree);

            vector::push_back(&mut path_hashes, *sibling_hash);
            vector::push_back(&mut path_tags, is_left);

            level_start_offset_in_tree = level_start_offset_in_tree + level_node_num;

            // Tree level up.
            level_node_index = level_node_index / 2;
            level_node_num = level_node_num / 2;
        };
        (path_hashes, path_tags)
    }

    public fun convert_merkel_path_and_tag_to_nodes(
        path_hashes: vector<vector<u8>>,
        path_tag: vector<bool>
    ): vector<MerkelNode> {
        vector::zip_map(path_hashes, path_tag, |hash, is_left| MerkelNode {
            hash,
            is_left
        })
    }

    public fun verify_merkel_path(
        root: vector<u8>,
        leaf_data: vector<u8>,
        path_nodes: vector<vector<u8>>,
        path_tags: vector<bool>
    ) {
        let calc_root = calculate_merkel_root_by_tag_from_hash(path_nodes, path_tags, sha3_256(leaf_data));
        assert!(root == calc_root, E_MERKEL_VERIFY_FAILED);
    }

    #[test_only]
    use endless_framework::randomness;
    #[test_only]
    use endless_std::debug::print;


    #[test_only]
    public fun initialize_for_testing(framework: &signer) {
        randomness::initialize(framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");
    }

    #[test(fx = @endless_framework)]
    fun test_merkel_prove(fx: signer) {
        initialize_for_testing(&fx);

        let path = vector::empty<MerkelNode>();
        let leaf = randomness::bytes(1024);
        let leaf_index = 0u64 ;
        let root_hash = sha3_256(leaf);

        for (in in 0..10) {
            let is_left_node = randomness::u8_integer() % 2 == 0;
            let sibling_hash = sha3_256(randomness::bytes(32));
            if (is_left_node) {
                let node_hash = sibling_hash;
                vector::append(&mut node_hash, root_hash);
                root_hash = sha3_256(node_hash);
            } else {
                vector::append(&mut root_hash, sibling_hash);
                root_hash = sha3_256(root_hash);
            };

            let node = MerkelNode {
                is_left: is_left_node,
                hash: sibling_hash,
            };

            leaf_index = leaf_index * 2 + if (is_left_node) { 1 } else { 0 };
            vector::push_back(&mut path, node);
        };

        let calc_root = calculate_merkel_root_from_leaf(leaf, path);
        assert!(root_hash == calc_root, E_TEST_FAILED);
    }

    #[test(fx = @endless_framework)]
    fun test_convert_path_hashes_to_nodes(fx: signer) {
        initialize_for_testing(&fx);

        let path = vector::empty<MerkelNode>();
        let leaf = randomness::bytes(1024);
        let leaf_index = 0u64 ;
        let root_hash = sha3_256(leaf);

        let tree_no_root_height = 6;
        for (i in 0..tree_no_root_height) {
            let is_left_node = randomness::u8_integer() % 2 == 0;
            let sibling_hash = sha3_256(randomness::bytes(32));
            if (is_left_node) {
                let node_hash = sibling_hash;
                vector::append(&mut node_hash, root_hash);
                root_hash = sha3_256(node_hash);
            } else {
                vector::append(&mut root_hash, sibling_hash);
                root_hash = sha3_256(root_hash);
            };

            let node = MerkelNode {
                is_left: is_left_node,
                hash: sibling_hash,
            };

            leaf_index = leaf_index + math64::pow(2, i) * if (is_left_node) { 1 } else { 0 };
            vector::push_back(&mut path, node);
        };

        let path_hashes = vector::map_ref(&path, |node| {
            let node: &MerkelNode = node;
            node.hash
        });

        let new_path = convert_merkel_path_and_offset_to_nodes(path_hashes, leaf_index);
        print(&string::utf8(b"---------------- Merkel path ----------------"));
        print(&path_hashes);

        for (i in 0..tree_no_root_height) {
            let node = vector::borrow(&path, i);
            let new_node = vector::borrow(&new_path, i);
            assert!(node.is_left == new_node.is_left, E_TEST_FAILED);
        }
    }
}

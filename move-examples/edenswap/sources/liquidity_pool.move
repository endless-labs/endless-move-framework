/// This module provides a common type of liquidity pool that supports both volatile and stable token pairs. It uses
/// fungible assets underneath and needs a separate router + coin_wrapper to support coins (different standard from
/// fungible assets). Swap fees are kept separately from the pool's reserves and thus don't compound.
///
/// For volatile pairs, the price and reserves can be computed using the constant product formula k = x * y.
///
/// Note that all functions that return fungible assets such as swap, burn, claim_fees are friend-only since they might
/// return an internal wrapper fungible assets. The router or other modules should provide interface to call these based
/// on the underlying tokens of the pool - whether they're coins or fungible assets. See router.move for an example.
///
/// Another important thing to note is that all transfers of the LP tokens have to call via this module. This is
/// required so that fees are correctly updated for LPs. fungible_asset::transfer and primary_fungible_store::transfer
/// are not supported
///
///
//
module edenswap::liquidity_pool {
    use endless_framework::event;
    use endless_framework::fungible_asset::{
        Self, FungibleAsset, FungibleStore, Metadata,
        BurnRef, MintRef, TransferRef,
    };
    use endless_framework::object::{Self, ConstructorRef, Object, object_address};
    use endless_framework::primary_fungible_store;
    use endless_std::comparator;
    use endless_std::math128;
    use endless_std::smart_vector::{Self, SmartVector};

    use std::bcs;
    use std::option;
    use std::signer;
    use std::signer::address_of;
    use std::string::{Self, String};
    use std::vector;
    use endless_framework::account;
    use endless_framework::account::SignerCapability;
    use endless_framework::endless_coin;
    use endless_std::debug::print;
    use endless_std::math64;
    use endless_std::string_utils;

    friend edenswap::router;

    // BLACKHoLEeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
    const BLACK_HOLE: address = @0x997d4d3303b525999cb0d69913474e8f7f914adfc68d0e989691e23a62ce98b3;

    const BPS_10000: u128 = 10000;
    const NEED_DYNAMIC_FEE_RATE_BPS: u128 = 10000;
    const MINIMUM_LIQUIDITY: u128 = 1000;

    const BASE_SWAP_FEES_BPS: u128 = 10;
    const DAO_FEES_BPS: u128 = 9;

    const SEED: vector<u8> = b"EndlessSwap";

    /// Amount of tokens provided must be greater than zero.
    const EZERO_AMOUNT: u64 = 1;
    /// The amount of liquidity provided is so small that corresponding LP token amount is rounded to zero.
    const EINSUFFICIENT_LIQUIDITY_MINTED: u64 = 2;
    /// Amount of LP tokens redeemed is too small, so amounts of tokens received back are rounded to zero.
    const EINSUFFICIENT_LIQUIDITY_REDEEMED: u64 = 3;
    /// The specified amount of output tokens is incorrect and does not maintain the pool's invariant.
    const EINCORRECT_SWAP_AMOUNT: u64 = 4;
    /// The caller is not the owner of the LP token store.
    const ENOT_STORE_OWNER: u64 = 5;
    /// Claler is not authorized to perform the operation.
    const ENOT_AUTHORIZED: u64 = 6;
    /// All swaps are currently paused.
    const ESWAPS_ARE_PAUSED: u64 = 7;
    /// Swap leaves pool in a worse state than before.
    const EK_BEFORE_SWAP_GREATER_THAN_EK_AFTER_SWAP: u64 = 8;

    /// Insufficient token reserve.
    const EINSUFFICIENT_TOKEN_RESERVE: u64 = 9;

    /// Invalid value.
    const EINVALID_MULTIPLER: u64 = 10;
    /// Invalid token address.
    const EINVALID_TOKEN_ADDRESS: u64 = 11;

    // Invalid value.
    const EINVALID_VALUE: u64 = 12;

    const ENOT_CHARGED_DAO_FEE: u64 = 13;

    const EINVALIDE_MULTI_SWAP_PATH: u64 = 14;

    const EZERO_AMOUNT_TOKEN_IN: u64 = 15;
    const EZERO_AMOUNT_TOKEN_OUT: u64 = 16;


    struct LPTokenRefs has store {
        burn_ref: BurnRef,
        mint_ref: MintRef,
        transfer_ref: TransferRef,
    }

    /// Stored in the protocol's account for configuring liquidity pools.
    struct LiquidityPoolConfigs has key {
        all_pools: SmartVector<Object<LiquidityPool>>,
        fee_store: Object<FungibleStore>,

        is_paused: bool,
        manager: address,
        fee_recipient: address,
        base_swap_fee_bps: u128,
        dao_fee_bps: u128,
    }

    struct LiquidityPool has key {
        token_store_0: Object<FungibleStore>,
        token_store_1: Object<FungibleStore>,
        lp_token_refs: LPTokenRefs,
        multipler: u128,

        virtual_token_reserve_0: u128,
        virtual_token_reserve_1: u128,

        /// Virtual reserve increase when pair single side add token liquidity.
        /// Say a/b token, when add a token single liquidity, liquidity of a add to virtual_token_reserve, and add pairing
        /// liquidity of b to virtual_pairing_reserve.
        virtual_pairing_reserve_0: u128,
        virtual_pairing_reserve_1: u128,
    }

    struct PoolInfo has copy, drop {
        pool: address,
        token_0: address,
        token_1: address,

        dao_fee_bps: u128,
        base_swap_fee_bps: u128,
        multipler: u128,

        reserve_0: u128,
        reserve_1: u128,

        virtual_token_reserve_0: u128,
        virtual_token_reserve_1: u128,

        virtual_pairing_reserve_0: u128,
        virtual_pairing_reserve_1: u128,

        total_reserve_0: u128,
        total_reserve_1: u128,

        lp_token_supply: u128,
        lp_token_decimals: u8,
    }

    struct TokenInfo has drop, copy {
        address: address,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
    }

    struct TokenPair has drop, copy {
        token_0: TokenInfo,
        token_1: TokenInfo,
    }

    struct PreSwapCalcDetail has copy, drop {
        amount_in: u128,
        amount_out: u128,
        fee: u128,
        price_impact_bps: u128,
        excutable: bool,
    }

    struct SwapPahtParams has copy, drop {
        token_in: Object<Metadata>,
        token_out: Object<Metadata>,
        amount_in: u128,
        amount_out: u128,
        dao_fee: u128,
        base_fee: u128,
        dynamic_fee: u128,
    }

    #[event]
    /// Event emitted when a pool is created.
    struct CreatePool has drop, store {
        pool: address,
        token_0: address,
        token_1: address,
        multiplier: u128,
    }

    #[event]
    /// Event emitted when a add liquidity.
    struct MintLP has drop, store {
        pool: address,
        provider: address,
        token_0: address,
        token_1: address,
        amount_0: u128,
        amount_1: u128,
        lp_token_amount: u128,
    }

    #[event]
    /// Event emitted when a remove liquidity.
    struct BurnLP has drop, store {
        pool: address,
        provider: address,
        token_0: address,
        token_1: address,
        redeem_amount_0: u128,
        redeem_amount_1: u128,
        lp_token_amount: u128,
    }


    #[event]
    /// Event emitted when a swap happens.
    struct Swap has drop, store {
        pool: address,
        recipient: address,
        token_in: address,
        amount_in: u128,
        token_out: address,
        amount_out: u128,
        fee: u128,
    }

    #[event]
    struct ReservesUpdated has drop, store {
        pool: address,
        reserve_0: u128,
        reserve_1: u128,
        total_reserve_0: u128,
        total_reserve_1: u128,
    }

    #[event]
    struct MutiplerUpdated has drop, store {
        pool: address,
        multipler_old: u128,
        multipler_new: u128,

        virtual_token_reserve_0_old: u128,
        virtual_token_reserve_1_old: u128,

        virtual_pairing_reserve_0_old: u128,
        virtual_pairing_reserve_1_old: u128,

        virtual_token_reserve_0_new: u128,
        virtual_token_reserve_1_new: u128,

        virtual_pairing_reserve_0_new: u128,
        virtual_pairing_reserve_1_new: u128,

    }

    /// Stores permission config such as SignerCapability for controlling the resource account.
    struct PermissionConfig has key {
        /// Required to obtain the resource account signer.
        signer_cap: SignerCapability,
    }

    /// Initialize PermissionConfig to establish control over the resource account.
    /// This function is invoked only when this package is deployed the first time.
    fun init_module(swap: &signer) {
        let (res_signer, signer_cap) = account::create_resource_account(swap, SEED);
        move_to(&res_signer, PermissionConfig {
            signer_cap,
        });

        move_to(&res_signer, LiquidityPoolConfigs {
            all_pools: smart_vector::new(),
            fee_store: create_token_store(&res_signer, eds()),
            is_paused: false,
            manager: address_of(swap),
            fee_recipient: address_of(swap),
            base_swap_fee_bps: BASE_SWAP_FEES_BPS, // 0.1%
            dao_fee_bps: DAO_FEES_BPS, // 0.09%
        });
    }

    /// Can be called by friended modules to obtain the resource account signer.
    fun res_signer(): signer acquires PermissionConfig {
        let signer_cap = &borrow_global<PermissionConfig>(signer_addr()).signer_cap;
        account::create_signer_with_capability(signer_cap)
    }

    fun signer_addr(): address {
        account::create_resource_address(&@edenswap, SEED)
    }

    #[view]
    public fun total_number_of_pools(): u64 acquires LiquidityPoolConfigs {
        smart_vector::length(&safe_liquidity_pool_configs().all_pools)
    }

    #[view]
    public fun all_pools(): vector<address> acquires LiquidityPoolConfigs {
        let all_pools = &safe_liquidity_pool_configs().all_pools;
        let results = vector[];
        let len = smart_vector::length(all_pools);
        let i = 0;
        while (i < len) {
            let pool_obj = smart_vector::borrow(all_pools, i);
            vector::push_back(&mut results, object::object_address(pool_obj));
            i = i + 1;
        };
        results
    }

    #[view]
    public fun min_liquidity(): u128 {
        MINIMUM_LIQUIDITY
    }

    #[view]
    public fun fixed_fee_rate(): u128 acquires LiquidityPoolConfigs {
        let cfg = safe_liquidity_pool_configs();
        cfg.base_swap_fee_bps + cfg.dao_fee_bps
    }

    #[view]
    public fun liquidity_pool(
        token_0: Object<Metadata>,
        token_1: Object<Metadata>,
    ): address {
        liquidity_pool_address(token_0, token_1)
    }

    #[view]
    public fun calc_pool_addr_and_is_exist(
        token_0: Object<Metadata>,
        token_1: Object<Metadata>,
    ): (address, bool) {
        let addr = liquidity_pool_address(token_0, token_1);
        let is_exist = object::object_exists<LiquidityPool>(addr);
        (addr, is_exist)
    }

    #[view]
    public fun pool_tokens_metadata(pool_addr: address): (TokenInfo, TokenInfo) acquires LiquidityPool {
        let pool = borrow_global<LiquidityPool>(pool_addr);
        let t0 = fa_metadata(object_address(&fungible_asset::store_metadata(pool.token_store_0)));
        let t1 = fa_metadata(object_address(&fungible_asset::store_metadata(pool.token_store_1)));
        (t0, t1)
    }

    #[view]
    public fun pool_tokens_metadata_batch(pools: vector<address>): vector<TokenPair> acquires LiquidityPool {
        vector::map(pools, |pool| {
            let (token_0, token_1) = pool_tokens_metadata(pool);
            TokenPair {
                token_0,
                token_1
            }
        })
    }

    #[view]
    public fun liquidity_pool_address(
        token_0: Object<Metadata>,
        token_1: Object<Metadata>,
    ): address {
        if (!is_sorted(token_0, token_1)) {
            return liquidity_pool_address(token_1, token_0)
        };
        object::create_object_address(&signer_addr(), get_pool_seeds(token_0, token_1))
    }

    #[view]
    public fun lp_token_balance(
        pool: address,
        provider: address,
    ): u128 {
        let pool_obj = object::address_to_object<LiquidityPool>(pool);
        primary_fungible_store::balance(provider, pool_obj)
    }

    #[view]
    public fun fa_metadata(token: address): TokenInfo {
        let m = object::address_to_object<Metadata>(token);
        TokenInfo {
            address: token,
            name: fungible_asset::name(m),
            symbol: fungible_asset::symbol(m),
            decimals: fungible_asset::decimals(m),
            icon_uri: fungible_asset::icon_uri(m),
            project_uri: fungible_asset::project_uri(m),
        }
    }

    #[view]
    public fun pool_info_by_fas(
        fa_a: Object<Metadata>,
        fa_b: Object<Metadata>
    ): PoolInfo acquires LiquidityPool, LiquidityPoolConfigs {
        let pool = liquidity_pool_address(fa_a, fa_b);
        pool_info(pool)
    }

    #[view]
    public fun pools_info(pools: vector<address>): vector<PoolInfo> acquires LiquidityPool, LiquidityPoolConfigs {
        vector::map(pools, |pool| {
            pool_info(pool)
        })
    }

    #[view]
    public fun pool_info(pool: address): PoolInfo acquires LiquidityPool, LiquidityPoolConfigs {
        let (token_0, token_1, ) = pool_tokens(pool);
        let (reserve_0, reserve_1, ) = pool_reserves(pool);
        let (total_reserve_0, total_reserve_1, ) = pool_total_reserves(pool);

        let pool_obj = borrow_global<LiquidityPool>(pool);
        PoolInfo {
            pool,
            token_0: object_address(&token_0),
            token_1: object_address(&token_1),
            dao_fee_bps: dao_fee_bps(),
            base_swap_fee_bps: base_fee_bps(),
            multipler: pool_obj.multipler,
            reserve_0,
            reserve_1,
            virtual_token_reserve_0: pool_obj.virtual_token_reserve_0,
            virtual_token_reserve_1: pool_obj.virtual_token_reserve_1,
            virtual_pairing_reserve_0: pool_obj.virtual_pairing_reserve_0,
            virtual_pairing_reserve_1: pool_obj.virtual_pairing_reserve_1,
            total_reserve_0,
            total_reserve_1,
            lp_token_supply: lp_token_supply(pool),
            lp_token_decimals: fa_metadata(pool).decimals
        }
    }

    #[view]
    public fun lp_token_supply(pool: address): u128 {
        let pool = object::address_to_object<LiquidityPool>(pool);
        option::destroy_some(fungible_asset::supply(pool))
    }

    #[view]
    public fun multipler(pool: address): u128 acquires LiquidityPool {
        liquidity_pool_data(pool).multipler
    }

    #[view]
    public fun pool_virtual_token_reserves(pool: address): (u128, u128) acquires LiquidityPool {
        let pool_data = liquidity_pool_data(pool);

        (pool_data.virtual_token_reserve_0, pool_data.virtual_token_reserve_1)
    }

    #[view]
    public fun pool_virtual_pairing_reserves(pool: address): (u128, u128) acquires LiquidityPool {
        let pool_data = liquidity_pool_data(pool);
        (pool_data.virtual_pairing_reserve_0, pool_data.virtual_pairing_reserve_1)
    }

    #[view]
    public fun pool_total_virtual_reserves(pool: address): (u128, u128) acquires LiquidityPool {
        let pool_data = liquidity_pool_data(pool);

        (
            pool_data.virtual_token_reserve_0 + pool_data.virtual_pairing_reserve_0,
            pool_data.virtual_token_reserve_1 + pool_data.virtual_pairing_reserve_1,
        )
    }

    #[view]
    public fun dao_fee_recipient(): address acquires LiquidityPoolConfigs {
        let swap = borrow_global<LiquidityPoolConfigs>(signer_addr());
        swap.fee_recipient
    }


    #[view]
    public fun dao_fee_balance(): u128 acquires LiquidityPoolConfigs {
        fungible_asset::balance(dao_fees_store())
    }

    //--///////////////////////////////////////////////// USERS /////////////////////////////////////////////////////////

    inline fun dao_fees_store(): (Object<FungibleStore>) {
        borrow_global<LiquidityPoolConfigs>(signer_addr()).fee_store
    }

    public fun dao_fee_bps(): u128 acquires LiquidityPoolConfigs {
        borrow_global<LiquidityPoolConfigs>(signer_addr()).dao_fee_bps
    }

    public fun base_fee_bps(): u128 acquires LiquidityPoolConfigs {
        borrow_global<LiquidityPoolConfigs>(signer_addr()).base_swap_fee_bps
    }

    #[view]
    public fun get_amount_out_pre_swap_calc_detail(
        pool: address,
        token_in: Object<Metadata>,
        amount_in: u128,
    ): PreSwapCalcDetail acquires LiquidityPool, LiquidityPoolConfigs {
        let c_detail = PreSwapCalcDetail {
            amount_in: 0,
            amount_out: 0,
            fee: 0,
            price_impact_bps: 0,
            excutable: false,
        };

        let pool_info = pool_info(pool);
        let token_in_addr = object_address(&token_in);
        let (amount_out_reserve, tr_out, tr_in) = if (token_in_addr == pool_info.token_0) {
            (pool_info.reserve_1, pool_info.total_reserve_1, pool_info.total_reserve_0)
        } else {
            (pool_info.reserve_0, pool_info.total_reserve_0, pool_info.total_reserve_1)
        };

        if (amount_in > 0) {
            let (amount_out, fee) = get_amount_out(pool, token_in, amount_in);
            if (amount_out > 0 && amount_out <= amount_out_reserve) {
                c_detail.amount_in = amount_in;
                c_detail.amount_out = amount_out;
                c_detail.fee = fee;
                c_detail.excutable = true;

                let pi_bps = (BPS_10000 as u256) * ((tr_in as u256) + (amount_in as u256)) * (tr_out as u256) / ((((tr_out as u256) - (amount_out as u256)) * (tr_in as u256))) - (BPS_10000 as u256);
                c_detail.price_impact_bps = (pi_bps as u128);
            };
        };

        c_detail
    }

    #[view]
    public fun get_amount_out_multi_pools_pre_swap_calc_detail(
        pools: vector<address>,
        token_in: Object<Metadata>,
        amount_in: u128,
    ): PreSwapCalcDetail acquires LiquidityPool, LiquidityPoolConfigs {
        let d = PreSwapCalcDetail {
            amount_in,
            amount_out: 0,
            fee: 0,
            price_impact_bps: 0,
            excutable: true,
        };

        let token_in_tmp = token_in;
        let amount_in_tmp = amount_in;
        vector::for_each(pools, |pool| {
            let pre_calc = get_amount_out_pre_swap_calc_detail(pool, token_in_tmp, amount_in_tmp);

            d.amount_out = pre_calc.amount_out;
            d.fee = d.fee + pre_calc.fee;
            d.price_impact_bps = (BPS_10000 + d.price_impact_bps) * (BPS_10000 + pre_calc.price_impact_bps) / BPS_10000 - BPS_10000;
            d.excutable = d.excutable && pre_calc.excutable;

            token_in_tmp = co_token(pool, token_in_tmp);
            amount_in_tmp = pre_calc.amount_out;
        });

        d
    }

    #[view]
    public fun get_amount_out(
        pool: address,
        token_in: Object<Metadata>,
        amount_in: u128,
    ): (u128, u128) acquires LiquidityPool, LiquidityPoolConfigs {
        let (amount_out, dao_fee_amount, base_fee_amount, dynamic_fee_amount) = get_amount_out_and_fees(
            pool,
            token_in,
            amount_in
        );

        let fee = dao_fee_amount + base_fee_amount + dynamic_fee_amount;
        (amount_out, fee)
    }

    /*  rate_bps = [10000*(reserve_out - amount_out)*(total_reserver_in + amount_in)] / [(reserve_in + amount_in)*(total_reserver_out -amount_out)]
    //  0<=rate_bps<=10000
    //  dynamic fee rate = MAX_SWAP_FEES_BPS*(2*10000/(10000+rate_bps) -1)  [0, MAX_SWAP_FEES_BPS]
    //  Return the amount of tokens received for a swap with the given amount in and the liquidity pool.
    */
    public fun get_amount_out_and_fees(
        pool: address,
        token_in: Object<Metadata>,
        amount_in: u128,
    ): (u128, u128, u128, u128) acquires LiquidityPool, LiquidityPoolConfigs {
        let (total_reserver_0, total_reserver_1) = pool_total_reserves(pool);
        let pool_data = liquidity_pool_data(pool);
        let reserve_0 = fungible_asset::balance(pool_data.token_store_0) ;
        let reserve_1 = fungible_asset::balance(pool_data.token_store_1) ;

        let (reserve_in, reserve_out, total_reserver_in, total_reserver_out) =
            if (token_in == fungible_asset::store_metadata(pool_data.token_store_0)) {
                (reserve_0, reserve_1, total_reserver_0, total_reserver_1)
            } else {
                (reserve_1, reserve_0, total_reserver_1, total_reserver_0)
            };

        let amount_out = math128::mul_div(amount_in, total_reserver_out, amount_in + total_reserver_in) ;
        if (amount_out > reserve_out) {
            return (0, 0, 0, 0)
        };

        let dynamic_fee_bps = calc_dynamic_fee_bps(
            amount_in,
            amount_out,
            reserve_in,
            reserve_out,
            total_reserver_in,
            total_reserver_out,
            multipler(pool),
        );

        let (dao_fee, base_fee, dynamic_fee) = if (token_in == eds()) {
            (
                mul_div_cell(amount_in, dao_fee_bps(), BPS_10000),
                mul_div_cell(amount_in, base_fee_bps(), BPS_10000),
                mul_div_cell(amount_in, dynamic_fee_bps, BPS_10000)
            )
        } else {
            (
                mul_div_cell(amount_out, dao_fee_bps(), BPS_10000),
                mul_div_cell(amount_out, base_fee_bps(), BPS_10000),
                mul_div_cell(amount_out, dynamic_fee_bps, BPS_10000)
            )
        };

        // subtract fees
        amount_out = if (co_token(pool, token_in) == eds()) {
            amount_out - dao_fee - base_fee - dynamic_fee
        } else {
            math128::mul_div(amount_out, BPS_10000 - fixed_fee_rate() - dynamic_fee_bps, BPS_10000)
        };

        (amount_out, dao_fee, base_fee, dynamic_fee)
    }

    // pools: from token_in to token_out, e.g. swap from token_in to C [pool_token_in_A, pool_A_B, pool_B_C)]
    #[view]
    public fun calc_amount_out_and_fees_multi_pools(
        pools: vector<address>,
        token_in: Object<Metadata>,
        amount_in: u128,
    ): (u128, u128) acquires LiquidityPool, LiquidityPoolConfigs {
        let (
            _,
            amount_out,
            dao_fee,
            base_fee,
            dynamic_fee
        ) = calc_amount_out_and_fees_and_path_amount_multi_pools(pools, token_in, amount_in);

        (amount_out, dao_fee + base_fee + dynamic_fee)
    }

    public fun calc_amount_out_and_fees_and_path_amount_multi_pools(
        pools: vector<address>,
        token_in: Object<Metadata>,
        amount_in: u128,
    ): (vector<SwapPahtParams>, u128, u128, u128, u128) acquires LiquidityPool, LiquidityPoolConfigs {
        if (vector::length(&pools) == 0 || !validate_path_from_in(&pools, token_in)) {
            return (vector[], 0, 0, 0, 0)
        };

        let (total_dao_fee, sum_base_fee, sum_dynamic_fee) = (0, 0, 0);
        // Reserve path
        vector::reverse(&mut pools);

        let (token_in_tmp, amount_in_tmp) = (token_in, amount_in);
        let swap_path = vector[];
        loop {
            if (vector::length(&pools) == 0) {
                break
            };

            let pool_cur = vector::pop_back(&mut pools);
            let (amount_out_tmp, dao_fee, base_fee, dynamic_fee) = get_amount_out_and_fees(
                pool_cur,
                token_in_tmp,
                amount_in_tmp,
            );

            if (amount_out_tmp == 0) {
                return (vector[], 0, 0, 0, 0)
            };

            // Only charge dao fee once.
            if (total_dao_fee == 0) {
                total_dao_fee = dao_fee;
            };

            sum_base_fee = sum_base_fee + base_fee;
            sum_dynamic_fee = sum_dynamic_fee + dynamic_fee;


            {
                print(
                    &string_utils::format4(
                        &b"In {} {} => Out {} {}",
                        amount_in_tmp,
                        fungible_asset::symbol(token_in_tmp),
                        amount_out_tmp,
                        fungible_asset::symbol(co_token(pool_cur, token_in_tmp)),
                    )
                );
            };

            let path_node = SwapPahtParams {
                token_in: token_in_tmp,
                token_out: co_token(pool_cur, token_in_tmp),
                amount_in: amount_in_tmp,
                amount_out: amount_out_tmp,
                dao_fee,
                base_fee,
                dynamic_fee,
            };

            vector::push_back(&mut swap_path, path_node);

            token_in_tmp = co_token(pool_cur, token_in_tmp);
            amount_in_tmp = amount_out_tmp;
        };

        (swap_path, amount_in_tmp, total_dao_fee, sum_base_fee, sum_dynamic_fee)
    }

    /// pools: from token_in to token_out, e.g. swap from token_in to C [pool_token_in_A, pool_A_B, pool_B_C)]
    public fun swap_exact_in_multi_pools(
        sender: &signer,
        pools: vector<address>,
        token_in: Object<Metadata>,
        amount_in: u128,
    ): (u128, u128, u128, u128) acquires LiquidityPool, LiquidityPoolConfigs, PermissionConfig {
        assert!((vector::length(&pools) > 0 || validate_path_from_in(&pools, token_in)), EINVALIDE_MULTI_SWAP_PATH);

        let (
            swap_path_params,
            amount_out_final,
            total_dao_fee,
            sum_base_fee,
            sum_dynamic_fee
        ) = calc_amount_out_and_fees_and_path_amount_multi_pools(pools, token_in, amount_in);

        assert!(vector::length(&swap_path_params) > 0, EINVALIDE_MULTI_SWAP_PATH);

        // Reserve path
        vector::reverse(&mut swap_path_params);

        loop {
            if (vector::length(&swap_path_params) == 0) {
                break
            };

            let SwapPahtParams {
                token_in,
                token_out,
                amount_in,
                amount_out,
                dao_fee,
                base_fee,
                dynamic_fee
            } = vector::pop_back(&mut swap_path_params);

            swap_exact(sender, token_in, token_out, amount_in, amount_out, dao_fee, base_fee, dynamic_fee);
        };

        (amount_out_final, total_dao_fee, sum_base_fee, sum_dynamic_fee)
    }

    public fun validate_path_from_in(pools: &vector<address>, token_in: Object<Metadata>): bool acquires LiquidityPool {
        let token_next = token_in;
        let len = vector::length(pools);
        let pools_tmp = vector[];

        for (i in 0..len) {
            let pool = vector::borrow(pools, i);

            // Must no repeat pool.
            if (vector::contains(&pools_tmp, pool)) {
                return false
            };

            vector::push_back(&mut pools_tmp, *pool);

            let (t0, t1) = pool_tokens(*pool);
            if (t0 == token_next) {
                token_next = t1;
            } else if (t1 == token_next) {
                token_next = t0;
            } else {
                return false
            }
        };

        true
    }

    public fun validate_path_from_out(
        pools: &vector<address>,
        token_out: Object<Metadata>
    ): bool acquires LiquidityPool {
        let token_pre = token_out;
        let len = vector::length(pools);
        let pools_tmp = vector[];

        for (i in 0..len) {
            let pool = vector::borrow(pools, len - i - 1);

            // Must no repeat pool.
            if (vector::contains(&pools_tmp, pool)) {
                return false
            };

            vector::push_back(&mut pools_tmp, *pool);

            let (t0, t1) = pool_tokens(*pool);
            if (t0 == token_pre) {
                token_pre = t1;
            } else if (t1 == token_pre) {
                token_pre = t0;
            } else {
                return false
            }
        };

        true
    }

    #[view]
    public fun get_amount_in_pre_swap_calc_detail(
        pool: address,
        token_out: Object<Metadata>,
        amount_out: u128,
    ): PreSwapCalcDetail acquires LiquidityPool, LiquidityPoolConfigs {
        let c_detail = PreSwapCalcDetail {
            amount_in: 0,
            amount_out: 0,
            fee: 0,
            price_impact_bps: 0,
            excutable: false,
        };


        let pool_info = pool_info(pool);
        let token_out_addr = object_address(&token_out);
        let (amount_out_reserve, tr_out, tr_in) = if (token_out_addr == pool_info.token_0) {
            (pool_info.reserve_0, pool_info.total_reserve_0, pool_info.total_reserve_1)
        } else {
            (pool_info.reserve_1, pool_info.total_reserve_1, pool_info.total_reserve_0)
        };

        if (amount_out > 0 && amount_out < amount_out_reserve) {
            let (amount_in, fee) = get_amount_in(pool, token_out, amount_out);
            if (amount_in > 0) {
                c_detail.amount_in = amount_in;
                c_detail.amount_out = amount_out;
                c_detail.fee = fee;
                c_detail.excutable = true;

                // let star_price = tr_in / tr_out;
                // let end_price = (tr_in + amount_in) / (tr_out - amount_out);
                // let price_delta = end_price - star_price;
                // let pi_bps = BPS_10000 *  price_delta / star_price;
                let pi_bps = (BPS_10000 as u256) * ((tr_in as u256) + (amount_in as u256)) * (tr_out as u256) / ((((tr_out as u256) - (amount_out as u256)) * (tr_in as u256))) - (BPS_10000 as u256);
                c_detail.price_impact_bps = (pi_bps as u128);
            }
        };

        c_detail
    }

    #[view]
    public fun get_amount_in_multi_pools_pre_swap_calc_detail(
        pools: vector<address>,
        token_out: Object<Metadata>,
        amount_out: u128,
    ): PreSwapCalcDetail acquires LiquidityPool, LiquidityPoolConfigs {
        let d = PreSwapCalcDetail {
            amount_in: 0,
            amount_out,
            fee: 0,
            price_impact_bps: 0,
            excutable: true,
        };

        vector::reverse(&mut pools);

        let token_out_tmp = token_out;
        let amount_out_tmp = amount_out;
        vector::for_each(pools, |pool| {
            let pre_calc = get_amount_in_pre_swap_calc_detail(pool, token_out_tmp, amount_out_tmp);
            d.amount_in = pre_calc.amount_in;
            d.fee = d.fee + pre_calc.fee;
            d.price_impact_bps = (BPS_10000 + d.price_impact_bps) * (BPS_10000 + pre_calc.price_impact_bps) / BPS_10000 - BPS_10000;
            d.excutable = d.excutable && pre_calc.excutable;

            token_out_tmp = co_token(pool, token_out_tmp);
            amount_out_tmp = pre_calc.amount_in;
        });

        d
    }

    #[view]
    public fun get_amount_in(
        pool: address,
        token_out: Object<Metadata>,
        amount_out: u128,
    ): (u128, u128) acquires LiquidityPool, LiquidityPoolConfigs {
        let (amount_in, dao_fee, base_fee, dynamic_fee) = get_amount_in_and_fees(
            pool,
            token_out,
            amount_out
        );

        let fee = dao_fee + base_fee + dynamic_fee;
        (amount_in, fee)
    }

    public fun get_amount_in_and_fees(
        pool: address,
        token_out: Object<Metadata>,
        amount_out: u128,
    ): (u128, u128, u128, u128) acquires LiquidityPool, LiquidityPoolConfigs {
        let (total_reserver_0, total_reserver_1) = pool_total_reserves(pool);
        let pool_data = liquidity_pool_data(pool);
        let reserve_0 = fungible_asset::balance(pool_data.token_store_0) ;
        let reserve_1 = fungible_asset::balance(pool_data.token_store_1) ;

        let (reserve_out, reserve_in, total_reserver_out, total_reserver_in) =
            if (token_out == fungible_asset::store_metadata(pool_data.token_store_0)) {
                (reserve_0, reserve_1, total_reserver_0, total_reserver_1)
            } else {
                (reserve_1, reserve_0, total_reserver_1, total_reserver_0)
            };

        if (amount_out == 0 || amount_out > reserve_out) {
            print(
                &string_utils::format2(
                    &b"amount_out {} reserve_out{}",
                    amount_out,
                    reserve_out
                )
            );
            return (0, 0, 0, 0)
        };

        let (dao_fee, base_fee, dynamic_fee);

        let amount_in = if (token_out == eds()) {
            dao_fee = mul_div_cell(amount_out, dao_fee_bps(), BPS_10000);
            base_fee = mul_div_cell(amount_out, base_fee_bps(), BPS_10000);
            amount_out = amount_out + dao_fee + base_fee;

            let amount_in_no_dynamic_fee = mul_div_cell(amount_out, total_reserver_in, total_reserver_out - amount_out);
            let dynamic_fee_bps = calc_dynamic_fee_bps(
                amount_in_no_dynamic_fee,
                amount_out,
                reserve_in,
                reserve_out,
                total_reserver_in,
                total_reserver_out,
                multipler(pool),
            );

            dynamic_fee = mul_div_cell(amount_out, dynamic_fee_bps, BPS_10000);
            amount_out = amount_out + dynamic_fee;

            let amount_in = mul_div_cell(amount_out, total_reserver_in, total_reserver_out - amount_out);

            amount_in
        } else if (co_token(pool, token_out) == eds()) {
            let amount_in = mul_div_cell(amount_out, total_reserver_in, total_reserver_out - amount_out);
            let dynamic_fee_bps = calc_dynamic_fee_bps(
                amount_in,
                amount_out,
                reserve_in,
                reserve_out,
                total_reserver_in,
                total_reserver_out,
                multipler(pool),
            );

            (dao_fee, base_fee, dynamic_fee) = (
                mul_div_cell(amount_in, dao_fee_bps(), BPS_10000),
                mul_div_cell(amount_in, base_fee_bps(), BPS_10000),
                mul_div_cell(amount_in, dynamic_fee_bps, BPS_10000)
            );

            amount_in + dao_fee + base_fee + dynamic_fee
        } else {
            print(
                &string_utils::format2(
                    &b"token_out {} co_token(pool, token_out){}",
                    token_out,
                    co_token(pool, token_out)
                )
            );
            return (0, 0, 0, 0)
        };

        (amount_in, dao_fee, base_fee, dynamic_fee)
    }

    // pools: from token_in to token_out, e.g. swap from A to token_out [pool_A_B, pool_B_C, pool_C_token_out)]
    #[view]
    public fun calc_amount_in_and_fees_multi_pools(
        pools: vector<address>,
        token_out: Object<Metadata>,
        amount_out: u128,
    ): (u128, u128) acquires LiquidityPool, LiquidityPoolConfigs {
        let (
            _,
            amount_in,
            dao_fee,
            base_fee,
            dynamic_fee
        ) = calc_amount_in_and_fees_and_path_amount_multi_pools(pools, token_out, amount_out);

        (amount_in, dao_fee + base_fee + dynamic_fee)
    }

    public fun calc_amount_in_and_fees_and_path_amount_multi_pools(
        pools: vector<address>,
        token_out: Object<Metadata>,
        amount_out: u128,
    ): (vector<SwapPahtParams>, u128, u128, u128, u128) acquires LiquidityPool, LiquidityPoolConfigs {
        if (vector::length(&pools) == 0 || !validate_path_from_out(&pools, token_out)) {
            return (vector[], 0, 0, 0, 0)
        };

        let swap_path = vector[];
        let (total_dao_fee, sum_base_fee, sum_dynamic_fee) = (0, 0, 0);
        let (token_out_tmp, amount_out_tmp) = (token_out, amount_out);
        loop {
            if (vector::length(&pools) == 0) {
                break
            };

            let pool_cur = vector::pop_back(&mut pools);
            let (amount_in_tmp, dao_fee, base_fee, dynamic_fee) = get_amount_in_and_fees(
                pool_cur,
                token_out_tmp,
                amount_out_tmp,
            );

            if (amount_in_tmp == 0) {
                return (vector[], 0, 0, 0, 0)
            };

            // Only charge dao fee once.
            if (total_dao_fee == 0) {
                total_dao_fee = dao_fee;
            };

            sum_base_fee = sum_base_fee + base_fee;
            sum_dynamic_fee = sum_dynamic_fee + dynamic_fee;

            {
                print(
                    &string_utils::format4(
                        &b"Out {} {} => In {} {}",
                        amount_out_tmp,
                        fungible_asset::symbol(token_out_tmp),
                        amount_in_tmp,
                        fungible_asset::symbol(co_token(pool_cur, token_out_tmp)),
                    )
                );
            };

            let path_node = SwapPahtParams {
                token_in: co_token(pool_cur, token_out_tmp),
                token_out: token_out_tmp,
                amount_in: amount_in_tmp,
                amount_out: amount_out_tmp,
                dao_fee,
                base_fee,
                dynamic_fee,
            };
            vector::push_back(&mut swap_path, path_node);

            token_out_tmp = co_token(pool_cur, token_out_tmp);
            amount_out_tmp = amount_in_tmp;
        };

        // Reserve to from in -> out
        vector::reverse(&mut swap_path);

        (swap_path, amount_out_tmp, total_dao_fee, sum_base_fee, sum_dynamic_fee)
    }


    /// pools: from token_in to token_out, e.g. swap from A to token_out [pool_A_B, pool_B_C, pool_C_token_out)]
    public fun swap_exact_out_multi_pools(
        sender: &signer,
        pools: vector<address>,
        token_out: Object<Metadata>,
        amount_out: u128,
    ): (u128, u128, u128, u128) acquires LiquidityPool, LiquidityPoolConfigs, PermissionConfig {
        assert!((vector::length(&pools) > 0 || validate_path_from_out(&pools, token_out)), EINVALIDE_MULTI_SWAP_PATH);
        let (
            swap_path_params,
            amount_in_final,
            total_dao_fee,
            sum_base_fee,
            sum_dynamic_fee
        ) = calc_amount_in_and_fees_and_path_amount_multi_pools(pools, token_out, amount_out);

        assert!(vector::length(&swap_path_params) > 0, EINVALIDE_MULTI_SWAP_PATH);

        vector::reverse(&mut swap_path_params);
        loop {
            if (vector::length(&swap_path_params) == 0) {
                break
            };

            let SwapPahtParams {
                token_in,
                token_out,
                amount_in,
                amount_out,
                dao_fee,
                base_fee,
                dynamic_fee
            } = vector::pop_back(&mut swap_path_params);

            swap_exact(sender, token_in, token_out, amount_in, amount_out, dao_fee, base_fee, dynamic_fee);
        };

        (amount_in_final, total_dao_fee, sum_base_fee, sum_dynamic_fee)
    }

    inline fun mul_div_cell(a: u128, b: u128, c: u128): u128 {
        if (a == 0 || b == 0) {
            // Inline functions cannot take constants, as then every module using it needs the constant
            assert!(c != 0, std::error::invalid_argument(4));
            0
        }else {
            ((((a as u256) * (b as u256) - 1) / (c as u256)) as u128) + 1
        }
    }

    fun calc_dynamic_fee_bps(
        amount_in: u128,
        amount_out: u128,
        reserve_in: u128,
        reserve_out: u128,
        total_reserver_in: u128,
        total_reserver_out: u128,
        multipler: u128,
    ): u128 {
        // Propotion of  (reserve_out/reserve_in) / (total_reserver_out/total_reserver_in) indicate wether pair is on
        // balance after swap. If propotion is smaller than 1 (or 10000 bps), it need to increase fee.
        let propotion_after_swap_bps = calc_propotion_after_swap_bps(
            amount_in,
            amount_out,
            reserve_in,
            reserve_out,
            total_reserver_in,
            total_reserver_out
        );

        let dynamic_fee_bps = if (propotion_after_swap_bps < NEED_DYNAMIC_FEE_RATE_BPS) {
            BASE_SWAP_FEES_BPS * (multipler - 1) * (2 * BPS_10000 / (BPS_10000 + propotion_after_swap_bps) - 1)
        } else {
            0
        };

        dynamic_fee_bps
    }

    fun calc_propotion_after_swap_bps(
        amount_in: u128,
        amount_out: u128,
        reserve_in: u128,
        reserve_out: u128,
        total_reserver_in: u128,
        total_reserver_out: u128,
    ): u128 {
        let propotion_after_swap_bps = if (amount_out <= reserve_out) {
            ((BPS_10000 as u256) * ((reserve_out - amount_out) as u256) * ((total_reserver_in + amount_in) as u256))
                / (((reserve_in + amount_in) as u256) * ((total_reserver_out - amount_out) as u256))
        } else {
            0
        };

        (propotion_after_swap_bps as u128)
    }

    // Deposits dao fees.
    fun deposit_dao_fee(fee: FungibleAsset) acquires LiquidityPoolConfigs {
        fungible_asset::deposit(dao_fees_store(), fee);
    }

    public fun pool_tokens(pool_addr: address): (Object<Metadata>, Object<Metadata>) acquires LiquidityPool {
        let pool = borrow_global<LiquidityPool>(pool_addr);
        (fungible_asset::store_metadata(pool.token_store_0), fungible_asset::store_metadata(pool.token_store_1))
    }

    fun co_token(pool: address, token: Object<Metadata>): Object<Metadata> acquires LiquidityPool {
        let (t0, t1) = pool_tokens(pool);
        if (t0 == token) {
            t1
        } else {
            t0
        }
    }


    public fun pool_reserves(pool: address): (u128, u128) acquires LiquidityPool {
        let pool_data = liquidity_pool_data(pool);
        (
            fungible_asset::balance(pool_data.token_store_0),
            fungible_asset::balance(pool_data.token_store_1),
        )
    }


    public fun pool_total_reserves(pool: address): (u128, u128) acquires LiquidityPool {
        let (tvr0, tvr1) = pool_total_virtual_reserves(pool);
        let (r0, r1) = pool_reserves(pool);
        (tvr0 + r0, tvr1 + r1)
    }


    public fun is_sorted(token_0: Object<Metadata>, token_1: Object<Metadata>): bool {
        // EDS always token0.
        if (token_0 == eds()) {
            true
        } else if (token_1 == eds()) {
            false
        } else {
            let token_0_addr = object::object_address(&token_0);
            let token_1_addr = object::object_address(&token_1);
            comparator::is_smaller_than(&comparator::compare(&token_0_addr, &token_1_addr))
        }
    }

    public fun eds(): Object<Metadata> {
        endless_coin::get_metadata()
    }

    /// Creates a new liquidity pool.
    public(friend) fun create(
        token_0: Object<Metadata>,
        token_1: Object<Metadata>,
    ): Object<LiquidityPool> acquires LiquidityPoolConfigs, LiquidityPool, PermissionConfig {
        if (!is_sorted(token_0, token_1)) {
            return create(token_1, token_0)
        };
        let configs = unchecked_mut_liquidity_pool_configs();

        // The liquidity pool will serve 3 separate roles:
        // 1. Represent the liquidity pool that LPs and users interact with to add/remove liquidity and swap tokens.
        // 2. Represent the metadata of the LP token.
        // 3. Store the min liquidity that will be locked into the pool when initial liquidity is added.
        let pool_constructor_ref = &create_lp_token(token_0, token_1);
        let pool_signer = &object::generate_signer(pool_constructor_ref);
        let lp_token = object::object_from_constructor_ref<Metadata>(pool_constructor_ref);
        fungible_asset::create_store(pool_constructor_ref, lp_token);
        move_to(pool_signer, LiquidityPool {
            token_store_0: create_token_store(pool_signer, token_0),
            token_store_1: create_token_store(pool_signer, token_1),
            lp_token_refs: create_lp_token_refs(pool_constructor_ref),
            multipler: 1,
            virtual_token_reserve_0: 0,
            virtual_token_reserve_1: 0,
            virtual_pairing_reserve_0: 0,
            virtual_pairing_reserve_1: 0,
        });

        let pool = object::convert(lp_token);
        smart_vector::push_back(&mut configs.all_pools, pool);

        event::emit(CreatePool {
            pool: object_address(&pool),
            token_0: object_address(&token_0),
            token_1: object_address(&token_1),
            multiplier: 1,
        });

        pool
    }

    public(friend) fun swap_exact(
        user: &signer,
        token_in: Object<Metadata>,
        token_out: Object<Metadata>,
        amount_in: u128,
        amount_out: u128,
        dao_fee: u128,
        base_fee: u128,
        dynamic_fee: u128
    ) acquires LiquidityPool, LiquidityPoolConfigs, PermissionConfig {
        let pool = liquidity_pool_address(token_in, token_out);
        let fa_in = primary_fungible_store::withdraw(user, token_in, amount_in);
        let user_addr = address_of(user);

        let fa_out = swap_fas_from_pool(
            liquidity_pool_address(token_in, token_out),
            fa_in,
            amount_out,
            dao_fee,
        );

        primary_fungible_store::deposit(user_addr, fa_out);

        event::emit(
            Swap {
                recipient: user_addr,
                pool,
                token_in: object_address(&token_in),
                amount_in,
                token_out: object_address(&token_out),
                amount_out,
                fee: dao_fee + base_fee + dynamic_fee,
            },
        );

        let (reserve_0, reserve_1) = pool_reserves(pool);
        let (total_reserve_0, total_reserve_1) = pool_total_reserves(pool);
        event::emit(
            ReservesUpdated {
                pool,
                reserve_0,
                reserve_1,
                total_reserve_0,
                total_reserve_1,
            }
        );
    }

    /// Swaps `from` for the other token in the pool.
    /// This is friend-only as the returned fungible assets might be of an internal wrapper type. If this is not the
    /// case, this function can be made public.
    fun swap_fas_from_pool(
        pool: address,
        fa_in: FungibleAsset,
        amount_out: u128,
        dao_fee_amount: u128,
    ): FungibleAsset acquires LiquidityPool, LiquidityPoolConfigs, PermissionConfig {
        assert!(!safe_liquidity_pool_configs().is_paused, ESWAPS_ARE_PAUSED);
        // Only charge dao fee once when multi hops swap.
        if (fungible_asset::metadata_from_asset(&fa_in) == eds()) {
            if (dao_fee_amount > 0) {
                deposit_dao_fee(fungible_asset::extract(&mut fa_in, dao_fee_amount));
            };
            // swap token out.
            swap(pool, fa_in, amount_out)
        } else {
            // swap token out.
            let fa_out = swap(pool, fa_in, amount_out + dao_fee_amount);
            if (dao_fee_amount > 0) {
                deposit_dao_fee(fungible_asset::extract(&mut fa_out, dao_fee_amount));
            };
            fa_out
        }
    }


    /// Deposit `token_in` and swap out `amount_out` of token_out.
    public(friend) fun swap(
        pool: address,
        fa_in: FungibleAsset,
        amount_out: u128,
    ): FungibleAsset acquires LiquidityPool, PermissionConfig {
        // Calculate the amount of tokens to return to the user and the amount of fees to extract.
        let token_in = fungible_asset::metadata_from_asset(&fa_in);

        // Deposits and withdraws.
        let k_before = calculate_constant_k(pool);
        let (token_store_0, token_store_1) = pool_token_stores(pool);

        let swap_signer = &res_signer();
        let out = if (token_in == fungible_asset::store_metadata(token_store_0)) {
            // User's swapping token 1 for token 2.
            fungible_asset::deposit(token_store_0, fa_in);
            fungible_asset::withdraw(swap_signer, token_store_1, amount_out)
        } else {
            // User's swapping token 2 for token 1.
            fungible_asset::deposit(token_store_1, fa_in);
            fungible_asset::withdraw(swap_signer, token_store_0, amount_out)
        };

        let k_after = calculate_constant_k(pool);
        assert!(k_before <= k_after, EK_BEFORE_SWAP_GREATER_THAN_EK_AFTER_SWAP);
        out
    }

    //////////////////////////////////////// Liquidity Providers (LPs) ///////////////////////////////////////////////

    /// Mint LP tokens for the given liquidity. Note that the LP would receive a smaller amount of LP tokens if the
    /// amounts of liquidity provided are not optimal (do not conform with the constant formula of the pool). Users
    /// should compute the optimal amounts before calling this function.
    public(friend) fun mint_lp_token(
        provider: &signer,
        fungible_asset_0: FungibleAsset,
        fungible_asset_1: FungibleAsset,
    ) acquires LiquidityPool {
        let token_0 = fungible_asset::metadata_from_asset(&fungible_asset_0);
        let token_1 = fungible_asset::metadata_from_asset(&fungible_asset_1);
        if (!is_sorted(token_0, token_1)) {
            return mint_lp_token(provider, fungible_asset_1, fungible_asset_0)
        };

        let pool = liquidity_pool_address(token_0, token_1);
        let amount_0 = fungible_asset::amount(&fungible_asset_0);
        let amount_1 = fungible_asset::amount(&fungible_asset_1);
        assert!(amount_0 > 0 || amount_1 > 0, EZERO_AMOUNT);

        // The LP store needs to exist before we can mint LP tokens.
        let lp_token_store = ensure_lp_token_store(signer::address_of(provider), pool);

        let liquidity_token_amount = calc_lp_token(token_0, token_1, amount_0, amount_1);

        update_reserves_with_liquidity(pool, liquidity_token_amount, fungible_asset_0, fungible_asset_1);

        // Mint the corresponding amount of LP tokens to the LP.
        let mint_ref = &liquidity_pool_data(pool).lp_token_refs.mint_ref;
        let lp_tokens = fungible_asset::mint(
            mint_ref,
            liquidity_token_amount
        );
        let transfer_ref = &liquidity_pool_data(pool).lp_token_refs.transfer_ref;
        fungible_asset::deposit_with_ref(transfer_ref, lp_token_store, lp_tokens);

        event::emit(MintLP {
            pool,
            provider: address_of(provider),
            token_0: object_address(&token_0),
            token_1: object_address(&token_1),
            amount_0,
            amount_1,
            lp_token_amount: liquidity_token_amount,
        });

        let (reserve_0, reserve_1) = pool_reserves(pool);
        let (total_reserve_0, total_reserve_1) = pool_total_reserves(pool);
        event::emit(
            ReservesUpdated {
                pool,
                reserve_0,
                reserve_1,
                total_reserve_0,
                total_reserve_1,
            }
        );
    }


    #[view]
    public fun calc_lp_token(
        token_0: Object<Metadata>,
        token_1: Object<Metadata>,
        amount_0: u128,
        amount_1: u128
    ): u128 acquires LiquidityPool {
        assert!(amount_0 > 0 || amount_1 > 0, EZERO_AMOUNT);

        let (amount_0, amount_1) = if (is_sorted(token_0, token_1)) {
            (amount_0, amount_1)
        } else {
            (amount_1, amount_0)
        };

        let pool = liquidity_pool_address(token_0, token_1);
        // 0. Before create pool, only need to calculate lp amount and return.
        if (!exists<LiquidityPool>(pool)) {
            let lp_amount = math128::sqrt(amount_0 * amount_1);
            assert!(lp_amount >= MINIMUM_LIQUIDITY, EINVALID_VALUE);
            return math128::sqrt(amount_0 * amount_1) - MINIMUM_LIQUIDITY
        };

        let (reserve_0, reserve_1) = pool_reserves(pool);
        let (total_reserve_0, total_reserve_1) = pool_total_reserves(pool);

        // The LP store needs to exist before we can mint LP tokens.
        let pool_obj = object::address_to_object<LiquidityPool>(pool);

        // Before depositing the added liquidity, compute the amount of LP tokens the LP will receive.
        let lp_token_supply = option::destroy_some(fungible_asset::supply(pool_obj));
        // 1. Creator add liquidity to pool afer initialize pool.
        let liquidity_token_amount = if (lp_token_supply == 0) {
            assert!(amount_0 > 0 && amount_1 > 0, EZERO_AMOUNT);

            let total_liquidity = math128::sqrt(amount_0) * math128::sqrt(amount_1);
            assert!(total_liquidity >= MINIMUM_LIQUIDITY, EINVALID_VALUE);

            // Permanently lock the first MINIMUM_LIQUIDITY tokens.
            fungible_asset::mint_to(&liquidity_pool_data(pool).lp_token_refs.mint_ref, pool_obj, MINIMUM_LIQUIDITY);
            total_liquidity - MINIMUM_LIQUIDITY
        } else {
            let numerator = (reserve_0 as u256) * (total_reserve_1 as u256);
            let denominator = (reserve_1 as u256) * (total_reserve_0 as u256);
            let weight_real_to_total_0_1_bps = if (denominator > 0) {
                (((BPS_10000 as u256) * numerator / denominator) as u128)
            } else {
                BPS_10000 * BPS_10000
            };

            // On curve ratio: total_reserve_0 / total_reserve_1
            // reserve_0 /reserve_1  compare( >/</=)? total_reserve_0/total_reserve_1
            let liquidity = if (numerator > denominator) /*token_0 exceed*/ {
                let on_curve_reserve_0 = math128::mul_div(reserve_1, total_reserve_0, total_reserve_1);
                let exceed_reserve_0 = reserve_0 - on_curve_reserve_0;
                let paring_exceed_reserve_1 = math128::mul_div(exceed_reserve_0, total_reserve_1, total_reserve_0);

                let liquidity = if (amount_0 > 0 && amount_1 > 0) {
                    // exceed_reserve_0 only 1/2 weight when calculate liquidity.
                    // liquidity_0 = amount_0 * lp_token_supply / (on_curve_reserve_0 + exceed_reserve_0/2)
                    let liquidity_0 = math128::mul_div(
                        amount_0 * 2,
                        lp_token_supply,
                        on_curve_reserve_0 * 2 + exceed_reserve_0
                    );
                    let liquidity_1 = math128::mul_div(
                        amount_1 * 2,
                        lp_token_supply,
                        reserve_1 * 2 + paring_exceed_reserve_1
                    );
                    math128::min(liquidity_0, liquidity_1)
                }
                else if (amount_0 == 0) /* only add token_1*/ {
                    // single side add liquidity weight 1/2 liquidity.
                    // amount_1 / 2 * lp_token_supply / (reserve_1 + paring_exceed_reserve_1/2)
                    math128::mul_div(amount_1, lp_token_supply, reserve_1 * 2 + paring_exceed_reserve_1)
                } else /* only add token_0*/ {
                    let original = math128::mul_div(
                        amount_0,
                        lp_token_supply,
                        on_curve_reserve_0 * 2 + exceed_reserve_0
                    );
                    let portition_real_to_total_reserve_1_0_bps = BPS_10000 * BPS_10000 / weight_real_to_total_0_1_bps;
                    original * single_add_unbalance_discount_bps(
                        pool,
                        portition_real_to_total_reserve_1_0_bps
                    ) / BPS_10000
                };

                liquidity
            } else /*token_1 exceed*/ {
                let on_curve_reserve_1 = math128::mul_div(reserve_0, total_reserve_1, total_reserve_0);
                let exceed_reserve_1 = reserve_1 - on_curve_reserve_1;
                let paring_exceed_reserve_0 = math128::mul_div(exceed_reserve_1, total_reserve_0, total_reserve_1);

                let liquidity = if (amount_0 > 0 && amount_1 > 0) {
                    // exceed_reserve_1 only 1/2 weight when calculate liquidity.
                    // liquidity_1 = amount_1 * lp_token_supply / (on_curve_reserve_1 + exceed_reserve_1/2)
                    let liquidity_0 = math128::mul_div(
                        amount_0 * 2,
                        lp_token_supply,
                        reserve_0 * 2 + paring_exceed_reserve_0
                    );
                    let liquidity_1 = math128::mul_div(
                        amount_1 * 2,
                        lp_token_supply,
                        on_curve_reserve_1 * 2 + exceed_reserve_1
                    );
                    math128::min(liquidity_0, liquidity_1)
                }
                else if (amount_0 == 0) /* only add token_1*/ {
                    // single side add liquidity weight 1/2 liquidity.
                    // amount_0 / 2 * lp_token_supply / (reserve_0 + paring_exceed_reserve_0/2)
                    let tmp = math128::mul_div(amount_1, lp_token_supply, on_curve_reserve_1 * 2 + exceed_reserve_1);
                    tmp * single_add_unbalance_discount_bps(pool, weight_real_to_total_0_1_bps) / BPS_10000
                } else /* only add token_0*/ {
                    math128::mul_div(amount_0, lp_token_supply, reserve_0 * 2 + paring_exceed_reserve_0)
                };

                liquidity
            };

            liquidity
        };

        liquidity_token_amount
    }

    // lp token discount when add signel token to pool that reserves unbalanced.
    fun single_add_unbalance_discount_bps(
        pool: address,
        portition_bps: u128
    ): u128 acquires LiquidityPool {
        // No discount.
        if (portition_bps >= BPS_10000 * 9 / 10) {
            BPS_10000
        } else {
            let discounted_bps = BPS_10000 - BASE_SWAP_FEES_BPS
                * (multipler(pool) - 1)
                * (BPS_10000 - portition_bps) / BPS_10000;

            discounted_bps
        }
    }

    fun update_reserves_with_liquidity(
        pool: address,
        liquidity_token_amount: u128,
        fungible_asset_0: FungibleAsset,
        fungible_asset_1: FungibleAsset,
    ) acquires LiquidityPool {
        assert!(liquidity_token_amount > 0, EINSUFFICIENT_LIQUIDITY_MINTED);

        let amount_0 = fungible_asset::amount(&fungible_asset_0);
        let amount_1 = fungible_asset::amount(&fungible_asset_1);
        let (total_reserve_0, total_reserve_1) = pool_total_reserves(pool);

        // Deposit the received liquidity into the pool.
        let (store_0, store_1) = pool_token_stores(pool);
        let multipler = liquidity_pool_data(pool).multipler;
        if (amount_0 > 0 && amount_1 > 0) {
            fungible_asset::deposit(store_0, fungible_asset_0);
            fungible_asset::deposit(store_1, fungible_asset_1);
            add_pair_virtual_reserve(pool, amount_0 * (multipler - 1), amount_1 * (multipler - 1));
        } else if (amount_0 > 0 && amount_1 == 0) {
            fungible_asset::deposit(store_0, fungible_asset_0);
            fungible_asset::destroy_zero(fungible_asset_1);

            // virtual_amount_1 / amount_0 = (reserve_1 + virtual_total_1) / (reserve_0 + virtual_total_0)
            let virtual_amount_1 = math128::mul_div(amount_0, total_reserve_1, total_reserve_0);
            add_token_0_virtual_reserve_and_token_1_pairing_virtual_reserve(
                pool,
                amount_0,
                virtual_amount_1 * multipler
            );
        } else {
            fungible_asset::destroy_zero(fungible_asset_0);
            fungible_asset::deposit(store_1, fungible_asset_1);

            // virtual_amount_0 / amount_1 = (reserve_0 + virtual_total_0) / (reserve_1 + virtual_total_1)
            let virtual_amount_0 = math128::mul_div(amount_1, total_reserve_0, total_reserve_1);
            add_token_1_virtual_reserve_and_token_0_pairing_virtual_reserve(
                pool,
                amount_1,
                virtual_amount_0 * multipler
            );
        };
    }

    /// Transfer a given amount of LP tokens from the sender to the receiver. This must be called for all transfers as
    /// fungible_asset::transfer or primary_fungible_store::transfer would not work for LP tokens.
    public entry fun transfer(
        from: &signer,
        lp_token: address,
        to: address,
        amount: u128,
    ) acquires LiquidityPool {
        assert!(amount > 0, EZERO_AMOUNT);
        let from_store = ensure_lp_token_store(address_of(from), lp_token);
        let to_store = ensure_lp_token_store(to, lp_token);

        let transfer_ref = &liquidity_pool_data(lp_token).lp_token_refs.transfer_ref;
        fungible_asset::transfer_with_ref(transfer_ref, from_store, to_store, amount);
    }

    // TODO remove it!!!
    entry fun burn_lp_token(
        provider: &signer,
        pool: address,
        amount: u128,
    ) acquires LiquidityPool {
        let store = ensure_lp_token_store(address_of(provider), pool);
        fungible_asset::burn_from(&liquidity_pool_data(pool).lp_token_refs.burn_ref, store, amount);
    }

    public entry fun lock_lp_token_in_black_hole(
        from: &signer,
        lp_token: address,
        amount: u128,
    ) acquires LiquidityPool {
        transfer(from, lp_token, BLACK_HOLE, amount);
    }

    #[view]
    public fun locked_lp_token_amount(lp_token: address): u128 {
        let black_hole_store = ensure_lp_token_store(BLACK_HOLE, lp_token);
        fungible_asset::balance(black_hole_store)
    }

    /// Burn the given amount of LP tokens and receive the underlying liquidity.
    /// This is friend-only as the returned fungible assets might be of an internal wrapper type. If this is not the
    /// case, this function can be made public.
    public(friend) fun burn(
        provider: &signer,
        pool: address,
        lp_token_amount: u128,
    ): (FungibleAsset, FungibleAsset) acquires LiquidityPool, PermissionConfig {
        assert!(lp_token_amount > 0, EZERO_AMOUNT);

        let lp_token_supply = lp_token_supply(pool);
        // Calculate the amounts of tokens redeemed from the pool.
        let (store_0, store_1) = pool_token_stores(pool);
        let (reserve_0, reserve_1) = pool_reserves(pool);
        let redeem_amount_0 = math128::mul_div(lp_token_amount, reserve_0, lp_token_supply) ;
        let redeem_amount_1 = math128::mul_div(lp_token_amount, reserve_1, lp_token_supply);
        assert!(redeem_amount_0 >= 0 || redeem_amount_1 >= 0, EINSUFFICIENT_LIQUIDITY_REDEEMED);

        burn_virtual_reverses_before_withdraw_redeemed(pool, redeem_amount_0, redeem_amount_1);
        // Withdraw and return the redeemed tokens.
        let swap_signer = &res_signer();

        let (token0, token1) = pool_tokens(pool);
        let redeemed_0 = if (redeem_amount_0 > 0) {
            fungible_asset::withdraw(swap_signer, store_0, redeem_amount_0)
        }else {
            fungible_asset::zero(token0)
        };

        let redeemed_1 = if (redeem_amount_1 > 0) {
            fungible_asset::withdraw(swap_signer, store_1, redeem_amount_1)
        } else {
            fungible_asset::zero(token1)
        };

        // Burn the provided LP tokens.
        let store = ensure_lp_token_store(address_of(provider), pool);
        fungible_asset::burn_from(&liquidity_pool_data(pool).lp_token_refs.burn_ref, store, lp_token_amount);

        event::emit(BurnLP {
            pool,
            provider: address_of(provider),
            token_0: object_address(&token0),
            token_1: object_address(&token1),
            redeem_amount_0,
            redeem_amount_1,
            lp_token_amount,
        });

        let (reserve_0, reserve_1) = pool_reserves(pool);
        let (total_reserve_0, total_reserve_1) = pool_total_reserves(pool);
        event::emit(
            ReservesUpdated {
                pool,
                reserve_0,
                reserve_1,
                total_reserve_0,
                total_reserve_1,
            }
        );

        (redeemed_0, redeemed_1)
    }

    fun burn_virtual_reverses_before_withdraw_redeemed(
        pool: address,
        redeem_0: u128,
        redeem_1: u128
    ) acquires LiquidityPool {
        let (reserve_0, reserve_1) = pool_reserves(pool);

        let reserve_0_remain = reserve_0 - redeem_0;
        let reserve_1_remain = reserve_1 - redeem_1;

        let pool_data = borrow_global_mut<LiquidityPool>(pool);

        pool_data.virtual_token_reserve_0 = math128::mul_div(
            pool_data.virtual_token_reserve_0,
            reserve_0_remain,
            reserve_0
        );
        pool_data.virtual_pairing_reserve_0 = math128::mul_div(
            pool_data.virtual_pairing_reserve_0,
            reserve_0_remain,
            reserve_0
        );
        pool_data.virtual_token_reserve_1 = math128::mul_div(
            pool_data.virtual_token_reserve_1,
            reserve_1_remain,
            reserve_1
        );
        pool_data.virtual_pairing_reserve_1 = math128::mul_div(
            pool_data.virtual_pairing_reserve_1,
            reserve_1_remain,
            reserve_1
        );
    }

    /////////////////////////////////////////////////// OPERATIONS /////////////////////////////////////////////////////
    #[view]
    public fun min_pool_multipler(pool_addr: address): u128 acquires LiquidityPool {
        let (reserve0, reserve1) = pool_reserves(pool_addr);
        let (total_reserve0, total_reserve1) = pool_total_reserves(pool_addr);

        // (reserve0/reserve1) / (total_reserve0/total_reserve1) = (reserve0*total_reserve1) / (reserve1*total_reserve0)
        let (a, b) = ((reserve0 as u256) * (total_reserve1 as u256), (reserve1 as u256) * (total_reserve0 as u256));
        let min_multipler = if (a > b) { (a - 1) / b + 1 } else { (b - 1) / a + 1 };
        (min_multipler as u128)
    }

    public entry fun claim_fees() acquires LiquidityPoolConfigs, PermissionConfig {
        assert!(dao_fee_balance() > 0, EZERO_AMOUNT);
        let dao_fee = fungible_asset::withdraw(&res_signer(), dao_fees_store(), dao_fee_balance());
        primary_fungible_store::deposit(dao_fee_recipient(), dao_fee);
    }

    public entry fun update_pool_multipler(
        sender: &signer,
        pool_addr: address,
        multipler: u128
    ) acquires LiquidityPoolConfigs, LiquidityPool {
        let configs = borrow_global<LiquidityPoolConfigs>(signer_addr());
        assert!(address_of(sender) == configs.manager, ENOT_AUTHORIZED);
        assert!(multipler >= min_pool_multipler(pool_addr) && multipler <= 100, EINVALID_MULTIPLER);

        let (total_reserve0, total_reserve1) = pool_total_reserves(pool_addr);
        let (total_virtual0, total_virtual1) = pool_total_virtual_reserves(pool_addr);
        let pool = borrow_global_mut<LiquidityPool>(pool_addr);
        let mpx_current = pool.multipler;
        assert!(multipler != mpx_current, EINVALID_MULTIPLER);
        let mpx_change = if (multipler > mpx_current) { multipler - mpx_current } else { mpx_current - multipler };
        let (total0_change, total1_change) = (total_reserve0 * mpx_change / mpx_current, total_reserve1 * mpx_change / mpx_current);

        let (vt0_change, vp0_change) = if (total_virtual0 > 0) {
            let vt0_change = math128::mul_div(pool.virtual_token_reserve_0, total0_change, total_virtual0);
            let vp0_change = math128::mul_div(pool.virtual_pairing_reserve_0, total0_change, total_virtual0);
            (vt0_change, vp0_change)
        } else {
            (total0_change, 0)
        };

        let (vt1_change, vp1_change) = if (total_virtual1 > 0) {
            let vt1_change = math128::mul_div(pool.virtual_token_reserve_1, total1_change, total_virtual1);
            let vp1_change = math128::mul_div(pool.virtual_pairing_reserve_1, total1_change, total_virtual1);
            (vt1_change, vp1_change)
        } else {
            (total1_change, 0)
        };

        let (mpx_old, vt0_old, vp0_old, vt1_old, vp1_old) = (
            pool.multipler,
            pool.virtual_token_reserve_0,
            pool.virtual_pairing_reserve_0,
            pool.virtual_token_reserve_1,
            pool.virtual_pairing_reserve_1,
        );

        pool.multipler = multipler;
        if (multipler > mpx_current) {
            pool.virtual_token_reserve_0 = pool.virtual_token_reserve_0 + vt0_change;
            pool.virtual_pairing_reserve_0 = pool.virtual_pairing_reserve_0 + vp0_change;
            pool.virtual_token_reserve_1 = pool.virtual_token_reserve_1 + vt1_change;
            pool.virtual_pairing_reserve_1 = pool.virtual_pairing_reserve_1 + vp1_change;
        } else {
            pool.virtual_token_reserve_0 = pool.virtual_token_reserve_0 - vt0_change;
            pool.virtual_pairing_reserve_0 = pool.virtual_pairing_reserve_0 - vp0_change;
            pool.virtual_token_reserve_1 = pool.virtual_token_reserve_1 - vt1_change;
            pool.virtual_pairing_reserve_1 = pool.virtual_pairing_reserve_1 - vp1_change;
        };

        event::emit(MutiplerUpdated {
            pool: pool_addr,
            multipler_old: mpx_old,
            multipler_new: multipler,
            virtual_token_reserve_0_old: vt0_old,
            virtual_token_reserve_1_old: vt1_old,
            virtual_pairing_reserve_0_old: vp0_old,
            virtual_pairing_reserve_1_old: vp1_old,
            virtual_token_reserve_0_new: pool.virtual_token_reserve_0,
            virtual_token_reserve_1_new: pool.virtual_token_reserve_1,
            virtual_pairing_reserve_0_new: pool.virtual_pairing_reserve_0,
            virtual_pairing_reserve_1_new: pool.virtual_pairing_reserve_1,
        })
    }


    public entry fun set_pause(pauser: &signer, is_paused: bool) acquires LiquidityPoolConfigs {
        let pool_configs = pauser_only_mut_liquidity_pool_configs(pauser);
        pool_configs.is_paused = is_paused;
    }


    public entry fun set_fee(manager: &signer, new_dao_fee_bps: u128) acquires LiquidityPoolConfigs {
        let pool_configs = fee_manager_only_mut_liquidity_pool_configs(manager);
        pool_configs.dao_fee_bps = new_dao_fee_bps;
    }

    fun create_lp_token(
        token_0: Object<Metadata>,
        token_1: Object<Metadata>,
    ): ConstructorRef acquires PermissionConfig {
        let token_name = lp_token_name(token_0, token_1);
        let seeds = get_pool_seeds(token_0, token_1);
        let lp_token_constructor_ref = object::create_named_object(&res_signer(), seeds);
        let decimals = math64::sqrt(
            ((fungible_asset::decimals(token_0) as u64) * (fungible_asset::decimals(token_1) as u64))
        ) ;
        // We don't enable automatic primary store creation because we need LPs to call into this module for transfers
        // so the fees accounting can be updated correctly.
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &lp_token_constructor_ref,
            option::none(),
            token_name,
            string::utf8(b""),
            (decimals as u8),
            string::utf8(b""),
            string::utf8(b"")
        );
        lp_token_constructor_ref
    }

    fun create_lp_token_refs(constructor_ref: &ConstructorRef): LPTokenRefs {
        LPTokenRefs {
            burn_ref: fungible_asset::generate_burn_ref(constructor_ref),
            mint_ref: fungible_asset::generate_mint_ref(constructor_ref),
            transfer_ref: fungible_asset::generate_transfer_ref(constructor_ref),
        }
    }

    fun ensure_lp_token_store(
        user: address,
        lp_token: address
    ): Object<FungibleStore> {
        let lp_token_obj = object::address_to_object<LiquidityPool>(lp_token);
        primary_fungible_store::ensure_primary_store_exists(user, lp_token_obj);
        primary_fungible_store::primary_store(user, lp_token_obj)
    }

    inline fun get_pool_seeds(token_0: Object<Metadata>, token_1: Object<Metadata>): vector<u8> {
        let seeds = vector[];
        vector::append(&mut seeds, bcs::to_bytes(&object::object_address(&token_0)));
        vector::append(&mut seeds, bcs::to_bytes(&object::object_address(&token_1)));
        seeds
    }

    fun create_token_store(res_signer: &signer, token: Object<Metadata>): Object<FungibleStore> {
        let constructor_ref = &object::create_object(address_of(res_signer));
        fungible_asset::create_store(constructor_ref, token)
    }

    inline fun lp_token_name(token_0: Object<Metadata>, token_1: Object<Metadata>): String {
        let token_symbol = string::utf8(b"LP-");
        string::append(&mut token_symbol, fungible_asset::symbol(token_0));
        string::append_utf8(&mut token_symbol, b"-");
        string::append(&mut token_symbol, fungible_asset::symbol(token_1));
        token_symbol
    }

    inline fun calculate_constant_k(pool: address): u256 {
        let (tr0, tr1) = pool_total_reserves(pool);

        // k = x * y. This is standard constant product for volatile asset pairs.
        (tr0 as u256) * (tr1 as u256)
    }

    inline fun liquidity_pool_data(pool: address): &LiquidityPool acquires LiquidityPool {
        borrow_global<LiquidityPool>(pool)
    }

    inline fun pool_token_stores(
        pool: address
    ): (Object<FungibleStore>, Object<FungibleStore>, ) acquires LiquidityPool {
        let pool_data = borrow_global<LiquidityPool>(pool);
        (pool_data.token_store_0, pool_data.token_store_1)
    }

    inline fun pool_token_store(
        pool: address,
        token: Object<Metadata>
    ): Object<FungibleStore> acquires LiquidityPool {
        let pool_data = borrow_global<LiquidityPool>(pool);
        let (t0, t1) = (pool_data.token_store_0, pool_data.token_store_1);
        if (fungible_asset::store_metadata(t0) == token) {
            t0
        } else if (fungible_asset::store_metadata(t1) == token) {
            t1
        } else {
            abort EINVALID_TOKEN_ADDRESS
        }
    }


    inline fun add_pair_virtual_reserve(pool: address, inc_virtual_0: u128, inc_virtual_1: u128) {
        let pool_data = borrow_global_mut<LiquidityPool>(pool);
        pool_data.virtual_token_reserve_0 = pool_data.virtual_token_reserve_0 + inc_virtual_0;
        pool_data.virtual_token_reserve_1 = pool_data.virtual_token_reserve_1 + inc_virtual_1;
    }

    fun add_token_0_virtual_reserve_and_token_1_pairing_virtual_reserve(
        pool: address,
        token_0_amount: u128,
        pairing_virtual: u128
    ) acquires LiquidityPool {
        let pd = borrow_global_mut<LiquidityPool>(pool);
        let total_reserve_0_inc = token_0_amount * pd.multipler;

        pd.virtual_token_reserve_0 = pd.virtual_token_reserve_0 + token_0_amount * (pd.multipler - 1);
        if (pd.virtual_pairing_reserve_0 < total_reserve_0_inc) {
            let delta = math128::mul_div(
                pairing_virtual,
                (total_reserve_0_inc - pd.virtual_pairing_reserve_0),
                total_reserve_0_inc
            );
            pd.virtual_pairing_reserve_0 = 0;
            pd.virtual_pairing_reserve_1 = pd.virtual_pairing_reserve_1 + delta;
        } else {
            pd.virtual_pairing_reserve_0 = pd.virtual_pairing_reserve_0 - total_reserve_0_inc;
        };
    }

    fun add_token_1_virtual_reserve_and_token_0_pairing_virtual_reserve(
        pool: address,
        token_1_amount: u128,
        pairing_virtual: u128
    ) acquires LiquidityPool {
        let pd = borrow_global_mut<LiquidityPool>(pool);
        let total_reserve_1_inc = token_1_amount * pd.multipler;

        pd.virtual_token_reserve_1 = pd.virtual_token_reserve_1 + token_1_amount * (pd.multipler - 1);
        if (pd.virtual_pairing_reserve_1 < total_reserve_1_inc) {
            let delta = math128::mul_div(
                pairing_virtual,
                (total_reserve_1_inc - pd.virtual_pairing_reserve_1),
                total_reserve_1_inc
            );
            pd.virtual_pairing_reserve_1 = 0;
            pd.virtual_pairing_reserve_0 = pd.virtual_pairing_reserve_0 + delta;
        } else {
            pd.virtual_pairing_reserve_1 = pd.virtual_pairing_reserve_1 - total_reserve_1_inc;
        };
    }

    inline fun safe_liquidity_pool_configs(): &LiquidityPoolConfigs acquires LiquidityPoolConfigs {
        borrow_global<LiquidityPoolConfigs>(signer_addr())
    }

    inline fun pauser_only_mut_liquidity_pool_configs(
        pauser: &signer,
    ): &mut LiquidityPoolConfigs acquires LiquidityPoolConfigs {
        let pool_configs = unchecked_mut_liquidity_pool_configs();
        assert!(signer::address_of(pauser) == pool_configs.manager, ENOT_AUTHORIZED);
        pool_configs
    }

    inline fun fee_manager_only_mut_liquidity_pool_configs(
        manager: &signer,
    ): &mut LiquidityPoolConfigs acquires LiquidityPoolConfigs {
        let pool_configs = unchecked_mut_liquidity_pool_configs();
        assert!(signer::address_of(manager) == pool_configs.manager, ENOT_AUTHORIZED);
        pool_configs
    }

    inline fun unchecked_mut_liquidity_pool_data<T: key>(pool: &Object<T>): &mut LiquidityPool acquires LiquidityPool {
        borrow_global_mut<LiquidityPool>(object::object_address(pool))
    }

    inline fun unchecked_mut_liquidity_pool_configs(): &mut LiquidityPoolConfigs acquires LiquidityPoolConfigs {
        borrow_global_mut<LiquidityPoolConfigs>(signer_addr())
    }

    /////// TODO: REMOVE IT!!! DEV FUNCIONGS !!!!!!!!!!!!
    public entry fun reset_pool_virtual_reserves(
        developer: &signer,
        pool: address,
    ) acquires LiquidityPool, PermissionConfig {
        assert!(address_of(developer) == @edenswap, ENOT_AUTHORIZED);

        let (reserv0, reserv1) = pool_reserves(pool);

        let lp_address = signer::address_of(developer);
        let store = ensure_lp_token_store(lp_address, pool);


        // Burn the provided LP tokens.
        let lp_token_balance = lp_token_balance(pool, @edenswap);

        if (lp_token_balance > 0) {
            fungible_asset::burn_from(&liquidity_pool_data(pool).lp_token_refs.burn_ref, store, lp_token_balance);
        };

        let pool_obj = object::address_to_object<LiquidityPool>(pool);
        let pool_lp_balance = fungible_asset::balance(pool_obj);
        if (pool_lp_balance > 0) {
            fungible_asset::burn_from(&liquidity_pool_data(pool).lp_token_refs.burn_ref, pool_obj, pool_lp_balance);
        };

        let p = borrow_global_mut<LiquidityPool>(pool);
        p.virtual_token_reserve_0 = 0;
        p.virtual_token_reserve_1 = 0;
        p.virtual_pairing_reserve_0 = 0;
        p.virtual_pairing_reserve_1 = 0;

        if (reserv0 > 0) {
            let fa0 = fungible_asset::withdraw(&res_signer(), p.token_store_0, reserv0);
            primary_fungible_store::deposit(address_of(developer), fa0);
        };

        if (reserv1 > 0) {
            let fa1 = fungible_asset::withdraw(&res_signer(), p.token_store_1, reserv1);
            primary_fungible_store::deposit(address_of(developer), fa1);
        };
    }

    /////// TODO: REMOVE IT!!! DEV FUNCIONGS !!!!!!!!!!!!
    public entry fun reset_pool_virtual_reserves_v2(
        developer: &signer,
        pool: address,
        token_reserve_0: u128,
        token_reserve_1: u128,
    ) acquires LiquidityPool, PermissionConfig {
        reset_pool_virtual_reserves(developer, pool);

        let (t0, t1) = pool_tokens(pool);
        let fa0 = primary_fungible_store::withdraw(developer, t0, token_reserve_0);
        let fa1 = primary_fungible_store::withdraw(developer, t1, token_reserve_1);
        let p = borrow_global_mut<LiquidityPool>(pool);
        fungible_asset::deposit(p.token_store_0, fa0);
        fungible_asset::deposit(p.token_store_1, fa1);
    }

    #[test_only]
    use endless_framework::account::create_signer_for_test;

    #[test_only]
    public fun init_swap_for_test() {
        let signer = create_signer_for_test(@edenswap);
        init_module(&signer);
    }

    #[test_only]
    public fun set_pool(
        pool: address,
        mpx: u128,
        virtual_pairing_reserve_0: u128,
        virtual_pairing_reserve_1: u128,
        virtual_token_reserve_0: u128,
        virtual_token_reserve_1: u128,
    ) acquires LiquidityPool {
        let p = borrow_global_mut<LiquidityPool>(pool);

        p.multipler = mpx;
        p.virtual_pairing_reserve_0 = virtual_pairing_reserve_0;
        p.virtual_pairing_reserve_1 = virtual_pairing_reserve_1;
        p.virtual_token_reserve_0 = virtual_token_reserve_0;
        p.virtual_token_reserve_1 = virtual_token_reserve_1;
    }
}

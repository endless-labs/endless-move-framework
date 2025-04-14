script {
    use endless_framework::endless_coin;
    use endless_framework::primary_fungible_store;
    use endless_framework::fungible_asset;

            //     let eds_metadata = endless_coin::get_metadata();
        // // Withdraw box amount from packer
        // let amount_fa = primary_fungible_store::withdraw(caller, eds_metadata, amount);
        // // Precharge gas fee, which will be paid by the contract when unpacking
        // // This is just an estimate, assume all unpacker is not on chain
        // let gas_fee = NEW_ACCOUNT_UNIT_GAS_FEE * count;
        // let gas_fa = primary_fungible_store::withdraw(caller, eds_metadata, gas_fee);
        // // Deposit (box amount) + (precharge gas fee) to resource account
        // fungible_asset::merge(&mut amount_fa, gas_fa);

    fun main(
        first: &signer,
        second: &signer,
        amount_first: u128,
        amount_second: u128,
        dst_first: address,
        dst_second: address,
        deposit_first: u128,
    ) {
        let metadata = endless_coin::get_metadata();
        let coin_first = primary_fungible_store::withdraw(first, metadata, amount_first);
        let coin_second = primary_fungible_store::withdraw(second, metadata, amount_second);

        fungible_asset::merge(&mut coin_first, coin_second);

        let coin_second = fungible_asset::extract(&mut coin_first, amount_first + amount_second - deposit_first);

        primary_fungible_store::deposit(dst_first, coin_first);
        primary_fungible_store::deposit(dst_second, coin_second);
    }
}

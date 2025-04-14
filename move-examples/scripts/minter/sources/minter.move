script {
    use std::signer;
    use endless_framework::endless_account;
    use endless_framework::endless_coin;

    // Tune this parameter based upon the actual gas costs
    const GAS_BUFFER: u128 = 100000;
    const U64_MAX: u128 = 18446744073709551615;

    fun main(minter: &signer, dst_addr: address, amount: u128) {
        let minter_addr = signer::address_of(minter);

        // Do not mint if it would exceed U64_MAX
        let balance = endless_coin::balance(minter_addr);
        if (balance < U64_MAX - amount - GAS_BUFFER) {
            endless_coin::mint(minter, minter_addr, amount + GAS_BUFFER);
        };

        endless_account::transfer(minter, dst_addr, amount);
    }
}

//:!:>moon
script {
    fun register(account: &signer) {
        endless_framework::managed_coin::register<MoonCoin::moon_coin::MoonCoin>(account)
    }
}
//<:!:moon

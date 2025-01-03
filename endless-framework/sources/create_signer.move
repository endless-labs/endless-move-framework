/// Provides a common place for exporting `create_signer` across the Endless Framework.
///
/// To use create_signer, add the module below, such that:
/// `friend endless_framework::friend_wants_create_signer`
/// where `friend_wants_create_signer` is the module that needs `create_signer`.
///
/// Note, that this is only available within the Endless Framework.
///
/// This exists to make auditing straight forward and to limit the need to depend
/// on account to have access to this.
module endless_framework::create_signer {
    friend endless_framework::account;
    friend endless_framework::endless_account;
    friend endless_framework::genesis;
    friend endless_framework::multisig_account;
    friend endless_framework::object;
    friend endless_framework::endless_coin;
    friend endless_framework::faucet;
    friend endless_framework::locking_coin_ex;

    public(friend) native fun create_signer(addr: address): signer;
}

module tapp::hook_factory {
    use tapp::amm;

    public fun create_pool(pool_signer: &signer) {
        let hook_type = 2;
        if (hook_type == 2) {
            amm::create_pool(pool_signer);
            return;
        };

        // so on for v3, stable, etc.
        abort 0
    }

    public fun update_pool(pool_signer: &signer, value: u64) {
        let hook_type = 2;
        if (hook_type == 2) {
            amm::update_pool(pool_signer, value);
            return;
        };

        abort 0;
    }
}

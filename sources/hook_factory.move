module tapp::hook_factory {
    use std::signer::address_of;
    use aptos_std::copyable_any::{Any, pack};

    use tapp::amm;

    struct PoolMeta has key {
        hook_type: u8,
    }

    struct LPoolMeta has copy, drop, store {
        hook_type: u8,
        pool: Any
    }

    public fun create_pool(pool_signer: &signer, id: address) {
        let hook_type = 2;
        if (hook_type == 2) {
            amm::create_pool(pool_signer, id);
            move_to(pool_signer, PoolMeta { hook_type: 2 });
            return;
        };

        // so on for v3, stable, etc.
        abort 0
    }

    public fun create_position(pool_signer: &signer, shares: u64) acquires PoolMeta {
        let pool_meta = borrow_global<PoolMeta>(address_of(pool_signer));
        if (pool_meta.hook_type == 2) {
            amm::create_position(pool_signer, shares);
            return;
        };

        abort 0;
    }

    public fun lcreate_pool(id: address): LPoolMeta {
        let hook_type = 2;
        if (hook_type == 2) {
            let pool = amm::lcreate_pool(id);
            return LPoolMeta { hook_type: 2, pool: pack(pool) }
        };

        // so on for v3, stable, etc.
        abort 0
    }

    public fun lcreate_position(pool_meta: &mut LPoolMeta, shares: u64) {
        if (pool_meta.hook_type == 2) {
            let pool = &mut pool_meta.pool.unpack::<amm::LPool>();
            pool.lcreate_position(shares);
            pool_meta.pool = pack(*pool);
            return;
        };

        abort 0;
    }
}

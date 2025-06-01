module tapp::amm {
    use std::signer::address_of;

    struct Pool has key {
        id: address,
        value: u64,
    }

    public fun create_pool(pool_signer: &signer) {
        move_to(pool_signer, Pool { id: @0x123456, value: 0 });
    }

    public fun update_pool(pool_signer: &signer, value: u64) acquires Pool {
        let pool = borrow_global_mut<Pool>(address_of(pool_signer));
        pool.value = value;
    }

    public fun value(pool_addr: address): u64 acquires Pool {
        let pool = borrow_global<Pool>(pool_addr);
        pool.value
    }
}

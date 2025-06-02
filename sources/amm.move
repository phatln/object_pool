module tapp::amm {
    use std::signer::address_of;
    use aptos_std::big_ordered_map;
    use aptos_std::big_ordered_map::BigOrderedMap;
    use aptos_std::simple_map;
    use aptos_std::simple_map::SimpleMap;

    struct Pool has key, store {
        id: address,
        position_count: u64,
        positions: BigOrderedMap<u64, Position>
    }

    struct Position has store {
        shares: u64,
    }

    struct LPool has copy, drop, store {
        id: address,
        position_count: u64,
        positions: SimpleMap<u64, LPosition>
    }

    struct LPosition has copy, drop, store {
        shares: u64,
    }

    public fun create_pool(pool_signer: &signer, id: address) {
        move_to(pool_signer, Pool {
            id,
            position_count: 0,
            positions: big_ordered_map::new()
        });
    }

    public fun create_position(pool_signer: &signer, shares: u64) acquires Pool {
        let pool = &mut Pool[address_of(pool_signer)];
        pool.position_count += 1;
        pool.positions.add(pool.position_count, Position { shares });
    }

    public fun lcreate_pool(id: address): LPool {
        LPool { id, position_count: 0, positions: simple_map::new() }
    }

    public fun lcreate_position(self: &mut LPool, shares: u64) {
        self.position_count += 1;
        self.positions.add(self.position_count, LPosition { shares });
    }
}

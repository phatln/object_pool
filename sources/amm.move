module tapp::amm {
    use aptos_std::big_ordered_map;
    use aptos_std::big_ordered_map::BigOrderedMap;

    struct Pool has key, store {
        id: address,
        position_count: u64,
        positions: BigOrderedMap<u64, Position>
    }

    struct LPool has store {
        id: address,
        position_count: u64,
        positions: BigOrderedMap<u64, Position>
    }

    struct Position has store {
        shares: u64,
    }

    public fun create_pool(id: address): Pool {
        Pool { id, position_count: 0, positions: big_ordered_map::new() }
    }

    public fun create_position(self: &mut Pool, shares: u64) {
        self.position_count += 1;
        self.positions.add(self.position_count, Position { shares });
    }

    public fun lcreate_pool(id: address): Pool {
        Pool { id, position_count: 0, positions: big_ordered_map::new() }
    }

    public fun lcreate_position(self: &mut Pool, shares: u64) {
        self.position_count += 1;
        self.positions.add(self.position_count, Position { shares });
    }
}

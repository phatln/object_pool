module tapp::router {
    use std::bcs::to_bytes;
    use std::signer::address_of;
    use std::vector::range;
    use aptos_std::table;
    use aptos_std::table::Table;
    use aptos_framework::account::{create_resource_account, create_signer_with_capability, SignerCapability};
    use aptos_framework::object::{create_named_object, ExtendRef,
        generate_extend_ref, generate_signer, generate_signer_for_extending};

    use tapp::hook_factory;
    use tapp::hook_factory::LPoolMeta;

    #[test_only]
    use aptos_framework::account::create_signer_for_test;

    struct Vault has key {
        vault: SignerCapability,
        pools: Table<address, address>
    }

    struct LegacyVault has key {
        vault: SignerCapability,
        pools: Table<address, LPoolMeta>
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct PoolCap has key {
        // cref: ConstructorRef,
        extend_ref: ExtendRef,
    }

    fun init_module(signer: &signer) {
        let (_, vault_cap) = create_resource_account(signer, b"VAULT");
        let (_, lvault_cap) = create_resource_account(signer, b"LVAULT");
        let vault = Vault { vault: vault_cap, pools: table::new() };
        let lvault = LegacyVault { vault: lvault_cap, pools: table::new() };
        move_to(signer, vault);
        move_to(signer, lvault);
    }

    public entry fun create_pool(id: address) acquires Vault {
        let vault = borrow_global_mut<Vault>(@tapp);
        let vault_signer = &create_signer_with_capability(&vault.vault);

        // create object
        let cref = create_named_object(vault_signer, to_bytes(&id));
        let object_signer = &generate_signer(&cref);

        // create concrete pool under object
        hook_factory::create_pool(object_signer, id);

        let extend_ref = generate_extend_ref(&cref);
        // PoolCap is defined in router, and it contains extend ref
        // extend ref is the only way to create object signer
        // which is required in hook concrete implementations to modify pool concrete data
        move_to(object_signer, PoolCap { extend_ref });

        // tracking pool id -> pool addr
        vault.pools.add(id, address_of(object_signer))
    }

    public entry fun create_position(id: address, shares: u64) acquires Vault, PoolCap {
        let vault = &mut Vault[@tapp];
        let pool_addr = vault.pools.borrow(id);

        // Router grants PoolCap
        let pool_cap = &PoolCap[*pool_addr];
        let pool_signer = generate_signer_for_extending(&pool_cap.extend_ref);

        hook_factory::create_position(&pool_signer, shares);
    }

    public entry fun create_many_positions(id: address, count: u64, shares: u64) acquires PoolCap, Vault {
        let vault = &mut Vault[@tapp];
        let pool_addr = vault.pools.borrow(id);

        // Router grants PoolCap
        let pool_cap = &PoolCap[*pool_addr];
        let pool_signer = generate_signer_for_extending(&pool_cap.extend_ref);

        range(0, count).for_each(|_| {
            hook_factory::create_position(&pool_signer, shares);
        });
    }

    public entry fun lcreate_pool(id: address) acquires LegacyVault {
        let vault = borrow_global_mut<LegacyVault>(@tapp);
        let pool_meta = hook_factory::lcreate_pool(id);
        vault.pools.add(id, pool_meta);
    }

    public entry fun lcreate_position(id: address, shares: u64) acquires LegacyVault {
        let vault = &mut LegacyVault[@tapp];
        let pool_meta = vault.pools.borrow_mut(id);
        hook_factory::lcreate_position(pool_meta, shares);
    }

    public entry fun lcreate_many_position(id: address, count: u64, shares: u64) acquires LegacyVault {
        let vault = &mut LegacyVault[@tapp];
        let pool_meta = vault.pools.borrow_mut(id);

        range(0, count).for_each(|_| {
            hook_factory::lcreate_position(pool_meta, shares);
        });
    }

    #[view]
    public fun pool_addr(pool_id: address): address acquires Vault {
        let vault = borrow_global<Vault>(@tapp);
        *vault.pools.borrow(pool_id)
    }

    #[test]
    fun test_create_and_update() acquires Vault, PoolCap, LegacyVault {
        init_module(&create_signer_for_test(@tapp));

        let pool_id = @012345;
        create_pool(pool_id);
        create_position(pool_id, 6969);

        lcreate_pool(pool_id);
        lcreate_position(pool_id, 6969);
    }
}

module tapp::router {
    use std::bcs::to_bytes;
    use std::signer::address_of;
    use aptos_std::big_ordered_map;
    use aptos_std::big_ordered_map::BigOrderedMap;
    use aptos_std::debug::print;
    use aptos_framework::account::{create_resource_account, create_signer_with_capability, SignerCapability};
    use aptos_framework::object::{create_named_object, ExtendRef, generate_extend_ref,
        generate_signer_for_extending
    };

    use tapp::hook_factory;

    #[test_only]
    use aptos_framework::account::create_signer_for_test;

    struct Vault has key {
        vault: SignerCapability,
        pools: BigOrderedMap<address, address>
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct PoolCap has key {
        // cref: ConstructorRef,
        extend_ref: ExtendRef,
    }

    fun init_module(signer: &signer) {
        let (_, vault_cap) = create_resource_account(signer, b"VAULT");
        let vault = Vault { vault: vault_cap, pools: big_ordered_map::new() };
        move_to(signer, vault);
    }

    public entry fun create_pool(id: address) acquires Vault {
        let vault = borrow_global_mut<Vault>(@tapp);
        let vault_signer = &create_signer_with_capability(&vault.vault);

        // create object
        let cref = &create_named_object(vault_signer, to_bytes(&id));
        let extend_ref = &generate_extend_ref(cref);
        let object_signer = &generate_signer_for_extending(extend_ref);
        print(&address_of(object_signer));

        // create concrete pool under object
        hook_factory::create_pool(object_signer);

        move_to(object_signer, PoolCap { extend_ref: *extend_ref });
        vault.pools.add(id, address_of(object_signer))
    }

    public entry fun update_pool(id: address, value: u64) acquires Vault, PoolCap {
        let vault = borrow_global_mut<Vault>(@tapp);
        let pool_addr = vault.pools.borrow(&id);

        let pool_cap = borrow_global_mut<PoolCap>(*pool_addr);

        let pool_signer = &generate_signer_for_extending(&pool_cap.extend_ref);
        hook_factory::update_pool(pool_signer, value);
    }

    #[test(signer= @0xfff)]
    fun test_create_and_update(signer: &signer) acquires Vault, PoolCap {
        init_module(&create_signer_for_test(@tapp));

        let pool_id = @012345;
        create_pool(pool_id);
        update_pool(pool_id, 6969);
    }
}

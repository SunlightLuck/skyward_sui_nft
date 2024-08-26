/// This module defines an NFT for representing miners in the Sui ecosystem.
module skyward_keeper::skywardkeeper {
    // === Imports ===

    use std::string::{Self, String};
    use sui::display;
    use sui::object::{Self, UID};
    use sui::package::{Self, Publisher};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};


    // === Errors ===

    /// The error code for when the sender is not owner of NFT contract.
    const ENotOwner: u64 = 0;

    /// The error code for when the argument is invalid.
    const EInvalidArgument: u64 = 1;


    // === Structs ===

    /// The Skyward Keeper NFT represents ownership of a miner in the Sui ecosystem.
    struct SkywardKeeper has key {
        /// The unique identifier of the Skyward Keeper NFT.
        id: UID,
        /// The name of the Skyward Keeper NFT.
        name: String,
        /// The URL of the image representing the Skyward Keeper NFT.
        image_url: String,
    }

    /// The transfer capability to authorize the transfer of a Skyward Keeper NFT.
    struct TransferCap has key, store {
        /// The unique identifier of the capability.
        id: UID,
    }

    /// The one time witness for the Skyward Keeper NFT.
    struct SKYWARDKEEPER has drop{}


  // === Admin Functions ===

    fun init(otw: SKYWARDKEEPER, ctx: &mut TxContext) {
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"project_url"),
        ];
        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"ipfs://{image_url}"),
            string::utf8(b"Skyward Keeper NFT symbolizes CHIRP miner ownership."),
            string::utf8(b"https://chirptoken.io/"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<SkywardKeeper>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(TransferCap{ id: object::new(ctx) }, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    /// Mints a new SkywardKeeper NFT.
    public entry fun mint(pub: &Publisher, count: u64, name: String, image_url: String, recipient: address, ctx: &mut TxContext) {
        assert!(package::from_package<SkywardKeeper>(pub), ENotOwner);
        assert!(package::from_module<SkywardKeeper>(pub), ENotOwner);
        assert!(count > 0, EInvalidArgument);
        while(count > 0) {
            let nft = SkywardKeeper {
                id: object::new(ctx),
                name: name,
                image_url: image_url,
            };
            transfer::transfer(nft, recipient);
            count = count - 1;
        }
    }

    /// Transfers a SkywardKeeper NFT to a new owner.
    public entry fun transfer(_: &TransferCap, nft: SkywardKeeper, recipient: address) {
        transfer::transfer(nft, recipient);
    }

    /// Burns a SkywardKeeper NFT.
    public entry fun burn(nft: SkywardKeeper) {
        let SkywardKeeper { id, name: _, image_url: _ } = nft;
        object::delete(id);
    }

    #[test_only]
    use sui::test_scenario;
    #[test_only]
    use sui::test_utils;
    #[test_only]
    use std::vector;
    #[test_only]
    const NFT_NAME: vector<u8> = b"SkywardKeeper NFT";
    #[test_only]
    const NFT_IMAGE_URL: vector<u8> = b"bafybeifsp6xtj5htj5dc2ygbgijsr5jpvck56yqom6kkkuc2ujob3afzce";
    #[test_only]
    const PUBLISHER: address = @0xA;

    #[test]
    fun test_mint(){
        let scenario = test_scenario::begin(PUBLISHER);
        {
            init(SKYWARDKEEPER{}, test_scenario::ctx(&mut scenario))
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let owner = test_scenario::take_from_sender<Publisher>(&scenario);
            mint(&owner, 10, string::utf8(NFT_NAME), string::utf8(NFT_IMAGE_URL), PUBLISHER, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_address<Publisher>(PUBLISHER, owner);
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let nft_ids = test_scenario::ids_for_sender<SkywardKeeper>(&scenario);
            test_utils::assert_eq(vector::length(&nft_ids), 10);

            while(!vector::is_empty(&nft_ids)) {
                let nft = test_scenario::take_from_sender_by_id<SkywardKeeper>(&scenario, vector::pop_back(&mut nft_ids));
                test_utils::assert_eq(string::index_of(&nft.name, &string::utf8(NFT_NAME)), 0);
                test_utils::assert_eq(string::index_of(&nft.image_url, &string::utf8(NFT_IMAGE_URL)), 0);
                test_scenario::return_to_sender<SkywardKeeper>(&scenario, nft);
            };
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transfer() {
        let sender = @0xB;
        let receiver =  @0xC;
        let scenario = test_scenario::begin(PUBLISHER);
        {
            init(SKYWARDKEEPER{}, test_scenario::ctx(&mut scenario))
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            // The TransferCap might be transferred to another account
            let cap = test_scenario::take_from_sender<TransferCap>(&scenario);
            transfer::public_transfer(cap, sender);
            let owner = test_scenario::take_from_sender<Publisher>(&scenario);
            mint(&owner, 1, string::utf8(NFT_NAME), string::utf8(NFT_IMAGE_URL), sender, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_address<Publisher>(PUBLISHER, owner);
        };
        test_scenario::next_tx(&mut scenario, sender);
        {
            let cap = test_scenario::take_from_sender<TransferCap>(&scenario);
            let nft = test_scenario::take_from_sender<SkywardKeeper>(&scenario);
            transfer(&cap, nft, receiver);
            test_scenario::return_to_sender<TransferCap>(&scenario, cap);
        };
        test_scenario::next_tx(&mut scenario, receiver);
        {
            let nft_ids = test_scenario::ids_for_sender<SkywardKeeper>(&scenario);
            test_utils::assert_eq(vector::length(&nft_ids), 1);
        };
        test_scenario::end(scenario);
    }
}

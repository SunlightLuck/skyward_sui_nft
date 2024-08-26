/// This module defines an NFT for representing earlier adopters.
module embryo::embryo {
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


    // === Structs ===

    /// The Embryo NFT represents represents early adopter.
    struct Embryo has key, store {
        /// The unique identifier of the embryo NFT.
        id: UID,
        /// The name of the Embryo NFT.
        name: String,
        /// The URL of the image representing the Embryo NFT.
        image_url: String,
    }

    /// The one time witness for the Embryo NFT.
    struct EMBRYO has drop{}


  // === Admin Functions ===

    fun init(otw: EMBRYO, ctx: &mut TxContext) {
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"project_url"),
        ];
        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"ipfs://{image_url}"),
            string::utf8(b"Embryo NFT symbolizes early adopter."),
            string::utf8(b"https://chirptoken.io/"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<Embryo>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    /// Mints a new Embryo NFT.
    public entry fun mint(pub: &Publisher, name: String, image_url: String, ctx: &mut TxContext) {
        assert!(package::from_package<Embryo>(pub), ENotOwner);
        assert!(package::from_module<Embryo>(pub), ENotOwner);
        let nft = Embryo {
            id: object::new(ctx),
            name: name,
            image_url: image_url,
        };
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    /// Burns a Embryo NFT.
    public entry fun burn(nft: Embryo) {
        let Embryo { id, name: _, image_url: _ } = nft;
        object::delete(id);
    }

    #[test_only]
    use sui::test_scenario;
    #[test_only]
    use sui::test_utils;
    #[test_only]
    const NFT_NAME: vector<u8> = b"Embryo NFT";
    #[test_only]
    const NFT_IMAGE_URL: vector<u8> = b"bafybeifsp6xtj5htj5dc2ygbgijsr5jpvck56yqom6kkkuc2ujob3afzce";
    #[test_only]
    const PUBLISHER: address = @0xA;

    #[test]
    fun test_mint(){
        let scenario = test_scenario::begin(PUBLISHER);
        {
            init(EMBRYO{}, test_scenario::ctx(&mut scenario))
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let owner = test_scenario::take_from_sender<Publisher>(&scenario);
            mint(&owner, string::utf8(NFT_NAME), string::utf8(NFT_IMAGE_URL), test_scenario::ctx(&mut scenario));
            test_scenario::return_to_address<Publisher>(PUBLISHER, owner);
        };
        test_scenario::next_tx(&mut scenario, PUBLISHER);
        {
            let nft = test_scenario::take_from_sender<Embryo>(&scenario);
            test_utils::assert_eq(string::index_of(&nft.name, &string::utf8(NFT_NAME)), 0);
            test_utils::assert_eq(string::index_of(&nft.image_url, &string::utf8(NFT_IMAGE_URL)), 0);
            test_scenario::return_to_sender<Embryo>(&scenario, nft);
        };
        test_scenario::end(scenario);
    }
}

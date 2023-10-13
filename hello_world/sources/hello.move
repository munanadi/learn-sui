module hello_world::hello_world { 
  use std::string;
  use sui::object::{Self, UID};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};

  struct HelloWorld has key, store {
    id: UID,
    text: string::String,
  }

  // Entry functions - that can be called by transactions
  // has mut txn context as last param, no return type, entry keyword
  public entry fun mint(ctx: &mut TxContext) {
    // Create the object
    let object = HelloWorld { 
      id: object::new(ctx),
      text: string::utf8(b"Hello world!")
    };

    transfer::transfer(object, tx_context::sender(ctx));
  }
}
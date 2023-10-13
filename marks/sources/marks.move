module marks::marks {
  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer;
  use sui::event;

  // Object Wrapping
  struct WrappedObject has key {
    id: UID,
    insideObject: InsideObj
  }

  // If objects are stored inside other objects, they need to have the store capability
  // This cannot be passed inside move calls and the only way to access this is the wrapped object.
  struct InsideObj has store {
    history: u8,
    math: u8,
    literature: u8
  }

  struct WrappableTransacript has key, store {
    id: UID,
    history: u8,
    math: u8,
    literature: u8
  }

  struct Folder has key {
    id: UID,
    transcript: WrappableTransacript,
    intended_address: address
  }

  // Capability - Access control to your contracts
  // Type that marks capability to create, update and delete transcripts
  // we omit `storage` here to make this capability non-trasnferable
  struct TeacherCap has key {
    id: UID
  }

  // Create a gated method that will create transcripts
  // We pass a ref of TeacherCap and consume it immediately. This mean only a address with such an object will have the 
  // ability to call this method, thereby implemnting access control
  public entry fun create_wrapped_transcript(_: &TeacherCap, history: u8, math: u8, literature: u8, ctx: &mut TxContext) {
    let transcriptObject = WrappableTransacript {
      id: object::new(ctx),
      math,
      literature,
      history
    };

    transfer::transfer(transcriptObject, tx_context::sender(ctx))
  }

  // Module initializer is called only once on module publish.
  // Setitng the teacher cap to whoever deploys the module.
  fun init(ctx: &mut TxContext) {
    transfer::transfer(
      TeacherCap {
        id: object::new(ctx)
      }, 
      tx_context::sender(ctx)
    )
  }

  // Add additional teacher caps or can even define new ability to add more access controls
  fun add_additional_teacher_caps(_: &TeacherCap, new_teacher_cap_add: address, ctx: &mut TxContext) {
    transfer::transfer(
      TeacherCap {
        id: object::new(ctx)
      }, 
      new_teacher_cap_add
    )
  }

  // Event when transcript is requested
  struct TranscriptRequested has copy, drop {
    // Object ID of the transcription wrapper
    wrapped_id: ID,
    // requester of the transcript
    requester: address,
    // intended address of the transcript
    intended_address: address
  }

  // Custom Errors
  const ENotIntendedAddress:u64 = 1;

  // Give the intended adderss a folder
  public entry fun request_transcript(transcript: WrappableTransacript, intended_address: address, ctx: &mut TxContext) {
    let folderObject = Folder {
      id: object::new(ctx),
      transcript,
      intended_address
    };

    // Emit transcript requested event
    event::emit(TranscriptRequested{
      wrapped_id: object::uid_to_inner(&folderObject.id),
      requester: tx_context::sender(ctx),
      intended_address
    });

    // Transfer this to the intended_address
    transfer::transfer(folderObject, intended_address);
  }

  // Get wrapped transacript
  public entry fun unpack_wrapped_transcript(folder: Folder, ctx: &mut TxContext) {
    // Check if the person unpacking is the intended viewer
    assert!(folder.intended_address == tx_context::sender(ctx), ENotIntendedAddress);

    let Folder {
      id,
      transcript,
      intended_address: _
    } = folder;

    // Transfer this transcript to the sender
    transfer::transfer(transcript, tx_context::sender(ctx));

    // Delete the wrapper
    object::delete(id);
  }

  // -----------------------------------

  // Standalone Object
  struct Transcript has key{
    id: UID,
    history: u8,
    math: u8,
    literature: u8
  }

  public entry fun create_transcript_object(history: u8, math: u8, literature: u8, ctx: &mut TxContext) {
    let transcriptObject = Transcript {
      id: object::new(ctx),
      history,
      math,
      literature
    };

    // here the transcriptObject object will be owned by the addrsse sending the tranasction
    transfer::transfer(transcriptObject, tx_context::sender(ctx));

    // object can be owned by other objects as well - dynamic_object_field - called a child_object

    // Shared immutable objects
    // These do not have an exclusive owner.
    // transfer::freeze_object(transcriptObject);

    // Shared mutable objects, these need global ordering and consensus.
    // transfer::share_object(transcriptObject);
  }

  // Retrieve score but cannot modify
  public fun view_score(transcriptObject: &Transcript): u8 {
    transcriptObject.literature
  }

  // Allwoed to edit but not delete
  public entry fun update_score(transcriptObject: &mut Transcript, new_score: u8) {
    transcriptObject.literature = new_score
  }

  // Allowed to do anything to the whole object
  public entry fun do_anything(transcriptObject: Transcript) {
    // unpacking the id from the object can be done inside the module that defines the object. 
    // destroying is also called unpacking
    let Transcript { id, history: _, math: _, literature: _ } = transcriptObject;

    // If need to do this outisde the module, then we need to expose the functions relative to this.
    object::delete(id);
  }
}
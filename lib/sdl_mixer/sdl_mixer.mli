module Mix : sig
  module Music : sig type t end
  module Chunk : sig type t end
  
  module Init : sig
    type t = int
    val ( + ) : t -> t -> t
    val ( = ) : t -> t -> bool
    val flac : t
    val mod_ : t
    val mp3 : t 
    val ogg : t
  end
  
  val free_music : Music.t -> unit
  val free_chunk : Chunk.t -> unit
  val allocate_channels : int -> int
  val halt_music : unit -> int
  val volume : int -> int -> int
  val volume_chunk : Chunk.t -> int -> int
  val volume_music : int -> int
  val init : int -> unit
  val open_audio : int -> int -> int -> int -> unit
  val load_mus : string -> Music.t
  val play_music : Music.t -> int -> unit
  val load_wav : string -> Chunk.t
  val play_channel : int -> Chunk.t -> int -> int
  val halt_channel : int -> unit
end

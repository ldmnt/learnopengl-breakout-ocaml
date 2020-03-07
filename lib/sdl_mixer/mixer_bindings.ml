open Ctypes
open Cstubs

module C (F : FOREIGN) = struct
open F
      
module Music : sig
  type t
  val t : t typ
  val is_null : t -> bool
end = struct
  type t = unit ptr
  let t = ptr void
  let is_null = is_null
end

module Chunk : sig
  type t
  val t : t typ
  val is_null : t -> bool
end = struct
  type t = unit ptr
  let t = ptr void
  let is_null = is_null
end

module Init = struct
  type t = int
  let ( + ) = Int.logor
  let ( = ) = Int.equal
  let flac = 1
  let mod_ = 2
  let mp3 = 8
  let ogg = 16
end

let get_error =
  foreign "Mix_GetError" (void @-> returning string)

let int_as_uint16_t =
  view ~read:Unsigned.UInt16.to_int ~write:Unsigned.UInt16.of_int uint16_t

let init =
  foreign "Mix_Init" (int @-> returning int)

let open_audio =
  foreign "Mix_OpenAudio" (int @-> int_as_uint16_t @-> int @-> int @-> returning int)

let load_mus =
  foreign "Mix_LoadMUS" (string @-> returning Music.t)

let play_music =
  foreign "Mix_PlayMusic" (Music.t @-> int @-> returning int)

let free_music =
  foreign "Mix_FreeMusic" (Music.t @-> returning void)

let load_wav =
  foreign "Mix_LoadWAV" (string @-> returning Chunk.t)

let free_chunk =
  foreign "Mix_FreeChunk" (Chunk.t @-> returning void)

let play_channel =
  foreign "Mix_PlayChannel" (int @-> Chunk.t @-> int @-> returning int)

let allocate_channels =
  foreign "Mix_AllocateChannels" (int @-> returning int)

let halt_channel =
  foreign "Mix_HaltChannel" (int @-> returning int)

let halt_music =
  foreign "Mix_HaltMusic" (void @-> returning int)

let volume =
  foreign "Mix_Volume" (int @-> int @-> returning int)

let volume_chunk =
  foreign "Mix_VolumeChunk" (Chunk.t @-> int @-> returning int)

let volume_music =
  foreign "Mix_VolumeMusic" (int @-> returning int)

end

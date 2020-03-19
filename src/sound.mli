type t =
  | Music of Sdl_mixer.Mix.Music.t
  | Chunk of Sdl_mixer.Mix.Chunk.t
               
val init : unit -> unit
val play : t * int option -> t * int option
val delete : t -> unit

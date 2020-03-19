open Base

val load_shader : vertex:string -> fragment:string -> ?geometry:string -> string -> unit
val get_shader : string -> Shader.t
                             
val load_texture : file:string -> alpha:bool -> name:string -> unit
val get_texture : string -> Texture.t
                              
val load_sound : file:string -> name:string -> [< `Chunk | `Music ] -> unit
val get_sound : string -> Sound.t * int option
val play_sound : string -> unit
  
val clear : unit -> unit

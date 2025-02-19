open Base

type t
  
val use : t -> unit
val compile : vertex:string -> fragment:string -> geometry:string Option.t -> t
val delete : t -> unit
val set_integer : t -> string -> ?use_shader:bool -> int -> unit
val set_float : t -> string -> ?use_shader:bool -> float -> unit
val set_vector2f : t -> string -> ?use_shader: bool -> float * float -> unit
val set_vector3f : t -> string -> ?use_shader: bool -> float * float * float -> unit
val set_vector4f : t -> string -> ?use_shader: bool -> float * float * float * float -> unit
val set_matrix4 : t -> string -> ?use_shader:bool -> float array array -> unit
val id : t -> int

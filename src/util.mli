open Base

module BA := Bigarray

type direction = Up | Right | Down | Left

val bigarray_create : ('a, 'b) BA.kind -> int -> ('a, 'b, BA.c_layout) BA.Array1.t
val float_bigarray : float array -> (float, BA.float32_elt, BA.c_layout) BA.Array1.t
val int_bigarray : int32 array -> (int32, BA.int32_elt, BA.c_layout) BA.Array1.t

val get_int : ((int32, BA.int32_elt, BA.c_layout) BA.Array1.t -> unit) -> int
val get_string : int -> ((char, BA.int8_unsigned_elt, BA.c_layout) BA.Array1.t -> unit) -> string
val set_int : ((int32, BA.int32_elt, BA.c_layout) BA.Array1.t -> 'a) -> int -> 'a
  
module Mat : sig
  val ( ** ) : float array array -> float array array -> float array array
  val identity : unit -> float array array
  val translation : float -> float -> float -> float array array
  val rotation_around_z : angle:float -> float array array
  val scaling : float -> float -> float array array
  val orthographic_projection : float -> float -> float -> float -> float -> float -> float array array
  val to_bigarray : float array array -> (float, BA.float32_elt, BA.c_layout) BA.Array1.t
end

module Vec2 : sig
  type t = { x : float; y : float; }
  val zero : t
  val add : t -> t -> t
  val ( + ) : t -> t -> t
  val mul : float -> t -> t
  val ( $* ) : float -> t -> t
  val ( - ) : t -> t -> t
  val clamp : t -> t -> t -> t
  val squared_norm : t -> float
  val dot : t -> t -> float
  val length : t -> float
  val normalize : t -> t
  val direction : t -> direction
end

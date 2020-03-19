open Base
    
type t = { bricks : Game_object.t list }

val load : float -> float -> string -> t
val draw : t -> unit
val is_completed : t -> bool

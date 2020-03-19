open Base
    
module V := Util.Vec2

type t

val make : int -> Texture.t -> Shader.t -> t
val update : t -> float -> Game_object.t -> int -> V.t -> unit
val draw : t -> unit

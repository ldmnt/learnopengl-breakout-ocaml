open Base

module V := Util.Vec2
              
type t = {
  obj : Game_object.t
; radius : float
; stuck : bool
; sticky : bool
; pass_through : bool
}

val make :
  pos:V.t ->
  ?radius:float ->
  ?sticky:bool ->
  ?pass_through:bool ->
  ?velocity:V.t -> sprite:Texture.t -> unit -> t
val move : t -> float -> float -> t
val reset : t -> pos:V.t -> velocity:V.t -> t
val stick_to_player : t -> player:Game_object.t -> t
val check_collision : t -> Game_object.t -> bool * Util.direction * V.t

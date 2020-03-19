open Base
    
module V := Util.Vec2
              
type t = {
  pos : V.t
; size : V.t
; velocity : V.t
; color : float * float * float
; rotation : float
; sprite : Texture.t
; is_solid : bool
; destroyed : bool
}

val make :
  pos:V.t ->
  size:V.t ->
  sprite:Texture.t ->
  ?color:float * float * float ->
  ?velocity:V.t ->
  ?rotation:float ->
  ?destroyed:bool -> ?is_solid:bool -> unit -> t
val draw : t -> unit
val check_collision : t -> t -> bool

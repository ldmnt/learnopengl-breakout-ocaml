open Base 

module V := Util.Vec2
              
type typ = Speed | Sticky | PassThrough | PadSizeIncrease | Confuse | Chaos
           
type t = {
  obj : Game_object.t
; typ : typ
; duration : float
; activated : bool
}

val make : typ -> float * float * float -> float -> V.t -> Texture.t -> t

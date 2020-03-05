open Base

module V = Util.Vec2

type typ =
    Speed
  | Sticky
  | PassThrough
  | PadSizeIncrease
  | Confuse
  | Chaos

type t = {
  obj : Game_object.t
; typ : typ
; duration : float
; activated : bool
}

let size = V.{ x = 60.; y = 20. }
let velocity = V.{ x = 0.; y = 150. }


let make typ color duration pos txt =
  { obj = Game_object.make ~pos ~size ~sprite:txt ~color ~velocity ();
    typ; duration; activated = false }

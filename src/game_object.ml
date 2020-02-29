open Base

module V = Util.Vec2

type t = {
  pos : V.t
; size : V.t
; velocity : V.t
; color : float Array.t
; rotation : float
; sprite : Texture.t
; is_solid : bool
; destroyed : bool
}

let make ~pos ~size ~sprite
    ?(color = [| 1.; 1.; 1. |])
    ?(velocity = V.{x=0.; y=0.})
    ?(rotation = 0.)
    ?(destroyed = false)
    ?(is_solid = true)
    () =
  { pos; size; velocity; sprite; rotation; is_solid; destroyed; color}

let draw t =
  Sprite.draw t.sprite t.pos t.size ~rotate:t.rotation ~color:t.color

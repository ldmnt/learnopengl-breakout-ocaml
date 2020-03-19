open Base

module V = Util.Vec2

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

let make ~pos ~size ~sprite
    ?(color = (1., 1., 1.))
    ?(velocity = V.{x=0.; y=0.})
    ?(rotation = 0.)
    ?(destroyed = false)
    ?(is_solid = true)
    () =
  { pos; size; velocity; sprite; rotation; is_solid; destroyed; color}

let draw t =
  Sprite.draw t.sprite t.pos t.size ~rotate:t.rotation ~color:t.color

let check_collision a b = (* AABB - AABB collision *)
  let open Float in
  (* collision on x-axis ? *)
  let collision_x = a.pos.x +. a.size.x >= b.pos.x && b.pos.x +. b.size.x >= a.pos.x in
  (* collision on y-axis ? *)
  let collision_y = a.pos.y +. a.size.y >= b.pos.y && b.pos.y +. b.size.y >= a.pos.y in
  (* collision only if on both axes *)
  collision_x && collision_y

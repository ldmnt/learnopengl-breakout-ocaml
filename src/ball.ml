module V = Util.Vec2

type t = {
  obj : Game_object.t
; radius : float
; stuck : bool
}

let make ~pos ?(radius=12.5) ?velocity ~sprite () =
  {
    obj =
      Game_object.make ~pos ~sprite ?velocity
        ~size:V.{ x = radius *. 2.; y = radius *. 2. } ()
  ; radius
  ; stuck = true
  }

let move t dt window_width =
  let new_pos = V.(mul dt t.obj.velocity |> add t.obj.pos) in
  let new_pos, new_velocity =
    match t.stuck with
    | false ->
      let pos, v, size = new_pos, t.obj.velocity, t.obj.size in
      let new_x, new_vx =
        if Float.(pos.x <= 0.) then
          0., -. v.x
        else if Float.(pos.x +. size.x >= window_width) then
          window_width -. size.x, -. v.x 
        else pos.x, v.x in
      let new_y, new_vy =
        if Float.(pos.y <= 0.) then
          0., -. v.y
        else pos.y, v.y in
      V.{ x = new_x; y = new_y }, V.{ x = new_vx; y = new_vy }
                                
    | true -> t.obj.pos, t.obj.velocity
  in

  let obj = { t.obj with pos = new_pos; velocity = new_velocity } in
  { t with obj }

let reset t pos velocity =
  let obj = { t.obj with pos; velocity } in
  { t with obj; stuck = true }

let stick_to_player t ~player =
  let pos = V.(Game_object.(add player.pos { x = player.size.x /. 2. -. t.radius; y = -. t.radius *. 2. })) in
  { t with obj = { t.obj with pos; velocity = V.zero } }


let check_collision ball (block : Game_object.t) = (* AABB - Circle collision *)
  let center = V.{ x = ball.obj.pos.x +. ball.radius; y = ball.obj.pos.y +. ball.radius } in
  let aabb_half_extents = V.((1. /. 2.) $* block.size) in
  let aabb_center = V.(block.pos + aabb_half_extents) in
  let difference = V.(center - aabb_center) in
  let clamped = V.(clamp difference (-.1. $* aabb_half_extents) aabb_half_extents) in
  let closest = V.(aabb_center + clamped) in
  let difference = V.(closest - center) in
  if Float.(V.squared_norm difference < ball.radius *. ball.radius) then
    (true, V.direction difference, difference)
  else
    (false, Up, V.zero)

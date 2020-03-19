open Base
    
module V = Util.Vec2

type t = {
  obj : Game_object.t
; radius : float
; stuck : bool
; sticky : bool
; pass_through : bool
}

let make
    ~pos
    ?(radius=12.5)
    ?(sticky=false)
    ?(pass_through=false)
    ?velocity
    ~sprite () =
  {
    obj =
      Game_object.make ~pos ~sprite ?velocity
        ~size:V.{ x = radius *. 2.; y = radius *. 2. } ()
  ; radius
  ; stuck = true
  ; sticky
  ; pass_through
  }

let move t dt window_width =
  let new_pos, new_velocity =
    match t.stuck with
    | false -> (* If not stuck to player board *)
      (* Move the ball *)
      let pos = V.(dt $* t.obj.velocity |> add t.obj.pos) in
      (* Then check in outside window bounds and if so, reverse velocity and restore at correct position *)
      let v, size = t.obj.velocity, t.obj.size in
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

let reset t ~pos ~velocity =
  let obj = { t.obj with pos; velocity } in
  { t with obj; stuck = true }

let stick_to_player t ~player =
  let pos = V.(Game_object.(add player.pos { x = player.size.x /. 2. -. t.radius; y = -. t.radius *. 2. })) in
  { t with obj = { t.obj with pos; velocity = V.zero } }

let check_collision ball (block : Game_object.t) = (* AABB - Circle collision *)
  (* Get center point circle first *)
  let center = V.{ x = ball.obj.pos.x +. ball.radius; y = ball.obj.pos.y +. ball.radius } in
  (* Calculate AABB info (center, half-extents) *)
  let aabb_half_extents = V.((1. /. 2.) $* block.size) in
  let aabb_center = V.(block.pos + aabb_half_extents) in
  (* Get difference vector between both centers *)
  let difference = V.(center - aabb_center) in
  let clamped = V.(clamp difference (-.1. $* aabb_half_extents) aabb_half_extents) in
  (* Now that we know the clamped values, add this to AABB_center and we get the value of box closest to circle *)
  let closest = V.(aabb_center + clamped) in
  (* Now retrieve vector between center circle and closest point AABB and check if length < radius *)
  let difference = V.(closest - center) in
  (* Not <= since in that case a collision also occurs when object one exactly touches object two,
     which they are at the end of each collision resolution stage. *)
  if Float.(V.squared_norm difference < ball.radius *. ball.radius) then
    (true, V.direction difference, difference)
  else
    (false, Up, V.zero)

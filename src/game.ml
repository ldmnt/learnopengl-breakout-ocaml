open Base
    
module RM = Resource_manager
module V = Util.Vec2

let abs_float = Caml.abs_float

let player_size = V.{ x = 100.; y = 20.}
let player_velocity = 500.
let initial_ball_velocity = V.{ x = 100.; y = -. 350. }
let ball_radius = 12.5

type state = {
  last_frame : float
; level : int
; player : Game_object.t
; ball : Ball.t
}

type mode = Active | Menu | Win

type t = {
  mode : mode
; state : state
; levels : Game_level.t Array.t
; particle_generator : Particle_generator.t
; width : float
; height : float
}


let keys : (GLFW.key, bool) Map.Poly.t ref = ref Map.Poly.empty

let update_key k v =
  keys := Map.Poly.set !keys ~key:k ~data:v

let get_key k =
  Map.Poly.find !keys k
  |> Option.value ~default:false


let initial_player_pos width height =
  V.{
    x = Float.(width / 2. - player_size.x / 2.);
    y = Float.(height - player_size.y)
  }

let init width height =
  (* Load shaders *)
  RM.load_shader
    ~vertex:"shaders/sprite.vs"
    ~fragment:"shaders/sprite.frag"
    "sprite";
  RM.load_shader
    ~vertex:"shaders/particle.vs"
    ~fragment:"shaders/particle.frag"
    "particle";
  
  (* Configure shaders *)
  let projection = Util.Mat.orthographic_projection 0. width height 0. (-.1.) 1. in
  let s = RM.get_shader "sprite" in
  Shader.set_integer s "image" 0 ~use_shader:true;
  Shader.set_matrix4 s "projection" projection;
  Sprite.init s;
  let s = RM.get_shader "particle" in
  Shader.set_integer s "sprite" 0 ~use_shader:true;
  Shader.set_matrix4 s "projection" projection;

  (* Load textures *)
  RM.load_texture ~file:"textures/background.jpg" ~alpha:false ~name:"background";
  RM.load_texture ~file:"textures/awesomeface.png" ~alpha:true ~name:"face";
  RM.load_texture ~file:"textures/block.png" ~alpha:false ~name:"block";
  RM.load_texture ~file:"textures/block_solid.png" ~alpha:false ~name:"block_solid";
  RM.load_texture ~file:"textures/paddle.png" ~alpha:true ~name:"paddle";
  RM.load_texture ~file:"textures/particle.png" ~alpha:true ~name:"particle";

  (* Initialize paddle *)
  let player = Game_object.make
      ~pos:(initial_player_pos width height)
      ~size:player_size
      ~sprite:(RM.get_texture "paddle")
      ~is_solid:true
      () in

  (* Initialize ball *)
  let ball =
    Ball.make ~pos:V.zero ~radius:ball_radius ~velocity:initial_ball_velocity
      ~sprite:(RM.get_texture "face") ()
    |> Ball.stick_to_player ~player in
               
  (* Initial state *)
  let state0 = {
    level = 0;
    last_frame = GLFW.getTime ();
    player;
    ball
  } in

  (* Load levels *)
  let levels = [|
    Game_level.load width (height *. 0.5) "levels/one.lvl";
    Game_level.load width (height *. 0.5) "levels/two.lvl";
    Game_level.load width (height *. 0.5) "levels/three.lvl";
    Game_level.load width (height *. 0.5) "levels/four.lvl";
  |] in

  (* Create particle generator *)
  let particle_generator =
    Particle_generator.make 500 (RM.get_texture "particle") (RM.get_shader "particle") in
  
  { mode = Active; state = state0; levels; width; height; particle_generator }


let reset_level levels i =
  let Game_level.{ bricks } = levels.(i) in
  let bricks = List.map bricks ~f:(fun b -> { b with destroyed = false }) in
  levels.(i) <- { bricks }


let reset_player g =
  let player = { g.state.player with pos = initial_player_pos g.width g.height } in
  let ball =
    Ball.reset g.state.ball V.zero V.zero
    |> Ball.stick_to_player ~player in
  { g with state = { g.state with player; ball } }


let resolve_collision (ball : Ball.t) (brick : Game_object.t) direction (diff_vector : V.t) =
  (* Destroy brick if not solid *)
  let destroyed = if not brick.is_solid then true else brick.destroyed in

  let V.{ x = px; y = py }, V.{ x = vx; y = vy } = ball.obj.pos, ball.obj.velocity in
  let px, py, vx, vy =
    match direction with
    | Util.Left | Util.Right ->
      let penetration = ball.radius -. abs_float diff_vector.x in
      let px = match direction with
        | Util.Left -> px +. penetration
        | Util.Right -> px -. penetration
        | _ -> assert false in
      px, py, -. vx, vy

    | Util.Up | Util.Down ->
      let penetration = ball.radius -. abs_float diff_vector.y in
      let py = match direction with
        | Util.Up -> py -. penetration
        | Util.Down -> py +. penetration
        | _ -> assert false in
      px, py, vx, -. vy
  in

  let pos, velocity = V.{ x = px; y = py }, V.{ x = vx; y = vy } in
  let ball = { ball with obj = { ball.obj with pos; velocity } } in
  let brick = { brick with destroyed } in
  (ball, brick)


let do_collisions g =
  let state, level = g.state, g.levels.(g.state.level) in

  (* Resolve collision between ball and blocks *)
  let resolve_one (ball : Ball.t) (brick : Game_object.t) =
    if not brick.destroyed then
      let (collide, direction, diff_vector) = Ball.check_collision ball brick in
      if collide then
        resolve_collision ball brick direction diff_vector
      else (ball, brick)
    else
      (ball, brick) in
  let (ball, bricks) = List.fold_map level.bricks ~init:state.ball ~f:resolve_one in
  g.levels.(g.state.level) <- { bricks };
 
  (* Resolve collision between ball and player *)
  let player = state.player in
  let (collide, direction, diff_vector) = Ball.check_collision ball player in
  let ball =
    if not ball.stuck && collide then
      let board_center = player.pos.x +. player.size.x /. 2. in
      let distance = ball.obj.pos.x +. ball.radius -. board_center in
      let percentage = distance /. (player.size.x /. 2.) in
      let strength = 2. in
      let old_velocity = ball.obj.velocity in
      let velocity = V.{
        x = initial_ball_velocity.x *. percentage *. strength;
        y = -. abs_float old_velocity.y
      } in
      let velocity = V.( (length old_velocity) $* (normalize velocity) ) in
      { ball with obj = { ball.obj with velocity } }
    else ball
  in
  
  { g with state = { g.state with ball } }


let update g ~dt =
  (* Update objects *)
  let ball = Ball.move g.state.ball dt g.width in
  let state = { g.state with ball } in
  let g = do_collisions { g with state } in

  (* Check if ball reached the bottom *)
  let g =
    if Float.(g.state.ball.obj.pos.y >= g.height) then begin
      reset_level g.levels g.state.level;
      reset_player g
    end else g in

  (* Update particles *)
  let ball = g.state.ball in
  let offset = V.{ x = ball.radius /. 2.; y = ball.radius /. 2. } in
  Particle_generator.update g.particle_generator dt ball.Ball.obj 2 offset;

  g
    


let process_input g ~dt =
  match g.mode with
  | Active ->
    (* Update paddle position *)
    let player = g.state.player in
    let velocity = player_velocity *. dt in
    let new_x = match get_key GLFW.A, get_key GLFW.D, player.pos.x with
      | true, false, x when Float.(x >= 0.) ->
        x -. velocity
      | false, true, x when Float.(x <= g.width -. player.size.x) ->
        x +. velocity
      | _, _, x -> x in
    let player = { player with pos = { player.pos with x = new_x } } in

    (* Update ball position *)
    let ball = g.state.ball in
    let ball = if ball.stuck then Ball.stick_to_player ~player ball else ball in
    let ball =
      if get_key GLFW.Space then
        let obj = { ball.obj with velocity = initial_ball_velocity } in
        { ball with stuck = false; obj}
      else ball in
    
    { g with state = { g.state with player; ball } }
    
  | Menu | Win -> g


let render g =
  match g.mode with
  | Active ->
    (* Draw background *)
    Sprite.draw
      (RM.get_texture "background")
      { x = 0.; y = 0. }
      { x = g.width; y = g.height };

    (* Draw level *)
    let current_level = g.state.level in
    Game_level.draw g.levels.(current_level);

    (* Draw player *)
    Game_object.draw g.state.player;

    (* Draw particles *)
    Particle_generator.draw g.particle_generator;
    
    (* Draw ball *)
    Game_object.draw g.state.ball.obj
      
  | _ -> ()

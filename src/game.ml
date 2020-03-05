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
; shake_time : float
; powerups : Powerup.t list
}

type mode = Active | Menu | Win

type t = {
  mode : mode
; state : state
; levels : Game_level.t Array.t
; particle_generator : Particle_generator.t
; effects : Postprocessor.t
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
  RM.load_shader
    ~vertex:"shaders/post_processing.vs"
    ~fragment:"shaders/post_processing.frag"
    "postprocessing";
  
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
  RM.load_texture ~file:"textures/powerup_speed.png" ~alpha:true ~name:"powerup_speed";
  RM.load_texture ~file:"textures/powerup_sticky.png" ~alpha:true ~name:"powerup_sticky";
  RM.load_texture ~file:"textures/powerup_increase.png" ~alpha:true ~name:"powerup_increase";
  RM.load_texture ~file:"textures/powerup_confuse.png" ~alpha:true ~name:"powerup_confuse";
  RM.load_texture ~file:"textures/powerup_chaos.png" ~alpha:true ~name:"powerup_chaos";
  RM.load_texture ~file:"textures/powerup_passthrough.png" ~alpha:true ~name:"powerup_passthrough";

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
    ball;
    shake_time = 0.;
    powerups = []
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

  (* Initialize postprocessor *)
  let effects =
    Postprocessor.make (RM.get_shader "postprocessing") (Int.of_float width) (Int.of_float height) in
  
  { mode = Active; state = state0; levels; width; height; particle_generator; effects }


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


let should_spawn chance =
  Random.int_incl 0 (chance - 1) = 0


let spawn_data =
  let open Powerup in
  [
    (75, Speed, [|0.5; 0.5; 1.0|], 0., "powerup_speed");
    (75, Sticky, [|1.0; 0.5; 1.0|], 20., "powerup_sticky");
    (75, PassThrough, [|0.5; 1.0; 0.5|], 10., "powerup_passthrough");
    (75, PadSizeIncrease, [|1.0; 0.6; 0.4|], 0., "powerup_increase");
    (15, Confuse, [|1.0; 0.3; 0.3|], 15.0, "powerup_confuse");
    (15, Chaos, [|0.9; 0.25; 0.25|], 15.0, "powerup_chaos");
  ]

let spawn_powerups pus block =
  let spawn_one (spawn_probability, typ, color, duration, txt) =
    match should_spawn spawn_probability with
    | true -> Some (Powerup.make typ color duration block.Game_object.pos (RM.get_texture txt))
    | false -> None in
  let maybe_pus = List.map spawn_data spawn_one in
  pus @ List.filter_opt maybe_pus

let activate_powerup g (pu : Powerup.t) =
  let open Powerup in
  let ball, player = g.state.ball, g.state.player in
  match pu.typ with
  | Speed ->
    let obj = ball.obj in
    let ball = { ball with obj = { obj with velocity = V.(1.2 $* obj.velocity) } } in
    { g with state = { g.state with ball } }
  | Sticky ->
    let ball = { ball with sticky = true } in
    let player = { player with color = [|1.; 0.5; 1.|] } in
    { g with state = { g.state with ball; player } }
  | PassThrough ->
    let ball = { ball with pass_through = true; obj = { ball.obj with color = [|1.; 0.5; 0.5|] } } in
    { g with state = { g.state with ball } }
  | PadSizeIncrease ->
    let player = { player with size = { player.size with x = player.size.x +. 50. } } in
    { g with state = { g.state with player } }
  | Confuse ->
    let effects = if not g.effects.chaos then
        { g.effects with confuse = true }
      else g.effects in
    { g with effects }
  | Chaos ->
    let effects = if not g.effects.confuse then
        { g.effects with chaos = true }
      else g.effects in
    { g with effects }


let update_powerups g dt =
  let powerups, ball, player, effects =
    ref g.state.powerups, ref g.state.ball, ref g.state.player, ref g.effects in

  let is_other_powerup_active typ =
    let same_typ = List.filter !powerups ~f:(fun pu -> pu.activated && phys_equal pu.typ typ) in
    Int.(List.length same_typ > 1) in
  
  let deactivate (pu : Powerup.t) =
    if not (is_other_powerup_active pu.typ) then
      match pu.typ with
      | Sticky ->
        ball := { !ball with sticky = false };
        player := { !player with color = [|1.0; 1.0; 1.0|] }
      | PassThrough ->
        ball := { !ball with pass_through = false; obj = { !ball.obj with color = [|1.0; 1.0; 1.0|] } }
      | Confuse ->
        effects := { !effects with confuse = false }
      | Chaos ->
        effects := { !effects with chaos = false }
      | PadSizeIncrease | Speed -> (); in

  let update_pu (pu : Powerup.t) =
    let pos = V.(pu.obj.pos + (dt $* pu.obj.velocity)) in
    let duration, activated =
      if pu.activated then
        let duration = pu.duration -. dt in
        let activated =
          if Float.(duration <= 0.) then (deactivate pu; false) else pu.activated in
        duration, activated
      else
        pu.duration, pu.activated in
    { pu with obj = { pu.obj with pos}; duration; activated } in

  let not_erasable (pu : Powerup.t) = not (pu.obj.destroyed && not pu.activated) in
  
  let powerups =
    !powerups
    |> List.map ~f:update_pu
    |> List.filter ~f:not_erasable in
  let state = { g.state with ball = !ball; player = !player; powerups } in
  { g with state; effects = !effects }
            
                                
let resolve_collision (ball : Ball.t) (brick : Game_object.t) direction (diff_vector : V.t) =  
  (* Destroy brick if not solid *)
  let destroyed = if not brick.is_solid then true else brick.destroyed in
  let brick = { brick with destroyed } in

  let ball =
    if not (ball.pass_through && (not brick.is_solid)) then
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
      { ball with obj = { ball.obj with pos; velocity } }
    else
      ball in
  (ball, brick)


let do_collisions g =
  (* Resolve collision between ball and blocks *)
  let g =
    let state, level = g.state, g.levels.(g.state.level) in
    let must_shake = ref false in
    let resolve_one ((ball : Ball.t), pus) (brick : Game_object.t) =
      if not brick.destroyed then
        let (collide, direction, diff_vector) = Ball.check_collision ball brick in
        if collide then begin
          let pus =
            if brick.is_solid then begin
              must_shake := true; (* If brick is solid, shake effect must be enabled *)
              pus
            end else
              spawn_powerups pus brick in
          let (ball, brick) = resolve_collision ball brick direction diff_vector in
          ((ball, pus), brick)
        end else
          ((ball, pus), brick)
      else
        ((ball, pus), brick) in
    let ((ball, powerups), bricks) = List.fold_map level.bricks ~init:(state.ball, state.powerups) ~f:resolve_one in
    g.levels.(g.state.level) <- { bricks };
    let shake_time, effects = (* Enable shake effect if necessary *)
      if !must_shake then 0.05, { g.effects with shake = true }
      else g.state.shake_time, g.effects in
    { g with state = { g.state with shake_time; ball; powerups }; effects } in

  (* Resolve collision between ball and player *)
  let g = 
    let player, ball = g.state.player, g.state.ball in
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
        let stuck = ball.sticky in
        { ball with stuck; obj = { ball.obj with velocity } }
      else ball
    in
    { g with state = { g.state with ball; player } } in

  (* Resolve collision between power ups and player *)
  let g =
    let update_powerup g (pu : Powerup.t) =
      let g = ref g in
      let pu =
        if not pu.obj.destroyed then
          let pu =
            if Float.(pu.obj.pos.y >= !g.height) then
              { pu with obj = { pu.obj with destroyed = true } }
            else pu in
          if Game_object.check_collision pu.obj !g.state.player then begin
            g := activate_powerup !g pu;
            { pu with activated = true; obj = { pu.obj with destroyed = true } }
          end else pu
        else pu in
      (!g, pu)
    in
    let (g, powerups) = List.fold_map ~init:g ~f:update_powerup g.state.powerups in
    
    { g with state = { g.state with powerups } } in

  g


let update g ~dt =
  (* Update objects *)
  let ball = Ball.move g.state.ball dt g.width in
  let state = { g.state with ball } in

  (* Check for collisions *)
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

  (* Stop shaking if shake timer is done *)
  let shake_time, effects = match g.state.shake_time with
    | t when Float.(t > 0.) ->
      let t = t -. dt in
      let effects = if Float.(t <= 0.) then { g.effects with shake = false } else g.effects in
      t, effects
    | t -> t, g.effects in
  let g = { g with effects; state = { g.state with shake_time } } in
  
  (* Update powerups *)
  let g = update_powerups g dt in

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
    Postprocessor.begin_render g.effects;
    
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

    (* Draw powerups *)
    Powerup.(Game_object.(
      g.state.powerups
      |> List.filter ~f:(fun pu -> not pu.obj.destroyed)
      |> List.iter ~f:(fun pu -> draw pu.obj)
    ));

    (* Draw particles *)
    Particle_generator.draw g.particle_generator;
    
    (* Draw ball *)
    Game_object.draw g.state.ball.obj;

    Postprocessor.end_render g.effects;
    Postprocessor.render g.effects (GLFW.getTime ())
      
  | _ -> ()

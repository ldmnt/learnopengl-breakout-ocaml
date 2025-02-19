open Base
open Tsdl
    
module RM = Resource_manager
module V = Util.Vec2

let abs_float = Caml.abs_float

(* Initial size of the player paddle *)
let player_size = V.{ x = 100.; y = 20.}
(* Initial velocity of the player paddle *)
let player_velocity = 500.

(* Ball characteristics *)
let initial_ball_velocity = V.{ x = 100.; y = -. 350. }
let ball_radius = 12.5


type state = Active | Menu | Win

type t = {
  state : state
; levels : Game_level.t array
; level : int (* Current level *)
; powerups : Powerup.t list
; player : Game_object.t
; ball : Ball.t
; shake_time : float
; lives : int (* Remaining lives *)
           
; particle_generator : Particle_generator.t
; effects : Postprocessor.t
; text : Text_renderer.t
           
; width : float
; height : float

; last_frame : float
}


(* Instead of GLFWgetTime. Note that GLFW uses seconds and SDL milliseconds *)
let get_time () = (Int32.to_float (Sdl.get_ticks ())) /. 1000.


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

  (* Load sounds *)
  RM.load_sound ~file:"audio/breakout.mp3" ~name:"background" `Music;
  RM.load_sound ~file:"audio/bleep.mp3" ~name:"hit_nonsolid" `Chunk;
  RM.load_sound ~file:"audio/solid.wav" ~name:"hit_solid" `Chunk;
  RM.load_sound ~file:"audio/powerup.wav" ~name:"powerup" `Chunk;
  RM.load_sound ~file:"audio/bleep.wav" ~name:"hit_player" `Chunk;

  (* Set render-specific controls *)
  let particle_generator =
    Particle_generator.make 500 (RM.get_texture "particle") (RM.get_shader "particle") in
  let effects =
    Postprocessor.make (RM.get_shader "postprocessing") (Int.of_float width) (Int.of_float height) in
  let text = Text_renderer.load ~width ~height ~file:"fonts/ocraext.ttf" ~size:24 in

  (* Load levels *)
  let levels = [|
    Game_level.load width (height *. 0.5) "levels/one.lvl";
    Game_level.load width (height *. 0.5) "levels/two.lvl";
    Game_level.load width (height *. 0.5) "levels/three.lvl";
    Game_level.load width (height *. 0.5) "levels/four.lvl";
  |] in

  (* Configure game objects *)
  let player = Game_object.make
      ~pos:(initial_player_pos width height)
      ~size:player_size
      ~sprite:(RM.get_texture "paddle")
      ~is_solid:true
      () in
  let ball =
    Ball.make ~pos:V.zero ~radius:ball_radius ~velocity:initial_ball_velocity
      ~sprite:(RM.get_texture "face") ()
    |> Ball.stick_to_player ~player in

  (* Audio *)
  RM.play_sound "background";

  {
    state = Menu;
    levels;
    level = 0;
    powerups = [];
    player;
    ball;
    shake_time = 0.;
    lives = 3;
    
    width; height;
    
    particle_generator; effects; text;

    last_frame = get_time ();
  }


let reset_level g =
  let levels = g.levels in
  let i = g.level in
  let Game_level.{ bricks } = levels.(i) in
  let bricks = List.map bricks ~f:(fun b -> { b with destroyed = false }) in
  levels.(i) <- { bricks };
  { g with lives = 3; state = Menu }

let reset_player g =
  (* Reset player/ball states *)
  let player = { g.player with pos = initial_player_pos g.width g.height } in
  let ball =
    Ball.reset g.ball ~pos:V.zero ~velocity:V.zero
    |> Ball.stick_to_player ~player in

  (* Also disable all active powerups *)
  let effects = { g.effects with confuse = false; chaos = false } in
  let ball = { ball with pass_through = false; sticky = false; obj = { ball.obj with color = (1., 1., 1.) } } in
  let player = { player with color = (1., 1., 1.) } in
  
  { g with player; ball; effects }


(* Powerups *)
let should_spawn chance =
  Random.int_incl 0 (chance - 1) = 0

let spawn_data =
  let open Powerup in
  [
    (75, Speed, (0.5, 0.5, 1.), 0., "powerup_speed");
    (75, Sticky, (1., 0.5, 1.), 20., "powerup_sticky");
    (75, PassThrough, (0.5, 1.0, 0.5), 10., "powerup_passthrough");
    (75, PadSizeIncrease, (1.0, 0.6, 0.4), 0., "powerup_increase");
    (15, Confuse, (1., 0.3, 0.3), 15., "powerup_confuse");
    (15, Chaos, (0.9, 0.25, 0.25), 15., "powerup_chaos");
  ]

let spawn_powerups pus block =
  let spawn_one (spawn_probability, typ, color, duration, txt) =
    match should_spawn spawn_probability with
    | true -> Some (Powerup.make typ color duration block.Game_object.pos (RM.get_texture txt))
    | false -> None in
  let maybe_pus = List.map spawn_data ~f:spawn_one in
  pus @ List.filter_opt maybe_pus

let activate_powerup g (pu : Powerup.t) =
  let open Powerup in
  let ball, player = g.ball, g.player in
  (* Initiate a powerup based on the type of powerup *)
  match pu.typ with
  | Speed ->
    let obj = ball.obj in
    let ball = { ball with obj = { obj with velocity = V.(1.2 $* obj.velocity) } } in
    { g with ball }
  | Sticky ->
    let ball = { ball with sticky = true } in
    let player = { player with color = (1., 0.5, 1.) } in
    { g with ball; player }
  | PassThrough ->
    let ball = { ball with pass_through = true; obj = { ball.obj with color = (1., 0.5, 0.5) } } in
    { g with ball }
  | PadSizeIncrease ->
    let player = { player with size = { player.size with x = player.size.x +. 50. } } in
    { g with player }
  | Confuse ->
    let effects = if not g.effects.chaos then
        (* Only activate if chaos wasn't already active *)
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
    ref g.powerups, ref g.ball, ref g.player, ref g.effects in

  (* Check if another powerup of the same type is still active
     in which case we don't disable its effect (yet) *)
  let is_other_powerup_active typ =
    let same_typ = List.filter !powerups ~f:(fun pu -> pu.activated && phys_equal pu.typ typ) in
    Int.(List.length same_typ > 1) in
  
  let deactivate (pu : Powerup.t) =
    if not (is_other_powerup_active pu.typ) then (* Only reset if no other PU of same type is active *)
      match pu.typ with
      | Sticky ->
        ball := { !ball with sticky = false };
        player := { !player with color = (1., 1., 1.) }
      | PassThrough ->
        ball := { !ball with pass_through = false; obj = { !ball.obj with color = (1., 1., 1.) } }
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
          if Float.(duration <= 0.) then (* Remove powerup from list (will later be removed) *)
            (deactivate pu; false)
          else pu.activated in
        duration, activated
      else
        pu.duration, pu.activated in
    { pu with obj = { pu.obj with pos}; duration; activated } in

  let not_erasable (pu : Powerup.t) = not (pu.obj.destroyed && not pu.activated) in
  
  let powerups =
    !powerups
    |> List.map ~f:update_pu
    |> List.filter ~f:not_erasable in
  
  { g with ball = !ball; player = !player; powerups; effects = !effects }
            
                                
let resolve_collision (ball : Ball.t) (brick : Game_object.t) direction (diff_vector : V.t) =  
  (* Destroy brick if not solid *)
  let destroyed = if not brick.is_solid then true else brick.destroyed in
  let brick = { brick with destroyed } in

  let ball =
    (* Dont do collision resolution on non-solid bricks if pass-through activated *)
    if not (ball.pass_through && (not brick.is_solid)) then
      let V.{ x = px; y = py }, V.{ x = vx; y = vy } = ball.obj.pos, ball.obj.velocity in
      let px, py, vx, vy =
        match direction with
        | Util.Left | Util.Right -> (* Horizontal collision *)
          let penetration = ball.radius -. abs_float diff_vector.x in
          (* Relocate *)
          let px = match direction with
            | Util.Left -> px +. penetration (* Move ball to right *)
            | Util.Right -> px -. penetration (* Move ball to left *)
            | _ -> assert false in
          px, py, -. vx, vy (* Reverse horizontal velocity *)

        | Util.Up | Util.Down -> (* Vertical collision *)
          let penetration = ball.radius -. abs_float diff_vector.y in
          (* Relocate *)
          let py = match direction with
            | Util.Up -> py -. penetration (* Move ball back up *)
            | Util.Down -> py +. penetration (* Move ball back down *)
            | _ -> assert false in
          px, py, vx, -. vy (* Reverse vertical velocity *)
      in

      let pos, velocity = V.{ x = px; y = py }, V.{ x = vx; y = vy } in
      { ball with obj = { ball.obj with pos; velocity } }
    else
      ball in
  (ball, brick)


let do_collisions g =
  (* Resolve collision between ball and blocks *)
  let g =
    let must_shake = ref false in
    let resolve_one ((ball : Ball.t), pus) (brick : Game_object.t) =
      if not brick.destroyed then
        let (collide, direction, diff_vector) = Ball.check_collision ball brick in
        if collide then begin
          if brick.is_solid then
             RM.play_sound "hit_solid" 
          else
             RM.play_sound "hit_nonsolid"; 
          let pus =
            if brick.is_solid then begin
              must_shake := true; (* If brick is solid, shake effect must be enabled *)
              pus
            end else
              spawn_powerups pus brick in
          let (ball, brick) = resolve_collision ball brick direction diff_vector in (* Collision resolution *)
          ((ball, pus), brick)
        end else
          ((ball, pus), brick)
      else
        ((ball, pus), brick) in
    let bricks = g.levels.(g.level).bricks in
    let ((ball, powerups), bricks) = List.fold_map bricks ~init:(g.ball, g.powerups) ~f:resolve_one in
    g.levels.(g.level) <- { bricks };
    let shake_time, effects = (* Enable shake effect if necessary *)
      if !must_shake then 0.05, { g.effects with shake = true }
      else g.shake_time, g.effects in
    { g with shake_time; ball; powerups; effects } in

  (* Also check collisions on powerups and if so, activate them *)
  let g =
    let update_powerup g (pu : Powerup.t) =
      let g = ref g in
      let pu =
        if not pu.obj.destroyed then
          (* First check if powerup passed bottom edge, if so: keep as inactive and destroy *)
          let pu =
            if Float.(pu.obj.pos.y >= !g.height) then
              { pu with obj = { pu.obj with destroyed = true } }
            else pu in

          if Game_object.check_collision pu.obj !g.player then begin
            (* Collided with player, now activate powerup *)
            RM.play_sound "powerup";
            g := activate_powerup !g pu;
            { pu with activated = true; obj = { pu.obj with destroyed = true } }
          end else pu
        else pu in
      (!g, pu)
    in
    let (g, powerups) = List.fold_map ~init:g ~f:update_powerup g.powerups in
    
    { g with powerups } in

  (* And finally check collisions for player pad (unless stuck) *)
  let g = 
    let player, ball = g.player, g.ball in
    let (collide, _, _) = Ball.check_collision ball player in
    let ball =
      if not ball.stuck && collide then
        (* Check where it hit the board, and change velocity based on where it hit it *)
        let board_center = player.pos.x +. player.size.x /. 2. in
        let distance = ball.obj.pos.x +. ball.radius -. board_center in
        let percentage = distance /. (player.size.x /. 2.) in
        let strength = 2. in
        let old_velocity = ball.obj.velocity in
        let velocity = V.{
            x = initial_ball_velocity.x *. percentage *. strength;
            y = -. abs_float old_velocity.y (* Fix sticky paddle *)
          } in
        let velocity = V.( (length old_velocity) $* (normalize velocity) ) in (* Keep speed consistent over both axes (multiply by length of old velocity, so total strength is not changed) *)
        let stuck = ball.sticky in (* If sticky powerup is activated, also stick ball to paddle once new velocity vectors were calculated *)
        RM.play_sound "hit_player";
        { ball with stuck; obj = { ball.obj with velocity } }
      else ball
    in
    { g with ball; player }
  in
  g


let update g ~dt =
  (* Update objects *)
  let g = { g with ball = Ball.move g.ball dt g.width } in

  (* Check for collisions *)
  let g = do_collisions g in

  (* Update particles *)
  let offset = V.{ x = g.ball.radius /. 2.; y = g.ball.radius /. 2. } in
  Particle_generator.update g.particle_generator dt g.ball.obj 2 offset;

  (* Update powerups *)
  let g = update_powerups g dt in

  (* Reduce shake time *)
  let shake_time, effects = match g.shake_time with
    | t when Float.(t > 0.) ->
      let t = t -. dt in
      let effects = if Float.(t <= 0.) then { g.effects with shake = false } else g.effects in
      t, effects
    | t -> t, g.effects in
  let g = { g with shake_time; effects } in

  (* Check loss condition *)
  let g =
    if Float.(g.ball.obj.pos.y >= g.height) then begin
      let g = { g with lives = g.lives - 1} in
      (if g.lives = 0 then reset_level g else g)
      |> reset_player
    end else g in

  (* Check win condition *)
  let g = match g.state with
    | Active ->
      if (Game_level.is_completed g.levels.(g.level)) then
        let g = g |> reset_level |> reset_player in
        { g with effects = { g.effects with chaos = true }; state = Win }
      else g
    | Menu | Win -> g in
  g


(* Pairs (a, b) of boolean where a is true iff the key is pressed and
   b is true iff the last key press was already processed. Equivalent
   to learnopengl's Keys + ProcessedKeys *)
let keys = ref (Map.empty (module Int)) 

let update_key k v =
  keys := Map.set !keys ~key:k ~data:v

let update_processed k =
  match Map.find !keys k with
  | Some (a, _) -> keys := Map.set !keys ~key:k ~data:(a, true)
  | None -> ()

let get_key k =
  match Map.find !keys k with
  | Some (pressed, _) -> pressed
  | None -> false

let was_processed k =
  match Map.find !keys k with
  | Some (_, processed) -> processed
  | None -> true

let process_input g ~dt =
  match g.state with      
  | Menu ->
    let g =
      if get_key Sdl.Scancode.return && not (was_processed Sdl.Scancode.return) then begin
        update_processed Sdl.Scancode.return;
        { g with state = Active }
      end else g in
    let level = g.level in
    let level = if get_key Sdl.Scancode.w && not (was_processed Sdl.Scancode.w) then begin
        update_processed Sdl.Scancode.w;
        (level + 1) % 4
      end else level in
    let level = if get_key Sdl.Scancode.s && not (was_processed Sdl.Scancode.s) then begin
        update_processed Sdl.Scancode.s;
        (level + 3) % 4
      end else level in
    { g with level }

  | Win ->
    if get_key Sdl.Scancode.return && not (was_processed Sdl.Scancode.return) then begin
      update_processed Sdl.Scancode.return;
      { g with state = Menu; effects = { g.effects with chaos = false } }
    end else g

  | Active ->
    (* Move playerboard *)
    let player = g.player in
    let velocity = player_velocity *. dt in
    let new_x = match get_key Sdl.Scancode.a, get_key Sdl.Scancode.d, player.pos.x with
      | true, false, x when Float.(x >= 0.) ->
        x -. velocity
      | false, true, x when Float.(x <= g.width -. player.size.x) ->
        x +. velocity
      | _, _, x -> x in
    let player = { player with pos = { player.pos with x = new_x } } in

    (* Update ball position *)
    let ball = g.ball in
    let ball = if ball.stuck then Ball.stick_to_player ~player ball else ball in
    let ball =
      if get_key Sdl.Scancode.space then
        let obj = { ball.obj with velocity = initial_ball_velocity } in
        { ball with stuck = false; obj}
      else ball in

    { g with player; ball }


let render g =
  (* Begin rendering to postprocessing quad *)
  Postprocessor.begin_render g.effects;

  (* Draw background *)
  Sprite.draw
    (RM.get_texture "background")
    { x = 0.; y = 0. }
    { x = g.width; y = g.height };

  (* Draw level *)
  let current_level = g.level in
  Game_level.draw g.levels.(current_level);

  (* Draw player *)
  Game_object.draw g.player;

  (* Draw powerups *)
  Powerup.(Game_object.(
      g.powerups
      |> List.filter ~f:(fun pu -> not pu.obj.destroyed)
      |> List.iter ~f:(fun pu -> draw pu.obj)
    ));

  (* Draw particles *)
  Particle_generator.draw g.particle_generator;

  (* Draw ball *)
  Game_object.draw g.ball.obj;

  (* End rendering to postprocessing quad *)
  Postprocessor.end_render g.effects;

  (* Render postprocessing quad *)
  Postprocessor.render g.effects (get_time ());

  (* Render text (don't include in postprocessing) *)
  Text_renderer.render_text g.text (Printf.sprintf "Lives:%d" g.lives)
    ~x:5. ~y:5. ~scaling:1.;

  match g.state with
  | Menu ->
    Text_renderer.render_text g.text "Press ENTER to start"
      ~x:250. ~y:(g.height /. 2.) ~scaling:1.;
    Text_renderer.render_text g.text "Press W or S to select level"
      ~x:245. ~y:(g.height /. 2. +. 20.) ~scaling:0.75

  | Win ->
    Text_renderer.render_text g.text "You WON!!!"
      ~x:320. ~y:(g.height /. 2. -. 20.) ~scaling:1. ~color:(0., 1., 0.);
    Text_renderer.render_text g.text "Press ENTER to retry or ESC to quit"
      ~x:130. ~y:(g.height /. 2.) ~scaling:1. ~color:(1., 1., 0.)

  | Active -> ()

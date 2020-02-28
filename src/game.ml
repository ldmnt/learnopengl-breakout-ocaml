open Base
    
module RM = Resource_manager
module V = Util.Vec2

let player_size = V.{ x = 100.; y = 20.}
let player_velocity = 500.

type state = {
  last_frame : float
; level : int
; player : Game_object.t
}

type mode = Active | Menu | Win

type t = {
  mode : mode
; state : state
; levels : Game_level.t Array.t
; width : float
; height : float
}


let keys : (GLFW.key, bool) Map.Poly.t ref = ref Map.Poly.empty

let update_key k v =
  keys := Map.Poly.set !keys ~key:k ~data:v

let get_key k =
  Map.Poly.find !keys k
  |> Option.value ~default:false

let init width height =
  (* Load shaders *)
  RM.load_shader
    ~vertex:"shaders/sprite.vs"
    ~fragment:"shaders/sprite.frag"
    "sprite";
  
  (* Configure shaders *)
  let projection = Util.Mat.orthographic_projection 0. width height 0. (-.1.) 1. in
  let s = RM.get_shader "sprite" in
  Shader.set_integer s "image" 0 ~use_shader:true;
  Shader.set_matrix4 s "projection" projection;
  Sprite.init s;

  (* Load textures *)
  RM.load_texture ~file:"textures/background.jpg" ~alpha:false ~name:"background";
  RM.load_texture ~file:"textures/awesomeface.png" ~alpha:true ~name:"face";
  RM.load_texture ~file:"textures/block.png" ~alpha:false ~name:"block";
  RM.load_texture ~file:"textures/block_solid.png" ~alpha:false ~name:"block_solid";
  RM.load_texture ~file:"textures/paddle.png" ~alpha:true ~name:"paddle";

  (* Initialize paddle *)
  let player_pos = V.{
    x = Float.(width / 2. - player_size.x / 2.);
    y = Float.(height - player_size.y)
  } in
  
  let player = Game_object.make
      ~pos:player_pos
      ~size:player_size
      ~sprite:(RM.get_texture "paddle")
      ~is_solid:true
      () in

  (* Initial state *)
  let state0 = {
    level = 0;
    last_frame = GLFW.getTime ();
    player
  } in

  (* Load levels *)
  let levels = [|
    Game_level.load width (height *. 0.5) "levels/one.lvl";
    Game_level.load width (height *. 0.5) "levels/two.lvl";
    Game_level.load width (height *. 0.5) "levels/three.lvl";
    Game_level.load width (height *. 0.5) "levels/four.lvl";
  |] in
  
  { mode = Active; state = state0; levels; width; height }


let update g ~dt = ignore dt; g


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
    
    { g with state = { g.state with player } }
    
  | _ -> g


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
    Game_object.draw g.state.player
  | _ -> ()

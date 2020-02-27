open Base
    
module RM = Resource_manager

module State = struct
  type t = {
    last_frame : float
  }
end

type t =
    Active of State.t
  | Menu
  | Win


let init () =
  (* Load shaders *)
  RM.load_shader
    ~vertex:"shaders/sprite.vs"
    ~fragment:"shaders/sprite.frag"
    "sprite";
  
  (* Configure shaders *)
  let projection = Util.Mat.orthographic_projection 0. 800. 600. 0. (-.1.) 1. in
  let s = RM.get_shader "sprite" in
  Shader.set_integer s "image" 0 ~use_shader:true;
  Shader.set_matrix4 s "projection" projection;

  Sprite.init s;

  RM.load_texture ~file:"textures/awesomeface.png" ~alpha:true ~name:"face";
    
  Active { last_frame = GLFW.getTime () }


let update g ~dt = ignore dt; g


let process_input g ~dt = ignore dt; g


let render _ =
  Sprite.draw
    (RM.get_texture "face")
    [| 200.; 200. |]
    [| 300.; 400. |]
    45.
    [| 1.; 1.; 1. |]


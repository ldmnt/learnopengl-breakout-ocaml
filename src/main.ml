open Base
open Tgl3

let screen_width = 800
let screen_height = 600

let key_callback win key _ a _ =
  match (key, a) with
  | (GLFW.Escape, GLFW.Press) -> GLFW.setWindowShouldClose ~window:win ~b:true
  | (k, GLFW.Press) -> Game.update_key k true
  | (k, GLFW.Release) -> Game.update_key k false
  | _ -> ()
      
let main () =
  GLFW.init ();
  GLFW.windowHint ~hint:ContextVersionMajor ~value:3;
  GLFW.windowHint ~hint:ContextVersionMinor ~value:3;
  GLFW.windowHint ~hint:OpenGLProfile ~value:GLFW.CoreProfile;
  GLFW.windowHint ~hint:Resizable ~value:false;

  let window = GLFW.createWindow ~width:screen_width ~height:screen_height ~title:"Breakout" () in
  GLFW.makeContextCurrent ~window:(Some window);

  ignore (GLFW.setKeyCallback ~window ~f:(Some key_callback));

  Gl.viewport 0 0 screen_width screen_height;
  Gl.enable Gl.cull_face_enum;
  Gl.enable Gl.blend;
  Gl.blend_func Gl.src_alpha Gl.one_minus_src_alpha;
  
  let rec main_loop g =
    match GLFW.windowShouldClose ~window with
    | true -> ()
    | false ->
      let current_frame = GLFW.getTime () in
      let g = match g.Game.mode with
        | Game.Active ->
          GLFW.pollEvents ();
          let dt = Float.(current_frame - g.Game.state.last_frame) in
          let g =
            g
            |> Game.process_input ~dt
            |> Game.update ~dt in

          Gl.clear_color 0. 0. 0. 1.;
          Gl.clear Gl.color_buffer_bit;
          Game.render g;

          GLFW.swapBuffers ~window;
          g
          
        | Game.Menu -> g
        | Game.Win -> g
      in
      main_loop Game.{ g with state = { g.state with last_frame = current_frame } }
  in

  let (width, height) = Float.(of_int screen_width, of_int screen_height) in
  main_loop (Game.init width height);
  GLFW.terminate ()

let () = main ()

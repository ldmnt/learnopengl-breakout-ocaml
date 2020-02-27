open Base
open Tgl3

let screen_width = 800
let screen_height = 600

let key_callback win key _ a _ =
  match (key, a) with
  | (GLFW.Escape, GLFW.Press) -> GLFW.setWindowShouldClose ~window:win ~b:true
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
      match g with
      | Game.Active s ->
        let current_frame = GLFW.getTime () in
        let dt = Float.(current_frame - s.last_frame) in
        GLFW.pollEvents ();

        let g =
          g
          |> Game.process_input ~dt
          |> Game.update ~dt in

        Gl.clear_color 0. 0. 0. 1.;
        Gl.clear Gl.color_buffer_bit;
        Game.render g;

        GLFW.swapBuffers ~window;
        main_loop g
      | Game.Menu -> main_loop g
      | Game.Win -> main_loop g in

  main_loop (Game.init ());
  GLFW.terminate ()

let () = main ()

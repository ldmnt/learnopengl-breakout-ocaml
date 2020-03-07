open Base
open Tgl3
open Tsdl

let screen_width = 800
let screen_height = 600


(* SDL equivalent of GLFW's key callback and windowShouldClose *)
let rec process_events e =
  if Sdl.poll_event (Some e) then
    let open Sdl.Event in
    let action = enum (get e typ) in
    match action with
    | `Quit -> `Quit
    | `Key_down | `Key_up ->
      let key = get e keyboard_scancode in
      if key = Sdl.Scancode.escape then `Quit
      else
        let new_state = match action with
          | `Key_down -> true
          | `Key_up -> false
          | _ -> assert false in
        Game.update_key key new_state;
        process_events e
    | _ -> process_events e
  else
    `Continue
      
let main () =
  let window, context =
    let maybe_error =
      (* Initialize SDL window and GL context *)
      let ( >>= ) = Result.(>>=) in
      let set = Sdl.gl_set_attribute in
      Sdl.init Sdl.Init.video >>= fun () ->
      set Sdl.Gl.context_profile_mask Sdl.Gl.context_profile_core >>= fun () ->
      set Sdl.Gl.context_major_version 3 >>= fun () ->
      set Sdl.Gl.context_minor_version 3 >>= fun () ->
      set Sdl.Gl.doublebuffer 1 >>= fun () ->
      Sdl.create_window ~w:screen_width ~h:screen_height "Breakout" Sdl.Window.opengl >>= fun window ->
      Sdl.gl_create_context window >>= fun context ->
      Sdl.gl_make_current window context >>= fun () ->
      Ok (window, context)
    in
    match maybe_error with
    | Ok wc -> wc
    | Error (`Msg s) -> failwith s
  in
  
  let event = Sdl.Event.create () in

  Gl.viewport 0 0 screen_width screen_height;
  Gl.enable Gl.cull_face_enum;
  Gl.enable Gl.blend;
  Gl.blend_func Gl.src_alpha Gl.one_minus_src_alpha;

  let rec main_loop g =
    match process_events event with
    | `Continue ->
      let current_frame = Game.get_time () in
      let g = match g.Game.mode with
        | Game.Active ->
          let dt = Float.(current_frame - g.Game.state.last_frame) in
          let g =
            g
            |> Game.process_input ~dt
            |> Game.update ~dt in

          Gl.clear_color 0. 0. 0. 1.;
          Gl.clear Gl.color_buffer_bit;
          Game.render g;

          Sdl.gl_swap_window window;
          g

        | Game.Menu -> g
        | Game.Win -> g
      in
      main_loop Game.{ g with state = { g.state with last_frame = current_frame } }

    | `Quit -> ()
  in

  let (width, height) = Float.(of_int screen_width, of_int screen_height) in
  main_loop (Game.init width height);

  (* Cleanup *)
  Sdl.gl_delete_context context;
  Sdl.destroy_window window

let () = main ()

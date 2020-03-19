open Base
open Tgl3
open Stb_truetype

module RM = Resource_manager

type character = {
  texture : int
; size : int * int
; bearing : int * int
; advance : int
}

type t = {
  characters : (char, character, Char.comparator_witness) Map.t
; space_advance : float (* Treat space character separately because it has no associated bitmap in stb_truetype *)
; shader : Shader.t
; vao : int
; vbo : int
}

let load ~width ~height ~file:font_file ~size:font_size =  
  (* Load and configure shader *)
  RM.load_shader ~vertex:"shaders/text.vs" ~fragment:"shaders/text.frag" "text";
  let shader = RM.get_shader "text" in
  Shader.set_matrix4 shader "projection" ~use_shader:true
    (Util.Mat.orthographic_projection 0. width height 0. (-.1.) 1.);
  Shader.set_integer shader "text" 0;

  (* Configure VAO/VBO for texture quads *)
  let float_size = Bigarray.(kind_size_in_bytes float32) in
  let vao = Util.get_int (Gl.gen_vertex_arrays 1) in
  let vbo = Util.get_int (Gl.gen_buffers 1) in
  Gl.bind_vertex_array vao;
  Gl.bind_buffer Gl.array_buffer vbo;
  Gl.buffer_data Gl.array_buffer (4 * 6 * float_size) None Gl.dynamic_draw;
  Gl.enable_vertex_attrib_array 0;
  Gl.vertex_attrib_pointer 0 4 Gl.float false (4 * float_size) (`Offset 0);
  Gl.bind_buffer Gl.array_buffer 0;
  Gl.bind_vertex_array 0;

  (* Load font *)
  let font = Stbtt.allocate_fontinfo () in
  let font_data = Stdio.In_channel.read_all font_file in
  Stbtt.init_font font font_data 0;

  (* Compute scale factor and space advance *)
  let scale = Stbtt.scale_for_pixel_height font (Float.of_int font_size) in
  Gl.pixel_storei Gl.unpack_alignment 1;

  let (advance, _) = Stbtt.get_codepoint_h_metrics font 32 in
  let space_advance = scale *. Float.of_int advance in
  
  let load_char c =
    (* Load character glyph *)
    match Stbtt.get_codepoint_bitmap font scale scale c with
    | None -> None
    | Some (bitmap, c_width, c_rows, bearing_x, bearing_y) ->
      (* Generate texture *)
      let txt = Util.get_int (Gl.gen_textures 1) in
      Gl.bind_texture Gl.texture_2d txt;
      Gl.tex_image2d Gl.texture_2d 0 Gl.red c_width c_rows 0 Gl.red Gl.unsigned_byte (`Data bitmap);

      (* Set texture options *)
      Gl.tex_parameteri Gl.texture_2d Gl.texture_wrap_s Gl.clamp_to_edge;
      Gl.tex_parameteri Gl.texture_2d Gl.texture_wrap_t Gl.clamp_to_edge;
      Gl.tex_parameteri Gl.texture_2d Gl.texture_min_filter Gl.linear;
      Gl.tex_parameteri Gl.texture_2d Gl.texture_mag_filter Gl.linear;
      
      (* Free bitmap data *)
      Stbtt.free_bitmap bitmap;
      
      (* Retrieve advance value *)   
      let (advance, _) = Stbtt.get_codepoint_h_metrics font c in

      let char = {
        texture = txt;
        size = (c_width, c_rows);
        bearing = (bearing_x, bearing_y);
        advance = Int.of_float (scale *. Float.of_int advance)
      } in
      Some (Char.of_int_exn c, char)
  in

  (* Store all characters into a map for later use *)
  let characters =
    List.init 128 ~f:load_char
    |> List.filter_opt
    |> Map.of_alist_exn (module Char) in

  Gl.bind_texture Gl.texture_2d 0;
  
  { characters; shader; vao; vbo; space_advance }


let render_text t ~x ~y ?(color=(1., 1., 1.)) ~scaling text =
  (* Activate corresponding render state *)
  Shader.use t.shader;
  Shader.set_vector3f t.shader "textColor" color;
  Gl.active_texture Gl.texture0;
  Gl.bind_vertex_array t.vao;

  (* Iterate through all characters *)
  let h = Map.find_exn t.characters (Char.of_string "H") in
  let (_, h_bearing_y) = h.bearing in
    
  let draw_one x c =
    match Char.to_int c with
    | 32 -> (* space *)
      Float.(x + scaling * t.space_advance)
    | _ ->
      let ch = Map.find_exn t.characters c in

      let bearing_x, bearing_y = ch.bearing in (* In stb_truetype, the bearing is already scaled and has negative y. *)
      let xpos = Float.(x + of_int bearing_x) in
      let ypos = Float.(y - (of_int h_bearing_y - of_int bearing_y) * scaling) in

      let size_x, size_y = ch.size in
      let w = Float.(scaling * of_int size_x) in
      let h = Float.(scaling * of_int size_y) in
      (* Update VBO for each character *)
      let vertices = Util.float_bigarray [|
          xpos     ; ypos +. h; 0.; 1.;
          xpos +. w; ypos     ; 1.; 0.;
          xpos     ; ypos     ; 0.; 0.;

          xpos     ; ypos +. h; 0.; 1.;
          xpos +. w; ypos +. h; 1.; 1.;
          xpos +. w; ypos     ; 1.; 0.
        |] in
      (* Render glyph texture over quad *)
      Gl.bind_texture Gl.texture_2d ch.texture;
      (* Update content of VBO memory *)
      Gl.bind_buffer Gl.array_buffer t.vbo;
      Gl.buffer_sub_data Gl.array_buffer 0 (4 * 6 * Bigarray.(kind_size_in_bytes float32)) (Some vertices); (* Be sure to use glBufferSubData and not glBufferData *)

      Gl.bind_buffer Gl.array_buffer 0;
      (* Render quad *)
      Gl.draw_arrays Gl.triangles 0 6;
      (* Return advanced cursor for next glyph *)
      Float.(x + scaling * of_int ch.advance)
  in
  
  let _ =
    text
    |> String.to_list
    |> List.fold ~init:x ~f:draw_one in

  Gl.bind_vertex_array 0;
  Gl.bind_texture Gl.texture_2d 0

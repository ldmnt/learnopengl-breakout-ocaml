open Base
open Tgl3

type t = {
  msfbo : int
; fbo : int
; rbo : int
; vao : int
; shader : Shader.t
; texture : Texture.t
; width : int
; height : int
; confuse : bool
; chaos : bool
; shake : bool
}


let init_render_data () =
  let vertices = Util.float_bigarray [|
      -.1.; -.1.; 0.; 0.;
        1.;   1.; 1.; 1.;
      -.1.;   1.; 0.; 1.;

      -.1.; -.1.; 0.; 0.;
        1.; -.1.; 1.; 0.;
        1.;   1.; 1.; 1.
    |] in

  let vao = Util.get_int (Gl.gen_vertex_arrays 1) in
  let vbo = Util.get_int (Gl.gen_buffers 1) in

  Gl.bind_buffer Gl.array_buffer vbo;
  Gl.buffer_data Gl.array_buffer (Bigarray.Array1.size_in_bytes vertices) (Some vertices) Gl.static_draw;

  Gl.bind_vertex_array vao;
  Gl.enable_vertex_attrib_array 0;
  Gl.vertex_attrib_pointer 0 4 Gl.float false (4 * Bigarray.(kind_size_in_bytes float32)) (`Offset 0);
  Gl.bind_buffer Gl.array_buffer 0;
  Gl.bind_vertex_array 0;
  vao

let make shader width height =
  (* Initialize renderbuffer/framebuffer objects *)
  let msfbo = Util.get_int (Gl.gen_framebuffers 1) in
  let fbo = Util.get_int (Gl.gen_framebuffers 1) in
  let rbo = Util.get_int (Gl.gen_renderbuffers 1) in

  (* Initialize renderbuffer storage with a multisampled color buffer (don't need a depth/stencil buffer) *)
  Gl.bind_framebuffer Gl.framebuffer msfbo;
  Gl.bind_renderbuffer Gl.renderbuffer rbo;
  Gl.renderbuffer_storage_multisample Gl.renderbuffer 1 Gl.rgb width height; (* Allocate storage for render buffer object *)
  Gl.framebuffer_renderbuffer Gl.framebuffer Gl.color_attachment0 Gl.renderbuffer rbo;
  if Gl.check_framebuffer_status Gl.framebuffer <> Gl.framebuffer_complete then
    failwith "ERROR::POSTPROCESSOR: Failed to initialize MSFBO\n";
   
  (* Also initialize the fbo/texture to blit multisampled color-buffer to; used for shader operations (for postprocessing effects) *)
  Gl.bind_framebuffer Gl.framebuffer fbo;
  let texture = Texture.generate ~width ~height (`Offset 0) in
  Gl.framebuffer_texture2d Gl.framebuffer Gl.color_attachment0 Gl.texture_2d (Texture.id texture) 0;
  if Gl.check_framebuffer_status Gl.framebuffer <> Gl.framebuffer_complete then
    failwith "ERROR::POSTPROCESSOR: Failed to initialize FBO\n";
  Gl.bind_framebuffer Gl.framebuffer 0;

  (* Initialize render data and uniforms *)
  let vao = init_render_data () in
  Shader.set_integer shader "scene" 0 ~use_shader:true;
  let offset = 1. /. 300. in
  let offsets = Util.float_bigarray [|
      -. offset;    offset;
      0.       ;    offset;
      offset   ;    offset;
      -. offset;        0.;
      0.       ;        0.;
      offset   ;        0.;
      -. offset; -. offset;
      0.       ; -. offset;
      offset   ; -. offset
    |] in
  let sid = Shader.id shader in
  Gl.uniform2fv (Gl.get_uniform_location sid "offsets") 9 offsets;
  let edge_kernel = Util.int_bigarray [|
      -1l; -1l; -1l;
      -1l;  8l; -1l;
      -1l; -1l; -1l
    |] in
  Gl.uniform1iv (Gl.get_uniform_location sid "edge_kernel") 9 edge_kernel;
  let blur_kernel = Util.float_bigarray [|
      1. /. 16.; 2. /. 16.; 1. /. 16.;
      2. /. 16.; 4. /. 16.; 2. /. 16.;
      1. /. 16.; 2. /. 16.; 1. /. 16.
    |] in
  Gl.uniform1fv (Gl.get_uniform_location sid "blur_kernel") 9 blur_kernel;

  { msfbo; fbo; rbo; vao; shader; texture; width; height; confuse = false; chaos = false; shake = false }


let begin_render t =
  Gl.bind_framebuffer Gl.framebuffer t.msfbo;
  Gl.clear_color 0. 0. 0. 1.;
  Gl.clear Gl.color_buffer_bit


let end_render t =
  (* Now resolve multisampled color-buffer into intermediate FBO to store to texture *)
  Gl.bind_framebuffer Gl.read_framebuffer t.msfbo;
  Gl.bind_framebuffer Gl.draw_framebuffer t.fbo;
  Gl.blit_framebuffer 0 0 t.width t.height 0 0 t.width t.height Gl.color_buffer_bit Gl.nearest;
  Gl.bind_framebuffer Gl.framebuffer 0


let render t time =
  let to_int = function | true -> 1 | false -> 0 in
  
  (* Set uniforms/options *)
  Shader.use t.shader;
  Shader.set_float t.shader "time" time;
  Shader.set_integer t.shader "confuse" (to_int t.confuse);
  Shader.set_integer t.shader "chaos" (to_int t.chaos);
  Shader.set_integer t.shader "shake" (to_int t.shake);

  (* Render texture quad *)
  Gl.active_texture Gl.texture0;
  Texture.bind t.texture;
  Gl.bind_vertex_array t.vao;
  Gl.draw_arrays Gl.triangles 0 6;
  Gl.bind_vertex_array 0

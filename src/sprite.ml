open Base
open Tgl3

module Mat = Util.Mat
module Vec = Util.Vec2

let vao_ = ref 0
let shader_ = ref None

let init s =
  let vertices = Util.float_bigarray
      [|
        0.; 1.; 0.; 1.;
        1.; 0.; 1.; 0.;
        0.; 0.; 0.; 0.;

        0.; 1.; 0.; 1.;
        1.; 1.; 1.; 1.;
        1.; 0.; 1.; 0.;
      |] in

  let vao = Util.get_int (Gl.gen_vertex_arrays 1) in
  let vbo = Util.get_int (Gl.gen_buffers 1) in

  Gl.bind_buffer Gl.array_buffer vbo;
  Gl.buffer_data Gl.array_buffer (Bigarray.Array1.size_in_bytes vertices) (Some vertices) Gl.static_draw;

  Gl.bind_vertex_array vao;
  Gl.enable_vertex_attrib_array 0;
  Gl.vertex_attrib_pointer 0 4 Gl.float false
    (4 * Bigarray.(kind_size_in_bytes float32))
    (`Offset 0);
  Gl.bind_buffer Gl.array_buffer 0;
  Gl.bind_vertex_array 0;
  shader_ := Some s;
  vao_ := vao

let draw txt pos
    ?(color = [|1.;1.;1.|])
    ?(rotate = 0.)
    size =
  let shader = Option.value_exn !shader_ in
  Shader.use shader;

  let radians = Float.(2. * pi * rotate / 360.) in

  let model =
    let open Mat in
    let open Vec in
    identity ()
    ** (translation [| pos.x; pos.y; 0. |])
    ** (translation Float.([| 0.5 * size.x; 0.5 * size.y; 0.|]))
    ** (rotation_around_z radians)
    ** (translation Float.([| -0.5 * size.x; -0.5 * size.y; 0. |]))
    ** (scaling size.x size.y) in
  
  Shader.set_matrix4 shader "model" model;
  Shader.set_vector3f shader "spriteColor" color;

  Gl.active_texture Gl.texture0;
  Texture.bind txt;

  Gl.bind_vertex_array !vao_;
  Gl.draw_arrays Gl.triangles 0 6;
  Gl.bind_vertex_array 0

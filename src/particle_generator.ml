open Base
open Tgl3

module V = Util.Vec2

type particle = {
  mutable pos : V.t
; mutable velocity : V.t
; mutable color : float array
; mutable life : float
}

type t = {
  particles : particle array
; mutable last_used_particle : int (* Stores the index of the last particle used (for quick access to next dead particle *)
; vao : int
; shader : Shader.t
; texture : Texture.t
}


let make_particle () = { pos = V.zero; velocity = V.zero; color = [|1.; 1.; 1.; 1.|]; life = 0. }


let make amount texture shader =
  (* Set up mesh and attribute properties *)
  let particle_quad = Util.float_bigarray [|
    0.; 1.; 0.; 1.;
    1.; 0.; 1.; 0.;
    0.; 0.; 0.; 0.;

    0.; 1.; 0.; 1.;
    1.; 1.; 1.; 1.;
    1.; 0.; 1.; 0.
  |] in
  let vao = Util.get_int (Gl.gen_vertex_arrays 1) in
  let vbo = Util.get_int (Gl.gen_buffers 1) in
  Gl.bind_vertex_array vao;

  (* Fill mesh buffer *)
  Gl.bind_buffer Gl.array_buffer vbo;
  Gl.buffer_data Gl.array_buffer (Bigarray.Array1.size_in_bytes particle_quad) (Some particle_quad) Gl.static_draw;

  (* Set mesh attributes *)
  Gl.enable_vertex_attrib_array 0;
  Gl.vertex_attrib_pointer 0 4 Gl.float false
    (4 * Bigarray.(kind_size_in_bytes float32))
    (`Offset 0);
  Gl.bind_vertex_array 0;

  { particles = Array.init amount ~f:(fun _ -> make_particle ()); (* Create `amount` default particles *)
    last_used_particle = 0;
    vao; texture; shader }


let respawn_particle p (obj : Game_object.t) offset =
  let random = Random.float_range (-. 5.) 5. in
  let r_color = 0.5 +. Random.float_range 0. 1. in
  p.pos <- V.(obj.pos + { x = random; y = random } + offset);
  p.color <- [|r_color; r_color; r_color; 1.|];
  p.life <- 1.;
  p.velocity <- V.(0.1 $* obj.velocity)


let draw t =
  Gl.blend_func Gl.src_alpha Gl.one;
  Shader.use t.shader;
  for i = 0 to Array.length t.particles - 1 do
    let p = t.particles.(i) in
    if Float.(p.life > 0.) then begin
      Shader.set_vector2f t.shader "offset" (p.pos.x, p.pos.y);
      let c = p.color in
      Shader.set_vector4f t.shader "color" (c.(0), c.(1), c.(2), c.(3));
      Texture.bind t.texture;
      Gl.bind_vertex_array t.vao;
      Gl.draw_arrays Gl.triangles 0 6;
      Gl.bind_vertex_array 0
    end
  done;
  Gl.blend_func Gl.src_alpha Gl.one_minus_src_alpha


let first_unused_particle t =
  let return i = t.last_used_particle <- i; i in
  let rec loop until = function
    | i when i < until ->
      if Float.(t.particles.(i).life <= 0.) then Some i else
        loop until (i + 1)
    | _ -> None in

  (* First search from last used particle, this will usually return almost instantly *)
  match loop (Array.length t.particles) t.last_used_particle with
  | Some i -> return i
  | None ->
    (* Otherwise, do a linear search *)
    match loop t.last_used_particle 0 with
    | Some i -> return i
    | None -> return 0 (* All particles are taken, override the first one (note that if it repeatedly hits this case, more particles should be reserved *)


let update t dt (obj : Game_object.t) n_new offset =
  (* Add new particles *)
  let spawn_one () =
    let i = first_unused_particle t in
    respawn_particle t.particles.(i) obj offset in
  Fn.apply_n_times ~n:n_new spawn_one ();

  (* Update all particles *)
  let update_particle p =
    p.life <- p.life -. dt; (* Reduce life *)
    if Float.(p.life > 0.) then begin
      (* Particle is alive, thus update *)
      p.pos <- V.(p.pos - (dt $* p.velocity));
      p.color.(3) <- p.color.(3) -. dt *. 2.5
    end in
  Array.iter ~f:update_particle t.particles 

open Tgl3
open Base

type t = int
  
type typ = Vertex | Fragment | Geometry

let use = Gl.use_program

let gl_type = function
  | Vertex -> Gl.vertex_shader
  | Fragment -> Gl.fragment_shader
  | Geometry -> Gl.geometry_shader

let string_of_typ = function
  | Vertex -> "VERTEX"
  | Fragment -> "FRAGMENT"
  | Geometry -> "GEOMETRY"

let check_compile_file_errors id typ =
  let success = Util.get_int (Gl.get_shaderiv id Gl.compile_status) = Gl.true_ in
  if success then () else
    let len = Util.get_int (Gl.get_shaderiv id Gl.info_log_length) in
    let log = Util.get_string len (Gl.get_shader_info_log id len None) in
    failwith (
      "| ERROR::SHADER: Compile-time error: Type: " ^ (string_of_typ typ) ^ "\n"
      ^ log ^ "\n -- ------------------------------------------ -- \n"
    )

let check_compile_program_errors id =
  let success = Util.get_int(Gl.get_programiv id Gl.link_status) = Gl.true_ in
  if success then () else
    let len = Util.get_int (Gl.get_programiv id Gl.info_log_length) in
    let log = Util.get_string len (Gl.get_program_info_log id len None) in
    failwith (
      "| ERROR::SHADER: Link-time error:\n"
      ^ log ^ "\n -- ------------------------------------------ -- \n"
    )

let compile_file source typ =
  let id = Gl.create_shader (gl_type typ) in
  Gl.shader_source id source;
  Gl.compile_shader id;
  check_compile_file_errors id typ;
  id

let compile ~vertex ~fragment ~geometry =
  (* Vertex shader *)
  let vsid = compile_file vertex Vertex in
  (* Fragment shader *)
  let fsid = compile_file fragment Fragment in
  (* If geometry shader source code is given, also compile geometry shader *)
  let gsid = Option.map geometry ~f:(fun s -> compile_file s Geometry) in
  (* Shader program *)
  let pid = Gl.create_program () in
  Gl.attach_shader pid vsid;
  Gl.attach_shader pid fsid;
  Option.map gsid ~f:(Gl.attach_shader pid) |> Caml.ignore;
  Gl.link_program pid;
  check_compile_program_errors pid;
  (* Delete the shaders as they're linked into our program now and no longer necessary *)
  Gl.delete_shader vsid;
  Gl.delete_shader fsid;
  Option.map gsid ~f:Gl.delete_shader |> Caml.ignore;
  pid

let delete = Gl.delete_program

let set_vector2f s name ?(use_shader=false) (x, y) =
  if use_shader then use s;
  Gl.uniform2f (Gl.get_uniform_location s name) x y

let set_vector3f s name ?(use_shader=false) (x, y, z) =
  if use_shader then use s;
  Gl.uniform3f (Gl.get_uniform_location s name) x y z

let set_vector4f s name ?(use_shader=false) (x, y, z, w) =
  if use_shader then use s;
  Gl.uniform4f (Gl.get_uniform_location s name) x y z w

let set_integer s name ?(use_shader=false) v =
  if use_shader then use s;
  Gl.uniform1i (Gl.get_uniform_location s name) v

let set_float s name ?(use_shader=false) v =
  if use_shader then use s;
  Gl.uniform1f (Gl.get_uniform_location s name) v

let set_matrix4 s name ?(use_shader=false) mat =
  if use_shader then use s;
  Gl.uniform_matrix4fv (Gl.get_uniform_location s name) 1 true (Util.Mat.to_bigarray mat)

let id s = s

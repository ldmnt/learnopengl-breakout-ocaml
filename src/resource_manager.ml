open Base
open Stdio
open Tgl3

let shaders = ref (Map.empty (module String))
let textures = ref (Map.empty (module String))

let load_shader ~vertex ~fragment ?geometry name =
  let vertex = In_channel.read_all vertex in
  let fragment = In_channel.read_all fragment in
  let geometry = Option.map ~f:In_channel.read_all geometry in
  let s = Shader.compile ~vertex ~fragment ~geometry in
  shaders := Map.set !shaders ~key:name ~data:s

let get_shader name = Map.find_exn !shaders name

let load_texture ~file ~alpha ~name =
  let (data, width, height, _) = Stb_image.stbi_load file in
  let txt = if alpha
    then Texture.generate (`Data data) ~width ~height ~internal_format:Gl.rgba ~image_format:Gl.rgba
    else Texture.generate (`Data data) ~width ~height in
  Stb_image.stbi_image_free data;
  textures := Map.set !textures ~key:name ~data:txt

let get_texture name = Map.find_exn !textures name

let clear () =
  Map.iter !shaders ~f:Shader.delete;
  Map.iter !textures ~f:Texture.delete

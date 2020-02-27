open Base
open Stdio
open Tgl3

type t = {
  shaders : (String.t, Shader.t, String.comparator_witness) Map.t
; textures : (String.t, Texture.t, String.comparator_witness) Map.t
}

let make () =
  {
    shaders = Map.empty (module String)
  ; textures = Map.empty (module String)
  }

let load_shader t ~vertex ~fragment ?geometry ~name =
  let vertex = In_channel.read_all vertex in
  let fragment = In_channel.read_all fragment in
  let geometry = Option.map ~f:In_channel.read_all geometry in
  let s = Shader.compile ~vertex ~fragment ~geometry in
  (s, { t with shaders = Map.set t.shaders ~key:name ~data:s })

let get_shader = Map.find_exn

let load_texture t ~file ~alpha ~name =
  let (data, width, height, _) = Stb_image.stbi_load file in
  let txt = if alpha
    then Texture.generate data ~width ~height ~internal_format:Gl.rgba ~image_format:Gl.rgba
    else Texture.generate data ~width ~height in
  Stb_image.stbi_image_free data;
  (txt, { t with textures = Map.set t.textures ~key:name ~data:txt })

let get_texture = Map.find_exn

let clear t =
  Map.iter t.shaders ~f:Shader.delete;
  Map.iter t.textures ~f:Texture.delete

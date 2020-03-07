open Base
open Stdio
open Tgl3
open Tsdl
open Sdl_mixer

let shaders = ref (Map.empty (module String))
let textures = ref (Map.empty (module String))
let sounds = ref (Map.empty (module String))

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

let load_sound ~file ~name mode =
  let open Sound in
  let snd = match mode with
    | `Music -> Music (Mix.load_mus file)
    | `Chunk -> Chunk (Mix.load_wav file)
  in
  sounds := Map.set !sounds ~key:name ~data:(snd, None)

let get_sound name = Map.find_exn !sounds name

let play_sound name =
  let s = Sound.play (get_sound name) in
  sounds := Map.set !sounds ~key:name ~data:s 

let clear () =
  Map.iter !shaders ~f:Shader.delete;
  Map.iter !textures ~f:Texture.delete;
  Mix.halt_channel (-1);
  Map.iter !sounds ~f:(fun (s, _) -> Sound.delete s)
  

open Tgl3

type t
val generate :
  ?width:int ->
  ?height:int ->
  ?internal_format:Gl.enum ->
  ?image_format:Gl.enum ->
  ?wrap_s:Gl.enum ->
  ?wrap_t:Gl.enum ->
  ?filter_min:Gl.enum ->
  ?filter_max:Gl.enum ->
  [ `Data of ('a, 'b, Bigarray.c_layout) Bigarray.Array1.t | `Offset of int ] -> t
val bind : t -> unit
val delete : t -> unit
val id : t -> int

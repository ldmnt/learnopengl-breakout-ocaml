type t
val generate :
  ?width:int ->
  ?height:int ->
  ?internal_format:Tgl3.Gl.enum ->
  ?image_format:Tgl3.Gl.enum ->
  ?wrap_s:Tgl3.Gl.enum ->
  ?wrap_t:Tgl3.Gl.enum ->
  ?filter_min:Tgl3.Gl.enum ->
  ?filter_max:Tgl3.Gl.enum ->
  ('a, 'b) Tgl3.Gl.bigarray -> t
val bind : t -> unit
val delete : t -> unit

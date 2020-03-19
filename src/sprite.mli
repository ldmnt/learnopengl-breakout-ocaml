module Vector := Util.Vec2

val init : Shader.t -> unit
val draw :
  Texture.t ->
  Vector.t ->
  ?color:float * float * float ->
  ?rotate:float ->
  Vector.t -> unit
val shutdown : unit -> unit

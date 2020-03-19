open Base
    
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

val make : Shader.t -> int -> int -> t
val begin_render : t -> unit
val end_render : t -> unit
val render : t -> float -> unit

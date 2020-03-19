open Base

type state = Active | Menu | Win

type t = {
  state : state
; levels : Game_level.t array
; level : int
; powerups : Powerup.t list
; player : Game_object.t
; ball : Ball.t
; shake_time : float
; lives : int
           
; particle_generator : Particle_generator.t
; effects : Postprocessor.t
; text : Text_renderer.t
           
; width : float
; height : float

; last_frame : float
}

val init : float -> float -> t

val process_input : t -> dt:float -> t
val update : t -> dt:float -> t
val render : t -> unit

val get_time : unit -> float

val update_key : int -> bool * bool -> unit


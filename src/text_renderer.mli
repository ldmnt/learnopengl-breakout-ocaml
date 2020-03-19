open Base

module RM := Resource_manager

type t

val load : width:float -> height:float -> file:string -> size:int -> t
val render_text : t -> x:float -> y:float -> ?color:float * float * float -> scaling:float -> string -> unit

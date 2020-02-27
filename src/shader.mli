open Base

type t
val use : int -> unit
val compile :
  vertex:string -> fragment:string -> geometry:string Option.t -> t
val delete : t -> unit

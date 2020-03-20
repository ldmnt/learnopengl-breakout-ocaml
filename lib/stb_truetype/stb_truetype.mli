module Stbtt : sig
  type fontinfo 

  val allocate_fontinfo : unit -> fontinfo
  val get_number_of_fonts : string -> int
  val scale_for_pixel_height : fontinfo -> float -> float
  val init_font : fontinfo -> string -> int -> unit
  val get_font_v_metrics : fontinfo  -> int * int * int
  val get_codepoint_h_metrics : fontinfo  -> int -> int * int
  val get_codepoint_bitmap : fontinfo -> float -> float -> int ->
    ((char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t * int * int * int * int) option
  val free_bitmap : (char, 'a, 'b) Bigarray.Array1.t -> unit
end

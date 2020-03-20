open Ctypes

module Stbtt = struct

include Stb_truetype_binding.C (Stb_truetype_generated)

type nonrec fontinfo = fontinfo ptr  

let fontinfo_size = fontinfo_size ()

let allocate_fontinfo () =
  allocate_fontinfo ~size:fontinfo_size

let init_font info data offset =
  match init_font info data offset with
  | 0 -> failwith "Error when loading font info.\n"
  | _ -> ()

let get_font_v_metrics info =
  let i () = allocate int 0 in
  let ascent, descent, line_gap = i (), i (), i () in
  get_font_v_metrics info ascent descent line_gap;
  !@ascent, !@descent, !@line_gap

let get_codepoint_h_metrics info c =
  let i () = allocate int 0 in
  let advance, bearing = i (), i () in
  get_codepoint_h_metrics info c advance bearing;
  !@advance, !@bearing

let get_codepoint_bitmap info scale_x scale_y c =
  let i () = allocate int 0 in
  let width, height, xoff, yoff = i (), i (), i (), i () in
  let data =
    get_codepoint_bitmap info scale_x scale_y c width height xoff yoff
    |> bigarray_of_ptr array1 (!@width * !@height) Bigarray.char in
  if !@width * !@height > 0 then
    Some (data, !@width, !@height, !@xoff, !@yoff)
  else None

let free_bitmap b =
  free_bitmap (bigarray_start array1 b) null
end

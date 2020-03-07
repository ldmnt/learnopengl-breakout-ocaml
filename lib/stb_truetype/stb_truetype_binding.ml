open Ctypes
open Cstubs

module C (F : FOREIGN)  = struct
open F

type fontinfo = [`font_info] structure
let fontinfo : fontinfo typ = structure "stbtt_fontinfo"

let allocate_fontinfo () =
  coerce (ptr char) (ptr fontinfo) (allocate_n ~count:160 char)

let get_number_of_fonts =
  foreign "stbtt_GetNumberOfFonts" (string @-> returning int)

let init_font =
  foreign "stbtt_InitFont" (ptr fontinfo @-> string @-> int @-> returning int)

let get_font_v_metrics =
  foreign "stbtt_GetFontVMetrics" (ptr fontinfo @-> ptr int @-> ptr int @-> ptr int @-> returning void)

let get_codepoint_h_metrics =
  foreign "stbtt_GetCodepointHMetrics" (ptr fontinfo @-> int @-> ptr int @-> ptr int @-> returning void)

let get_codepoint_bitmap =
  foreign "stbtt_GetCodepointBitmap"
    (ptr fontinfo @-> float @-> float @-> int @-> ptr int @-> ptr int @-> ptr int @-> ptr int
     @-> returning (ptr char))

let free_bitmap =
  foreign "stbtt_FreeBitmap" (ptr char @-> ptr void @-> returning void)

let scale_for_pixel_height =
  foreign "stbtt_ScaleForPixelHeight" (ptr fontinfo @-> float @-> returning float)
    
end

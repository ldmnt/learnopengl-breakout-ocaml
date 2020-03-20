let () = 
  let fmt = Format.formatter_of_out_channel (open_out "stb_truetype_stubs.c") in
  Format.fprintf fmt
    "#define STB_TRUETYPE_IMPLEMENTATION\n#include \"stb_truetype.h\"\n
     int fontinfoSize() { return (int) sizeof(stbtt_fontinfo); }\n";
  Cstubs.write_c fmt ~prefix:"stb_truetype_stubs" (module Stb_truetype_binding.C);

  let fmt = Format.formatter_of_out_channel (open_out "stb_truetype_generated.ml") in
  Cstubs.write_ml fmt ~prefix:"stb_truetype_stubs" (module Stb_truetype_binding.C)

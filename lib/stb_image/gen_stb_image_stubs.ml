let () = 
  let fmt = Format.formatter_of_out_channel (open_out "stb_image_stubs.c") in
    Format.fprintf fmt "#define STB_IMAGE_IMPLEMENTATION\n#include \"stb_image.h\"\n";
    Cstubs.write_c fmt ~prefix:"stb_image_stubs" (module Stb_image_binding.C);

    let fmt = Format.formatter_of_out_channel (open_out "stb_image_generated.ml") in
    Cstubs.write_ml fmt ~prefix:"stb_image_stubs" (module Stb_image_binding.C)

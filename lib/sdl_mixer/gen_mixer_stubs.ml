let () =
  let fmt = Format.formatter_of_out_channel (open_out "mixer_stubs.c") in
  Format.fprintf fmt "#include <SDL2/SDL.h>\n#include <SDL2/SDL_mixer.h>\n";
  Cstubs.write_c fmt ~prefix:"mixer_stubs" (module Mixer_bindings.C);

  let fmt = Format.formatter_of_out_channel (open_out "mixer_generated.ml") in
  Cstubs.write_ml fmt ~prefix:"mixer_stubs" (module Mixer_bindings.C);

  let fmt = Format.formatter_of_out_channel (open_out "gen_consts.c") in
  Format.fprintf fmt "#include <SDL2/SDL.h>\n#include <SDL2/SDL_mixer.h>\n";
  Cstubs.Types.write_c fmt (module Mixer_bindings.Consts)

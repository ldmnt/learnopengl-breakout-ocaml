open Tgl3

type t = int
         
let generate
    ?(width=0)
    ?(height=0)
    ?(internal_format=Gl.rgb)
    ?(image_format=Gl.rgb)
    ?(wrap_s=Gl.repeat)
    ?(wrap_t=Gl.repeat)
    ?(filter_min=Gl.linear)
    ?(filter_max=Gl.linear)
    data =
  let id = Util.get_int (Gl.gen_textures 1) in
  Gl.bind_texture Gl.texture_2d id;
  Gl.tex_image2d Gl.texture_2d 0 internal_format width height 0 image_format Gl.unsigned_byte (`Data data);
  Gl.tex_parameteri Gl.texture_2d Gl.texture_wrap_s wrap_s;
  Gl.tex_parameteri Gl.texture_2d Gl.texture_wrap_t wrap_t;
  Gl.tex_parameteri Gl.texture_2d Gl.texture_min_filter filter_min;
  Gl.tex_parameteri Gl.texture_2d Gl.texture_mag_filter filter_max;
  Gl.bind_texture Gl.texture_2d 0;
  id

let bind = Gl.bind_texture Gl.texture_2d

let delete = Util.set_int (Gl.delete_textures 1)

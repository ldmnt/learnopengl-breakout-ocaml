open Ctypes

module Stbi = struct

include Stb_image_binding.C (Stb_image_generated)

let load file =
  let i () = allocate int 0 in
  let width, height, n_channels = i (), i (), i () in
  let data = load file width height n_channels 0 in
  let data = bigarray_of_ptr array1 (!@width * !@height * !@n_channels) Bigarray.Char data in
  (data, !@width, !@height, !@n_channels)

let image_free data =
  data
  |> bigarray_start array1
  |> to_voidp
  |> image_free

end

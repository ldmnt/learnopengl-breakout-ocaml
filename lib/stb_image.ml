open Ctypes
open Foreign

let stbi_load =
  foreign "stbi_load"
    (string @-> ptr int @-> ptr int @-> ptr int @-> int @-> returning (ptr char))

let stbi_image_free =
  foreign "stbi_image_free" (ptr void @-> returning void)

let stbi_load file =
  let width = allocate int 0 in
  let height = allocate int 0 in
  let n_channels = allocate int 0 in
  let data = stbi_load file width height n_channels 0 in
  let data = bigarray_of_ptr array1 (!@width * !@height * !@n_channels) Bigarray.Char data in
  (data, !@width, !@height, !@n_channels)

let stbi_image_free data =
  data
  |> bigarray_start array1
  |> to_voidp
  |> stbi_image_free


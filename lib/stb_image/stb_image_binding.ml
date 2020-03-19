open Ctypes
open Cstubs

module C (F : FOREIGN) = struct
open F

let load =
  foreign "stbi_load" (string @-> ptr int @-> ptr int @-> ptr int @-> int @-> returning (ptr char))

let image_free =
  foreign "stbi_image_free" (ptr void @-> returning void)
    
end

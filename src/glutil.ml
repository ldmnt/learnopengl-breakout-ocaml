open Tgl3

let bigarray_create k len = Bigarray.(Array1.create k c_layout len)

let get_int f =
  let a = bigarray_create Bigarray.int32 1 in
  f a; Int32.to_int a.{0}

let get_string len f =
  let a = bigarray_create Bigarray.char len in
  f a; Gl.string_of_bigarray a

let set_int f n =
  let a = bigarray_create Bigarray.int32 1 in
  a.{0} <- Int32.of_int n; f a

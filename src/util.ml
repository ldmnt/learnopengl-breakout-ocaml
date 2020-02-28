open Base
open Tgl3

(* Arrays that can be used to exchange data with GL context *)
let bigarray_create k len = Bigarray.(Array1.create k c_layout len)

let float_bigarray a = Bigarray.(Array1.of_array float32 c_layout a)

(* Helpers to retrieve values from GL calls *)
let get_int f =
  let a = bigarray_create Bigarray.int32 1 in
  f a; Int32.to_int_exn a.{0}

let get_string len f =
  let a = bigarray_create Bigarray.char len in
  f a; Gl.string_of_bigarray a

let set_int f n =
  let a = bigarray_create Bigarray.int32 1 in
  a.{0} <- Int32.of_int_exn n; f a

module Mat = struct
  let ( ** ) a b =
    let n = Array.length a in
    let m = Array.length a.(0) in
    let p = Array.length b.(0) in
    let result = Array.make_matrix n p 0. in
    for i = 0 to n - 1 do
      for j = 0 to p - 1 do
        for k = 0 to m - 1 do
          result.(i).(j) <- result.(i).(j) +. a.(i).(k) *. b.(k).(j)
        done
      done
    done;
    result

  let identity () =
    [|
      [| 1.; 0.; 0.; 0. |];
      [| 0.; 1.; 0.; 0. |];
      [| 0.; 0.; 1.; 0. |];
      [| 0.; 0.; 0.; 1. |]
    |]

  let translation vec =
    [|
      [| 1.; 0.; 0.; vec.(0) |];
      [| 0.; 1.; 0.; vec.(1) |];
      [| 0.; 0.; 1.; vec.(2) |];
      [| 0.; 0.; 0.; 1.      |]
    |]

  let rotation_around_z ~angle =
    let t = angle in
    let open Float in
    [|
      [| cos t; -.sin t; 0.; 0. |];
      [| sin t; cos t  ; 0.; 0. |];
      [| 0.   ; 0.     ; 1.; 0. |];
      [| 0.   ; 0.     ; 0.; 1. |]
    |]

  let scaling cx cy =
    [|
      [| cx; 0.; 0.; 0. |];
      [| 0.; cy; 0.; 0. |];
      [| 0.; 0.; 1.; 0. |];
      [| 0.; 0.; 0.; 1. |]
    |]
  
  let orthographic_projection left right bottom top near far =
      [|
        [| 2. /. (right -. left); 0.                   ; 0.                   ; -. (right +. left) /. (right -. left) |];
        [| 0.                   ; 2. /. (top -. bottom); 0.                   ; -. (top +. bottom) /. (top -. bottom) |];
        [| 0.                   ; 0.                   ; -.2. /. (far -. near); -. (far +. near) /. (far -. near)     |];
        [| 0.                   ; 0.                   ; 0.                   ; 1.                                    |]
      |]
      
  let to_bigarray mat =
    let n = Array.length mat in
    let m = Array.length mat.(0) in
    let result = bigarray_create Bigarray.float32 (n * m) in
    for i = 0 to n - 1 do
      for j = 0 to m - 1 do
        result.{i * m + j} <- mat.(i).(j)
      done
    done;
    result
end

module Vec2 = struct
  type t = {
    x : float
  ; y : float
  }
end

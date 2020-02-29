open Base
open Tgl3

type direction = Up | Right | Down | Left


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

  let zero = { x = 0.; y = 0. }
  
  let add { x = x1; y = y1 } { x = x2; y = y2 } =
    { x = x1 +. x2; y = y1 +. y2 }

  let ( + ) = add

  let mul a {x; y} = { x = a *. x; y = a *. y }

  let ( $* ) = mul

  let ( - ) u v = u + (-. 1. $* v)

  let clamp v low high =
    let clamp_float a low high = Float.max low (Float.min high a) in
    { x = clamp_float v.x low.x high.x; y = clamp_float v.y low.y high.y }

  let squared_norm { x; y } = x *. x +. y *. y

  let dot { x = x1; y = y1 } { x = x2; y = y2 } = x1 *. x2 +. y1 *. y2

  let length v = Float.sqrt (squared_norm v)

  let normalize v = (1. /. length v) $* v

  let direction target =
    let compass = [
      ( Up, { x = 0.; y = 1. } );
      ( Right, { x = 1.; y = 0. } );
      ( Down, { x = 0.; y = -. 1. } );
      ( Left, { x = -. 1.; y = 0. } );
    ] in
    let (_, best_dir) =
      List.fold_left compass ~init:(0., Up) ~f:
        begin fun (maxi, best_dir) (dir, v) ->
          let dotp = dot target v in
          if Float.(dotp > maxi) then (dotp, dir) else (maxi, best_dir)
        end in
    best_dir
end

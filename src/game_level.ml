open Base
open Stdio

module RM = Resource_manager

type t = {
  bricks : Game_object.t list
}

let tile_color = function
  | 1 -> (0.8, 0.8, 0.7)
  | 2 -> (0.2, 0.6, 1.0)
  | 3 -> (0.0, 0.7, 0.0)
  | 4 -> (0.8, 0.8, 0.4)
  | 5 -> (1.0, 0.5, 0.0)
  | _ -> (1.0, 1.0, 1.0) (* default: white *)


let init level_width level_height tile_data =
  (* Calculate dimensions *)
  let height = List.length tile_data |> Float.of_int in
  if Float.(height > 0.) then
    let width = tile_data |> List.hd_exn |> List.length |> Float.of_int in
    let unit_width = level_width /. width in
    let unit_height = level_height /. height in

    (* Create block for (x, y) in level data depending on tile type *)
    let make_block y x = function 
      | 0 -> None
      | 1 ->
        Some (
          Game_object.make
            ~pos:{ x = unit_width *. Float.of_int x; y = unit_height *. Float.of_int y }
            ~size:{ x = unit_width; y = unit_height }
            ~sprite:(RM.get_texture "block_solid")
            ~color:(tile_color 1)
            ~is_solid:true
            ()
        ) 
      | n ->
        Some (
          Game_object.make
            ~pos: { x = unit_width *. Float.of_int x; y = unit_height *. Float.of_int y }
            ~size:{ x = unit_width; y = unit_height }
            ~sprite:(RM.get_texture "block")
            ~color:(tile_color n)
            ~is_solid:false
            ()
        )
    in

    (* Iterate on tile data *)
    List.mapi tile_data ~f:begin
      fun y -> List.mapi ~f:(make_block y)
    end
    |> List.concat
    |> List.filter_opt (* Filter out zeros (no block) *)

  else []


let load level_width level_height file =
  let parse_line l =
    l
    |> String.rstrip (* Remove trailing whitespace *)
    |> String.split ~on:(Char.of_string " ") (* Read each word separated by spaces *)
    |> List.map ~f:Int.of_string
  in

  let bricks =
    (* Load from file *)
    In_channel.read_all file
    |> String.split_lines (* Read each line from level file *)
    |> List.map ~f:parse_line
    |> init level_width level_height in

  { bricks }


let draw t =
  let maybe_draw b =
    if not b.Game_object.destroyed then
      Game_object.draw b in
  List.iter t.bricks ~f:maybe_draw


let is_completed t =
  let is_done b = Game_object.(b.is_solid || b.destroyed) in
  List.for_all t.bricks ~f:is_done

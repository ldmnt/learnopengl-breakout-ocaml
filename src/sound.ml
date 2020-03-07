open Tsdl
open Sdl_mixer

(* Music is for the background music and
   Chunk is for the sound effects *)
type t =
  | Music of Mix.Music.t
  | Chunk of Mix.Chunk.t

let init () =
  Mix.init Mix.Init.mp3;
  Mix.open_audio 22050 Sdl.Audio.s16_sys 2 512;
  ignore (Mix.allocate_channels 8)

let play (snd, current_channel) =
  match snd with
  | Music m -> Mix.play_music m (-1); (snd, None)
  | Chunk c ->
    let new_channel =
      begin
        match current_channel with
        | Some c -> Mix.halt_channel c
        | None -> ()
      end;
      try
        let c = Mix.play_channel (-1) c 0  in
        Some c
      with | _ -> None
    in
    (snd, new_channel)

let delete = function
  | Music m -> Mix.free_music m
  | Chunk c -> Mix.free_chunk c

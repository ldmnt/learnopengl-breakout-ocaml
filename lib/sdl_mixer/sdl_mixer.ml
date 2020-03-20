module Mix = struct
  
include Mixer_bindings.C (Mixer_generated)
include Mixer_bindings.Consts (Mixer_consts_generated)

module Init = struct
  type t = int
  let ( + ) = Int.logor
  let ( = ) = Int.equal
  let flac = mix_init_flac
  let mod_ = mix_init_mod
  let mp3 = mix_init_mp3
  let ogg = mix_init_ogg
end

let error () = failwith (get_error ())

let zero_to_ok = function
  | 0 -> ()
  | _ -> error ()

let error_if cond = function
  | p when cond p -> error ()
  | p -> p

let init flags =
  match init flags with
  | n when n = flags -> ()
  | _ -> error ()

let open_audio freq fmt channels chunksize =
  zero_to_ok (open_audio freq fmt channels chunksize)

let load_mus fname =
  error_if Music.is_null (load_mus fname)

let play_music music loops =
  zero_to_ok (play_music music loops)

let load_wav fname =
  error_if Chunk.is_null (load_wav fname)

let play_channel channel chunk loops =
  let c = play_channel channel chunk loops in
  error_if (fun c -> c < 0) c

let halt_channel c =
  ignore (halt_channel c)
end

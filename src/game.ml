module State = struct
  type t = {
    last_frame : float
  }
end

type t =
    Active of State.t
  | Menu
  | Win
  
let init () = Active { last_frame = GLFW.getTime () }

let update g ~dt = ignore dt; g

let process_input g ~dt = ignore dt; g

let render _ = ()


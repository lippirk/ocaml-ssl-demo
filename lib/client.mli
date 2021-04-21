val set_ssl_params :
  enable_verification:bool -> bundle_fname:string -> cb:Ssl.verify_callback -> unit

val call_server : unit -> unit Lwt.t

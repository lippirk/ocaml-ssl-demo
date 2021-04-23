val create_ssl_ctx :
  enable_verification:bool ->
  bundle_fname:string ->
  cb:Ssl.verify_callback ->
  Ssl.context

val call_server : ctx:Ssl.context -> unit -> unit Lwt.t

val call_server : enable_verification:bool ->
                  bundle_fname:string ->
                  cb:Ssl.verify_callback ->
                  unit Lwt.t

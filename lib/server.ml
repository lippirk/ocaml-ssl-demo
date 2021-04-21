let cert = "cert.pem"

let key = "key.pem"

let ip, port = ("127.0.0.1", 8080)

let ciphers = "RSA+AES128-SHA256"

let disable_protocols = [ Ssl.SSLv23; TLSv1; TLSv1_1 ]

let ( let* ) = Lwt.bind

let ( let+ ) = Lwt.bind

let printf = Lwt_io.printf

let eprintf = Lwt_io.eprintf

let setup_ctx () =
  let ctx = Conduit_lwt_unix_ssl.Server.default_ctx in
  Ssl.set_verify ctx [] None;
  Ssl.set_cipher_list ctx ciphers;
  Ssl.use_certificate ctx cert key;
  Ssl.disable_protocols ctx disable_protocols


let callback _process req body =
  let uri = Cohttp.Request.uri req in
  let path = Uri.path uri in
  match (Cohttp.Request.meth req, path) with
  | `POST, "/echo" ->
      let* body = Cohttp_lwt.Body.to_string body in
      let+ () = printf "OK body = %s\n" body in
      Cohttp_lwt_unix.Server.respond_string ~status:`OK ~body ()
  | _ ->
      let+ () = eprintf "ERR bad request\n" in
      Cohttp_lwt_unix.Server.respond_string ~status:`Bad_request ~body:"" ()

let start () : unit Lwt.t =
  let () = setup_ctx () in
  let config = Cohttp_lwt_unix.Server.make ~callback () in
  let server_config = (`Crt_file_path cert, `Key_file_path key, `No_password, `Port port) in
  let mode = `OpenSSL server_config in
  let* ctx = Conduit_lwt_unix.init ~src:ip () in
  let ctx = Cohttp_lwt_unix.Net.init ~ctx () in
  let on_exn e = Printf.eprintf "server.ml: server error: %s" (Printexc.to_string e) in
  Cohttp_lwt_unix.Server.create ~ctx ~on_exn ~mode config

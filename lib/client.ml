let cn = "127.0.0.1"

let port = 8080

let ssl_verbose = true

let ciphers = "RSA+AES128-SHA256"

let disable_protocols = [ Ssl.SSLv23; TLSv1; TLSv1_1 ]

let eprintf = Lwt_io.eprintf

let ( let* ) = Lwt.bind

let _call_server ~body : unit Lwt.t =
  let open Cohttp_lwt_unix in
  let uri = Uri.of_string (Printf.sprintf "https://%s:%i/echo" cn port) in
  let body_str = body in
  let body = Cohttp_lwt.Body.of_string body in
  let* _resp, resp_body = Client.call `POST ~body uri in
  let* resp_body_str = Cohttp_lwt.Body.to_string resp_body in
  if body_str = resp_body_str then eprintf "client.ml: got good response\n"
  else
    let msg =
      Printf.sprintf "client.ml: expected '%s' in response, got '%s'\n" body_str resp_body_str
    in
    let* () = eprintf "%s" msg in
    Lwt.fail_with msg

let set_ssl_params ~enable_verification ~bundle_fname ~cb : unit =
  let ctx = Conduit_lwt_unix_ssl.Client.default_ctx in
  if enable_verification then (
    Printf.eprintf "client.ml: enabling verification\n";
    Ssl.set_verify ctx [ Ssl.Verify_peer ] (Some cb);
    Ssl.load_verify_locations ctx bundle_fname "")
  else (
    Printf.eprintf "client.ml: not enabling verification\n";
    Ssl.set_verify ctx [] None);
  Ssl.set_cipher_list ctx ciphers;
  Ssl.disable_protocols ctx disable_protocols

let call_server () : unit Lwt.t =
  let logger e =
    let* () = eprintf "client.ml:call_server exception: %s\n" (Printexc.to_string e) in
    Lwt.fail e
  in
  Lwt.catch (fun () -> _call_server ~body:"blah") logger

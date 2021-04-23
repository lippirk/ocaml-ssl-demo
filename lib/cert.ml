module Rsa = Mirage_crypto_pk.Rsa
open Rresult

let ( let* ) = Result.bind

let () = Mirage_crypto_rng_unix.initialize ()

type stdout = string

let finally f g = Fun.protect ~finally:g f

let string_to_file ~fname s : unit =
  let open Stdlib in
  let oc = open_out fname in
  finally (fun () -> Printf.fprintf oc "%s" s) (fun () -> close_out oc)

let read_stdout cmd : stdout =
  let open Stdlib in
  let inp = Unix.open_process_in cmd in
  let cond = ref true in
  let buf = Buffer.create 16 in
  while !cond do
    try
      let l = input_line inp in
      Buffer.add_string buf l;
      Buffer.add_char buf '\n'
    with End_of_file -> cond := false
  done;
  close_in inp;
  Buffer.contents buf |> String.trim

let call_openssl args : stdout =
  let openssl = "/usr/bin/openssl" in
  read_stdout (Printf.sprintf "%s %s" openssl (String.concat " " args))

let expire_in days =
  let seconds = days * 24 * 60 * 60 in
  let start = Ptime_clock.now () in
  match Ptime.(add_span start @@ Span.of_int_s seconds) with
  | Some expire -> R.ok (start, expire)
  | None -> R.error_msgf "can't represent %d as time span" days

let generate_private_key length : stdout =
  let args = [ "genrsa"; string_of_int length ] in
  call_openssl args

let write_certs fname pkcs12 =
  let f () = string_to_file ~fname pkcs12 in
  R.trap_exn f () |> R.error_exn_trap_to_msg

let sign days privkey pubkey issuer req extensions =
  expire_in days >>= fun (valid_from, valid_until) ->
  match (privkey, pubkey) with
  | `RSA priv, `RSA pub when Rsa.pub_of_priv priv = pub ->
      X509.Signing_request.sign ~valid_from ~valid_until ~extensions req privkey issuer
      |> R.reword_error (fun _ -> Printf.sprintf "signing failed" |> R.msg)
  | _ -> R.error_msgf "public/private keys don't match (%s)" __LOC__

let selfsign issuer extensions key_length days certfile =
  let rsa =
    try
      generate_private_key key_length |> Cstruct.of_string |> X509.Private_key.decode_pem
      |> R.failwith_error_msg
      |> function
      | `RSA x -> x
    with e ->
      let msg =
        Printf.sprintf "generating RSA key for %s failed: %s" certfile (Printexc.to_string e)
      in
      failwith msg
  in
  let privkey = `RSA rsa in
  let pubkey = `RSA (Rsa.pub_of_priv rsa) in
  let* req = X509.Signing_request.create issuer privkey in
  sign days privkey pubkey issuer req extensions >>= fun cert ->
  let key_pem = X509.Private_key.encode_pem privkey in
  let cert_pem = X509.Certificate.encode_pem cert in
  let pkcs12 = String.concat "\n\n" [ Cstruct.to_string key_pem; Cstruct.to_string cert_pem ] in
  write_certs certfile pkcs12 >>| fun () -> cert

let make ~fname ~cn : unit =
  let expire_days = 3650 in
  let key_length = 2048 in
  let issuer = [ X509.Distinguished_name.(Relative_distinguished_name.singleton (CN cn)) ] in
  let extensions = X509.Extension.empty in
  selfsign issuer extensions key_length expire_days fname >>| (fun _ -> ()) |> R.failwith_error_msg

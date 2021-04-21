let ( let* ) = Lwt.bind

let _create_certs () =
  Printf.eprintf "main.ml: making cert";
  Cert.make ~fname:"ssl.pem" ~cn:"cf412cfa-de68-48f3-9aef-434927f883af"

let assert_fail f : unit Lwt.t =
  let* res = Lwt.catch
    (fun () -> let* () = f () in Error () |> Lwt.return)
    (fun e -> Ok () |> Lwt.return) in
  match res with
  | Ok () -> Lwt.return ()
  | Error () -> "expected failure, got success" |> Lwt.fail_with


let matrix =
  (* 3 variables ==> 2**3 = 8 test cases *)
  ["good-bundle.pem", `no_verif, Ssl.client_verify_callback, `success
  ;"good-bundle.pem", `verif   , Ssl.client_verify_callback, `failure
  ;"good-bundle.pem", `no_verif, Ssl.Citrix.exact_match_cb , `success
  ;"good-bundle.pem", `verif   , Ssl.Citrix.exact_match_cb , `success
  ;"bad-bundle.pem" , `no_verif, Ssl.client_verify_callback, `success
  ;"bad-bundle.pem" , `verif   , Ssl.client_verify_callback, `failure
  ;"bad-bundle.pem" , `no_verif, Ssl.Citrix.exact_match_cb , `success
  ;"bad-bundle.pem" , `verif   , Ssl.Citrix.exact_match_cb , `failure
  ]

let run_matrix () : unit Lwt.t =
  matrix |> Lwt_list.iter_s @@ fun (bundle_fname, verif_flag, cb, success_or_fail) ->
    let enable_verification = match verif_flag with `no_verif -> false | `verif -> true in
    let f () = Client.call_server ~enable_verification ~bundle_fname ~cb  in
    match success_or_fail with
    | `success ->  f ()
    | `failure -> assert_fail f


let main () : unit Lwt.t =
  Printexc.record_backtrace true ;
  Lwt.async Server.start;
  run_matrix ()

(* let () = _create_certs () *)
let () = Lwt_main.run (main ())

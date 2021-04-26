let ( let* ) = Lwt.bind

let eprintf = Lwt_io.eprintf

let _create_certs () =
  Printf.eprintf "main.ml: making cert\n";
  Cert.make ~fname:"good-ssl.pem" ~cn:"cf412cfa-de68-48f3-9aef-434927f883af";
  Cert.make ~fname:"bad-ssl.pem" ~cn:"240f0d63-c213-4c00-ad5a-862c1e8c0b00"

let assert_fail f : unit Lwt.t =
  let* res =
    Lwt.catch
      (fun () ->
        let* () = f () in
        Error () |> Lwt.return)
      (fun e -> Ok () |> Lwt.return)
  in
  match res with
  | Ok () -> Lwt.return ()
  | Error () -> "expected failure, got success" |> Lwt.fail_with

let matrix =
  (* 3 variables ==> 2**3 = 8 test cases *)
  [
    ("bad-bundle.pem", `verif, `default_cb, `failure);
    ("good-bundle.pem", `verif, `default_cb, `success);
    ("bad-bundle.pem", `no_verif, `default_cb, `success);
    ("good-bundle.pem", `no_verif, `default_cb, `success);
    (* ("bad-bundle.pem", `verif, `my_cb, `failure); *)
    (* ("good-bundle.pem", `verif, `my_cb, `success); *)
    (* ("bad-bundle.pem", `no_verif, `my_cb, `success); *)
    (* ("good-bundle.pem", `no_verif, `my_cb, `success); *)
  ]

let run_test_case (bundle_fname, verif_flag, cb, success_or_fail) : unit Lwt.t =
  (* run a single test case *)
  let cb_str = match cb with `default_cb -> "default_cb" | `my_cb -> "my_cb" in
  (* let cb = *)
    (* match cb with `default_cb -> Ssl.client_verify_callback | `my_cb -> Ssl.Citrix.exact_match_cb *)
  (* in *)
  let enable_verification = match verif_flag with `no_verif -> false | `verif -> true in
  let* () =
    eprintf "====test case: bundle=%s, cb=%s, enable_verification=%b\n" bundle_fname cb_str
      enable_verification
  in
  let ctx = Client.create_ssl_ctx ~enable_verification ~bundle_fname in
  let f () : unit Lwt.t =
    match success_or_fail with
    | `success -> Client.call_server ~ctx ()
    | `failure -> assert_fail (Client.call_server ~ctx)
  in
  let* () = List.init 10 (fun _ -> ()) |> Lwt_list.iter_p f in
  Stdlib.flush Stdlib.stderr;
  let* () = eprintf "====\n" in
  Lwt.return ()

let run_matrix () : unit Lwt.t =
  (* run all the test cases in [matrix] in a random order *)
  let rec permutation list =
    let rec extract acc n = function
      | [] -> raise Not_found
      | h :: t -> if n = 0 then (h, acc @ t) else extract (h :: acc) (n - 1) t
    in
    let extract_rand list len = extract [] (Random.int len) list in
    let rec aux acc list len =
      if len = 0 then acc
      else
        let picked, rest = extract_rand list len in
        aux (picked :: acc) rest (len - 1)
    in
    aux [] list (List.length list)
  in
  matrix |> permutation |> Lwt_list.iter_s run_test_case

let main () : unit Lwt.t =
  Lwt.async Server.start;
  Printexc.record_backtrace true;
  match Sys.argv with
  | [| _; i |] -> i |> int_of_string |> List.nth matrix |> run_test_case
  | [| _ |] -> run_matrix ()
  | _ -> failwith "invalid args"

(* let () = _create_certs () *)

let () = Lwt_main.run (main ())

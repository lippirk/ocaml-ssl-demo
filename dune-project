(lang dune 2.8)
(name ocaml-ssl-demo)
(generate_opam_files true)

(package
 (name ocaml-ssl-demo)
 (version 0.0.1)
 (synopsis "")
 (description "")
 (depends
  cohttp-lwt-unix
  conduit-lwt-unix
  cohttp
  lwt
  lwt-ssl
  ssl))

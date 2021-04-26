.PHONY: build
build:
	dune build @default --profile=release

.PHONY: run-separately
run-separately:
	CONDUIT_TLS=openssl dune exec ocaml-ssl-demo --profile=release -- 0
	CONDUIT_TLS=openssl dune exec ocaml-ssl-demo --profile=release -- 1
	CONDUIT_TLS=openssl dune exec ocaml-ssl-demo --profile=release -- 2
	CONDUIT_TLS=openssl dune exec ocaml-ssl-demo --profile=release -- 3

.PHONY: run-together
run-together: build
	CONDUIT_TLS=openssl dune exec ocaml-ssl-demo --profile=release

.PHONY: clean
clean:
	dune clean

.PHONY: format
format:
	dune build @fmt --auto-promote

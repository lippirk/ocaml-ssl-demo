.PHONY: build
build:
	dune build @default --profile=release

.PHONY: run-separately
run-separately:
	dune exec ocaml-ssl-demo --profile=release -- 0
	dune exec ocaml-ssl-demo --profile=release -- 1
	dune exec ocaml-ssl-demo --profile=release -- 2
	dune exec ocaml-ssl-demo --profile=release -- 3
	dune exec ocaml-ssl-demo --profile=release -- 4
	dune exec ocaml-ssl-demo --profile=release -- 5
	dune exec ocaml-ssl-demo --profile=release -- 6
	dune exec ocaml-ssl-demo --profile=release -- 7


.PHONY: run-together
run-together: build
	dune exec ocaml-ssl-demo --profile=release

.PHONY: clean
clean:
	dune clean

.PHONY: format
format:
	dune build @fmt --auto-promote

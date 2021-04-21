.PHONY: build
build:
	dune build @default --profile=release

.PHONY: run
run: build
	dune exec ocaml-ssl-demo --profile=release

.PHONY: clean
clean:
	dune clean

.PHONY: format
format:
	dune build @fmt --auto-promote

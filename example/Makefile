.PHONY: get generate check-generated analyze test build-web check

get:
	flutter pub get

generate:
	dart run solana_idl_codegen generate lib/idl/example_program.json lib/idl/secondary_program.json --input-root lib/idl --output lib/generated --layout modular

check-generated:
	dart run solana_idl_codegen generate lib/idl/example_program.json lib/idl/secondary_program.json --input-root lib/idl --output lib/generated --layout modular --check

analyze:
	flutter analyze

test:
	flutter test

build-web:
	flutter build web

check: get check-generated analyze test build-web

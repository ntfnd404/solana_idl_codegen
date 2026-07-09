# solana_idl_codegen Flutter example

This is a neutral Flutter consumer application for the generator. It is not
part of the generator public API.

The example has Android, iOS, web, Linux, macOS, and Windows targets. It uses
modular generation for two IDLs under `lib/idl/` and composes their structural
`toWire()` records in application-owned code.

Mock mode is the default. `lib/solana_account_reader_adapter.dart` shows an
optional application adapter to `package:solana`; that adapter is example code,
not generated API and not a dependency of generated SDKs.

## Generate

The example includes a convenience `Makefile`:

```shell
cd example
make generate
make check-generated
```

Raw command from the repository root:

```shell
dart run solana_idl_codegen generate \
  example/lib/idl/example_program.json \
  example/lib/idl/secondary_program.json \
  --input-root example/lib/idl \
  --output example/lib/generated \
  --layout modular
```

Check committed generated output without writing:

```shell
dart run solana_idl_codegen generate \
  example/lib/idl/example_program.json \
  example/lib/idl/secondary_program.json \
  --input-root example/lib/idl \
  --output example/lib/generated \
  --layout modular \
  --check
```

## Run checks

Makefile workflow:

```shell
cd example
make check
```

Raw commands:

```shell
flutter pub get
dart run solana_idl_codegen generate \
  lib/idl/example_program.json \
  lib/idl/secondary_program.json \
  --input-root lib/idl \
  --output lib/generated \
  --layout modular \
  --check
flutter analyze
flutter test
flutter build web
```

Run on an available platform with:

```shell
flutter run
```

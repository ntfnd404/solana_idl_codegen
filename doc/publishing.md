# Publishing

The repository root is the only publishable package. `example/` is an
independent `publish_to: none` Flutter consumer that demonstrates generated SDK
usage; it is not generator public API.

## Release checklist

1. Update `pubspec.yaml` version.
2. Update `CHANGELOG.md` with the same version.
3. Confirm `lib/src/generator/generator_version.dart` matches the package
   version embedded in generated headers.
4. Regenerate and check the Flutter example.
5. Run the full check set below.
6. Run `dart pub publish --dry-run` and require zero warnings.
7. Inspect the archive list for accidental caches, build artifacts, temporary
   files, or maintainer-only tooling.
8. Tag and publish only after CI succeeds.

## Required commands

```shell
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart doc --dry-run .
dart run solana_idl_codegen generate \
  example/lib/idl/example_program.json \
  example/lib/idl/secondary_program.json \
  --input-root example/lib/idl \
  --output example/lib/generated \
  --layout modular \
  --check
(cd example && flutter analyze && flutter test && flutter build web)
dart pub publish --dry-run
```

Normal release checks do not require Node, npm, Rust, Anchor CLI, Solana CLI,
Docker, or a local validator.

## Archive policy

The archive should include README, CHANGELOG, LICENSE, SECURITY, CONTRIBUTING,
`doc/`, `lib/`, `bin/`, `build.yaml`, and the useful Flutter example.

The archive should exclude `.dart_tool`, `build`, IDE folders, generated API
docs, temporary lock/recovery files, and maintainer-only
`tool/reference_vectors/` contents.

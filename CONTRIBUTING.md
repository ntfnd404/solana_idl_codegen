# Contributing

Open an issue before large public API, schema, validation, or generated-output
changes. Unsupported wire data must fail with an explicit diagnostic; do not
add silent fallbacks.

## Setup

```shell
dart pub get
cd example
flutter pub get
```

Normal development does not require Node, npm, Rust, Anchor CLI, Solana CLI,
Docker, or a local validator.

## Required checks

Run before submitting a pull request:

```shell
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart doc --dry-run .
dart pub publish --dry-run
dart run solana_idl_codegen generate \
  example/lib/idl/example_program.json \
  example/lib/idl/secondary_program.json \
  --input-root example/lib/idl \
  --output example/lib/generated \
  --layout modular \
  --check
(cd example && flutter analyze && flutter test && flutter build web)
```

## Generated files

Generated output must remain deterministic:

- no timestamps;
- no absolute paths;
- LF line endings;
- stable ordering;
- generated header with tool marker, generator version, source digest,
  semantic digest, and SPDX notice.

When generated output intentionally changes, update committed example output
and any affected golden/reference expectations in the same change.

## Documentation

Update README and `doc/` when behavior, public API, builder options, CLI flags,
generated layout, reference-vector policy, or release workflow changes. Keep
`example/README.md` aligned with the Flutter example.

## Reference vectors

Committed vectors under `test/reference_vectors/` are used by ordinary tests.
`tool/reference_vectors/verify_upstream.dart` is maintainer-only provenance
checking and must not become a normal PR requirement.

## Forbidden changes

Do not add:

- public generated `dynamic`;
- unjustified public generated `Object?`;
- silent fallback for unknown IDL data;
- concrete RPC, wallet, or transaction dependencies in generated SDKs;
- Node/npm as package or ordinary CI dependencies;
- `part` / `part of`;
- generated timestamps or absolute source paths;
- handwritten `ignore_for_file: public_member_api_docs`.

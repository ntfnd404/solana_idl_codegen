## 0.2.0

- **Breaking:** Changed generated filenames to Dart-style lower snake case,
  such as `my_program_solana_accounts.dart`; CLI regeneration removes owned
  legacy dotted filenames.
- Made generated bundled and modular SDKs analyzer-clean without broad lint
  suppressions, explicit `dynamic`, or raw collection type checks.
- Enabled strict casts, inference, and raw-type analysis throughout the
  generator and generated-output test matrix.
- Fixed nullable account resolution and account-data PDA seed emission while
  preserving typed failures and transport-neutral runtime boundaries.
- Added feature-aware generated imports and private helpers so minimal and
  real-world IDLs emit only the dependencies they use.
- Fixed generic codec parameter naming and added analyzer and runtime coverage
  for concrete generic byte codecs and nested writable account groups.

## 0.1.0

Initial release.

- Added one publishable, development-only `solana_idl_codegen` package.
- Added strict legacy and modern Anchor IDL parsing with duplicate-key
  detection, resource limits, stable diagnostics, and semantic validation.
- Added deterministic bundled and modular build_runner builders.
- Added batch CLI workflows for validation, generation, check mode, clean,
  output ownership, locks, and recovery.
- Added self-contained generated Borsh support, value models, instruction
  requests, account resolution, account clients, views, events, errors, and
  transport-neutral capability ports.
- Added program-prefixed generated APIs with no runtime dependency on the
  generator, `package:solana`, RPC, wallet, or Borsh packages.
- Added a six-platform Flutter example with mock mode and an optional
  application-owned `package:solana` adapter.
- Added consumer-package, builder, CLI, emitter-contract, parser, validator,
  Borsh/runtime, and reference-vector tests.
- Added publication metadata, documentation, security policy, and release
  checklist.

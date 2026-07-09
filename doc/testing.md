# Testing and reference provenance

Normal development and pull-request CI are pure Dart/Flutter workflows. They
do not require Node, npm, Rust, Anchor CLI, Solana CLI, Docker, or a local
validator. The generated SDK is transport-neutral, so validator lifecycle and
transaction submission belong to an application-owned adapter rather than this
package.

## Test layers

- Parser and validator tests cover duplicate keys, dialect detection, strict
  JSON typing, diagnostics, semantic rules, and unsupported wire data.
- Emitter tests ensure section emitters return declaration specs and bundled
  and modular layouts expose identical public declarations.
- Runtime/vector tests generate fresh SDKs and exercise Borsh, discriminators,
  account padding, SPL fixed-span COption, PDA seed bytes, invocation-stack
  events, typed Anchor errors, and malformed wire input.
- Consumer tests create temporary packages without a dependency on
  `solana_idl_codegen`, compile bundled and modular SDKs, compile two SDKs in
  one package, run on the VM, and compile to JavaScript.
- CLI and builder tests cover output planning, generated ownership,
  layout-specific outputs, checks, clean, locks, and recovery.

## Reference vectors

Committed compatibility vectors live in `test/reference_vectors/`. Their
versioned manifest records:

- Anchor producer and exact version;
- release-tag commit;
- upstream source URL and SHA-256 when a source file is referenced;
- the IDL and typed input;
- expected hexadecimal wire output.

The normal test suite uses the committed vectors only. It does not download
upstream sources.

`tool/reference_vectors/` is maintainer-only and excluded from the pub archive.
`dart run tool/reference_vectors/verify_upstream.dart` verifies recorded
upstream SHA-256 values and is intended for manual or scheduled maintainer
checks, not ordinary pull-request CI.

The current matrix covers legacy pre-0.30 and modern IDLs produced by Anchor
0.30.1, 0.31.1, and 1.0.2 provenance. A newer producer version is added only
after its schema behavior and vectors are committed and reviewed.

## Real-world external fixtures

External IDL fixtures live under `test/fixtures/external/`. They are copied
from public protocol repositories only when their source URL, exact commit or
tag, license note, SHA-256, purpose, and test mode are recorded in
`test/fixtures/external/provenance.json`.

These fixtures are not byte-level truth sources. Unless a protocol publishes
audited expected bytes, real-world fixtures are used for parser/generator
compatibility and analyzer checks only.

If a real IDL currently exposes a strict-policy incompatibility, keep it as a
`skipped-generation-candidate` with the exact diagnostic code and reason. Do
not silently patch the fixture, add JSON comments, rename source fields, or
claim parity.

No Node/npm regeneration tooling is used for external fixtures.

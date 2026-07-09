# Architecture

The repository publishes one development-only package,
`solana_idl_codegen`. There is no runtime package. Generated SDKs are
self-contained and do not depend on the generator, `package:solana`, a wallet,
an RPC client, or a third-party Borsh runtime.

```text
JSON
  → duplicate-aware decoder
  → dialect detector
  → legacy normalizer / modern decoder
  → immutable IR
  → semantic validator
  → generation pipeline
  → bundled or modular Dart SDK

CLI ───────────────┐
build_runner ──────┴→ SolanaIdlGenerator facade
```

`SolanaIdlGenerator` is the public Facade and GRASP Controller. Parser,
normalizer, IR, validation, naming, dependency collection, and emitters remain
internal. Components use constructor injection and composition instead of
global state.

`DartGenerator` selects the output layout and assembles `code_builder`
libraries. Support, types/codecs, accounts, instructions, resolution,
events/errors, and clients are emitted by focused section emitters. Top-level
declarations are produced as `code_builder` specs; raw code is reserved for
complex method bodies.

## Repository layout

```text
bin/                         CLI executable entrypoint
lib/solana_idl_codegen.dart  public programmatic API
lib/builder.dart             build_runner builder entrypoints
lib/src/builder/             builder implementation and options
lib/src/cli/                 CLI commands, output planning, locks, recovery
lib/src/generator/           Dart SDK emitters and generation context
lib/src/intermediate_representation/
                              immutable IDL IR families
lib/src/parser/              JSON, dialect, modern, and legacy decoding
lib/src/validation/          semantic validation rules
doc/                         package documentation
example/                     Flutter consumer example
test/                        unit, builder, CLI, consumer, and vector tests
tool/reference_vectors/      maintainer-only provenance verifier
```

Sealed/model families stay together. Unrelated responsibilities are separated.
The handwritten and generated source do not use `part` or `part of`.

## Transport boundary

The generated SDK follows Ports and Adapters:

```text
generated typed SDK → generated capability interfaces ← application adapters
                                                   ↙
                                 RPC / websocket / wallet selected by app
```

Generated account reader, scanner, event subscriber, simulator, PDA deriver,
and relation resolver ports satisfy ISP. The optional generated client facade
composes specialized instruction, account, event, and view clients. Concrete
RPC, wallet, transaction, fee-payer, blockhash, signing, sending, and
confirmation policy remain in the application layer.

## Design principles

- OOP: immutable IR and generated value objects.
- SRP: parser, validator, generator, builder, and CLI responsibilities are
  split by reason to change.
- OCP: dialects, layouts, naming, type mapping, and emitters are isolated
  behind small contracts.
- ISP: account, scanner, simulator, subscriber, PDA, and relation ports are
  separate.
- DIP: generated clients depend on ports, not RPC implementations.
- GRASP Information Expert: emitters own only the IR section they generate.
- Strategy: naming and layout.
- Factory: dialect detection and parser selection.
- Adapter: CLI, build_runner, and application callback adapters.
- Facade: public generator and generated program client.
- Composite: nested accounts and nested wire types.

Patterns are not introduced where a function or immutable value object is
enough.

Generated support is repeated per IDL by design. This costs output size but
keeps the published package development-only and makes generated SDKs portable
to Dart VM, Flutter, and web consumers.

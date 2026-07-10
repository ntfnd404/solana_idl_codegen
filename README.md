# solana_idl_codegen

Strict Anchor IDL → self-contained, transport-neutral Dart SDK generation for
Solana programs.

`solana_idl_codegen` is a development dependency. It validates Anchor IDL files
and generates Dart SDKs that import only `dart:*` libraries and neighboring
generated files. Applications keep ownership of RPC, websocket, wallet,
transaction, fee-payer, blockhash, signing, sending, and confirmation policy.

The generator accepts arbitrary supported Anchor IDL documents.
Project-specific domain boundaries, RPC clients, wallets, transaction
builders, and deployment workflows stay in the consuming application.

## Install

```yaml
dev_dependencies:
  build_runner: ^2.15.0
  solana_idl_codegen: ^0.1.0
```

Put IDLs under `lib/idl/` and enable exactly one builder.

## Quick start

1. Add an Anchor IDL:

   ```text
   lib/idl/my_program.json
   ```

2. Add `build.yaml`:

   ```yaml
   targets:
     $default:
       builders:
         solana_idl_codegen:bundled:
           enabled: true
           generate_for:
             - lib/idl/**.json
           options:
             type_prefix: auto
             type_suffix: ""
   ```

3. Generate:

   ```shell
   dart run build_runner build
   ```

4. Import the generated SDK:

   ```dart
   import 'generated/my_program.solana.dart';
   ```

5. Build an instruction and hand its wire record to your application-owned
   transaction layer:

   ```dart
   final request = MyProgramCreateMessageRequest(
     args: MyProgramCreateMessageArgs(
       id: BigInt.from(7),
       text: 'hello',
     ),
     accounts: MyProgramCreateMessageAccounts(
       authority: authority,
       stateMessage: stateMessage,
       optionalReferrer: null,
       systemProgram: systemProgram,
     ),
   );

   final wire = request.instruction().toWire();
   ```

The generated `wire` record contains only program address, ordered account
metas, and instruction data bytes. Converting it into a transaction
instruction, adding signers, recent blockhash, fee payer, pre/post
instructions, sending, and confirmation are application responsibilities.

## Builder configuration

Builder keys use the `build_config` scalar format `<package>:<builder>`.
The colon is part of the key; it is not YAML nesting.

| Key | Use when | Output |
| --- | --- | --- |
| `solana_idl_codegen:bundled` | You want the simplest setup | `lib/generated/<idl>.solana.dart` |
| `solana_idl_codegen:modular` | You want smaller focused libraries | Barrel plus support/types/accounts/instructions/resolution/events/errors/client files |

Package-specific options:

| Option | Type | Default | Meaning |
| --- | --- | --- | --- |
| `type_prefix` | `String` | `auto` | `auto` derives a Dart prefix from the program name; a custom value overrides it |
| `type_suffix` | `String` | `""` | Optional suffix appended to generated public type names |

Target-level `build_config` controls:

| Control | Meaning |
| --- | --- |
| `enabled` | Must be `true` because builders are opt-in |
| `generate_for` | Glob of IDL JSON files to process; default is `lib/idl/**.json` |

Enable exactly one builder for an input. Bundled and modular both own the same
barrel output, so enabling both for the same IDL is an output conflict.

### Bundled layout

Bundled is the recommended simple layout. It writes one
`lib/generated/<path>.solana.dart` SDK per IDL.

```yaml
targets:
  $default:
    builders:
      solana_idl_codegen:bundled:
        enabled: true
        generate_for:
          - lib/idl/**.json
        options:
          type_prefix: auto
          type_suffix: ""
```

### Modular layout

Modular writes a barrel plus support, types, accounts, instructions,
resolution, events, errors, and client libraries.

```yaml
targets:
  $default:
    builders:
      solana_idl_codegen:modular:
        enabled: true
        generate_for:
          - lib/idl/**.json
        options:
          type_prefix: auto
          type_suffix: ""
```

Run:

```shell
dart run build_runner build
```

When switching layouts, remove known generated outputs first:

```shell
dart run solana_idl_codegen clean --output lib/generated
dart run build_runner build
```

## CLI

```shell
dart run solana_idl_codegen validate lib/idl/program.json

dart run solana_idl_codegen generate lib/idl/program.json \
  --input-root lib/idl \
  --output lib/generated \
  --layout modular \
  --type-prefix auto

dart run solana_idl_codegen generate lib/idl/program.json \
  --input-root lib/idl \
  --output lib/generated \
  --check

dart run solana_idl_codegen clean --output lib/generated
```

The CLI accepts multiple IDLs as one batch. It detects output collisions,
changed files, stale tool-owned outputs for requested IDL stems, and path
escape. `clean` deletes only files containing the stable `solana_idl_codegen`
marker; handwritten files are preserved.

Exit codes are `0` success, `1` input/IDL/generation failure, `2` invalid CLI
configuration, `3` check drift, and `4` lock/recovery failure.

## Generated SDK

Every public generated declaration uses the program prefix:

```dart
final request = ExampleProgramCreateMessageRequest(
  args: ExampleProgramCreateMessageArgs(
    id: BigInt.from(7),
    text: 'hello',
  ),
  accounts: ExampleProgramCreateMessageAccounts(
    authority: authority,
    stateMessage: messagePda,
    optionalReferrer: null,
    systemProgram: systemProgram,
  ),
);

final instruction = request.instruction();
final wire = instruction.toWire();
```

The generated SDK provides:

- immutable models, sealed enums, value equality, and Borsh codecs;
- typed instruction args, resolved accounts, immutable requests, and remaining
  accounts;
- tri-state account overrides and async account resolution;
- account `fetch`, `fetchNullable`, `fetchMultiple`, and `all`;
- typed views for read-only instructions with return values;
- invocation-stack event decoding and closeable typed subscriptions;
- typed IDL errors and unknown-code preservation;
- narrow account, scanner, simulator, subscriber, PDA, and relation ports with
  callback adapters.

It deliberately does not model wallets, signers, blockhashes, fee payers,
transactions, sending, confirmation, or pre/post instructions. Those belong to
the application transaction layer.

### Application-owned adapters

Generated instructions expose structural wire data:

```dart
final wire = request.instruction().toWire();
```

Your adapter converts that record into whichever Solana transaction package
you use. The generated SDK does not care whether the application uses
`package:solana`, a mobile wallet adapter, a hardware wallet bridge, or a
custom RPC client.

The same boundary applies to errors: the transaction/RPC layer owns transport
failure policy, then can pass logs or custom error payloads into generated
program-error parsers to produce typed program exceptions.

The [Flutter example](example/) has Android, iOS, web, Linux, macOS, and
Windows targets. It composes two generated SDKs, uses mock mode by default,
and includes an optional application-owned `package:solana` account adapter.
That adapter is example code, not generator API.

## IDL compatibility

The contract is based on schema features, not an inferred producer version.
Fixtures track legacy pre-0.30 and modern `metadata.spec == "0.1.0"` IDLs from
Anchor 0.30.1, 0.31.1, and 1.0.2 provenance.

Supported wire types include integers through 256 bits, f32/f64, bool,
strings, bytes, pubkeys, Option, SPL COption, vectors, arrays, generics,
const-generic array lengths, aliases, structs, tuple structs, and Rust enums.
`u64` through `i256` map to `BigInt`; bytes map to immutable `Uint8List`.

Only Borsh serialization is emitted. Bytemuck, bytemuckunsafe, and custom
serialization are recognized and rejected explicitly. Unknown fields, wrong
JSON types, unresolved references, recursive layouts, discriminator ambiguity,
and unsupported constants stop generation with a stable diagnostic and JSON
path. There is no lenient mode and no `dynamic` fallback.

## Multiple IDLs and generated licensing

Per-program support code is intentionally repeated so consumers do not need a
runtime package. Program prefixes avoid normal symbol collisions. Two IDLs with
the same program name should use `type_prefix` or import prefixes.

Generated files carry an MIT SPDX notice, generator version, raw source
SHA-256, and semantic IR SHA-256. They contain no timestamp or absolute path.
The project license permits generated artifacts to be copied, modified, and
distributed without a runtime attribution dependency.

## Design and comparison scope

The generator targets stronger static typing, validation, deterministic output,
transport boundaries, and generated documentation than `dart-coral-xyz`. It
does not attempt to replace that project's dynamic IDL, Quasar/Pinocchio, or
SVM APIs.

## Backlog

Multiparser support for non-Anchor Solana IDL dialects is intentionally out of
scope for the current Anchor backend. A future multiparser layer should define
an `IdlParser` registry/factory, choose dialect detection policy, add parsers
for Shank, Codama, and other formats, normalize them into the shared IR, and
expand the external fixture matrix. The design should not assume a closed set
of dialects: consumers may need to register any number of custom IDL parsers,
so public parser extension points need a stable or explicitly experimental IR
contract before they are exposed.

Validation diagnostic priority can be refined after the current resolver/path
matching work lands. Canonical account path collisions should eventually be
reported before generated Dart member naming collisions, while preserving
`IDL_DART_ACCOUNT_MEMBER_COLLISION` for pure Dart API name clashes. That change
should be made as a focused validation-pipeline update with fixture expectation
updates, because it changes which stable diagnostic is reported first for some
invalid IDLs.

Normal development and pull-request CI do not require Node, npm, Rust,
Anchor CLI, Solana CLI, Docker, or a local validator.

See:

- [Usage guide](doc/usage.md)
- [Configuration](doc/configuration.md)
- [Architecture](doc/architecture.md)
- [Generated API](doc/generated-api.md)
- [Testing and reference provenance](doc/testing.md)
- [Publishing](doc/publishing.md)

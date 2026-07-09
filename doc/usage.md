# Usage guide

This guide shows how to use `solana_idl_codegen` from a consumer project. The
package is a dev dependency: it reads checked-in Anchor IDL JSON files and
writes generated Dart SDK files into your project.

The generated SDK is transport-neutral. It does not know which RPC, wallet,
signer, transaction, or confirmation package your application uses.

## 1. Install

Add the generator and `build_runner` to `dev_dependencies`:

```yaml
dev_dependencies:
  build_runner: ^2.15.0
  solana_idl_codegen: ^0.1.0
```

Put IDL files under `lib/idl/`:

```text
lib/
  idl/
    my_program.json
```

## 2. Choose a layout

Use exactly one builder for the same input files.

### Bundled layout

Bundled is the simplest option. It generates one Dart file per IDL:

```text
lib/generated/my_program.solana.dart
```

`build.yaml`:

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

Modular generates a barrel file plus focused files for support, models,
instructions, accounts, resolution, events, errors, and clients:

```text
lib/generated/my_program.solana.dart
lib/generated/my_program.solana.support.dart
lib/generated/my_program.solana.types.dart
lib/generated/my_program.solana.accounts.dart
lib/generated/my_program.solana.instructions.dart
lib/generated/my_program.solana.resolution.dart
lib/generated/my_program.solana.events.dart
lib/generated/my_program.solana.errors.dart
lib/generated/my_program.solana.client.dart
```

`build.yaml`:

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

The key format is the `build_config` scalar `<package>:<builder>`. The colon is
part of the builder key; it is not YAML nesting.

## 3. Builder options

Only two package-specific options exist:

| Option | Default | Valid values | Meaning |
| --- | --- | --- | --- |
| `type_prefix` | `auto` | `auto` or a non-empty Dart identifier | Prefix for generated public type names. `auto` derives it from the IDL program name. |
| `type_suffix` | `""` | Empty or a Dart identifier | Optional suffix appended to generated public type names. |

`generate_for` is handled by `build_config`, not by this package. Use it to
select which IDL JSON files the builder should process.

Use a custom `type_prefix` when two IDLs have the same program name or when you
want generated symbols to follow your project naming:

```yaml
options:
  type_prefix: TokenSwap
  type_suffix: V1
```

This produces names such as `TokenSwapCreatePoolV1Request`.

## 4. Generate with build_runner

Run:

```shell
dart run build_runner build
```

For watch mode:

```shell
dart run build_runner watch
```

When switching between bundled and modular layouts, clean tool-owned generated
files first:

```shell
dart run solana_idl_codegen clean --output lib/generated
dart run build_runner build
```

`clean` removes only files with this tool's generated marker. Handwritten files
are preserved.

## 5. Generate with the CLI

Validate one or more IDL files:

```shell
dart run solana_idl_codegen validate lib/idl/my_program.json
```

Generate bundled output:

```shell
dart run solana_idl_codegen generate lib/idl/my_program.json \
  --input-root lib/idl \
  --output lib/generated \
  --layout bundled
```

Generate modular output:

```shell
dart run solana_idl_codegen generate lib/idl/my_program.json \
  --input-root lib/idl \
  --output lib/generated \
  --layout modular
```

Check generated files without writing:

```shell
dart run solana_idl_codegen generate lib/idl/my_program.json \
  --input-root lib/idl \
  --output lib/generated \
  --layout modular \
  --check
```

Clean generated files:

```shell
dart run solana_idl_codegen clean --output lib/generated
```

CLI exit codes:

| Code | Meaning |
| --- | --- |
| `0` | Success |
| `1` | Input I/O, IDL validation, or generation failure |
| `2` | Invalid command or configuration |
| `3` | `--check` detected drift |
| `4` | Lock or transaction recovery failure |

## 6. Import generated code

Bundled and modular layouts both expose the same barrel import:

```dart
import 'package:my_app/generated/my_program.solana.dart';
```

Generated public names use the program prefix:

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

final instruction = request.instruction();
final wire = instruction.toWire();
```

`wire` contains:

- program address bytes;
- ordered account metas;
- instruction data bytes.

Your application converts this wire record into the instruction type expected
by the Solana transaction package you chose.

## 7. Adapter example

The generated SDK intentionally has no `package:solana` dependency. A consumer
adapter can map generated wire data into any transaction library:

```dart
AppInstruction toAppInstruction(MyProgramInstruction instruction) {
  final wire = instruction.toWire();

  return AppInstruction(
    programId: AppAddress.fromBytes(wire.programAddress),
    accounts: [
      for (final meta in wire.accounts)
        AppAccountMeta(
          address: AppAddress.fromBytes(meta.address),
          isSigner: meta.isSigner,
          isWritable: meta.isWritable,
        ),
    ],
    data: wire.data,
  );
}
```

The same rule applies to account reads, simulation, events, and errors:
generated code exposes narrow ports and typed parsers; your application owns
the concrete RPC and wallet implementation.

## 8. Programmatic API

You can call the generator directly from Dart tooling:

```dart
import 'package:solana_idl_codegen/solana_idl_codegen.dart';

void main() {
  const generator = SolanaIdlGenerator();

  final source = /* read IDL JSON */;
  final validation = generator.validateString(
    source,
    sourceName: 'my_program.json',
  );

  if (!validation.isValid) {
    for (final diagnostic in validation.diagnostics) {
      print(diagnostic);
    }
    return;
  }

  final output = generator.generateString(
    source,
    sourceName: 'my_program.json',
    options: const GenerationOptions(layout: OutputLayout.modular),
  );

  for (final file in output.files) {
    print('${file.path}: ${file.content.length} bytes');
  }
}
```

The programmatic API is useful for custom developer tooling. Normal consumers
usually use `build_runner` or the CLI.

## 9. What the package does not do

`solana_idl_codegen` does not:

- fetch IDLs from chain or from RPC;
- choose a Solana RPC package;
- choose a wallet or signer package;
- build, sign, send, or confirm transactions;
- provide a dynamic IDL runtime API;
- silently coerce unsupported IDL features into `dynamic`.

Provide the IDL file locally, generate a typed SDK, and keep transport policy in
your application.

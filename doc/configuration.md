# Configuration

For an end-to-end setup walkthrough with copy-pasteable examples, see the
[usage guide](usage.md). This page is the reference for every supported
configuration option.

## Builder keys

`build_config` identifies a builder with one scalar key in the
`<package>:<builder>` format. The colon is part of the identifier; it does not
represent YAML nesting.

| Key | Layout | Outputs |
| --- | --- | --- |
| `solana_idl_codegen:bundled` | Bundled | One `_solana.dart` SDK |
| `solana_idl_codegen:modular` | Modular | Barrel plus eight focused libraries |

Both builders are opt-in (`auto_apply: none`) and select
`lib/idl/**.json` by default. Enable exactly one builder for an input. Bundled
is the recommended simple layout and the default used by the CLI.

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

The target-level controls accepted by `build_config` are:

| Control | Type | Default | Meaning |
| --- | --- | --- | --- |
| `enabled` | `bool` | Derived from `auto_apply` (`false` here) | Enables this builder for the target |
| `generate_for` | glob list/map | `lib/idl/**.json` | Restricts selected IDL assets |

The complete set of package-specific `options` is:

| Option | Type | Default | Validation |
| --- | --- | --- | --- |
| `type_prefix` | `String` | `auto` | `auto` or a non-empty Dart identifier |
| `type_suffix` | `String` | empty | Empty or a Dart identifier |

Unknown options, wrong value types and invalid identifiers fail configuration.
Layout is selected by the builder key; there is no `layout` or unsafe `strict`
builder option. Builders use only `BuildStep` and never import `dart:io`.

When switching layouts, remove the previous tool-owned outputs first:

```shell
dart run solana_idl_codegen clean --output lib/generated
dart run build_runner build
```

The experimental pre-0.1 builder keys have been removed without aliases.
Migrate to the `bundled` or `modular` keys shown above.

## CLI reference

All positional `<idl...>` values are required and may contain multiple files.

```text
solana_idl_codegen validate <idl...>
  --diagnostics human|json              default: human

solana_idl_codegen generate <idl...>
  --input-root PATH                     default: lib/idl
  --output PATH                         default: lib/generated
  --layout bundled|modular              default: bundled
  --type-prefix auto|DART_IDENTIFIER    default: auto
  --type-suffix DART_IDENTIFIER         default: empty
  --diagnostics human|json              default: human
  --check                               default: false

solana_idl_codegen clean
  --output PATH                         default: lib/generated
  --check                               default: false
```

Every generate input must resolve inside `input-root`. Its relative path is
preserved under `output`. `generate --check` performs no writes and reports
missing, changed and stale files belonging to the requested IDL stems.
`clean --check` reports all tool-owned files without deleting them. Foreign
files are never removed.

Exit codes:

| Code | Meaning |
| --- | --- |
| `0` | Success |
| `1` | Input I/O, IDL validation or generation failure |
| `2` | Invalid command or configuration |
| `3` | `--check` detected drift |
| `4` | Lock or transaction recovery failure |

## Programmatic API

`GenerationOptions` accepts:

| Property | Type | Default |
| --- | --- | --- |
| `layout` | `OutputLayout` | `bundled` |
| `typePrefix` | `String` | `auto` |
| `typeSuffix` | `String` | empty |

`SolanaIdlGenerator` accepts `IdlParseLimits`. `IdlParseLimits.defaults` is:

| Limit | Default |
| --- | ---: |
| `maxSourceBytes` | 16 MiB |
| `maxJsonDepth` | 128 |
| `maxDeclarations` | 10,000 |
| `maxFieldsPerDeclaration` | 4,096 |
| `maxTotalFields` | 100,000 |
| `maxDocsBytes` | 4 MiB |
| `maxIdentifierLength` | 512 |

All limits must satisfy the constructor assertions. Unsupported IDL data
always fails; there is no lenient mode.

## Determinism and ownership

Generated output uses LF, stable ordering and no timestamp or absolute source
path. A generated header identifies files owned by this tool and includes the
generator version, source SHA-256, semantic IR SHA-256 and MIT SPDX notice.
Generation only replaces outputs for requested IDL stems; global deletion
requires `clean`. Writes use a canonical-output lock, same-filesystem staging
and a recovery manifest.

Output-affecting dependencies use narrow compatible ranges, following pub.dev
package guidance. Byte-identical output is guaranteed for the same generator
version and the same resolved dependency versions. A dependency update is
validated by generation goldens before release.

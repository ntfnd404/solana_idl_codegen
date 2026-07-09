# Maintainer-only reference vector verification

This directory is intentionally excluded from the pub archive and ordinary
pull-request CI.

The checked-in Dart verifier downloads the exact upstream files recorded in
`test/reference_vectors/provenance.json` and checks their SHA-256 values:

```shell
dart run tool/reference_vectors/verify_upstream.dart
```

Run it manually before changing committed reference-vector provenance, or from
a scheduled maintainer workflow. Do not make this verifier a normal PR
requirement, because it depends on network access to upstream sources.

Do not add Node, npm, Anchor CLI, Solana CLI, Rust, Docker, or a validator as a
package dependency or ordinary CI requirement.

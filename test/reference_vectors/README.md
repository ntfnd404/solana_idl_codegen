# Reference vectors

These committed vectors exercise generator output without requiring Node,
Rust, Anchor CLI, Solana CLI, or a validator in normal development and CI.

`provenance.json` records the exact Anchor release tag commit, upstream source,
source SHA-256, typed input, and expected wire bytes. The modern alias vector
is derived directly from Anchor's versioned `coder-instructions.spec.ts`: the
test fixes the discriminator to `00..07` and the alias input to `[1, 2, 3]`.
The legacy vector additionally applies Anchor's documented
`sha256("global:<instruction>")[0..8]` discriminator rule.

The optional maintainer tooling under `tool/reference_vectors/` verifies
upstream source checksums and is excluded from the published package. It is
not part of the normal PR test path.

`runtime_matrix.json` composes the verified Anchor account/event layouts and
the SPL fixed-span COption layout. Entries marked `generator-contract` test
transport-neutral behavior such as typed PDA seed bytes; they are deliberately
not presented as independently generated upstream vectors.

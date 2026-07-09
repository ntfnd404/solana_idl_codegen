# Backlog

This file tracks deliberate follow-up work that is not required for the
current publishable `0.1.0` package, but should not be forgotten.

## Account-data PDA seed type policy

Mango V4 remains a skipped real-world compatibility fixture because it contains
account-data PDA seeds where the IDL does not provide enough type metadata for
the current generated resolver policy.

Current behavior:

- the generator rejects the fixture with `IDL_PDA_ACCOUNT_DATA_TYPE`;
- no fallback to `dynamic`, raw untyped bytes, or guessed account layout is
  used;
- Drift and OpenBook remain generation-only real-world fixtures.

The missing design decision is how the generator should model account-data PDA
seeds when the IDL references account fields but does not fully identify a
local generated account codec or an explicit external seed resolver contract.

Acceptable future directions:

- require explicit metadata or generator configuration that maps the seed
  account path to a generated account type;
- require an explicit external account-data seed resolver for that path;
- add a conservative legacy compatibility rule only if it is backed by
  Anchor-compatible fixtures and does not introduce guessing.

Non-goals:

- do not silently treat unknown account-data seeds as raw `Uint8List`;
- do not introduce `dynamic` or `Object?` into the public generated API;
- do not make RPC or account fetching policy part of generated SDK runtime.

# Backlog

This file tracks deliberate follow-up work that is not required for the
current publishable `0.1.0` package, but should not be forgotten.

## Remove generated lint suppressions

Generated libraries should satisfy common consumer lint sets through emitted
code and feature-aware imports/helpers instead of broad file suppressions.

Progress:

- [x] remove the unused `empty_constructor_bodies` suppression;
- [x] emit block bodies for assignment branches and remove
  `curly_braces_in_flow_control_structures`;
- [ ] use initializing formals where no defensive copy or validation is
  required, then remove `prefer_initializing_formals`;
- [ ] emit super parameters for forwarding exception constructors, then remove
  `use_super_parameters`;
- [ ] derive modular imports from the declarations actually emitted, then
  remove `unused_import`;
- [ ] emit private helpers such as `_programListEquals` and `_startsWith` only
  when referenced, then remove `unused_element`.

Every removal must be covered by bundled and modular analyzer tests using the
lint explicitly, plus generic, checked-in example, and external IDL fixtures.
Do not replace targeted suppressions with `type=lint` or consumer-side analyzer
configuration.

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

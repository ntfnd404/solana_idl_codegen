# External IDL fixtures

These fixtures are copied from public protocol repositories to keep the
generator honest against real-world Anchor IDL shapes.

The JSON files remain valid JSON. Source links, commits, license notes, and
test mode live in `provenance.json` instead of JSON comments.

Drift and OpenBook are generation-only fixtures. They do not claim byte-level
parity; they prove the generator can validate and emit SDKs for large
real-world IDL surfaces.

Mango currently remains a skipped compatibility candidate because it contains
account-data PDA seeds without enough type metadata for the generated resolver
policy.

Do not add Node/npm regeneration tooling here. Ordinary tests consume committed
fixtures only.

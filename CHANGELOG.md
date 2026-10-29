# Changelog

All notable changes are recorded here. This project follows Semantic
Versioning once a public release is tagged; the contract version is governed
separately by the compatibility rules in `docs/contract-v1.md`.

## Unreleased

- Repair downstream Rivet/Glaze compatibility workflow commands after the
  GitHub owner rename; require run URLs and exact SHAs in release handoff,
  and protect canonical downstream identities with a documentation test.
- Update the contributor guide to the renamed family language policy.
- Define the canonical five-repository family architecture, including
  Commerce's provider/issuance boundary, Permit integration direction,
  change routing, release sequencing, and independent trust domains.
- Add a documentation gate for local links, the five repository names, and
  every Keel maintainer entry point to the canonical architecture.
- Close out the `tests/documentation` module-path collision with rivet
  v0.11.0: the colliding module was renamed to `tests/keel-documentation`
  on main (never present in any tagged release), every remaining `tests/`
  module is renamed to a `keel-`-prefixed name, and a collection-name guard
  keeps the top-level `tests` collection — shared by every installed
  package — free of unprefixed Keel module paths.

## 0.3.1 - 2026-10-12

- Make schema names transport identities rather than ASCII source-language
  identifiers: preserve Racket `?`, `!`, `->`, spaces, and Unicode, with a
  255-byte UTF-8 bound and rejection of control, format, and surrogate code
  points. Consumer code generators continue to own collision-checked local
  identifiers.

## 0.3.0 - 2026-10-11

- Rename the package and collection to `keel` (was `racket-app-core` /
  `app-core`). The repository renames with it; GitHub redirects the old
  URL. No consumers exist yet, so this is the cheapest possible moment —
  the value contract, tags, golden corpus, and schema vocabulary are
  unchanged.

## 0.2.0 - 2026-10-11

- Add a transport-neutral schema contract for scalar and compound types,
  records, enums, commands, events, and states, with validated references and
  deterministic Keel encoding.

## 0.1.0 - 2026-10-11

- Define the Keel v1 value union and canonical encoding.
- Add structured errors and shared lifecycle vocabulary.
- Enforce the documented Keel value invariant at the structured-error
  constructor boundary.
- Add golden, rejection, budget, and deterministic property tests.

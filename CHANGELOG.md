# Changelog

All notable changes are recorded here. The format is based on
[Keep a Changelog](https://keepachangelog.com/), and this project adheres to
[Semantic Versioning](https://semver.org/) once a public release is tagged; the
contract version is governed separately by the compatibility rules in
`docs/contract-v1.md`.

## [Unreleased]

### Added

- Add transport-neutral schema compatibility checking: `app-schema-changes`
  compares two schema revisions and reports each `breaking` or `compatible`
  difference at a stable dotted path, and `schema-compatible?` answers whether
  peers built against the old revision can keep operating against the new one.
  Closed enums, command parameters, declared error codes, and required record
  fields are treated conservatively; optional record fields, new records,
  commands, events, and states are compatible additions. This gives Rivet and
  Glaze one shared rule set instead of two protocol-local approximations.

- Add an on-demand official Racket package catalog release gate that verifies
  `keel` resolves to the renamed GitHub source and installs by catalog package
  name from a fresh Racket 9.3 runner, before attempting downstream
  Rivet/Glaze compatibility. Document the maintainer-only published metadata
  repair and enforce current AGENTS.md dispatch targets.

- Define the canonical five-repository family architecture, including
  Commerce's provider/issuance boundary, Permit integration direction,
  change routing, release sequencing, and independent trust domains.

- Add a documentation gate for local links, the five repository names, and
  every Keel maintainer entry point to the canonical architecture.

- Bring the README up to the family front-door standard in both languages:
  CI/Racket/license/version badges, a Quick Start with the catalog install
  and a runnable round trip, an explicit License section, direct links to the
  sibling repositories, and a pointer to keel.jrtx.site.

- Give the contract homepage a schema section covering the schema vocabulary
  and the compatibility rules, plus links to the four sibling repositories.

- Give the Scribble manual a stable `keel` anchor and a Further reading
  section pointing at the normative contract, the repository, and the
  contract homepage.

### Changed

- Document the remaining public exports in the Scribble manual: the seven
  `app-schema` accessors, `schema-type->app-value`, the lifecycle constants,
  and `request-terminal-outcomes`.

- Make the documentation gate pass for an installed source package, which does
  not contain `.github`: link the catalog workflow by URL and require the
  workflow file only in a repository checkout. Remove stale fixed test counts
  from the README, Chinese README, CONTRIBUTING, and AGENTS, and state the
  tested Racket versions instead of "and newer".

- Preserve CI evidence for every `main` commit instead of cancelling earlier
  builds, while continuing to cancel superseded pull request checks; release
  and downstream compatibility gates remain unchanged.

- Update the contributor guide to the renamed family language policy.

- Assert in CI that the rendered manual is a real artifact: the Scribble
  build must produce a nonempty `keel/index.html`, not just exit zero.

### Fixed

- Reject eq-based maps whose string keys collide by value. `app-value?` used to
  accept a `hasheq` holding two distinct string objects with equal contents;
  encoding emitted duplicate keys that `decode-app-value` rejects, so
  encode/decode was not total over `app-value?`. Such maps are now rejected
  before encoding and covered by a regression test.

- Move the portable code/message shape check into the `app-error` struct guard.
  Requiring `(submod keel/error private)` could previously mint an
  `app-error?` value with a non-kebab-case code or a non-string message;
  the private constructor now enforces the same invariants as the public one.

- Repair downstream Rivet/Glaze compatibility workflow commands after the
  GitHub owner rename; require run URLs and exact SHAs in release handoff,
  and protect canonical downstream identities with a documentation test.

- Close out the `tests/documentation` module-path collision with rivet
  v0.11.0: the colliding module was renamed to `tests/keel-documentation`
  on main (never present in any tagged release), every remaining `tests/`
  module is renamed to a `keel-`-prefixed name, and a collection-name guard
  keeps the top-level `tests` collection — shared by every installed
  package — free of unprefixed Keel module paths.

## [0.3.1] - 2026-10-12

### Changed

- Make schema names transport identities rather than ASCII source-language
  identifiers: preserve Racket `?`, `!`, `->`, spaces, and Unicode, with a
  255-byte UTF-8 bound and rejection of control, format, and surrogate code
  points. Consumer code generators continue to own collision-checked local
  identifiers.

## [0.3.0] - 2026-10-11

### Changed

- Rename the package and collection to `keel` (was `racket-app-core` /
  `app-core`). The repository renames with it; GitHub redirects the old
  URL. No consumers exist yet, so this is the cheapest possible moment —
  the value contract, tags, golden corpus, and schema vocabulary are
  unchanged.

## [0.2.0] - 2026-10-11

### Added

- Add a transport-neutral schema contract for scalar and compound types,
  records, enums, commands, events, and states, with validated references and
  deterministic Keel encoding.

## [0.1.0] - 2026-10-11

### Added

- Define the Keel v1 value union and canonical encoding.
- Add structured errors and shared lifecycle vocabulary.
- Enforce the documented Keel value invariant at the structured-error
  constructor boundary.
- Add golden, rejection, budget, and deterministic property tests.

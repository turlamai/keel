# TuringLambdaAI family architecture

This document is the canonical coordination contract for Keel, Rivet, Glaze,
Permit, and Commerce. Its location in the Keel repository is a documentation
convenience: Keel is not the root package of the family, and Permit and
Commerce do not depend on it.

Each repository owns an independently versioned product. An application is the
composition root and selects only the parts it needs.

## Dependency graph

```text
Product
├── presentation/runtime ──> Rivet or Glaze ──> Keel
├── local authorization ───> Permit
└── online commerce ────────> Commerce client ──> Commerce service
                                                    ├── provider adapters
                                                    └── Permit issuer adapter
                                                          └── permit/issuer
```

The important negative edges are:

```text
Rivet  -X-> Glaze, Permit, Commerce
Glaze  -X-> Rivet, Permit, Commerce
Keel   -X-> Rivet, Glaze, Permit, Commerce
Permit -X-> Rivet, Glaze, Keel, Commerce
Commerce core/default facade -X-> Rivet, Glaze, Keel, Permit
```

The explicit Commerce issuer adapter may consume `permit/issuer`; Permit never
imports Commerce. A future Commerce operator application may use Glaze as its
UI framework, but that application remains outside the headless Commerce core.
Neither case transfers domain ownership.

## Ownership

| Repository | Owns | Must not absorb |
| --- | --- | --- |
| Keel | Transport-neutral application values, canonical encoding, structured errors, lifecycle names, schema vocabulary, and the cross-runtime corpus | Transport frames, renderers, permissions, packaging, or commercial semantics |
| Rivet | First-party native hosts, RVT1, Racket embedding, native system/distribution services, and typed native clients | WebView application semantics, product rights, checkout, or commercial operations |
| Glaze | Native WebView hosts, GLZ1, resource delivery, capability enforcement, web-frontend tooling, and WebView-oriented distribution | Native-control abstraction, product rights, checkout, or commercial operations |
| Permit | Signed-rights vocabulary, credential and trust protocols, offline verification, pure policy evaluation, and issuer primitives | Prices, payment evidence, accounts, delivery workflows, UI/runtime services, or update signing |
| Commerce | Provider adapters, authenticated payment journal, commercial projections, offer-to-rights intent, issuance workflow, claim delivery, reconciliation, and operator audit | Payment acquiring, tax/MoR promises, identity-provider behavior, client authorization, UI frameworks, or Permit wire semantics |

The product still owns its user experience, feature meaning, commercial
promises, choice of offline versus managed behavior, and the decision to adopt
each optional component. Commerce stores versioned provider mappings and
fulfilment policy, but it does not invent a product's feature model. An account
or identity provider, when one exists, owns login and recovery; Commerce uses
opaque stable subject identifiers instead of becoming an account system.

## Composition profiles

Small products should be able to start with the smallest honest composition:

- a free or non-commercial app uses Rivet or Glaze, and therefore Keel;
- a manually fulfilled or fully offline paid app adds Permit, without Commerce;
- an online-sale app adds the Commerce client and service;
- timely refund, subscription, or device enforcement uses an explicit managed
  mechanism such as short-lived Permit activation leases. It never pretends a
  permanently offline credential can be remotely revoked.

A product normally chooses Rivet or Glaze, not both. Shared product logic that
truly must support both frameworks stays in an application-owned Racket
library until a transport-neutral contract has been proven and belongs in
Keel.

## Change routing

Route a proposed change to the lowest owner that can express it without
knowing a renderer, carrier, provider, or particular product:

1. Shared values, schema, lifecycle, or structured-error vocabulary starts in
   Keel.
2. RVT1, native controls, embedding, device communication, and first-party
   native host lifecycle stay in Rivet.
3. GLZ1, WebView resources/messages, frontend bindings, and browser development
   adapters stay in Glaze.
4. Credential, trust, entitlement, activation, trial, seat-limit, and local
   authorization semantics start in Permit.
5. Provider authentication, checkout orchestration, payment projections,
   refunds, subscription operations, rights intents, issuance/delivery, and
   reconciliation start in Commerce.
6. Product-specific workflow and policy stays in the product until repeated
   use proves a narrower reusable contract.

If a Commerce use case needs a new signed meaning, specify and release that
meaning in Permit first. If Rivet and Glaze need the same application-boundary
value, specify and release it in Keel first. Do not copy a type or protocol into
two repositories to avoid sequencing the upstream change.

## Integration and release order

Coordinated changes are sequential, not simultaneous speculative edits:

```text
Keel change
  -> Keel tests + normative text + release
  -> Rivet and Glaze latest-package suites
  -> affected product schema/build/package checks

Permit change
  -> Permit tests + vectors/specification + release
  -> Commerce issuer-adapter suite, when affected
  -> product verification and policy acceptance tests

Commerce change
  -> Commerce event/journal/outbox/adapter evidence + release
  -> affected product checkout/claim acceptance tests

Rivet or Glaze change
  -> local framework and platform gates + release
  -> affected product build/package/launch evidence
```

Every family package dependency declares a version floor equal to the lowest
version its suite actually covers. Development follows the latest published
family packages; release builds pin the exact versions they ship. A red
upstream, consumer, or family-compatibility run stops new feature work until it
is fixed forward or the upstream release is corrected.

The top-level `tests/` collection is shared by every package in one Racket
installation: two packages claiming the same module path there cannot
coinstall. Each family package namespaces its test modules with its own
prefix (`keel-` here, enforced by Keel's collection-name guard) so any set of
family packages always installs together.

The active implementation queue remains local to each repository:

- Keel wire semantics: `docs/contract-v1.md`
- Rivet: `docs/desktop-closeout-mobile-plan.md`
- Glaze: `docs/1.0-plan.md`
- Permit: `ROADMAP.md`
- Commerce: `ROADMAP.md`

Cross-repository coordination belongs in a GitHub issue with the upstream
owner, compatibility impact, release order, and downstream evidence. Chat
history is never the only handoff.

## Trust domains

Provider API/webhook secrets, Commerce claim/session secrets, Commerce data
encryption keys, Permit credential-signing keys, update-signing keys, and OS
publisher credentials are separate trust domains. They use separate keys,
identifiers, access policies, storage, and rotation procedures. A convenience
integration may pass signed artifacts or opaque identifiers across a boundary;
it may not collapse key custody or make a framework process an issuer.

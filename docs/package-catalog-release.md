# Official Racket package catalog release gate

**Current blocker: [Keel issue #8](https://github.com/turlamai/keel/issues/8).**
The official `keel` catalog metadata still points at the old GitHub
owner `turinglambdaai`, which can break a fresh `raco pkg install` in
Rivet/Glaze before any application tests execute. A correct GitHub README
or URL redirect does **not** change the separately published catalog
record. No local worktree or CI green badge can substitute for that
external correction.

## Maintainer-only catalog repair

1. Open the [official package record](https://pkgs.racket-lang.org/package/keel),
   sign in with the account which manages the **existing** `keel` package
   and edit its source to `https://github.com/turlamai/keel.git#main`
   (preserve the package name `keel`, license, version metadata and
   published dependency identity). Do not create a shadow package.
2. Wait for the published record to reflect the canonical source;
   record the change and the actual source shown in the catalogue.
   An HTML/REST GitHub redirect is not equivalent to a fresh package
   manager install. No signer secrets or admin credentials belong in Git.
3. Inspect the catalog on a clean Racket installation:

   ```sh
   raco pkg catalog-show --catalog https://pkgs.racket-lang.org keel
   ```

   Confirm it displays `https://github.com/turlamai/keel.git#main`,
   not `https://github.com/turinglambdaai/keel.git#main`.
4. Run [Published package catalog release gate](../.github/workflows/catalog-release-gate.yml)
   **manually** in GitHub Actions. This deliberately fails if the official
   catalog is stale; it installs `keel` **by package name** in a fresh
   Racket 9.3 environment and runs the package tests.
5. Re-run `turlamai/rivet` and `turlamai/glaze`
   `family-compat.yml` and the affected Rivet packaging jobs; verify
   published `keel` still satisfies the Rivet version floor. Save exact
   run URLs and both consumer SHAs as release evidence.
6. Close [#8](https://github.com/turlamai/keel/issues/8) only after
   actual fresh catalog installation and the previously blocked downstream
   suite pass. Do not “fix” the consumer by vendoring Keel or switching
   its dependency to a direct Git checkout.

## Failure semantics and scope

- Catalog unavailable: **NO-GO** (not proof of a valid source).
- Published source is the retired owner: **NO-GO**.
- Published source is correct but clean install or tests fail: **NO-GO**;
  inspect the Racket package output and fix the actual dependency.
- Local linked-package tests succeed: useful development evidence, but
  not catalog verification.
- The manual workflow does not auto-publish metadata, perform downloads
  on developer machines, or trigger consumer workflows; the catalog
  owner must perform the external edit and collect the downstream evidence.

See [the Racket package command documentation](https://docs.racket-lang.org/pkg/cmdline.html)
for `raco pkg catalog-show` and the
[package catalog protocol](https://docs.racket-lang.org/pkg/catalog-protocol.html)
for the distinction between source metadata and a Git checkout.

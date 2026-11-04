# Official Racket package catalog release gate

**Catalog source correction verified (2026-10-29):** the
[official Keel package record](https://pkgs.racket-lang.org/package/keel)
now resolves to `https://github.com/turlamai/keel.git#main`.
The package page links the current build transcript for the commit it
tested; treat that transcript, not a test count copied into this document,
as authoritative. Counts and commits change with every push.

**Known issue (2026-11-03 official builder):** the Racket 9.3 catalog
installation compiled, but its documentation test expected the repository-only
`.github/workflows/catalog-release-gate.yml` file inside a published package.
The gate remains mandatory in a Git checkout; package archive tests must not
require a workflow file that the Racket package archive omits. The latest
[official package status](https://pkgs.racket-lang.org/package/keel) must be
rechecked after this fix reaches `main`—local CI green alone is not enough.

The former package-source problem has been fixed. [Issue #8](https://github.com/turlamai/keel/issues/8)
now tracks rerunning the *previously blocked* Rivet/Glaze consumer suites.
A green Keel package build does not establish all downstream compatibility.

## Catalog revalidation and future maintenance

1. Inspect the current published source with a fresh Racket install:

   ```sh
   raco pkg catalog-show --catalog https://pkgs.racket-lang.org keel
   ```

   Confirm `https://github.com/turlamai/keel.git#main`. If a future
   migration requires correction, the authorized package catalog maintainer
   must edit the **existing** `keel` source record; GitHub redirects and
   repository README edits do not update official catalog metadata.
2. Run [Published package catalog release gate](https://github.com/turlamai/keel/blob/main/.github/workflows/catalog-release-gate.yml)
   manually after it reaches the default branch. This checks the official
   source and installs/tests `keel` by name on a clean Racket 9.3 runner.
   The workflow is repository metadata: `raco pkg create` does not ship
   `.github`, so package-installed documentation tests must not require it.
3. Rerun `turlamai/rivet` and `turlamai/glaze` `family-compat.yml` and
   any affected packaging CI; verify the published Keel version still
   satisfies the consumers' declared minimum version. Record exact run
   URLs and consumer SHAs.
4. Close [#8](https://github.com/turlamai/keel/issues/8) only after
   the previously blocked suites complete successfully. Do not vendor
   Keel or replace its published catalog dependency with a direct Git clone.

## Failure semantics

- Catalog unavailable or old owner reappears: **NO-GO**.
- Catalog correct but fresh install/test fails: **NO-GO**, investigate.
- Official Keel build passes but downstream jobs remain queued: **Keel
  package gate passed, downstream gate unverified**; not an all-green release.
- Local linked-package tests alone are not official catalog evidence.

The manual gate never edits official metadata or dispatches downstream CI.
See [Racket package commands](https://docs.racket-lang.org/pkg/cmdline.html)
for `raco pkg catalog-show`.

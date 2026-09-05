# Changelog

Releases from v0.1.3 onwards are documented here — v0.1.3 is where the file starts because that is the tag the consumers were pinned to when it was written. Entries are derived from the release tags and describe the image from the outside: the tool versions it carries, and what changes for a repository that runs `mage sql:generate` or `mage sql:migrate` against it. Work in this repository goes straight to main, so there are no PR references.

## [v0.2.1] - 2026-09-05

v0.2.0 carries the same changes but was never published: its multi-architecture build crashed while resolving modules under QEMU emulation, so no image exists at that tag. Go straight to v0.2.1.

**Behaviour change (migrations):** tern now adds a primary key to an existing `schema_version` table. From v2.3.6 the migrator checks for a primary key on the version table at startup and issues `alter table <version table> add primary key (version)` when there is none, so the first `tern` run from this image alters the version table of every database that was migrated with an earlier one. The table holds a single row, so the `ACCESS EXCLUSIVE` lock is taken and released immediately and no maintenance window is needed — but it is DDL against a production database, executed by the migrator rather than by a migration file, and it happens whether or not there are pending migrations to apply.

**Behaviour change (generated code):** sqlc goes from v1.26.0 to v1.31.1, five minor versions, so the next `mage sql:generate` in a consumer will produce a diff beyond the version stamp. Three changes in that range can alter or block generation: models whose name ends in `metadata` were being named incorrectly and are now renamed (v1.28.0), `xid8` columns map to `pgtype.Uint64` under pgx/v5 (v1.31.0), and invalid column references in `ON CONFLICT DO UPDATE` are now rejected instead of silently generating (v1.31.0). Neither the `metadata` suffix nor `xid8` occurs in the elephant repositories today, but `ON CONFLICT DO UPDATE` is widely used, so regenerate deliberately in each consumer rather than discovering the diff mid-feature.

**Behaviour change (TLS):** `sslrootcert=system` now works in the connection string tern is given. The pgx in v0.1.3 predates support for it and read `system` as a filename, failing with `unable to read CA file: open system`, and it stopped at the first resolved address rather than falling back to the next — so a host with no IPv6 route could not reach an AAAA-first provider at all. pgx v5.7.0 added `sslrootcert=system` and v5.7.3 matched libpq's fallback behaviour more closely, both of which this release carries. Connection strings that were downgraded to `sslmode=require` to work around this — `enas/conn-string` in the ttrun store is one — can move to `sslmode=verify-full&sslrootcert=system`.

Changes:

- tern upgraded from v2.1.1 to v2.4.3. Beyond the version-table change above, it splits SQL statements correctly when a migration contains dollar-quoted blocks (v2.2.1), which previously broke function and trigger bodies, and fixes connection setting precedence (v2.4.2) and port handling when `sslmode` is unset (v2.2.2).
- sqlc upgraded from v1.26.0 to v1.31.1.
- The image is now built on Debian 13 (trixie) rather than Debian 12 (bookworm), for both the build stage and the runtime image. Anything deriving from this image with `FROM` inherits the newer userland and glibc.
- The arm64 image is cross-compiled rather than built under QEMU emulation, which is what broke v0.2.0. sqlc needed cgo when this image was first built for arm64, which is why emulation was used; it is pure Go now, so the toolchain runs natively on the build host for both architectures.
- Dependency upgrades: Go to 1.27.1, pgx to v5.10.0, gRPC to v1.83.2, and the rest of the module graph. The gRPC bump clears two high-severity advisories that sqlc's dependency on v1.80.0 raises against the image; they are in gRPC's server-side message handling, which a codegen CLI does not expose, so this removes the scanner finding rather than a reachable vulnerability. `protoc-gen-go` is no longer a dependency — it was inherited from elephant-twirptools and the image never shipped it. The tool dependencies moved from a `tools.go` build-tag file to `tool` directives in `go.mod`.

## [v0.1.4] - 2024-04-18

Changes:

- sqlc upgraded from v1.25.0 to v1.26.0, and pgx to v5.5.5, which carries the fix for CVE-2024-27304 — an integer overflow in the calculated message size allowed SQL injection when a single query or bind message could be made to exceed 4 GB.
- Dependency upgrades: Go to 1.22.2 and protobuf to v1.33.0.

## [v0.1.3] - 2024-01-17

**Breaking:** sqlc moved from `github.com/kyleconroy/sqlc` to `github.com/sqlc-dev/sqlc` and jumped from v1.19.1 to v1.25.0, six minor versions. Consumers regenerating against this image should expect a substantial diff.

Changes:

- sqlc upgraded from v1.19.1 to v1.25.0 under its new module path.
- Dependency upgrades: Go to 1.21.6 and protobuf to v1.32.0.

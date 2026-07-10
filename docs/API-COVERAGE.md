# API coverage audit

Cross-check of every endpoint documented across the five `xcloud:*` skills
against the **live** xCloud Public API OpenAPI spec.

- **Source of truth:** the OpenAPI document served at
  <https://app.xcloud.host/api/v1/docs> (inlined in the Scalar page;
  `openapi: 3.0.3`, `info.version: 1.0.0`).
- **Audited:** 2026-07-10.
- **Method:** extracted every `METHOD /path` from `plugins/xcloud/**/*.md`
  (expanding `[/optional]` suffixes and `{a,b,c}` groups, normalizing `{uuid}` /
  `$VAR` / version segments) and diffed both directions against the spec's
  path+verb set.

## Headline

| Metric | Count |
|---|---|
| Operations in the live OpenAPI (97 paths) | **111** |
| Distinct operations documented by the skills | **120** |
| Documented operations that match the live spec | **111** |
| Documented operations **absent** from the live spec | **9** (all `databases` / `database-users`) |
| Live operations **not** documented by any skill | **0** |

## The "120-operation surface" claim

The current skill-side count is **120** documented operations:

- **111** operations that exist in the live OpenAPI spec.
- **9** caveated `databases`/`database-users` operations that the live OpenAPI
  does **not** list.
- The live API's documented surface is **111** operations.
- Coverage is therefore **111 / 111** live operations documented, with **0** live
  gaps. The 9 extra database operations stay marked as forward-looking /
  currently unavailable.

## A. Documented but absent from the live OpenAPI (9)

All in `skills/servers/reference/databases.md`. No `databases` or
`database-users` path appears anywhere in the live spec.

| Method | Path |
|---|---|
| GET | `/servers/{uuid}/databases` |
| GET | `/servers/{uuid}/databases/search` |
| POST | `/servers/{uuid}/databases` |
| DELETE | `/servers/{uuid}/databases` |
| GET | `/servers/{uuid}/database-users` |
| GET | `/servers/{uuid}/database-users/search` |
| POST | `/servers/{uuid}/database-users` |
| PUT | `/servers/{uuid}/database-users` |
| DELETE | `/servers/{uuid}/database-users` |

**Status — verified absent (HTTP 404), 2026-06-29.** Live reads against two
distinct `provisioned` servers returned **HTTP 404 "Resource not found"** for
both `databases` and `database-users`, while sibling endpoints on the *same*
server (`php-versions`, `firewall-rules`) returned `200`. Combined with their
absence from the OpenAPI spec, these endpoints are **not part of the current
public API** — `reference/databases.md` now carries a prominent caveat and the
`xcloud:servers` smoke suite treats `databases` as optional (404 → SKIP). They
should be removed or kept strictly as a forward-looking reference until the API
ships them.

## B. Live but not documented — coverage gaps (0)

No live OpenAPI operations are currently missing from the skill documentation.

The 2026-07-10 pass closed the previous gaps:

| Method | Path | Summary (from spec) | Covered in |
|---|---|---|---|
| GET | `/vulnerabilities` | Team-Wide Vulnerability Rollup | `xcloud:wordpress` |
| PUT | `/sites/{uuid}/git` | Update Git Deployment Settings | `xcloud:sites` |
| POST | `/sites/{uuid}/git/deploy` | Trigger Git Deployment | `xcloud:sites` |
| POST | `/servers/{uuid}/services/disable` | Disable a Server Service | `xcloud:servers` |

## No path/verb drift elsewhere

Every other documented endpoint — across `servers`, `sites`, `ssl`, `wordpress`,
`account`, and all `reference/*.md` sub-resources — matches the live spec exactly
on both path and verb, including:

- `monitoring[/history]` (servers & sites) — both the base and `/history` forms
  exist.
- `php-versions/{version}/{default,opcache,patch}` — version-segmented writes.
- `/sites/{uuid}/{custom-nginx,site-scripts,ip-access}` — all three exist.
- `/vulnerabilities` — team-wide vulnerability rollup exists and was verified
  read-only against live API on 2026-07-10.
- `/sites/{uuid}/git` and `/sites/{uuid}/git/deploy` — Git deployment settings
  and manual deploy are documented under `xcloud:sites`.
- `/servers/{uuid}/services/disable` — service disable is documented under
  `xcloud:servers` with confirmation guidance.
- Token revocation: live is `DELETE /user/tokens/{tokenUuid}` (`string`/`uuid`) —
  see the `xcloud:account` fix that aligned the docs to this.

## Recommended follow-ups

1. ~~Verify the 9 `databases` operations against a live server.~~ **Done
   (2026-06-29): all 404.** Decide whether to fully remove `databases.md` and its
   `xcloud:servers` references, or keep the now-caveated forward-looking reference.
2. Keep the database/database-user reference caveated until those endpoints ship
   in the live OpenAPI and return non-404 responses.
3. Re-run this audit before each marketplace release, because ClawHub indexing
   and security review both benefit from accurate coverage claims.

# Authentication

The xCloud Public API authenticates via [Sanctum personal access tokens](https://laravel.com/docs/sanctum) (Bearer auth).

## Required environment variables

```bash
export XCLOUD_API_TOKEN="xc_pat_..."           # required
export XCLOUD_API_BASE_URL="https://app.xcloud.host"  # default; override for white-label or staging
export XCLOUD_TEAM_UUID="team_..."             # optional; defaults to the token's team
```

## Generating a token

1. Log into the xCloud dashboard
2. Navigate to **Profile → API Tokens**
3. Click **Generate New Token**
4. Choose abilities (scopes): `read:sites`, `read:servers`, `write:sites`, `write:servers`, or `*`
5. Copy the token immediately — it is shown only once

## Scopes (Sanctum abilities)

| Scope | Grants |
|---|---|
| `read:sites` | All `GET` under `/sites/*` |
| `write:sites` | All write methods under `/sites/*` |
| `read:servers` | All `GET` under `/servers/*` |
| `write:servers` | All write methods under `/servers/*` |
| `*` | Full access (token management, all endpoints) |

For Slice A PR1 (this skill version), `read:sites` is sufficient for every endpoint.

## Fine-grained authorization

Sanctum scopes are coarse. Each request also passes through a per-resource policy check (`apiAccess`) that requires the user to:

1. Belong to the team that owns the resource
2. Have a team role of `TEAM_ADMIN`, `SERVER_ADMIN`, or `SITE_ADMIN`
3. Hold any extra team permission listed in the endpoint's policy (e.g. `site:manage-update`)

A token with `read:sites` but a user without `site:manage-update` will receive `403`.

## White-label deployments

Set `XCLOUD_API_BASE_URL` to the white-label host (no trailing slash):

```bash
export XCLOUD_API_BASE_URL="https://hosting.example.com"
```

The OpenAPI spec is also rewritten to that host when fetched from `/api/v1/docs`.

## Verifying auth works

```bash
./scripts/xcloud.sh GET /user
```

Expected response (200):

```json
{ "success": true, "message": "Success", "data": { "uuid": "...", "name": "...", "email": "...", "team": { "uuid": "...", "name": "..." } } }
```

A `401` means the token is missing, expired, or revoked.
A `403` on this endpoint usually means the token lacks the `*` scope and is being asked for token-management info.

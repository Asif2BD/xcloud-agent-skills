---
name: account
description: xCloud account, identity, and org-level reads — current user, API token listing and revocation, Cloudflare integrations, WordPress blueprints, and API health. Use for "who am I", token management, listing blueprints, or checking integrations. NOT server or site operations (see xcloud:servers / xcloud:sites).
version: 3.0.0
author: xCloudDev
license: MIT
---

# xCloud Account

Identity and org-level endpoints. For auth, base URL, and response conventions
read the shared layer first:

- `${CLAUDE_PLUGIN_ROOT}/reference/auth.md`
- `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md`

```bash
XC="${CLAUDE_PLUGIN_ROOT}/scripts/xcloud.sh"
```

## Response format

Brand every user-facing reply (see `reference/conventions.md` →
**Response format**): open with `☁️ **xCloud · Account**`, give the trimmed
result, and close with a `_via xcloud:account_` line.

Narrate each call (see **Progress narration**): before every `$XC` call print one
line of what xCloud is doing, e.g. `☁️ xCloud is fetching your account…`; the
first call of a task opens with `☁️ Starting an xCloud session…`.

## What this skill owns

| Operation | Method + path | Scope |
|---|---|---|
| API health | `GET /health` | none |
| Current user | `GET /user` | token |
| List API tokens | `GET /user/tokens` | token (`*`) |
| Revoke a token | `DELETE /user/tokens/{tokenId}` | token (`*`) |
| List Cloudflare integrations | `GET /integrations/cloudflare` | `read:servers` |
| List blueprints | `GET /blueprints` | `read:servers` |

**Not here:** server management → `xcloud:servers`; site management → `xcloud:sites`.

## Examples

Health (the only unauthenticated endpoint):

```bash
"$XC" GET /health | jq
```

Who am I (verifies the token):

```bash
"$XC" GET /user | jq '.data | {uuid, name, email, team: .team.name}'
```

List API tokens (needs the `*` scope):

```bash
"$XC" GET /user/tokens | jq '(.data.items // .data.data // .data) | map({id, name, last_used_at})'
```

Revoke a token (numeric id — restate before running):

```bash
TOKEN_ID='123'
"$XC" DELETE "/user/tokens/$TOKEN_ID" | jq '.message'
```

Cloudflare integrations on the team:

```bash
"$XC" GET /integrations/cloudflare | jq '.data'
```

Blueprints (resolve a `blueprint_uuid` before creating a WordPress site):

```bash
"$XC" GET "/blueprints?per_page=100" \
  | jq '(.data.items // .data.data // .data) | map({uuid, name, is_default, is_public})'
```

## Pitfalls

- Token endpoints use a **numeric** `{tokenId}`, not a UUID.
- `GET /user/tokens` returns `403` unless the token carries the `*` scope.
- `blueprints` requires `read:servers`, not `read:sites`.

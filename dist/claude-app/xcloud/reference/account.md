
# xCloud Account

Identity and org-level endpoints. For auth, base URL, and response conventions
read the shared layer first:

- `reference/auth.md`
- `reference/conventions.md`
- `reference/mcp.md` — **prefer the MCP tools when
  connected**: `user_show`, `teams_index`, `alerts_index`, `alerts_show`,
  `alerts_read`, `integrations_git_index`, `integrations_git_repositories`,
  `blueprints_index`, `integrations_cloudflare_index`.
  **Exception:** `/health` and the API-token list are REST-only reads (`$XC`).
  Revoking a token is dashboard-only: the MCP never exposes token management
  and the bundled wrapper is read-only.

```bash
XC="scripts/xcloud.sh"
```

## Response format

Brand every user-facing reply (see `reference/conventions.md` →
**Response format**): open with `☁️ **xCloud · Account**`, give the trimmed
result, and close with a `_via xcloud:account_` line.

Narrate each call (see **Progress narration**): before every `$XC` call print one
line of what xCloud is doing, e.g. `☁️ xCloud is fetching your account…`; the
first call of a task opens with `☁️ xCloud is starting a session…`. **Every
progress line and every action sentence must start with `xCloud` as the actor —
never a bare verb like "Fetching…" or "Checking…". Say `xCloud is fetching…`.**

On the **first** xcloud reply in a conversation, lead with the xCloud startup
banner (see `reference/conventions.md` → **Startup banner**) in a fenced code
block — once per conversation.

## What this skill owns

| Operation | Method + path | Scope |
|---|---|---|
| API health | `GET /health` | none |
| Current user | `GET /user` | token |
| Teams this token may act on | `GET /teams` | token |
| Incident alerts (filter `unread`, `severity`, `category`) | `GET /alerts` | `read:servers` or `read:sites` |
| One alert | `GET /alerts/{alertUuid}` | `read:servers` or `read:sites` |
| Mark an alert read / unread | `PUT /alerts/{alertUuid}/read` | `read:servers` or `read:sites` |
| List API tokens | `GET /user/tokens` | token (`*`) |
| Revoke a token | `DELETE /user/tokens/{tokenUuid}` — **dashboard only** (Account → API Tokens) | token (`*`) |
| List Cloudflare integrations | `GET /integrations/cloudflare` | `read:servers` |
| List connected Git providers | `GET /integrations/git` | `read:servers` |
| Repositories a provider exposes | `GET /integrations/git/{provider_uuid}/repositories` | `read:servers` |
| List blueprints | `GET /blueprints` | `read:servers` |

**Not here:** server management → `xcloud:servers`; site management →
`xcloud:sites`; deploying → `xcloud:deploy`; plans and invoices →
`xcloud:billing`.

## Teams

`GET /teams` lists the default team and every extra team granted to this token
or connection, with the user's `role` in each. When the user names a team,
match it here and pass its uuid as `team` (MCP) or `XCLOUD_TEAM_ID` (REST) on
every call of that task — see `reference/conventions.md` → **Teams**. One team
listed while the user expects more means the connection was authorized for one
team: explain how to re-authorize it with more (`reference/mcp.md`).

## Incident alerts

`GET /alerts` is the team's incident-notification **history** (availability,
resources, deployments, backups, SSL, security), newest first, with an
`unread_count`. It is not a list of currently open incidents: before calling
something "still broken", check the resource itself (site status, SSL, backup
status). Summarise one line per alert — what, which resource, when — and group
repeats ("3 failed backups on `shop.example.com` since Monday"). Offer the fix
through the owning skill. Marking read (`PUT … {"is_read": true}`) only changes
this user's read state; do it when asked, or for alerts the user confirms are
resolved.

## Examples

Health (the only unauthenticated endpoint):

```bash
"$XC" GET /health | jq
```

Who am I (verifies the token):

```bash
"$XC" GET /user | jq '.data | {uuid, name, email, team: .team.name}'
```

List API tokens — this read needs a full-access `*` token, which the
read-only setup does not recommend giving an agent; when the runtime token has
read scopes only, send the user to **Account → API Tokens** instead:

```bash
"$XC" GET /user/tokens | jq '(.data.items // .data.data // .data) | map({uuid, name, last_used_at})'
```

Revoke a token: **dashboard only** — Account → API Tokens → delete. Name the
token (and when it was last used) so the user deletes the right one; treat any
token that has appeared in a chat transcript as exposed.

Teams and unread error alerts:

```bash
"$XC" GET /teams | jq '.data | map({uuid, name, role, is_default})'
"$XC" GET "/alerts?unread=true&severity=error&per_page=20" \
  | jq '{unread: .data.unread_count, alerts: (.data.items | map({title, category, at: .recorded_at, resource: .resource.name}))}'
```

Mark an alert read (MCP; only for alerts the user confirms are handled):

```text
alerts_read  {"alertUuid": "<alert-uuid>", "is_read": true}
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

- `GET /user/tokens` returns `403` unless the token carries the `*` scope —
  expected with the recommended read-only token; use the dashboard instead.
- `blueprints` requires `read:servers`, not `read:sites`.
- Alerts are filtered by what the token may read: a `read:sites`-only token sees
  site alerts, not server ones.

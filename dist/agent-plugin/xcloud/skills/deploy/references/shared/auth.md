# Authentication (shared)

Shared by every xCloud domain skill.

## Two ways to connect — MCP first

1. **xCloud MCP (recommended).** If tools from the MCP server named `xcloud` are available in
   the session, the account is already connected via OAuth — **no token setup is
   needed** and the rest of this file does not apply. Use the MCP tools directly;
   see `references/shared/mcp.md` for the transport rule, tool naming, and the
   confirm-before-destructive contract. If the user has no connection yet,
   onboard them with the MCP connect instructions in `references/shared/mcp.md`
   **before** falling back to a raw API token.
2. **REST API token (read-only fallback).** For looking at the account from
   agents without MCP support, and for the REST-only reads (`/health`, API-token
   list). The bundled wrapper sends `GET` only, so create the token with **read
   scopes only** — a write scope would add risk and no capability. Changes need
   the MCP connection (`references/shared/conventions.md` → Transports). The Public API
   authenticates via [Sanctum personal access tokens](https://laravel.com/docs/sanctum)
   (Bearer auth) — everything below covers this path.

## Environment variables

```bash
export XCLOUD_API_TOKEN="..."                         # required
export XCLOUD_API_BASE_URL="https://app.xcloud.host"  # default (live)
# Local development (plaintext http needs the explicit override):
export XCLOUD_API_BASE_URL="http://xcloud.test"
export XCLOUD_ALLOW_INSECURE_HTTP=1
# Per call, optional:
XCLOUD_TEAM_ID="team-uuid"      # read a non-default granted team (X-Team-Id)
```

A token can be granted several teams when it is created (its default is the team
active in the dashboard at that moment); `GET /teams` lists them, and
`XCLOUD_TEAM_ID` selects one per call. Set it per call (prefix the command), not
globally, so a later request never reads the wrong team. The wrapper refuses a
set-but-empty or malformed `XCLOUD_TEAM_ID` (exit 64) instead of silently
reading the default team.

The base URL is the **only** thing that changes between local and live — never
hardcode a host in a skill body.

## Proactive token onboarding

If `XCLOUD_API_TOKEN` is missing or a request returns `401`, guide the user
through setup before continuing. **Offer the xCloud MCP
connector first** (`references/shared/mcp.md` → Connecting) — OAuth, no secret to
store. Only if MCP isn't an option for their client, walk them through the
token path below. Be proactive and helpful, but do **not** ask the user to
paste a raw production token into the chat by default. Direct them to the
runtime's environment, settings file, or secret store.

Use this wording pattern:

```text
☁️ **xCloud · Setup**

xCloud needs an API token before it can inspect or manage your hosting account.
Create a scoped token in the xCloud dashboard, store it in your agent runtime as
`XCLOUD_API_TOKEN`, restart the agent if needed, then ask me to check the xCloud
connection.

_via xCloud/account_
```

After setup, verify with `GET /health` and `GET /user` before continuing the
original task.

## Setting the token in a portable client

**Step 1 — generate the token.** In the xCloud dashboard, open **Profile → API
Tokens → Generate New Token**. Select the narrowest required scopes and copy the
token immediately.

**Step 2 — store the token.** Put `XCLOUD_API_TOKEN` in the client environment or
its secure secret store. Do not put a token in `plugin.json`, `mcp.json`, a skill
file, source control, or chat. Set `XCLOUD_API_BASE_URL` only for a non-default
xCloud host.

For a temporary terminal session:

```bash
export XCLOUD_API_TOKEN="..."
export XCLOUD_API_BASE_URL="https://app.xcloud.host"
```

Use the client's documented environment or secret configuration for persistent
storage. Restart the client if it does not reload environment changes.

> **Browser/chat-only agents:** use the **xCloud MCP connector**
> (`references/shared/mcp.md`) with OAuth or the host's secure credential store.
> Never request production tokens in chat. If secure credential injection is
> unavailable, stop authenticated operations and explain the limitation.
>
> **If a token is exposed (pasted in the wrong place, shared transcript,
> committed):** revoke it immediately — xCloud dashboard → **Profile → API
> Tokens** → delete it (`GET /user/tokens` helps find it; revoking is
> dashboard-only — neither the read-only wrapper nor the MCP can revoke a
> token). Then generate a fresh read-scoped token and update the runtime.
> Rotate routinely, not only after incidents.

## Generating a token

xCloud dashboard → **Profile → API Tokens → Generate New Token** → choose read
scopes → copy immediately (shown once). The team active in the dashboard becomes
the token's default team; tick any others it should read.

## Scopes (Sanctum abilities)

| Scope | Grants |
|---|---|
| `read:sites` | All `GET` under `/sites/*` and `/ssl-certificates/*` |
| `write:sites` | All write methods under `/sites/*` |
| `read:servers` | All `GET` under `/servers/*` |
| `write:servers` | All write methods under `/servers/*` (incl. buying a server) |
| `read:billing` | Plan, overview, invoices, bills, subscriptions, payment methods |
| `read:addons` | Mailbox and mail-delivery reads |
| `write:addons` | Add-on purchases and deletion, paying an invoice |
| `*` | Full access (incl. token management) |

For the bundled read-only wrapper, grant only the `read:*` scopes the task
needs. The `write:*` scopes and `*` matter only to other API clients.

## Fine-grained authorization

Scopes are coarse; each request also passes a per-resource policy check. A `403`
with a valid token means the user lacks a required team permission (e.g.
`site:manage-ssl` for SSL renewal), not that the token is wrong.

## Verifying auth

```bash
"$SKILL_ROOT/scripts/xcloud.sh" GET /user
```

`401` → token missing/expired/revoked. `403` → scope or team-permission gap.

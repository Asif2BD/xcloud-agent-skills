# Authentication (shared)

Shared by every `xcloud-*` domain skill. The xCloud Public API authenticates via
[Sanctum personal access tokens](https://laravel.com/docs/sanctum) (Bearer auth).

## Environment variables

```bash
export XCLOUD_API_TOKEN="..."                         # required
export XCLOUD_API_BASE_URL="https://app.xcloud.host"  # default (live)
# Local development:
export XCLOUD_API_BASE_URL="http://xcloud.test"
```

The base URL is the **only** thing that changes between local and live — never
hardcode a host in a skill body.

## Setting the token (pick one persistent option)

1. **Claude Code `settings.json`** (recommended with these skills):
   ```json
   { "env": { "XCLOUD_API_TOKEN": "your-token-here" } }
   ```
2. **Shell profile:**
   ```bash
   echo "export XCLOUD_API_TOKEN='your-token-here'" >> ~/.zshrc && source ~/.zshrc
   ```
3. **Inline for one session** (not persistent):
   ```bash
   XCLOUD_API_TOKEN=... ./scripts/xcloud.sh GET /user
   ```

## Generating a token

xCloud dashboard → **Profile → API Tokens → Generate New Token** → choose scopes
→ copy immediately (shown once).

## Scopes (Sanctum abilities)

| Scope | Grants |
|---|---|
| `read:sites` | All `GET` under `/sites/*` and `/ssl-certificates/*` |
| `write:sites` | All write methods under `/sites/*` |
| `read:servers` | All `GET` under `/servers/*` |
| `write:servers` | All write methods under `/servers/*` |
| `*` | Full access (incl. token management) |

## Fine-grained authorization

Scopes are coarse; each request also passes a per-resource policy check. A `403`
with a valid token means the user lacks a required team permission (e.g.
`site:manage-ssl` for SSL renewal), not that the token is wrong.

## Verifying auth

```bash
"${CLAUDE_PLUGIN_ROOT}"/scripts/xcloud.sh GET /user
```

`401` → token missing/expired/revoked. `403` → scope or team-permission gap.

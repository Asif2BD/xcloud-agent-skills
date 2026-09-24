# xCloud Agent Skills

[![ClawHub](https://img.shields.io/badge/ClawHub-xcloud-blue)](https://clawhub.ai/asif2bd/skills/xcloud)
[![Version](https://img.shields.io/badge/version-4.4.0-green)](CHANGELOG.md)
[![MCP](https://img.shields.io/badge/MCP-app.xcloud.host%2Fmcp-0EA5E9)](https://app.xcloud.host/mcp/docs)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![xCloud](https://img.shields.io/badge/xCloud-Official-0EA5E9.svg)](https://xcloud.host)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-purple)](https://openclaw.ai)

**Operate xCloud in plain language from any AI agent.** Paste a GitHub URL and
say *"deploy this"*, or ask *"install Ghost on my Frankfurt server"*, *"renew
SSL for example.com"*, *"why did my last deploy fail?"* — the agent picks the
right skill, previews what it will do, asks once, then finishes the job: it
provisions, polls, checks the live URL, and diagnoses and retries failures. No
endpoints to memorize, no SDK to wire up.

Built by [xCloud](https://xcloud.host) · [Official GitHub](https://github.com/xCloudDev/xcloud-agent-skills) · [MCP Docs](https://app.xcloud.host/mcp/docs) · [User Guide](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md) · [Install Guide](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md) · [API Docs](https://app.xcloud.host/api/v1/docs) · [OpenClaw + ClawHub Tutorial](https://xcloud.host/openclaw-skills-and-clawhub-on-xcloud-openclaw-agent/) · [Tutorial Video](https://www.youtube.com/watch?v=oEE9OHo3_48)

This repository ships the **`xcloud` Claude Code plugin** (v4.4.0): nine
capability skills that pair with the **[xCloud MCP server](https://app.xcloud.host/mcp/docs)**
— one native tool per authenticated
[Public API](https://app.xcloud.host/api/v1/docs) operation plus two search
tools, or a five-tool compact profile — with a bundled REST fallback for
agents without MCP support.

> **New here?** Start with the [User Guide](docs/USER_GUIDE.md) (task-first) or
> the [Install & Usage Guide](docs/SKILLS-GUIDE.md) (full install, per-skill
> reference, smoke tests, routing rules).

## The nine skills

You never name them — the agent picks the right one from what you ask.

| Skill | Owns |
|---|---|
| `xcloud:deploy` | **Deploy anything**: a GitHub/GitLab/Bitbucket URL, Docker Compose or Dockerfile apps, one-click apps, Git staging environments, new WordPress sites — detect, dry run, approve, provision, verify, and diagnose + retry failures |
| `xcloud:troubleshoot` | **A site that errors**: 500/502/503, critical error, site down — status, recent events, nginx access and error log, WordPress health, WP_DEBUG, services; dashboard handoff for the logs only Site → Logs shows |
| `xcloud:performance` | **A slow site**: site and server monitoring, which cache layers are on, PageSpeed, traffic spikes and bots, the site's PHP version; dashboard handoff for enabling a cache or changing a site's PHP |
| `xcloud:servers` | Servers: **buy a server** (plans, prices, provisioning), services install/enable/restart, Node.js and PHP versions, verified reboots, cron, firewall/fail2ban, sudo users, DNS checks |
| `xcloud:sites` | Site lifecycle: status, backups (incl. Docker apps), staging, domains, cache, SSH, site cron, monitoring, site deletion |
| `xcloud:wordpress` | WP plugins/themes/updates, WP_DEBUG, magic login, site and team vulnerabilities, PageSpeed, broken links |
| `xcloud:ssl` | SSL certificates: view, install, renew, status, delete |
| `xcloud:billing` | Plan, invoices, bills, subscriptions, prices, paying an invoice, **mailboxes and mail delivery** |
| `xcloud:account` | Current user, **teams (multi-team)**, **incident alerts**, API tokens, Git and Cloudflare integrations, blueprints, health |

Skills are organized by **capability, not URL root** — each declares what it does
*not* own with `see xcloud:*` cross-links so trigger keywords don't collide. See
[ADR 0001](docs/adr/0001-capability-domain-skills.md) for the rationale.

## Connect the xCloud MCP (recommended)

The **xCloud MCP server** is the fastest way to give any agent full xCloud
control — OAuth sign-in, no token to store, and built-in confirmation before
every destructive operation. **One tool per authenticated API operation, plus
`xcloud_agent_search` and `xcloud_docs_search`** (190 tools on 2026-09-24); or
the **compact profile** (`/mcp?profile=compact`, five tools) for clients that
cap tool counts.

**One connection, several teams.** Since xCloud v2.8.8 a single MCP connection
or API token can be granted several teams. Older connections keep working but
see only the team they were authorized for — to add teams, reconnect (or remove
and re-add) the connection and tick every team on the xCloud approval screen.
The skills then pick the right team per request. Details:
[multi-team access](https://xcloud.host/docs/multi-team-api-tokens-and-mcp-access/).

**Claude Code:**

```bash
claude mcp add xcloud --transport http https://app.xcloud.host/mcp
```

Then run `/mcp` → **Authenticate** and grant **Read** or **Read & write**.

**Claude Desktop / claude.ai:** Settings → **Connectors** → **Add custom
connector** → name it `xcloud`, URL `https://app.xcloud.host/mcp`, sign in.

**Cursor** (`~/.cursor/mcp.json`) and any HTTP-capable MCP client:

```json
{ "mcpServers": { "xcloud": { "url": "https://app.xcloud.host/mcp" } } }
```

**Headless / CI:** use an API token carrying the `mcp:invoke` scope:

```bash
claude mcp add xcloud --transport http https://app.xcloud.host/mcp \
  --header 'Authorization: Bearer YOUR_TOKEN'
```

Verify with *"who am I on xCloud?"*. Full details: [MCP docs](https://app.xcloud.host/mcp/docs).

## Install the skills plugin

The skills teach the agent xCloud's workflows — routing, safety guardrails,
async polling, multi-step chains — on top of either transport (MCP or REST).

1. **Install in Claude Code:**

   ```
   /plugin marketplace add xCloudDev/xcloud-agent-skills
   /plugin install xcloud@xcloud-agent-skills
   /reload-plugins
   ```

2. **Connect the account.** If you added the MCP connector above, you're done —
   no token needed. Otherwise (REST fallback), get a token from the xCloud
   dashboard → **Profile → API Tokens → Generate New Token** and add it to your
   Claude Code settings:

   ```json
   { "env": { "XCLOUD_API_TOKEN": "your-token-here" } }
   ```

   Use `~/.claude/settings.json` (global) or a project-local
   `.claude/settings.local.json` (keep it out of git). Restart Claude Code so it
   picks up the token.

3. **Check it works.** Ask Claude: *"Check my xCloud API connection."* A green
   light means you're ready.

If xCloud finds no connection, it will offer the MCP connector first, then guide
you through scoped-token setup. Do not paste a production token into chat unless
you are using a temporary, scoped token and no safer secret-store/runtime option
exists.

> **Note:** API-token management (list/revoke) and the `/health` probe are
> REST-only — the skills use the bundled `curl` wrapper for those even when the
> MCP is connected.

### Agent Plugins 1.0.0

The portable package is at [`dist/agent-plugin/xcloud`](dist/agent-plugin/xcloud).
It includes the nine skills and the xCloud MCP connection in the standard layout:

```text
xcloud/
├── plugin.json
├── mcp.json
└── skills/
```

Load that directory in a compatible Agent Plugins client. The package declares
`https://app.xcloud.host/mcp`; the client manages OAuth authorization. Current
compatible clients include ChatGPT and Codex, Cursor, GitHub Copilot, Kiro, and
VS Code.

The repository's root `/plugin marketplace` entry remains the Claude Code
package. For a local Codex test before the portable package is published, use the
separate marketplace adapter:

```bash
codex plugin marketplace add ./dist/agent-plugin
codex plugin add xcloud@xcloud-agent-plugins
```

Release `xcloud-agent-plugin.zip` is the portable artifact for directory
submission and clients that support local package import.

Build and validate it locally:

```bash
python3 dist/agent-plugin/build.py
python3 dist/agent-plugin/validate.py
for skill in dist/agent-plugin/xcloud/skills/*; do
  npx --yes skills-ref validate "$skill"
done
```

The portable distribution keeps every file reference within its skill. Before
running its REST wrapper, an agent resolves `SKILL_ROOT` to the absolute directory
containing the loaded `SKILL.md`; commands therefore do not depend on the user's
working directory or Claude Code's `${CLAUDE_PLUGIN_ROOT}` variable.

> **Known OAuth limitations:** the production API Gateway currently returns
> `x-amzn-remapped-www-authenticate` instead of the required `WWW-Authenticate`
> header on an unauthenticated MCP `401`. Clients that probe the OAuth well-known
> URLs directly work; strict clients may require the MCP URL to be added manually.
> Dynamic client registration currently grants `mcp:read` only even when
> `mcp:write` is requested, so newly registered portable clients must be treated
> as read-only until the production fixes are completed and verified. See the
> [live regression checklist](https://github.com/xCloudDev/xCloud/issues/5662#issuecomment-5221475839).

### Other agent frameworks

The generated skills are plain Markdown plus a skill-local `bash`/`curl` wrapper:

```bash
git clone https://github.com/xCloudDev/xcloud-agent-skills.git
cd xcloud-agent-skills
python3 dist/agent-plugin/build.py
cp -r dist/agent-plugin/xcloud/skills/* /your/agent/skills/
```

Agents that support MCP should load the root `mcp.json`; other agents can use the
skill-local REST wrapper and `XCLOUD_API_TOKEN`.

## Example requests

You describe what you want; Claude chains the steps.

```text
Deploy https://github.com/acme/shop to my Frankfurt server.
Deploy github.com/acme/api as a Compose app on a staging hostname — scan the compose file first.
The last deploy of the API site failed — diagnose it, fix the build command, and retry.
Install Uptime Kuma on my Docker server and give me the URL.
Create a staging environment for the API site from the feature/checkout branch.
List my xCloud servers and flag any above 80% disk.
Any unread incident alerts on the Acme team?
Show me last month's invoice and its total.
Buy a mailbox for hello@example.com and tell me which DNS records to add.
Is example.com up right now?
Renew the SSL certificate for shop.example.com.
Update all plugins on example.com, but back up first.
Scan example.com for vulnerabilities and show me the critical ones.
Something's hammering my server from 203.0.113.7 — block it.
Show me team-wide WordPress vulnerabilities across all xCloud sites.
Deploy the latest Git commit for example.com.
```

**Multi-step workflows** — each is a single request:

```text
Audit example.com — is it up, is SSL healthy, any vulnerabilities, and how's performance?
example.com is throwing 502 errors — what's going on?
I just provisioned shop.example.com — set up HTTPS and confirm it's serving.
```

> If Claude ever reaches for the wrong area, name it:
> `Using xcloud:ssl, renew the cert for example.com.`

## Authentication & scopes

**MCP (recommended):** browser OAuth with two grant levels — **Read**
(`mcp:read`) or **Read & write** (`mcp:write`). Access is team-scoped and every
connection shows up in the dashboard's API key management for one-click
revocation. Every destructive MCP tool additionally requires per-action
confirmation.

**REST fallback:** the skills authenticate with a
[Sanctum personal access token](https://laravel.com/docs/sanctum) (Bearer auth).
Generate one in the xCloud dashboard → **Profile → API Tokens → Generate New
Token**, choosing scopes:

| Scope | Grants |
|---|---|
| `read:sites` / `write:sites` | Reads / writes under `/sites/*` and `/ssl-certificates/*` |
| `read:servers` / `write:servers` | Reads / writes under `/servers/*` (incl. buying a server) |
| `read:billing` | Plan, invoices, bills, subscriptions, payment methods |
| `read:addons` / `write:addons` | Mailbox and mail-delivery add-ons, paying invoices |
| `*` | Full access, including token management |

Tokens can be granted several teams; set `XCLOUD_TEAM_ID` per call to pick one
(sent as `X-Team-Id`), and `XCLOUD_IDEMPOTENCY_KEY` to make a create safe to
retry.

Prefer the narrowest scopes that cover your use. The base URL is environment
driven (`XCLOUD_API_BASE_URL`, default `https://app.xcloud.host`) — point it at a
local or white-label host without touching any skill. Full details in
[`plugins/xcloud/reference/auth.md`](plugins/xcloud/reference/auth.md).

## API & MCP reference

- **MCP endpoint**: `https://app.xcloud.host/mcp` (Streamable HTTP) — [docs](https://app.xcloud.host/mcp/docs)
- **MCP tools**: one per agent-facing REST operation — 188 on 2026-09-24 —
  plus `xcloud_agent_search` and `xcloud_docs_search` (the API's other 11
  operations are `/health`, token management, and the mobile app's own sign-in
  and push endpoints); tool names mirror
  endpoint paths (`servers_reboot`, `sites_ssl_renew`, …). Compact profile:
  `/mcp?profile=compact` (two searches + three executors); toolset narrowing:
  `/mcp?toolsets=sites,servers`
- **API docs**: https://app.xcloud.host/api/v1/docs (every endpoint,
  request/response schema, interactive try-it console)
- **Base URL**: `https://app.xcloud.host/api/v1`
- **Auth**: MCP OAuth, or Bearer token (Sanctum)
- **Rate limit**: 60 requests/minute authenticated (10/min unauthenticated)

## Useful links

| Link | Use it for |
|---|---|
| [xCloud](https://xcloud.host) | Product landing page and hosting platform overview |
| [xCloud MCP Docs](https://app.xcloud.host/mcp/docs) | Connect the MCP server from any agent (OAuth or API key) |
| [xCloud Dashboard](https://app.xcloud.host) | Generate API tokens and manage hosting resources |
| [User Guide](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md) | Task-first examples for using the skills with an agent |
| [Install & Usage Guide](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md) | Full install steps, routing rules, and smoke tests |
| [API Docs](https://app.xcloud.host/api/v1/docs) | Public API reference and schemas |
| [OpenClaw + ClawHub Tutorial](https://xcloud.host/openclaw-skills-and-clawhub-on-xcloud-openclaw-agent/) | Step-by-step xCloud guide to installing skills from ClawHub |
| [xCloud Tutorial Video](https://www.youtube.com/watch?v=oEE9OHo3_48) | Video walkthrough for the xCloud/OpenClaw skills workflow |
| [xCloud YouTube](https://www.youtube.com/@xCloud-Hosting) | xCloud tutorials, walkthroughs, and release videos |
| [GitHub](https://github.com/xCloudDev/xcloud-agent-skills) | Source, issues, changelog, and contribution flow |

## Testing

Each skill ships a read-only `tests/smoke.sh`. Point it at a real resource and it
exercises that skill's core reads end-to-end:

```bash
export XCLOUD_API_TOKEN="your-token"
export XCLOUD_TEST_SERVER_UUID="..."   # for the servers suite
plugins/xcloud/skills/servers/tests/smoke.sh
```

The suites are read-only (the deploy suite only runs side-effect-free repository
detection) and tolerate optional sub-resources a server/site type doesn't
support, and billing reads a token isn't scoped for. Offline suites need no
token: `bash plugins/xcloud/scripts/tests/wrapper-test.sh`.

## Legacy: Python SDK & CLI

> The installable artifact is the **skill set above**. The Python SDK, async
> helpers, and shell CLI under `src/` predate the skills (v1.x) and are kept for
> direct scripting use. They are **not** part of the `xcloud` plugin and are not
> copied into it.

```python
from src.xcloud_sdk import XCloudAPI, XCloudDeployer

api = XCloudAPI()              # reads XCLOUD_API_TOKEN
for s in api.list_servers()['items']:
    print(s['name'], s['ip_address'])

deployer = XCloudDeployer(api)
health = deployer.get_fleet_health()
print("Total sites:", health['sites']['total'])
```

```bash
./src/xcloud-cli.sh server list
./src/xcloud-cli.sh site status <site-uuid>
```

- **`src/xcloud_sdk.py`** — `XCloudAPI` (low-level client) + `XCloudDeployer`
  (provisioning, fleet health, batch backups).
- **`src/xcloud_async.py`** — polling, persistent state, rate-limit backoff.
- **`src/xcloud-cli.sh`** — interactive server/site management.
- Recovery patterns live in [`docs/ERROR-HANDLING.md`](docs/ERROR-HANDLING.md);
  real-world scenarios in [`docs/AGENT-SCENARIOS.md`](docs/AGENT-SCENARIOS.md).

Install the SDK dependencies with `pip install -r requirements.txt`.

## Security

- Store the token in agent/CLI settings or a secure credential file — never commit
  it. `.env*` and `.claude/settings.local.json` are gitignored.
- Use scoped tokens (avoid `*` unless you need token management), rotate
  regularly, and revoke tokens that have been exposed.
- Each request also passes a per-resource policy check — a `403` with a valid
  token means a missing team permission, not a bad token.

Full guidance: [`SECURITY.md`](SECURITY.md).

## Links

- **xCloud**: https://xcloud.host
- **MCP docs**: https://app.xcloud.host/mcp/docs
- **Dashboard**: https://app.xcloud.host
- **User Guide**: https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md
- **Install Guide**: https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md
- **API docs**: https://app.xcloud.host/api/v1/docs
- **OpenClaw + ClawHub tutorial**: https://xcloud.host/openclaw-skills-and-clawhub-on-xcloud-openclaw-agent/
- **Tutorial video**: https://www.youtube.com/watch?v=oEE9OHo3_48
- **Official repository**: https://github.com/xCloudDev/xcloud-agent-skills
- **Development fork**: https://github.com/Asif2BD/xcloud-agent-skills
- **Issues**: https://github.com/xCloudDev/xcloud-agent-skills/issues
- **Changelog**: [`CHANGELOG.md`](CHANGELOG.md)

## License

MIT — see [`LICENSE`](LICENSE).

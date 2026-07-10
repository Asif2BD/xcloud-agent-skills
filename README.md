# xCloud Agent Skills

[![ClawHub](https://img.shields.io/badge/ClawHub-xcloud-blue)](https://clawhub.ai/asif2bd/skills/xcloud)
[![Version](https://img.shields.io/badge/version-3.0.2-green)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![xCloud](https://img.shields.io/badge/xCloud-Official-0EA5E9.svg)](https://xcloud.host)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-purple)](https://openclaw.ai)

**Operate xCloud in plain language from any AI agent.** Ask *"reboot my Hermes
server"*, *"renew SSL for example.com"*, or *"scan example.com for
vulnerabilities and show me the criticals"* — the agent picks the right skill and
chains the steps. No endpoints to memorize, no SDK to wire up.

Built by [xCloud](https://xcloud.host) · [Official GitHub](https://github.com/xCloudDev/xcloud-agent-skills) · [User Guide](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md) · [Install Guide](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md) · [API Docs](https://app.xcloud.host/api/v1/docs)

This repository ships the **`xcloud` Claude Code plugin** (v3.0.2): five
capability skills that wrap the [xCloud Public API](https://app.xcloud.host/api/v1/docs).

> **New here?** Start with the [User Guide](docs/USER_GUIDE.md) (task-first) or
> the [Install & Usage Guide](docs/SKILLS-GUIDE.md) (full install, per-skill
> reference, smoke tests, routing rules).

## The five skills

You never name them — the agent picks the right one from what you ask.

| Skill | Owns |
|---|---|
| `xcloud:servers` | Servers, PHP, databases, cron, firewall/fail2ban, sudo users, WordPress provisioning |
| `xcloud:sites` | Site lifecycle: status, backups, domains, cache, SSH, site cron, git |
| `xcloud:wordpress` | WP plugins/themes/updates, WP_DEBUG, magic login, vulnerabilities, PageSpeed |
| `xcloud:ssl` | SSL certificates: view, install, renew, status, delete |
| `xcloud:account` | Current user, API tokens, Cloudflare integrations, blueprints, health |

Skills are organized by **capability, not URL root** — each declares what it does
*not* own with `see xcloud:*` cross-links so trigger keywords don't collide. See
[ADR 0001](docs/adr/0001-capability-domain-skills.md) for the rationale.

## Install in Claude Code

1. **Install the plugin:**

   ```
   /plugin marketplace add xCloudDev/xcloud-agent-skills
   /plugin install xcloud@xcloud-agent-skills
   /reload-plugins
   ```

2. **Add your API token.** Get one from the xCloud dashboard → **Profile → API
   Tokens → Generate New Token** (choose scopes; copy it once). Add it to your
   Claude Code settings:

   ```json
   { "env": { "XCLOUD_API_TOKEN": "your-token-here" } }
   ```

   Use `~/.claude/settings.json` (global) or a project-local
   `.claude/settings.local.json` (keep it out of git). Restart Claude Code so it
   picks up the token.

3. **Check it works.** Ask Claude: *"Check my xCloud API connection."* A green
   light means you're ready.

### Other agent frameworks

The skills are plain Markdown + a shared `bash`/`curl` wrapper, so they port to
any agent that supports a skills directory:

```bash
git clone https://github.com/xCloudDev/xcloud-agent-skills.git
cp -r xcloud-agent-skills/plugins/xcloud/skills/* /your/agent/skills/
```

The shared layer (`plugins/xcloud/scripts/xcloud.sh`,
`plugins/xcloud/reference/{auth,conventions}.md`) is referenced by every skill
via `${CLAUDE_PLUGIN_ROOT}`.

## Example requests

You describe what you want; Claude chains the steps.

```text
List my xCloud servers.
Is example.com up right now?
Renew the SSL certificate for shop.example.com.
Update all plugins on example.com, but back up first.
Scan example.com for vulnerabilities and show me the critical ones.
Something's hammering my server from 203.0.113.7 — block it.
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

The skills authenticate with a
[Sanctum personal access token](https://laravel.com/docs/sanctum) (Bearer auth).
Generate one in the xCloud dashboard → **Profile → API Tokens → Generate New
Token**, choosing scopes:

| Scope | Grants |
|---|---|
| `read:sites` / `write:sites` | Reads / writes under `/sites/*` and `/ssl-certificates/*` |
| `read:servers` / `write:servers` | Reads / writes under `/servers/*` |
| `*` | Full access, including token management |

Prefer the narrowest scopes that cover your use. The base URL is environment
driven (`XCLOUD_API_BASE_URL`, default `https://app.xcloud.host`) — point it at a
local or white-label host without touching any skill. Full details in
[`plugins/xcloud/reference/auth.md`](plugins/xcloud/reference/auth.md).

## API reference

Full REST reference — every endpoint, request/response schema, and an interactive
try-it console:

- **API docs**: https://app.xcloud.host/api/v1/docs
- **Base URL**: `https://app.xcloud.host/api/v1`
- **Auth**: Bearer token (Sanctum)
- **Rate limit**: 60 requests/minute authenticated (10/min unauthenticated)

## Useful links

| Link | Use it for |
|---|---|
| [xCloud](https://xcloud.host) | Product landing page and hosting platform overview |
| [xCloud Dashboard](https://app.xcloud.host) | Generate API tokens and manage hosting resources |
| [User Guide](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md) | Task-first examples for using the skills with an agent |
| [Install & Usage Guide](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md) | Full install steps, routing rules, and smoke tests |
| [API Docs](https://app.xcloud.host/api/v1/docs) | Public API reference and schemas |
| [GitHub](https://github.com/xCloudDev/xcloud-agent-skills) | Source, issues, changelog, and contribution flow |

## Testing

Each skill ships a read-only `tests/smoke.sh`. Point it at a real resource and it
exercises that skill's core reads end-to-end:

```bash
export XCLOUD_API_TOKEN="your-token"
export XCLOUD_TEST_SERVER_UUID="..."   # for the servers suite
plugins/xcloud/skills/servers/tests/smoke.sh
```

The suites are read-only and tolerate optional sub-resources that a given
server/site type doesn't support.

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
- **Dashboard**: https://app.xcloud.host
- **User Guide**: https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md
- **Install Guide**: https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md
- **API docs**: https://app.xcloud.host/api/v1/docs
- **Official repository**: https://github.com/xCloudDev/xcloud-agent-skills
- **Development fork**: https://github.com/Asif2BD/xcloud-agent-skills
- **Issues**: https://github.com/xCloudDev/xcloud-agent-skills/issues
- **Changelog**: [`CHANGELOG.md`](CHANGELOG.md)

## License

MIT — see [`LICENSE`](LICENSE).

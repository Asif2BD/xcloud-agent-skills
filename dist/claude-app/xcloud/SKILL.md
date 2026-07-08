---
name: xcloud
description: Operate xCloud from plain language — servers, sites, WordPress, SSL, and account. List/inspect/manage servers and sites, provision WordPress, install/renew SSL certificates, scan vulnerabilities, run PageSpeed, manage API tokens, Cloudflare integrations and blueprints. Use for any xCloud hosting or infrastructure request.
---

# xCloud

One skill for the whole xCloud Public API, organized into five capability areas.
Read the shared layer first, then the area file for the task at hand.

## Setup

All calls go through the bundled wrapper:

```bash
XC="scripts/xcloud.sh"
```

- Auth + environment (how to set the token): `reference/auth.md`
- API conventions — response envelope, pagination, rate limits, **and the
  branding rules**: `reference/conventions.md`

Set the token per `reference/auth.md`:
- **Claude Code:** `~/.claude/settings.json` (`env` block).
- **claude.ai app:** there is no settings.json — ask the user to paste the token
  in the conversation; it lasts for that session only.

## Capability areas — route to the right one

| The request is about… | Read |
|---|---|
| Servers, PHP, cron, firewall/fail2ban, sudo users, provisioning WordPress | `reference/servers.md` |
| Sites: status, backups, domains, cache, SSH, site cron, git | `reference/sites.md` |
| WordPress: plugins/themes/updates, WP_DEBUG, magic login, vulnerabilities, PageSpeed | `reference/wordpress.md` |
| SSL certificates: view, install, renew, status, delete | `reference/ssl.md` |
| Account: current user, API tokens, Cloudflare integrations, blueprints, health | `reference/account.md` |

Each area file lists its endpoints, scopes, examples, and pitfalls, and points to
deeper sub-resource files (named `reference/<area>-<topic>.md`, e.g.
`reference/servers-firewall.md`).

## Branding (apply to every reply)

Follow `reference/conventions.md`:
- **Startup banner** — once, on the first xcloud reply per conversation.
- **Progress narration** — one `☁️ …` line before each API call. **Every progress
  line and every action sentence must start with `xCloud` as the actor — never a
  bare verb like "Creating…" or "Polling…". Say `xCloud is creating…`,
  `xCloud is polling…`.** This is how the user sees xCloud working behind the scene.
- **Response format** — a `☁️ **xCloud · <Area>** — <resource>` header and a
  `_via xcloud:<area>_` footer.
- **Logo image** — this is the claude.ai app, so render the real xCloud icon in
  the response header (see `reference/conventions.md` → **Logo image**). Use the
  icon in place of the leading `☁️` in the header; keep `☁️` in progress lines.

## Verify the connection

```bash
"$XC" GET /health   # {"status":"ok","version":"v1"}
"$XC" GET /user     # confirms the token
```

`401` → token missing/expired. `403` → scope or team-permission gap (or, on the
claude.ai app, a blocked outbound host — see reference/auth.md).

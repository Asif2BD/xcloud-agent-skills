---
name: xcloud-sites
description: Manage xCloud sites — list/inspect sites, status, events, deployment logs, monitoring, backups, rescue, snapshots, domains & redirections, cache purge, SSH/SFTP config, site cron jobs, git, and access logs. Use for any site lifecycle or delivery request. For SSL/certs see xcloud:ssl; for WordPress plugins/updates/vulnerabilities/PageSpeed see xcloud:wordpress; for server-level infra see xcloud:servers.
version: 3.0.0
author: xCloudDev
license: MIT
---

# xCloud Sites

Owns site lifecycle and delivery. Read the shared layer first for auth, base
URL, envelope, pagination, and rate limits:

- `reference/auth.md`
- `reference/conventions.md`

```bash
XC="scripts/xcloud.sh"
```

Scopes: reads need `read:sites`, writes need `write:sites`.

## Response format

Brand every user-facing reply (see `reference/conventions.md` →
**Response format**): open with `☁️ **xCloud · Sites** — <site domain>`, give the
trimmed result, and close with a `_via xcloud:sites_` line.

Narrate each call (see **Progress narration**): before every `$XC` call print one
line of what xCloud is doing, e.g. `☁️ xCloud is fetching site \`<domain>\`…`; the
first call of a task opens with `☁️ Starting an xCloud session…`.

On the **first** xcloud reply in a conversation, lead with the xCloud startup
banner (see `reference/conventions.md` → **Startup banner**) in a fenced code
block — once per conversation.

## Sub-resources (load on demand)

| Sub-resource | Reference file |
|---|---|
| Backups (trigger, list, settings, status, count) | `reference/backups.md` |
| Domains, redirections, web rules | `reference/domains.md` |
| Cache (purge, purge-all, settings) | `reference/cache.md` |
| SSH/SFTP config & keys | `reference/ssh.md` |
| Site cron jobs | `reference/cron-jobs.md` |

## Core endpoints

| Operation | Method + path |
|---|---|
| List sites | `GET /sites` |
| Get site | `GET /sites/{uuid}` |
| Status | `GET /sites/{uuid}/status` |
| Events | `GET /sites/{uuid}/events` |
| Deployment logs | `GET /sites/{uuid}/deployment-logs` |
| Monitoring (+ history) | `GET /sites/{uuid}/monitoring[/history]` |
| Access logs | `GET /sites/{uuid}/access-logs` |
| Git repo info | `GET /sites/{uuid}/git` |
| Snapshots | `GET /sites/{uuid}/snapshots` |
| Staging sites | `GET /sites/{uuid}/staging-sites` |
| Custom nginx / site scripts / IP access | `GET /sites/{uuid}/{custom-nginx,site-scripts,ip-access}` |
| Rescue site | `POST /sites/{uuid}/rescue` |

**Not here:** SSL → `xcloud:ssl`; WordPress/vulns/pagespeed → `xcloud:wordpress`;
servers → `xcloud:servers`.

## Common reads

Find a site by domain (resolve its UUID first):

```bash
"$XC" GET "/sites?search=example.com&per_page=20" \
  | jq '(.data.items // .data.data // []) | map({uuid, name, domain: .domain_name, status, type})'
```

Status + recent events (the go-to triage pair):

```bash
SITE_UUID='replace-me'
"$XC" GET "/sites/$SITE_UUID/status" | jq '.data'
"$XC" GET "/sites/$SITE_UUID/events" | jq '(.data.items // .data) | .[0:10]'
```

## Writes

Rescue a broken site (all flags optional booleans; pick the repairs you need):

```bash
"$XC" POST "/sites/$SITE_UUID/rescue" '{
  "isolate_user": true,
  "regenerate_nginx": true,
  "restart_nginx": true,
  "reinstall_php": false
}' | jq '.message'
```

## Pitfalls

- Many list endpoints differ in pagination shape — use
  `(.data.items // .data.data // [])`.
- Writes are async; confirm via `GET /sites/{uuid}/events`.
- A 502 with status still `provisioned` is usually a missing site OS user — pull
  `/sites/{uuid}/ssh` (`site_user`) and the server tasks to confirm.

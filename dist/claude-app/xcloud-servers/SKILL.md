---
name: xcloud-servers
description: Manage xCloud servers — list/inspect servers, monitoring, services, tasks, reboot, snapshots, sudo users, PHP versions, databases & database users, server cron jobs, firewall rules, fail2ban, and provisioning a new WordPress site onto a server. Use for any server-level infrastructure or server security (firewall/fail2ban) request. NOT site-level config (see xcloud:sites), NOT SSL certs (see xcloud:ssl), NOT WordPress app management (see xcloud:wordpress).
version: 3.0.0
author: xCloudDev
license: MIT
---

# xCloud Servers

Owns server infrastructure and server-level security. Read the shared layer
first for auth, base URL, envelope, pagination, and rate limits:

- `reference/auth.md`
- `reference/conventions.md`

```bash
XC="scripts/xcloud.sh"
```

Scopes: reads need `read:servers`, writes need `write:servers`.

## Response format

Brand every user-facing reply (see `reference/conventions.md` →
**Response format**): open with `☁️ **xCloud · Servers** — <server>`, give the
trimmed result, and close with a `_via xcloud:servers_` line.

Narrate each call (see **Progress narration**): before every `$XC` call print one
line of what xCloud is doing, e.g. `☁️ xCloud is fetching server \`<name>\`…`; the
first call of a task opens with `☁️ Starting an xCloud session…`.

On the **first** xcloud reply in a conversation, lead with the xCloud startup
banner (see `reference/conventions.md` → **Startup banner**) in a fenced code
block — once per conversation.

## Sub-resources (load on demand)

Big domain — detailed per-sub-resource guidance lives in `reference/`:

| Sub-resource | Reference file |
|---|---|
| PHP versions (install, default, opcache, patch) | `reference/php-versions.md` |
| Server cron jobs (CRUD, execute, output) | `reference/cron-jobs.md` |
| Databases & database users | `reference/databases.md` |
| Firewall rules, fail2ban, IP whitelisting | `reference/firewall.md` |
| Sudo users | `reference/sudo-users.md` |

## Core endpoints

| Operation | Method + path |
|---|---|
| List servers | `GET /servers` |
| Get server | `GET /servers/{uuid}` |
| List sites on server | `GET /servers/{uuid}/sites` |
| Monitoring (+ history) | `GET /servers/{uuid}/monitoring[/history]` |
| Services | `GET /servers/{uuid}/services` |
| Restart a service | `POST /servers/{uuid}/services/restart` |
| Recent tasks | `GET /servers/{uuid}/tasks` |
| Snapshots | `GET /servers/{uuid}/snapshots` |
| Supervisor processes | `GET /servers/{uuid}/supervisor-processes` |
| Reboot server | `POST /servers/{uuid}/reboot` |
| Create WordPress site on server | `POST /servers/{uuid}/sites/wordpress` |

**Not here:** site settings → `xcloud:sites`; SSL → `xcloud:ssl`; WordPress
plugins/themes/updates → `xcloud:wordpress`.

## Common reads

List servers:

```bash
"$XC" GET "/servers?per_page=100" \
  | jq '(.data.items // .data.data // []) | map({uuid, name, status, ip: (.ip_address // .ip)})'
```

One server + its monitoring:

```bash
SERVER_UUID='replace-me'
"$XC" GET "/servers/$SERVER_UUID" | jq '.data'
"$XC" GET "/servers/$SERVER_UUID/monitoring" | jq '.data'
```

Recent tasks (use after any async write to confirm progress):

```bash
"$XC" GET "/servers/$SERVER_UUID/tasks" | jq '(.data.items // .data) | map({uuid, type, status, created_at})'
```

## Common writes

Reboot (async — poll tasks afterward):

```bash
"$XC" POST "/servers/$SERVER_UUID/reboot" | jq '.message'
```

Restart a service:

```bash
"$XC" POST "/servers/$SERVER_UUID/services/restart" '{"service":"nginx"}' | jq '.message'
```

Create a WordPress site on the server (live mode needs `domain` + `ssl`; omit
`domain` for demo). `blueprint_uuid` and `snapshot_uuid` are mutually exclusive;
auto-generated credentials are returned only once.

```bash
"$XC" POST "/servers/$SERVER_UUID/sites/wordpress" '{
  "mode": "live",
  "domain": "example.com",
  "title": "My Site",
  "php_version": "8.2",
  "ssl": {"provider": "letsencrypt"},
  "cache": {"full_page": true, "object_cache": true}
}' | jq '.data'
# then poll site provisioning:  GET /sites/{new_uuid}/status   (xcloud:sites)
```

## Pitfalls

- Server writes are async; success is returned before work completes — poll
  `GET /servers/{uuid}/tasks`.
- WordPress creation lives here (the URL is `/servers/...`), but the resulting
  site is then managed via `xcloud:sites` / `xcloud:wordpress`.
- `setting default PHP` and `patching PHP` do not enforce a `write:servers`
  scope line in the docs but still require server write permission in practice.

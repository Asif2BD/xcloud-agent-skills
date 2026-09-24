# xCloud Skills — Install & Usage Guide

A step-by-step guide to installing and using the **xCloud Public API skills**
(plugin `xcloud` v4.4.1) inside Claude Code.

The plugin ships **nine skills**, each owning one capability area of the API.
You don't call them directly — you describe what you want in plain language and
Claude picks the right skill automatically.

| Skill | Owns | Typical asks |
|---|---|---|
| `xcloud:deploy` | Deploy a Git repo, Docker Compose app, one-click app, Git staging environment or WordPress site end to end; diagnose and retry failed deploys; redeploys | "deploy github.com/acme/shop", "install Uptime Kuma", "my last deploy failed", "deploy latest commit" |
| `xcloud:troubleshoot` | A site that errors: status, recent events, nginx access and error log, WordPress health, WP_DEBUG, services, temporary shell access | "example.com shows a 500", "my site has a critical error", "why is my site down" |
| `xcloud:performance` | A slow site: site and server monitoring, cache layers, PageSpeed, traffic, the site's PHP version | "my site is slow", "is Redis on for shop.example.com", "why is TTFB so high" |
| `xcloud:servers` | Servers: buy a server, services, Node/PHP versions, verified reboots, cron, firewall/fail2ban, sudo users, DNS checks | "reboot server X", "install Redis", "switch Node to 22", "ban this IP" |
| `xcloud:sites` | Site lifecycle: status, backups (incl. Docker apps), staging, domains, cache, SSH, site cron, monitoring, deletion | "back up example.com", "show site events", "purge the cache" |
| `xcloud:wordpress` | WP plugins/themes/updates, WP_DEBUG, magic login, site/team vulnerabilities, PageSpeed, broken links | "update WooCommerce", "show team vulnerabilities", "find broken links" |
| `xcloud:ssl` | SSL certificates: view, install, renew, status, delete | "renew SSL for example.com", "install a Let's Encrypt cert" |
| `xcloud:billing` | Plan, invoices, bills, prices, paying an invoice, mailboxes and mail delivery | "what plan am I on", "last month's invoice", "buy a mailbox" |
| `xcloud:account` | Current user, teams, incident alerts, API tokens, Git/Cloudflare integrations, blueprints, health | "who am I", "switch to the Acme team", "any unread alerts?" |

---

## 1. Install

### 1.1 Add the marketplace and install the plugin

In Claude Code:

```
/plugin marketplace add xCloudDev/xcloud-agent-skills
/plugin install xcloud
/reload-plugins
```

After reload, confirm the nine skills are present:

```
/plugin
```

You should see `xcloud:deploy`, `xcloud:troubleshoot`, `xcloud:performance`,
`xcloud:servers`, `xcloud:sites`, `xcloud:wordpress`, `xcloud:ssl`,
`xcloud:billing`, and `xcloud:account`.

> Installing v3.0.0 renames the plugin to `xcloud` and shortens the skill IDs to
> `xcloud:servers`, `xcloud:sites`, `xcloud:wordpress`, `xcloud:ssl`, and
> `xcloud:account`. If you previously installed `xcloud-public-api`, reinstall.
> The v1 single skill remains available at the `v1.2.0` git tag if you need it.

---

## 2. Connect your xCloud account

### 2.0 Recommended — the xCloud MCP connector (no token needed)

The fastest, safest connection is the **xCloud MCP server** — browser OAuth, no
secret to store, per-action confirmation on every destructive operation, and
one native tool per authenticated API operation plus two search tools
(`xcloud_agent_search` for jobs, `xcloud_docs_search` for questions) that the
skills use automatically. Clients that cap tool counts (Cursor: 40) use the
compact profile, `https://app.xcloud.host/mcp?profile=compact`:

```bash
claude mcp add xcloud --transport http https://app.xcloud.host/mcp
```

Then run `/mcp` → **Authenticate** and grant **Read** or **Read & write**.
Other clients (Claude Desktop, claude.ai, Cursor): add a custom connector with
URL `https://app.xcloud.host/mcp`. Full instructions:
<https://app.xcloud.host/mcp/docs>.

With the MCP connected you can **skip the token setup below** — every read and
every change runs through it. The token below is only for agents without MCP
support, and it is **read-only**: the bundled wrapper sends `GET` requests only.
Changes (deploys, SSL, backups, purchases) always need the MCP; revoking API
tokens is done in the dashboard (**Account → API Tokens**).

### 2.1 Read-only REST fallback — API token

Without MCP, the skills can still look at your account with a Sanctum personal
access token. Generate one in
the xCloud dashboard → **Account → API Tokens → Generate New Token**, choosing
**read** scopes only (`read:sites`, `read:servers`, and `read:billing` /
`read:addons` if you want billing answers). Write scopes add risk and no
capability here. Copy it immediately — it's shown only once.

Pick **one** persistent option:

**Option A — Claude Code settings (recommended):**
```json
// ~/.claude/settings.json
{ "env": { "XCLOUD_API_TOKEN": "your-token-here" } }
```

**Option B — shell profile:**
```bash
echo "export XCLOUD_API_TOKEN='your-token-here'" >> ~/.zshrc && source ~/.zshrc
```

**Option C — inline, one session only (not persistent):**
```bash
XCLOUD_API_TOKEN=... <command>
```

If the token is missing, the xCloud skills should proactively guide you through
this setup and then verify with `/health` and `/user`. Do not paste long-lived
production tokens into chat by default; use a runtime env var, settings file, or
secret store whenever possible.

---

## 3. Choose live or local

The skills default to the live host. Switch environments with **one env var** —
no code change:

```bash
# Live (default — you can leave this unset)
export XCLOUD_API_BASE_URL="https://app.xcloud.host"

# Local development (plaintext http needs the explicit override)
export XCLOUD_API_BASE_URL="http://xcloud.test"
export XCLOUD_ALLOW_INSECURE_HTTP=1
```

---

## 4. How to use the skills

Just talk to Claude. The skill descriptions are written so Claude routes your
request to the right one. Examples of what to type:

- "List my xCloud servers."
- "Renew the SSL certificate for shop.example.com."
- "Update all plugins on example.com, backing up first."
- "Scan example.com for vulnerabilities and show critical findings."
- "Purge the cache on example.com."

Claude resolves UUIDs for you (it lists sites/servers first), runs the call
through the shared wrapper, and returns a trimmed summary.

### Verify everything works

Ask Claude: **"Check my xCloud API connection."** It will run the equivalent of:

```bash
XC="${CLAUDE_PLUGIN_ROOT}/scripts/xcloud.sh"
"$XC" GET /health   # {"status":"ok","version":"v1"}
"$XC" GET /user     # confirms the token
```

`401` → token missing/expired. `403` → token lacks a scope or team permission.

---

## 5. Use cases per skill (with small examples)

Each example shows the **prompt** you'd give Claude and the **calls** the skill
makes under the hood. Two notations:

- `"$XC" GET …` — a read through the bundled REST wrapper (`$SITE`/`$SRV` = a
  resolved UUID). The wrapper is read-only: `GET` only.
- `tool_name  {…}` — an xCloud MCP tool call with its arguments. Every change
  runs this way; tools marked *destructive* are sent with `confirm: true` only
  after your explicit yes. Without the MCP connection the skill offers to
  connect it first.

### 5.1 `xcloud:servers`

Server infrastructure and server-level security.

**Reboot a server** (verified: xCloud confirms the machine came back)
> "Reboot my Hermes server."
```text
servers_reboots_store  {"uuid": "<server-uuid>"}  # destructive: confirm: true after the user's yes
servers_reboots_show   {"uuid": "<server-uuid>", "operationUuid": "<data.uuid from the store call>"}
```

**Install and default a PHP version**
> "Install PHP 8.3 on that server and make it the default."
```text
servers_php-versions_install  {"uuid": "<server-uuid>", "php_version": "8.3"}  # destructive: confirm: true after the user's yes
servers_php-versions_default  {"uuid": "<server-uuid>", "version": "8.3"}  # destructive: confirm: true after the user's yes
```

**Ban an abusive IP (fail2ban)**
> "Ban 203.0.113.7 on server X."
```bash
servers_fail2ban_ban  {"uuid": "<server-uuid>", "ip_addresses": ["203.0.113.7"]}  # destructive: confirm: true after the user's yes
```

**Disable a service**
> "Disable Redis on server X."
```text
servers_services_disable  {"uuid": "<server-uuid>", "service": "redis"}  # destructive: confirm: true after the user's yes
```
Require explicit confirmation first; disabling services can cause downtime or
lockout.

**Create a database + user** ⚠️ *not available on the current public API — these
endpoints return 404 today (see `docs/API-COVERAGE.md`); shown as a
forward-looking example only*
> "Create a database app_prod with a user on server X."
```text
POST /servers/{uuid}/databases       {"database_name": "app_prod"}
POST /servers/{uuid}/database-users  {"username": "app_user", "password": "<strong>", "databases": ["app_prod"]}
```
(No MCP tool exists for these yet; nothing to run today.)

### 5.2 `xcloud:sites`

Site lifecycle and delivery.

**Back up a site**
> "Back up example.com before I deploy."
```text
sites_backup  {"uuid": "<site-uuid>", "type": "local"}
"$XC" GET  "/sites/$SITE/backup-status"
```

**Triage a down site**
> "example.com is throwing 502 — what's going on?"
```bash
"$XC" GET "/sites/$SITE/status"
"$XC" GET "/sites/$SITE/events"
"$XC" GET "/sites/$SITE/ssh"     # check site_user for a missing OS user
```

**Purge cache**
> "Clear the cache on example.com."
```text
sites_cache_purge-all  {"uuid": "<site-uuid>"}
```

**Switch SSH to key auth**
> "Set example.com SSH to public-key auth with my key."
```text
sites_ssh_update  {"uuid": "<site-uuid>", "authentication_mode": "public_key", "ssh_public_keys": ["ssh-ed25519 AAAA..."]}  # destructive: confirm: true after the user's yes
```

### 5.3 `xcloud:wordpress`

WordPress app management, vulnerabilities, PageSpeed.

**Update specific plugins, with a backup first**
> "Update WooCommerce and Akismet on example.com, back up first."
```text
sites_wordpress_update  {"uuid": "<site-uuid>", "type": "plugin", "slugs": ["woocommerce", "akismet"], "backup_before_update": true}  # destructive: confirm: true after the user's yes
```

**Run a vulnerability scan and review**
> "Scan example.com for vulnerabilities and show me the critical ones."
```text
sites_vulnerability-scan  {"uuid": "<site-uuid>"}
"$XC" GET  "/sites/$SITE/vulnerabilities/count"
"$XC" GET  "/sites/$SITE/vulnerabilities"
```

**Check performance**
> "What's the PageSpeed score for example.com?"
```text
sites_pagespeed_scan  {"uuid": "<site-uuid>"}
"$XC" GET  "/sites/$SITE/pagespeed"
```

**One-time admin login**
> "Give me a magic login link for example.com."
```text
sites_magic-login  {"uuid": "<site-uuid>", "login_as": "admin"}  # destructive: confirm: true after the user's yes
```

### 5.4 `xcloud:ssl`

SSL certificates and HTTPS.

**Install a Let's Encrypt certificate**
> "Set up HTTPS for newsite.example.com with Let's Encrypt."
```text
sites_sslCertificates_create  {"uuid": "<site-uuid>", "provider": "xcloud"}  # destructive: confirm: true after the user's yes
```

**Renew before expiry**
> "Renew the SSL cert for example.com."
```text
# a no-op unless the cert expires within 7 days; "force": true renews now
sites_ssl_renew  {"uuid": "<site-uuid>"}  # destructive: confirm: true after the user's yes
sites_ssl_renew  {"uuid": "<site-uuid>", "force": true}  # destructive: confirm: true after the user's yes
```

**Check cert status**
> "Is example.com's certificate valid?"
```bash
"$XC" GET "/sites/$SITE/ssl"
```

### 5.5 `xcloud:account`

Identity and org-level reads.

**Who am I / which team**
> "Who am I on xCloud?"
```bash
"$XC" GET /user
```

**List tokens; revoke in the dashboard**
> "List my API tokens — which one is the old CI token?"
```bash
"$XC" GET /user/tokens    # needs a full-access (*) token; otherwise use the dashboard
```
Revoking is dashboard-only (**Account → API Tokens**): neither the read-only
wrapper nor the MCP can revoke a token.

**Teams and alerts**
> "Which teams can you see? Any unread error alerts on the Acme team?"
```bash
"$XC" GET /teams
XCLOUD_TEAM_ID="$ACME_TEAM_UUID" "$XC" GET "/alerts?unread=true&severity=error"
```

**List blueprints** (before creating a WordPress site)
> "Show me my WordPress blueprints."
```bash
"$XC" GET "/blueprints?per_page=100"
```

### 5.6 `xcloud:deploy`

Getting code and apps live, and recovering failed deploys. On MCP the skill
runs `xcloud_agent_search` first and follows the returned steps.

**Deploy a GitHub URL**
> "Deploy https://github.com/acme/shop to my Frankfurt server."
```text
git_detect              {"repository_url": "https://github.com/acme/shop", "server_uuid": "<server-uuid>"}
servers_sites_git_auto  {"uuid": "<server-uuid>", "repository": {"url": "https://github.com/acme/shop"}, "dry_run": true}
# after "yes" on the preview: the same arguments without dry_run
servers_sites_git_auto  {"uuid": "<server-uuid>", "repository": {"url": "https://github.com/acme/shop"},
                         "Idempotency-Key": "<one key for this site>", "confirm": true}
sites_status            {"uuid": "<new site uuid>"}   # poll until terminal, then open the URL
```

**Recover a failed deploy**
> "The last deploy of the API site failed — fix it."
```text
"$XC" GET "/sites/$SITE/deploy-diagnosis"     # classification, explanation, correctable_fields
sites_provision-retry  {"uuid": "<site-uuid>", "corrections": {"build_command": "npm run build"},
                        "Idempotency-Key": "<one key for this retry>"}  # destructive: confirm: true after the user's yes
```

**Ship the latest commit / change deploy settings**
> "Deploy the latest Git commit for example.com."
```text
sites_git_update  {"uuid": "<site-uuid>", "git_branch": "main", "enable_push_deploy": true}  # destructive: confirm: true after the user's yes
sites_git_deploy  {"uuid": "<site-uuid>"}  # destructive: confirm: true after the user's yes
```

**Install a one-click app**
> "Install Uptime Kuma on my Docker server."
```bash
"$XC" GET "/oneclick-apps?search=uptime"
"$XC" GET "/servers/$SRV/oneclick-apps/$SLUG/compatibility"
```

### 5.7 `xcloud:billing`

Plans, invoices, prices and paid add-ons. Every purchase or payment waits for
an explicit yes with the price.

**Latest invoice**
> "Show me last month's invoice and its total."
```bash
"$XC" GET "/billing/invoices?per_page=5"
"$XC" GET "/billing/invoices/$INVOICE_NUMBER"
```

**Mailbox DNS**
> "Which DNS records do I still need for hello@example.com?"
```text
"$XC" GET /addons/mailbox
addons_mailbox_verify-dns  {"mailbox": "<mailbox-uuid>"}  # destructive: confirm: true after the user's yes
```

---

## 6. Real-world workflows (how users actually use it)

The examples above are single calls. In practice a user drives Claude through a
whole task in plain language, and Claude chains the skills for them. Three common
end-to-end flows:

### 6.1 Monday-morning health audit

> "Audit example.com: is it up, is SSL healthy, any vulnerabilities, and how's
> performance?"

Claude resolves the site UUID once, then fans out across **three** skills:

```text
# xcloud:sites  — is it alive?
"$XC" GET "/sites/$SITE/status"
# xcloud:ssl    — cert valid / expiring?
"$XC" GET "/sites/$SITE/ssl"
# xcloud:wordpress — security + speed
sites_vulnerability-scan  {"uuid": "<site-uuid>"}
"$XC" GET  "/sites/$SITE/vulnerabilities/count"
sites_pagespeed_scan  {"uuid": "<site-uuid>"}
"$XC" GET  "/sites/$SITE/pagespeed"
```

You get one consolidated summary: uptime, days-to-cert-expiry, critical CVE
count, PageSpeed score — without naming a single endpoint.

### 6.2 Safe WordPress update

> "WooCommerce has an update — apply it to example.com but back up first and
> tell me if anything looks off."

```text
# 1. snapshot first (xcloud:sites)
sites_backup  {"uuid": "<site-uuid>", "type": "local"}
"$XC" GET  "/sites/$SITE/backup-status"          # wait for "completed"
# 2. update with built-in pre-update backup (xcloud:wordpress)
sites_wordpress_update  {"uuid": "<site-uuid>", "type": "plugin", "slugs": ["woocommerce"],
                         "backup_before_update": true}  # destructive: confirm: true after the user's yes
# 3. confirm the site still serves (xcloud:sites)
"$XC" GET "/sites/$SITE/status"
```

If status comes back unhealthy, Claude surfaces it immediately and points you to
the backup it just took — restoring is one click in the dashboard (**Site →
Backups → Restore**).

### 6.3 New site go-live

> "I just provisioned shop.example.com — set up HTTPS and confirm it's serving."

```text
# 1. install Let's Encrypt cert (xcloud:ssl)
sites_sslCertificates_create  {"uuid": "<site-uuid>", "provider": "xcloud"}  # destructive: confirm: true after the user's yes
"$XC" GET  "/sites/$SITE/ssl"                    # wait for issued/active
# 2. verify delivery (xcloud:sites)
"$XC" GET "/sites/$SITE/status"
# 3. baseline performance (xcloud:wordpress)
sites_pagespeed_scan  {"uuid": "<site-uuid>"}
```

The point: users think in **tasks** ("go live", "audit", "update safely"), not
endpoints. The skills are sliced so one task maps cleanly onto one short
conversation.

---

## 7. How requests get routed (and avoiding surprises)

Skills are organized by **capability**, which sometimes differs from where the
endpoint lives in the URL. A few rules to keep in mind:

- **SSL** is always `xcloud:ssl`, even though certs hang off `/sites/...`.
- **WordPress updates, vulnerabilities, and PageSpeed** are `xcloud:wordpress`,
  even for the site-level paths.
- **Firewall and fail2ban** are `xcloud:servers` (server security), not a
  separate security skill.
- **Cron** exists on both servers and sites — say "server cron" or "site cron"
  if it's ambiguous.
- **Creating anything that runs code** — a Git site, Docker app, one-click app,
  staging environment or WordPress site — and fixing a failed deploy is
  `xcloud:deploy`, even though the create URLs live under `/servers/...`.
- **Money** (plans, invoices, add-on purchases) is `xcloud:billing`; buying a
  server itself is `xcloud:servers`.

If Claude picks the wrong skill, name it explicitly: *"Using xcloud:ssl, renew
the cert for example.com."*

---

## 8. Running the smoke tests (optional)

Each skill ships a read-only smoke test. To run one against your local
environment:

```bash
export CLAUDE_PLUGIN_ROOT="$PWD/plugins/xcloud"
export XCLOUD_API_BASE_URL="http://xcloud.test"
export XCLOUD_ALLOW_INSECURE_HTTP=1   # plaintext http is refused without this
export XCLOUD_API_TOKEN="your-token"
export XCLOUD_TEST_SITE_UUID="<a-real-site-uuid>"
export XCLOUD_TEST_SERVER_UUID="<a-real-server-uuid>"

bash plugins/xcloud/skills/sites/tests/smoke.sh
```

The tests never mutate anything: they send `GET` requests only, through the
read-only wrapper. Repository detection (`git_detect`) runs on the MCP, so the
deploy suite does not cover it; it checks the catalog, Git integrations, staging
hostname and deploy keys, and that the wrapper refuses a `POST`.

---

## 9. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `XCLOUD_API_TOKEN is not set` | No token in env | Set it (section 2) |
| `401` on any call | Token missing/expired/revoked | Regenerate the token |
| `403` with a valid token | Missing scope or team permission (e.g. `site:manage-ssl`) | Grant the scope/permission |
| `429` | Rate limit (60/min auth) | Wait for `Retry-After` |
| Wrong skill triggered | Ambiguous phrasing | Name the skill explicitly |
| Calls hit the wrong host | `XCLOUD_API_BASE_URL` set unexpectedly | Unset for live, or point at `xcloud.test` for local |

---

## Reference

- Shared auth details: `plugins/xcloud/reference/auth.md`
- Shared API conventions: `plugins/xcloud/reference/conventions.md`
- Architecture rationale: `docs/adr/0001-capability-domain-skills.md`
- Glossary: `CONTEXT.md`
- Full API docs: `https://app.xcloud.host/api/v1/docs`

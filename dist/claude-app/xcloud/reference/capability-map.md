# What the API cannot do (shared)

Shared by every `xcloud:*` domain skill. Before promising a job, check it here.
Most of xCloud is on the API; the rows below are the exceptions, in one place,
so an agent can say "that is a dashboard step: **Site → Cache**" instead of
guessing an operation or reporting a 404 as an outage.

Every job falls into one of five kinds:

| Kind | Meaning | What the agent does |
|---|---|---|
| **api** | An operation does the whole job | Do it (with confirmation where the class needs it) |
| **api_read** | The API reads it; changing it is dashboard-only | Read it, report it, then hand off with the dashboard path |
| **rest** | Public REST only, no MCP tool | Reads: the read-only REST wrapper (`GET`). Changes: the dashboard path — the wrapper sends nothing else |
| **ui** | Dashboard only, nothing on the API | Give the dashboard path and the site's or server's `dashboard_url` |
| **impossible** | xCloud refuses it outright | Say so plainly, with the reason, and offer the alternative |

Always give the `dashboard_url` from the server or site read (`servers.show`,
`sites.show`) next to the path — never construct one. On MCP,
`xcloud_agent_search` returns the same `ui` and impossible steps inside a job's
guidance.

## Dashboard-only jobs

| Job | Kind | Dashboard path | What the API does instead |
|---|---|---|---|
| Turn page cache, object cache (Redis) or Cloudflare edge cache on or off | api_read | **Site → Cache** | `sites.cacheSettings` reads every layer; `sites.cache.purge` / `sites.cache.purge-all` purge |
| Change **one site's** PHP version | api_read | **Site → Settings → PHP version** | `sites.wordpress.status` reads it; PHP is managed per **server** (`servers.php-versions.*`) — a server install moves no site, a server default moves every site that follows it |
| Read the PHP-FPM error log, the WordPress `debug.log`, docker-compose, PM2 or OpenClaw logs | ui | **Site → Logs** | `sites.access-logs` (`type=nginx`: access, error and 7G logs), `sites.events`; `sites.wp-debug` only toggles the flag |
| Add, change or remove a domain on an existing site | api_read | **Site → Domain** | `sites.domain`, `sites.domains`, `sites.domainUpdateStatus`, `servers.dns.check`; a live domain is chosen at creation |
| Create or edit redirects, web rules or custom nginx | api_read | **Site → Tools** | `sites.redirections`, `sites.webRules`, `sites.customNginx` list them |
| Restore a site from a backup (native or Docker) | ui | **Site → Backups → Restore** | `sites.backups`, `sites.docker.backups` list them; `sites.backup` takes one |
| Change a native site's backup schedule, retention or destination | api_read | **Site → Backups → Backup settings** | `sites.backupSettings` reads; Docker sites are the exception — `sites.docker.backupSettings.update` writes |
| Apply backup settings to many sites at once | ui | **Team settings → Global backup settings** | — |
| Add or change a backup storage provider | ui | **User → Storage providers** | Backup settings return the provider's uuid and status, never its credentials |
| Enable, schedule or restore a server backup (the cloud provider's image of the whole server) | ui | **Server → Backups** | — `servers.snapshots` lists the **site** snapshots taken on that server, and `sites.snapshots` one site's; neither is a server backup |
| Push staging to production, pull production to staging | api_read | **Site → Staging → Push / Pull** | `sites.deployment-logs` is the push/pull history |
| Create a **WordPress** staging environment | ui | **Site → Staging** | `sites.stagingSites.create` covers Git sites only (Laravel, Node.js, custom PHP, Lovable); WordPress answers `422` |
| Databases and database users | ui | **Server → Database** | — (withheld from the public API) |
| Connect a server from the customer's own cloud account, or a self-managed server | ui | **Dashboard → Servers → Create server** | `servers.store` buys xCloud-managed servers only |
| Install n8n, Supabase, Nextcloud, Mautic, LibreChat, Open WebUI, Ollama, Umami, WireGuard, phpMyAdmin or Site.pro | ui | **Server → Sites → Create → One-Click Apps** | `catalog.apps.index` lists them; `oneclickApps.install` answers `404` for these eleven |
| Change or cancel a subscription, change the card, see payment history or refunds | ui | **Dashboard → Billing** | `billing.*` reads plan, invoices and subscriptions; `payments.pay` settles an outstanding invoice |
| Grant more teams to an API token or MCP connection | ui | **Account → API Tokens**, or the OAuth consent screen when reconnecting | `teams.index` lists the teams already granted |
| Revoke an API token | rest | **Account → API Tokens** | `user.tokens.index` lists them through the read-only wrapper (`GET /user/tokens`); `user.tokens.revoke` is a REST `DELETE` the wrapper refuses and no MCP tool offers |

## Without an MCP connection

Every change runs on the xCloud MCP; the bundled REST wrapper only reads
(`reference/conventions.md` → Transports). When a change is asked for and the
MCP is not connected, offer to connect it first. Only if the user cannot or
will not, give the dashboard path for that one action — these are the common
ones, checked against xCloud's documentation:

| Change | Dashboard path |
|---|---|
| Deploy from Git | **Add New Site** → pick the server → **Deploy via Git** |
| New WordPress site | **Add New Site** → pick the server → **Install a New WordPress Website** |
| New server | **Servers** → **Create server** |
| Purge cache | **Site → Cache** → **Purge Cache** |
| HTTPS / SSL | **Site → Domain → SSL/HTTPS** |
| Staging | **Site → Staging** (create, **Push / Pull**) |
| Backups | **Site → Backups** (**Backup settings**, **Restore**) |
| Plugin, theme, core updates | **Site → WordPress → Updates**; across sites: **Team Settings → Updates Manager** |
| Vulnerabilities | **Site → WordPress → Vulnerability Scan** |
| PHP version | **Site → Settings → PHP version** |
| Redirects, web rules, custom Nginx | **Site → Tools → Redirects / Web rules / Custom nginx** |
| Delete a site | The site's **⋯** menu → **Delete Site** |
| Cron jobs | **Server → Cron Jobs** → **Add Cron Job** |
| Firewall | **Server → Security → Firewall Management** |
| Restart a service | **Server → Server Management** (services) |
| Restart the server | The server's **Actions** menu → **Restart Server** |
| API tokens | **Account → API Tokens** |
| Cloudflare integration | **Profile → Integrations → Cloudflare** |

For anything not listed, name the site or server page that owns the setting and
say the exact label may differ; never invent a path.

## Impossible jobs

| Job | Why | Offer instead |
|---|---|---|
| Add a second site (WordPress, Git or one-click) to an **agentic** server — OpenClaw, Paperclip, Hermes, DeepSeek Harness | These stacks host only the one site created while the server was provisioned. The dashboard refuses it too; it is not a permission support can grant. | A new server for the second site |
| Create a WordPress site on a **Docker** server | `422` "WordPress is not supported on Docker servers" | An Nginx or OpenLiteSpeed server, or deploy the repository as a Docker site |

## Status codes are not uniform — match on the message

The same kind of refusal can come back as `403` on one endpoint and `422` on
another, and a `403` is not always a missing permission. Branch on the
`message` (and `errors.code` where the response carries one), never on the
status code alone:

| Situation | Status | What the response says |
|---|---|---|
| WordPress create on an agentic server | `403` | "OpenClaw servers support only one site, created automatically during provisioning" (OpenClaw) or "Agentic servers support only the site created automatically during provisioning" |
| Git create or auto-deploy on an agentic server | `403` | "Agentic servers support only the site created during provisioning" |
| Docker deploy (`servers.sites.git.docker`) on any non-Docker server, agentic included | `422` | `errors.code: incompatible_server` |
| One-click install on a server of the wrong stack | `422` | "This app requires a … server. This server is on the … stack." |
| WordPress create on a Docker server | `422` | "WordPress is not supported on Docker servers" |
| Staging create for a WordPress site | `422` | "WordPress staging is not available via the API…" (and `403` on a free plan) |
| Monitoring history on a free plan | `403` | "Monitoring history is not available on the free plan." — a plan limit, not a permission |
| The caller's team role or team permissions do not allow it | `403` | "Your team permissions do not allow: site:manage-monitoring" (the permission is named), or "Your team role does not permit access to site resources" |
| The token lacks the scope (ability) | `403` | "This action is unauthorized." |

So: an agentic refusal is final whatever its code — do not retry it on another
endpoint and do not ask for more permissions. A plan-limit `403` is answered
with the plan, not with "you lack access". Only a `403` that names a team
permission or role, or the bare "This action is unauthorized." of a missing
token scope, is fixed by changing the role or the token.

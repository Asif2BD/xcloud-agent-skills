#!/usr/bin/env node
/**
 * build.mjs — generate the Scalar document for the xCloud agent skills landing
 * page.
 *
 * This is a GUIDE/landing page, not an API endpoint reference. It renders the
 * introduction (what the skills are, how to install, example requests) and
 * links out to the full xCloud Public API reference. It intentionally contains
 * no API operations.
 *
 * Regenerate:
 *   node docs/scalar/build.mjs
 *
 * Output: ./xcloud-skills.openapi.json  (loaded by ./index.html)
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const PLUGIN_VERSION = JSON.parse(
  readFileSync(join(HERE, '../../plugins/xcloud/.claude-plugin/plugin.json'), 'utf8'),
).version;

// The full xCloud Public API reference. When this document is served by the
// xCloud app (routes/web.php → /agent/skills), the `app.xcloud.host` host is
// rewritten to the current host, so this resolves correctly on white-label and
// staging deployments too.
const XCLOUD_API_DOCS_URL = 'https://app.xcloud.host/api/v1/docs';
const XCLOUD_MCP_DOCS_URL = 'https://app.xcloud.host/mcp/docs';

const INFO_DESCRIPTION = `
The **xCloud agent skills** let any AI agent (Claude Code, OpenCode, and others)
operate xCloud in plain language — *"reboot my Hermes server"*, *"renew SSL for
example.com"*, *"scan example.com for vulnerabilities"*. You describe what you
want; the agent picks the right skill and chains the steps.

> **Skills repo:** <https://github.com/xCloudDev/xcloud-agent-skills>
> **User guide:** <https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md>
> **Install & call reference:** <https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md>

## xCloud MCP and API

The skills prefer the **xCloud MCP server** and retain the Public API wrapper as
a REST fallback:

### → [Connect the xCloud MCP](${XCLOUD_MCP_DOCS_URL})
### → [xCloud API](${XCLOUD_API_DOCS_URL})

## The nine skills

You never name them — the agent picks the right one from what you ask.

| Skill | Owns |
|---|---|
| \`xcloud:deploy\` | Deploy a GitHub URL, Docker Compose app, one-click app, Git staging environment or WordPress site end to end; diagnose and retry failed deploys |
| \`xcloud:troubleshoot\` | A site that errors (500/502, critical error): status, events, nginx logs, WordPress health, WP_DEBUG, services |
| \`xcloud:performance\` | A slow site: monitoring, cache layers, PageSpeed, traffic, the site's PHP version |
| \`xcloud:servers\` | Servers: buy a server, services, Node/PHP versions, verified reboots, cron, firewall/fail2ban, sudo users, DNS checks |
| \`xcloud:sites\` | Site lifecycle: status, backups (incl. Docker apps), staging, domains, cache, SSH, site cron, deletion |
| \`xcloud:wordpress\` | WP plugins/themes/updates, WP_DEBUG, magic login, vulnerabilities, PageSpeed, broken links |
| \`xcloud:ssl\` | SSL certificates: view, install, renew, status, delete |
| \`xcloud:billing\` | Plan, invoices, prices, paying an invoice, mailboxes and mail delivery |
| \`xcloud:account\` | Current user, teams, incident alerts, API tokens, Git/Cloudflare integrations, blueprints, health |

## Install in Claude Code

1. **Connect the xCloud MCP server:**

   \`\`\`bash
   claude mcp add xcloud --transport http https://app.xcloud.host/mcp
   \`\`\`

   Run \`/mcp\` → **Authenticate** and grant read or read/write access.

2. **Install the plugin:**

   \`\`\`
   /plugin marketplace add xCloudDev/xcloud-agent-skills
   /plugin install xcloud
   /reload-plugins
   \`\`\`

3. **Check it works.** Ask Claude: *"Check my xCloud connection."* Green light
   = you're ready.

No MCP support? Use the REST fallback: create a scoped API token in the xCloud
dashboard and store it as \`XCLOUD_API_TOKEN\` in your runtime or secret store.
Do not paste a long-lived production token into chat.

That's it — everything below is just talking to Claude.

## Example requests

You don't name skills or endpoints — describe what you want in plain language and
Claude picks the right skill and chains the steps. Hover any request below and use
the copy button.

**One-liners**

\`\`\`text
Deploy https://github.com/acme/shop to my Frankfurt server.
\`\`\`

\`\`\`text
The last deploy of the API site failed — fix it.
\`\`\`

\`\`\`text
List my xCloud servers.
\`\`\`

\`\`\`text
Is example.com up right now?
\`\`\`

\`\`\`text
Renew the SSL certificate for shop.example.com.
\`\`\`

\`\`\`text
Update all plugins on example.com, but back up first.
\`\`\`

\`\`\`text
Scan example.com for vulnerabilities and show me the critical ones.
\`\`\`

\`\`\`text
Something's hammering my server from 203.0.113.7 — block it.
\`\`\`

**Multi-step workflows** — each is a single request; Claude does the chaining.

*Monday-morning health audit* — checks the site is serving, inspects SSL expiry,
runs a vulnerability scan, and runs a PageSpeed scan, then returns one summary.

\`\`\`text
Audit example.com — is it up, is SSL healthy, any vulnerabilities, and how's performance?
\`\`\`

*Safe WordPress update* — takes a backup and waits for it, applies the update,
then confirms the site is still healthy; if anything breaks it points you to that
backup (restore is one click in the dashboard).

\`\`\`text
WooCommerce has an update — apply it to example.com, but back up first and tell me if anything looks off.
\`\`\`

*New site go-live* — installs a Let's Encrypt certificate, waits for issuance,
verifies HTTPS, and runs a baseline PageSpeed scan.

\`\`\`text
I just provisioned shop.example.com — set up HTTPS and confirm it's serving.
\`\`\`

*Triage a site that's down* — pulls site status, recent events, and SSH/user
config to spot the usual culprits (stopped service, missing OS user, failed
deploy).

\`\`\`text
example.com is throwing 502 errors — what's going on?
\`\`\`

> If Claude ever reaches for the wrong area, name it:
> \`Using xcloud:ssl, renew the cert for example.com.\`

## Authentication

**Recommended:** browser OAuth through the xCloud MCP connector, with Read
(\`mcp:read\`) or Read & write (\`mcp:write\`) access. See the
[MCP setup guide](${XCLOUD_MCP_DOCS_URL}).

**REST fallback:** a scoped Sanctum personal access token stored as
\`XCLOUD_API_TOKEN\`. API-token list/revoke and \`/health\` remain REST-only.

For full auth details, scopes, and the endpoint reference, see the
[xCloud API](${XCLOUD_API_DOCS_URL}).
`.trim();

const doc = {
  openapi: '3.1.0',
  info: {
    title: 'xCloud Agent Skills',
    version: PLUGIN_VERSION,
    description: INFO_DESCRIPTION,
  },
  // No contact / license / externalDocs — they render in Scalar's right column,
  // which we don't want. The "xCloud API" link lives in the description body.
  // Intentionally empty: this is a guide/landing page, not an endpoint reference.
  paths: {},
};

const outPath = join(HERE, 'xcloud-skills.openapi.json');
writeFileSync(outPath, JSON.stringify(doc, null, 2) + '\n');
console.log(`Wrote ${outPath}`);
console.log('  guide/landing page · 0 operations · links to xCloud API at ' + XCLOUD_API_DOCS_URL);

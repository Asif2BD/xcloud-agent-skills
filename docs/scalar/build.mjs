#!/usr/bin/env node
/**
 * build.mjs — generate the Scalar OpenAPI document for the xCloud agent skills.
 *
 * Source of truth: ./skills-catalog.json (one entry per skill, each with its
 * operations). This script transforms that catalog into a valid OpenAPI 3.1
 * document that Scalar renders as an interactive API reference.
 *
 * Regenerate after editing the catalog:
 *   node docs/scalar/build.mjs
 *
 * Output: ./xcloud-skills.openapi.json  (loaded by ./index.html)
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const catalog = JSON.parse(readFileSync(join(HERE, 'skills-catalog.json'), 'utf8'));

/** Human-friendly group label per skill id. */
const SKILL_GROUP = {
  servers: 'xcloud:servers',
  sites: 'xcloud:sites',
  wordpress: 'xcloud:wordpress',
  ssl: 'xcloud:ssl',
  account: 'xcloud:account',
};

/** Short description per sub-area tag (sidebar groups inside Scalar). */
const TAG_DESCRIPTIONS = {
  Servers: 'Inspect servers, monitoring, services, tasks, snapshots, reboot, and WordPress provisioning.',
  'Server PHP': 'Install, default, OPcache, and patch PHP versions on a server.',
  'Server Cron': 'Server-level cron jobs: list, create, update, delete, run, and read output.',
  Databases: 'Databases and database users on a server.',
  'Firewall & fail2ban': 'Firewall rules, fail2ban bans, SSH restriction, and IP whitelisting.',
  'Sudo Users': 'OS-level privileged (sudo) accounts on a server.',
  Sites: 'Site lifecycle: status, events, logs, monitoring, rescue, and config reads.',
  Backups: 'Trigger and inspect site backups.',
  Domains: 'Primary domain, all domains, redirections, and web rules (reads).',
  Cache: 'Cache settings and purging.',
  SSH: 'SSH/SFTP authentication config and keys.',
  'Site Cron': 'Site-level cron jobs (run as the site user).',
  WordPress: 'Plugins, themes, updates, WP_DEBUG, and magic login.',
  Vulnerabilities: 'Vulnerability findings, counts, rescans, and ignore management.',
  PageSpeed: 'PageSpeed Insights snapshots, history, and scans.',
  SSL: 'SSL certificates: view, install, renew, status, and delete.',
  Account: 'Identity, API tokens, Cloudflare integrations, blueprints, and health.',
};

const INFO_DESCRIPTION = `
The **xCloud agent skills** let any AI agent (Claude Code, OpenCode, and others)
operate xCloud in plain language — *"reboot my Hermes server"*, *"renew SSL for
example.com"*, *"scan example.com for vulnerabilities"*. Under the hood every
skill calls this **xCloud Public API**.

This reference documents the API surface those skills cover, grouped by skill.
You normally never call it by hand — you talk to the agent. It's here so you can
see exactly what each skill can do, what scope it needs, and what each request
takes.

> **Skills repo:** <https://github.com/xCloudDev/xcloud-agent-skills>
> **User guide:** <https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md>
> **Install & call reference:** <https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md>

## Install in Claude Code

1. **Install the plugin:**

   \`\`\`
   /plugin marketplace add xCloudDev/xcloud-agent-skills
   /plugin install xcloud
   /reload-plugins
   \`\`\`

2. **Add your API token.** Get one from the xCloud dashboard → **Profile → API
   Tokens → Generate New Token** (copy it once). Then add to
   \`~/.claude/settings.json\`:

   \`\`\`json
   { "env": { "XCLOUD_API_TOKEN": "your-token-here" } }
   \`\`\`

   Restart Claude Code so it picks up the token.

3. **Check it works.** Ask Claude: *"Check my xCloud API connection."* Green
   light = you're ready.

That's it — everything below is just talking to Claude.

## The five skills

| Skill | Owns |
|---|---|
| \`xcloud:servers\` | Servers, PHP, databases, cron, firewall/fail2ban, sudo users, WordPress provisioning |
| \`xcloud:sites\` | Site lifecycle: status, backups, domains, cache, SSH, site cron, git |
| \`xcloud:wordpress\` | WP plugins/themes/updates, WP_DEBUG, magic login, vulnerabilities, PageSpeed |
| \`xcloud:ssl\` | SSL certificates: view, install, renew, status, delete |
| \`xcloud:account\` | Current user, API tokens, Cloudflare integrations, blueprints, health |

## Example requests

You don't name skills or endpoints — you describe what you want in plain
language and Claude picks the right skill and chains the steps.

**One-liners:**

- *"List my xCloud servers."*
- *"Is example.com up right now?"*
- *"Renew the SSL certificate for shop.example.com."*
- *"Update all plugins on example.com, but back up first."*
- *"Scan example.com for vulnerabilities and show me the critical ones."*
- *"Something's hammering my server from 203.0.113.7 — block it."*

**Multi-step workflows** (each is a single request — Claude does the chaining):

- **Monday-morning health audit** — *"Audit example.com — is it up, is SSL
  healthy, any vulnerabilities, and how's performance?"*
  Checks the site is serving, inspects SSL expiry, runs a vulnerability scan, and
  runs a PageSpeed scan, then returns one summary.

- **Safe WordPress update** — *"WooCommerce has an update — apply it to
  example.com, but back up first and tell me if anything looks off."*
  Takes a labelled backup and waits for it, applies the update, then confirms the
  site is still healthy. Follow up with *"restore the backup you just took"* to
  roll back.

- **New site go-live** — *"I just provisioned shop.example.com — set up HTTPS and
  confirm it's serving."*
  Installs a Let's Encrypt certificate, waits for issuance, verifies HTTPS, and
  runs a baseline PageSpeed scan.

- **Triage a site that's down** — *"example.com is throwing 502 errors — what's
  going on?"*
  Pulls site status, recent events, and SSH/user config to spot the usual
  culprits (stopped service, missing OS user, failed deploy).

> If Claude ever reaches for the wrong area, name it:
> *"Using xcloud:ssl, renew the cert for example.com."*

## Authentication

The API uses [Sanctum personal access tokens](https://laravel.com/docs/sanctum)
sent as a Bearer token:

\`\`\`
Authorization: Bearer <XCLOUD_API_TOKEN>
\`\`\`

Generate one in the xCloud dashboard → **Profile → API Tokens → Generate New
Token**, choosing scopes (\`read:sites\`, \`write:sites\`, \`read:servers\`,
\`write:servers\`, or \`*\`). It's shown once — copy it immediately.

Scopes are coarse; each request also passes a per-resource policy check. A
**403** with a valid token means a missing team permission (e.g.
\`site:manage-ssl\` for SSL renewal), not a bad token. A **401** means the token
is missing, expired, or revoked.

## Response envelope

Every response uses the same wrapper:

\`\`\`json
{ "success": true, "message": "Success", "data": {} }
\`\`\`

On error, \`success\` is \`false\` and \`message\` carries the reason; the HTTP
status is authoritative.

## Pagination

List endpoints return **either** shape — inspect before assuming:

- \`data.items\` + \`data.pagination\` (most live endpoints)
- \`data.data\` + \`data.meta\` (some examples)

Max **100** per page.

## Rate limits & async writes

Authenticated callers get **60 req/min** (10 unauthenticated). A **429** returns
\`Retry-After\` — honor it. Writes often return success immediately while work
continues; poll the matching read endpoint (status / events / tasks) to confirm
completion.
`.trim();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const slug = (s) => s.replace(/[^a-zA-Z0-9]+/g, '_').replace(/^_+|_+$/g, '');

function operationId(method, path) {
  return `${method.toLowerCase()}${slug(path).replace(/^_/, '_')}`;
}

/** Map a documented body field string to a JSON Schema property. */
function parseBodyField(field) {
  const colon = field.indexOf(':');
  const name = field.slice(0, colon).trim();
  const rest = field.slice(colon + 1).trim();
  const [typePart, ...noteParts] = rest.split('—');
  const rawType = typePart.trim().toLowerCase();
  const note = noteParts.join('—').trim();
  const required = /\(required\)/i.test(note) || /\brequired\b/i.test(note) && !/required (only|when|for)/i.test(note);

  const typeMap = {
    string: { type: 'string' },
    boolean: { type: 'boolean' },
    integer: { type: 'integer' },
    number: { type: 'number' },
    array: { type: 'array', items: {} },
    object: { type: 'object' },
  };
  const schema = { ...(typeMap[rawType] ?? { type: 'string' }) };
  if (note) schema.description = note;
  return { name, schema, required };
}

const KNOWN_QUERY = {
  per_page: { name: 'per_page', in: 'query', required: false, description: 'Items per page (max 100).', schema: { type: 'integer', maximum: 100, default: 20 } },
  page: { name: 'page', in: 'query', required: false, description: 'Page number.', schema: { type: 'integer', default: 1 } },
  search: { name: 'search', in: 'query', required: false, description: 'Search term; resolves a site UUID by domain.', schema: { type: 'string' } },
  q: { name: 'q', in: 'query', required: false, description: 'Search query.', schema: { type: 'string' } },
  status: { name: 'status', in: 'query', required: false, description: 'Filter by status (e.g. active, inactive).', schema: { type: 'string' } },
  site: { name: 'site', in: 'query', required: true, description: 'Site UUID (required for this endpoint).', schema: { type: 'string', format: 'uuid' } },
};

function queryParam(name) {
  return KNOWN_QUERY[name] ?? { name, in: 'query', required: false, schema: { type: 'string' } };
}

function pathParam(name) {
  const isUuid = /uuid/i.test(name);
  return {
    name,
    in: 'path',
    required: true,
    description: isUuid ? 'Resource UUID.' : name === 'tokenId' ? 'Numeric token id.' : name === 'ip' ? 'IP address.' : name === 'version' ? 'PHP version, e.g. 8.3.' : `Path value: ${name}.`,
    schema: { type: name === 'tokenId' ? 'integer' : 'string', ...(isUuid ? { format: 'uuid' } : {}) },
  };
}

// ---------------------------------------------------------------------------
// Build paths + tags
// ---------------------------------------------------------------------------

const paths = {};
const tagOrder = []; // [{ name, description, group }]
const tagGroups = []; // [{ name, tags: [] }]

for (const skill of catalog.skills) {
  const groupName = SKILL_GROUP[skill.skill] ?? skill.skill;
  const groupTags = [];

  for (const op of skill.operations) {
    if (!tagOrder.find((t) => t.name === op.tag)) {
      tagOrder.push({ name: op.tag, description: TAG_DESCRIPTIONS[op.tag] ?? '' });
    }
    if (!groupTags.includes(op.tag)) groupTags.push(op.tag);

    const authed = op.scope !== 'none';
    const params = [
      ...op.pathParams.map(pathParam),
      ...op.queryParams.map(queryParam),
    ];

    const operation = {
      tags: [op.tag],
      summary: op.summary,
      description: `${op.description}\n\n**Scope:** \`${op.scope}\``,
      operationId: operationId(op.method, op.path),
    };
    if (params.length) operation.parameters = params;

    if (op.bodyFields.length) {
      const props = {};
      const required = [];
      for (const f of op.bodyFields) {
        const { name, schema, required: req } = parseBodyField(f);
        props[name] = schema;
        if (req) required.push(name);
      }
      operation.requestBody = {
        required: required.length > 0,
        content: {
          'application/json': {
            schema: { type: 'object', properties: props, ...(required.length ? { required } : {}) },
          },
        },
      };
    }

    const responses = {
      200: { $ref: '#/components/responses/Success' },
    };
    if (authed) {
      responses[401] = { $ref: '#/components/responses/Unauthorized' };
      responses[403] = { $ref: '#/components/responses/Forbidden' };
    }
    if (op.pathParams.length) responses[404] = { $ref: '#/components/responses/NotFound' };
    if (op.bodyFields.length || op.queryParams.includes('site')) {
      responses[422] = { $ref: '#/components/responses/ValidationError' };
    }
    responses[429] = { $ref: '#/components/responses/RateLimited' };
    operation.responses = responses;

    operation.security = authed ? [{ bearerAuth: [] }] : [];

    paths[op.path] ??= {};
    paths[op.path][op.method.toLowerCase()] = operation;
  }

  tagGroups.push({ name: groupName, tags: groupTags });
}

// ---------------------------------------------------------------------------
// Components
// ---------------------------------------------------------------------------

const envelope = (dataSchema = { type: 'object' }) => ({
  type: 'object',
  properties: {
    success: { type: 'boolean', example: true },
    message: { type: 'string', example: 'Success' },
    data: dataSchema,
  },
});

const errorEnvelope = {
  type: 'object',
  properties: {
    success: { type: 'boolean', example: false },
    message: { type: 'string' },
    data: { type: 'object', nullable: true },
  },
};

const jsonResponse = (description, schema) => ({
  description,
  content: { 'application/json': { schema } },
});

const components = {
  securitySchemes: {
    bearerAuth: {
      type: 'http',
      scheme: 'bearer',
      description: 'Sanctum personal access token. Send as `Authorization: Bearer <token>`.',
    },
  },
  schemas: {
    SuccessEnvelope: envelope(),
    ErrorEnvelope: errorEnvelope,
  },
  responses: {
    Success: jsonResponse('Standard success envelope.', { $ref: '#/components/schemas/SuccessEnvelope' }),
    Unauthorized: jsonResponse('Token missing, expired, or revoked.', { $ref: '#/components/schemas/ErrorEnvelope' }),
    Forbidden: jsonResponse('Token lacks the required scope or team permission.', { $ref: '#/components/schemas/ErrorEnvelope' }),
    NotFound: jsonResponse('Resource not found for the given identifier.', { $ref: '#/components/schemas/ErrorEnvelope' }),
    ValidationError: jsonResponse('Request failed validation (422).', { $ref: '#/components/schemas/ErrorEnvelope' }),
    RateLimited: jsonResponse('Rate limit exceeded; honor the Retry-After header.', { $ref: '#/components/schemas/ErrorEnvelope' }),
  },
};

// ---------------------------------------------------------------------------
// Assemble document
// ---------------------------------------------------------------------------

const doc = {
  openapi: '3.1.0',
  info: {
    title: 'xCloud Agent Skills — API Reference',
    version: '3.0.0',
    description: INFO_DESCRIPTION,
    contact: { name: 'xCloud', url: 'https://xcloud.host/support' },
    license: { name: 'MIT', url: 'https://github.com/xCloudDev/xcloud-agent-skills/blob/main/LICENSE' },
  },
  servers: [
    { url: 'https://app.xcloud.host/api/v1', description: 'Live' },
    { url: 'http://xcloud.test/api/v1', description: 'Local development' },
  ],
  security: [{ bearerAuth: [] }],
  tags: tagOrder,
  'x-tagGroups': tagGroups,
  paths,
  components,
};

const outPath = join(HERE, 'xcloud-skills.openapi.json');
writeFileSync(outPath, JSON.stringify(doc, null, 2) + '\n');

const opCount = Object.values(paths).reduce(
  (n, item) => n + Object.keys(item).filter((k) => ['get', 'post', 'put', 'delete', 'patch'].includes(k)).length,
  0,
);
console.log(`Wrote ${outPath}`);
console.log(`  ${catalog.skills.length} skills · ${tagOrder.length} tags · ${Object.keys(paths).length} paths · ${opCount} operations`);

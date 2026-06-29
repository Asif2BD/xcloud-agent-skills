---
name: wordpress
description: Manage WordPress on xCloud sites — list/update/activate plugins and themes, check WordPress health and update summaries, toggle WP_DEBUG, generate magic-login URLs, run vulnerability scans and manage findings, and run PageSpeed Insights scans. Use for WordPress app management, security scans, or site performance. For SSL see xcloud:ssl; for site backups/domains/cache see xcloud:sites; for server infra see xcloud:servers.
---

# xCloud WordPress

Owns WordPress app management plus site vulnerability scanning and PageSpeed.
Read the shared layer first for auth, base URL, and conventions:

- `${CLAUDE_PLUGIN_ROOT}/reference/auth.md`
- `${CLAUDE_PLUGIN_ROOT}/reference/conventions.md`

```bash
XC="${CLAUDE_PLUGIN_ROOT}/scripts/xcloud.sh"
```

Scopes: reads need `read:sites`, writes need `write:sites`.

## Response format

Brand every user-facing reply (see `reference/conventions.md` →
**Response format**): open with `☁️ **xCloud · WordPress** — <site domain>`, give
the trimmed result, and close with a `_via xcloud:wordpress_` line.

## Sub-resources (load on demand)

| Sub-resource | Reference file |
|---|---|
| Plugins, themes, updates, activate, refresh | `reference/plugins-themes.md` |
| Vulnerabilities (scan, list, ignore) | `reference/vulnerabilities.md` |
| PageSpeed Insights | `reference/pagespeed.md` |

## Core endpoints

| Operation | Method + path |
|---|---|
| WP health status | `GET /sites/{uuid}/wordpress/status` |
| Updates summary | `GET /sites/{uuid}/wordpress/updates` |
| Toggle WP_DEBUG | `POST /sites/{uuid}/wp-debug` |
| Magic login URL | `POST /sites/{uuid}/magic-login` |

**Not here:** SSL → `xcloud:ssl`; backups/domains/cache/SSH → `xcloud:sites`;
server infra → `xcloud:servers`.

## Examples

WordPress health + pending updates:

```bash
SITE_UUID='replace-me'
"$XC" GET "/sites/$SITE_UUID/wordpress/status"  | jq '.data'
"$XC" GET "/sites/$SITE_UUID/wordpress/updates" | jq '.data'
```

Toggle WP_DEBUG (`enabled` required):

```bash
"$XC" POST "/sites/$SITE_UUID/wp-debug" '{"enabled":true}' | jq '.message'
```

Generate a one-time admin magic-login URL:

```bash
"$XC" POST "/sites/$SITE_UUID/magic-login" '{"login_as":"admin"}' | jq -r '.data.url // .data'
```

## Cross-domain note

`vulnerabilities` and `pagespeed` are addressed at `/sites/{uuid}/…` and work on
any site, but are owned here because they are predominantly WordPress concerns.
A non-WordPress "scan my site" request still routes here via the `xcloud:sites`
cross-link.

## Pitfalls

- Plugin/theme updates and activations are async and can optionally back up
  first — see `reference/plugins-themes.md`.
- Magic-login URLs are single-use and short-lived; never log them.

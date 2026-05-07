# Runbook: Site health check

**Goal:** Answer "is this WordPress site healthy?" with one round-trip when possible.

**Inputs:** `site_uuid`
**Skill version:** v0.1+

## Quick path — single call

```bash
./scripts/xcloud.sh GET /sites/${site_uuid}/wordpress/status
```

The status response is designed for at-a-glance health and includes:

- WordPress + PHP versions
- Multisite, WP_DEBUG, WP_CRON flags
- Checksum status (last integrity check)
- Counts of plugins/themes
- Pending update counts (core / plugins / themes)
- SSL provider + expiry

For most "is X healthy?" questions, this single response is enough.

## Composite path — three calls

When the user asks for *details* (which plugins, which CVEs), chain three calls:

```bash
./scripts/xcloud.sh GET /sites/${site_uuid}/wordpress/status
./scripts/xcloud.sh GET /sites/${site_uuid}/wordpress/updates
# v0.2:
./scripts/xcloud.sh GET /sites/${site_uuid}/vulnerabilities
```

Compose into a single report with three sections: **Health**, **Updates**, **Security**.

## Health rubric (v0.1)

| Signal | Healthy | Warning | Critical |
|---|---|---|---|
| `wp_debug_enabled` | `false` (production) | — | `true` (production) |
| `checksum_status` | `passed` | `unknown` | `failed` |
| `updates_pending.core` | `false` | — | `true` |
| `updates_pending.plugins` | 0 | 1–4 | ≥5 |
| `updates_pending.themes` | 0 | 1+ | — |
| `ssl.expires_at` | >30 days | <30 days | <7 days OR null |

Map any **Critical** to a red flag, any **Warning** to amber, otherwise green.

## Edge cases

- **Status fields nullable:** if the site was just created, `wordpress_version` / `last_checksum_at` / `expires_at` may be `null`. Treat null as Warning, not Critical.
- **404 on the site itself:** the UUID is wrong or the site was deleted. Stop and confirm with the user.
- **403:** user lacks `site:manage-update` for that site. Tell user to ask a `TEAM_ADMIN` to grant it.

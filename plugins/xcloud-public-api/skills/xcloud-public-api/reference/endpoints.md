# Endpoints

> **Auto-generated.** Do not hand-edit. Regenerated from `docs/public/xcloud-public-api.openapi.yaml` by the per-PR CI script (Section P, Phase 2 PR1).

## Slice A PR1 — WordPress info reads (v0.1)

### `GET /api/v1/sites/{site_uuid}/wordpress/plugins`

List WordPress plugins installed on a site.

- **Scope:** `read:sites`
- **Permission:** `apiAccess` + `site:manage-update`
- **Query params:** `page`, `per_page` (default 50, max 100), `status` (`active|inactive|all`), `update_status` (`available|none|all`), `search`
- **Returns:** `{ items: [...], pagination, summary }`

### `GET /api/v1/sites/{site_uuid}/wordpress/themes`

List WordPress themes installed on a site.

- **Scope:** `read:sites`
- **Permission:** `apiAccess` + `site:manage-update`
- **Query params:** `page`, `per_page` (default 25, max 100), `status`, `update_status`, `search`
- **Returns:** `{ items: [...], pagination, summary }`

### `GET /api/v1/sites/{site_uuid}/wordpress/updates`

Pending updates summary (core + plugins + themes) with security cross-reference.

- **Scope:** `read:sites`
- **Permission:** `apiAccess` + `site:manage-update`
- **Query params:** `include_security_only` (`true|false`, default `false`)
- **Returns:** `{ site_uuid, core, plugins: { total, active, with_updates, with_security_updates, items[] }, themes: { ... }, summary }`

### `GET /api/v1/sites/{site_uuid}/wordpress/status`

Single-call site WordPress health snapshot.

- **Scope:** `read:sites`
- **Permission:** `apiAccess` + `site:manage-update`
- **Returns:** `{ wordpress_version, php_version, multisite_enabled, wp_debug_enabled, wp_cron_enabled, checksum_status, items_count, updates_pending, ssl }`

---

For Phase 1 endpoints (servers, sites listing, ssl, monitoring, backups, events, deployment-logs, git, ssh), see [`/api/v1/docs`](https://app.xcloud.host/api/v1/docs).

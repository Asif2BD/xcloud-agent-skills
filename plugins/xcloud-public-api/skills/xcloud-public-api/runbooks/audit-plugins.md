# Runbook: Audit outdated plugins/themes for a site

**Goal:** Surface every plugin and theme that has a pending update on one site, flag which are security updates, and present a fix list.

**Inputs:** `site_uuid`
**Skill version:** v0.1+

## Steps

### 1. Get the updates summary

```bash
./scripts/xcloud.sh GET /sites/${site_uuid}/wordpress/updates
```

Read `data.summary.total_pending` and `data.summary.security_pending`. If both are 0, the site is fully patched — stop here and tell the user.

### 2. Pull plugin and theme details

The `/wordpress/updates` response already contains the patchable items in `data.plugins.items[]` and `data.themes.items[]`. Each entry has `slug`, `name`, `current_version`, `available_version`, and `is_security_update`.

If you need full plugin/theme metadata (active state, last-checked timestamp, etc.), call:

```bash
./scripts/xcloud.sh GET "/sites/${site_uuid}/wordpress/plugins?update_status=available&per_page=100"
./scripts/xcloud.sh GET "/sites/${site_uuid}/wordpress/themes?update_status=available&per_page=100"
```

### 3. Format the audit for the user

Sort by `is_security_update DESC`, then by `name ASC`. Example presentation:

```
Site example.com — WordPress audit
==================================
2 security updates available:
  • WooCommerce 8.5.2 → 8.6.0  (security)
  • Yoast SEO 22.3 → 22.4      (security)

5 non-security updates available:
  • Advanced Custom Fields 6.2.4 → 6.3.0
  • ...
```

### 4. Offer next step

Phase 2 only exposes reads. To apply updates, point the user at the xCloud dashboard. In Phase 3 (skill v1.x), `POST /sites/{uuid}/wordpress/update` will let the agent apply patches directly.

## Cross-site variant (v0.2+)

When the team rollup endpoint ships with vulnerabilities (v0.2), prefer `GET /vulnerabilities?severity=critical,high&type=plugin` for a one-call multi-site audit. Until then, loop `/sites` → per-site updates.

## Edge cases

- **Site has no WordPress core item:** `data.core` will have `null` versions. This usually means the site is freshly created and hasn't completed its first WP item scan yet. Tell the user to refresh from the dashboard.
- **Stale data:** check `data.summary.last_scanned_at`. If older than 24 hours, mention it in the audit so the user knows the snapshot may be out of date.
- **403 on a specific site:** the user's team role doesn't include `site:manage-update` for that site. Skip and report.

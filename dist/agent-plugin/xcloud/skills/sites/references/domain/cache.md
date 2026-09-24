# Site cache

`XC="$SKILL_ROOT/scripts/xcloud.sh"` · scope `read:sites` / `write:sites`.

| Operation | Method + path |
|---|---|
| Cache settings | `GET /sites/{uuid}/cache/settings` |
| Purge full-page cache | `POST /sites/{uuid}/cache/purge` |
| Purge all caches | `POST /sites/{uuid}/cache/purge-all` |

```bash
SITE_UUID='replace-me'
"$XC" GET "/sites/$SITE_UUID/cache/settings" | jq '.data'
```

```text
sites_cache_purge      {"uuid": "<site-uuid>"}   # full-page only
sites_cache_purge-all  {"uuid": "<site-uuid>"}   # full-page + object + CDN
```

- `purge` clears the full-page cache; `purge-all` clears every cache layer.
- Async — confirm via `GET /sites/{uuid}/events`.
- `cache/settings` reads which layers are on (`page_cache`, `object_cache` with
  `redis` / `object_cache_pro`, `cloudflare_edge_cache`); **turning a layer on
  or off is dashboard-only (Site → Cache)** — no operation enables one. A slow
  site or "should caching be on" → the `performance` skill.

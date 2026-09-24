# Site backups

`XC="${CLAUDE_PLUGIN_ROOT}/scripts/xcloud.sh"` · scope `read:sites` / `write:sites`.

| Operation | Method + path |
|---|---|
| Trigger backup | `POST /sites/{uuid}/backup` |
| List backups | `GET /sites/{uuid}/backups` |
| Backup count | `GET /sites/{uuid}/backup-count` |
| Backup settings | `GET /sites/{uuid}/backup-settings` |
| Backup status | `GET /sites/{uuid}/backup-status` |

Docker apps (Compose sites, most one-click apps) have their own backup
endpoints — see `reference/docker-backups.md`.

```bash
SITE_UUID='replace-me'
TASK=$("$XC" POST "/sites/$SITE_UUID/backup" '{"type":"local"}' | jq -r '.data.task_uuid')
"$XC" GET "/sites/$SITE_UUID/events/$TASK" | jq '.data | {status, finished_at}'
"$XC" GET "/sites/$SITE_UUID/backup-status" | jq '.data'
"$XC" GET "/sites/$SITE_UUID/backups" | jq '(.data.items // .data) | map({uuid, status, created_at})'
```

- `type` is `local` (default) or `remote`. A remote backup needs a configured
  storage provider with a working connection, otherwise `422` before anything is
  queued.
- Backups are async: `data.task_uuid` is the backup task itself — poll
  `GET /sites/{uuid}/events/{task_uuid}` until it is terminal.
- "Which sites have no backup schedule?" → read `backup-settings` per site and
  list the ones without automatic backups; mention unread `backups` incident
  alerts (`xcloud:account`) alongside.
- Restoring a backup is dashboard-only (**Site → Backups → Restore**) for every
  site type; the API triggers, lists and configures backups.

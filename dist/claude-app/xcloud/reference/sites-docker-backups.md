# Docker app backups

`XC="scripts/xcloud.sh"` · scope `read:sites` / `write:sites`.
For sites on a Docker server (Compose deploys and one-click apps).

| Operation | Operation id | Method + path |
|---|---|---|
| Back up now | `sites.docker.backup` | `POST /sites/{uuid}/docker/backup` |
| List backups | `sites.docker.backups` | `GET /sites/{uuid}/docker/backups` |
| One backup | `sites.docker.backup.show` | `GET /sites/{uuid}/docker/backups/{backupUuid}` |
| Label a backup | `sites.docker.backup.note.update` | `PUT /sites/{uuid}/docker/backups/{backupUuid}/note` |
| Delete a backup | `sites.docker.backup.destroy` | `DELETE /sites/{uuid}/docker/backups/{backupUuid}` |
| Backup count | `sites.docker.backupCount` | `GET /sites/{uuid}/docker/backup-count` |
| Schedule and retention | `sites.docker.backupSettings` · `.update` | `GET\|PUT /sites/{uuid}/docker/backup-settings` |

"Take a backup of the n8n app before I upgrade it, and tell me when it's done":

```bash
SITE_UUID='replace-me'
B='uuid-from-sites_docker_backup'
"$XC" GET "/sites/$SITE_UUID/docker/backups/$B" | jq '.data'   # poll until status is terminal
```

```text
sites_docker_backup              {"uuid": "<site-uuid>"}   # 202 with the running backup's uuid
sites_docker_backup_note_update  {"uuid": "<site-uuid>", "backupUuid": "<backup-uuid>", "user_note": "before upgrade"}  # destructive: confirm: true after the user's yes
```

- The app is **briefly cold-stopped** while its volumes are captured — say so
  before triggering it on a production app.
- `destination` is a storage-provider uuid (S3-compatible or SFTP); omit it for
  a local backup. Google Drive and pCloud are not supported.
- Schedule: `auto_backup` (bool) and `auto_backup_frequency` (`daily`,
  `weekly`, `monthly`) are required on update; `delete_after_days` sets
  retention.
- Deleting a backup is irreversible — confirm the exact backup (date and note)
  first.

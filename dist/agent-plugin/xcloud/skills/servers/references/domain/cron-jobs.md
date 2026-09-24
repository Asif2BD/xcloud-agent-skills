# Server cron jobs

`XC="$SKILL_ROOT/scripts/xcloud.sh"` · scope `read:servers` / `write:servers`.

| Operation | Method + path |
|---|---|
| List | `GET /servers/{uuid}/cron-jobs` |
| Create | `POST /servers/{uuid}/cron-jobs` |
| Update | `PUT /servers/{uuid}/cron-jobs/{cronJobUuid}` |
| Delete | `DELETE /servers/{uuid}/cron-jobs/{cronJobUuid}` |
| Run now | `POST /servers/{uuid}/cron-jobs/{cronJobUuid}/execute` |
| Last output | `GET /servers/{uuid}/cron-jobs/{cronJobUuid}/output` |

Create body — required `user`, `frequency`, `command`; `pattern` holds a custom
cron expression when `frequency=custom`:

```text
servers_cron-jobs_create  {"uuid": "<server-uuid>", "user": "xcloud", "frequency": "custom",
                           "pattern": "*/15 * * * *", "command": "php /home/xcloud/cleanup.php"}  # destructive: confirm: true after the user's yes
```

```bash
CRON_UUID='replace-me'
"$XC" GET "/servers/$SERVER_UUID/cron-jobs/$CRON_UUID/output" | jq '.data'
```

```text
servers_cron-jobs_execute  {"uuid": "<server-uuid>", "cronJobUuid": "<cron-uuid>"}  # destructive: confirm: true after the user's yes
servers_cron-jobs_destroy  {"uuid": "<server-uuid>", "cronJobUuid": "<cron-uuid>"}  # destructive: confirm: true after the user's yes
```

> Site-scoped cron is a different resource — load the `sites` skill.

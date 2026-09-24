# Server PHP versions

`XC="${CLAUDE_PLUGIN_ROOT}/scripts/xcloud.sh"` · scope `read:servers` / `write:servers`.

| Operation | Method + path | Body |
|---|---|---|
| List installed | `GET /servers/{uuid}/php-versions` | — |
| List available | `GET /servers/{uuid}/php-versions/available` | — |
| Patch info | `GET /servers/{uuid}/php-versions/patch-info` | — |
| Install | `POST /servers/{uuid}/php-versions` | `{"php_version":"8.3"}` |
| Uninstall | `DELETE /servers/{uuid}/php-versions` | `{"php_version":"8.1"}` |
| Set default | `POST /servers/{uuid}/php-versions/{version}/default` | — |
| Toggle OPcache | `POST /servers/{uuid}/php-versions/{version}/opcache` | `{"enabled":true}` |
| Patch | `POST /servers/{uuid}/php-versions/{version}/patch` | — |

```bash
SERVER_UUID='replace-me'
"$XC" GET "/servers/$SERVER_UUID/php-versions" | jq '.data'
```

```text
servers_php-versions_install  {"uuid": "<server-uuid>", "php_version": "8.3"}  # destructive: confirm: true after the user's yes
servers_php-versions_default  {"uuid": "<server-uuid>", "version": "8.3"}  # destructive: confirm: true after the user's yes
servers_php-versions_opcache  {"uuid": "<server-uuid>", "version": "8.3", "enabled": true}  # destructive: confirm: true after the user's yes
```

- `php_version` is required for install/uninstall.
- `enabled` is required for the opcache toggle.
- Install/patch are async — confirm via `GET /servers/{uuid}/tasks`.

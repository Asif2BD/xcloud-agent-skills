# Sudo users

`XC="${CLAUDE_PLUGIN_ROOT}/scripts/xcloud.sh"` · scope `read:servers` / `write:servers`.
OS-level privileged accounts on the server (distinct from the API token user).

| Operation | Method + path |
|---|---|
| List | `GET /servers/{uuid}/sudo-users` |
| Create or update | `POST /servers/{uuid}/sudo-users` |
| Delete | `DELETE /servers/{uuid}/sudo-users/{sudo_user_uuid}` |

Create/update body (all optional in schema, but supply `username` plus either
keys or a password):

The password is a secret — build the JSON with `jq -n` and pipe it on **stdin**
(`-`) so it never appears in any process argument list:

```text
servers_sudoUsers_store  {"uuid": "<server-uuid>", "username": "deploy", "password": "<set by the user>",
                          "ssh_public_keys": ["ssh-ed25519 AAAA... user@host"], "is_temporary": false}  # destructive: confirm: true after the user's yes
```

```text
servers_sudoUsers_destroy  {"uuid": "<server-uuid>", "sudo_user_uuid": "<sudo-user-uuid>"}  # destructive: confirm: true after the user's yes
```

- Private keys are never returned.
- `is_temporary: true` provisions a short-lived account.

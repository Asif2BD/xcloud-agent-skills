# Sudo users

`XC="scripts/xcloud.sh"` · scope `read:servers` / `write:servers`.
OS-level privileged accounts on the server (distinct from the API token user).

| Operation | Method + path |
|---|---|
| List | `GET /servers/{uuid}/sudo-users` |
| Create or update | `POST /servers/{uuid}/sudo-users` |
| Delete | `DELETE /servers/{uuid}/sudo-users/{sudo_user_uuid}` |

Body: `username` and `ssh_public_keys` are required; `password` and
`is_temporary` are optional. **A username that already exists is updated, not
created** — list the users first, and never reuse a name unless the user asked
to change that account. A password is a secret: take it from the user, never
echo it back or put it in a summary.

```text
servers_sudoUsers_store  {"uuid": "<server-uuid>", "username": "deploy", "password": "<set by the user>",
                          "ssh_public_keys": ["ssh-ed25519 AAAA... user@host"], "is_temporary": false}  # destructive: confirm: true after the user's yes
```

```text
servers_sudoUsers_destroy  {"uuid": "<server-uuid>", "sudo_user_uuid": "<sudo-user-uuid>"}  # destructive: confirm: true after the user's yes
```

- Private keys are never returned.
- `is_temporary: true` provisions a short-lived account.

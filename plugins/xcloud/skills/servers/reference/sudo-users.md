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

```bash
SERVER_UUID='replace-me'
"$XC" POST "/servers/$SERVER_UUID/sudo-users" '{
  "username": "deploy",
  "password": "<strong-password>",
  "ssh_public_keys": ["ssh-ed25519 AAAA... user@host"],
  "is_temporary": false
}' | jq '.data'
```

```bash
SUDO_USER_UUID='replace-me'
"$XC" DELETE "/servers/$SERVER_UUID/sudo-users/$SUDO_USER_UUID" | jq '.message'
```

- Private keys are never returned.
- `is_temporary: true` provisions a short-lived account.

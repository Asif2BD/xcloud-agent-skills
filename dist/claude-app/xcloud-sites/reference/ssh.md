# Site SSH/SFTP config

`XC="${CLAUDE_PLUGIN_ROOT}/scripts/xcloud.sh"` · scope `read:sites` / `write:sites`.

| Operation | Method + path |
|---|---|
| Get SSH/SFTP config | `GET /sites/{uuid}/ssh` |
| Update SSH/SFTP config | `PUT /sites/{uuid}/ssh` |
| List SSH keys | `GET /sites/{uuid}/ssh-keys` |

Switch to public-key auth (`ssh_public_keys` required):

```bash
SITE_UUID='replace-me'
"$XC" PUT "/sites/$SITE_UUID/ssh" '{
  "authentication_mode": "public_key",
  "ssh_public_keys": ["ssh-ed25519 AAAA... user@host"]
}' | jq '.message'
```

Switch to password auth (`password` required):

```bash
"$XC" PUT "/sites/$SITE_UUID/ssh" '{
  "authentication_mode": "password",
  "password": "<strong-password>"
}' | jq '.message'
```

- `authentication_mode=public_key` requires `ssh_public_keys`;
  `authentication_mode=password` requires `password`.
- `GET /sites/{uuid}/ssh` exposes `site_user` — useful when triaging a 502
  caused by a missing OS user. Private keys are never returned.

# xCloud Skills — claude.ai build

Self-contained Skills for the **Claude apps** (claude.ai web/desktop) "Add Skill"
feature. This is a **separate distribution** from the Claude Code plugin in
`plugins/xcloud/` — both coexist:

| Surface | Use |
|---|---|
| **Claude Code** (CLI / IDE) | Install the plugin (`plugins/xcloud`) via the marketplace. Full local + live support, token via `settings.json`. |
| **claude.ai app** | Upload the zips in this folder via **Add Skill**. |

These folders are **generated** from the plugin by `build.sh` — don't edit them by
hand. Change the plugin, then re-run the build.

## Build / rebuild

```bash
bash dist/claude-app/build.sh
```

Produces, for each capability, a self-contained folder + zip:

```
xcloud-servers/   xcloud-servers.zip
xcloud-sites/     xcloud-sites.zip
xcloud-wordpress/ xcloud-wordpress.zip
xcloud-ssl/       xcloud-ssl.zip
xcloud-account/   xcloud-account.zip
```

Each bundles its own copy of the shared wrapper (`scripts/xcloud.sh`) and shared
reference (`reference/auth.md`, `reference/conventions.md`) — because claude.ai
skills must be self-contained (there's no shared plugin root like in Claude Code).

## Install on claude.ai

1. Open **claude.ai → Settings → Capabilities** (Skills). You need the
   **code execution / Files & Skills** capability enabled (plan/admin gated).
2. **Add Skill → Upload** and pick a zip (e.g. `xcloud-ssl.zip`). Repeat for each
   capability you want.
3. The skills appear as `xcloud-servers`, `xcloud-ssl`, … (note: the CLI uses
   `xcloud:servers` with a colon; the app build uses a hyphen and is otherwise
   identical).

## Required: API token

There's no `settings.json` env injection on claude.ai. The wrapper reads
`XCLOUD_API_TOKEN` (and optional `XCLOUD_API_BASE_URL`) from the sandbox
environment. Easiest path when testing: give Claude the token in chat and ask it
to export it before calling, e.g.

> "Use this xCloud token for this session: `xxxx`. List my servers."

Claude will `export XCLOUD_API_TOKEN=xxxx` in the sandbox, then run the wrapper.
Treat the token as sensitive — anything pasted into chat is sent to Anthropic.

## Known limitations (read before testing)

These are properties of the claude.ai code sandbox, not bugs in the skill:

1. **Network egress.** The sandbox's outbound network is restricted. Reaching
   `https://app.xcloud.host` may be blocked depending on your plan/workspace
   policy. If calls hang or fail to connect, egress is the cause — there's no
   skill-side fix.
2. **Local hosts unreachable.** `http://xcloud.test` (your local xCloud) is
   **never** reachable from the cloud sandbox. The app build is **live-only**.
3. **Working directory / paths.** SKILL.md calls the wrapper as
   `scripts/xcloud.sh`, relative to the skill folder. If the sandbox's working
   directory isn't the skill root, tell Claude to `cd` into the skill directory
   (or `chmod +x scripts/xcloud.sh`) first. Claude usually handles this, but it's
   the most likely paper-cut.
4. **Branding.** The startup banner + `xCloud` header/footer are model output, so
   they render the same as in the CLI.

## Status

Experimental. The Claude Code plugin is the primary, fully-tested distribution.
This app build is for evaluating how far the claude.ai sandbox gets against the
live API. For a robust cross-surface integration, an **MCP server** (works in the
app, Claude Code, and the API) is the better long-term path.

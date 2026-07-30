# xCloud Skills — claude.ai build

Self-contained Skills for the **Claude apps** (claude.ai web/desktop) "Add Skill"
feature. This is a **separate distribution** from the Claude Code plugin in
`plugins/xcloud/` — both coexist:

| Surface | Use |
|---|---|
| **Claude Code** (CLI / IDE) | Install the plugin (`plugins/xcloud`) via the marketplace. Full local + live support, token via `settings.json`. |
| **claude.ai app** | Upload `xcloud-agent-skill.zip` via **Add Skill**. |

These folders are **generated** from the plugin by `build.sh` — don't edit them by
hand. Change the plugin, then re-run the build.

## Build / rebuild

```bash
bash dist/claude-app/build.sh
```

Produces **one** self-contained skill + a single zip:

```
xcloud/                  xcloud-agent-skill.zip
```

claude.ai treats an uploaded zip as **one skill** (a single `SKILL.md` at the
root), so all five capability areas ship as **one `xcloud` skill**: a router
`SKILL.md` that dispatches to per-area reference files
(`reference/servers.md`, `reference/sites.md`, …), with the shared wrapper
(`scripts/xcloud.sh`) and shared reference (`reference/auth.md`,
`reference/conventions.md`) bundled in. Sub-resource files are namespaced by area
(`reference/servers-firewall.md`) so nothing collides.

## Install on claude.ai

1. Open **claude.ai → Settings → Capabilities** (Skills). You need the
   **code execution / Files & Skills** capability enabled (plan/admin gated).
2. **Add Skill → Upload** and pick **`xcloud-agent-skill.zip`**. That's it — one
   upload installs everything.
3. The skill appears as **`xcloud`** and handles servers, sites, WordPress, SSL,
   and account requests (the CLI splits these into `xcloud:servers`, `xcloud:ssl`,
   … — same capabilities, one skill in the app).

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
live API. For robust cross-surface integration, connect the **official xCloud
MCP server** — `https://app.xcloud.host/mcp`
([docs](https://app.xcloud.host/mcp/docs)) — which works in the app, Claude
Code, and the API, and pair it with these skills.

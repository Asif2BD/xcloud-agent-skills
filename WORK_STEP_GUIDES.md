# Work Step Guide — Adding New API Endpoints to the xCloud Agent Skill

This guide explains, step by step, how to wire a **new xCloud Public API endpoint** into the
`xcloud` agent skill so that a natural-language prompt triggers it correctly in
Claude Code.

Running example throughout:

> **Prompt:** "Find me the sites which have vulnerabilities."
>
> **Assumption:** the backend already serves the vulnerability endpoints
> (e.g. `GET /vulnerabilities` team-wide rollup and `GET /sites/{uuid}/vulnerabilities`).

---

## Mental model — what you are actually editing

The agent skill is **not** generated code. It is **documentation + a thin curl wrapper**.
Claude reads the docs, then shells out to `scripts/xcloud.sh` to make the real HTTP call.

So "adding an endpoint" means two jobs:

| Half | Goal | Where |
|------|------|-------|
| **A. Make the trigger fire** | The prompt must match the skill and load it | `SKILL.md` frontmatter `description` |
| **B. Make the skill aware** | Claude must know the path, scope, shape, and `jq` filter | `SKILL.md` body, `runbooks/`, `scripts/` |

There is **no backend code** in this repo. If the endpoint does not exist on the API yet,
build it in the main xCloud app first — this guide starts *after* the endpoint is live.

### Progressive disclosure (why file placement matters)

```
Tier 1  name + description        always in context        (the trigger)
Tier 2  SKILL.md body             loaded when triggered     (core how-to)
Tier 3  reference/ runbooks/      loaded only on demand     (deep recipes)
        scripts/ tests/
```

Keep the always-loaded `description` lean but keyword-rich. Put heavy detail in Tier 3.

---

## Prerequisites

```bash
# Local API token (Sanctum personal access token)
export XCLOUD_API_TOKEN="7|xxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Point the wrapper at your environment (omit for production app.xcloud.host)
export XCLOUD_API_BASE_URL="http://xcloud.test"

# Convenience alias for the curl wrapper used below
SC=./plugins/xcloud/scripts/xcloud.sh
```

---

## Step 0 — Verify the live endpoint FIRST

Never document a response shape you have not seen. Call the endpoint and capture the real
JSON envelope.

```bash
$SC GET '/vulnerabilities?per_page=5'         # team-wide rollup
$SC GET /sites/<SITE_UUID>/vulnerabilities    # per-site detail
```

Record:

- exact path and query params
- the success envelope (`data.items` vs `data.data`, field names, severity enum, counts)
- the required auth scope (check route middleware in the backend `routes/public-api.php`)

Everything downstream documents **this verified shape**, not an OpenAPI guess.

---

## Step 1 — Update the `description` (this is the trigger)

File: `plugins/xcloud/skills/servers/SKILL.md` (frontmatter, line ~3).

This single line is the only thing in Claude's context until the skill loads. If it does not
mention the new domain, the prompt may never fire the skill.

```yaml
description: Interact with the xCloud Public API at https://app.xcloud.host/api/v1 ...
  Covers auth, scopes, curl patterns, endpoint selection, async polling, and security
  vulnerability scanning across sites.
```

Add the intent keywords: `vulnerabilit*`, `security scan`, `CVE`. These connect
"sites which have vulnerabilities" → this skill.

---

## Step 2 — Add to "What this API covers"

File: `SKILL.md`, section **What this API covers** (line ~47). Append a bullet:

```markdown
- Site vulnerabilities (per-site list + team-wide rollup)
```

---

## Step 3 — Document the scope

File: `SKILL.md`, **Scopes** block (line ~112). Use the exact scope the backend route enforces.

```markdown
- `read:vulnerabilities` — list per-site and team-wide vulnerability findings
```

If the route reuses `read:sites`, say so instead. Match the backend middleware exactly —
a wrong scope name here causes confusing `403` triage later.

---

## Step 4 — Add a canonical read example (how it executes)

File: `SKILL.md`, read-examples section (line ~193+). Use the **verified** shape from Step 0.
The `jq` filter is what turns raw data into the user's actual intent ("sites that HAVE vulns").

````markdown
List sites that have vulnerabilities (team-wide rollup):

```bash
curl -sS \
  -H "Authorization: Bearer $XCLOUD_API_TOKEN" \
  -H "Accept: application/json" \
  "https://app.xcloud.host/api/v1/vulnerabilities?per_page=100" \
  | jq '(.data.items // .data.data // [])
        | map(select(.vulnerability_count > 0)
        | {site_uuid, domain, vulnerability_count, severity})'
```
````

---

## Step 5 — Route it in the Intent Routing Table

File: `SKILL.md`, **Intent Routing Table** (line ~24). "Find vulnerable sites" is an
**analyze** (security gaps) intent. Extend the row and the linked workflow doc.

```markdown
| **analyze** | Understand & optimize | `docs/ANALYZE.md` | Utilization, costs, capacity planning, security gaps, vulnerability triage |
```

Then add a short vulnerability-triage section to `docs/ANALYZE.md`.

---

## Step 6 — Add a runbook (recommended, Tier 3)

New file: `plugins/xcloud/skills/wordpress/runbooks/find-vulnerable-sites.md`.

Runbooks load only when needed and give Claude a repeatable recipe.

```markdown
# Runbook: Find sites with vulnerabilities

Goal: list all sites with open vulnerabilities, sorted by severity.

1. Pull the team-wide rollup:
   ./scripts/xcloud.sh GET '/vulnerabilities?per_page=100'

2. Filter to sites with findings:
   ... | jq '(.data.items // []) | map(select(.vulnerability_count > 0))'

3. For each flagged site, drill in:
   ./scripts/xcloud.sh GET /sites/{uuid}/vulnerabilities

4. Report: domain, count, highest severity, CVE references.
```

---

## Step 7 — Add an example script (optional)

File: `scripts/examples/list-vulnerabilities.sh`, mirroring the existing `list-plugins.sh`.
Gives Claude (and humans) a ready-to-run wrapper.

```bash
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"${DIR}/xcloud.sh" GET '/vulnerabilities?per_page=100' \
  | jq '(.data.items // []) | map(select(.vulnerability_count > 0))'
```

---

## Step 8 — Add a smoke test

File: `tests/smoke.sh`. Assert the endpoint returns a healthy envelope so you catch breakage.

```bash
$SC GET '/vulnerabilities?per_page=1' | jq -e '.success == true' >/dev/null \
  && echo "OK  /vulnerabilities" \
  || { echo "FAIL /vulnerabilities"; exit 1; }
```

---

## Step 9 — Bump the version (keep all three in sync)

| File | Field |
|------|-------|
| `plugins/xcloud/skills/servers/SKILL.md` | `version: 1.3.0` |
| `.claude-plugin/marketplace.json` | `"version": "1.3.0"` |
| `.clawhubinfo.json` | version field |

---

## Step 10 — Changelog, commit, push

```bash
# Add a v1.3.0 entry to CHANGELOG.md describing the new vulnerability endpoints.
git checkout -b feat/vuln-endpoints
git add -A
git commit -m "feat: add vulnerability endpoints to xcloud skill"
git push -u origin feat/vuln-endpoints
```

Open a PR following the repo's normal review flow.

---

## Step 11 — Reinstall, reload, and test the trigger cold

```text
/plugin marketplace update xcloud-agent-skills
/reload-plugins
```

Then, in a fresh prompt:

```text
Find me the sites which have vulnerabilities
```

Confirm the end-to-end flow:

1. Claude loads the `xcloud:wordpress` skill (trigger matched).
2. It runs `xcloud.sh GET /vulnerabilities`.
3. It returns the filtered table of vulnerable sites.

---

## Effort tiers — pick based on need

| Goal | Steps required |
|------|----------------|
| **Just works** (trigger + call) | 0, 1, 2, 4 |
| **Production-grade** | + 3, 6, 8, 9, 10, 11 |
| **Polished** | all of 0–11 |

The two **mandatory** edits:

- **Step 1** — `description` keyword is the trigger.
- **Step 4** — the curl + `jq` example is how Claude executes the intent.

Everything else adds robustness, discoverability, and regression safety.

---

## Checklist (copy into your PR description)

```text
[ ] Step 0  Verified live endpoint shape (path, envelope, scope)
[ ] Step 1  description updated with trigger keywords
[ ] Step 2  Added to "What this API covers"
[ ] Step 3  Scope documented (matches backend middleware)
[ ] Step 4  Canonical read example with jq filter
[ ] Step 5  Intent Routing Table + docs/ANALYZE.md updated
[ ] Step 6  Runbook added
[ ] Step 7  Example script added
[ ] Step 8  Smoke test added
[ ] Step 9  Version bumped in 3 files (in sync)
[ ] Step 10 CHANGELOG + commit + push + PR
[ ] Step 11 Reinstalled, reloaded, trigger tested cold
```

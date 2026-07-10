---
name: xcloud-agent-skills
description: "Official xCloud Public API plugin for agents: manage servers, sites, WordPress, SSL, account data, and API-driven hosting operations."
version: 3.0.3
author: xCloudDev
homepage: https://xcloud.host
category: deployment
tags: [xcloud, xcloud-agent-skills, wordpress, hosting, deployment, devops, ssl, servers, sites, automation]
openclaw: ">=2026.2"
metadata:
  {
    "openclaw":
      {
        "emoji": "☁️",
        "requires": { "bins": ["bash", "curl", "jq"] },
        "install":
          [
            {
              "id": "xcloud-site",
              "kind": "link",
              "label": "xCloud",
              "url": "https://xcloud.host",
            },
            {
              "id": "dashboard",
              "kind": "link",
              "label": "xCloud Dashboard",
              "url": "https://app.xcloud.host",
            },
            {
              "id": "user-guide",
              "kind": "link",
              "label": "User Guide",
              "url": "https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md",
            },
            {
              "id": "install-guide",
              "kind": "link",
              "label": "Install Guide",
              "url": "https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md",
            },
            {
              "id": "github",
              "kind": "link",
              "label": "Official GitHub",
              "url": "https://github.com/xCloudDev/xcloud-agent-skills",
            },
            {
              "id": "docs",
              "kind": "link",
              "label": "API Docs",
              "url": "https://app.xcloud.host/api/v1/docs",
            },
            {
              "id": "tutorial",
              "kind": "link",
              "label": "OpenClaw Tutorial",
              "url": "https://xcloud.host/openclaw-skills-and-clawhub-on-xcloud-openclaw-agent/",
            },
            {
              "id": "video",
              "kind": "link",
              "label": "Tutorial Video",
              "url": "https://www.youtube.com/watch?v=oEE9OHo3_48",
            },
          ],
      },
  }
---

# xCloud Agent Skills v3.0.3

[![Version](https://img.shields.io/badge/version-3.0.3-brightgreen.svg)](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/LICENSE)
[![xCloud](https://img.shields.io/badge/xCloud-hosting-0EA5E9.svg)](https://xcloud.host)
[![ClawHub](https://img.shields.io/badge/ClawHub-xcloud-blue.svg)](https://clawhub.ai/asif2bd/skills/xcloud)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-skill-purple.svg)](https://openclaw.ai)

Built for xCloud hosting operators by [xCloud](https://xcloud.host) · [GitHub](https://github.com/xCloudDev/xcloud-agent-skills) · [User Guide](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md) · [Install Guide](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md) · [API Docs](https://app.xcloud.host/api/v1/docs) · [OpenClaw Tutorial](https://xcloud.host/openclaw-skills-and-clawhub-on-xcloud-openclaw-agent/) · [Tutorial Video](https://www.youtube.com/watch?v=oEE9OHo3_48) · [Security Notes](https://github.com/xCloudDev/xcloud-agent-skills/blob/main/SECURITY.md)

> **Security notice:** agent-only xCloud operations toolkit. This package contains skill routing instructions, reference docs, and a small `bash`/`curl` wrapper. It ships no API tokens and only calls the xCloud API after a user or agent explicitly invokes a skill with `XCLOUD_API_TOKEN` configured.

---

This root skill describes the official xCloud Public API plugin bundle for agent marketplaces such as ClawHub and skills.mp.com.

The runnable skills live under `plugins/xcloud/skills/` and are invoked as:

- `xcloud:servers`
- `xcloud:sites`
- `xcloud:wordpress`
- `xcloud:ssl`
- `xcloud:account`

## What It Provides

Use this package when an agent needs to operate xCloud hosting infrastructure through the xCloud Public API:

- Manage servers, services, monitoring, PHP versions, databases, firewall rules, fail2ban, and snapshots
- Manage sites, domains, cache, backups, deployment logs, rescue workflows, SSH/SFTP, cron jobs, and access logs
- Manage Git deployment settings and trigger manual Git deployments for xCloud sites
- Manage WordPress health, updates, plugins, themes, vulnerabilities, PageSpeed, WP_DEBUG, and magic-login URLs
- Run team-wide vulnerability rollups across all xCloud sites
- Manage SSL certificates, renewals, custom certificates, certificate status, and Cloudflare certificates
- Read account identity, API health, API tokens, Cloudflare integrations, and WordPress blueprints

## Agent Experience

- Every user-facing reply is xCloud branded with a clear header and `_via
  xcloud:*_` footer.
- The first xCloud interaction greets the user and shows the xCloud startup
  banner once per conversation.
- If no token is configured, xCloud proactively explains how to create a scoped
  API token and store it in the agent runtime as `XCLOUD_API_TOKEN`; it does not
  ask users to paste production tokens into chat by default.
- After token setup, xCloud verifies the connection with `/health` and `/user`
  before continuing operational tasks.

## Setup

Create an xCloud API token from:

https://app.xcloud.host/settings/api-tokens

Then configure your runtime:

```bash
export XCLOUD_API_TOKEN="your-token-here"
export XCLOUD_API_BASE_URL="https://app.xcloud.host"
```

The shared command wrapper is:

```bash
"${CLAUDE_PLUGIN_ROOT}"/scripts/xcloud.sh GET /user
```

## Official Links

- xCloud: https://xcloud.host
- Dashboard: https://app.xcloud.host
- User guide: https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/USER_GUIDE.md
- Install guide: https://github.com/xCloudDev/xcloud-agent-skills/blob/main/docs/SKILLS-GUIDE.md
- Official repository: https://github.com/xCloudDev/xcloud-agent-skills
- Development fork: https://github.com/Asif2BD/xcloud-agent-skills
- Public API docs: https://app.xcloud.host/api/v1/docs
- OpenClaw + ClawHub tutorial: https://xcloud.host/openclaw-skills-and-clawhub-on-xcloud-openclaw-agent/
- Tutorial video: https://www.youtube.com/watch?v=oEE9OHo3_48

## Safety

This package contains documentation, skill routing instructions, and a small shell wrapper. It does not include real API tokens and does not run API calls during installation. Network requests are made only after a user or agent explicitly invokes an xCloud skill with an API token configured in the environment.

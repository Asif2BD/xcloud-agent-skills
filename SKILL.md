---
name: xcloud
description: "Official xCloud Public API plugin for agents: manage servers, sites, WordPress, SSL, account data, and API-driven hosting operations."
version: 3.0.1
author: xCloudDev
homepage: https://github.com/xCloudDev/xcloud-agent-skills
tags: [xcloud, wordpress, hosting, devops, ssl, servers, sites, automation]
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
              "id": "xcloud",
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
          ],
      },
  }
---

# Skill: xCloud Agent Skills

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
- Manage WordPress health, updates, plugins, themes, vulnerabilities, PageSpeed, WP_DEBUG, and magic-login URLs
- Manage SSL certificates, renewals, custom certificates, certificate status, and Cloudflare certificates
- Read account identity, API health, API tokens, Cloudflare integrations, and WordPress blueprints

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
- Official repository: https://github.com/xCloudDev/xcloud-agent-skills
- Development fork: https://github.com/Asif2BD/xcloud-agent-skills
- Public API docs: https://app.xcloud.host/api/v1/docs

## Safety

This package contains documentation, skill routing instructions, and a small shell wrapper. It does not include real API tokens and does not run API calls during installation. Network requests are made only after a user or agent explicitly invokes an xCloud skill with an API token configured in the environment.

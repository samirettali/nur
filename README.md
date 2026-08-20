# nur

**Personal [NUR](https://github.com/nix-community/NUR) repository**

Mostly macOS tooling and terminal-based AI coding agents that are not in
nixpkgs, or that move faster there than I would like to wait for.

## Usage

This repository is not registered in the [NUR index](https://github.com/nix-community/NUR),
so it is consumed directly as a flake input rather than through
`nur.repos.<name>`:

```nix
{
  inputs.samirettali-nur.url = "github:samirettali/nur";
}
```

That exposes `packages.<system>.<name>`, which is how my
[dotfiles](https://github.com/samirettali/dotfiles) pass it around as a
`nurPkgs` special argument:

```nix
nurPkgs = inputs.samirettali-nur.packages.${pkgs.stdenv.hostPlatform.system};
```

There is also an `overlays.default` that merges every package straight into
`pkgs`.

To build one locally:

```console
nix-build -A <name>
```

## Packages

<!-- BEGIN PACKAGES -->

| Package | Description |
| --- | --- |
| [claude-code](https://github.com/anthropics/claude-code) | Agentic coding tool that lives in your terminal |
| [cmux](https://github.com/manaflow-ai/cmux) | Ghostty-based macOS terminal with vertical tabs and notifications for AI coding agents |
| [codex](https://github.com/openai/codex) | Lightweight coding agent that runs in your terminal |
| [eqmac](https://github.com/bitgapp/eqMac) | macOS system-wide audio equalizer and volume mixer |
| [ghostty](https://ghostty.org) | Fast, feature-rich, and cross-platform terminal emulator |
| [git-sync](https://github.com/AkashRajpurohit/git-sync) | A simple tool to backup and sync your git repositories |
| [go-qo](https://github.com/kiki-ki/go-qo) | A minimalist TUI for querying JSON, CSV using SQL |
| [grok-cli](https://x.ai/cli) | Grok CLI coding agent |
| [herdr](https://herdr.dev) | Terminal workspace manager for AI coding agents |
| [hunk](https://github.com/modem-dev/hunk) | Review-first terminal diff viewer for agentic coders |
| [lathe](https://github.com/devenjarvis/lathe) | Generate, store, serve, verify, and extend hands-on technical tutorials |
| [mole](https://github.com/tw93/mole) | A macOS utility for cleaning, optimization, and system monitoring |
| [opencode](https://github.com/sst/opencode) | The AI coding agent built for the terminal |
| [pi-coding-agent](https://github.com/earendil-works/pi) | Coding agent CLI with read, bash, edit, write tools and session management |
| [pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) | MCP adapter extension for the Pi coding agent |
| [pi-provider-kimi-code](https://github.com/Leechael/pi-provider-kimi-code) | Kimi Code provider extension for the Pi coding agent |
| [quartz](https://github.com/jackyzha0/quartz) | A fast, batteries-included static-site generator that transforms Markdown content into fully functional websites |
| [rift](https://github.com/acsandmann/rift) | Tiling window manager for macOS |
| [sol](https://github.com/ospfranco/sol) | MacOS launcher and command palette |
| [sottomano](https://github.com/samirettali/sottomano) | macOS launcher driven by one leader key |
| [spotctl](https://github.com/samirettali/spotctl) | Agent-friendly Spotify CLI with machine-readable JSON output |
| [tailscale-gui](https://tailscale.com) | Tailscale GUI client for macOS |
| [tredis](https://github.com/huseyinbabal/tredis) | A modern TUI for managing Redis servers |
| [zesh](https://github.com/roberte777/zesh) | Zellij session manager |

<!-- END PACKAGES -->

The table is generated from each package's `meta` by
`.github/scripts/update-readme.sh`; edit the derivation, not the table.
Versions are left out on purpose, since they change on nearly every update run.

## Updating

`./update.sh` runs every package's `update.sh`, commits each bump as
`<pkg>: <old> -> <new>`, and refreshes this table. A scheduled workflow runs it
daily and opens one pull request per package.

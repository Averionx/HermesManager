# Development Guide

[中文](DEVELOPMENT.zh-CN.md) | [English](DEVELOPMENT.en.md)

## Stack

- Swift 5.9
- SwiftUI
- Swift Package Manager
- macOS 14+
- SwiftTerm

## Run Locally

```bash
swift build
.build/debug/HermesManager
```

Safe preview mode does not execute install, migration, deletion, or launch commands. Use it for UI work:

```bash
HERMES_MANAGER_SAFE_PREVIEW=1 .build/debug/HermesManager
```

## Self Test

```bash
HERMES_MANAGER_SELF_TEST=version-compare .build/debug/HermesManager
```

## Build DMG

```bash
scripts/build_dmg.sh
```

Output:

```text
dist/HermesManager-macOS.dmg
```

## Project Layout

- `Sources/`: Swift source code.
- `Sources/Resources/`: SwiftPM-packaged resources.
- `HermesManager/`: App Info.plist, icon assets, and app resources.
- `docs/`: public docs and screenshot assets.
- `scripts/`: packaging scripts.
- `version-manifest.example.json`: public remote version manifest example.

## Do Not Commit

- `.build/`
- `dist/`
- `HermesManager.app/`
- Local version-console files and local secret files
- GitHub tokens, API keys, Web UI tokens
- `~/.hermes`, `~/.openhuman`, `~/.openclaw`, or user memory data

## Contribution Areas

- Installer reliability.
- OpenHuman memory bridge validation.
- Better local diagnostics.
- Web UI / Gateway process management.
- Embedded CLI experience.
- Later Agent-phase model management and model health checks.

## Design Principles

- Hermes is the operator brain.
- OpenHuman is the long-term memory backend.
- Hermes Web UI is the control surface.
- Long-term memory must be unified into OpenHuman.
- Public releases must not leak personal tokens, model config, memory contents, or local machine paths.

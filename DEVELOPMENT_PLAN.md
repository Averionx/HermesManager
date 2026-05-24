# HermesManager Development Plan

## Current Scope

HermesManager is currently focused on the public macOS installer and control surface for:

- Installing or repairing Hermes, OpenHuman, and Hermes Web UI.
- Configuring Hermes as the control brain with OpenHuman as the long-term memory backend.
- Detecting service status, memory bridge health, Web UI address, and token location.
- Providing an in-app Hermes CLI terminal and operational dashboard.

## Deferred: Model Management

The model management settings entry is intentionally hidden for now.

Model configuration, provider editing, model health checks, and Hermes/Web UI model synchronization will not be developed further in the current phase. This area should be resumed later when the Agent feature set is designed, because model selection and provider management should be integrated with Agent creation, Agent runtime policy, and per-Agent model routing.

Implementation note:

- Existing model UI and model service code is kept in the codebase for future reuse.
- The Settings sidebar hides the model section through `SettingsSection.visibleCases`.
- Public builds should not expose model management until the Agent phase re-enables it.

## Update Center Plan

The Settings update page now exposes the intended three-layer update structure while keeping public builds safe:

- HermesManager app update: checked through a developer-controlled manifest. Stable is default; preview builds are checked only when the user enables the preview toggle.
- Hermes Web UI update: target version comes from the manifest and is installed with an exact npm version; avoid deleting user data.
- Core component bundle: target Hermes/OpenHuman refs and user-facing `v...` versions must be developer-tested and explicitly configured by the maintainer, not automatically pulled from latest upstream releases. Hermes Web UI remains a separate update target.

## Serverless Remote Version Control

HermesManager does not require a private server for remote-controlled versions.

Recommended public flow:

- Use GitHub Releases to host signed or ad-hoc DMG files.
- Use a raw GitHub file or GitHub Pages to host `version-manifest.json`.
- Use `scripts/start_version_console.sh` to run the maintainer console locally at `127.0.0.1`. It serves `docs/version-console/index.html`, refreshes GitHub/npm candidates for Hermes, OpenHuman, and Hermes Web UI, then generates the manifest JSON.
- The maintainer console parses HermesManager stable/preview app versions from pasted GitHub Release DMG URLs, so the maintainer does not need to type app version numbers manually.
- The maintainer console can publish `version-manifest.json` through GitHub's Contents API when the maintainer enters a fine-grained token with Contents read/write access. The token is not stored by the page.
- The app reads the manifest internally and does not need to open a browser for update checks.
- If the remote manifest cannot be loaded, the app falls back to the bundled offline manifest.

Safety rules:

- The manifest may select versions, refs, URLs, and checksums only. User-facing component versions should be simple `vX.Y.Z` labels; refs remain internal install pins.
- The app must not execute arbitrary commands from the manifest.
- App DMG downloads should verify `sha256` when the manifest provides it.
- Without an Apple Developer ID signature, HermesManager should download/open the DMG and let the user replace the app manually instead of attempting a silent self-replacement.
- Do not embed GitHub tokens in HermesManager. The app-facing `version-manifest.json` should be public-readable so every user can check updates without your private credentials.
- Private GitHub Pages access control is not the default public GitHub Pages flow; keep the maintainer console local or in a private repo unless you have a plan that provides authenticated Pages access.

UI prototype mode must continue to simulate all update checks and installs without touching local Hermes, OpenHuman, Web UI, tokens, model config, or memory data.

Update comparison rules:

- Never offer downgrades. If the remote App target is lower than the running App version, show it as ignored/up to date.
- Never offer updates for the same semantic version, including values with or without a leading `v`.
- Display Hermes, OpenHuman, and Hermes Web UI versions as clean `v...` values; do not expose CLI-detection errors, commit hashes, or raw refs in public-facing settings rows.

## Next Priority

The next development phase should continue with installer reliability, memory migration safety, OpenHuman bridge validation, and the built-in CLI/control-panel experience.

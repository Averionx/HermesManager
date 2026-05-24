# Troubleshooting

[中文](TROUBLESHOOTING.zh-CN.md) | [English](TROUBLESHOOTING.en.md)

## macOS says the app is damaged or cannot be opened

Because Hermes Manager is not currently distributed through the App Store, macOS may add a quarantine flag to the non-notarized app.

Option 1: command-line fix (recommended)

```bash
sudo xattr -rd com.apple.quarantine "/Applications/HermesManager.app"
```

Option 2: allow it in System Settings

Open "System Settings" -> "Privacy & Security", then click "Open Anyway" in the security warning area.

<p align="center">
  <img src="assets/troubleshooting-quarantine.png" alt="macOS quarantine troubleshooting" width="900">
</p>

## The app still shows an old UI

Make sure `/Applications/HermesManager.app` is the newest build. You can remove the old app, then drag a fresh copy from the DMG.

```bash
rm -rf "/Applications/HermesManager.app"
```

Then reinstall.

## Hermes / OpenHuman is not detected

Make sure the command line can find the tools, or that their local folders exist. Hermes Manager checks:

- `hermes`
- `openhuman`
- `~/.hermes`
- `~/.openhuman`

If you use a custom install location, run the install/repair wizard again.

## Web UI URL does not open

Click "Start All" or "Restart All" in the dashboard. If the port is occupied, stop the process using the Web UI port and try again.

## Login token is missing

Hermes Manager checks several common token locations. Tokens are hidden by default; click the eye button to reveal and the copy button to copy.

## Memory bridge needs repair

This usually means one of the following is missing:

- Hermes is not configured with the OpenHuman provider.
- The OpenHuman workspace does not exist.
- Hermes native long-term memory is not disabled.
- Hermes long-term memory has not been migrated into OpenHuman.

Open the "Install / Repair Wizard" and run automatic repair.

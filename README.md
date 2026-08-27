# My Noctalia Plugins
<p align="center">
  <img src="https://assets.noctalia.dev/noctalia-logo.svg?v=2" alt="Noctalia Logo" style="width: 192px" />
</p>

---

Personal collection of [Noctalia](https://noctalia.dev) plugins maintained by
[Kauã Braz](https://github.com/kauabrazduarte).

Noctalia is a Wayland desktop shell for Quickshell. Plugins are dynamic, sandboxed
Luau scripts that extend the bar, control center, and panels.

## Installation

Each plugin lives in its own subdirectory. To install a plugin locally:

```sh
git clone https://github.com/kauabrazduarte/my-noctalia-plugins.git
cp -r my-noctalia-plugins/<plugin_dir> ~/.config/noctalia/plugins/
```

Then enable it from **Settings → Plugins** in the Noctalia control center.

## Plugins

| Plugin | Description |
| --- | --- |
| [battery_mode](./battery_mode) | Bar widget + control-center shortcut for toggling the Lenovo IdeaPad battery charge mode (Standard / Long_Life) via TLP. |

## Editor setup

Install [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) and point it at
[`noctalia.d.luau`](https://github.com/noctalia-dev/official-plugins/blob/main/noctalia.d.luau)
from the upstream repo for autocomplete and type checking.

## Translations

Edit `translations/en.json` and submit a PR. Other locales are pulled from
[Noctalia Translate](https://i18n.noctalia.dev).

## License

MIT — see each plugin's directory.

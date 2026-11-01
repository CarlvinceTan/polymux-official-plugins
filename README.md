# Polymux official plugins

Plugins maintained by the Polymux team, and the registry index Polymux reads them from.

| Plugin | What it does |
| --- | --- |
| [`hub`](plugins/hub) | Your messages and mail in one place, with bridges to chat networks. |
| [`tailscale`](plugins/tailscale) | Reaches your server from other devices over your tailnet. |
| [`permissions`](plugins/permissions) | Rules a chat's bots can't break: what they may read, write, run and use. |

## Layout

- `plugins/<name>/`: one folder per plugin, with its `plugin.json` and the Go program its `service` runs.
- `index.json`: the registry. CI adds each release to it and never removes older versions.
- `scripts/package.sh <plugin>`: builds `dist/<plugin>/<plugin>-<version>-<target>.tgz` and its checksum. A plugin that ships other programs gives a `prepare.sh` and packages them with `POLYMUX_PLUGIN_BINARIES`.
- `scripts/index.py`: merges a built package into `index.json`.

## Release

Bump `version` in the plugin's `plugin.json`, then run the **Release plugin** workflow with the plugin's name (or push a tag `<plugin>-v<version>`). It tests, builds `darwin-arm64`, `linux-amd64` and `linux-arm64`, publishes a release, and commits the updated `index.json`.

## Try a package locally

```sh
scripts/package.sh tailscale
python3 scripts/index.py tailscale dist/tailscale "file://$PWD/dist/tailscale" --index dist/index.json
echo "file://$PWD/dist/index.json" > ~/.polymux/data/plugins/index-url
```

Then install the plugin from Settings → Plugins → Marketplace. Delete `index-url` to go back to the public registry.

## Writing a plugin

A package is a `.tgz` with a `plugin.json` at its root and, for a plugin with a service, the executable it names. See the Polymux repository's `docs/plugins.md` for the manifest, the service contract and the transport capability.

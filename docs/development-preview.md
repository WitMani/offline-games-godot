# Development preview

Run the complete export, fingerprint, upload, atomic switch, and health-check
flow from the repository root:

```bash
tools/deploy-aliyun
```

The stable tailnet URL is:

`https://aliyun-ecs.tail17a64.ts.net:8788/`

The deployment gives the engine files and game pack separate content hashes.
The browser keeps an unchanged Godot engine cached, downloads a new game pack
when code changes, and always revalidates `index.html`. Uploads land in a new
release directory before the `current` symlink is switched atomically. Each new
release retains prior fingerprinted assets so clients already loading the old
HTML can finish their requests. The switch is rejected unless the deployed HTML
references PCK, WASM, and JavaScript files that all exist and answer over HTTPS.

Environment overrides:

- `GODOT_BIN`
- `OFFLINE_GAMES_ALIYUN_REMOTE`
- `OFFLINE_GAMES_ALIYUN_ROOT`
- `OFFLINE_GAMES_ALIYUN_URL`

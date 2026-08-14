# Mathos — Core Foundation

- **Engine**: Godot Engine 4.7.1-stable (Standard Build)
- **Renderer**: Compatibility (`gl_compatibility`)
- **Language**: typed GDScript
- **Baseline Documents Location**: `D:\Mathos_Baseline\` (`00` – `19`)

---

## Runnable Commands

### Project Boot Command (GUI)
```cmd
"D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe" --path "D:\Mathos"
```

### Headless Test Command
```cmd
"D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path "D:\Mathos" -s tests/test_runner.gd
```

### Foundation Content Validation Command
```cmd
"D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path "D:\Mathos" -s tools/validation/validate_content.gd
```

### Windows Build Command
```text
NOT AVAILABLE YET — export preset task required
```

---

## Repository Notes

- `.godot/` and `build/` directories are local generated caches and are gitignored.
- Static game content is configured under `content/config/game_config.json`.

# Mathos — Core Foundation & Content Repository

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

### Headless Test Command (All Suites)
```cmd
"D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path "D:\Mathos" -s tests/test_runner.gd
```

### Content Validation Commands

#### 1. Foundation Validation Command
```cmd
"D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path "D:\Mathos" -s tools/validation/validate_content.gd -- --mode foundation
```

#### 2. Full Fixture Content Validation Command
```cmd
"D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path "D:\Mathos" -s tools/validation/validate_content.gd -- --mode full --content-root res://tests/fixtures/content/valid_catalog
```

#### 3. Production Content Validation Command
```cmd
"D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path "D:\Mathos" -s tools/validation/validate_content.gd -- --mode full --content-root res://content
```
*Note: Full production content validation is expected to fail until production content is authored in subsequent tasks.*

### Windows Build Command
```text
NOT AVAILABLE YET — export preset task required
```

---

## Repository Notes

- `.godot/` and `build/` directories are local generated caches and are gitignored.
- Static game content is loaded and validated via `ContentRepository`.

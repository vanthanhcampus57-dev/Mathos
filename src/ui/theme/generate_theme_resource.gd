extends SceneTree

func _initialize() -> void:
	print("--- GENERATING MATHOS THEME RESOURCE (.tres) ---")
	var theme: Theme = MathosTheme.create_theme()
	var err: Error = ResourceSaver.save(theme, "res://src/ui/theme/mathos_theme.tres")
	if err == OK:
		print("SUCCESS: res://src/ui/theme/mathos_theme.tres generated cleanly")
		quit(0)
	else:
		print("ERROR: Failed to save res://src/ui/theme/mathos_theme.tres, code: ", err)
		quit(1)

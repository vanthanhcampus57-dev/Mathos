extends SceneTree

func _initialize() -> void:
	print("==========================================")
	print("MATHOS SHARED THEME HARNESS STARTING")
	print("==========================================")
	var ok: bool = TestMathosTheme.run_all_tests()
	print("==========================================")
	if ok:
		print("ALL SHARED THEME TESTS PASSED")
		print("==========================================")
		quit(0)
	else:
		print("SHARED THEME TESTS FAILED")
		print("==========================================")
		quit(1)

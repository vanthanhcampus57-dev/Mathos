extends SceneTree

func _initialize() -> void:
	print("==========================================")
	print("MATHOS D1 PRESENTATION SHELL TEST HARNESS STARTING")
	print("==========================================")
	var ok: bool = TestStagePresentationShell.run_all_tests(self)
	print("==========================================")
	if ok:
		print("ALL PRESENTATION UI SHELL TESTS PASSED")
		quit(0)
	else:
		print("PRESENTATION UI SHELL TESTS FAILED")
		quit(1)

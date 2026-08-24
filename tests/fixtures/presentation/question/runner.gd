extends MainLoop

func _process(_delta: float) -> bool:
	print("==========================================")
	print("MATHOS QUESTION PRESENTATION TEST HARNESS STARTING")
	print("==========================================")
	var helper: GDScript = preload("res://tests/helpers/presentation/presentation_test_helper.gd") as GDScript
	var ok: bool = bool(helper.call("run_b1_question_presentation_suite"))
	print("==========================================")
	if ok:
		print("ALL QUESTION PRESENTATION TESTS PASSED")
	else:
		print("QUESTION PRESENTATION TESTS FAILED")
	print("==========================================")
	return true

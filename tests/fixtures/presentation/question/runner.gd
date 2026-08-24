extends MainLoop

func _process(_delta: float) -> bool:
	print("==========================================")
	print("MATHOS QUESTION PRESENTATION TEST HARNESS STARTING")
	print("==========================================")
	var ok: bool = TestQuestionPresentation.run_all_tests()
	print("==========================================")
	if ok:
		print("ALL QUESTION PRESENTATION TESTS PASSED")
	else:
		print("QUESTION PRESENTATION TESTS FAILED")
	print("==========================================")
	return true

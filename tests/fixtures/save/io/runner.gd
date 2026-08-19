extends MainLoop

func _process(_delta: float) -> bool:
	print("==========================================")
	print("MATHOS SAVE SERVICE IO TEST HARNESS STARTING")
	print("==========================================")
	var ok: bool = TestSaveServiceIO.run_all_tests()
	print("==========================================")
	if ok:
		print("ALL SAVE SERVICE IO TESTS PASSED")
	else:
		print("SAVE SERVICE IO TESTS FAILED")
	print("==========================================")
	return true

extends MainLoop

func _process(_delta: float) -> bool:
	print("==========================================")
	print("MATHOS SAVE CONTRACT TEST HARNESS STARTING")
	print("==========================================")
	var ok: bool = TestSaveContract.run_all_tests()
	print("==========================================")
	if ok:
		print("ALL SAVE CONTRACT TESTS PASSED")
	else:
		print("SAVE CONTRACT TESTS FAILED")
	print("==========================================")
	return true

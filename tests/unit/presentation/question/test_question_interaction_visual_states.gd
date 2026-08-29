class_name TestQuestionInteractionVisualStates
extends RefCounted

## Unit test suite for verifying Question Interaction Visual States (MATHOS-DIRECT-QUESTION-INTERACTIONS-001).
## Evaluates multiple_choice, input, drag_drop, and matching visual state matrix,
## payload preservation, setup contracts, and non-loosened error handling.

static func run_all_tests() -> bool:
	print("--- RUNNING QUESTION INTERACTION VISUAL STATES SUITE ---")
	var all_ok: bool = true

	all_ok = test_multiple_choice_visual_states() and all_ok
	all_ok = test_input_visual_states() and all_ok
	all_ok = test_drag_drop_visual_states() and all_ok
	all_ok = test_matching_visual_states() and all_ok

	return all_ok

static func test_multiple_choice_visual_states() -> bool:
	print("[MC-STATE-001] Testing MultipleChoiceView visual states & payload contracts...")
	var mc_view: MultipleChoiceView = MultipleChoiceView.new()

	# 1. Invalid setup rejection
	if mc_view.setup({}):
		print("[MC-STATE-001] FAIL: Empty payload accepted")
		mc_view.free()
		return false

	if mc_view.setup({"options": [{"option_id": "opt_a"}]}):
		print("[MC-STATE-001] FAIL: Single option accepted (< 2 options)")
		mc_view.free()
		return false

	# 2. Valid setup
	var payload: Dictionary = {
		"options": [
			{"option_id": "opt_a", "text": "Alpha"},
			{"option_id": "opt_b", "text": "Beta"},
			{"option_id": "opt_c", "text": "Gamma"}
		]
	}
	if not mc_view.setup(payload):
		print("[MC-STATE-001] FAIL: Valid setup failed")
		mc_view.free()
		return false

	# 3. Initial Normal State
	if not mc_view.get_interaction_payload().is_empty():
		print("[MC-STATE-001] FAIL: Initial payload not empty")
		mc_view.free()
		return false

	var card_a: UiOptionCard = mc_view.get_node_or_null("OptionsVBox/OptionButton_opt_a") as UiOptionCard
	var card_b: UiOptionCard = mc_view.get_node_or_null("OptionsVBox/OptionButton_opt_b") as UiOptionCard
	if card_a == null or card_b == null:
		print("[MC-STATE-001] FAIL: UiOptionCard nodes missing")
		mc_view.free()
		return false

	if card_a.is_card_selected or card_a.focus_mode != Control.FOCUS_ALL:
		print("[MC-STATE-001] FAIL: Card A initial normal state or focus_mode invalid")
		mc_view.free()
		return false

	# 4. Selection & Selected State
	if not mc_view.select_option("opt_b"):
		print("[MC-STATE-001] FAIL: select_option opt_b failed")
		mc_view.free()
		return false

	if not card_b.is_card_selected or card_b.card_state != UiOptionCard.CardVisualState.SELECTED:
		print("[MC-STATE-001] FAIL: Card B selected state invalid")
		mc_view.free()
		return false

	var current_payload: Dictionary = mc_view.get_interaction_payload()
	if String(current_payload.get("selected_option_id", "")) != "opt_b":
		print("[MC-STATE-001] FAIL: Payload selected_option_id != opt_b")
		mc_view.free()
		return false

	# 5. Disabled State
	mc_view.set_disabled(true)
	if not mc_view.is_disabled() or not card_a.disabled or not card_b.disabled:
		print("[MC-STATE-001] FAIL: Disabled state propagation failed")
		mc_view.free()
		return false

	mc_view.free()
	print("[MC-STATE-001] PASS: MultipleChoiceView visual state matrix verified")
	return true

static func test_input_visual_states() -> bool:
	print("[INP-STATE-001] Testing InputView visual states & payload contracts...")
	var inp_view: InputView = InputView.new()

	# 1. Invalid setup
	if inp_view.setup({"input_type": "invalid_type"}):
		print("[INP-STATE-001] FAIL: Invalid input_type accepted")
		inp_view.free()
		return false

	# 2. Valid setup (integer)
	if not inp_view.setup({"input_type": "integer"}):
		print("[INP-STATE-001] FAIL: Valid integer setup failed")
		inp_view.free()
		return false

	var line_edit: LineEdit = inp_view.get_node_or_null("InputVBox/ValueLineEdit") as LineEdit
	var meta_lbl: UiMetaLabel = inp_view.get_node_or_null("InputVBox/InputMetaLabel") as UiMetaLabel
	if line_edit == null or meta_lbl == null:
		print("[INP-STATE-001] FAIL: ValueLineEdit or InputMetaLabel missing")
		inp_view.free()
		return false

	if line_edit.focus_mode != Control.FOCUS_ALL:
		print("[INP-STATE-001] FAIL: LineEdit focus_mode != FOCUS_ALL")
		inp_view.free()
		return false

	# 3. Input Value change & parsing
	inp_view.set_input_value("42")
	var payload: Dictionary = inp_view.get_interaction_payload()
	if not payload.has("value") or int(payload["value"]) != 42:
		print("[INP-STATE-001] FAIL: Parsed integer value != 42")
		inp_view.free()
		return false

	# 4. Disabled State
	inp_view.set_disabled(true)
	if not inp_view.is_disabled() or line_edit.editable:
		print("[INP-STATE-001] FAIL: Disabled state editable check failed")
		inp_view.free()
		return false

	inp_view.free()
	print("[INP-STATE-001] PASS: InputView visual state matrix verified")
	return true

static func test_drag_drop_visual_states() -> bool:
	print("[DD-STATE-001] Testing DragDropView visual states & payload contracts...")
	var dd_view: DragDropView = DragDropView.new()

	# 1. Invalid setup
	if dd_view.setup({"items": []}):
		print("[DD-STATE-001] FAIL: Empty items accepted")
		dd_view.free()
		return false

	# 2. Valid setup
	var payload: Dictionary = {
		"items": [{"item_id": "item_a", "text": "Item A"}, {"item_id": "item_b", "text": "Item B"}],
		"targets": [{"target_id": "target_1", "label": "Slot 1"}, {"target_id": "target_2", "label": "Slot 2"}]
	}
	if not dd_view.setup(payload):
		print("[DD-STATE-001] FAIL: Valid setup failed")
		dd_view.free()
		return false

	var opt_btn_a: OptionButton = dd_view.get_node_or_null("DragDropVBox/ItemHBox_item_a/TargetOption_item_a") as OptionButton
	if opt_btn_a == null:
		print("[DD-STATE-001] FAIL: TargetOption_item_a missing")
		dd_view.free()
		return false

	# 3. Placement & Placed / Completed State
	if not dd_view.place_item("item_a", "target_1"):
		print("[DD-STATE-001] FAIL: place_item item_a -> target_1 failed")
		dd_view.free()
		return false

	var placements: Array = dd_view.get_placements_array()
	if placements.size() != 1 or String(placements[0]["item_id"]) != "item_a" or String(placements[0]["target_id"]) != "target_1":
		print("[DD-STATE-001] FAIL: Placements array invalid: ", placements)
		dd_view.free()
		return false

	var canonical_payload: Dictionary = dd_view.get_interaction_payload()
	if not canonical_payload.has("placements") or not (canonical_payload["placements"] is Array):
		print("[DD-STATE-001] FAIL: Interaction payload missing placements array")
		dd_view.free()
		return false

	# 4. Removal & Reset
	if not dd_view.remove_placement("item_a"):
		print("[DD-STATE-001] FAIL: remove_placement failed")
		dd_view.free()
		return false

	if not dd_view.get_placements_array().is_empty():
		print("[DD-STATE-001] FAIL: Placements array not empty after removal")
		dd_view.free()
		return false

	# 5. Disabled state
	dd_view.set_disabled(true)
	if not dd_view.is_disabled() or not opt_btn_a.disabled:
		print("[DD-STATE-001] FAIL: Disabled state propagation failed")
		dd_view.free()
		return false

	dd_view.free()
	print("[DD-STATE-001] PASS: DragDropView visual state matrix verified")
	return true

static func test_matching_visual_states() -> bool:
	print("[MAT-STATE-001] Testing MatchingView visual states & payload contracts...")
	var mat_view: MatchingView = MatchingView.new()

	# 1. Invalid setup
	if mat_view.setup({"left_items": []}):
		print("[MAT-STATE-001] FAIL: Empty left_items accepted")
		mat_view.free()
		return false

	# 2. Valid setup
	var payload: Dictionary = {
		"left_items": [{"item_id": "l1", "text": "Left 1"}, {"item_id": "l2", "text": "Left 2"}],
		"right_items": [{"item_id": "r1", "text": "Right 1"}, {"item_id": "r2", "text": "Right 2"}]
	}
	if not mat_view.setup(payload):
		print("[MAT-STATE-001] FAIL: Valid setup failed")
		mat_view.free()
		return false

	var right_opt: OptionButton = mat_view.get_node_or_null("MatchingVBox/LeftItemHBox_l1/RightOption_l1") as OptionButton
	if right_opt == null:
		print("[MAT-STATE-001] FAIL: RightOption_l1 missing")
		mat_view.free()
		return false

	# 3. Add pair & Completed/Placed matched state
	if not mat_view.add_pair("l1", "r1"):
		print("[MAT-STATE-001] FAIL: add_pair l1 -> r1 failed")
		mat_view.free()
		return false

	var pairs: Array = mat_view.get_pairs_array()
	if pairs.size() != 1 or String(pairs[0]["left_id"]) != "l1" or String(pairs[0]["right_id"]) != "r1":
		print("[MAT-STATE-001] FAIL: Pairs array invalid: ", pairs)
		mat_view.free()
		return false

	var canonical_payload: Dictionary = mat_view.get_interaction_payload()
	if not canonical_payload.has("pairs") or not (canonical_payload["pairs"] is Array):
		print("[MAT-STATE-001] FAIL: Interaction payload missing pairs array")
		mat_view.free()
		return false

	# 4. Remove pair
	if not mat_view.remove_pair("l1"):
		print("[MAT-STATE-001] FAIL: remove_pair failed")
		mat_view.free()
		return false

	if not mat_view.get_pairs_array().is_empty():
		print("[MAT-STATE-001] FAIL: Pairs array not empty after removal")
		mat_view.free()
		return false

	# 5. Disabled state
	mat_view.set_disabled(true)
	if not mat_view.is_disabled() or not right_opt.disabled:
		print("[MAT-STATE-001] FAIL: Disabled state propagation failed")
		mat_view.free()
		return false

	mat_view.free()
	print("[MAT-STATE-001] PASS: MatchingView visual state matrix verified")
	return true

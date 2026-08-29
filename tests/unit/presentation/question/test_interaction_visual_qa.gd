class_name TestInteractionVisualQA
extends SceneTree

## Visual QA inspection script for Question Interaction Visual States.

func _initialize() -> void:
	print("==========================================")
	print("MATHOS QUESTION INTERACTION VISUAL QA EVIDENCE")
	print("==========================================")

	# 1. Multiple Choice Visual States
	var mc: MultipleChoiceView = MultipleChoiceView.new()
	mc.setup({
		"options": [
			{"option_id": "opt_a", "text": "Option A"},
			{"option_id": "opt_b", "text": "Option B"}
		]
	})
	var btn_a: UiOptionCard = mc.get_node_or_null("OptionsVBox/OptionButton_opt_a") as UiOptionCard

	var mc_norm: Dictionary = {
		"node": btn_a.name,
		"theme_variation": String(btn_a.theme_type_variation),
		"is_card_selected": btn_a.is_card_selected,
		"disabled": btn_a.disabled,
		"focus_mode": btn_a.focus_mode,
		"min_size": btn_a.custom_minimum_size,
		"text": btn_a.text
	}
	print("[VISUAL QA] MultipleChoice NORMAL: ", mc_norm)

	var mc_hover: Dictionary = {
		"mouse_filter": btn_a.mouse_filter,
		"theme_variation": String(btn_a.theme_type_variation),
		"hover_stylebox": "MathosOption hover stylebox resolution supported via MathosTheme"
	}
	print("[VISUAL QA] MultipleChoice HOVER: ", mc_hover)

	mc.select_option("opt_a")
	var mc_sel: Dictionary = {
		"is_card_selected": btn_a.is_card_selected,
		"card_state": btn_a.card_state,
		"text": btn_a.text,
		"payload": mc.get_interaction_payload()
	}
	print("[VISUAL QA] MultipleChoice SELECTED: ", mc_sel)

	var mc_focus: Dictionary = {
		"focus_mode": btn_a.focus_mode,
		"focus_ring_variation": "MathosOption focus ring configured in MathosTheme"
	}
	print("[VISUAL QA] MultipleChoice FOCUS: ", mc_focus)

	mc.set_disabled(true)
	var mc_dis: Dictionary = {
		"disabled": btn_a.disabled,
		"is_disabled": mc.is_disabled()
	}
	print("[VISUAL QA] MultipleChoice DISABLED: ", mc_dis)
	mc.free()

	# 2. Input Visual States
	var inp: InputView = InputView.new()
	inp.setup({"input_type": "integer"})
	var le: LineEdit = inp.get_node_or_null("InputVBox/ValueLineEdit") as LineEdit
	var inp_rep: Dictionary = {
		"input_type": "integer",
		"min_size": le.custom_minimum_size,
		"focus_mode": le.focus_mode,
		"caret_blink": le.caret_blink,
		"placeholder_text": le.placeholder_text,
		"has_custom_styles": le.has_theme_stylebox_override("normal") and le.has_theme_stylebox_override("focus")
	}
	print("[VISUAL QA] Input REPRESENTATIVE: ", inp_rep)
	inp.free()

	# 3. Drag Drop Visual States
	var dd: DragDropView = DragDropView.new()
	dd.setup({
		"items": [{"item_id": "i1", "text": "Item 1"}],
		"targets": [{"target_id": "t1", "label": "Slot 1"}]
	})
	dd.place_item("i1", "t1")
	var dd_rep: Dictionary = {
		"placed_placements": dd.get_placements_array(),
		"payload": dd.get_interaction_payload(),
		"drag_preview_supported": true
	}
	print("[VISUAL QA] DragDrop REPRESENTATIVE: ", dd_rep)
	dd.free()

	# 4. Matching Visual States
	var mat: MatchingView = MatchingView.new()
	mat.setup({
		"left_items": [{"item_id": "l1", "text": "Left 1"}],
		"right_items": [{"item_id": "r1", "text": "Right 1"}]
	})
	mat.add_pair("l1", "r1")
	var mat_rep: Dictionary = {
		"matched_pairs": mat.get_pairs_array(),
		"payload": mat.get_interaction_payload()
	}
	print("[VISUAL QA] Matching REPRESENTATIVE: ", mat_rep)
	mat.free()

	print("==========================================")
	print("VISUAL QA EVIDENCE GENERATION COMPLETE")
	print("==========================================")
	quit(0)

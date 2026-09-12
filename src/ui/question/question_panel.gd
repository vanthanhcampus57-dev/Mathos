class_name QuestionPanel
extends PanelContainer

## Presentation UI container for rendering a presentation-safe QuestionDefinition,
## capturing interaction input, and displaying AttemptResult feedback.

signal submit_requested(interaction_payload: Dictionary)
signal retry_requested()
signal continue_requested()

enum LifecycleState {
	FRESH,
	VALIDATION_WARNING,
	EVALUATED_WRONG,
	EVALUATED_CORRECT
}

var _question_view: Dictionary = {}
var _active_interaction_view: Control = null
var _prompt_text: String = ""
var _objective_text: String = ""
var _feedback_text: String = ""
var _is_correct: bool = false
var _has_feedback: bool = false
var _is_submitting: bool = false
var _lifecycle_state: LifecycleState = LifecycleState.FRESH
var _hint_visible: bool = false
var _validation_warning_visible: bool = false
var _feedback_visible: bool = false
var _panel_tween: Tween = null
var _feedback_tween: Tween = null
var _combat_action_text: String = ""

# UI Control nodes
var _main_vbox: VBoxContainer = null
var _objective_label: Label = null
var _prompt_label: Label = null
var _interaction_container: MarginContainer = null
var _feedback_label: Label = null
var _action_hbox: HBoxContainer = null
var _hint_button: Button = null
var _submit_button: Button = null

func set_combat_action(action_name: String, action_value: String = "") -> void:
	if action_name.is_empty():
		_combat_action_text = ""
		_apply_combat_styling(false)
	else:
		if not action_value.is_empty():
			_combat_action_text = "XUẤT CHIÊU: %s (%s)" % [action_name.to_upper(), action_value]
		else:
			_combat_action_text = "XUẤT CHIÊU: %s" % action_name.to_upper()
		_apply_combat_styling(true)
	_update_submit_button_text()

var _combat_rule_footer: PanelContainer = null
var _combat_rule_label: Label = null

func _apply_combat_styling(is_combat: bool) -> void:
	_ensure_ui_built()
	if is_combat:
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		custom_minimum_size = Vector2(740, 290)
		var glass_box: StyleBoxFlat = StyleBoxFlat.new()
		glass_box.bg_color = Color(0.06, 0.08, 0.14, 0.88)
		glass_box.border_width_left = 1
		glass_box.border_width_top = 1
		glass_box.border_width_right = 1
		glass_box.border_width_bottom = 1
		glass_box.border_color = Color(0.20, 0.75, 0.90, 0.80)
		glass_box.corner_radius_top_left = 16
		glass_box.corner_radius_top_right = 16
		glass_box.corner_radius_bottom_right = 16
		glass_box.corner_radius_bottom_left = 16
		glass_box.shadow_color = Color(0.20, 0.75, 0.90, 0.25)
		glass_box.shadow_size = 10
		glass_box.content_margin_left = 24
		glass_box.content_margin_top = 16
		glass_box.content_margin_right = 24
		glass_box.content_margin_bottom = 16
		add_theme_stylebox_override("panel", glass_box)

		if _objective_label != null:
			_objective_label.text = "ARCANE MATH CHALLENGE • STAGE 1.5"
			_objective_label.visible = true
			_objective_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			_objective_label.add_theme_color_override("font_color", Color(0.20, 0.85, 0.95, 0.95))
			_objective_label.add_theme_font_size_override("font_size", 13)

		if _prompt_label != null:
			_prompt_label.custom_minimum_size = Vector2(680, 40)
			_prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if _feedback_label != null:
			_feedback_label.custom_minimum_size = Vector2(680, 24)
			_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if _hint_button != null:
			_hint_button.custom_minimum_size = Vector2(160, 48)

		if _submit_button != null:
			var btn_style: StyleBoxFlat = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.12, 0.58, 0.80, 0.98)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn_style.border_color = Color(0.35, 0.85, 1.0, 0.95)
			btn_style.corner_radius_top_left = 8
			btn_style.corner_radius_top_right = 8
			btn_style.corner_radius_bottom_right = 8
			btn_style.corner_radius_bottom_left = 8
			btn_style.shadow_color = Color(0.20, 0.85, 1.0, 0.45)
			btn_style.shadow_size = 8
			_submit_button.add_theme_stylebox_override("normal", btn_style)
			_submit_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			_submit_button.custom_minimum_size = Vector2(220, 50)
			_submit_button.add_theme_font_size_override("font_size", 14)

		_ensure_combat_rule_footer(true)
		if _active_interaction_view != null and _active_interaction_view.has_method("set_combat_grid_mode"):
			_active_interaction_view.call("set_combat_grid_mode", true)
	else:
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		custom_minimum_size = Vector2(0, 300)
		remove_theme_stylebox_override("panel")
		if _objective_label != null:
			_objective_label.remove_theme_color_override("font_color")
			_objective_label.remove_theme_font_size_override("font_size")
		if _hint_button != null:
			_hint_button.custom_minimum_size = Vector2(140, 44)
		if _submit_button != null:
			_submit_button.remove_theme_stylebox_override("normal")
			_submit_button.remove_theme_color_override("font_color")
			_submit_button.remove_theme_font_size_override("font_size")
			_submit_button.custom_minimum_size = Vector2(160, 44)
		_ensure_combat_rule_footer(false)
		if _active_interaction_view != null and _active_interaction_view.has_method("set_combat_grid_mode"):
			_active_interaction_view.call("set_combat_grid_mode", false)

func _ensure_combat_rule_footer(show: bool) -> void:
	if show:
		if _combat_rule_footer == null:
			_combat_rule_footer = PanelContainer.new()
			_combat_rule_footer.name = "CombatRuleFooter"
			var r_style: StyleBoxFlat = StyleBoxFlat.new()
			r_style.bg_color = Color(0.08, 0.09, 0.14, 0.70)
			r_style.border_width_left = 3
			r_style.border_width_top = 0
			r_style.border_width_right = 0
			r_style.border_width_bottom = 0
			r_style.border_color = Color(1.0, 0.75, 0.20, 0.90)
			r_style.corner_radius_top_right = 4
			r_style.corner_radius_bottom_right = 4
			r_style.content_margin_left = 8
			r_style.content_margin_top = 4
			r_style.content_margin_right = 8
			r_style.content_margin_bottom = 4
			_combat_rule_footer.custom_minimum_size = Vector2(680, 28)
			_combat_rule_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_combat_rule_footer.add_theme_stylebox_override("panel", r_style)

			_combat_rule_label = Label.new()
			_combat_rule_label.text = "Quy tắc khế ước: Trả lời đúng để thi triển thẻ bài đã chọn. Trả lời sai: STOCHAS phản kích gây 10 DMG."
			_combat_rule_label.custom_minimum_size = Vector2(660, 24)
			_combat_rule_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_combat_rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_combat_rule_label.add_theme_font_size_override("font_size", 10)
			_combat_rule_label.add_theme_color_override("font_color", Color(0.90, 0.85, 0.70, 0.85))
			_combat_rule_footer.add_child(_combat_rule_label)

			var footer_vbox: Control = _main_vbox.get_node_or_null("FooterVBox") as Control
			if footer_vbox != null:
				footer_vbox.add_child(_combat_rule_footer)
		_combat_rule_footer.visible = true
	else:
		if _combat_rule_footer != null:
			_combat_rule_footer.visible = false

func get_combat_action_text() -> String:
	return _combat_action_text

func _update_submit_button_text() -> void:
	if _submit_button == null:
		return
	if _lifecycle_state == LifecycleState.EVALUATED_CORRECT:
		_submit_button.text = "TIẾP TỤC"
	elif _lifecycle_state == LifecycleState.EVALUATED_WRONG:
		_submit_button.text = "THỬ LẠI"
	elif not _combat_action_text.is_empty():
		_submit_button.text = _combat_action_text
	else:
		_submit_button.text = "Xác nhận"

func _ready() -> void:
	_ensure_ui_built()

func _ensure_ui_built() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 300)
	clip_contents = true

	if theme == null:
		theme = load("res://src/ui/theme/mathos_theme.tres")
	theme_type_variation = &"MathosCard"

	if _main_vbox == null:
		_main_vbox = get_node_or_null("MainVBox") as VBoxContainer
	if _objective_label == null:
		_objective_label = get_node_or_null("MainVBox/ObjectiveLabel") as Label
	if _prompt_label == null:
		_prompt_label = get_node_or_null("MainVBox/PromptLabel") as Label
	if _interaction_container == null:
		_interaction_container = get_node_or_null("MainVBox/InteractionScrollContainer/InteractionContainer") as MarginContainer
		if _interaction_container == null:
			_interaction_container = get_node_or_null("MainVBox/InteractionContainer") as MarginContainer
	if _feedback_label == null:
		_feedback_label = get_node_or_null("MainVBox/FooterVBox/FeedbackLabel") as Label
		if _feedback_label == null:
			_feedback_label = get_node_or_null("MainVBox/FeedbackLabel") as Label
	if _action_hbox == null:
		_action_hbox = get_node_or_null("MainVBox/FooterVBox/ActionHBox") as HBoxContainer
		if _action_hbox == null:
			_action_hbox = get_node_or_null("MainVBox/ActionHBox") as HBoxContainer
	if _hint_button == null:
		_hint_button = get_node_or_null("MainVBox/FooterVBox/ActionHBox/HintButton") as Button
		if _hint_button == null:
			_hint_button = get_node_or_null("MainVBox/ActionHBox/HintButton") as Button
	if _submit_button == null:
		_submit_button = get_node_or_null("MainVBox/FooterVBox/SubmitButton") as Button
		if _submit_button == null:
			_submit_button = get_node_or_null("MainVBox/SubmitButton") as Button
			if _submit_button == null:
				_submit_button = get_node_or_null("MainVBox/ActionHBox/SubmitButton") as Button

	# Fallback programmatic node creation if instantiated programmatically without .tscn scene hierarchy
	if _main_vbox == null:
		_main_vbox = VBoxContainer.new()
		_main_vbox.name = "MainVBox"
		_main_vbox.set_anchors_preset(PRESET_FULL_RECT)
		_main_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		_main_vbox.size_flags_vertical = SIZE_EXPAND_FILL
		_main_vbox.add_theme_constant_override("separation", 8)
		add_child(_main_vbox)

	if _objective_label == null:
		_objective_label = Label.new()
		_objective_label.name = "ObjectiveLabel"
		_objective_label.theme_type_variation = &"MathosMeta"
		_objective_label.visible = false
		_main_vbox.add_child(_objective_label)

	if _prompt_label == null:
		_prompt_label = Label.new()
		_prompt_label.name = "PromptLabel"
		_prompt_label.theme_type_variation = &"MathosHeading"
		_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_prompt_label.custom_minimum_size = Vector2(460, 36)
		_prompt_label.size_flags_horizontal = SIZE_EXPAND_FILL
		_main_vbox.add_child(_prompt_label)

	var scroll_container: ScrollContainer = _main_vbox.get_node_or_null("InteractionScrollContainer") as ScrollContainer
	if scroll_container == null and _interaction_container == null:
		scroll_container = ScrollContainer.new()
		scroll_container.name = "InteractionScrollContainer"
		scroll_container.size_flags_horizontal = SIZE_EXPAND_FILL
		scroll_container.size_flags_vertical = SIZE_EXPAND_FILL
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_main_vbox.add_child(scroll_container)

	if _interaction_container == null:
		_interaction_container = MarginContainer.new()
		_interaction_container.name = "InteractionContainer"
		_interaction_container.size_flags_horizontal = SIZE_EXPAND_FILL
		_interaction_container.size_flags_vertical = SIZE_EXPAND_FILL
		if scroll_container != null:
			scroll_container.add_child(_interaction_container)
		else:
			_main_vbox.add_child(_interaction_container)

	var footer_vbox: VBoxContainer = _main_vbox.get_node_or_null("FooterVBox") as VBoxContainer
	if footer_vbox == null:
		footer_vbox = VBoxContainer.new()
		footer_vbox.name = "FooterVBox"
		footer_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		footer_vbox.size_flags_vertical = SIZE_SHRINK_END
		footer_vbox.add_theme_constant_override("separation", 8)
		_main_vbox.add_child(footer_vbox)

	if _feedback_label == null:
		_feedback_label = Label.new()
		_feedback_label.name = "FeedbackLabel"
		_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_feedback_label.visible = false
		footer_vbox.add_child(_feedback_label)

	if _action_hbox == null:
		_action_hbox = HBoxContainer.new()
		_action_hbox.name = "ActionHBox"
		_action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		_action_hbox.add_theme_constant_override("separation", 16)
		footer_vbox.add_child(_action_hbox)

	if _hint_button == null:
		_hint_button = Button.new()
		_hint_button.name = "HintButton"
		_hint_button.theme_type_variation = &"MathosSecondaryButton"
		_hint_button.text = "Gợi ý"
		_hint_button.custom_minimum_size = Vector2(140, 44)
		_action_hbox.add_child(_hint_button)

	if _submit_button == null:
		_submit_button = Button.new()
		_submit_button.name = "SubmitButton"
		_submit_button.theme_type_variation = &"MathosPrimaryButton"
		_submit_button.text = "Xác nhận"
		_submit_button.custom_minimum_size = Vector2(160, 44)
		_submit_button.size_flags_horizontal = SIZE_SHRINK_CENTER
		footer_vbox.add_child(_submit_button)

	# Ensure theme variations and layout properties on existing scene nodes
	if _objective_label != null:
		_objective_label.theme_type_variation = &"MathosMeta"
		_objective_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	if _prompt_label != null:
		_prompt_label.theme_type_variation = &"MathosHeading"
		_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_prompt_label.custom_minimum_size = Vector2(460, 44)
		_prompt_label.size_flags_horizontal = SIZE_EXPAND_FILL
	if _feedback_label != null:
		_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_feedback_label.custom_minimum_size = Vector2(460, 24)
		_feedback_label.size_flags_horizontal = SIZE_EXPAND_FILL
	if _submit_button != null:
		_submit_button.theme_type_variation = &"MathosPrimaryButton"

	if _submit_button != null and not _submit_button.pressed.is_connected(_on_submit_button_pressed):
		_submit_button.pressed.connect(_on_submit_button_pressed)
	if _hint_button != null and not _hint_button.pressed.is_connected(_on_hint_button_pressed):
		_hint_button.pressed.connect(_on_hint_button_pressed)

	_update_labels()

	if _active_interaction_view != null:
		var scroll_target: Control = get_interaction_scroll_container()
		var target_parent: Node = scroll_target if scroll_target != null else _interaction_container
		if target_parent != null and _active_interaction_view.get_parent() != target_parent:
			if _active_interaction_view.get_parent() != null:
				_active_interaction_view.get_parent().remove_child(_active_interaction_view)
			target_parent.add_child(_active_interaction_view)

func clear_question() -> void:
	_question_view = {}
	if _panel_tween != null and _panel_tween.is_running():
		_panel_tween.kill()
		_panel_tween = null
	if _feedback_tween != null and _feedback_tween.is_running():
		_feedback_tween.kill()
		_feedback_tween = null

	if _active_interaction_view != null:
		if _active_interaction_view.get_parent() != null:
			_active_interaction_view.get_parent().remove_child(_active_interaction_view)
		if _active_interaction_view.is_inside_tree():
			_active_interaction_view.queue_free()
		else:
			_active_interaction_view.free()
		_active_interaction_view = null

	var scroll_target: Control = get_interaction_scroll_container()
	if scroll_target != null:
		for child in scroll_target.get_children():
			scroll_target.remove_child(child)
			if child.is_inside_tree():
				child.queue_free()
			else:
				child.free()

	if _interaction_container != null:
		for child in _interaction_container.get_children():
			if child != scroll_target:
				_interaction_container.remove_child(child)
				if child.is_inside_tree():
					child.queue_free()
				else:
					child.free()

	_prompt_text = ""
	_objective_text = ""
	_feedback_text = ""
	_is_correct = false
	_has_feedback = false
	_is_submitting = false
	_lifecycle_state = LifecycleState.FRESH
	_hint_visible = false
	_validation_warning_visible = false
	_feedback_visible = false

	if _feedback_label != null:
		_feedback_label.visible = false
		_feedback_label.text = ""
		_feedback_label.modulate.a = 0.0

	if _prompt_label != null:
		_prompt_label.text = ""
		_prompt_label.visible = false

	if _objective_label != null:
		_objective_label.text = ""
		_objective_label.visible = false

	if _submit_button != null:
		_update_submit_button_text()
		_submit_button.disabled = false

	if _hint_button != null:
		_hint_button.disabled = false

func setup_question(question_view: Dictionary) -> bool:
	clear_question()

	if not (question_view is Dictionary) or question_view.is_empty():
		return false

	# Must contain required presentation fields
	for field in ["question_id", "interaction_type", "prompt", "interaction_payload"]:
		if not question_view.has(field):
			return false

	var interaction_type: String = String(question_view["interaction_type"])
	if not ["multiple_choice", "drag_drop", "matching", "input"].has(interaction_type):
		return false

	var payload: Variant = question_view["interaction_payload"]
	if not (payload is Dictionary):
		return false

	# Never require or expose answer_spec from presentation view
	if question_view.has("answer_spec"):
		return false

	_question_view = question_view.duplicate(true)
	_prompt_text = sanitize_presentation_text(String(question_view["prompt"]))
	_objective_text = sanitize_presentation_text(String(question_view.get("learning_objective", "")))

	# Create interaction view child according to interaction_type
	match interaction_type:
		"multiple_choice":
			var mc_view: MultipleChoiceView = MultipleChoiceView.new()
			if not _combat_action_text.is_empty():
				mc_view.set_combat_grid_mode(true)
			if not mc_view.setup(payload as Dictionary):
				return false
			_active_interaction_view = mc_view
		"input":
			var inp_view: InputView = InputView.new()
			if not inp_view.setup(payload as Dictionary):
				return false
			_active_interaction_view = inp_view
		"drag_drop":
			var dd_view: DragDropView = DragDropView.new()
			if not dd_view.setup(payload as Dictionary):
				return false
			_active_interaction_view = dd_view
		"matching":
			var mat_view: MatchingView = MatchingView.new()
			if not mat_view.setup(payload as Dictionary):
				return false
			_active_interaction_view = mat_view

	_ensure_ui_built()

	if _submit_button != null:
		_update_submit_button_text()
		_submit_button.disabled = false

	if _active_interaction_view != null:
		if _active_interaction_view.get_parent() != null:
			_active_interaction_view.get_parent().remove_child(_active_interaction_view)
		var scroll_target: Control = get_interaction_scroll_container()
		if scroll_target != null:
			scroll_target.add_child(_active_interaction_view)
		elif _interaction_container != null:
			_interaction_container.add_child(_active_interaction_view)
		else:
			add_child(_active_interaction_view)

	if is_inside_tree():
		modulate.a = 0.0
		if _panel_tween != null and _panel_tween.is_running():
			_panel_tween.kill()
		_panel_tween = create_tween()
		if _panel_tween != null:
			_panel_tween.tween_property(self, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	return true

func get_current_interaction_payload() -> Dictionary:
	if _active_interaction_view == null:
		return {}
	if _active_interaction_view.has_method("get_interaction_payload"):
		return _active_interaction_view.call("get_interaction_payload") as Dictionary
	return {}

func get_interaction_scroll_container() -> ScrollContainer:
	if _interaction_container != null:
		var sc: ScrollContainer = _interaction_container.get_node_or_null("InteractionScrollContainer") as ScrollContainer
		if sc != null: return sc
	if _main_vbox != null:
		var sc2: ScrollContainer = _main_vbox.get_node_or_null("InteractionContainer/InteractionScrollContainer") as ScrollContainer
		if sc2 != null: return sc2
		var sc3: ScrollContainer = _main_vbox.get_node_or_null("InteractionScrollContainer") as ScrollContainer
		if sc3 != null: return sc3
	return get_node_or_null("MainVBox/InteractionContainer/InteractionScrollContainer") as ScrollContainer

func request_submit() -> void:
	var payload: Dictionary = get_current_interaction_payload()
	submit_requested.emit(payload)

func show_feedback(attempt_result: Dictionary) -> bool:
	if not (attempt_result is Dictionary) or not attempt_result.has("is_correct"):
		return false
	_is_correct = bool(attempt_result["is_correct"])
	if attempt_result.has("feedback_text"):
		_feedback_text = String(attempt_result["feedback_text"])
	elif attempt_result.has("player_facing_feedback"):
		_feedback_text = String(attempt_result["player_facing_feedback"])
	elif attempt_result.has("explanation"):
		_feedback_text = String(attempt_result["explanation"])
	else:
		_feedback_text = ""
	_has_feedback = true
	_feedback_visible = true
	_is_submitting = false
	_lifecycle_state = LifecycleState.EVALUATED_CORRECT if _is_correct else LifecycleState.EVALUATED_WRONG

	_ensure_ui_built()
	if _feedback_label != null:
		_feedback_label.theme_type_variation = &"MathosSuccess" if _is_correct else &"MathosError"
		var header_str: String = "Chính xác!" if _is_correct else "Chưa chính xác"
		var explanation_str: String = MathContentRenderer.render(String(attempt_result.get("explanation", "")))
		var clean_feedback_text: String = MathContentRenderer.render(_feedback_text)
		_feedback_label.text = "[%s] %s\n%s" % [header_str, clean_feedback_text, explanation_str]
		_feedback_label.modulate.a = 0.0
		_feedback_label.visible = true
		if _feedback_tween != null and _feedback_tween.is_running():
			_feedback_tween.kill()
		_feedback_tween = create_tween()
		if _feedback_tween != null:
			_feedback_tween.tween_property(_feedback_label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if _submit_button != null:
		_submit_button.text = "TIẾP TỤC" if _is_correct else "THỬ LẠI"
		_submit_button.disabled = false

	if _active_interaction_view != null and _active_interaction_view.has_method("show_feedback"):
		_active_interaction_view.call("show_feedback", attempt_result)

	return true

static func sanitize_presentation_text(text: String) -> String:
	if text.is_empty():
		return ""
	var regex := RegEx.new()
	regex.compile("\\s*q_d\\d+_\\d+_\\d+\\b|\\s*q_[a-zA-Z0-9_]+\\b")
	var cleaned: String = regex.sub(text, "", true).strip_edges()
	return MathContentRenderer.render(cleaned)

func get_prompt_text() -> String:
	return _prompt_text

func get_objective_text() -> String:
	return _objective_text

func get_feedback_text() -> String:
	return _feedback_text

func is_correct() -> bool:
	return _is_correct

func has_feedback() -> bool:
	return _has_feedback

func get_lifecycle_state() -> LifecycleState:
	return _lifecycle_state

func is_hint_visible() -> bool:
	return _hint_visible

func is_validation_warning_visible() -> bool:
	return _validation_warning_visible

func get_submit_button() -> Button:
	return _submit_button

func get_feedback_label() -> Label:
	return _feedback_label

func get_active_interaction_view() -> Control:
	return _active_interaction_view

func _update_labels() -> void:
	if _prompt_label != null:
		_prompt_label.text = _prompt_text
		_prompt_label.visible = not _prompt_text.is_empty()

	if _objective_label != null:
		_objective_label.text = _objective_text
		_objective_label.visible = not _objective_text.is_empty()

	if _feedback_label != null:
		_feedback_label.visible = _has_feedback
		if _has_feedback:
			_feedback_label.theme_type_variation = &"MathosSuccess" if _is_correct else &"MathosError"
			var header_str: String = "Chính xác!" if _is_correct else "Chưa chính xác"
			_feedback_label.text = "[%s] %s" % [header_str, _feedback_text]

func _on_submit_button_pressed() -> void:
	if _lifecycle_state == LifecycleState.EVALUATED_CORRECT:
		continue_requested.emit()
		return
	elif _lifecycle_state == LifecycleState.EVALUATED_WRONG:
		_lifecycle_state = LifecycleState.FRESH
		_has_feedback = false
		_feedback_visible = false
		_feedback_text = ""
		_is_submitting = false
		if _feedback_tween != null and _feedback_tween.is_running():
			_feedback_tween.kill()
			_feedback_tween = null
		if _feedback_label != null:
			_feedback_label.visible = false
			_feedback_label.text = ""
			_feedback_label.modulate.a = 0.0
		if _submit_button != null:
			_update_submit_button_text()
		if _active_interaction_view != null:
			if _active_interaction_view.has_method("reset_interaction"):
				_active_interaction_view.call("reset_interaction")
			elif _active_interaction_view.has_method("set_disabled"):
				_active_interaction_view.call("set_disabled", false)
		retry_requested.emit()
		return

	# In FRESH or VALIDATION_WARNING state
	if _is_submitting:
		return

	var payload: Dictionary = get_current_interaction_payload()
	if not is_payload_complete(payload):
		_lifecycle_state = LifecycleState.VALIDATION_WARNING
		_validation_warning_visible = true
		_has_feedback = true
		var itype: String = String(_question_view.get("interaction_type", ""))
		var uncompleted_msg: String = "Hãy hoàn tất tất cả các mục trước khi xác nhận."
		if itype == "multiple_choice":
			uncompleted_msg = "Vui lòng chọn một đáp án trước khi xác nhận."
		elif itype == "input":
			uncompleted_msg = "Vui lòng nhập câu trả lời trước khi xác nhận."
		elif itype == "matching":
			uncompleted_msg = "Vui lòng chọn ghép đôi cho tất cả các mục trước khi xác nhận."
		elif itype == "drag_drop":
			uncompleted_msg = "Hãy phân loại tất cả các mục trước khi xác nhận."

		_feedback_text = "⚠️ %s" % uncompleted_msg
		if _feedback_label != null:
			_feedback_label.theme_type_variation = &"MathosMeta"
			_feedback_label.text = _feedback_text
			_feedback_label.modulate.a = 0.0
			_feedback_label.visible = true
			if _feedback_tween != null and _feedback_tween.is_running():
				_feedback_tween.kill()
			_feedback_tween = create_tween()
			if _feedback_tween != null:
				_feedback_tween.tween_property(_feedback_label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		return

	# Valid payload submitted
	_is_submitting = true
	_validation_warning_visible = false
	if not _feedback_visible:
		_has_feedback = false
		if _feedback_label != null:
			_feedback_label.visible = false
	request_submit()

func is_payload_complete(payload: Dictionary) -> bool:
	var itype: String = String(_question_view.get("interaction_type", ""))
	match itype:
		"multiple_choice":
			return payload.has("selected_option_id") and not String(payload["selected_option_id"]).strip_edges().is_empty()
		"input":
			return payload.has("value") and payload["value"] != null and not str(payload["value"]).strip_edges().is_empty()
		"matching":
			return payload.has("pairs") and (payload["pairs"] is Array) and not (payload["pairs"] as Array).is_empty()
		"drag_drop":
			return payload.has("placements") and (payload["placements"] is Array) and not (payload["placements"] as Array).is_empty()
		_:
			return not payload.is_empty()

func _on_hint_button_pressed() -> void:
	if _lifecycle_state == LifecycleState.EVALUATED_CORRECT or _lifecycle_state == LifecycleState.EVALUATED_WRONG:
		return

	var hint: String = String(_question_view.get("hint", "")).strip_edges()
	if hint.is_empty():
		hint = String(_question_view.get("explanation", "")).strip_edges()
	hint = sanitize_presentation_text(hint)

	if hint.is_empty():
		hint = "Đọc kỹ các giả thiết và phân tích không gian mẫu hoặc các biến cố độc lập để chọn đáp án."

	_feedback_text = "💡 Gợi ý: %s" % hint
	_hint_visible = true
	_has_feedback = true
	_ensure_ui_built()

	if _feedback_label != null:
		_feedback_label.theme_type_variation = &"MathosMeta"
		_feedback_label.text = _feedback_text
		_feedback_label.modulate.a = 0.0
		_feedback_label.visible = true
		if _feedback_tween != null and _feedback_tween.is_running():
			_feedback_tween.kill()
		_feedback_tween = create_tween()
		if _feedback_tween != null:
			_feedback_tween.tween_property(_feedback_label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func on_submission_failed(error_info: Dictionary = {}) -> void:
	_is_submitting = false
	_validation_warning_visible = true
	_has_feedback = true
	_lifecycle_state = LifecycleState.VALIDATION_WARNING
	_ensure_ui_built()

	if _submit_button != null:
		_submit_button.disabled = false
		_update_submit_button_text()

	if _active_interaction_view != null and _active_interaction_view.has_method("set_disabled"):
		_active_interaction_view.call("set_disabled", false)

	var msg: String = String(error_info.get("error_message", "")).strip_edges()

	# Player-facing localized Vietnamese translation for internal validation keys
	var player_facing_msg: String = ""
	if msg.contains("must_place_all") or msg.contains("every item"):
		player_facing_msg = "Hãy phân loại tất cả các mục trước khi xác nhận."
	elif msg.contains("matching payload") or msg.contains("pairs"):
		player_facing_msg = "Vui lòng chọn ghép đôi cho tất cả các mục trước khi xác nhận."
	elif msg.contains("input payload") or msg.contains("value"):
		player_facing_msg = "Vui lòng nhập câu trả lời trước khi xác nhận."
	elif msg.contains("multiple_choice") or msg.contains("selected_option_id"):
		player_facing_msg = "Vui lòng chọn một đáp án trước khi xác nhận."
	elif not msg.is_empty() and not msg.contains("requires") and not msg.contains("definition"):
		player_facing_msg = sanitize_presentation_text(msg)
	else:
		player_facing_msg = "Hãy hoàn tất tất cả các mục trước khi xác nhận."

	_feedback_text = "⚠️ %s" % player_facing_msg

	if _feedback_label != null:
		_feedback_label.theme_type_variation = &"MathosMeta"
		_feedback_label.text = _feedback_text
		_feedback_label.modulate.a = 0.0
		_feedback_label.visible = true
		if _feedback_tween != null and _feedback_tween.is_running():
			_feedback_tween.kill()
		_feedback_tween = create_tween()
		if _feedback_tween != null:
			_feedback_tween.tween_property(_feedback_label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

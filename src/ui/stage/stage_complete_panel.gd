class_name StageCompletePanel
extends Control

## UI component displaying stage-complete presentation feedback
## matching MATHOS_MASTER_UI_STAGE_COMPLETE_V1 and emitting presentation intents.

signal stage_continue_requested()
signal review_requested()

func _ready() -> void:
	var cont_btn: Button = _get_continue_button()
	if cont_btn != null:
		if not cont_btn.pressed.is_connected(_on_continue_pressed):
			cont_btn.pressed.connect(_on_continue_pressed)

	var rev_btn: Button = _get_review_button()
	if rev_btn != null:
		if not rev_btn.pressed.is_connected(_on_review_pressed):
			rev_btn.pressed.connect(_on_review_pressed)

func set_summary_data(stage_title: String, message: String = "") -> void:
	var stage_name_label: Label = get_node_or_null("MarginContainer/VBoxContainer/StageNameLabel") as Label
	if stage_name_label != null:
		stage_name_label.text = stage_title if not stage_title.is_empty() else "Khởi Đầu Rừng Mù Sương"

	var summary_label: Label = _get_summary_label()
	if summary_label != null and not message.is_empty():
		summary_label.text = message
		summary_label.visible = true

func set_stage_complete_stats(question_count: int, accuracy_pct: float, learned_summary: String = "") -> void:
	var q_val: Label = get_node_or_null("MarginContainer/VBoxContainer/StatsHBox/QuestionCountPanel/VBox/Value") as Label
	var acc_val: Label = get_node_or_null("MarginContainer/VBoxContainer/StatsHBox/AccuracyPanel/VBox/Value") as Label
	var learned_body: Label = get_node_or_null("MarginContainer/VBoxContainer/LearnedPanel/LearnedVBox/Body") as Label

	if learned_body != null and not learned_summary.is_empty():
		learned_body.text = learned_summary

	if not is_inside_tree():
		if q_val != null:
			q_val.text = str(question_count)
		if acc_val != null:
			acc_val.text = "%d%%" % int(round(accuracy_pct))
		return

	# Animated count up
	var target_q: float = float(question_count)
	var target_acc: float = float(int(round(accuracy_pct)))

	var t: Tween = create_tween()
	if t != null:
		t.set_parallel(true)
		t.tween_method(Callable(self, "_update_q_count_text").bind(q_val), 0.0, target_q, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_method(Callable(self, "_update_acc_text").bind(acc_val), 0.0, target_acc, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fade in container
	var container: Control = get_node_or_null("MarginContainer/VBoxContainer") as Control
	if container == null:
		container = get_node_or_null("MarginContainer/PanelContainer/VBoxContainer") as Control
	if container != null:
		container.modulate.a = 0.0
		var t_fade: Tween = create_tween()
		if t_fade != null:
			t_fade.tween_property(container, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _update_q_count_text(val: float, label: Label) -> void:
	if label != null:
		label.text = str(int(round(val)))

func _update_acc_text(val: float, label: Label) -> void:
	if label != null:
		label.text = "%d%%" % int(round(val))

func _on_continue_pressed() -> void:
	stage_continue_requested.emit()

func _on_review_pressed() -> void:
	review_requested.emit()

func _get_title_label() -> Label:
	return get_node_or_null("MarginContainer/VBoxContainer/TitleLabel") as Label

func _get_summary_label() -> Label:
	return get_node_or_null("MarginContainer/VBoxContainer/SummaryLabel") as Label

func _get_continue_button() -> Button:
	var btn = get_node_or_null("MarginContainer/VBoxContainer/ActionHBox/ContinueButton")
	if btn == null:
		btn = get_node_or_null("MarginContainer/PanelContainer/VBoxContainer/ContinueButton")
	return btn as Button

func _get_review_button() -> Button:
	var btn = get_node_or_null("MarginContainer/VBoxContainer/ActionHBox/ReviewButton")
	return btn as Button

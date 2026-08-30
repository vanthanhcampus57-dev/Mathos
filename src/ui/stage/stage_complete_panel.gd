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
	if q_val != null:
		q_val.text = str(question_count)

	var acc_val: Label = get_node_or_null("MarginContainer/VBoxContainer/StatsHBox/AccuracyPanel/VBox/Value") as Label
	if acc_val != null:
		acc_val.text = "%d%%" % int(round(accuracy_pct))

	var learned_body: Label = get_node_or_null("MarginContainer/VBoxContainer/LearnedPanel/LearnedVBox/Body") as Label
	if learned_body != null and not learned_summary.is_empty():
		learned_body.text = learned_summary

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

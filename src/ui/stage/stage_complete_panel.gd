class_name StageCompletePanel
extends Control

## UI component displaying stage-complete presentation feedback
## and emitting presentation intents for stage continuation.

signal stage_continue_requested()

func _ready() -> void:
	var btn: Button = _get_continue_button()
	if btn != null:
		if not btn.pressed.is_connected(_on_continue_pressed):
			btn.pressed.connect(_on_continue_pressed)

func set_summary_data(stage_title: String, message: String = "") -> void:
	var title_label: Label = _get_title_label()
	var summary_label: Label = _get_summary_label()

	if title_label != null:
		title_label.text = "Stage Completed: %s" % stage_title if not stage_title.is_empty() else "Stage Completed!"
	if summary_label != null:
		summary_label.text = message if not message.is_empty() else "Great job! You have cleared this stage."

func _on_continue_pressed() -> void:
	stage_continue_requested.emit()

func _get_title_label() -> Label:
	return get_node_or_null("MarginContainer/PanelContainer/VBoxContainer/TitleLabel") as Label

func _get_summary_label() -> Label:
	return get_node_or_null("MarginContainer/PanelContainer/VBoxContainer/SummaryLabel") as Label

func _get_continue_button() -> Button:
	return get_node_or_null("MarginContainer/PanelContainer/VBoxContainer/ContinueButton") as Button

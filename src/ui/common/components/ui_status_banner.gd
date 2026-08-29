class_name UiStatusBanner
extends PanelContainer

## Shared status/feedback presentation shell.
## Domain-neutral banner displaying status messages using authoritative Mathos Theme variations.

enum StatusType {
	INFO,
	SUCCESS,
	ERROR,
	WARNING
}

@export var status_type: StatusType = StatusType.INFO:
	set(value):
		status_type = value
		_update_appearance()

@export var title_text: String = "Status Title":
	set(value):
		title_text = value
		_update_labels()

@export var message_text: String = "Status message details":
	set(value):
		message_text = value
		_update_labels()

@export var detail_text: String = "":
	set(value):
		detail_text = value
		_update_labels()

@onready var title_label: Label = get_node_or_null("MarginContainer/VBoxContainer/TitleLabel") as Label
@onready var message_label: Label = get_node_or_null("MarginContainer/VBoxContainer/MessageLabel") as Label
@onready var detail_label: Label = get_node_or_null("MarginContainer/VBoxContainer/DetailLabel") as Label

func _init() -> void:
	_update_appearance()

func _ready() -> void:
	_update_appearance()
	_update_labels()

func show_status(p_type: StatusType, title: String, message: String, detail: String = "") -> void:
	status_type = p_type
	title_text = title
	message_text = message
	detail_text = detail
	visible = true

func _update_labels() -> void:
	if title_label != null:
		title_label.text = title_text
	if message_label != null:
		message_label.text = message_text
	if detail_label != null:
		detail_label.text = detail_text
		detail_label.visible = not detail_text.is_empty()

func _update_appearance() -> void:
	match status_type:
		StatusType.SUCCESS:
			theme_type_variation = &"MathosPanelElevated"
			if title_label != null:
				title_label.theme_type_variation = &"MathosSuccess"
		StatusType.ERROR:
			theme_type_variation = &"MathosPanelElevated"
			if title_label != null:
				title_label.theme_type_variation = &"MathosError"
		StatusType.WARNING:
			theme_type_variation = &"MathosPanelSecondary"
			if title_label != null:
				title_label.theme_type_variation = &"MathosError"
		_:
			theme_type_variation = &"MathosPanelSecondary"
			if title_label != null:
				title_label.theme_type_variation = &"MathosSubtitle"

	if message_label != null:
		message_label.theme_type_variation = &"MathosBody"
	if detail_label != null:
		detail_label.theme_type_variation = &"MathosMeta"

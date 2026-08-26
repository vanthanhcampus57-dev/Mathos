class_name UiOptionCard
extends Button

## Shared option/card visual shell.
## Domain-neutral selectable card supporting normal, selected, correct, and incorrect states.

enum CardVisualState {
	NORMAL,
	SELECTED,
	CORRECT,
	INCORRECT
}

signal card_selected(selected: bool)

@export var title_text: String = "Option Title":
	set(value):
		title_text = value
		_update_labels()

@export var subtitle_text: String = "":
	set(value):
		subtitle_text = value
		_update_labels()

@export var is_card_selected: bool = false:
	set(value):
		is_card_selected = value
		if is_card_selected and card_state == CardVisualState.NORMAL:
			card_state = CardVisualState.SELECTED
		elif not is_card_selected and card_state == CardVisualState.SELECTED:
			card_state = CardVisualState.NORMAL
		_update_theme_variation()

var card_state: CardVisualState = CardVisualState.NORMAL:
	set(value):
		card_state = value
		is_card_selected = (card_state == CardVisualState.SELECTED)
		_update_theme_variation()

@onready var title_label: Label = get_node_or_null("MarginContainer/VBoxContainer/TitleLabel") as Label
@onready var subtitle_label: Label = get_node_or_null("MarginContainer/VBoxContainer/SubtitleLabel") as Label

func _init() -> void:
	_update_theme_variation()

func _ready() -> void:
	toggle_mode = true
	toggled.connect(_on_toggled)
	_update_labels()
	_update_theme_variation()

func set_card_state(state: CardVisualState) -> void:
	card_state = state

func set_selected(p_selected: bool) -> void:
	button_pressed = p_selected
	is_card_selected = p_selected

func set_feedback(is_correct: bool) -> void:
	card_state = CardVisualState.CORRECT if is_correct else CardVisualState.INCORRECT

func set_card_content(title: String, subtitle: String = "") -> void:
	title_text = title
	subtitle_text = subtitle

func _on_toggled(p_pressed: bool) -> void:
	is_card_selected = p_pressed
	card_selected.emit(is_card_selected)

func _update_labels() -> void:
	if title_label != null:
		title_label.text = title_text
	if subtitle_label != null:
		subtitle_label.text = subtitle_text
		subtitle_label.visible = not subtitle_text.is_empty()

func _update_theme_variation() -> void:
	match card_state:
		CardVisualState.SELECTED:
			theme_type_variation = &"OptionCardSelected"
		CardVisualState.CORRECT:
			theme_type_variation = &"OptionCardCorrect"
		CardVisualState.INCORRECT:
			theme_type_variation = &"OptionCardIncorrect"
		_:
			theme_type_variation = &"OptionCard"

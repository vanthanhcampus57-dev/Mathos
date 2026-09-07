class_name UiOptionCard
extends Button

## Shared option/card visual shell.
## Domain-neutral selectable card consuming authoritative "MathosOption" Theme variation and states.

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
	theme_type_variation = &"MathosOption"

func _ready() -> void:
	theme_type_variation = &"MathosOption"
	toggle_mode = true
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	clip_text = false
	if not toggled.is_connected(_on_toggled):
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
	theme_type_variation = &"MathosOption"
	var style_key: StringName = &"panel"
	match card_state:
		CardVisualState.SELECTED:
			style_key = &"selected"
		CardVisualState.CORRECT:
			style_key = &"correct"
		CardVisualState.INCORRECT:
			style_key = &"incorrect"
		_:
			style_key = &"panel"

	var sb: StyleBox = null
	if has_theme_stylebox(style_key, &"MathosOption"):
		sb = get_theme_stylebox(style_key, &"MathosOption")

	if sb == null:
		sb = _create_fallback_stylebox(card_state)

	if sb != null:
		add_theme_stylebox_override(&"normal", sb)
		add_theme_stylebox_override(&"pressed", sb)

		var hover_sb: StyleBox = _create_hover_stylebox(card_state, sb)
		add_theme_stylebox_override(&"hover", hover_sb)
		add_theme_stylebox_override(&"focus", hover_sb)

		var disabled_sb: StyleBox = _create_disabled_stylebox(card_state, sb)
		add_theme_stylebox_override(&"disabled", disabled_sb)

	_update_font_colors()

func _create_fallback_stylebox(state: CardVisualState) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10

	match state:
		CardVisualState.SELECTED:
			sb.bg_color = Color(0.08, 0.18, 0.32, 0.95)
			sb.border_color = Color(0.96, 0.77, 0.26, 0.95)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.shadow_color = Color(0.96, 0.77, 0.26, 0.25)
			sb.shadow_size = 6
		CardVisualState.CORRECT:
			sb.bg_color = Color(0.06, 0.22, 0.14, 0.95)
			sb.border_color = Color(0.25, 0.85, 0.45, 1.0)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.shadow_color = Color(0.25, 0.85, 0.45, 0.25)
			sb.shadow_size = 6
		CardVisualState.INCORRECT:
			sb.bg_color = Color(0.26, 0.08, 0.10, 0.95)
			sb.border_color = Color(0.92, 0.28, 0.32, 1.0)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.shadow_color = Color(0.92, 0.28, 0.32, 0.25)
			sb.shadow_size = 6
		_:
			sb.bg_color = Color(0.05, 0.09, 0.16, 0.88)
			sb.border_color = Color(0.18, 0.35, 0.52, 0.55)
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.shadow_color = Color(0.02, 0.05, 0.10, 0.30)
			sb.shadow_size = 3
	return sb

func _create_hover_stylebox(state: CardVisualState, base_sb: StyleBox) -> StyleBox:
	if not (base_sb is StyleBoxFlat):
		return base_sb
	var hsb: StyleBoxFlat = (base_sb as StyleBoxFlat).duplicate()
	match state:
		CardVisualState.SELECTED:
			hsb.bg_color = Color(0.10, 0.22, 0.38, 0.98)
			hsb.shadow_size = 8
		CardVisualState.CORRECT, CardVisualState.INCORRECT:
			pass
		_:
			hsb.bg_color = Color(0.08, 0.14, 0.24, 0.95)
			hsb.border_color = Color(0.30, 0.70, 0.95, 0.85)
			hsb.shadow_color = Color(0.10, 0.40, 0.70, 0.35)
			hsb.shadow_size = 5
	return hsb

func _create_disabled_stylebox(state: CardVisualState, base_sb: StyleBox) -> StyleBox:
	if not (base_sb is StyleBoxFlat):
		return base_sb
	var dsb: StyleBoxFlat = (base_sb as StyleBoxFlat).duplicate()
	if state == CardVisualState.NORMAL:
		dsb.bg_color = Color(0.04, 0.06, 0.10, 0.65)
		dsb.border_color = Color(0.12, 0.18, 0.25, 0.35)
		dsb.shadow_size = 0
	return dsb

func _update_font_colors() -> void:
	match card_state:
		CardVisualState.SELECTED:
			add_theme_color_override(&"font_color", Color(1.0, 0.94, 0.75, 1.0))
			add_theme_color_override(&"font_hover_color", Color(1.0, 0.96, 0.82, 1.0))
			add_theme_color_override(&"font_pressed_color", Color(1.0, 0.90, 0.65, 1.0))
		CardVisualState.CORRECT:
			add_theme_color_override(&"font_color", Color(0.85, 1.0, 0.88, 1.0))
			add_theme_color_override(&"font_disabled_color", Color(0.85, 1.0, 0.88, 1.0))
		CardVisualState.INCORRECT:
			add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.88, 1.0))
			add_theme_color_override(&"font_disabled_color", Color(1.0, 0.85, 0.88, 1.0))
		_:
			add_theme_color_override(&"font_color", Color(0.88, 0.92, 0.98, 1.0))
			add_theme_color_override(&"font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
			add_theme_color_override(&"font_pressed_color", Color(0.80, 0.88, 0.96, 1.0))
			add_theme_color_override(&"font_disabled_color", Color(0.50, 0.55, 0.62, 0.65))


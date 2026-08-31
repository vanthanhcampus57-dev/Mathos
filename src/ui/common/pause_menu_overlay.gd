class_name PauseMenuOverlay
extends Control

## Standalone Production Pause Menu Overlay for Mathos.
## Emits resume_requested, stage_map_requested, and main_menu_requested signals.
## Handles ESC / ui_cancel key toggling cleanly.

signal resume_requested
signal stage_map_requested
signal main_menu_requested

var _card_panel: PanelContainer = null
var _resume_button: Button = null
var _map_button: Button = null
var _menu_button: Button = null

func _init() -> void:
	visible = false

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false
	_build_ui()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	# Dark semi-transparent backdrop
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.02, 0.04, 0.08, 0.85)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	add_child(backdrop)

	# Center container
	var center: CenterContainer = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	# Card Panel
	_card_panel = PanelContainer.new()
	_card_panel.custom_minimum_size = Vector2(380, 320)
	_card_panel.theme_type_variation = &"MathosCard"
	center.add_child(_card_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_card_panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Title
	var title_lbl: Label = Label.new()
	title_lbl.text = "TẠM DỪNG GAME"
	title_lbl.theme_type_variation = &"MathosHeading"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var hs: HSeparator = HSeparator.new()
	vbox.add_child(hs)

	# Resume Button
	_resume_button = Button.new()
	_resume_button.text = "Tiếp tục"
	_resume_button.theme_type_variation = &"MathosPrimaryButton"
	_resume_button.custom_minimum_size = Vector2(0, 48)
	_resume_button.pressed.connect(func() -> void:
		hide_pause()
		resume_requested.emit()
	)
	vbox.add_child(_resume_button)

	# Stage Map Button
	_map_button = Button.new()
	_map_button.text = "Bản đồ hành trình"
	_map_button.theme_type_variation = &"MathosSecondaryButton"
	_map_button.custom_minimum_size = Vector2(0, 48)
	_map_button.pressed.connect(func() -> void:
		hide_pause()
		stage_map_requested.emit()
	)
	vbox.add_child(_map_button)

	# Main Menu Button
	_menu_button = Button.new()
	_menu_button.text = "Trở về trang chủ"
	_menu_button.theme_type_variation = &"MathosDestructiveButton"
	_menu_button.custom_minimum_size = Vector2(0, 48)
	_menu_button.pressed.connect(func() -> void:
		hide_pause()
		main_menu_requested.emit()
	)
	vbox.add_child(_menu_button)

func show_pause() -> void:
	visible = true

func hide_pause() -> void:
	visible = false

func toggle_pause() -> void:
	if visible:
		hide_pause()
		resume_requested.emit()
	else:
		show_pause()

func is_paused() -> bool:
	return visible

func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		toggle_pause()
		get_viewport().set_input_as_handled()

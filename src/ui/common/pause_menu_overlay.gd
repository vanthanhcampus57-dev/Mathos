class_name PauseMenuOverlay
extends Control

## Standalone Production Pause Menu Overlay for Mathos.
## Emits resume_requested, stage_map_requested, main_menu_requested, and logout_requested signals.
## Handles ESC / ui_cancel key toggling cleanly.
## Includes player-facing Logout / Exit action with confirmation modal and guest-mode awareness.

signal resume_requested
signal stage_map_requested
signal main_menu_requested
signal logout_requested

var _card_panel: PanelContainer = null
var _main_vbox: VBoxContainer = null
var _resume_button: Button = null
var _map_button: Button = null
var _menu_button: Button = null
var _logout_button: Button = null

# Confirmation sub-view
var _confirm_vbox: VBoxContainer = null
var _confirm_title_lbl: Label = null
var _confirm_prompt_lbl: Label = null
var _confirm_accept_button: Button = null
var _confirm_cancel_button: Button = null

var _is_guest: bool = false

func _init() -> void:
	visible = false

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false
	_ensure_ui_built()

func _ensure_ui_built() -> void:
	if _main_vbox != null and _logout_button != null:
		return
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
	_card_panel.custom_minimum_size = Vector2(400, 360)
	_card_panel.theme_type_variation = &"MathosCard"
	center.add_child(_card_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_card_panel.add_child(margin)

	# 1. Main Pause View
	_main_vbox = VBoxContainer.new()
	_main_vbox.name = "MainPauseVBox"
	_main_vbox.add_theme_constant_override("separation", 14)
	margin.add_child(_main_vbox)

	# Title
	var title_lbl: Label = Label.new()
	title_lbl.text = "TẠM DỪNG GAME"
	title_lbl.theme_type_variation = &"MathosHeading"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_vbox.add_child(title_lbl)

	var hs: HSeparator = HSeparator.new()
	_main_vbox.add_child(hs)

	# Resume Button
	_resume_button = Button.new()
	_resume_button.text = "Tiếp tục"
	_resume_button.theme_type_variation = &"MathosPrimaryButton"
	_resume_button.custom_minimum_size = Vector2(0, 46)
	_resume_button.pressed.connect(func() -> void:
		hide_pause()
		resume_requested.emit()
	)
	_main_vbox.add_child(_resume_button)

	# Stage Map Button
	_map_button = Button.new()
	_map_button.text = "Bản đồ hành trình"
	_map_button.theme_type_variation = &"MathosSecondaryButton"
	_map_button.custom_minimum_size = Vector2(0, 46)
	_map_button.pressed.connect(func() -> void:
		hide_pause()
		stage_map_requested.emit()
	)
	_main_vbox.add_child(_map_button)

	# Main Menu Button
	_menu_button = Button.new()
	_menu_button.text = "Trở về trang chủ"
	_menu_button.theme_type_variation = &"MathosSecondaryButton"
	_menu_button.custom_minimum_size = Vector2(0, 46)
	_menu_button.pressed.connect(func() -> void:
		hide_pause()
		main_menu_requested.emit()
	)
	_main_vbox.add_child(_menu_button)

	# Logout Button
	_logout_button = Button.new()
	_logout_button.name = "LogoutButton"
	_logout_button.text = "ĐĂNG XUẤT"
	_logout_button.theme_type_variation = &"MathosDestructiveButton"
	_logout_button.custom_minimum_size = Vector2(0, 46)
	_logout_button.pressed.connect(_on_logout_pressed)
	_main_vbox.add_child(_logout_button)

	# 2. Confirmation View
	_confirm_vbox = VBoxContainer.new()
	_confirm_vbox.name = "LogoutConfirmVBox"
	_confirm_vbox.add_theme_constant_override("separation", 16)
	_confirm_vbox.visible = false
	margin.add_child(_confirm_vbox)

	_confirm_title_lbl = Label.new()
	_confirm_title_lbl.name = "ConfirmTitleLabel"
	_confirm_title_lbl.text = "XÁC NHẬN ĐĂNG XUẤT"
	_confirm_title_lbl.theme_type_variation = &"MathosHeading"
	_confirm_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_vbox.add_child(_confirm_title_lbl)

	var confirm_hs: HSeparator = HSeparator.new()
	_confirm_vbox.add_child(confirm_hs)

	_confirm_prompt_lbl = Label.new()
	_confirm_prompt_lbl.name = "ConfirmPromptLabel"
	_confirm_prompt_lbl.text = "Bạn có chắc chắn muốn đăng xuất không?\nTiến trình chưa lưu có thể bị mất."
	_confirm_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_prompt_lbl.custom_minimum_size = Vector2(340, 40)
	_confirm_prompt_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_prompt_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_vbox.add_child(_confirm_prompt_lbl)

	var btn_hbox: HBoxContainer = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 12)
	_confirm_vbox.add_child(btn_hbox)

	_confirm_cancel_button = Button.new()
	_confirm_cancel_button.name = "ConfirmCancelButton"
	_confirm_cancel_button.text = "HỦY"
	_confirm_cancel_button.theme_type_variation = &"MathosSecondaryButton"
	_confirm_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_cancel_button.custom_minimum_size = Vector2(0, 46)
	_confirm_cancel_button.pressed.connect(_on_confirm_cancel_pressed)
	btn_hbox.add_child(_confirm_cancel_button)

	_confirm_accept_button = Button.new()
	_confirm_accept_button.name = "ConfirmAcceptButton"
	_confirm_accept_button.text = "XÁC NHẬN"
	_confirm_accept_button.theme_type_variation = &"MathosDestructiveButton"
	_confirm_accept_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_accept_button.custom_minimum_size = Vector2(0, 46)
	_confirm_accept_button.pressed.connect(_on_confirm_accept_pressed)
	btn_hbox.add_child(_confirm_accept_button)

	_update_labels()

func _on_logout_pressed() -> void:
	if _main_vbox != null:
		_main_vbox.visible = false
	if _confirm_vbox != null:
		_confirm_vbox.visible = true

func _on_confirm_cancel_pressed() -> void:
	if _confirm_vbox != null:
		_confirm_vbox.visible = false
	if _main_vbox != null:
		_main_vbox.visible = true

func _on_confirm_accept_pressed() -> void:
	hide_pause()
	if _confirm_vbox != null:
		_confirm_vbox.visible = false
	if _main_vbox != null:
		_main_vbox.visible = true
	logout_requested.emit()

func set_guest_mode(guest: bool) -> void:
	_is_guest = guest
	_ensure_ui_built()
	_update_labels()

func is_guest_mode() -> bool:
	return _is_guest

func _update_labels() -> void:
	if _logout_button != null:
		_logout_button.text = "THOÁT VỀ ĐĂNG NHẬP" if _is_guest else "ĐĂNG XUẤT"
	if _confirm_title_lbl != null:
		_confirm_title_lbl.text = "XÁC NHẬN THOÁT" if _is_guest else "XÁC NHẬN ĐĂNG XUẤT"
	if _confirm_prompt_lbl != null:
		_confirm_prompt_lbl.text = "Bạn có chắc muốn quay về màn hình đăng nhập?" if _is_guest else "Bạn có chắc chắn muốn đăng xuất không?\nTiến trình chưa lưu có thể bị mất."

func show_pause() -> void:
	_ensure_ui_built()
	if _confirm_vbox != null:
		_confirm_vbox.visible = false
	if _main_vbox != null:
		_main_vbox.visible = true
	_update_labels()
	visible = true

func hide_pause() -> void:
	visible = false
	if _confirm_vbox != null:
		_confirm_vbox.visible = false
	if _main_vbox != null:
		_main_vbox.visible = true

func toggle_pause() -> void:
	if visible:
		hide_pause()
		resume_requested.emit()
	else:
		show_pause()

func show_overlay() -> void:
	show_pause()

func hide_overlay() -> void:
	hide_pause()

func toggle_overlay() -> void:
	toggle_pause()

func is_paused() -> bool:
	return visible

func get_logout_button() -> Button:
	_ensure_ui_built()
	return _logout_button

func get_confirm_accept_button() -> Button:
	_ensure_ui_built()
	return _confirm_accept_button

func get_confirm_cancel_button() -> Button:
	_ensure_ui_built()
	return _confirm_cancel_button

func is_confirmation_visible() -> bool:
	_ensure_ui_built()
	return _confirm_vbox != null and _confirm_vbox.visible

func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		toggle_pause()
		get_viewport().set_input_as_handled()

class_name BossCombatPanel
extends PanelContainer

## Production Boss Combat Panel for Stage 1.5 (Boss STOCHAS).
## Renders Boss HP, Intent telegraph, real approved STOCHAS sprite, Player HP/Shield,
## Card Selection Bar, Combat Log, and Defeat/Retry overlay.

signal card_selected(card_id: String)
signal retry_pressed()
signal victory_acknowledged()

const STOCHAS_TEXTURE_PATH: String = "res://assets/characters/bosses/dungeon_1/stochas_boss.png"
const BOSS_VISUAL_CONTAINER_HEIGHT: float = 180.0
const SAFE_MARGIN_PERCENT: float = 0.10 # 10% safe visual margin (8–12% requirement)

var _combat_controller: CardCombatController = null

# UI Controls
var _boss_name_label: Label = null
var _boss_hp_bar: ProgressBar = null
var _boss_hp_label: Label = null
var _boss_intent_label: Label = null
var _boss_visual_rect: PanelContainer = null
var _boss_sprite_rect: TextureRect = null

var _player_hp_bar: ProgressBar = null
var _player_hp_label: Label = null
var _player_shield_label: Label = null

var _cards_header_label: Label = null
var _cards_container: HBoxContainer = null
var _card_buttons: Array[Button] = []

var _combat_log_label: Label = null
var _defeat_overlay: PanelContainer = null
var _defeat_retry_button: Button = null
var _victory_overlay: PanelContainer = null

func _ready() -> void:
	_ensure_ui()

func get_controller() -> CardCombatController:
	return _combat_controller

func set_controller(controller: CardCombatController) -> void:
	if _combat_controller == controller:
		return
	if _combat_controller != null:
		_disconnect_controller()
	_combat_controller = controller
	if _combat_controller != null:
		_connect_controller()
		_update_full_display()

func _disconnect_controller() -> void:
	if _combat_controller == null:
		return
	if _combat_controller.combat_state_changed.is_connected(_update_full_display):
		_combat_controller.combat_state_changed.disconnect(_update_full_display)
	if _combat_controller.combat_log_emitted.is_connected(_on_combat_log):
		_combat_controller.combat_log_emitted.disconnect(_on_combat_log)
	if _combat_controller.boss_defeated.is_connected(_on_boss_defeated):
		_combat_controller.boss_defeated.disconnect(_on_boss_defeated)
	if _combat_controller.player_defeated.is_connected(_on_player_defeated):
		_combat_controller.player_defeated.disconnect(_on_player_defeated)
	if _combat_controller.combat_reset.is_connected(_on_combat_reset):
		_combat_controller.combat_reset.disconnect(_on_combat_reset)

func _connect_controller() -> void:
	if _combat_controller == null:
		return
	if not _combat_controller.combat_state_changed.is_connected(_update_full_display):
		_combat_controller.combat_state_changed.connect(_update_full_display)
	if not _combat_controller.combat_log_emitted.is_connected(_on_combat_log):
		_combat_controller.combat_log_emitted.connect(_on_combat_log)
	if not _combat_controller.boss_defeated.is_connected(_on_boss_defeated):
		_combat_controller.boss_defeated.connect(_on_boss_defeated)
	if not _combat_controller.player_defeated.is_connected(_on_player_defeated):
		_combat_controller.player_defeated.connect(_on_player_defeated)
	if not _combat_controller.combat_reset.is_connected(_on_combat_reset):
		_combat_controller.combat_reset.connect(_on_combat_reset)

func _ensure_ui() -> void:
	if _boss_name_label != null:
		return

	custom_minimum_size = Vector2(280, 0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Main Panel Styling
	var main_style: StyleBoxFlat = StyleBoxFlat.new()
	main_style.bg_color = Color(0.08, 0.07, 0.14, 0.92)
	main_style.border_width_left = 2
	main_style.border_width_top = 2
	main_style.border_width_right = 2
	main_style.border_width_bottom = 2
	main_style.border_color = Color(0.6, 0.3, 0.8, 0.6)
	main_style.corner_radius_top_left = 12
	main_style.corner_radius_top_right = 12
	main_style.corner_radius_bottom_right = 12
	main_style.corner_radius_bottom_left = 12
	add_theme_stylebox_override("panel", main_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# 1. BOSS HEADER & VISUAL PLACEHOLDER
	var boss_section: VBoxContainer = VBoxContainer.new()
	boss_section.add_theme_constant_override("separation", 6)
	vbox.add_child(boss_section)

	var title_box: HBoxContainer = HBoxContainer.new()
	boss_section.add_child(title_box)

	_boss_name_label = Label.new()
	_boss_name_label.text = "BOSS: STOCHAS"
	_boss_name_label.add_theme_font_size_override("font_size", 16)
	_boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.8, 1.0))
	title_box.add_child(_boss_name_label)

	var role_tag: Label = Label.new()
	role_tag.text = " [THỦ LĨNH BIẾN CỐ]"
	role_tag.add_theme_font_size_override("font_size", 12)
	role_tag.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0, 0.8))
	title_box.add_child(role_tag)

	# Boss Visual Container (Real Approved STOCHAS Sprite)
	_boss_visual_rect = PanelContainer.new()
	_boss_visual_rect.name = "BossVisualContainer"
	_boss_visual_rect.custom_minimum_size = Vector2(0, BOSS_VISUAL_CONTAINER_HEIGHT)
	_boss_visual_rect.clip_contents = true
	var boss_vbox_style: StyleBoxFlat = StyleBoxFlat.new()
	boss_vbox_style.bg_color = Color(0.10, 0.07, 0.18, 0.88)
	boss_vbox_style.border_width_left = 1
	boss_vbox_style.border_width_top = 1
	boss_vbox_style.border_width_right = 1
	boss_vbox_style.border_width_bottom = 1
	boss_vbox_style.border_color = Color(0.3, 0.7, 0.9, 0.5)
	boss_vbox_style.corner_radius_top_left = 8
	boss_vbox_style.corner_radius_top_right = 8
	boss_vbox_style.corner_radius_bottom_right = 8
	boss_vbox_style.corner_radius_bottom_left = 8
	_boss_visual_rect.add_theme_stylebox_override("panel", boss_vbox_style)
	boss_section.add_child(_boss_visual_rect)

	# Safe Margin Container: 8–12% margin ensures staff, hood, runes, robe, probability shapes do not clip
	var sprite_margin: MarginContainer = MarginContainer.new()
	sprite_margin.name = "SpriteMarginContainer"
	var margin_px: int = int(round(BOSS_VISUAL_CONTAINER_HEIGHT * SAFE_MARGIN_PERCENT)) # 18px = 10%
	sprite_margin.add_theme_constant_override("margin_left", margin_px)
	sprite_margin.add_theme_constant_override("margin_top", margin_px)
	sprite_margin.add_theme_constant_override("margin_right", margin_px)
	sprite_margin.add_theme_constant_override("margin_bottom", margin_px)
	sprite_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sprite_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_boss_visual_rect.add_child(sprite_margin)

	_boss_sprite_rect = TextureRect.new()
	_boss_sprite_rect.name = "BossSpriteRect"
	_boss_sprite_rect.texture = _load_boss_texture()
	_boss_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_boss_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_boss_sprite_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_boss_sprite_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_sprite_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_boss_sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_margin.add_child(_boss_sprite_rect)

	# Boss HP Bar
	var hp_box: HBoxContainer = HBoxContainer.new()
	boss_section.add_child(hp_box)

	var hp_tag: Label = Label.new()
	hp_tag.text = "Máu Boss:"
	hp_tag.add_theme_font_size_override("font_size", 12)
	hp_box.add_child(hp_tag)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.custom_minimum_size = Vector2(0, 18)
	_boss_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_hp_bar.max_value = 100
	_boss_hp_bar.value = 100
	_boss_hp_bar.show_percentage = false
	var hp_fill: StyleBoxFlat = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.85, 0.15, 0.4, 0.9)
	hp_fill.corner_radius_top_left = 4
	hp_fill.corner_radius_top_right = 4
	hp_fill.corner_radius_bottom_right = 4
	hp_fill.corner_radius_bottom_left = 4
	_boss_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_box.add_child(_boss_hp_bar)

	_boss_hp_label = Label.new()
	_boss_hp_label.text = "100 / 100"
	_boss_hp_label.add_theme_font_size_override("font_size", 12)
	hp_box.add_child(_boss_hp_label)

	# Boss Intent
	_boss_intent_label = Label.new()
	_boss_intent_label.text = "⚡ Ý định: Ma Thuật Ngẫu Nhiên (10 ST)"
	_boss_intent_label.add_theme_font_size_override("font_size", 12)
	_boss_intent_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
	boss_section.add_child(_boss_intent_label)

	var sep1: HSeparator = HSeparator.new()
	vbox.add_child(sep1)

	# 2. PLAYER STATUS
	var player_section: VBoxContainer = VBoxContainer.new()
	player_section.add_theme_constant_override("separation", 4)
	vbox.add_child(player_section)

	var p_title_box: HBoxContainer = HBoxContainer.new()
	player_section.add_child(p_title_box)

	var p_title: Label = Label.new()
	p_title.text = "CHIẾN BINH MATHOS"
	p_title.add_theme_font_size_override("font_size", 13)
	p_title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1.0))
	p_title_box.add_child(p_title)

	_player_shield_label = Label.new()
	_player_shield_label.text = "  🛡️ Giáp: 0"
	_player_shield_label.add_theme_font_size_override("font_size", 12)
	_player_shield_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
	p_title_box.add_child(_player_shield_label)

	var p_hp_box: HBoxContainer = HBoxContainer.new()
	player_section.add_child(p_hp_box)

	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.custom_minimum_size = Vector2(0, 16)
	_player_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_hp_bar.max_value = 100
	_player_hp_bar.value = 100
	_player_hp_bar.show_percentage = false
	var php_fill: StyleBoxFlat = StyleBoxFlat.new()
	php_fill.bg_color = Color(0.2, 0.75, 0.3, 0.9)
	php_fill.corner_radius_top_left = 4
	php_fill.corner_radius_top_right = 4
	php_fill.corner_radius_bottom_right = 4
	php_fill.corner_radius_bottom_left = 4
	_player_hp_bar.add_theme_stylebox_override("fill", php_fill)
	p_hp_box.add_child(_player_hp_bar)

	_player_hp_label = Label.new()
	_player_hp_label.text = "100 / 100"
	_player_hp_label.add_theme_font_size_override("font_size", 12)
	p_hp_box.add_child(_player_hp_label)

	var sep2: HSeparator = HSeparator.new()
	vbox.add_child(sep2)

	# 3. ACTION CARDS BAR
	_cards_header_label = Label.new()
	_cards_header_label.text = "THẺ BÀI CHIẾN THUẬT (Chọn 1 thẻ trước khi giải đố):"
	_cards_header_label.add_theme_font_size_override("font_size", 11)
	_cards_header_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 0.9))
	vbox.add_child(_cards_header_label)

	_cards_container = HBoxContainer.new()
	_cards_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_cards_container)

	# 4. COMBAT ACTION LOG
	_combat_log_label = Label.new()
	_combat_log_label.text = "⚔️ Chọn thẻ bài và trả lời chính xác để tấn công Boss!"
	_combat_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_combat_log_label.add_theme_font_size_override("font_size", 12)
	_combat_log_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
	vbox.add_child(_combat_log_label)

	# 5. DEFEAT OVERLAY (Hidden by default)
	_defeat_overlay = PanelContainer.new()
	_defeat_overlay.visible = false
	var def_style: StyleBoxFlat = StyleBoxFlat.new()
	def_style.bg_color = Color(0.2, 0.05, 0.05, 0.95)
	def_style.border_width_left = 2
	def_style.border_width_top = 2
	def_style.border_width_right = 2
	def_style.border_width_bottom = 2
	def_style.border_color = Color(1.0, 0.2, 0.2, 0.8)
	def_style.corner_radius_top_left = 8
	def_style.corner_radius_top_right = 8
	def_style.corner_radius_bottom_right = 8
	def_style.corner_radius_bottom_left = 8
	_defeat_overlay.add_theme_stylebox_override("panel", def_style)
	vbox.add_child(_defeat_overlay)

	var def_vbox: VBoxContainer = VBoxContainer.new()
	def_vbox.add_theme_constant_override("separation", 8)
	_defeat_overlay.add_child(def_vbox)

	var def_title: Label = Label.new()
	def_title.text = "💀 BỊ ĐÁNH BẠI!"
	def_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_title.add_theme_font_size_override("font_size", 16)
	def_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	def_vbox.add_child(def_title)

	var def_msg: Label = Label.new()
	def_msg.text = "STOCHAS đã đánh gục bạn. Hãy kiên trì thử lại!"
	def_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_msg.add_theme_font_size_override("font_size", 12)
	def_vbox.add_child(def_msg)

	_defeat_retry_button = Button.new()
	_defeat_retry_button.text = "🔄 Thử Lại Quyết Chiến"
	_defeat_retry_button.custom_minimum_size = Vector2(0, 36)
	_defeat_retry_button.pressed.connect(_on_retry_pressed)
	def_vbox.add_child(_defeat_retry_button)

	# 6. VICTORY OVERLAY (Hidden by default)
	_victory_overlay = PanelContainer.new()
	_victory_overlay.visible = false
	var vic_style: StyleBoxFlat = StyleBoxFlat.new()
	vic_style.bg_color = Color(0.05, 0.2, 0.1, 0.95)
	vic_style.border_width_left = 2
	vic_style.border_width_top = 2
	vic_style.border_width_right = 2
	vic_style.border_width_bottom = 2
	vic_style.border_color = Color(0.3, 1.0, 0.4, 0.8)
	vic_style.corner_radius_top_left = 8
	vic_style.corner_radius_top_right = 8
	vic_style.corner_radius_bottom_right = 8
	vic_style.corner_radius_bottom_left = 8
	_victory_overlay.add_theme_stylebox_override("panel", vic_style)
	vbox.add_child(_victory_overlay)

	var vic_vbox: VBoxContainer = VBoxContainer.new()
	vic_vbox.add_theme_constant_override("separation", 8)
	_victory_overlay.add_child(vic_vbox)

	var vic_title: Label = Label.new()
	vic_title.text = "🏆 CHIẾN THẮNG!"
	vic_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_title.add_theme_font_size_override("font_size", 16)
	vic_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1.0))
	vic_vbox.add_child(vic_title)

	var vic_msg: Label = Label.new()
	vic_msg.text = "Bạn đã đánh bại Boss STOCHAS thành công!"
	vic_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_msg.add_theme_font_size_override("font_size", 12)
	vic_vbox.add_child(vic_msg)

func _update_full_display() -> void:
	_ensure_ui()
	if _combat_controller == null:
		return

	# Update Boss Status
	var boss: EnemyEntity = _combat_controller.boss_entity
	if boss != null:
		_boss_name_label.text = "BOSS: %s" % boss.display_name
		_boss_hp_bar.max_value = boss.max_hp
		_boss_hp_bar.value = boss.current_hp
		_boss_hp_label.text = "%d / %d" % [boss.current_hp, boss.max_hp]

		var intent: Dictionary = boss.get_current_intent()
		if not intent.is_empty():
			var telegraph: String = String(intent.get("telegraph_text", "Chuẩn bị tấn công!"))
			_boss_intent_label.text = "⚡ Ý định: %s" % telegraph
		else:
			_boss_intent_label.text = "⚡ Đang quan sát..."

	# Update Player Status
	var player: PlayerRuntime = _combat_controller.player_runtime
	if player != null:
		_player_hp_bar.max_value = player.max_hp
		_player_hp_bar.value = player.current_hp
		_player_hp_label.text = "%d / %d" % [player.current_hp, player.max_hp]
		_player_shield_label.text = "  🛡️ Giáp: %d" % player.shield

	# Update Card Buttons
	_render_cards()

func _render_cards() -> void:
	if _cards_container == null:
		return

	var in_active_combat: bool = (_combat_controller != null and _combat_controller.is_in_combat and _combat_controller.boss_entity != null and not _combat_controller.boss_entity.is_defeated and _combat_controller.player_runtime != null and not _combat_controller.player_runtime.is_defeated)
	_cards_container.visible = in_active_combat
	if _cards_header_label != null:
		_cards_header_label.visible = in_active_combat

	if not in_active_combat or _combat_controller == null:
		return

	# Rebuild card buttons if needed
	var cards: Array[CardModel] = _combat_controller.hand_cards
	var active_card: CardModel = _combat_controller.get_selected_card()

	# Clear existing children
	for child in _cards_container.get_children():
		child.queue_free()
	_card_buttons.clear()

	for card in cards:
		var btn: Button = Button.new()
		btn.text = "%s %s\n%s" % [card.get_icon(), card.name, card.get_summary_text()]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

		var is_selected: bool = (active_card != null and active_card.card_id == card.card_id)
		if is_selected:
			var sel_style: StyleBoxFlat = StyleBoxFlat.new()
			sel_style.bg_color = Color(0.2, 0.4, 0.8, 0.9)
			sel_style.border_width_left = 2
			sel_style.border_width_top = 2
			sel_style.border_width_right = 2
			sel_style.border_width_bottom = 2
			sel_style.border_color = Color(1.0, 0.9, 0.3, 1.0)
			sel_style.corner_radius_top_left = 6
			sel_style.corner_radius_top_right = 6
			sel_style.corner_radius_bottom_right = 6
			sel_style.corner_radius_bottom_left = 6
			btn.add_theme_stylebox_override("normal", sel_style)
			btn.add_theme_stylebox_override("hover", sel_style)

		var c_id: String = card.card_id
		btn.pressed.connect(func(): _on_card_button_pressed(c_id))
		_cards_container.add_child(btn)
		_card_buttons.append(btn)

func _on_card_button_pressed(card_id: String) -> void:
	if _combat_controller != null and _combat_controller.is_in_combat:
		_combat_controller.select_card(card_id)
		card_selected.emit(card_id)

func _on_combat_log(message: String, type: String) -> void:
	_ensure_ui()
	if _combat_log_label != null:
		_combat_log_label.text = message
		match type:
			"player_success":
				_combat_log_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1.0))
			"player_fail", "boss_attack":
				_combat_log_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
			"victory":
				_combat_log_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
			"defeat":
				_combat_log_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			_:
				_combat_log_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))

func _on_boss_defeated() -> void:
	_ensure_ui()
	if _victory_overlay != null:
		_victory_overlay.visible = true
	_render_cards()
	victory_acknowledged.emit()

func _on_player_defeated() -> void:
	_ensure_ui()
	if _defeat_overlay != null:
		_defeat_overlay.visible = true
	_render_cards()

func _on_combat_reset() -> void:
	_ensure_ui()
	if _defeat_overlay != null:
		_defeat_overlay.visible = false
	if _victory_overlay != null:
		_victory_overlay.visible = false
	_update_full_display()

func _on_retry_pressed() -> void:
	retry_pressed.emit()

func get_boss_sprite_rect() -> TextureRect:
	_ensure_ui()
	return _boss_sprite_rect

func get_boss_texture() -> Texture2D:
	_ensure_ui()
	return _boss_sprite_rect.texture if _boss_sprite_rect != null else null

func _load_boss_texture() -> Texture2D:
	return load_boss_sprite()

static func load_boss_sprite() -> Texture2D:
	var path: String = STOCHAS_TEXTURE_PATH
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			return res as Texture2D

	var global_path: String = ProjectSettings.globalize_path(path)
	var img: Image = Image.new()
	if img.load(global_path) == OK or img.load(path) == OK:
		return ImageTexture.create_from_image(img)

	if FileAccess.file_exists(path) or FileAccess.file_exists(global_path):
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		if bytes.is_empty():
			bytes = FileAccess.get_file_as_bytes(global_path)
		if not bytes.is_empty():
			var img_buf: Image = Image.new()
			if img_buf.load_png_from_buffer(bytes) == OK:
				return ImageTexture.create_from_image(img_buf)

	return null

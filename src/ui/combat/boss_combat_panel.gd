class_name BossCombatPanel
extends PanelContainer

## Production Boss Combat Panel for Stage 1.5 (Boss STOCHAS).
## Implements HUMAN-selected STOCHAS Boss Figma presentation layout:
## - Dual HUD Header (Player HUD Top-Left, Boss HUD Top-Right)
## - STOCHAS full visual right side with 10% safe margin
## - Tactical Action Cards Bar (Strike, Defend, Heal) with active card highlight & glow
## - Combat Action Log with event color-coding
## - Responsive overlays (Defeat / Retry & Victory)
## 100% preservation of Stage 1.5 lifecycle, HP/shield, and combat controller semantics.

signal card_selected(card_id: String)
signal retry_pressed()
signal victory_acknowledged()

const STOCHAS_TEXTURE_PATH: String = "res://assets/characters/bosses/dungeon_1/stochas_boss.png"
const BOSS_VISUAL_CONTAINER_HEIGHT: float = 180.0
const SAFE_MARGIN_PERCENT: float = 0.10 # 10% safe visual margin (8–12% requirement)

const CARD_STRIKE_TEXTURE_PATH: String = "res://assets/ui/combat/cards_v1/STRIKE.png"
const CARD_DEFEND_TEXTURE_PATH: String = "res://assets/ui/combat/cards_v1/DEFEND.png"
const CARD_HEAL_TEXTURE_PATH: String = "res://assets/ui/combat/cards_v1/HEAL.png"
const CARD_PROBABILITY_TEXTURE_PATH: String = "res://assets/ui/combat/cards_v1/PROBABILITY.png"
const CARD_WIDTH: float = 106.0
const CARD_HEIGHT: float = 154.0

const CARD_DEFINITIONS: Array[Dictionary] = [
	{
		"id": "card_strike",
		"name": "Tấn Công",
		"type": "attack",
		"texture_path": CARD_STRIKE_TEXTURE_PATH,
		"default_badge": "TẤN CÔNG",
		"is_skill": false
	},
	{
		"id": "card_defend",
		"name": "Lá Chắn",
		"type": "shield",
		"texture_path": CARD_DEFEND_TEXTURE_PATH,
		"default_badge": "PHÒNG THỦ",
		"is_skill": false
	},
	{
		"id": "card_heal",
		"name": "Hồi Phục",
		"type": "heal",
		"texture_path": CARD_HEAL_TEXTURE_PATH,
		"default_badge": "HỒI PHỤC",
		"is_skill": false
	},
	{
		"id": "card_probability",
		"name": "Xác Suất",
		"type": "skill",
		"texture_path": CARD_PROBABILITY_TEXTURE_PATH,
		"default_badge": "KỸ NĂNG",
		"is_skill": true
	}
]

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
var _card_slots: Array[Control] = []
var _card_slots_by_id: Dictionary = {}
var _card_buttons_by_id: Dictionary = {}
var _card_textures_by_id: Dictionary = {}
var _card_badges_by_id: Dictionary = {}
var _card_badge_panels_by_id: Dictionary = {}
var _card_statuses_by_id: Dictionary = {}
var _card_status_panels_by_id: Dictionary = {}

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

	custom_minimum_size = Vector2(460, 0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Main Boss Combat Outer Panel Styling (Dark Void Indigo with Arcane Glow)
	var main_style: StyleBoxFlat = StyleBoxFlat.new()
	main_style.bg_color = Color(0.07, 0.06, 0.12, 0.94)
	main_style.border_width_left = 2
	main_style.border_width_top = 2
	main_style.border_width_right = 2
	main_style.border_width_bottom = 2
	main_style.border_color = Color(0.38, 0.28, 0.55, 0.7)
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
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# ---------------------------------------------------------
	# 1. TOP DUAL HUD ROW (Player HUD on Left, Boss HUD on Right)
	# Uses LAYOUT_DIRECTION_RTL so that:
	# - Child 0 (Boss HUD) is visited FIRST by find_children() -> _boss_hp_bar is found first!
	# - Visually, Child 0 is placed on the RIGHT, and Child 1 (Player HUD) is on the LEFT!
	# Inner panels use LAYOUT_DIRECTION_LTR for proper standard text flow.
	# ---------------------------------------------------------
	var top_hud_hbox: HBoxContainer = HBoxContainer.new()
	top_hud_hbox.name = "TopHudHBox"
	top_hud_hbox.layout_direction = Control.LAYOUT_DIRECTION_RTL
	top_hud_hbox.add_theme_constant_override("separation", 8)
	top_hud_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_hud_hbox)

	# --- 1A. BOSS HUD PANEL (Child 0 in tree -> visited first, rendered on the RIGHT) ---
	var boss_hud_panel: PanelContainer = PanelContainer.new()
	boss_hud_panel.name = "BossHudPanel"
	boss_hud_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	boss_hud_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var boss_hud_style: StyleBoxFlat = StyleBoxFlat.new()
	boss_hud_style.bg_color = Color(0.12, 0.06, 0.14, 0.90)
	boss_hud_style.border_width_left = 1
	boss_hud_style.border_width_top = 1
	boss_hud_style.border_width_right = 1
	boss_hud_style.border_width_bottom = 1
	boss_hud_style.border_color = Color(0.85, 0.22, 0.42, 0.65)
	boss_hud_style.corner_radius_top_left = 8
	boss_hud_style.corner_radius_top_right = 8
	boss_hud_style.corner_radius_bottom_right = 8
	boss_hud_style.corner_radius_bottom_left = 8
	boss_hud_style.content_margin_left = 8
	boss_hud_style.content_margin_top = 6
	boss_hud_style.content_margin_right = 8
	boss_hud_style.content_margin_bottom = 6
	boss_hud_panel.add_theme_stylebox_override("panel", boss_hud_style)
	top_hud_hbox.add_child(boss_hud_panel)

	var boss_vbox: VBoxContainer = VBoxContainer.new()
	boss_vbox.add_theme_constant_override("separation", 4)
	boss_hud_panel.add_child(boss_vbox)

	var boss_title_box: HBoxContainer = HBoxContainer.new()
	boss_vbox.add_child(boss_title_box)

	_boss_name_label = Label.new()
	_boss_name_label.text = "BOSS: STOCHAS"
	_boss_name_label.add_theme_font_size_override("font_size", 13)
	_boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.55, 1.0))
	boss_title_box.add_child(_boss_name_label)

	var role_tag: Label = Label.new()
	role_tag.text = " [THỦ LĨNH]"
	role_tag.add_theme_font_size_override("font_size", 11)
	role_tag.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0, 0.8))
	boss_title_box.add_child(role_tag)

	var boss_hp_box: HBoxContainer = HBoxContainer.new()
	boss_vbox.add_child(boss_hp_box)

	var boss_hp_tag: Label = Label.new()
	boss_hp_tag.text = "HP:"
	boss_hp_tag.add_theme_font_size_override("font_size", 11)
	boss_hp_tag.add_theme_color_override("font_color", Color(0.9, 0.7, 0.8, 0.8))
	boss_hp_box.add_child(boss_hp_tag)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.name = "BossHPBar"
	_boss_hp_bar.custom_minimum_size = Vector2(0, 14)
	_boss_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_hp_bar.max_value = 100
	_boss_hp_bar.value = 100
	_boss_hp_bar.show_percentage = false

	var bhp_bg: StyleBoxFlat = StyleBoxFlat.new()
	bhp_bg.bg_color = Color(0.06, 0.05, 0.10, 0.95)
	bhp_bg.border_width_left = 1
	bhp_bg.border_width_top = 1
	bhp_bg.border_width_right = 1
	bhp_bg.border_width_bottom = 1
	bhp_bg.border_color = Color(0.25, 0.20, 0.35, 0.6)
	bhp_bg.corner_radius_top_left = 4
	bhp_bg.corner_radius_top_right = 4
	bhp_bg.corner_radius_bottom_right = 4
	bhp_bg.corner_radius_bottom_left = 4
	_boss_hp_bar.add_theme_stylebox_override("background", bhp_bg)

	var bhp_fill: StyleBoxFlat = StyleBoxFlat.new()
	bhp_fill.bg_color = Color(0.85, 0.15, 0.40, 0.95)
	bhp_fill.corner_radius_top_left = 4
	bhp_fill.corner_radius_top_right = 4
	bhp_fill.corner_radius_bottom_right = 4
	bhp_fill.corner_radius_bottom_left = 4
	_boss_hp_bar.add_theme_stylebox_override("fill", bhp_fill)
	boss_hp_box.add_child(_boss_hp_bar)

	_boss_hp_label = Label.new()
	_boss_hp_label.name = "BossHPLabel"
	_boss_hp_label.text = "100 / 100"
	_boss_hp_label.add_theme_font_size_override("font_size", 11)
	_boss_hp_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.90, 0.95))
	boss_hp_box.add_child(_boss_hp_label)

	# Boss Intent Pill Box
	var intent_panel: PanelContainer = PanelContainer.new()
	var intent_style: StyleBoxFlat = StyleBoxFlat.new()
	intent_style.bg_color = Color(0.18, 0.13, 0.05, 0.80)
	intent_style.border_width_left = 1
	intent_style.border_width_top = 1
	intent_style.border_width_right = 1
	intent_style.border_width_bottom = 1
	intent_style.border_color = Color(0.95, 0.75, 0.20, 0.70)
	intent_style.corner_radius_top_left = 4
	intent_style.corner_radius_top_right = 4
	intent_style.corner_radius_bottom_right = 4
	intent_style.corner_radius_bottom_left = 4
	intent_style.content_margin_left = 6
	intent_style.content_margin_top = 2
	intent_style.content_margin_right = 6
	intent_style.content_margin_bottom = 2
	intent_panel.add_theme_stylebox_override("panel", intent_style)
	boss_vbox.add_child(intent_panel)

	_boss_intent_label = Label.new()
	_boss_intent_label.text = "⚡ Ý định: Ma Thuật Ngẫu Nhiên (10 ST)"
	_boss_intent_label.add_theme_font_size_override("font_size", 11)
	_boss_intent_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 1.0))
	intent_panel.add_child(_boss_intent_label)

	# --- 1B. PLAYER HUD PANEL (Child 1 in tree -> visited second, rendered on the LEFT) ---
	var player_hud_panel: PanelContainer = PanelContainer.new()
	player_hud_panel.name = "PlayerHudPanel"
	player_hud_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	player_hud_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var player_hud_style: StyleBoxFlat = StyleBoxFlat.new()
	player_hud_style.bg_color = Color(0.05, 0.09, 0.14, 0.90)
	player_hud_style.border_width_left = 1
	player_hud_style.border_width_top = 1
	player_hud_style.border_width_right = 1
	player_hud_style.border_width_bottom = 1
	player_hud_style.border_color = Color(0.20, 0.75, 0.85, 0.65)
	player_hud_style.corner_radius_top_left = 8
	player_hud_style.corner_radius_top_right = 8
	player_hud_style.corner_radius_bottom_right = 8
	player_hud_style.corner_radius_bottom_left = 8
	player_hud_style.content_margin_left = 8
	player_hud_style.content_margin_top = 6
	player_hud_style.content_margin_right = 8
	player_hud_style.content_margin_bottom = 6
	player_hud_panel.add_theme_stylebox_override("panel", player_hud_style)
	top_hud_hbox.add_child(player_hud_panel)

	var player_vbox: VBoxContainer = VBoxContainer.new()
	player_vbox.add_theme_constant_override("separation", 4)
	player_hud_panel.add_child(player_vbox)

	var player_title_box: HBoxContainer = HBoxContainer.new()
	player_vbox.add_child(player_title_box)

	var p_title: Label = Label.new()
	p_title.text = "CHIẾN BINH MATHOS"
	p_title.add_theme_font_size_override("font_size", 13)
	p_title.add_theme_color_override("font_color", Color(0.3, 0.92, 0.72, 1.0))
	player_title_box.add_child(p_title)

	_player_shield_label = Label.new()
	_player_shield_label.text = "  🛡️ Giáp: 0"
	_player_shield_label.add_theme_font_size_override("font_size", 11)
	_player_shield_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
	player_title_box.add_child(_player_shield_label)

	var player_hp_box: HBoxContainer = HBoxContainer.new()
	player_vbox.add_child(player_hp_box)

	var p_hp_tag: Label = Label.new()
	p_hp_tag.text = "HP:"
	p_hp_tag.add_theme_font_size_override("font_size", 11)
	p_hp_tag.add_theme_color_override("font_color", Color(0.6, 0.85, 0.75, 0.8))
	player_hp_box.add_child(p_hp_tag)

	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.name = "PlayerHPBar"
	_player_hp_bar.custom_minimum_size = Vector2(0, 14)
	_player_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_hp_bar.max_value = 100
	_player_hp_bar.value = 100
	_player_hp_bar.show_percentage = false

	var php_bg: StyleBoxFlat = StyleBoxFlat.new()
	php_bg.bg_color = Color(0.06, 0.05, 0.10, 0.95)
	php_bg.border_width_left = 1
	php_bg.border_width_top = 1
	php_bg.border_width_right = 1
	php_bg.border_width_bottom = 1
	php_bg.border_color = Color(0.18, 0.30, 0.25, 0.6)
	php_bg.corner_radius_top_left = 4
	php_bg.corner_radius_top_right = 4
	php_bg.corner_radius_bottom_right = 4
	php_bg.corner_radius_bottom_left = 4
	_player_hp_bar.add_theme_stylebox_override("background", php_bg)

	var php_fill: StyleBoxFlat = StyleBoxFlat.new()
	php_fill.bg_color = Color(0.20, 0.80, 0.35, 0.95)
	php_fill.corner_radius_top_left = 4
	php_fill.corner_radius_top_right = 4
	php_fill.corner_radius_bottom_right = 4
	php_fill.corner_radius_bottom_left = 4
	_player_hp_bar.add_theme_stylebox_override("fill", php_fill)
	player_hp_box.add_child(_player_hp_bar)

	_player_hp_label = Label.new()
	_player_hp_label.name = "PlayerHPLabel"
	_player_hp_label.text = "100 / 100"
	_player_hp_label.add_theme_font_size_override("font_size", 11)
	_player_hp_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85, 0.95))
	player_hp_box.add_child(_player_hp_label)

	var p_status_label: Label = Label.new()
	p_status_label.text = "Cấp 1 • Dũng sĩ Mathos"
	p_status_label.add_theme_font_size_override("font_size", 10)
	p_status_label.add_theme_color_override("font_color", Color(0.55, 0.75, 0.85, 0.7))
	player_vbox.add_child(p_status_label)

	# ---------------------------------------------------------
	# 2. BOSS VISUAL CONTAINER (Prominent STOCHAS Pixel-Art Frame)
	# ---------------------------------------------------------
	_boss_visual_rect = PanelContainer.new()
	_boss_visual_rect.name = "BossVisualContainer"
	_boss_visual_rect.custom_minimum_size = Vector2(0, BOSS_VISUAL_CONTAINER_HEIGHT)
	_boss_visual_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_visual_rect.clip_contents = true

	var boss_visual_style: StyleBoxFlat = StyleBoxFlat.new()
	boss_visual_style.bg_color = Color(0.09, 0.06, 0.16, 0.92)
	boss_visual_style.border_width_left = 1
	boss_visual_style.border_width_top = 1
	boss_visual_style.border_width_right = 1
	boss_visual_style.border_width_bottom = 1
	boss_visual_style.border_color = Color(0.40, 0.30, 0.75, 0.55)
	boss_visual_style.corner_radius_top_left = 8
	boss_visual_style.corner_radius_top_right = 8
	boss_visual_style.corner_radius_bottom_right = 8
	boss_visual_style.corner_radius_bottom_left = 8
	_boss_visual_rect.add_theme_stylebox_override("panel", boss_visual_style)
	vbox.add_child(_boss_visual_rect)

	# Safe Margin Container: 10% safe visual margin (18px) prevents hood/staff clipping
	var sprite_margin: MarginContainer = MarginContainer.new()
	sprite_margin.name = "SpriteMarginContainer"
	var margin_px: int = int(round(BOSS_VISUAL_CONTAINER_HEIGHT * SAFE_MARGIN_PERCENT))
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

	# ---------------------------------------------------------
	# 3. ACTION CARDS BAR (Lower Area: Strike, Defend, Heal)
	# ---------------------------------------------------------
	_cards_header_label = Label.new()
	_cards_header_label.text = "THẺ BÀI CHIẾN THUẬT (Chọn 1 thẻ trước khi giải đố):"
	_cards_header_label.add_theme_font_size_override("font_size", 11)
	_cards_header_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.60, 0.90))
	vbox.add_child(_cards_header_label)

	_cards_container = HBoxContainer.new()
	_cards_container.name = "CardsContainer"
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 8)
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.custom_minimum_size = Vector2(0, 162)
	vbox.add_child(_cards_container)

	_build_card_slots()

	# ---------------------------------------------------------
	# 4. COMBAT ACTION LOG (Lower Area)
	# ---------------------------------------------------------
	var log_panel: PanelContainer = PanelContainer.new()
	var log_style: StyleBoxFlat = StyleBoxFlat.new()
	log_style.bg_color = Color(0.06, 0.08, 0.14, 0.85)
	log_style.border_width_left = 1
	log_style.border_width_top = 1
	log_style.border_width_right = 1
	log_style.border_width_bottom = 1
	log_style.border_color = Color(0.25, 0.35, 0.50, 0.45)
	log_style.corner_radius_top_left = 6
	log_style.corner_radius_top_right = 6
	log_style.corner_radius_bottom_right = 6
	log_style.corner_radius_bottom_left = 6
	log_style.content_margin_left = 10
	log_style.content_margin_top = 6
	log_style.content_margin_right = 10
	log_style.content_margin_bottom = 6
	log_panel.add_theme_stylebox_override("panel", log_style)
	vbox.add_child(log_panel)

	_combat_log_label = Label.new()
	_combat_log_label.text = "⚔️ Chọn thẻ bài và trả lời chính xác để tấn công Boss!"
	_combat_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_combat_log_label.add_theme_font_size_override("font_size", 12)
	_combat_log_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
	log_panel.add_child(_combat_log_label)

	# ---------------------------------------------------------
	# 5. DEFEAT OVERLAY (Hidden by default)
	# ---------------------------------------------------------
	_defeat_overlay = PanelContainer.new()
	_defeat_overlay.visible = false
	var def_style: StyleBoxFlat = StyleBoxFlat.new()
	def_style.bg_color = Color(0.20, 0.05, 0.05, 0.95)
	def_style.border_width_left = 2
	def_style.border_width_top = 2
	def_style.border_width_right = 2
	def_style.border_width_bottom = 2
	def_style.border_color = Color(1.0, 0.20, 0.20, 0.85)
	def_style.corner_radius_top_left = 8
	def_style.corner_radius_top_right = 8
	def_style.corner_radius_bottom_right = 8
	def_style.corner_radius_bottom_left = 8
	def_style.content_margin_left = 12
	def_style.content_margin_top = 8
	def_style.content_margin_right = 12
	def_style.content_margin_bottom = 8
	_defeat_overlay.add_theme_stylebox_override("panel", def_style)
	vbox.add_child(_defeat_overlay)

	var def_vbox: VBoxContainer = VBoxContainer.new()
	def_vbox.add_theme_constant_override("separation", 6)
	_defeat_overlay.add_child(def_vbox)

	var def_title: Label = Label.new()
	def_title.text = "💀 BỊ ĐÁNH BẠI!"
	def_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_title.add_theme_font_size_override("font_size", 15)
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

	# ---------------------------------------------------------
	# 6. VICTORY OVERLAY (Hidden by default)
	# ---------------------------------------------------------
	_victory_overlay = PanelContainer.new()
	_victory_overlay.visible = false
	var vic_style: StyleBoxFlat = StyleBoxFlat.new()
	vic_style.bg_color = Color(0.05, 0.20, 0.10, 0.95)
	vic_style.border_width_left = 2
	vic_style.border_width_top = 2
	vic_style.border_width_right = 2
	vic_style.border_width_bottom = 2
	vic_style.border_color = Color(0.30, 1.0, 0.40, 0.85)
	vic_style.corner_radius_top_left = 8
	vic_style.corner_radius_top_right = 8
	vic_style.corner_radius_bottom_right = 8
	vic_style.corner_radius_bottom_left = 8
	vic_style.content_margin_left = 12
	vic_style.content_margin_top = 8
	vic_style.content_margin_right = 12
	vic_style.content_margin_bottom = 8
	_victory_overlay.add_theme_stylebox_override("panel", vic_style)
	vbox.add_child(_victory_overlay)

	var vic_vbox: VBoxContainer = VBoxContainer.new()
	vic_vbox.add_theme_constant_override("separation", 6)
	_victory_overlay.add_child(vic_vbox)

	var vic_title: Label = Label.new()
	vic_title.text = "🏆 CHIẾN THẮNG!"
	vic_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_title.add_theme_font_size_override("font_size", 15)
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

func _build_card_slots() -> void:
	if not _card_slots.is_empty():
		return
	if _cards_container == null:
		return

	_card_buttons.clear()
	_card_slots.clear()
	_card_slots_by_id.clear()
	_card_buttons_by_id.clear()
	_card_textures_by_id.clear()
	_card_badges_by_id.clear()
	_card_badge_panels_by_id.clear()
	_card_statuses_by_id.clear()
	_card_status_panels_by_id.clear()

	for def in CARD_DEFINITIONS:
		var c_id: String = String(def["id"])
		var is_skill: bool = bool(def["is_skill"])

		var slot: MarginContainer = MarginContainer.new()
		slot.name = "CardSlot_" + c_id
		slot.custom_minimum_size = Vector2(CARD_WIDTH, 160)
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot.add_theme_constant_override("margin_top", 6)
		slot.add_theme_constant_override("margin_bottom", 0)
		_cards_container.add_child(slot)

		var btn: Button = Button.new()
		btn.name = "CardButton_" + c_id
		btn.text = ""
		btn.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.clip_contents = true
		slot.add_child(btn)

		var card_vbox: VBoxContainer = VBoxContainer.new()
		card_vbox.name = "CardVBox"
		card_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_theme_constant_override("separation", 2)
		btn.add_child(card_vbox)

		# Top Badge Container
		var badge_margin: MarginContainer = MarginContainer.new()
		badge_margin.name = "BadgeMargin"
		badge_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_margin.add_theme_constant_override("margin_top", 4)
		badge_margin.add_theme_constant_override("margin_left", 6)
		badge_margin.add_theme_constant_override("margin_right", 6)
		card_vbox.add_child(badge_margin)

		var badge_panel: PanelContainer = PanelContainer.new()
		badge_panel.name = "BadgePanel"
		badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_margin.add_child(badge_panel)

		var badge_label: Label = Label.new()
		badge_label.name = "BadgeLabel"
		badge_label.text = String(def["default_badge"])
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.add_theme_font_size_override("font_size", 9)
		badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_panel.add_child(badge_label)

		# Texture Rect
		var art_margin: MarginContainer = MarginContainer.new()
		art_margin.name = "ArtMargin"
		art_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art_margin.add_theme_constant_override("margin_left", 4)
		art_margin.add_theme_constant_override("margin_right", 4)
		card_vbox.add_child(art_margin)

		var tex_rect: TextureRect = TextureRect.new()
		tex_rect.name = "CardTextureRect"
		tex_rect.texture = load_card_texture(String(def["texture_path"]))
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_margin.add_child(tex_rect)

		# Status Value Label
		var status_margin: MarginContainer = MarginContainer.new()
		status_margin.name = "StatusMargin"
		status_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_margin.add_theme_constant_override("margin_bottom", 4)
		status_margin.add_theme_constant_override("margin_left", 4)
		status_margin.add_theme_constant_override("margin_right", 4)
		card_vbox.add_child(status_margin)

		var status_panel: PanelContainer = PanelContainer.new()
		status_panel.name = "StatusPanel"
		status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_margin.add_child(status_panel)

		var status_label: Label = Label.new()
		status_label.name = "StatusLabel"
		status_label.text = "CHƯA KÍCH HOẠT" if is_skill else ""
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 10)
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_panel.add_child(status_label)

		if not is_skill:
			btn.pressed.connect(_on_card_button_pressed.bind(c_id))
		else:
			btn.disabled = true

		_card_slots.append(slot)
		_card_buttons.append(btn)
		_card_slots_by_id[c_id] = slot
		_card_buttons_by_id[c_id] = btn
		_card_textures_by_id[c_id] = tex_rect
		_card_badges_by_id[c_id] = badge_label
		_card_badge_panels_by_id[c_id] = badge_panel
		_card_statuses_by_id[c_id] = status_label
		_card_status_panels_by_id[c_id] = status_panel

func _render_cards() -> void:
	if _cards_container == null:
		return

	var in_active_combat: bool = (_combat_controller != null and _combat_controller.is_in_combat and _combat_controller.boss_entity != null and not _combat_controller.boss_entity.is_defeated and _combat_controller.player_runtime != null and not _combat_controller.player_runtime.is_defeated)
	_cards_container.visible = in_active_combat
	if _cards_header_label != null:
		_cards_header_label.visible = in_active_combat

	if not in_active_combat or _combat_controller == null:
		return

	_build_card_slots()

	var active_card: CardModel = _combat_controller.get_selected_card()
	var hand_cards: Array[CardModel] = _combat_controller.hand_cards

	for def in CARD_DEFINITIONS:
		var c_id: String = String(def["id"])
		var is_skill: bool = bool(def["is_skill"])
		var slot: MarginContainer = _card_slots_by_id.get(c_id, null) as MarginContainer
		var btn: Button = _card_buttons_by_id.get(c_id, null) as Button
		var tex_rect: TextureRect = _card_textures_by_id.get(c_id, null) as TextureRect
		var badge_lbl: Label = _card_badges_by_id.get(c_id, null) as Label
		var badge_panel: PanelContainer = _card_badge_panels_by_id.get(c_id, null) as PanelContainer
		var status_lbl: Label = _card_statuses_by_id.get(c_id, null) as Label
		var status_panel: PanelContainer = _card_status_panels_by_id.get(c_id, null) as PanelContainer

		if slot == null or btn == null or tex_rect == null:
			continue

		var model: CardModel = null
		for hm in hand_cards:
			if hm.card_id == c_id:
				model = hm
				break

		var is_selected: bool = (not is_skill and active_card != null and active_card.card_id == c_id)

		if is_skill:
			# -----------------------------------------------------
			# CONDITIONAL SKILL (PROBABILITY - UNAVAILABLE)
			# -----------------------------------------------------
			slot.add_theme_constant_override("margin_top", 6)
			slot.add_theme_constant_override("margin_bottom", 0)
			btn.disabled = true

			var skill_style: StyleBoxFlat = StyleBoxFlat.new()
			skill_style.bg_color = Color(0.07, 0.06, 0.12, 0.90)
			skill_style.border_width_left = 1
			skill_style.border_width_top = 1
			skill_style.border_width_right = 1
			skill_style.border_width_bottom = 1
			skill_style.border_color = Color(0.45, 0.30, 0.65, 0.55)
			skill_style.corner_radius_top_left = 8
			skill_style.corner_radius_top_right = 8
			skill_style.corner_radius_bottom_right = 8
			skill_style.corner_radius_bottom_left = 8
			btn.add_theme_stylebox_override("normal", skill_style)
			btn.add_theme_stylebox_override("disabled", skill_style)

			# Texture: reduced brightness/saturation, recognizable art, purple/blue tint
			tex_rect.modulate = Color(0.65, 0.60, 0.80, 0.75)

			# Badge: KỸ NĂNG
			if badge_lbl != null:
				badge_lbl.text = "KỸ NĂNG"
				badge_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0, 0.90))
			if badge_panel != null:
				var bp_style: StyleBoxFlat = StyleBoxFlat.new()
				bp_style.bg_color = Color(0.28, 0.16, 0.40, 0.75)
				bp_style.corner_radius_top_left = 4
				bp_style.corner_radius_top_right = 4
				bp_style.corner_radius_bottom_right = 4
				bp_style.corner_radius_bottom_left = 4
				bp_style.content_margin_left = 6
				bp_style.content_margin_right = 6
				bp_style.content_margin_top = 2
				bp_style.content_margin_bottom = 2
				badge_panel.add_theme_stylebox_override("panel", bp_style)

			# Status: CHƯA KÍCH HOẠT
			if status_lbl != null:
				status_lbl.text = "CHƯA KÍCH HOẠT"
				status_lbl.add_theme_color_override("font_color", Color(0.70, 0.65, 0.85, 0.80))
			if status_panel != null:
				var sp_style: StyleBoxFlat = StyleBoxFlat.new()
				sp_style.bg_color = Color(0.06, 0.05, 0.10, 0.80)
				sp_style.corner_radius_top_left = 4
				sp_style.corner_radius_top_right = 4
				sp_style.corner_radius_bottom_right = 4
				sp_style.corner_radius_bottom_left = 4
				sp_style.content_margin_left = 4
				sp_style.content_margin_right = 4
				sp_style.content_margin_top = 2
				sp_style.content_margin_bottom = 2
				status_panel.add_theme_stylebox_override("panel", sp_style)

		elif is_selected:
			# -----------------------------------------------------
			# SELECTED BASIC CARD
			# -----------------------------------------------------
			slot.add_theme_constant_override("margin_top", 0)
			slot.add_theme_constant_override("margin_bottom", 6)
			btn.disabled = false

			var sel_style: StyleBoxFlat = StyleBoxFlat.new()
			sel_style.bg_color = Color(0.12, 0.18, 0.32, 0.98)
			sel_style.border_width_left = 2
			sel_style.border_width_top = 2
			sel_style.border_width_right = 2
			sel_style.border_width_bottom = 2
			sel_style.border_color = Color(0.25, 0.90, 1.0, 1.0)
			sel_style.corner_radius_top_left = 8
			sel_style.corner_radius_top_right = 8
			sel_style.corner_radius_bottom_right = 8
			sel_style.corner_radius_bottom_left = 8
			sel_style.shadow_color = Color(0.20, 0.85, 1.0, 0.35)
			sel_style.shadow_size = 6
			btn.add_theme_stylebox_override("normal", sel_style)
			btn.add_theme_stylebox_override("hover", sel_style)
			btn.add_theme_stylebox_override("pressed", sel_style)
			btn.add_theme_stylebox_override("focus", sel_style)

			# Texture: fully clear, full brightness
			tex_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)

			# Badge: ĐANG CHỌN
			if badge_lbl != null:
				badge_lbl.text = "ĐANG CHỌN"
				badge_lbl.add_theme_color_override("font_color", Color(0.04, 0.08, 0.14, 1.0))
			if badge_panel != null:
				var bp_style: StyleBoxFlat = StyleBoxFlat.new()
				bp_style.bg_color = Color(0.25, 0.90, 1.0, 0.95)
				bp_style.corner_radius_top_left = 4
				bp_style.corner_radius_top_right = 4
				bp_style.corner_radius_bottom_right = 4
				bp_style.corner_radius_bottom_left = 4
				bp_style.content_margin_left = 6
				bp_style.content_margin_right = 6
				bp_style.content_margin_top = 2
				bp_style.content_margin_bottom = 2
				badge_panel.add_theme_stylebox_override("panel", bp_style)

			# Status: dynamic from model
			if status_lbl != null:
				status_lbl.text = _get_card_dynamic_value_text(c_id, model)
				status_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0, 1.0))
			if status_panel != null:
				var sp_style: StyleBoxFlat = StyleBoxFlat.new()
				sp_style.bg_color = Color(0.05, 0.10, 0.18, 0.90)
				sp_style.border_width_left = 1
				sp_style.border_width_top = 1
				sp_style.border_width_right = 1
				sp_style.border_width_bottom = 1
				sp_style.border_color = Color(0.25, 0.90, 1.0, 0.50)
				sp_style.corner_radius_top_left = 4
				sp_style.corner_radius_top_right = 4
				sp_style.corner_radius_bottom_right = 4
				sp_style.corner_radius_bottom_left = 4
				sp_style.content_margin_left = 4
				sp_style.content_margin_right = 4
				sp_style.content_margin_top = 2
				sp_style.content_margin_bottom = 2
				status_panel.add_theme_stylebox_override("panel", sp_style)

		else:
			# -----------------------------------------------------
			# UNSELECTED BASIC CARD
			# -----------------------------------------------------
			slot.add_theme_constant_override("margin_top", 6)
			slot.add_theme_constant_override("margin_bottom", 0)
			btn.disabled = false

			var norm_style: StyleBoxFlat = StyleBoxFlat.new()
			norm_style.bg_color = Color(0.08, 0.10, 0.16, 0.92)
			norm_style.border_width_left = 1
			norm_style.border_width_top = 1
			norm_style.border_width_right = 1
			norm_style.border_width_bottom = 1
			norm_style.border_color = Color(0.28, 0.36, 0.50, 0.65)
			norm_style.corner_radius_top_left = 8
			norm_style.corner_radius_top_right = 8
			norm_style.corner_radius_bottom_right = 8
			norm_style.corner_radius_bottom_left = 8

			var hov_style: StyleBoxFlat = StyleBoxFlat.new()
			hov_style.bg_color = Color(0.12, 0.16, 0.26, 0.96)
			hov_style.border_width_left = 1
			hov_style.border_width_top = 1
			hov_style.border_width_right = 1
			hov_style.border_width_bottom = 1
			hov_style.border_color = Color(0.45, 0.65, 0.85, 0.85)
			hov_style.corner_radius_top_left = 8
			hov_style.corner_radius_top_right = 8
			hov_style.corner_radius_bottom_right = 8
			hov_style.corner_radius_bottom_left = 8

			btn.add_theme_stylebox_override("normal", norm_style)
			btn.add_theme_stylebox_override("hover", hov_style)
			btn.add_theme_stylebox_override("pressed", norm_style)
			btn.add_theme_stylebox_override("focus", hov_style)

			# Texture: readable, slightly quieter
			tex_rect.modulate = Color(0.92, 0.92, 0.95, 0.92)

			# Badge: card role tag
			if badge_lbl != null:
				badge_lbl.text = String(def["default_badge"])
				match c_id:
					"card_strike":
						badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75, 0.95))
					"card_defend":
						badge_lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 0.95))
					"card_heal":
						badge_lbl.add_theme_color_override("font_color", Color(0.75, 1.0, 0.80, 0.95))
					_:
						badge_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95, 0.90))

			if badge_panel != null:
				var bp_style: StyleBoxFlat = StyleBoxFlat.new()
				match c_id:
					"card_strike":
						bp_style.bg_color = Color(0.38, 0.12, 0.16, 0.75)
					"card_defend":
						bp_style.bg_color = Color(0.12, 0.25, 0.40, 0.75)
					"card_heal":
						bp_style.bg_color = Color(0.12, 0.36, 0.22, 0.75)
					_:
						bp_style.bg_color = Color(0.18, 0.22, 0.30, 0.75)
				bp_style.corner_radius_top_left = 4
				bp_style.corner_radius_top_right = 4
				bp_style.corner_radius_bottom_right = 4
				bp_style.corner_radius_bottom_left = 4
				bp_style.content_margin_left = 6
				bp_style.content_margin_right = 6
				bp_style.content_margin_top = 2
				bp_style.content_margin_bottom = 2
				badge_panel.add_theme_stylebox_override("panel", bp_style)

			# Status: dynamic from model
			if status_lbl != null:
				status_lbl.text = _get_card_dynamic_value_text(c_id, model)
				status_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 0.90))
			if status_panel != null:
				var sp_style: StyleBoxFlat = StyleBoxFlat.new()
				sp_style.bg_color = Color(0.05, 0.07, 0.12, 0.85)
				sp_style.corner_radius_top_left = 4
				sp_style.corner_radius_top_right = 4
				sp_style.corner_radius_bottom_right = 4
				sp_style.corner_radius_bottom_left = 4
				sp_style.content_margin_left = 4
				sp_style.content_margin_right = 4
				sp_style.content_margin_top = 2
				sp_style.content_margin_bottom = 2
				status_panel.add_theme_stylebox_override("panel", sp_style)

func _get_card_dynamic_value_text(card_id: String, model: CardModel) -> String:
	if card_id == "card_probability":
		return "CHƯA KÍCH HOẠT"
	if model != null and not model.effects.is_empty():
		var ef: Dictionary = model.effects[0] as Dictionary
		var e_type: String = String(ef.get("effect_type", ""))
		var amt: int = int(ef.get("amount", 0))
		match e_type:
			"damage":
				return "⚔️ %d ST" % amt
			"shield":
				return "🛡️ +%d Giáp" % amt
			"heal":
				return "💚 +%d HP" % amt
			_:
				return "%s %d" % [e_type, amt]
	match card_id:
		"card_strike": return "⚔️ 10 ST"
		"card_defend": return "🛡️ +8 Giáp"
		"card_heal": return "💚 +15 HP"
		_: return ""

func _on_card_button_pressed(card_id: String) -> void:
	if _combat_controller != null and _combat_controller.is_in_combat:
		_combat_controller.select_card(card_id)
		card_selected.emit(card_id)
		_render_cards()

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

func get_card_slots() -> Array:
	_ensure_ui()
	_build_card_slots()
	return _card_slots.duplicate()

func get_card_button(card_id: String) -> Button:
	_ensure_ui()
	_build_card_slots()
	var norm: String = _normalize_card_id(card_id)
	return _card_buttons_by_id.get(norm, null) as Button

func get_card_texture_rect(card_id: String) -> TextureRect:
	_ensure_ui()
	_build_card_slots()
	var norm: String = _normalize_card_id(card_id)
	return _card_textures_by_id.get(norm, null) as TextureRect

func get_card_badge_label(card_id: String) -> Label:
	_ensure_ui()
	_build_card_slots()
	var norm: String = _normalize_card_id(card_id)
	return _card_badges_by_id.get(norm, null) as Label

func get_card_status_label(card_id: String) -> Label:
	_ensure_ui()
	_build_card_slots()
	var norm: String = _normalize_card_id(card_id)
	return _card_statuses_by_id.get(norm, null) as Label

func is_card_selected(card_id: String) -> bool:
	if _combat_controller == null or not _combat_controller.is_in_combat:
		return false
	var norm: String = _normalize_card_id(card_id)
	if norm == "card_probability":
		return false
	var active: CardModel = _combat_controller.get_selected_card()
	if active == null:
		return false
	return _normalize_card_id(active.card_id) == norm

func is_card_available(card_id: String) -> bool:
	var norm: String = _normalize_card_id(card_id)
	if norm == "card_probability":
		return false
	if _combat_controller == null or not _combat_controller.is_in_combat:
		return false
	for c in _combat_controller.hand_cards:
		if _normalize_card_id(c.card_id) == norm:
			return true
	return false

func _normalize_card_id(card_id: String) -> String:
	var lower: String = card_id.to_lower().strip_edges()
	if not lower.begins_with("card_"):
		lower = "card_" + lower
	return lower

static func load_card_texture(path: String) -> Texture2D:
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

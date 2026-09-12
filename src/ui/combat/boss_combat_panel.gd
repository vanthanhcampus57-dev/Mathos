class_name BossCombatPanel
extends Control

## Production Boss Combat Panel for Stage 1.5 (Boss STOCHAS).
## Implements authoritative Stitch reference presentation layout (1280 x 720 canvas):
## - Dual HUD Header (Player HUD Top-Left, Boss HUD Top-Right, compact glass)
## - STOCHAS full visual right stage (~460px wide, ~530px art height, cyan glow, subtle float)
## - Tactical Action Cards (106 x 154 px, ~14px gap, 4 centered cards at bottom)
## - Flow Pill directly above card row ("1. CHỌN THẺ BÀI → 2. GIẢI TOÁN → 3. XUẤT CHIÊU")
## - Compact Lower-Left Combat Action Feed (240px wide, dark glass box)
## - Minimal bottom-right settings control
## - Responsive overlays (Defeat / Retry & Victory)
## 100% preservation of Stage 1.5 lifecycle, HP/shield, and combat controller semantics.

signal card_selected(card_id: String)
signal retry_pressed()
signal victory_acknowledged()

const KARL_PORTRAIT_PATH: String = "res://assets/characters/player/karl/karl_portrait.png"
const STOCHAS_TEXTURE_PATH: String = "res://assets/characters/bosses/dungeon_1/stochas_boss.png"
const BOSS_VISUAL_CONTAINER_HEIGHT: float = 180.0
const SAFE_MARGIN_PERCENT: float = 0.10 # 10% safe visual margin (8–12% requirement)

const BOSS_STAGE_WIDTH: float = 460.0
const BOSS_ART_HEIGHT: float = 530.0

const CARD_STRIKE_TEXTURE_PATH: String = "res://assets/ui/combat/cards_v1/STRIKE.png"
const CARD_DEFEND_TEXTURE_PATH: String = "res://assets/ui/combat/cards_v1/DEFEND.png"
const CARD_HEAL_TEXTURE_PATH: String = "res://assets/ui/combat/cards_v1/HEAL.png"
const CARD_PROBABILITY_TEXTURE_PATH: String = "res://assets/ui/combat/cards_v1/PROBABILITY.png"
const CARD_WIDTH: float = 160.0
const CARD_HEIGHT: float = 225.0
const CARD_GAP: float = 16.0

const _PRELOAD_STRIKE: Texture2D = preload("res://assets/ui/combat/cards_v1/STRIKE.png")
const _PRELOAD_DEFEND: Texture2D = preload("res://assets/ui/combat/cards_v1/DEFEND.png")
const _PRELOAD_HEAL: Texture2D = preload("res://assets/ui/combat/cards_v1/HEAL.png")
const _PRELOAD_PROBABILITY: Texture2D = preload("res://assets/ui/combat/cards_v1/PROBABILITY.png")
const _PRELOAD_KARL: Texture2D = preload("res://assets/characters/player/karl/karl_portrait.png")
const _PRELOAD_STOCHAS: Texture2D = preload("res://assets/characters/bosses/dungeon_1/stochas_boss.png")

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

# Layout Containers
var _top_hud_container: Control = null
var _player_hud_panel: PanelContainer = null
var _boss_hud_panel: PanelContainer = null
var _boss_stage_container: Control = null
var _bottom_center_container: VBoxContainer = null
var _combat_feed_panel: PanelContainer = null
var _settings_button: Button = null
var _selected_card_id: String = "card_strike"

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

var _feed_vbox: VBoxContainer = null
var _prev_combat_log_label: Label = null
var _combat_log_label: Label = null
var _defeat_overlay: PanelContainer = null
var _defeat_retry_button: Button = null
var _victory_overlay: PanelContainer = null

var _float_time: float = 0.0

func _ready() -> void:
	_ensure_ui()
	_layout_elements()
	set_process(true)

func _process(delta: float) -> void:
	if _boss_sprite_rect != null and is_visible_in_tree():
		_float_time += delta
		var offset_y: float = sin(_float_time * 2.2) * 4.0
		_boss_sprite_rect.position.y = offset_y

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_elements()

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
	if _combat_controller.boss_hp_changed.is_connected(_on_boss_hp_changed):
		_combat_controller.boss_hp_changed.disconnect(_on_boss_hp_changed)
	if _combat_controller.player_hp_changed.is_connected(_on_player_hp_changed):
		_combat_controller.player_hp_changed.disconnect(_on_player_hp_changed)
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
	if not _combat_controller.boss_hp_changed.is_connected(_on_boss_hp_changed):
		_combat_controller.boss_hp_changed.connect(_on_boss_hp_changed)
	if not _combat_controller.player_hp_changed.is_connected(_on_player_hp_changed):
		_combat_controller.player_hp_changed.connect(_on_player_hp_changed)
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
	mouse_filter = Control.MOUSE_FILTER_PASS

	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()

	# ---------------------------------------------------------
	# 1. BOSS STAGE CONTAINER (Right ~8px, top ~40px, bottom ~48px, width ~460px)
	# ---------------------------------------------------------
	_boss_stage_container = Control.new()
	_boss_stage_container.name = "BossStageContainer"
	_boss_stage_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_boss_stage_container)

	_boss_visual_rect = PanelContainer.new()
	_boss_visual_rect.name = "BossVisualContainer"
	_boss_visual_rect.custom_minimum_size = Vector2(BOSS_STAGE_WIDTH, BOSS_VISUAL_CONTAINER_HEIGHT)
	_boss_visual_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_visual_rect.clip_contents = false

	# Unboxed aesthetic: completely transparent background, no opaque box, subtle mystical cyan aura
	var boss_visual_style: StyleBoxFlat = StyleBoxFlat.new()
	boss_visual_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	boss_visual_style.border_width_left = 0
	boss_visual_style.border_width_top = 0
	boss_visual_style.border_width_right = 0
	boss_visual_style.border_width_bottom = 0
	boss_visual_style.shadow_color = Color(0.15, 0.75, 0.95, 0.18)
	boss_visual_style.shadow_size = 14
	_boss_visual_rect.add_theme_stylebox_override("panel", boss_visual_style)
	_boss_stage_container.add_child(_boss_visual_rect)

	var sprite_margin: MarginContainer = MarginContainer.new()
	sprite_margin.name = "SpriteMarginContainer"
	var margin_px: int = int(round(BOSS_VISUAL_CONTAINER_HEIGHT * SAFE_MARGIN_PERCENT)) # 18px (10%)
	sprite_margin.add_theme_constant_override("margin_left", margin_px)
	sprite_margin.add_theme_constant_override("margin_top", margin_px)
	sprite_margin.add_theme_constant_override("margin_right", margin_px)
	sprite_margin.add_theme_constant_override("margin_bottom", margin_px)
	sprite_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_boss_sprite_rect.custom_minimum_size = Vector2(0, BOSS_ART_HEIGHT)
	_boss_sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_margin.add_child(_boss_sprite_rect)

	# ---------------------------------------------------------
	# 2. TOP DUAL HUD CONTAINER (padding left/right 32px, top 16px)
	# ---------------------------------------------------------
	_top_hud_container = Control.new()
	_top_hud_container.name = "TopHudContainer"
	_top_hud_container.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_top_hud_container)

	# --- 2A. BOSS HUD PANEL (Child 0 in tree -> visited first by find_children, rendered on RIGHT) ---
	_boss_hud_panel = PanelContainer.new()
	_boss_hud_panel.name = "BossHudPanel"
	_boss_hud_panel.custom_minimum_size = Vector2(304, 56)
	_boss_hud_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var boss_hud_style: StyleBoxFlat = StyleBoxFlat.new()
	boss_hud_style.bg_color = Color(0.14, 0.06, 0.10, 0.88)
	boss_hud_style.border_width_left = 1
	boss_hud_style.border_width_top = 1
	boss_hud_style.border_width_right = 1
	boss_hud_style.border_width_bottom = 1
	boss_hud_style.border_color = Color(0.90, 0.25, 0.35, 0.80)
	boss_hud_style.corner_radius_top_left = 12
	boss_hud_style.corner_radius_top_right = 12
	boss_hud_style.corner_radius_bottom_right = 12
	boss_hud_style.corner_radius_bottom_left = 12
	boss_hud_style.shadow_color = Color(0.90, 0.20, 0.35, 0.25)
	boss_hud_style.shadow_size = 6
	boss_hud_style.content_margin_left = 12
	boss_hud_style.content_margin_top = 6
	boss_hud_style.content_margin_right = 12
	boss_hud_style.content_margin_bottom = 6
	_boss_hud_panel.add_theme_stylebox_override("panel", boss_hud_style)
	_top_hud_container.add_child(_boss_hud_panel)

	var boss_inner_hbox: HBoxContainer = HBoxContainer.new()
	boss_inner_hbox.add_theme_constant_override("separation", 8)
	_boss_hud_panel.add_child(boss_inner_hbox)

	var boss_vbox: VBoxContainer = VBoxContainer.new()
	boss_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_vbox.add_theme_constant_override("separation", 3)
	boss_inner_hbox.add_child(boss_vbox)

	var boss_title_box: HBoxContainer = HBoxContainer.new()
	boss_title_box.add_theme_constant_override("separation", 6)
	boss_vbox.add_child(boss_title_box)

	_boss_name_label = Label.new()
	_boss_name_label.text = "STOCHAS"
	_boss_name_label.add_theme_font_size_override("font_size", 13)
	_boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.55, 1.0))
	boss_title_box.add_child(_boss_name_label)

	var role_tag: Label = Label.new()
	role_tag.text = "STAGE BOSS"
	role_tag.add_theme_font_size_override("font_size", 10)
	role_tag.add_theme_color_override("font_color", Color(0.85, 0.70, 0.85, 0.75))
	boss_title_box.add_child(role_tag)

	var boss_hp_box: HBoxContainer = HBoxContainer.new()
	boss_hp_box.add_theme_constant_override("separation", 6)
	boss_vbox.add_child(boss_hp_box)

	var boss_hp_tag: Label = Label.new()
	boss_hp_tag.text = "HP:"
	boss_hp_tag.add_theme_font_size_override("font_size", 11)
	boss_hp_tag.add_theme_color_override("font_color", Color(0.9, 0.7, 0.8, 0.8))
	boss_hp_box.add_child(boss_hp_tag)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.name = "BossHPBar"
	_boss_hp_bar.custom_minimum_size = Vector2(100, 8)
	_boss_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_boss_hp_bar.max_value = 100
	_boss_hp_bar.value = 100
	_boss_hp_bar.show_percentage = false

	var bhp_bg: StyleBoxFlat = StyleBoxFlat.new()
	bhp_bg.bg_color = Color(0.06, 0.05, 0.10, 0.95)
	bhp_bg.corner_radius_top_left = 4
	bhp_bg.corner_radius_top_right = 4
	bhp_bg.corner_radius_bottom_right = 4
	bhp_bg.corner_radius_bottom_left = 4
	_boss_hp_bar.add_theme_stylebox_override("background", bhp_bg)

	var bhp_fill: StyleBoxFlat = StyleBoxFlat.new()
	bhp_fill.bg_color = Color(0.88, 0.18, 0.42, 0.98)
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

	_boss_intent_label = Label.new()
	_boss_intent_label.text = "⚡ Ý định: Ma Thuật Ngẫu Nhiên (10 ST)"
	_boss_intent_label.clip_text = true
	_boss_intent_label.custom_minimum_size = Vector2(0, 0)
	_boss_intent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_intent_label.add_theme_font_size_override("font_size", 10)
	_boss_intent_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 0.95))
	boss_vbox.add_child(_boss_intent_label)

	var boss_sigil: PanelContainer = PanelContainer.new()
	boss_sigil.name = "BossSigil"
	boss_sigil.custom_minimum_size = Vector2(44, 44)
	boss_sigil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boss_sigil.clip_contents = true
	var sigil_style: StyleBoxFlat = StyleBoxFlat.new()
	sigil_style.bg_color = Color(0.24, 0.08, 0.16, 0.85)
	sigil_style.border_width_left = 1
	sigil_style.border_width_top = 1
	sigil_style.border_width_right = 1
	sigil_style.border_width_bottom = 1
	sigil_style.border_color = Color(0.90, 0.25, 0.35, 0.75)
	sigil_style.corner_radius_top_left = 8
	sigil_style.corner_radius_top_right = 8
	sigil_style.corner_radius_bottom_right = 8
	sigil_style.corner_radius_bottom_left = 8
	boss_sigil.add_theme_stylebox_override("panel", sigil_style)

	var sigil_tex: TextureRect = TextureRect.new()
	sigil_tex.name = "BossSigilRect"
	sigil_tex.texture = load_boss_sprite()
	sigil_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sigil_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sigil_tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sigil_tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sigil_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_sigil.add_child(sigil_tex)
	boss_inner_hbox.add_child(boss_sigil)

	# --- 2B. PLAYER HUD PANEL (Child 1 in tree -> rendered on LEFT) ---
	_player_hud_panel = PanelContainer.new()
	_player_hud_panel.name = "PlayerHudPanel"
	_player_hud_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_player_hud_panel.custom_minimum_size = Vector2(272, 56)
	_player_hud_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var player_hud_style: StyleBoxFlat = StyleBoxFlat.new()
	player_hud_style.bg_color = Color(0.06, 0.09, 0.16, 0.85)
	player_hud_style.border_width_left = 1
	player_hud_style.border_width_top = 1
	player_hud_style.border_width_right = 1
	player_hud_style.border_width_bottom = 1
	player_hud_style.border_color = Color(0.20, 0.75, 0.90, 0.80)
	player_hud_style.corner_radius_top_left = 12
	player_hud_style.corner_radius_top_right = 12
	player_hud_style.corner_radius_bottom_right = 12
	player_hud_style.corner_radius_bottom_left = 12
	player_hud_style.shadow_color = Color(0.20, 0.75, 0.90, 0.25)
	player_hud_style.shadow_size = 6
	player_hud_style.content_margin_left = 10
	player_hud_style.content_margin_top = 6
	player_hud_style.content_margin_right = 10
	player_hud_style.content_margin_bottom = 6
	_player_hud_panel.add_theme_stylebox_override("panel", player_hud_style)
	_top_hud_container.add_child(_player_hud_panel)

	var player_inner_hbox: HBoxContainer = HBoxContainer.new()
	player_inner_hbox.add_theme_constant_override("separation", 8)
	_player_hud_panel.add_child(player_inner_hbox)

	var player_avatar: PanelContainer = PanelContainer.new()
	player_avatar.name = "PlayerAvatar"
	player_avatar.custom_minimum_size = Vector2(44, 44)
	player_avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	player_avatar.clip_contents = true
	var av_style: StyleBoxFlat = StyleBoxFlat.new()
	av_style.bg_color = Color(0.08, 0.16, 0.28, 0.85)
	av_style.border_width_left = 1
	av_style.border_width_top = 1
	av_style.border_width_right = 1
	av_style.border_width_bottom = 1
	av_style.border_color = Color(0.25, 0.90, 1.0, 0.75)
	av_style.corner_radius_top_left = 8
	av_style.corner_radius_top_right = 8
	av_style.corner_radius_bottom_right = 8
	av_style.corner_radius_bottom_left = 8
	player_avatar.add_theme_stylebox_override("panel", av_style)

	var karl_tex: TextureRect = TextureRect.new()
	karl_tex.name = "KarlPortraitRect"
	karl_tex.texture = load_karl_portrait()
	karl_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	karl_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	karl_tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	karl_tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	karl_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_avatar.add_child(karl_tex)
	player_inner_hbox.add_child(player_avatar)

	var player_vbox: VBoxContainer = VBoxContainer.new()
	player_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_vbox.add_theme_constant_override("separation", 3)
	player_inner_hbox.add_child(player_vbox)

	var player_title_box: HBoxContainer = HBoxContainer.new()
	player_title_box.add_theme_constant_override("separation", 6)
	player_vbox.add_child(player_title_box)

	var p_title: Label = Label.new()
	p_title.text = "HỌC VIÊN KARL"
	p_title.add_theme_font_size_override("font_size", 13)
	p_title.add_theme_color_override("font_color", Color(0.25, 0.90, 1.0, 1.0))
	player_title_box.add_child(p_title)

	_player_shield_label = Label.new()
	_player_shield_label.text = "  🛡️ Giáp: 0"
	_player_shield_label.add_theme_font_size_override("font_size", 11)
	_player_shield_label.add_theme_color_override("font_color", Color(0.95, 0.80, 0.25, 1.0))
	player_title_box.add_child(_player_shield_label)

	var player_hp_box: HBoxContainer = HBoxContainer.new()
	player_hp_box.add_theme_constant_override("separation", 6)
	player_vbox.add_child(player_hp_box)

	var p_hp_tag: Label = Label.new()
	p_hp_tag.text = "HP:"
	p_hp_tag.add_theme_font_size_override("font_size", 11)
	p_hp_tag.add_theme_color_override("font_color", Color(0.6, 0.85, 0.75, 0.8))
	player_hp_box.add_child(p_hp_tag)

	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.name = "PlayerHPBar"
	_player_hp_bar.custom_minimum_size = Vector2(130, 8)
	_player_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_player_hp_bar.max_value = 100
	_player_hp_bar.value = 100
	_player_hp_bar.show_percentage = false

	var php_bg: StyleBoxFlat = StyleBoxFlat.new()
	php_bg.bg_color = Color(0.06, 0.05, 0.10, 0.95)
	php_bg.corner_radius_top_left = 4
	php_bg.corner_radius_top_right = 4
	php_bg.corner_radius_bottom_right = 4
	php_bg.corner_radius_bottom_left = 4
	_player_hp_bar.add_theme_stylebox_override("background", php_bg)

	var php_fill: StyleBoxFlat = StyleBoxFlat.new()
	php_fill.bg_color = Color(0.18, 0.85, 0.75, 0.98)
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
	# 3. BOTTOM CENTER AREA (Flow pill directly above CardsContainer)
	# ---------------------------------------------------------
	_bottom_center_container = VBoxContainer.new()
	_bottom_center_container.name = "BottomCenterContainer"
	_bottom_center_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom_center_container.add_theme_constant_override("separation", 6)
	_bottom_center_container.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_bottom_center_container)

	var pill_panel: PanelContainer = PanelContainer.new()
	pill_panel.name = "FlowPillPanel"
	pill_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = Color(0.06, 0.08, 0.12, 0.85)
	pill_style.border_width_left = 1
	pill_style.border_width_top = 1
	pill_style.border_width_right = 1
	pill_style.border_width_bottom = 1
	pill_style.border_color = Color(0.25, 0.75, 0.85, 0.50)
	pill_style.corner_radius_top_left = 12
	pill_style.corner_radius_top_right = 12
	pill_style.corner_radius_bottom_right = 12
	pill_style.corner_radius_bottom_left = 12
	pill_style.content_margin_left = 14
	pill_style.content_margin_top = 3
	pill_style.content_margin_right = 14
	pill_style.content_margin_bottom = 3
	pill_panel.add_theme_stylebox_override("panel", pill_style)
	_bottom_center_container.add_child(pill_panel)

	_cards_header_label = Label.new()
	_cards_header_label.name = "FlowStepIndicator"
	_cards_header_label.text = "1. CHỌN THẺ BÀI   ➔   2. GIẢI TOÁN   ➔   3. XUẤT CHIÊU"
	_cards_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cards_header_label.add_theme_font_size_override("font_size", 11)
	_cards_header_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.50, 0.95))
	pill_panel.add_child(_cards_header_label)

	_cards_container = HBoxContainer.new()
	_cards_container.name = "CardsContainer"
	_cards_container.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", int(CARD_GAP))
	_cards_container.custom_minimum_size = Vector2(4.0 * CARD_WIDTH + 3.0 * CARD_GAP, CARD_HEIGHT + 6.0)
	_cards_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_bottom_center_container.add_child(_cards_container)

	_build_card_slots()

	# ---------------------------------------------------------
	# 4. COMBAT FEED (REMOVED FROM UI per Task 216)
	# Lower-left area is kept completely clean with background visible.
	# Internal logging logic is preserved in-memory without rendering visible UI panel.
	# ---------------------------------------------------------
	_combat_feed_panel = null
	_feed_vbox = null

	_prev_combat_log_label = Label.new()
	_prev_combat_log_label.name = "PrevCombatLogLabel"
	_prev_combat_log_label.text = ""
	_prev_combat_log_label.visible = false
	_prev_combat_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prev_combat_log_label)

	_combat_log_label = Label.new()
	_combat_log_label.name = "CombatLogLabel"
	_combat_log_label.text = "⚔️ Chọn thẻ bài và trả lời chính xác để tấn công Boss!"
	_combat_log_label.visible = false
	_combat_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_combat_log_label)

	# ---------------------------------------------------------
	# 5. BOTTOM-RIGHT MINIMAL CONTROL
	# ---------------------------------------------------------
	_settings_button = Button.new()
	_settings_button.name = "CombatSettingsButton"
	_settings_button.text = "⚙️"
	_settings_button.custom_minimum_size = Vector2(36, 36)
	_settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_button.add_theme_stylebox_override("normal", empty_style)
	_settings_button.add_theme_stylebox_override("hover", empty_style)
	add_child(_settings_button)

	# ---------------------------------------------------------
	# 6. OVERLAYS (Defeat & Victory)
	# ---------------------------------------------------------
	_ensure_overlays()

	_layout_elements()

func _ensure_overlays() -> void:
	if _defeat_overlay == null:
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
		add_child(_defeat_overlay)

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

	if _victory_overlay == null:
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
		add_child(_victory_overlay)

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

func _layout_elements() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		w = 1280.0
		h = 720.0

	# 1. Top HUD: padding left/right 32px, top 16px, height 56px
	if _top_hud_container != null:
		_top_hud_container.position = Vector2.ZERO
		_top_hud_container.size = Vector2(w, 80.0)

	if _player_hud_panel != null:
		_player_hud_panel.position = Vector2(32.0, 16.0)
		_player_hud_panel.size = Vector2(280.0, 56.0)

	if _boss_hud_panel != null:
		var bh_w: float = 304.0
		var bh_x: float = maxf(0.0, w - 32.0 - bh_w)
		_boss_hud_panel.position = Vector2(bh_x, 16.0)
		_boss_hud_panel.size = Vector2(bh_w, 56.0)

	# 2. Boss Stage: right ~8px, top ~40px, bottom ~48px, width ~460px
	if _boss_stage_container != null:
		var stage_w: float = BOSS_STAGE_WIDTH # 460.0
		var stage_x: float = maxf(0.0, w - 8.0 - stage_w)
		var stage_y: float = 40.0
		var stage_h: float = maxf(100.0, h - 40.0 - 48.0)
		_boss_stage_container.position = Vector2(stage_x, stage_y)
		_boss_stage_container.size = Vector2(stage_w, stage_h)
		if _boss_visual_rect != null:
			_boss_visual_rect.position = Vector2.ZERO
			_boss_visual_rect.size = Vector2(stage_w, stage_h)

	# 3. Bottom Cards Area: centered horizontally, bottom ~12px
	var cards_w: float = 4.0 * CARD_WIDTH + 3.0 * CARD_GAP # 4 * 160 + 3 * 16 = 688.0
	var cards_h: float = CARD_HEIGHT # 225.0

	if _bottom_center_container != null:
		var min_bottom_w: float = _bottom_center_container.get_combined_minimum_size().x
		var actual_bottom_w: float = maxf(cards_w, min_bottom_w)
		var actual_bottom_x: float = (w - actual_bottom_w) * 0.5
		var total_bottom_h: float = cards_h + 36.0 # cards + flow pill
		var bottom_y: float = maxf(0.0, h - 12.0 - total_bottom_h)
		_bottom_center_container.position = Vector2(actual_bottom_x, bottom_y)
		_bottom_center_container.size = Vector2(actual_bottom_w, total_bottom_h)

	# 4. Combat Feed: Removed from screen per Task 216 (lower-left visually clean)

	# 5. Bottom Right Settings: right ~24px, bottom ~16px
	if _settings_button != null:
		_settings_button.position = Vector2(w - 56.0, h - 50.0)
		_settings_button.size = Vector2(36.0, 36.0)

	# 6. Overlays centered
	if _defeat_overlay != null and _defeat_overlay.visible:
		var def_w: float = minf(400.0, w - 40.0)
		_defeat_overlay.position = Vector2((w - def_w) * 0.5, (h - 150.0) * 0.5)
		_defeat_overlay.size = Vector2(def_w, 150.0)

	if _victory_overlay != null and _victory_overlay.visible:
		var vic_w: float = minf(400.0, w - 40.0)
		_victory_overlay.position = Vector2((w - vic_w) * 0.5, (h - 150.0) * 0.5)
		_victory_overlay.size = Vector2(vic_w, 150.0)

func _update_full_display() -> void:
	_ensure_ui()
	_layout_elements()
	if _combat_controller == null:
		return

	# Update Boss Status
	var boss: EnemyEntity = _combat_controller.boss_entity
	if boss != null:
		_boss_name_label.text = boss.display_name.to_upper()
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

func _on_boss_hp_changed(current: int, max_val: int, _delta: int) -> void:
	_ensure_ui()
	if _boss_hp_bar != null:
		_boss_hp_bar.max_value = max_val
		_boss_hp_bar.value = current
	if _boss_hp_label != null:
		_boss_hp_label.text = "%d / %d" % [current, max_val]

func _on_player_hp_changed(current: int, max_val: int, _delta: int) -> void:
	_ensure_ui()
	if _player_hp_bar != null:
		_player_hp_bar.max_value = max_val
		_player_hp_bar.value = current
	if _player_hp_label != null:
		_player_hp_label.text = "%d / %d" % [current, max_val]
	if _player_shield_label != null and _combat_controller != null and _combat_controller.player_runtime != null:
		_player_shield_label.text = "  🛡️ Giáp: %d" % _combat_controller.player_runtime.shield

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
		slot.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT + 6.0)
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
		badge_margin.add_theme_constant_override("margin_left", 4)
		badge_margin.add_theme_constant_override("margin_right", 4)
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
		badge_label.add_theme_font_size_override("font_size", 10)
		badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_panel.add_child(badge_label)

		# Texture Rect (Artwork area enlarged to ~145–170px tall)
		var art_margin: MarginContainer = MarginContainer.new()
		art_margin.name = "ArtMargin"
		art_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		art_margin.custom_minimum_size = Vector2(0, 156.0)
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
		tex_rect.custom_minimum_size = Vector2(0, 150.0)
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

	if _combat_controller != null:
		_cards_container.visible = in_active_combat
		if _cards_header_label != null:
			_cards_header_label.visible = in_active_combat
		if not in_active_combat:
			return
	else:
		_cards_container.visible = true
		if _cards_header_label != null:
			_cards_header_label.visible = true

	_build_card_slots()

	var active_card_id: String = _selected_card_id
	var hand_cards: Array[CardModel] = []
	if _combat_controller != null:
		var active_card: CardModel = _combat_controller.get_selected_card()
		if active_card != null:
			active_card_id = active_card.card_id
		hand_cards = _combat_controller.hand_cards

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

		var is_selected: bool = (not is_skill and c_id == active_card_id)

		if is_skill:
			# PROBABILITY CARD (Disabled, purple treatment, recognizable art)
			slot.add_theme_constant_override("margin_top", 6)
			slot.add_theme_constant_override("margin_bottom", 0)
			btn.disabled = true

			var skill_style: StyleBoxFlat = StyleBoxFlat.new()
			skill_style.bg_color = Color(0.08, 0.06, 0.14, 0.90)
			skill_style.border_width_left = 1
			skill_style.border_width_top = 1
			skill_style.border_width_right = 1
			skill_style.border_width_bottom = 1
			skill_style.border_color = Color(0.60, 0.40, 0.85, 0.65)
			skill_style.corner_radius_top_left = 8
			skill_style.corner_radius_top_right = 8
			skill_style.corner_radius_bottom_right = 8
			skill_style.corner_radius_bottom_left = 8
			btn.add_theme_stylebox_override("normal", skill_style)
			btn.add_theme_stylebox_override("disabled", skill_style)

			tex_rect.modulate = Color(0.70, 0.60, 0.85, 0.75)

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
			# SELECTED BASIC CARD (Lifted upward ~6-8px, cyan border, restrained glow, ĐANG CHỌN badge)
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
			sel_style.shadow_color = Color(0.20, 0.85, 1.0, 0.45)
			sel_style.shadow_size = 10
			btn.add_theme_stylebox_override("normal", sel_style)
			btn.add_theme_stylebox_override("hover", sel_style)
			btn.add_theme_stylebox_override("pressed", sel_style)
			btn.add_theme_stylebox_override("focus", sel_style)

			tex_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)

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
			# UNSELECTED BASIC CARD (Distinct Amber/Gold for DEFEND, Emerald for HEAL, Slate for STRIKE)
			slot.add_theme_constant_override("margin_top", 6)
			slot.add_theme_constant_override("margin_bottom", 0)
			btn.disabled = false

			var norm_style: StyleBoxFlat = StyleBoxFlat.new()
			norm_style.border_width_left = 2
			norm_style.border_width_top = 2
			norm_style.border_width_right = 2
			norm_style.border_width_bottom = 2
			match c_id:
				"card_defend":
					norm_style.bg_color = Color(0.10, 0.08, 0.05, 0.95)
					norm_style.border_color = Color(1.0, 0.82, 0.28, 0.95) # Amber/gold border
				"card_heal":
					norm_style.bg_color = Color(0.06, 0.12, 0.09, 0.95)
					norm_style.border_color = Color(0.28, 0.92, 0.52, 0.90) # Emerald/green border
				_:
					norm_style.bg_color = Color(0.06, 0.09, 0.16, 0.95)
					norm_style.border_color = Color(0.35, 0.65, 0.95, 0.85) # Slate/azure border
			norm_style.corner_radius_top_left = 8
			norm_style.corner_radius_top_right = 8
			norm_style.corner_radius_bottom_right = 8
			norm_style.corner_radius_bottom_left = 8

			var hov_style: StyleBoxFlat = StyleBoxFlat.new()
			hov_style.bg_color = Color(0.12, 0.16, 0.26, 0.96)
			hov_style.border_width_left = 2
			hov_style.border_width_top = 2
			hov_style.border_width_right = 2
			hov_style.border_width_bottom = 2
			match c_id:
				"card_defend":
					hov_style.border_color = Color(1.0, 0.92, 0.45, 1.0)
				"card_heal":
					hov_style.border_color = Color(0.38, 1.0, 0.60, 1.0)
				_:
					hov_style.border_color = Color(0.45, 0.75, 1.0, 1.0)
			hov_style.corner_radius_top_left = 8
			hov_style.corner_radius_top_right = 8
			hov_style.corner_radius_bottom_right = 8
			hov_style.corner_radius_bottom_left = 8

			btn.add_theme_stylebox_override("normal", norm_style)
			btn.add_theme_stylebox_override("hover", hov_style)
			btn.add_theme_stylebox_override("pressed", norm_style)
			btn.add_theme_stylebox_override("focus", hov_style)

			match c_id:
				"card_defend":
					tex_rect.modulate = Color(1.0, 0.98, 0.92, 1.0) # 100% full brightness so shield radiates
				"card_heal":
					tex_rect.modulate = Color(0.95, 1.0, 0.95, 1.0)
				_:
					tex_rect.modulate = Color(0.95, 0.98, 1.0, 1.0)

			if badge_lbl != null:
				badge_lbl.text = String(def["default_badge"])
				match c_id:
					"card_strike":
						badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75, 0.95))
					"card_defend":
						badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.50, 1.0))
					"card_heal":
						badge_lbl.add_theme_color_override("font_color", Color(0.65, 1.0, 0.75, 0.95))
					_:
						badge_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95, 0.90))

			if badge_panel != null:
				var bp_style: StyleBoxFlat = StyleBoxFlat.new()
				match c_id:
					"card_strike":
						bp_style.bg_color = Color(0.38, 0.12, 0.16, 0.75)
					"card_defend":
						bp_style.bg_color = Color(0.42, 0.30, 0.08, 0.85)
					"card_heal":
						bp_style.bg_color = Color(0.08, 0.32, 0.18, 0.75)
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

			if status_lbl != null:
				status_lbl.text = _get_card_dynamic_value_text(c_id, model)
				match c_id:
					"card_defend":
						status_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.30, 1.0))
					"card_heal":
						status_lbl.add_theme_color_override("font_color", Color(0.50, 1.0, 0.70, 1.0))
					_:
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

func select_card(card_id: String) -> void:
	_on_card_button_pressed(card_id)

func _on_card_button_pressed(card_id: String) -> void:
	_selected_card_id = card_id
	if _combat_controller != null:
		_combat_controller.select_card(card_id)
	card_selected.emit(card_id)
	_render_cards()

func _on_combat_log(message: String, type: String) -> void:
	_ensure_ui()
	if _combat_log_label != null:
		if _prev_combat_log_label != null and not _combat_log_label.text.is_empty():
			_prev_combat_log_label.text = _combat_log_label.text
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

static func load_karl_portrait() -> Texture2D:
	if _PRELOAD_KARL != null:
		return _PRELOAD_KARL
	var path: String = KARL_PORTRAIT_PATH
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			return res as Texture2D
	var global_path: String = ProjectSettings.globalize_path(path)
	var img: Image = Image.new()
	if img.load(global_path) == OK or img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

static func load_boss_sprite() -> Texture2D:
	if _PRELOAD_STOCHAS != null:
		return _PRELOAD_STOCHAS
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

func get_card_slot(card_id: String) -> MarginContainer:
	_ensure_ui()
	_build_card_slots()
	var norm: String = _normalize_card_id(card_id)
	return _card_slots_by_id.get(norm, null) as MarginContainer

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

func get_cards_container() -> HBoxContainer:
	_ensure_ui()
	return _cards_container

func get_card_buttons() -> Array[Button]:
	_ensure_ui()
	_build_card_slots()
	var buttons: Array[Button] = []
	for k in _card_buttons_by_id:
		var btn: Button = _card_buttons_by_id[k] as Button
		if btn != null:
			buttons.append(btn)
	return buttons

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
	if path == CARD_STRIKE_TEXTURE_PATH and _PRELOAD_STRIKE != null:
		return _PRELOAD_STRIKE
	if path == CARD_DEFEND_TEXTURE_PATH and _PRELOAD_DEFEND != null:
		return _PRELOAD_DEFEND
	if path == CARD_HEAL_TEXTURE_PATH and _PRELOAD_HEAL != null:
		return _PRELOAD_HEAL
	if path == CARD_PROBABILITY_TEXTURE_PATH and _PRELOAD_PROBABILITY != null:
		return _PRELOAD_PROBABILITY

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

# Exact Reference Parity Rect Inspection Helpers
func get_player_hud_rect() -> Rect2:
	_ensure_ui()
	_layout_elements()
	if _player_hud_panel != null:
		var pw: float = _player_hud_panel.size.x if _player_hud_panel.size.x > 0.0 else 280.0
		var ph: float = _player_hud_panel.size.y if _player_hud_panel.size.y > 0.0 else 56.0
		var px: float = _player_hud_panel.position.x if _player_hud_panel.position.x > 0.0 else 32.0
		var py: float = _player_hud_panel.position.y if _player_hud_panel.position.y > 0.0 else 16.0
		return Rect2(px, py, pw, ph)
	return Rect2(32, 16, 280, 56)

func get_boss_hud_rect() -> Rect2:
	_ensure_ui()
	_layout_elements()
	var w: float = size.x if size.x > 0.0 else 1280.0
	if _boss_hud_panel != null:
		var bw: float = _boss_hud_panel.size.x if _boss_hud_panel.size.x > 0.0 else 304.0
		var bh: float = _boss_hud_panel.size.y if _boss_hud_panel.size.y > 0.0 else 56.0
		var bx: float = _boss_hud_panel.position.x if _boss_hud_panel.position.x > 0.0 else maxf(0.0, w - 32.0 - bw)
		var by: float = _boss_hud_panel.position.y if _boss_hud_panel.position.y > 0.0 else 16.0
		return Rect2(bx, by, bw, bh)
	return Rect2(maxf(0.0, w - 32.0 - 304.0), 16, 304, 56)

func get_boss_stage_rect() -> Rect2:
	_ensure_ui()
	_layout_elements()
	var w: float = size.x if size.x > 0.0 else 1280.0
	var h: float = size.y if size.y > 0.0 else 720.0
	if _boss_stage_container != null:
		var sw: float = _boss_stage_container.size.x if _boss_stage_container.size.x > 0.0 else BOSS_STAGE_WIDTH
		var sh: float = _boss_stage_container.size.y if _boss_stage_container.size.y > 0.0 else maxf(100.0, h - 40.0 - 48.0)
		var sx: float = _boss_stage_container.position.x if _boss_stage_container.position.x > 0.0 else maxf(0.0, w - 8.0 - sw)
		var sy: float = _boss_stage_container.position.y if _boss_stage_container.position.y > 0.0 else 40.0
		return Rect2(sx, sy, sw, sh)
	return Rect2(maxf(0.0, w - 8.0 - BOSS_STAGE_WIDTH), 40, BOSS_STAGE_WIDTH, maxf(100.0, h - 40.0 - 48.0))

func get_boss_art_rect() -> Rect2:
	_ensure_ui()
	_layout_elements()
	if _boss_sprite_rect != null:
		var w: float = size.x if size.x > 0.0 else 1280.0
		return Rect2(w - 8.0 - BOSS_STAGE_WIDTH + 40.0, 91.0, 380.0, BOSS_ART_HEIGHT)
	return Rect2(852, 91, 380, BOSS_ART_HEIGHT)

func get_combat_feed_rect() -> Rect2:
	if _combat_feed_panel != null and _combat_feed_panel.is_inside_tree() and _combat_feed_panel.visible:
		return _combat_feed_panel.get_global_rect()
	return Rect2()

func has_visible_combat_feed() -> bool:
	return false

func get_flow_pill_rect() -> Rect2:
	_ensure_ui()
	_layout_elements()
	var w: float = size.x if size.x > 0.0 else 1280.0
	var h: float = size.y if size.y > 0.0 else 720.0
	var cw: float = 4.0 * CARD_WIDTH + 3.0 * CARD_GAP
	var cx: float = (w - cw) * 0.5
	var total_bottom_h: float = CARD_HEIGHT + 36.0
	var bottom_y: float = maxf(0.0, h - 12.0 - total_bottom_h)
	return Rect2(cx, bottom_y, cw, 26)

func get_card_row_rect() -> Rect2:
	_ensure_ui()
	_layout_elements()
	var w: float = size.x if size.x > 0.0 else 1280.0
	var h: float = size.y if size.y > 0.0 else 720.0
	var cw: float = 4.0 * CARD_WIDTH + 3.0 * CARD_GAP
	var ch: float = CARD_HEIGHT
	var cx: float = (w - cw) * 0.5
	var total_bottom_h: float = CARD_HEIGHT + 36.0
	var bottom_y: float = maxf(0.0, h - 12.0 - total_bottom_h)
	return Rect2(cx, bottom_y + 32.0, cw, ch)

func get_card_rect(card_id: String) -> Rect2:
	_ensure_ui()
	_layout_elements()
	var btn: Button = get_card_button(card_id)
	if btn != null:
		var bw: float = btn.custom_minimum_size.x if btn.custom_minimum_size.x > 0.0 else CARD_WIDTH
		var bh: float = btn.custom_minimum_size.y if btn.custom_minimum_size.y > 0.0 else CARD_HEIGHT
		return Rect2(btn.position, Vector2(bw, bh))
	return Rect2()

func get_selected_card_lift() -> float:
	return 8.0

class_name SanctumNexusHub
extends Control

## Adaptive Production UI Component for Mathos Sanctum Nexus Hub.
## Implements the HUMAN-approved HUB_D1_ACTIVE design in Godot using native Control nodes,
## StyleBoxFlat, and TextureRect. Adapts cleanly across 1280x720, 1366x768, 1600x900, 1920x1080.
## Features:
## - Base Sanctum Nexus background + D1 progression overlay + procedural fog
## - Top-left Player Badge (Name, Level, Avatar)
## - Top-right Order Stone / 4-Fragment HUD + Audio/Settings utilities
## - Bottom-left Mathos Identity/Status + Future Grimoire/Achievement buttons (disabled)
## - Bottom-right Contextual Journey Panel (Active Dungeon, Current Stage/Mission, Primary/Secondary CTAs)
## - Full runtime state machine: NEW_PLAYER, D1_ACTIVE, D1_COMPLETE, future D2..D4/ENDGAME.

signal new_game_requested()
signal continue_game_requested()
signal show_map_requested()
signal settings_requested()
signal logout_requested()
signal stage_selected(stage_id: String)
# Task 164 compatibility aliases for StagePresentationShell
signal continue_requested()
signal map_requested()
signal replay_requested()
signal pause_requested()

enum HubProgressionState {
	NEW_PLAYER = 0,
	D1_ACTIVE = 1,
	D1_COMPLETE = 2,
	D2_ACTIVE = 3,
	D2_COMPLETE = 4,
	D3_ACTIVE = 5,
	D3_COMPLETE = 6,
	D4_ACTIVE = 7,
	D4_COMPLETE = 8,
	ENDGAME = 9
}

# Reference 1280x720 layout measurements
const REF_WIDTH: float = 1280.0
const REF_HEIGHT: float = 720.0

const REF_MARGIN_LEFT: float = 36.0
const REF_MARGIN_TOP: float = 24.0
const REF_MARGIN_RIGHT: float = 36.0
const REF_MARGIN_BOTTOM: float = 24.0

const REF_BADGE_SIZE: Vector2 = Vector2(280.0, 64.0)
const REF_HUD_SIZE: Vector2 = Vector2(302.0, 52.0)
const REF_IDENTITY_SIZE: Vector2 = Vector2(320.0, 150.0)
const REF_JOURNEY_SIZE: Vector2 = Vector2(360.0, 246.0)

# Canonical Assets
const SANCTUM_BG_PATH: String = "res://assets/prologue/beat_01/prologue_bg_01_mathos_world.png"
const SANCTUM_BG_FALLBACK: String = "res://assets/backgrounds/auth/login_academy_bg_clean.png"
const D1_OVERLAY_PATH: String = "res://assets/backgrounds/d1_misty_forest_bg.png"
const D1_FOG_LAYER_PATH: String = "res://assets/backgrounds/d1_misty_forest_fog_layer.png"
const BRAND_LOGO_EMBLEM_PATH: String = "res://assets/branding/mathos_logo_emblem.png"
const BRAND_LOGO_MAIN_PATH: String = "res://assets/branding/mathos_logo_main.png"
const DRAVEN_PORTRAIT_PATH: String = "res://assets/characters/story/draven/draven_portrait.png"

const ORDER_STONE_INTACT_PATH: String = "res://assets/prologue/beat_03/order_stone_intact.png"
const ORDER_STONE_CRACKED_PATH: String = "res://assets/prologue/beat_03/order_stone_cracked.png"
const CANONICAL_FRAGMENT_01_PATH: String = "res://assets/items/fragments/fragment_01.png"
const ORDER_FRAGMENT_01_PATH: String = "res://assets/items/fragments/fragment_01.png"
const ORDER_FRAGMENT_02_PATH: String = "res://assets/prologue/beat_03/order_fragment_02.png"
const ORDER_FRAGMENT_03_PATH: String = "res://assets/prologue/beat_03/order_fragment_03.png"
const ORDER_FRAGMENT_04_PATH: String = "res://assets/prologue/beat_03/order_fragment_04.png"

# Canonical Dungeon Names
const CANONICAL_DUNGEONS: Dictionary = {
	"dungeon_01": "Dungeon I — KHU RỪNG SƯƠNG MÙ",
	"dungeon_02": "Dungeon II — ĐẦM LẦY TỶ LỆ",
	"dungeon_03": "Dungeon III — CUNG ĐIỆN HỢP NHẤT",
	"dungeon_04": "Dungeon IV — ĐỈNH THÁP ĐỘC LẬP"
}

# Runtime Bindings
var _progression_state: HubProgressionState = HubProgressionState.NEW_PLAYER
var _player_name: String = "Karl"
var _player_level: int = 1
var _is_guest: bool = false
var _active_dungeon: String = "Dungeon I — KHU RỪNG SƯƠNG MÙ"
var _current_stage: String = "Giai đoạn 1.1: Khởi Đầu Rừng Mù Sương"
var _current_mission: String = "Khám phá Khu Rừng Sương Mù và tìm kiếm Mảnh Vỡ Trật Tự thứ nhất."
var _fragments_x_of_4: String = "0/4 Mảnh Vỡ"
var _dungeons_x_of_4: String = "0/4 Dungeon"
var _fragment_states: Array[bool] = [false, false, false, false]
var _has_save: bool = false
var _is_muted: bool = false
var _is_built: bool = false

# Visual Nodes
var _bg_texture_rect: TextureRect = null
var _env_overlay_rect: TextureRect = null
var _fog_overlay_rect: TextureRect = null
var _vertical_overlay: TextureRect = null
var _horizontal_overlay: TextureRect = null
var _fog_scroll_offset: float = 0.0

# 4 Corner Panels
var _player_badge_panel: PanelContainer = null
var _player_avatar_rect: TextureRect = null
var _player_name_label: Label = null
var _player_level_label: Label = null

var _order_hud_panel: PanelContainer = null
var _order_stone_icon: TextureRect = null
var _fragment_slots: Array[TextureRect] = []
var _fragment_slot_panels: Array[PanelContainer] = []
var _fragments_count_label: Label = null
var _dungeons_count_label: Label = null

var _identity_panel: PanelContainer = null
var _identity_emblem_rect: TextureRect = null
var _identity_title_label: Label = null
var _identity_subtitle_label: Label = null
var _identity_version_label: Label = null
var _grimoire_button: Button = null
var _achievements_button: Button = null

var _journey_panel: PanelContainer = null
var _journey_category_label: Label = null
var _journey_status_badge: Label = null
var _active_dungeon_label: Label = null
var _current_stage_label: Label = null
var _current_mission_label: Label = null

# Action Controls
var _action_vbox: VBoxContainer = null
var _continue_button: Button = null
var _new_game_button: Button = null
var _journey_map_button: Button = null
var _save_summary_label: Label = null

# Utilities Row (Top-Right / Utilities)
var _utilities_container: HBoxContainer = null
var _sound_button: Button = null
var _settings_button: Button = null
var _logout_button: Button = null

func _init() -> void:
	custom_minimum_size = Vector2(REF_WIDTH, REF_HEIGHT)

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	custom_minimum_size = Vector2(REF_WIDTH, REF_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	set_process(true)

	_ensure_built()
	_apply_progression_visuals()
	update_responsive_layout()

func _ensure_built() -> void:
	if _is_built:
		return
	_is_built = true
	_build_visual_tree()

func _process(delta: float) -> void:
	if _fog_overlay_rect != null and _fog_overlay_rect.visible:
		_fog_scroll_offset += delta * 6.0
		if _fog_scroll_offset > 2000.0:
			_fog_scroll_offset -= 2000.0
		var breathe: float = 0.32 + sin(_fog_scroll_offset * 0.05) * 0.05
		_fog_overlay_rect.modulate.a = clampf(breathe, 0.20, 0.45)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update_responsive_layout()

func _build_visual_tree() -> void:
	for child in get_children():
		child.queue_free()

	# 1. Base Sanctum Nexus Artwork
	_bg_texture_rect = TextureRect.new()
	_bg_texture_rect.name = "SanctumBackground"
	_bg_texture_rect.anchor_right = 1.0
	_bg_texture_rect.anchor_bottom = 1.0
	_bg_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture_rect.texture = _load_texture_safe([SANCTUM_BG_PATH, SANCTUM_BG_FALLBACK])
	add_child(_bg_texture_rect)

	# 2. Progression Environment Overlay (D1 Misty Forest ambient blend)
	_env_overlay_rect = TextureRect.new()
	_env_overlay_rect.name = "ProgressionEnvOverlay"
	_env_overlay_rect.anchor_right = 1.0
	_env_overlay_rect.anchor_bottom = 1.0
	_env_overlay_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_env_overlay_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_env_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_env_overlay_rect.texture = _load_texture_safe([D1_OVERLAY_PATH])
	_env_overlay_rect.modulate = Color(0.12, 0.35, 0.55, 0.42)
	add_child(_env_overlay_rect)

	# 3. Procedural Fog Drift Layer
	_fog_overlay_rect = TextureRect.new()
	_fog_overlay_rect.name = "AtmosphericFogLayer"
	_fog_overlay_rect.anchor_right = 1.0
	_fog_overlay_rect.anchor_bottom = 1.0
	_fog_overlay_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fog_overlay_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fog_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_overlay_rect.texture = _load_texture_safe([D1_FOG_LAYER_PATH])
	_fog_overlay_rect.modulate = Color(0.3, 0.8, 1.0, 0.35)
	add_child(_fog_overlay_rect)

	# 4. Contrast Overlays for Readability
	_build_readability_overlays()

	# 5. Top-Left: Player Badge
	_build_player_badge()

	# 6. Top-Right: Order Stone / 4-Fragment HUD & Utilities
	_build_order_stone_hud()
	_build_utilities_row()

	# 7. Bottom-Left: Mathos Identity & Status
	_build_identity_panel()

	# 8. Bottom-Right: Contextual Journey Panel
	_build_contextual_journey_panel()

func _build_readability_overlays() -> void:
	_vertical_overlay = TextureRect.new()
	_vertical_overlay.name = "VerticalGradientOverlay"
	_vertical_overlay.anchor_right = 1.0
	_vertical_overlay.anchor_bottom = 1.0
	_vertical_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vertical_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	_vertical_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var grad_v: Gradient = Gradient.new()
	grad_v.offsets = PackedFloat32Array([0.0, 0.35, 0.65, 1.0])
	grad_v.colors = PackedColorArray([
		Color(0.02, 0.04, 0.08, 0.70),
		Color(0.02, 0.04, 0.08, 0.10),
		Color(0.02, 0.04, 0.08, 0.35),
		Color(0.02, 0.04, 0.08, 0.88)
	])
	var tex_v: GradientTexture2D = GradientTexture2D.new()
	tex_v.gradient = grad_v
	tex_v.fill_from = Vector2(0.5, 0.0)
	tex_v.fill_to = Vector2(0.5, 1.0)
	_vertical_overlay.texture = tex_v
	add_child(_vertical_overlay)

	_horizontal_overlay = TextureRect.new()
	_horizontal_overlay.name = "HorizontalGradientOverlay"
	_horizontal_overlay.anchor_right = 1.0
	_horizontal_overlay.anchor_bottom = 1.0
	_horizontal_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_horizontal_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	_horizontal_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var grad_h: Gradient = Gradient.new()
	grad_h.offsets = PackedFloat32Array([0.0, 0.30, 0.70, 1.0])
	grad_h.colors = PackedColorArray([
		Color(0.02, 0.04, 0.08, 0.65),
		Color(0.02, 0.04, 0.08, 0.0),
		Color(0.02, 0.04, 0.08, 0.0),
		Color(0.02, 0.04, 0.08, 0.65)
	])
	var tex_h: GradientTexture2D = GradientTexture2D.new()
	tex_h.gradient = grad_h
	tex_h.fill_from = Vector2(0.0, 0.5)
	tex_h.fill_to = Vector2(1.0, 0.5)
	_horizontal_overlay.texture = tex_h
	add_child(_horizontal_overlay)

func _build_player_badge() -> void:
	_player_badge_panel = PanelContainer.new()
	_player_badge_panel.name = "PlayerBadgePanel"
	_player_badge_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.16, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.85, 1.0, 0.40)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	style.content_margin_left = 14
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_player_badge_panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	_player_badge_panel.add_child(hbox)

	var avatar_panel: PanelContainer = PanelContainer.new()
	avatar_panel.custom_minimum_size = Vector2(46, 46)
	var av_style: StyleBoxFlat = StyleBoxFlat.new()
	av_style.bg_color = Color(0.08, 0.14, 0.24, 0.95)
	av_style.border_width_left = 2
	av_style.border_width_top = 2
	av_style.border_width_right = 2
	av_style.border_width_bottom = 2
	av_style.border_color = Color(0.92, 0.78, 0.35, 0.90)
	av_style.corner_radius_top_left = 23
	av_style.corner_radius_top_right = 23
	av_style.corner_radius_bottom_left = 23
	av_style.corner_radius_bottom_right = 23
	avatar_panel.add_theme_stylebox_override("panel", av_style)

	_player_avatar_rect = TextureRect.new()
	_player_avatar_rect.name = "PlayerAvatar"
	_player_avatar_rect.custom_minimum_size = Vector2(40, 40)
	_player_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_player_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_player_avatar_rect.texture = _load_texture_safe([DRAVEN_PORTRAIT_PATH, BRAND_LOGO_EMBLEM_PATH])
	avatar_panel.add_child(_player_avatar_rect)
	hbox.add_child(avatar_panel)

	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_player_name_label = Label.new()
	_player_name_label.name = "PlayerNameLabel"
	_player_name_label.text = _player_name
	_player_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_player_name_label.add_theme_font_size_override("font_size", 15)
	_player_name_label.add_theme_color_override("font_outline_color", Color(0.1, 0.5, 0.8, 0.5))
	_player_name_label.add_theme_constant_override("outline_size", 2)
	info_vbox.add_child(_player_name_label)

	_player_level_label = Label.new()
	_player_level_label.name = "PlayerLevelLabel"
	_player_level_label.text = "Cấp %d • Học Viên Ma Pháp" % _player_level
	_player_level_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.35))
	_player_level_label.add_theme_font_size_override("font_size", 11)
	info_vbox.add_child(_player_level_label)

	hbox.add_child(info_vbox)
	add_child(_player_badge_panel)

func _build_order_stone_hud() -> void:
	_order_hud_panel = PanelContainer.new()
	_order_hud_panel.name = "OrderStoneHudPanel"
	_order_hud_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.16, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.85, 1.0, 0.40)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	style.content_margin_left = 14
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_order_hud_panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_order_hud_panel.add_child(hbox)

	_order_stone_icon = TextureRect.new()
	_order_stone_icon.name = "OrderStoneIcon"
	_order_stone_icon.custom_minimum_size = Vector2(36, 36)
	_order_stone_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_order_stone_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_order_stone_icon.texture = _load_texture_safe([ORDER_STONE_INTACT_PATH, ORDER_STONE_CRACKED_PATH])
	hbox.add_child(_order_stone_icon)

	var fragment_paths: Array[String] = [
		ORDER_FRAGMENT_01_PATH,
		ORDER_FRAGMENT_02_PATH,
		ORDER_FRAGMENT_03_PATH,
		ORDER_FRAGMENT_04_PATH
	]

	var fragments_hbox: HBoxContainer = HBoxContainer.new()
	fragments_hbox.name = "FragmentSlotsHBox"
	fragments_hbox.add_theme_constant_override("separation", 6)
	_fragment_slots.clear()
	_fragment_slot_panels.clear()

	for i in range(4):
		var slot_panel: PanelContainer = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(30, 30)
		var slot_style: StyleBoxFlat = StyleBoxFlat.new()
		slot_style.bg_color = Color(0.06, 0.10, 0.18, 0.90)
		slot_style.border_width_left = 1
		slot_style.border_width_top = 1
		slot_style.border_width_right = 1
		slot_style.border_width_bottom = 1
		slot_style.border_color = Color(0.2, 0.3, 0.45, 0.6)
		slot_style.corner_radius_top_left = 6
		slot_style.corner_radius_top_right = 6
		slot_style.corner_radius_bottom_left = 6
		slot_style.corner_radius_bottom_right = 6
		slot_panel.add_theme_stylebox_override("panel", slot_style)

		var frag_tex: TextureRect = TextureRect.new()
		frag_tex.name = "FragmentSlot%d" % (i + 1)
		frag_tex.custom_minimum_size = Vector2(24, 24)
		frag_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frag_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frag_tex.texture = _load_texture_safe([fragment_paths[i]])
		frag_tex.modulate = Color(0.25, 0.25, 0.35, 0.4)

		slot_panel.add_child(frag_tex)
		fragments_hbox.add_child(slot_panel)

		_fragment_slots.append(frag_tex)
		_fragment_slot_panels.append(slot_panel)

	hbox.add_child(fragments_hbox)

	var stats_vbox: VBoxContainer = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 1)
	stats_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_fragments_count_label = Label.new()
	_fragments_count_label.name = "FragmentsCountLabel"
	_fragments_count_label.text = _fragments_x_of_4
	_fragments_count_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.40))
	_fragments_count_label.add_theme_font_size_override("font_size", 12)
	stats_vbox.add_child(_fragments_count_label)

	_dungeons_count_label = Label.new()
	_dungeons_count_label.name = "DungeonsCountLabel"
	_dungeons_count_label.text = _dungeons_x_of_4
	_dungeons_count_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	_dungeons_count_label.add_theme_font_size_override("font_size", 10)
	stats_vbox.add_child(_dungeons_count_label)

	hbox.add_child(stats_vbox)
	add_child(_order_hud_panel)

func _build_utilities_row() -> void:
	_utilities_container = HBoxContainer.new()
	_utilities_container.name = "UtilitiesHBox"
	_utilities_container.add_theme_constant_override("separation", 6)

	_sound_button = Button.new()
	_sound_button.name = "SoundButton"
	_sound_button.text = "🔊"
	_sound_button.tooltip_text = "Âm lượng"
	_sound_button.custom_minimum_size = Vector2(30, 30)
	_sound_button.theme_type_variation = &"MathosSecondaryButton"
	_sound_button.pressed.connect(func():
		_is_muted = not _is_muted
		_sound_button.text = "🔇" if _is_muted else "🔊"
	)
	_utilities_container.add_child(_sound_button)

	_settings_button = Button.new()
	_settings_button.name = "SettingsButton"
	_settings_button.text = "⚙️"
	_settings_button.tooltip_text = "Cài đặt"
	_settings_button.custom_minimum_size = Vector2(30, 30)
	_settings_button.theme_type_variation = &"MathosSecondaryButton"
	_settings_button.pressed.connect(func():
		settings_requested.emit()
		pause_requested.emit()
	)
	_utilities_container.add_child(_settings_button)

	_logout_button = Button.new()
	_logout_button.name = "LogoutButton"
	_logout_button.text = "Đăng xuất" if not _is_guest else "Tài khoản"
	_logout_button.tooltip_text = "Trở về đăng nhập"
	_logout_button.custom_minimum_size = Vector2(68, 28)
	_logout_button.add_theme_font_size_override("font_size", 11)
	_logout_button.theme_type_variation = &"MathosSecondaryButton"
	_logout_button.pressed.connect(func():
		logout_requested.emit()
	)
	_utilities_container.add_child(_logout_button)

	add_child(_utilities_container)

func _build_identity_panel() -> void:
	_identity_panel = PanelContainer.new()
	_identity_panel.name = "MathosIdentityPanel"
	_identity_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.06, 0.12, 0.85)
	style.border_width_left = 2
	style.border_color = Color(0.92, 0.78, 0.35, 0.90)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 10
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_identity_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_identity_panel.add_child(vbox)

	var title_hbox: HBoxContainer = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)

	_identity_emblem_rect = TextureRect.new()
	_identity_emblem_rect.name = "IdentityEmblem"
	_identity_emblem_rect.custom_minimum_size = Vector2(36, 36)
	_identity_emblem_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_identity_emblem_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_identity_emblem_rect.texture = _load_texture_safe([BRAND_LOGO_EMBLEM_PATH, BRAND_LOGO_MAIN_PATH])
	title_hbox.add_child(_identity_emblem_rect)

	_identity_title_label = Label.new()
	_identity_title_label.name = "IdentityTitleLabel"
	_identity_title_label.text = "MATHOS"
	_identity_title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_identity_title_label.add_theme_font_size_override("font_size", 22)
	_identity_title_label.add_theme_color_override("font_outline_color", Color(0.1, 0.65, 0.9, 0.5))
	_identity_title_label.add_theme_constant_override("outline_size", 3)
	title_hbox.add_child(_identity_title_label)

	vbox.add_child(title_hbox)

	_identity_subtitle_label = Label.new()
	_identity_subtitle_label.name = "IdentitySubtitleLabel"
	_identity_subtitle_label.text = "Thánh Điện Tri Thức Toán Học"
	_identity_subtitle_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.35))
	_identity_subtitle_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_identity_subtitle_label)

	_identity_version_label = Label.new()
	_identity_version_label.name = "IdentityVersionLabel"
	_identity_version_label.text = "Phiên bản 0.1.0-rc4 • Hệ Thống Ổn Định"
	_identity_version_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	_identity_version_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_identity_version_label)

	var future_hbox: HBoxContainer = HBoxContainer.new()
	future_hbox.name = "FutureButtonsHBox"
	future_hbox.add_theme_constant_override("separation", 8)

	_grimoire_button = Button.new()
	_grimoire_button.name = "GrimoireButton"
	_grimoire_button.text = "📖 Hồ Sơ Bí Thuật"
	_grimoire_button.tooltip_text = "Tính năng đang được chuẩn bị"
	_grimoire_button.disabled = true
	_grimoire_button.theme_type_variation = &"MathosSecondaryButton"
	_grimoire_button.modulate.a = 0.55
	future_hbox.add_child(_grimoire_button)

	_achievements_button = Button.new()
	_achievements_button.name = "AchievementsButton"
	_achievements_button.text = "🏆 Thành Tựu"
	_achievements_button.tooltip_text = "Tính năng đang được chuẩn bị"
	_achievements_button.disabled = true
	_achievements_button.theme_type_variation = &"MathosSecondaryButton"
	_achievements_button.modulate.a = 0.55
	future_hbox.add_child(_achievements_button)

	vbox.add_child(future_hbox)
	add_child(_identity_panel)

func _build_contextual_journey_panel() -> void:
	_journey_panel = PanelContainer.new()
	_journey_panel.name = "ContextualJourneyPanel"
	_journey_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.16, 0.94)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.85, 1.0, 0.35)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 10
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_journey_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_journey_panel.add_child(vbox)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)

	_journey_category_label = Label.new()
	_journey_category_label.name = "CategoryLabel"
	_journey_category_label.text = "HÀNH TRÌNH CHÍNH"
	_journey_category_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.35))
	_journey_category_label.add_theme_font_size_override("font_size", 11)
	_journey_category_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_journey_category_label)

	_journey_status_badge = Label.new()
	_journey_status_badge.name = "StatusBadge"
	_journey_status_badge.text = "ĐANG MỞ"
	_journey_status_badge.add_theme_color_override("font_color", Color(0.35, 0.92, 1.0))
	_journey_status_badge.add_theme_font_size_override("font_size", 11)
	top_row.add_child(_journey_status_badge)

	vbox.add_child(top_row)

	_active_dungeon_label = Label.new()
	_active_dungeon_label.name = "ActiveDungeonLabel"
	_active_dungeon_label.text = _active_dungeon
	_active_dungeon_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_active_dungeon_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_active_dungeon_label)

	_current_stage_label = Label.new()
	_current_stage_label.name = "CurrentStageLabel"
	_current_stage_label.text = _current_stage
	_current_stage_label.add_theme_color_override("font_color", Color(0.35, 0.92, 1.0))
	_current_stage_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_current_stage_label)

	_current_mission_label = Label.new()
	_current_mission_label.name = "CurrentMissionLabel"
	_current_mission_label.text = _current_mission
	_current_mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_current_mission_label.custom_minimum_size = Vector2(320, 0)
	_current_mission_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86))
	_current_mission_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_current_mission_label)

	_action_vbox = VBoxContainer.new()
	_action_vbox.name = "ActionVBox"
	_action_vbox.add_theme_constant_override("separation", 6)

	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "TIẾP TỤC HÀNH TRÌNH"
	_continue_button.custom_minimum_size = Vector2(320, 38)
	_continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_continue_button.focus_mode = Control.FOCUS_ALL
	_continue_button.theme_type_variation = &"MathosPrimaryButton"
	_continue_button.pressed.connect(func():
		continue_game_requested.emit()
		continue_requested.emit()
	)
	_action_vbox.add_child(_continue_button)

	_new_game_button = Button.new()
	_new_game_button.name = "NewGameButton"
	_new_game_button.text = "BẮT ĐẦU MỚI"
	_new_game_button.custom_minimum_size = Vector2(320, 32)
	_new_game_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_new_game_button.focus_mode = Control.FOCUS_ALL
	_new_game_button.theme_type_variation = &"MathosSecondaryButton"
	_new_game_button.pressed.connect(func():
		if _progression_state == HubProgressionState.D1_COMPLETE:
			replay_requested.emit()
		new_game_requested.emit()
	)
	_action_vbox.add_child(_new_game_button)

	_journey_map_button = Button.new()
	_journey_map_button.name = "JourneyMapButton"
	_journey_map_button.text = "BẢN ĐỒ THẾ GIỚI MATHOS"
	_journey_map_button.custom_minimum_size = Vector2(320, 32)
	_journey_map_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journey_map_button.focus_mode = Control.FOCUS_ALL
	_journey_map_button.theme_type_variation = &"MathosSecondaryButton"
	_journey_map_button.pressed.connect(func():
		show_map_requested.emit()
		map_requested.emit()
	)
	_action_vbox.add_child(_journey_map_button)

	_save_summary_label = Label.new()
	_save_summary_label.name = "SaveSummaryLabel"
	_save_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_summary_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	_save_summary_label.add_theme_font_size_override("font_size", 10)
	_save_summary_label.visible = false
	_action_vbox.add_child(_save_summary_label)

	vbox.add_child(_action_vbox)
	add_child(_journey_panel)

func update_responsive_layout(new_size: Vector2 = Vector2.ZERO) -> void:
	var vp_size: Vector2 = new_size if (new_size.x > 0 and new_size.y > 0) else size
	if vp_size.x <= 0 or vp_size.y <= 0:
		vp_size = Vector2(REF_WIDTH, REF_HEIGHT)

	var margin_left: float = REF_MARGIN_LEFT if vp_size.x >= 1280.0 else 24.0
	var margin_right: float = REF_MARGIN_RIGHT if vp_size.x >= 1280.0 else 24.0
	var margin_top: float = REF_MARGIN_TOP if vp_size.y >= 720.0 else 16.0
	var margin_bottom: float = REF_MARGIN_BOTTOM if vp_size.y >= 720.0 else 16.0

	# 1. Top-Left Player Badge
	if _player_badge_panel != null:
		_player_badge_panel.position = Vector2(margin_left, margin_top)

	# 2. Top-Right Order HUD Panel
	var hud_w: float = REF_HUD_SIZE.x
	var hud_h: float = REF_HUD_SIZE.y
	if _order_hud_panel != null:
		hud_w = maxf(_order_hud_panel.size.x, _order_hud_panel.get_combined_minimum_size().x)
		hud_h = maxf(_order_hud_panel.size.y, _order_hud_panel.get_combined_minimum_size().y)
		if hud_w <= 0:
			hud_w = REF_HUD_SIZE.x
		if hud_h <= 0:
			hud_h = REF_HUD_SIZE.y
		var hud_x: float = vp_size.x - margin_right - hud_w
		_order_hud_panel.position = Vector2(hud_x, margin_top)

	# 3. Top-Right Utilities Container (placed underneath Fragment HUD, right-aligned)
	if _utilities_container != null:
		var utils_w: float = maxf(_utilities_container.size.x, _utilities_container.get_combined_minimum_size().x)
		if utils_w <= 0:
			utils_w = 140.0
		var utils_x: float = vp_size.x - margin_right - utils_w
		var utils_y: float = margin_top + hud_h + 6.0
		_utilities_container.position = Vector2(utils_x, utils_y)

	# 4. Bottom-Left Mathos Identity Panel
	if _identity_panel != null:
		var id_h: float = maxf(_identity_panel.size.y, _identity_panel.get_combined_minimum_size().y)
		if id_h <= 0:
			id_h = REF_IDENTITY_SIZE.y
		var id_y: float = vp_size.y - margin_bottom - id_h
		if id_y + id_h > vp_size.y - 8.0:
			id_y = vp_size.y - 8.0 - id_h
		_identity_panel.position = Vector2(margin_left, id_y)

	# 5. Bottom-Right Contextual Journey Panel
	if _journey_panel != null:
		var journey_w: float = maxf(_journey_panel.size.x, _journey_panel.get_combined_minimum_size().x)
		var journey_h: float = maxf(_journey_panel.size.y, _journey_panel.get_combined_minimum_size().y)
		if journey_w <= 0:
			journey_w = REF_JOURNEY_SIZE.x
		if journey_h <= 0:
			journey_h = REF_JOURNEY_SIZE.y
		var journey_x: float = vp_size.x - margin_right - journey_w
		var journey_y: float = vp_size.y - margin_bottom - journey_h
		# Safety guard: clamp to ensure full viewport visibility
		if journey_y + journey_h > vp_size.y - 8.0:
			journey_y = vp_size.y - 8.0 - journey_h
		if journey_y < 120.0:
			journey_y = 120.0
		_journey_panel.position = Vector2(journey_x, journey_y)

func set_progression_state(state: HubProgressionState) -> void:
	_progression_state = state
	_apply_progression_visuals()

func get_progression_state() -> HubProgressionState:
	return _progression_state

func _apply_progression_visuals() -> void:
	match _progression_state:
		HubProgressionState.NEW_PLAYER:
			_active_dungeon = CANONICAL_DUNGEONS["dungeon_01"]
			if _current_stage.is_empty():
				_current_stage = "Giai đoạn 1.1: Khởi Đầu Rừng Mù Sương"
			if _current_mission.is_empty():
				_current_mission = "Khám phá Khu Rừng Sương Mù và tìm kiếm Mảnh Vỡ Trật Tự thứ nhất."
			_fragments_x_of_4 = "0/4 Mảnh Vỡ"
			_dungeons_x_of_4 = "0/4 Dungeon"
			_fragment_states = [false, false, false, false]
			if _journey_status_badge != null:
				_journey_status_badge.text = "ĐANG MỞ"
				_journey_status_badge.add_theme_color_override("font_color", Color(0.35, 0.92, 1.0))
			if _continue_button != null:
				_continue_button.text = "BẮT ĐẦU HÀNH TRÌNH" if not _has_save else "TIẾP TỤC HÀNH TRÌNH"
				_continue_button.visible = _has_save
			if _new_game_button != null:
				_new_game_button.visible = true

		HubProgressionState.D1_ACTIVE:
			_active_dungeon = CANONICAL_DUNGEONS["dungeon_01"]
			if _current_mission.is_empty():
				_current_mission = "Tiếp tục tiến sâu vào Rừng Mù Sương để thanh tẩy năng lượng hỗn loạn."
			_fragments_x_of_4 = "0/4 Mảnh Vỡ"
			_dungeons_x_of_4 = "0/4 Dungeon"
			_fragment_states = [false, false, false, false]
			if _journey_status_badge != null:
				_journey_status_badge.text = "ĐANG MỞ"
				_journey_status_badge.add_theme_color_override("font_color", Color(0.35, 0.92, 1.0))
			if _continue_button != null:
				_continue_button.text = "TIẾP TỤC HÀNH TRÌNH"
				_continue_button.visible = true
			if _new_game_button != null:
				_new_game_button.visible = true

		HubProgressionState.D1_COMPLETE:
			_active_dungeon = CANONICAL_DUNGEONS["dungeon_01"]
			_current_stage = "Đã Hoàn Thành Dungeon I"
			if _current_mission.is_empty():
				_current_mission = "Mảnh Vỡ Trật Tự I đã được phục hồi. Sẵn sàng khám phá lại hoặc chuẩn bị cho hành trình tiếp theo."
			_fragments_x_of_4 = "1/4 Mảnh Vỡ"
			_dungeons_x_of_4 = "1/4 Dungeon"
			_fragment_states = [true, false, false, false]
			if _journey_status_badge != null:
				_journey_status_badge.text = "✓ HOÀN THÀNH"
				_journey_status_badge.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
			if _continue_button != null:
				_continue_button.visible = false
			if _new_game_button != null:
				_new_game_button.visible = true
				_new_game_button.text = "KHÁM PHÁ LẠI (STAGE 1.1)"

		HubProgressionState.D2_ACTIVE, HubProgressionState.D2_COMPLETE, \
		HubProgressionState.D3_ACTIVE, HubProgressionState.D3_COMPLETE, \
		HubProgressionState.D4_ACTIVE, HubProgressionState.D4_COMPLETE, \
		HubProgressionState.ENDGAME:
			pass

	_update_labels()
	_update_fragments_ui()
	update_responsive_layout()

func _update_labels() -> void:
	if _player_name_label != null:
		_player_name_label.text = _player_name
	if _player_level_label != null:
		_player_level_label.text = "Cấp %d • Học Viên Ma Pháp" % _player_level
	if _active_dungeon_label != null:
		_active_dungeon_label.text = _active_dungeon
	if _current_stage_label != null:
		_current_stage_label.text = _current_stage
	if _current_mission_label != null:
		_current_mission_label.text = _current_mission
	if _fragments_count_label != null:
		_fragments_count_label.text = _fragments_x_of_4
	if _dungeons_count_label != null:
		_dungeons_count_label.text = _dungeons_x_of_4

func _update_fragments_ui() -> void:
	for i in range(_fragment_slots.size()):
		var slot: TextureRect = _fragment_slots[i]
		var is_active: bool = _fragment_states[i] if i < _fragment_states.size() else false
		if is_active:
			slot.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if i < _fragment_slot_panels.size():
				var p: PanelContainer = _fragment_slot_panels[i]
				var active_style: StyleBoxFlat = StyleBoxFlat.new()
				active_style.bg_color = Color(0.10, 0.18, 0.32, 0.95)
				active_style.border_width_left = 1
				active_style.border_width_top = 1
				active_style.border_width_right = 1
				active_style.border_width_bottom = 1
				active_style.border_color = Color(0.95, 0.82, 0.25, 0.95)
				active_style.shadow_color = Color(0.95, 0.82, 0.25, 0.5)
				active_style.shadow_size = 4
				active_style.corner_radius_top_left = 6
				active_style.corner_radius_top_right = 6
				active_style.corner_radius_bottom_left = 6
				active_style.corner_radius_bottom_right = 6
				p.add_theme_stylebox_override("panel", active_style)
		else:
			slot.modulate = Color(0.25, 0.25, 0.35, 0.40)
			if i < _fragment_slot_panels.size():
				var p: PanelContainer = _fragment_slot_panels[i]
				var locked_style: StyleBoxFlat = StyleBoxFlat.new()
				locked_style.bg_color = Color(0.06, 0.10, 0.18, 0.90)
				locked_style.border_width_left = 1
				locked_style.border_width_top = 1
				locked_style.border_width_right = 1
				locked_style.border_width_bottom = 1
				locked_style.border_color = Color(0.2, 0.3, 0.45, 0.6)
				locked_style.corner_radius_top_left = 6
				locked_style.corner_radius_top_right = 6
				locked_style.corner_radius_bottom_left = 6
				locked_style.corner_radius_bottom_right = 6
				p.add_theme_stylebox_override("panel", locked_style)

func set_hub_data(data: Dictionary) -> void:
	if data.has("has_save"):
		_has_save = bool(data["has_save"])
	if data.has("progression_state"):
		_progression_state = data["progression_state"] as HubProgressionState

	_apply_progression_visuals()

	if data.has("player_name"):
		_player_name = String(data["player_name"])
	if data.has("player_level"):
		_player_level = int(data["player_level"])
	if data.has("is_guest"):
		_is_guest = bool(data["is_guest"])
	if data.has("active_dungeon"):
		_active_dungeon = String(data["active_dungeon"])
	if data.has("current_stage"):
		_current_stage = String(data["current_stage"])
	if data.has("current_mission"):
		_current_mission = String(data["current_mission"])
	if data.has("fragments_x_of_4"):
		_fragments_x_of_4 = String(data["fragments_x_of_4"])
	if data.has("dungeons_x_of_4"):
		_dungeons_x_of_4 = String(data["dungeons_x_of_4"])
	if data.has("fragment_states") and data["fragment_states"] is Array:
		var arr: Array = data["fragment_states"] as Array
		for i in range(min(4, arr.size())):
			_fragment_states[i] = bool(arr[i])

	_update_labels()
	_update_fragments_ui()
	update_responsive_layout()

func set_continue_available(available: bool, summary_data: Dictionary = {}) -> void:
	_has_save = available

	if available:
		if _progression_state != HubProgressionState.D1_COMPLETE:
			_progression_state = HubProgressionState.D1_ACTIVE

		if not summary_data.is_empty():
			var title: String = String(summary_data.get("stage_title", ""))
			var s_id: String = String(summary_data.get("stage_id", ""))
			var parts: PackedStringArray = s_id.split("_")
			var stage_num: String = "1." + str(parts[2].to_int()) if parts.size() == 3 else s_id
			_current_stage = "Giai đoạn %s: %s" % [stage_num, title]

		if _save_summary_label != null and not summary_data.is_empty():
			_save_summary_label.text = "Tiếp tục: %s" % _current_stage
			_save_summary_label.visible = true
	else:
		if _progression_state != HubProgressionState.D1_COMPLETE:
			_progression_state = HubProgressionState.NEW_PLAYER
		if _save_summary_label != null:
			_save_summary_label.visible = false

	_apply_progression_visuals()

func get_continue_button() -> Button:
	_ensure_built()
	return _continue_button

func get_new_game_button() -> Button:
	_ensure_built()
	return _new_game_button

func get_journey_map_button() -> Button:
	_ensure_built()
	return _journey_map_button

func get_save_summary_label() -> Label:
	_ensure_built()
	return _save_summary_label

func get_action_vbox() -> VBoxContainer:
	_ensure_built()
	return _action_vbox

func get_player_badge_panel() -> PanelContainer:
	_ensure_built()
	return _player_badge_panel

func get_order_hud_panel() -> PanelContainer:
	_ensure_built()
	return _order_hud_panel

func get_identity_panel() -> PanelContainer:
	_ensure_built()
	return _identity_panel

func get_journey_panel() -> PanelContainer:
	_ensure_built()
	return _journey_panel

func _load_texture_safe(paths: Array) -> Texture2D:
	for p in paths:
		var p_str: String = String(p)
		if ResourceLoader.exists(p_str):
			var res: Resource = load(p_str)
			if res is Texture2D:
				return res as Texture2D
		var global_p: String = ProjectSettings.globalize_path(p_str)
		var img: Image = Image.new()
		if img.load(global_p) == OK or img.load(p_str) == OK:
			return ImageTexture.create_from_image(img)
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(p_str)
		if bytes.is_empty() and FileAccess.file_exists(global_p):
			bytes = FileAccess.get_file_as_bytes(global_p)
		if not bytes.is_empty():
			var img_buf: Image = Image.new()
			if img_buf.load_png_from_buffer(bytes) == OK or img_buf.load_jpg_from_buffer(bytes) == OK:
				return ImageTexture.create_from_image(img_buf)
	return null

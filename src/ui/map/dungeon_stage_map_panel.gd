class_name DungeonStageMapPanel
extends Control

## Standalone Production UI Component for Mathos 4 Dungeons Map.
## Implements the human-approved Figma world-map visual (1280x720 reference)
## with native Godot 4.7.1 Control nodes, StyleBoxFlat, and TextureRect.
## Preserves existing D1 gameplay entry flow and keeps D2-D4 locked.

signal stage_selected(stage_id: String)
signal back_requested

var _unlocked_stages: Array[String] = ["stage_01_01"]
var _completed_stages: Array[String] = []
var _current_stage_id: String = "stage_01_01"

# Authoritative Figma reference measurements at 1280x720
const REF_WIDTH: float = 1280.0
const REF_HEIGHT: float = 720.0

const REF_HEADER_POS: Vector2 = Vector2(40.0, 28.0)
const REF_HEADER_SIZE: Vector2 = Vector2(310.0, 112.0)

const REF_HUD_RIGHT: float = 40.0
const REF_HUD_TOP: float = 28.0
const REF_HUD_SIZE: Vector2 = Vector2(289.69, 42.0)

const REF_D1_POS: Vector2 = Vector2(147.19, 420.0)
const REF_D1_SIZE: Vector2 = Vector2(135.63, 130.0)

const REF_D2_POS: Vector2 = Vector2(595.94, 311.88)
const REF_D2_SIZE: Vector2 = Vector2(98.13, 87.0)

const REF_D3_POS: Vector2 = Vector2(927.66, 186.88)
const REF_D3_SIZE: Vector2 = Vector2(104.69, 87.0)

const REF_D4_POS: Vector2 = Vector2(358.85, 116.88)
const REF_D4_SIZE: Vector2 = Vector2(102.30, 87.0)

const REF_PANEL_RIGHT: float = 40.0
const REF_PANEL_BOTTOM: float = 32.0
const REF_PANEL_SIZE: Vector2 = Vector2(350.0, 228.07)

const WORLD_MAP_BG_PATH: String = "res://assets/backgrounds/map/d1_world_map_bg.jpg"

# Visual Nodes
var _bg_texture_rect: TextureRect = null
var _overlay_vertical: TextureRect = null
var _overlay_horizontal: TextureRect = null
var _visual_layer: Control = null

var _header_panel: PanelContainer = null
var _title_label: Label = null
var _world_label: Label = null
var _subtitle_label: Label = null
var _back_button: Button = null

var _hud_panel: PanelContainer = null
var _hud_fragment_label: Label = null
var _hud_dungeon_label: Label = null

var _d1_marker_group: Control = null
var _d1_marker_button: Button = null
var _d1_marker_rune_label: Label = null
var _d1_status_label: Label = null

var _d2_marker_group: Control = null
var _d3_marker_group: Control = null
var _d4_marker_group: Control = null

var _d1_context_panel: PanelContainer = null
var _d1_panel_category_label: Label = null
var _d1_panel_status_badge: Label = null
var _d1_panel_title_label: Label = null
var _d1_panel_body_label: Label = null
var _d1_action_button: Button = null

# Backing container for test compatibility (non-visible to player)
var _dungeon_container: HBoxContainer = null

const DEFAULT_DUNGEONS: Array = [
	{
		"dungeon_id": "dungeon_01",
		"title": "Dungeon 1: Khu Rừng Mù Sương",
		"stages": ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04", "stage_01_05"]
	},
	{
		"dungeon_id": "dungeon_02",
		"title": "Dungeon 2: Đầm Lầy Tỷ Lệ",
		"stages": ["stage_02_01", "stage_02_02", "stage_02_03", "stage_02_04", "stage_02_05"]
	},
	{
		"dungeon_id": "dungeon_03",
		"title": "Dungeon 3: Cung Điện Hợp Nhất",
		"stages": ["stage_03_01", "stage_03_02", "stage_03_03", "stage_03_04", "stage_03_05"]
	},
	{
		"dungeon_id": "dungeon_04",
		"title": "Dungeon 4: Đỉnh Tháp Độc Lập",
		"stages": ["stage_04_01", "stage_04_02", "stage_04_03", "stage_04_04", "stage_04_05"]
	}
]

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	custom_minimum_size = Vector2(REF_WIDTH, REF_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	_build_base_layout()
	render_map()
	_update_responsive_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_responsive_layout()

func _build_base_layout() -> void:
	for child in get_children():
		child.queue_free()

	# 1. Background Artwork TextureRect
	_bg_texture_rect = TextureRect.new()
	_bg_texture_rect.name = "WorldMapBackground"
	_bg_texture_rect.anchor_right = 1.0
	_bg_texture_rect.anchor_bottom = 1.0
	_bg_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture_rect.texture = _load_texture_safe(WORLD_MAP_BG_PATH)
	add_child(_bg_texture_rect)

	# 2. Readability Overlays
	_build_readability_overlays()

	# 3. Visual Layer for Map Presentation (Figma 1280x720 specification)
	_visual_layer = Control.new()
	_visual_layer.name = "MapVisualLayer"
	_visual_layer.anchor_right = 1.0
	_visual_layer.anchor_bottom = 1.0
	_visual_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual_layer)

	_build_header()
	_build_top_right_hud()
	_build_dungeon_markers()
	_build_d1_context_panel()

	# 4. Backing container for test compatibility (kept invisible to player)
	_dungeon_container = HBoxContainer.new()
	_dungeon_container.name = "TestCompatibilityDungeonContainer"
	_dungeon_container.visible = false
	_dungeon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dungeon_container)

func _build_readability_overlays() -> void:
	_overlay_vertical = TextureRect.new()
	_overlay_vertical.name = "VerticalOverlay"
	_overlay_vertical.anchor_right = 1.0
	_overlay_vertical.anchor_bottom = 1.0
	_overlay_vertical.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay_vertical.stretch_mode = TextureRect.STRETCH_SCALE
	_overlay_vertical.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var grad_v: Gradient = Gradient.new()
	grad_v.offsets = PackedFloat32Array([0.0, 0.45, 0.70, 1.0])
	grad_v.colors = PackedColorArray([
		Color(0.02, 0.04, 0.08, 0.40),
		Color(0.02, 0.04, 0.08, 0.0),
		Color(0.02, 0.04, 0.08, 0.35),
		Color(0.02, 0.04, 0.08, 0.85)
	])
	var tex_v: GradientTexture2D = GradientTexture2D.new()
	tex_v.gradient = grad_v
	tex_v.fill_from = Vector2(0.5, 0.0)
	tex_v.fill_to = Vector2(0.5, 1.0)
	_overlay_vertical.texture = tex_v
	add_child(_overlay_vertical)

	_overlay_horizontal = TextureRect.new()
	_overlay_horizontal.name = "HorizontalOverlay"
	_overlay_horizontal.anchor_right = 1.0
	_overlay_horizontal.anchor_bottom = 1.0
	_overlay_horizontal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay_horizontal.stretch_mode = TextureRect.STRETCH_SCALE
	_overlay_horizontal.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var grad_h: Gradient = Gradient.new()
	grad_h.offsets = PackedFloat32Array([0.0, 0.40, 0.65, 1.0])
	grad_h.colors = PackedColorArray([
		Color(0.02, 0.04, 0.08, 0.60),
		Color(0.02, 0.04, 0.08, 0.0),
		Color(0.02, 0.04, 0.08, 0.0),
		Color(0.02, 0.04, 0.08, 0.50)
	])
	var tex_h: GradientTexture2D = GradientTexture2D.new()
	tex_h.gradient = grad_h
	tex_h.fill_from = Vector2(0.0, 0.5)
	tex_h.fill_to = Vector2(1.0, 0.5)
	_overlay_horizontal.texture = tex_h
	add_child(_overlay_horizontal)

func _build_header() -> void:
	_header_panel = PanelContainer.new()
	_header_panel.name = "MapHeaderPanel"
	_header_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.06, 0.12, 0.85)
	style.border_width_left = 2
	style.border_color = Color(0.92, 0.78, 0.35, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 10
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_header_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_header_panel.add_child(vbox)

	_world_label = Label.new()
	_world_label.name = "WorldLabel"
	_world_label.text = "MATHOS"
	_world_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.35))
	_world_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_world_label)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "BẢN ĐỒ HÀNH TRÌNH"
	_title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_outline_color", Color(0.1, 0.65, 0.9, 0.45))
	_title_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "SubtitleLabel"
	_subtitle_label.text = "Chọn thử thách tiếp theo trên hành trình của bạn."
	_subtitle_label.add_theme_color_override("font_color", Color(0.68, 0.76, 0.86))
	_subtitle_label.add_theme_font_size_override("font_size", 11)
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label.custom_minimum_size = Vector2(260, 0)
	vbox.add_child(_subtitle_label)

	_visual_layer.add_child(_header_panel)

	# Dedicated Hub / Back return button positioned cleanly in HUD row
	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = "← TRANG CHỦ"
	_back_button.theme_type_variation = &"MathosSecondaryButton"
	_back_button.custom_minimum_size = Vector2(124, 36)
	_back_button.focus_mode = Control.FOCUS_ALL
	_back_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_back_button.visible = true
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_visual_layer.add_child(_back_button)

func _build_top_right_hud() -> void:
	_hud_panel = PanelContainer.new()
	_hud_panel.name = "TopRightHUDPanel"
	_hud_panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.07, 0.14, 0.85)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.8, 1.0, 0.55)
	style.corner_radius_top_left = 21
	style.corner_radius_top_right = 21
	style.corner_radius_bottom_left = 21
	style.corner_radius_bottom_right = 21
	style.shadow_color = Color(0.1, 0.55, 0.85, 0.25)
	style.shadow_size = 6
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_hud_panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	_hud_panel.add_child(hbox)

	_hud_fragment_label = Label.new()
	_hud_fragment_label.name = "FragmentLabel"
	_hud_fragment_label.text = "Mảnh vỡ: 1"
	_hud_fragment_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.35))
	_hud_fragment_label.add_theme_font_size_override("font_size", 13)
	hbox.add_child(_hud_fragment_label)

	var sep: Label = Label.new()
	sep.text = "|"
	sep.add_theme_color_override("font_color", Color(0.3, 0.5, 0.7, 0.6))
	hbox.add_child(sep)

	_hud_dungeon_label = Label.new()
	_hud_dungeon_label.name = "DungeonLabel"
	_hud_dungeon_label.text = "Dungeon: 1/4"
	_hud_dungeon_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	_hud_dungeon_label.add_theme_font_size_override("font_size", 13)
	hbox.add_child(_hud_dungeon_label)

	_visual_layer.add_child(_hud_panel)

func _build_dungeon_markers() -> void:
	# 1. DUNGEON I (Lower-left ancient cyan stone gate)
	_d1_marker_group = Control.new()
	_d1_marker_group.name = "Dungeon1MarkerGroup"
	_d1_marker_group.custom_minimum_size = REF_D1_SIZE
	_visual_layer.add_child(_d1_marker_group)

	var d1_vbox: VBoxContainer = VBoxContainer.new()
	d1_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	d1_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_d1_marker_group.add_child(d1_vbox)

	_d1_marker_button = Button.new()
	_d1_marker_button.name = "D1MarkerButton"
	_d1_marker_button.custom_minimum_size = Vector2(64, 64)
	_d1_marker_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_d1_marker_button.text = ""

	_d1_marker_rune_label = Label.new()
	_d1_marker_rune_label.name = "RuneLabel"
	_d1_marker_rune_label.text = "◈"
	_d1_marker_rune_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d1_marker_rune_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_d1_marker_rune_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_d1_marker_rune_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_d1_marker_rune_label.add_theme_font_size_override("font_size", 24)
	_d1_marker_rune_label.add_theme_color_override("font_color", Color(0.35, 0.92, 1.0))
	_d1_marker_rune_label.add_theme_color_override("font_outline_color", Color(0.1, 0.65, 0.9, 0.6))
	_d1_marker_rune_label.add_theme_constant_override("outline_size", 2)
	_d1_marker_button.add_child(_d1_marker_rune_label)

	var d1_btn_style: StyleBoxFlat = StyleBoxFlat.new()
	d1_btn_style.bg_color = Color(0.04, 0.08, 0.16, 0.94)
	d1_btn_style.border_width_left = 2
	d1_btn_style.border_width_right = 2
	d1_btn_style.border_width_top = 2
	d1_btn_style.border_width_bottom = 2
	d1_btn_style.border_color = Color(0.25, 0.90, 1.0, 0.95)
	d1_btn_style.corner_radius_top_left = 16
	d1_btn_style.corner_radius_top_right = 16
	d1_btn_style.corner_radius_bottom_left = 16
	d1_btn_style.corner_radius_bottom_right = 16
	d1_btn_style.shadow_color = Color(0.15, 0.85, 1.0, 0.60)
	d1_btn_style.shadow_size = 12
	_d1_marker_button.add_theme_stylebox_override("normal", d1_btn_style)

	var d1_hover_style: StyleBoxFlat = d1_btn_style.duplicate()
	d1_hover_style.shadow_size = 16
	_d1_marker_button.add_theme_stylebox_override("hover", d1_hover_style)
	_d1_marker_button.add_theme_stylebox_override("pressed", d1_hover_style)

	_d1_marker_button.pressed.connect(func() -> void:
		_on_d1_action_pressed()
	)
	d1_vbox.add_child(_d1_marker_button)

	var d1_title: Label = Label.new()
	d1_title.text = "DUNGEON I"
	d1_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d1_title.add_theme_font_size_override("font_size", 12)
	d1_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	d1_vbox.add_child(d1_title)

	var d1_name: Label = Label.new()
	d1_name.text = "KHU RỪNG SƯƠNG MÙ"
	d1_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d1_name.add_theme_font_size_override("font_size", 10)
	d1_name.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	d1_vbox.add_child(d1_name)

	_d1_status_label = Label.new()
	_d1_status_label.name = "D1StatusLabel"
	_d1_status_label.text = "ĐANG MỞ"
	_d1_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d1_status_label.add_theme_font_size_override("font_size", 10)
	_d1_status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	d1_vbox.add_child(_d1_status_label)

	# 2. DUNGEON II (Center purple ruined spire) - LOCKED
	_d2_marker_group = _create_locked_marker(
		"Dungeon2MarkerGroup",
		REF_D2_SIZE,
		"II",
		"DUNGEON II",
		Color(0.65, 0.35, 0.95, 0.80),
		Color(0.08, 0.05, 0.14, 0.90),
		Color(0.65, 0.35, 0.95, 0.35),
		8,
		0.75
	)
	_visual_layer.add_child(_d2_marker_group)

	# 3. DUNGEON III (Upper-right glacial cave) - LOCKED
	_d3_marker_group = _create_locked_marker(
		"Dungeon3MarkerGroup",
		REF_D3_SIZE,
		"III",
		"DUNGEON III",
		Color(0.30, 0.80, 0.95, 0.80),
		Color(0.04, 0.08, 0.14, 0.90),
		Color(0.30, 0.80, 0.95, 0.35),
		8,
		0.75
	)
	_visual_layer.add_child(_d3_marker_group)

	# 4. DUNGEON IV (Upper-left distant castle) - LOCKED
	_d4_marker_group = _create_locked_marker(
		"Dungeon4MarkerGroup",
		REF_D4_SIZE,
		"IV",
		"DUNGEON IV",
		Color(0.45, 0.55, 0.65, 0.70),
		Color(0.06, 0.08, 0.10, 0.90),
		Color(0.20, 0.25, 0.35, 0.30),
		6,
		0.65
	)
	_visual_layer.add_child(_d4_marker_group)

func _create_locked_marker(group_name: String, group_size: Vector2, numeral: String, title: String, tint_color: Color, plate_bg: Color, glow_color: Color, glow_size: int, opacity: float) -> Control:
	var ctrl: Control = Control.new()
	ctrl.name = group_name
	ctrl.custom_minimum_size = group_size
	ctrl.modulate.a = opacity

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.add_child(vbox)

	var icon_box: PanelContainer = PanelContainer.new()
	icon_box.name = "LockedPlate"
	icon_box.custom_minimum_size = Vector2(44, 44)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = plate_bg
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = tint_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = glow_color
	style.shadow_size = glow_size
	icon_box.add_theme_stylebox_override("panel", style)

	var lock_lbl: Label = Label.new()
	lock_lbl.text = "🔒"
	lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock_lbl.add_theme_font_size_override("font_size", 14)
	icon_box.add_child(lock_lbl)
	vbox.add_child(icon_box)

	var t_lbl: Label = Label.new()
	t_lbl.text = title
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	vbox.add_child(t_lbl)

	var l_lbl: Label = Label.new()
	l_lbl.text = "KHÓA"
	l_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_lbl.add_theme_font_size_override("font_size", 10)
	l_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
	vbox.add_child(l_lbl)

	return ctrl

func _build_d1_context_panel() -> void:
	_d1_context_panel = PanelContainer.new()
	_d1_context_panel.name = "D1ContextPanel"
	_d1_context_panel.custom_minimum_size = REF_PANEL_SIZE
	_d1_context_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.06, 0.12, 0.88)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.85, 1.0, 0.35)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 10
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_d1_context_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_d1_context_panel.add_child(vbox)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	vbox.add_child(top_row)

	_d1_panel_category_label = Label.new()
	_d1_panel_category_label.name = "CategoryLabel"
	_d1_panel_category_label.text = "DUNGEON I"
	_d1_panel_category_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.35))
	_d1_panel_category_label.add_theme_font_size_override("font_size", 12)
	_d1_panel_category_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_d1_panel_category_label)

	_d1_panel_status_badge = Label.new()
	_d1_panel_status_badge.name = "StatusBadge"
	_d1_panel_status_badge.text = "✓ HOÀN THÀNH"
	_d1_panel_status_badge.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	_d1_panel_status_badge.add_theme_font_size_override("font_size", 11)
	top_row.add_child(_d1_panel_status_badge)

	_d1_panel_title_label = Label.new()
	_d1_panel_title_label.name = "DungeonNameLabel"
	_d1_panel_title_label.text = "KHU RỪNG SƯƠNG MÙ"
	_d1_panel_title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_d1_panel_title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_d1_panel_title_label)

	_d1_panel_body_label = Label.new()
	_d1_panel_body_label.name = "DescriptionLabel"
	_d1_panel_body_label.text = "Khởi đầu hành trình tại khu rừng cổ bị bao phủ bởi màn sương ma thuật."
	_d1_panel_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d1_panel_body_label.custom_minimum_size = Vector2(300, 0)
	_d1_panel_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_d1_panel_body_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_d1_panel_body_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86))
	_d1_panel_body_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_d1_panel_body_label)

	_d1_action_button = Button.new()
	_d1_action_button.name = "D1ActionButton"
	_d1_action_button.custom_minimum_size = Vector2(300, 44)
	_d1_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_d1_action_button.text = "KHÁM PHÁ LẠI"
	_d1_action_button.add_theme_font_size_override("font_size", 14)

	var btn_norm: StyleBoxFlat = StyleBoxFlat.new()
	btn_norm.bg_color = Color(0.88, 0.72, 0.25)
	btn_norm.corner_radius_top_left = 12
	btn_norm.corner_radius_top_right = 12
	btn_norm.corner_radius_bottom_left = 12
	btn_norm.corner_radius_bottom_right = 12
	btn_norm.shadow_color = Color(0.92, 0.75, 0.25, 0.4)
	btn_norm.shadow_size = 6
	_d1_action_button.add_theme_stylebox_override("normal", btn_norm)

	var btn_hov: StyleBoxFlat = btn_norm.duplicate()
	btn_hov.bg_color = Color(0.98, 0.82, 0.35)
	btn_hov.shadow_size = 10
	_d1_action_button.add_theme_stylebox_override("hover", btn_hov)

	var btn_press: StyleBoxFlat = btn_norm.duplicate()
	btn_press.bg_color = Color(0.78, 0.62, 0.18)
	_d1_action_button.add_theme_stylebox_override("pressed", btn_press)

	_d1_action_button.add_theme_color_override("font_color", Color(0.04, 0.07, 0.12))
	_d1_action_button.add_theme_color_override("font_hover_color", Color(0.02, 0.04, 0.08))
	_d1_action_button.add_theme_color_override("font_pressed_color", Color(0.02, 0.04, 0.08))

	_d1_action_button.pressed.connect(func() -> void:
		_on_d1_action_pressed()
	)
	vbox.add_child(_d1_action_button)

	_visual_layer.add_child(_d1_context_panel)

func _update_responsive_layout() -> void:
	if _visual_layer == null:
		return

	var vp_size: Vector2 = size
	if vp_size.x <= 0 or vp_size.y <= 0:
		vp_size = Vector2(REF_WIDTH, REF_HEIGHT)

	if _header_panel != null:
		_header_panel.position = REF_HEADER_POS
		_header_panel.size = REF_HEADER_SIZE

	if _hud_panel != null:
		_hud_panel.size = REF_HUD_SIZE
		_hud_panel.position = Vector2(vp_size.x - REF_HUD_RIGHT - REF_HUD_SIZE.x, REF_HUD_TOP)

	if _back_button != null and _back_button.visible:
		var hud_x: float = vp_size.x - REF_HUD_RIGHT - REF_HUD_SIZE.x
		_back_button.position = Vector2(hud_x - 136.0, REF_HUD_TOP + 3.0)
		_back_button.size = Vector2(124.0, 36.0)

	if _d1_context_panel != null:
		_d1_context_panel.position = Vector2(vp_size.x - REF_PANEL_RIGHT - REF_PANEL_SIZE.x, vp_size.y - REF_PANEL_BOTTOM - REF_PANEL_SIZE.y)
		_d1_context_panel.size = REF_PANEL_SIZE
		_d1_context_panel.reset_size()

	var scale_factor: float = maxf(vp_size.x / REF_WIDTH, vp_size.y / REF_HEIGHT)
	var offset_x: float = (vp_size.x - REF_WIDTH * scale_factor) * 0.5
	var offset_y: float = (vp_size.y - REF_HEIGHT * scale_factor) * 0.5

	if _d1_marker_group != null:
		_d1_marker_group.position = Vector2(offset_x + REF_D1_POS.x * scale_factor, offset_y + REF_D1_POS.y * scale_factor)
		_d1_marker_group.size = REF_D1_SIZE

	if _d2_marker_group != null:
		_d2_marker_group.position = Vector2(offset_x + REF_D2_POS.x * scale_factor, offset_y + REF_D2_POS.y * scale_factor)
		_d2_marker_group.size = REF_D2_SIZE

	if _d3_marker_group != null:
		_d3_marker_group.position = Vector2(offset_x + REF_D3_POS.x * scale_factor, offset_y + REF_D3_POS.y * scale_factor)
		_d3_marker_group.size = REF_D3_SIZE

	if _d4_marker_group != null:
		_d4_marker_group.position = Vector2(offset_x + REF_D4_POS.x * scale_factor, offset_y + REF_D4_POS.y * scale_factor)
		_d4_marker_group.size = REF_D4_SIZE

func set_map_data(p_map_data: Dictionary) -> void:
	if p_map_data.has("unlocked_stages"):
		_unlocked_stages.clear()
		for s in p_map_data.get("unlocked_stages", []):
			_unlocked_stages.append(String(s))

	if p_map_data.has("completed_stages"):
		_completed_stages.clear()
		for s in p_map_data.get("completed_stages", []):
			_completed_stages.append(String(s))

	if p_map_data.has("current_stage_id"):
		_current_stage_id = String(p_map_data.get("current_stage_id", "stage_01_01"))

	render_map()

func render_map() -> void:
	var is_d1_completed: bool = ("stage_01_05" in _completed_stages) or ("stage_01_01" in _completed_stages and _completed_stages.size() >= 5)

	if _hud_fragment_label != null:
		var frag_count: int = 1 if is_d1_completed else 0
		_hud_fragment_label.text = "Mảnh vỡ: %d" % frag_count
	if _hud_dungeon_label != null:
		var d_count: int = 1 if is_d1_completed else 0
		_hud_dungeon_label.text = "Dungeon: %d/4" % d_count

	if _d1_status_label != null:
		_d1_status_label.text = "✓ HOÀN THÀNH" if is_d1_completed else "ĐANG MỞ"
		_d1_status_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25) if is_d1_completed else Color(0.3, 0.9, 0.4))

	if _d1_panel_status_badge != null:
		_d1_panel_status_badge.text = "✓ HOÀN THÀNH" if is_d1_completed else "ĐANG MỞ"
		_d1_panel_status_badge.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25) if is_d1_completed else Color(0.3, 0.9, 0.4))

	if _d1_action_button != null:
		_d1_action_button.text = "KHÁM PHÁ LẠI" if is_d1_completed else "BẮT ĐẦU"

	if _d1_marker_button != null:
		var d1_btn_style: StyleBoxFlat = StyleBoxFlat.new()
		d1_btn_style.bg_color = Color(0.04, 0.08, 0.16, 0.94)
		d1_btn_style.border_width_left = 2
		d1_btn_style.border_width_right = 2
		d1_btn_style.border_width_top = 2
		d1_btn_style.border_width_bottom = 2
		d1_btn_style.corner_radius_top_left = 16
		d1_btn_style.corner_radius_top_right = 16
		d1_btn_style.corner_radius_bottom_left = 16
		d1_btn_style.corner_radius_bottom_right = 16

		if is_d1_completed:
			d1_btn_style.border_color = Color(0.95, 0.82, 0.30, 1.0)
			d1_btn_style.shadow_color = Color(0.95, 0.82, 0.30, 0.60)
			d1_btn_style.shadow_size = 12
			if _d1_marker_rune_label != null:
				_d1_marker_rune_label.text = "✓"
				_d1_marker_rune_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
				_d1_marker_rune_label.add_theme_color_override("font_outline_color", Color(0.5, 0.4, 0.1, 0.6))
		else:
			d1_btn_style.border_color = Color(0.25, 0.90, 1.0, 0.95)
			d1_btn_style.shadow_color = Color(0.15, 0.85, 1.0, 0.60)
			d1_btn_style.shadow_size = 12
			if _d1_marker_rune_label != null:
				_d1_marker_rune_label.text = "◈"
				_d1_marker_rune_label.add_theme_color_override("font_color", Color(0.35, 0.92, 1.0))
				_d1_marker_rune_label.add_theme_color_override("font_outline_color", Color(0.1, 0.65, 0.9, 0.6))

		_d1_marker_button.add_theme_stylebox_override("normal", d1_btn_style)
		var d1_hover_style: StyleBoxFlat = d1_btn_style.duplicate()
		d1_hover_style.shadow_size = 16
		_d1_marker_button.add_theme_stylebox_override("hover", d1_hover_style)
		_d1_marker_button.add_theme_stylebox_override("pressed", d1_hover_style)

	_render_backing_dungeon_container()

func _render_backing_dungeon_container() -> void:
	if _dungeon_container == null:
		return

	for child in _dungeon_container.get_children():
		_dungeon_container.remove_child(child)
		child.free()

	for dun_info in DEFAULT_DUNGEONS:
		var dun_panel: PanelContainer = PanelContainer.new()
		dun_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dun_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var dun_margin: MarginContainer = MarginContainer.new()
		dun_margin.add_theme_constant_override("margin_left", 12)
		dun_margin.add_theme_constant_override("margin_right", 12)
		dun_margin.add_theme_constant_override("margin_top", 12)
		dun_margin.add_theme_constant_override("margin_bottom", 12)
		dun_panel.add_child(dun_margin)

		var dun_vbox: VBoxContainer = VBoxContainer.new()
		dun_vbox.add_theme_constant_override("separation", 10)
		dun_margin.add_child(dun_vbox)

		var dun_title: Label = Label.new()
		dun_title.text = String(dun_info.get("title", "Dungeon"))
		dun_vbox.add_child(dun_title)

		var stages: Array = dun_info.get("stages", [])
		for s_id_raw in stages:
			var s_id: String = String(s_id_raw)
			var is_completed: bool = s_id in _completed_stages
			var is_unlocked: bool = is_completed or (s_id in _unlocked_stages) or (s_id == _current_stage_id)
			var is_current: bool = (s_id == _current_stage_id)

			var stage_btn: Button = Button.new()
			var parts: PackedStringArray = s_id.split("_")
			var stage_num_str: String = "Stage " + str(parts[1].to_int()) + "." + str(parts[2].to_int()) if parts.size() == 3 else s_id

			if is_completed:
				stage_btn.text = "✔ " + stage_num_str + " (Đã xong)"
				stage_btn.disabled = false
				stage_btn.theme_type_variation = &"MathosSecondaryButton"
			elif is_current or is_unlocked:
				stage_btn.text = "▶ " + stage_num_str + " (Đang mở)"
				stage_btn.disabled = false
				stage_btn.theme_type_variation = &"MathosPrimaryButton"
			else:
				stage_btn.text = "🔒 " + stage_num_str + " (Khóa)"
				stage_btn.disabled = true
				stage_btn.theme_type_variation = &"MathosSecondaryButton"
				stage_btn.modulate.a = 0.55

			if is_unlocked or is_completed:
				stage_btn.pressed.connect(func() -> void:
					_on_stage_button_pressed(s_id)
				)

			dun_vbox.add_child(stage_btn)

		_dungeon_container.add_child(dun_panel)

func _on_d1_action_pressed() -> void:
	var target_stage: String = "stage_01_01"
	if _current_stage_id.begins_with("stage_01_") and (_current_stage_id in _unlocked_stages):
		target_stage = _current_stage_id
	_on_stage_button_pressed(target_stage)

func _on_stage_button_pressed(stage_id: String) -> void:
	var is_completed: bool = stage_id in _completed_stages
	var is_unlocked: bool = is_completed or (stage_id in _unlocked_stages) or (stage_id == _current_stage_id)

	if stage_id.begins_with("stage_02_") or stage_id.begins_with("stage_03_") or stage_id.begins_with("stage_04_"):
		return

	if is_unlocked or is_completed:
		stage_selected.emit(stage_id)

func _load_texture_safe(p_path: String) -> Texture2D:
	if ResourceLoader.exists(p_path):
		var res: Resource = load(p_path)
		if res is Texture2D:
			return res as Texture2D
	var global_p: String = ProjectSettings.globalize_path(p_path)
	var img: Image = Image.new()
	if img.load(global_p) == OK or img.load(p_path) == OK:
		return ImageTexture.create_from_image(img)
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(p_path)
	if bytes.is_empty() and FileAccess.file_exists(global_p):
		bytes = FileAccess.get_file_as_bytes(global_p)
	if not bytes.is_empty():
		var img_buf: Image = Image.new()
		if img_buf.load_jpg_from_buffer(bytes) == OK or img_buf.load_png_from_buffer(bytes) == OK:
			return ImageTexture.create_from_image(img_buf)
	return null

func has_white_endpoints_in_overlays() -> bool:
	for tex_rect in [_overlay_vertical, _overlay_horizontal]:
		if tex_rect == null or not (tex_rect.texture is GradientTexture2D):
			continue
		var grad_tex: GradientTexture2D = tex_rect.texture as GradientTexture2D
		var grad: Gradient = grad_tex.gradient
		if grad == null:
			continue
		for i in range(grad.get_point_count()):
			var c: Color = grad.get_color(i)
			if c.r >= 0.8 and c.g >= 0.8 and c.b >= 0.8 and c.a > 0.05:
				return true
	return false

func is_d1_marker_non_circular() -> bool:
	if _d1_marker_button == null:
		return false
	var style: StyleBoxFlat = _d1_marker_button.get_theme_stylebox("normal") as StyleBoxFlat
	if style == null:
		return false
	return style.corner_radius_top_left <= 20 and style.corner_radius_top_left >= 8

func are_locked_markers_rounded_squares() -> bool:
	for group in [_d2_marker_group, _d3_marker_group, _d4_marker_group]:
		if group == null:
			return false
		var plate: PanelContainer = group.find_child("LockedPlate", true, false) as PanelContainer
		if plate == null:
			return false
		var style: StyleBoxFlat = plate.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null:
			return false
		if style.corner_radius_top_left > 16 or style.corner_radius_top_left < 8:
			return false
	return true

func has_header_back_row() -> bool:
	if _header_panel == null:
		return false
	for child in _header_panel.find_children("*", "", true, false):
		if child.name == "BackButton":
			return true
		if child is Button:
			var btn: Button = child as Button
			if btn.text.contains("Trở về") or btn.text.contains("Back"):
				return true
		if child is Label:
			var lbl: Label = child as Label
			if lbl.text.contains("Trở về") or lbl.text.contains("←"):
				return true
	return false

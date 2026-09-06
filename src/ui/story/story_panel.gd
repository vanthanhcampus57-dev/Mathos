class_name StoryPanel
extends Control

## Dedicated UI component for displaying the D1 Story scene (Visual Novel style)
## matching the human-approved Figma specification:
## - TopBar 1280x72 with MATHOS branding, Dungeon context, Stage title, CỐT TRUYỆN badge, Pause button
## - Character stage with Draven portrait (340x480 footprint, 340x440 rendered, bottom alpha fade)
## - Draven nameplate (~147px wide, dark navy, cyan border, gold diamond accents, "ĐẠI PHÁP SƯ HƯỚNG DẪN")
## - Translucent dialogue panel 840x210 (padding 24, dark navy ~0.88, cyan border, gold corner ornaments)
## - Exact story dialogue preservation
## - Footer with "Bước 1 / 1" and "VÀO BÀI HỌC" CTA button (165.87x38)

signal continue_requested()
signal pause_requested()
signal step_changed(step_index: int, total_steps: int)
signal story_completed()

const DRAVEN_PORTRAIT_PATH: String = "res://assets/characters/story/draven/draven_portrait.png"
const DRAVEN_PORTRAIT_ALT_PATH: String = "D:/Mathos_Art_Source/characters/Draven/draven_portrait.png"

# Canonical Speaker Profiles for Story Mode
const SPEAKER_CONFIGS: Dictionary = {
	"npc_draven": {
		"id": "npc_draven",
		"name": "DRAVEN",
		"subtitle": "ĐẠI PHÁP SƯ HƯỚNG DẪN",
		"portrait_path": "res://assets/characters/story/draven/draven_portrait.png"
	},
	"draven": {
		"id": "npc_draven",
		"name": "DRAVEN",
		"subtitle": "ĐẠI PHÁP SƯ HƯỚNG DẪN",
		"portrait_path": "res://assets/characters/story/draven/draven_portrait.png"
	},
	"npc_arithmos": {
		"id": "npc_arithmos",
		"name": "ARITHMOS",
		"subtitle": "TRƯỞNG THƯ VIỆN TRI THỨC",
		"portrait_path": "res://assets/characters/story/arithmos/arithmos_portrait.png"
	},
	"arithmos": {
		"id": "npc_arithmos",
		"name": "ARITHMOS",
		"subtitle": "TRƯỞNG THƯ VIỆN TRI THỨC",
		"portrait_path": "res://assets/characters/story/arithmos/arithmos_portrait.png"
	},
	"char_karl": {
		"id": "char_karl",
		"name": "KARL",
		"subtitle": "HỌC VIÊN PHÁP THUẬT",
		"portrait_path": ""
	},
	"karl": {
		"id": "char_karl",
		"name": "KARL",
		"subtitle": "HỌC VIÊN PHÁP THUẬT",
		"portrait_path": ""
	},
	"npc_aether": {
		"id": "npc_aether",
		"name": "AETHER",
		"subtitle": "LINH HỒN CỔ ĐẠI",
		"portrait_path": ""
	},
	"aether": {
		"id": "npc_aether",
		"name": "AETHER",
		"subtitle": "LINH HỒN CỔ ĐẠI",
		"portrait_path": ""
	}
}

# Subtitle approved in Figma design (presentation copy)
const DRAVEN_PRESENTATION_SUBTITLE: String = "ĐẠI PHÁP SƯ HƯỚNG DẪN"
const ARITHMOS_PRESENTATION_SUBTITLE: String = "TRƯỞNG THƯ VIỆN TRI THỨC"

var _custom_speaker_configs: Dictionary = {}
var _active_speaker_id: String = "npc_draven"
var _active_speaker_name: String = "DRAVEN"
var _active_speaker_subtitle: String = "ĐẠI PHÁP SƯ HƯỚNG DẪN"
var _active_portrait_path: String = DRAVEN_PORTRAIT_PATH

var _steps: Array[PresentationModels.LessonStepData] = []
var _current_index: int = 0
var _context_info: PresentationModels.StageContextInfo = null

# Node references
var _top_bar: Control = null
var _mathos_brand_label: Label = null
var _dungeon_context_label: Label = null
var _stage_title_label: Label = null
var _phase_badge_label: Label = null
var _pause_button: Button = null

var _stage_container: Control = null
var _character_slot: Control = null
var _draven_rect: TextureRect = null
var _draven_shader_material: ShaderMaterial = null
var _nameplate_panel: PanelContainer = null
var _nameplate_name_label: Label = null
var _nameplate_subtitle_label: Label = null

var _dialogue_panel: PanelContainer = null
var _speaker_label: Label = null
var _body_label: RichTextLabel = null
var _page_indicator_label: Label = null
var _continue_button: Button = null

func _ready() -> void:
	if _top_bar != null:
		return
	_build_ui_structure()
	_load_draven_texture()
	_update_display()

func set_context_info(info: Variant) -> void:
	if info is PresentationModels.StageContextInfo:
		_context_info = info as PresentationModels.StageContextInfo
	elif info is Dictionary:
		_context_info = PresentationModels.StageContextInfo.from_dict(info as Dictionary)
	else:
		_context_info = null

	if _context_info != null:
		if not _context_info.story_steps.is_empty():
			set_story_data(_context_info.story_steps)
		_update_header_context()

func set_story_data(steps: Array) -> void:
	_steps.clear()
	for s in steps:
		if s is PresentationModels.LessonStepData:
			_steps.append(s as PresentationModels.LessonStepData)
		elif s is Dictionary:
			_steps.append(PresentationModels.LessonStepData.from_dict(s as Dictionary))
	_current_index = 0
	_update_display()

func show_step(index: int) -> void:
	if index >= 0 and index < _steps.size():
		_current_index = index
		_update_display()

func next_step() -> bool:
	if _current_index + 1 < _steps.size():
		_current_index += 1
		_update_display()
		step_changed.emit(_current_index, _steps.size())
		return true
	else:
		story_completed.emit()
		return false

func get_current_step_index() -> int:
	return _current_index

func get_total_steps() -> int:
	return _steps.size()

func is_on_last_step() -> bool:
	return _steps.is_empty() or _current_index >= _steps.size() - 1

func _build_ui_structure() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Root VBox layout (TopBar 72px + Stage 648px)
	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.name = "RootVBox"
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.mouse_filter = MOUSE_FILTER_STOP
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	# 1. TopBar (1280x72 reference)
	_build_top_bar(root_vbox)

	# 2. CharacterAndDialogueStage (1280x648 reference)
	_build_character_and_dialogue_stage(root_vbox)

func _build_top_bar(parent: Control) -> void:
	var topbar_margin: MarginContainer = MarginContainer.new()
	topbar_margin.name = "TopBarMargin"
	topbar_margin.custom_minimum_size = Vector2(0, 72)
	topbar_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topbar_margin.mouse_filter = MOUSE_FILTER_IGNORE
	topbar_margin.add_theme_constant_override("margin_top", 24)
	topbar_margin.add_theme_constant_override("margin_left", 32)
	topbar_margin.add_theme_constant_override("margin_right", 32)
	parent.add_child(topbar_margin)
	_top_bar = topbar_margin

	var top_hbox: HBoxContainer = HBoxContainer.new()
	top_hbox.name = "TopHBox"
	top_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.mouse_filter = MOUSE_FILTER_IGNORE
	topbar_margin.add_child(top_hbox)

	# Left Header Hierarchy: MATHOS -> Dungeon -> Stage Title + CỐT TRUYỆN badge
	var left_header_vbox: VBoxContainer = VBoxContainer.new()
	left_header_vbox.name = "LeftHeaderVBox"
	left_header_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_header_vbox.mouse_filter = MOUSE_FILTER_IGNORE
	left_header_vbox.add_theme_constant_override("separation", 2)
	top_hbox.add_child(left_header_vbox)

	# Row 1: Brand & Dungeon Context
	var meta_hbox: HBoxContainer = HBoxContainer.new()
	meta_hbox.name = "MetaHBox"
	meta_hbox.mouse_filter = MOUSE_FILTER_IGNORE
	meta_hbox.add_theme_constant_override("separation", 8)
	left_header_vbox.add_child(meta_hbox)

	_mathos_brand_label = Label.new()
	_mathos_brand_label.name = "MathosBrandLabel"
	_mathos_brand_label.text = "MATHOS"
	_mathos_brand_label.add_theme_font_size_override("font_size", 12)
	_mathos_brand_label.add_theme_color_override("font_color", Color(0.96, 0.77, 0.26, 0.95)) # Subtle gold
	meta_hbox.add_child(_mathos_brand_label)

	var bullet_label: Label = Label.new()
	bullet_label.text = "•"
	bullet_label.add_theme_font_size_override("font_size", 12)
	bullet_label.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6, 0.8))
	meta_hbox.add_child(bullet_label)

	_dungeon_context_label = Label.new()
	_dungeon_context_label.name = "DungeonContextLabel"
	_dungeon_context_label.text = "DUNGEON I: KHU RỪNG MÙ SƯƠNG"
	_dungeon_context_label.add_theme_font_size_override("font_size", 12)
	_dungeon_context_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 0.9))
	meta_hbox.add_child(_dungeon_context_label)

	# Row 2: Stage Title + Phase Badge
	var title_hbox: HBoxContainer = HBoxContainer.new()
	title_hbox.name = "TitleHBox"
	title_hbox.mouse_filter = MOUSE_FILTER_IGNORE
	title_hbox.add_theme_constant_override("separation", 12)
	left_header_vbox.add_child(title_hbox)

	_stage_title_label = Label.new()
	_stage_title_label.name = "StageTitleLabel"
	_stage_title_label.text = "Khởi Đầu Rừng Mù Sương"
	_stage_title_label.add_theme_font_size_override("font_size", 20)
	_stage_title_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0, 1.0))
	title_hbox.add_child(_stage_title_label)

	# CỐT TRUYỆN badge (replacing old [LÝ THUYẾT])
	var badge_panel: PanelContainer = PanelContainer.new()
	badge_panel.name = "PhaseBadgePanel"
	var badge_sb: StyleBoxFlat = StyleBoxFlat.new()
	badge_sb.bg_color = Color(0.06, 0.20, 0.30, 0.85)
	badge_sb.border_color = Color(0.30, 0.85, 0.95, 0.60)
	badge_sb.border_width_left = 1
	badge_sb.border_width_top = 1
	badge_sb.border_width_right = 1
	badge_sb.border_width_bottom = 1
	badge_sb.corner_radius_top_left = 4
	badge_sb.corner_radius_top_right = 4
	badge_sb.corner_radius_bottom_left = 4
	badge_sb.corner_radius_bottom_right = 4
	badge_sb.content_margin_left = 8
	badge_sb.content_margin_right = 8
	badge_sb.content_margin_top = 2
	badge_sb.content_margin_bottom = 2
	badge_panel.add_theme_stylebox_override("panel", badge_sb)
	title_hbox.add_child(badge_panel)

	_phase_badge_label = Label.new()
	_phase_badge_label.name = "PhaseBadgeLabel"
	_phase_badge_label.text = "CỐT TRUYỆN"
	_phase_badge_label.add_theme_font_size_override("font_size", 11)
	_phase_badge_label.add_theme_color_override("font_color", Color(0.40, 0.90, 1.0, 1.0))
	badge_panel.add_child(_phase_badge_label)

	# Right: Tạm dừng button (~118x34 reference)
	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "Tạm dừng"
	_pause_button.custom_minimum_size = Vector2(118, 34)
	_pause_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pause_button.theme_type_variation = &"MathosSecondaryButton"
	_pause_button.focus_mode = FOCUS_ALL
	_pause_button.pressed.connect(_on_pause_pressed)
	top_hbox.add_child(_pause_button)

func _build_character_and_dialogue_stage(parent: Control) -> void:
	var stage_margin: MarginContainer = MarginContainer.new()
	stage_margin.name = "CharacterAndDialogueStage"
	stage_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_margin.mouse_filter = MOUSE_FILTER_IGNORE
	stage_margin.add_theme_constant_override("margin_left", 40)
	stage_margin.add_theme_constant_override("margin_right", 40)
	stage_margin.add_theme_constant_override("margin_bottom", 32)
	parent.add_child(stage_margin)
	_stage_container = stage_margin

	# Horizontal container aligning character and dialogue bottom
	var stage_hbox: HBoxContainer = HBoxContainer.new()
	stage_hbox.name = "StageHBox"
	stage_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_hbox.mouse_filter = MOUSE_FILTER_IGNORE
	stage_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	stage_hbox.add_theme_constant_override("separation", 24)
	stage_margin.add_child(stage_hbox)

	# 1. Draven Slot (340x480 reference)
	_build_draven_slot(stage_hbox)

	# 2. Dialogue Panel (840x210 reference)
	_build_dialogue_panel(stage_hbox)

func _build_draven_slot(parent: Control) -> void:
	var draven_vbox: VBoxContainer = VBoxContainer.new()
	draven_vbox.name = "DravenSlotVBox"
	draven_vbox.custom_minimum_size = Vector2(340, 480)
	draven_vbox.size_flags_vertical = Control.SIZE_SHRINK_END
	draven_vbox.mouse_filter = MOUSE_FILTER_IGNORE
	draven_vbox.add_theme_constant_override("separation", -24) # Overlap nameplate on bottom of portrait
	parent.add_child(draven_vbox)
	_character_slot = draven_vbox

	# Portrait container
	var portrait_container: Control = Control.new()
	portrait_container.name = "PortraitContainer"
	portrait_container.custom_minimum_size = Vector2(340, 440)
	portrait_container.size_flags_horizontal = Control.SIZE_FILL
	portrait_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_container.mouse_filter = MOUSE_FILTER_IGNORE
	draven_vbox.add_child(portrait_container)

	_draven_rect = TextureRect.new()
	_draven_rect.name = "DravenTextureRect"
	_draven_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_draven_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_draven_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_draven_rect.mouse_filter = MOUSE_FILTER_IGNORE
	portrait_container.add_child(_draven_rect)

	# Non-destructive native bottom alpha fade shader
	_apply_bottom_alpha_shader(_draven_rect)

	# Nameplate (~147px wide, dark navy, cyan border, gold diamond accents)
	var nameplate_center: CenterContainer = CenterContainer.new()
	nameplate_center.name = "NameplateCenter"
	nameplate_center.size_flags_horizontal = Control.SIZE_FILL
	nameplate_center.mouse_filter = MOUSE_FILTER_IGNORE
	draven_vbox.add_child(nameplate_center)

	_nameplate_panel = PanelContainer.new()
	_nameplate_panel.name = "DravenNameplate"
	_nameplate_panel.custom_minimum_size = Vector2(148, 44)
	var np_sb: StyleBoxFlat = StyleBoxFlat.new()
	np_sb.bg_color = Color(0.04, 0.08, 0.16, 0.94)
	np_sb.border_color = Color(0.25, 0.85, 0.95, 0.85)
	np_sb.border_width_left = 1
	np_sb.border_width_top = 1
	np_sb.border_width_right = 1
	np_sb.border_width_bottom = 1
	np_sb.corner_radius_top_left = 6
	np_sb.corner_radius_top_right = 6
	np_sb.corner_radius_bottom_left = 6
	np_sb.corner_radius_bottom_right = 6
	np_sb.shadow_color = Color(0.05, 0.40, 0.60, 0.40)
	np_sb.shadow_size = 6
	np_sb.content_margin_left = 12
	np_sb.content_margin_right = 12
	np_sb.content_margin_top = 4
	np_sb.content_margin_bottom = 4
	_nameplate_panel.add_theme_stylebox_override("panel", np_sb)
	nameplate_center.add_child(_nameplate_panel)

	var np_vbox: VBoxContainer = VBoxContainer.new()
	np_vbox.name = "NameplateVBox"
	np_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	np_vbox.add_theme_constant_override("separation", 1)
	_nameplate_panel.add_child(np_vbox)

	var name_hbox: HBoxContainer = HBoxContainer.new()
	name_hbox.name = "NameHBox"
	name_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	name_hbox.add_theme_constant_override("separation", 6)
	np_vbox.add_child(name_hbox)

	var d1: Label = Label.new()
	d1.text = "◈"
	d1.add_theme_font_size_override("font_size", 10)
	d1.add_theme_color_override("font_color", Color(0.96, 0.77, 0.26, 0.9))
	name_hbox.add_child(d1)

	_nameplate_name_label = Label.new()
	_nameplate_name_label.name = "NameLabel"
	_nameplate_name_label.text = "DRAVEN"
	_nameplate_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nameplate_name_label.add_theme_font_size_override("font_size", 14)
	_nameplate_name_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0, 1.0))
	name_hbox.add_child(_nameplate_name_label)

	var d2: Label = Label.new()
	d2.text = "◈"
	d2.add_theme_font_size_override("font_size", 10)
	d2.add_theme_color_override("font_color", Color(0.96, 0.77, 0.26, 0.9))
	name_hbox.add_child(d2)

	_nameplate_subtitle_label = Label.new()
	_nameplate_subtitle_label.name = "SubtitleLabel"
	_nameplate_subtitle_label.text = DRAVEN_PRESENTATION_SUBTITLE
	_nameplate_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nameplate_subtitle_label.add_theme_font_size_override("font_size", 9)
	_nameplate_subtitle_label.add_theme_color_override("font_color", Color(0.48, 0.83, 0.98, 0.90))
	np_vbox.add_child(_nameplate_subtitle_label)

func _build_dialogue_panel(parent: Control) -> void:
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.name = "DialoguePanel"
	_dialogue_panel.custom_minimum_size = Vector2(840, 210)
	_dialogue_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_panel.size_flags_vertical = Control.SIZE_SHRINK_END

	# Translucent dark navy with cyan border and subtle glow
	var dlg_sb: StyleBoxFlat = StyleBoxFlat.new()
	dlg_sb.bg_color = Color(0.03, 0.06, 0.12, 0.88)
	dlg_sb.border_color = Color(0.20, 0.80, 0.95, 0.40)
	dlg_sb.border_width_left = 1
	dlg_sb.border_width_top = 1
	dlg_sb.border_width_right = 1
	dlg_sb.border_width_bottom = 1
	dlg_sb.corner_radius_top_left = 8
	dlg_sb.corner_radius_top_right = 8
	dlg_sb.corner_radius_bottom_left = 8
	dlg_sb.corner_radius_bottom_right = 8
	dlg_sb.shadow_color = Color(0.02, 0.35, 0.50, 0.25)
	dlg_sb.shadow_size = 14
	dlg_sb.content_margin_left = 24
	dlg_sb.content_margin_right = 24
	dlg_sb.content_margin_top = 20
	dlg_sb.content_margin_bottom = 20
	_dialogue_panel.add_theme_stylebox_override("panel", dlg_sb)
	parent.add_child(_dialogue_panel)

	# Dialogue inner layout
	var dlg_vbox: VBoxContainer = VBoxContainer.new()
	dlg_vbox.name = "DialogueVBox"
	dlg_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dlg_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dlg_vbox.add_theme_constant_override("separation", 10)
	_dialogue_panel.add_child(dlg_vbox)

	# Speaker Row: DRAVEN
	_speaker_label = Label.new()
	_speaker_label.name = "SpeakerLabel"
	_speaker_label.text = "DRAVEN"
	_speaker_label.add_theme_font_size_override("font_size", 16)
	_speaker_label.add_theme_color_override("font_color", Color(0.48, 0.83, 0.98, 1.0))
	dlg_vbox.add_child(_speaker_label)

	# Dialogue Body Text (RichTextLabel with auto-wrap)
	_body_label = RichTextLabel.new()
	_body_label.name = "BodyLabel"
	_body_label.bbcode_enabled = true
	_body_label.fit_content = false
	_body_label.scroll_active = false
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_label.mouse_filter = MOUSE_FILTER_IGNORE
	_body_label.add_theme_font_size_override("normal_font_size", 16)
	_body_label.add_theme_color_override("default_color", Color(0.92, 0.94, 0.98, 1.0))
	_body_label.text = "Karl! Rừng Mù Sương bị bao phủ bởi Ma Thuật Ngẫu Nhiên. Mọi hành động ở đây đều là một phép thử — ta không thể biết trước kết quả, nhưng có thể lường trước mọi khả năng!"
	dlg_vbox.add_child(_body_label)

	# Footer Row: Page indicator + CTA button
	var footer_hbox: HBoxContainer = HBoxContainer.new()
	footer_hbox.name = "FooterHBox"
	footer_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	dlg_vbox.add_child(footer_hbox)

	_page_indicator_label = Label.new()
	_page_indicator_label.name = "PageIndicatorLabel"
	_page_indicator_label.text = "Bước 1 / 1"
	_page_indicator_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_indicator_label.add_theme_font_size_override("font_size", 13)
	_page_indicator_label.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72, 1.0))
	footer_hbox.add_child(_page_indicator_label)

	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "VÀO BÀI HỌC"
	_continue_button.custom_minimum_size = Vector2(166, 38)
	_continue_button.theme_type_variation = &"MathosPrimaryButton"
	_continue_button.focus_mode = FOCUS_ALL
	_continue_button.pressed.connect(_on_continue_pressed)
	footer_hbox.add_child(_continue_button)

	# 12x12 Gold corner accents
	_add_gold_corner_accents(_dialogue_panel)

func _add_gold_corner_accents(panel: Control) -> void:
	var corners = [
		{"name": "CornerTL", "symbol": "┌"},
		{"name": "CornerTR", "symbol": "┐"},
		{"name": "CornerBL", "symbol": "└"},
		{"name": "CornerBR", "symbol": "┘"}
	]
	for c in corners:
		var lbl: Label = Label.new()
		lbl.name = c["name"]
		lbl.text = c["symbol"]
		lbl.custom_minimum_size = Vector2(12, 12)
		lbl.mouse_filter = MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.96, 0.77, 0.26, 0.65))
		panel.add_child(lbl)

func _apply_bottom_alpha_shader(target: CanvasItem) -> void:
	var shader_code: String = """
shader_type canvas_item;

uniform float fade_start : hint_range(0.0, 1.0) = 0.85;
uniform float fade_end : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float alpha_mult = 1.0 - smoothstep(fade_start, fade_end, UV.y);
	COLOR = vec4(col.rgb, col.a * alpha_mult);
}
"""
	var shader: Shader = Shader.new()
	shader.code = shader_code
	_draven_shader_material = ShaderMaterial.new()
	_draven_shader_material.shader = shader
	_draven_shader_material.set_shader_parameter("fade_start", 0.85)
	_draven_shader_material.set_shader_parameter("fade_end", 1.0)
	target.material = _draven_shader_material

func _load_draven_texture() -> void:
	if _draven_rect == null:
		return

	var tex: Texture2D = null
	if ResourceLoader.exists(DRAVEN_PORTRAIT_PATH):
		tex = load(DRAVEN_PORTRAIT_PATH) as Texture2D

	if tex == null:
		var global_p: String = ProjectSettings.globalize_path(DRAVEN_PORTRAIT_PATH)
		if FileAccess.file_exists(global_p):
			var img: Image = Image.new()
			if img.load(global_p) == OK:
				tex = ImageTexture.create_from_image(img)

	if tex == null and FileAccess.file_exists(DRAVEN_PORTRAIT_ALT_PATH):
		var img2: Image = Image.new()
		if img2.load(DRAVEN_PORTRAIT_ALT_PATH) == OK:
			tex = ImageTexture.create_from_image(img2)

	if tex != null:
		_draven_rect.texture = tex

func _update_header_context() -> void:
	if _context_info == null:
		return

	if _dungeon_context_label != null:
		var d_title: String = _context_info.dungeon_title.to_upper()
		if not d_title.begins_with("DUNGEON"):
			d_title = "DUNGEON I: " + d_title
		_dungeon_context_label.text = d_title

	if _stage_title_label != null:
		_stage_title_label.text = _context_info.stage_title

func _update_display() -> void:
	if _steps.is_empty():
		return

	var step: PresentationModels.LessonStepData = _steps[_current_index]
	var raw_spk: String = step.speaker_label
	if raw_spk.is_empty():
		raw_spk = "npc_draven"

	var cfg: Dictionary = get_speaker_config(raw_spk)
	_apply_speaker_config(cfg)

	if _body_label != null:
		_body_label.text = step.body_text

	if _page_indicator_label != null:
		_page_indicator_label.text = "Bước %d / %d" % [_current_index + 1, _steps.size()]

	if _continue_button != null:
		_continue_button.focus_mode = FOCUS_ALL
		_continue_button.disabled = false
		if is_on_last_step():
			_continue_button.text = "VÀO BÀI HỌC"
		else:
			_continue_button.text = "TIẾP TỤC"

func register_speaker_config(speaker_id: String, display_name: String, subtitle: String, portrait_path: String = "") -> void:
	_custom_speaker_configs[speaker_id.to_lower().strip_edges()] = {
		"id": speaker_id,
		"name": display_name,
		"subtitle": subtitle,
		"portrait_path": portrait_path
	}

func get_speaker_config(speaker_id: String) -> Dictionary:
	var key: String = speaker_id.to_lower().strip_edges()
	if _custom_speaker_configs.has(key):
		return (_custom_speaker_configs[key] as Dictionary).duplicate()
	if SPEAKER_CONFIGS.has(key):
		return (SPEAKER_CONFIGS[key] as Dictionary).duplicate()
	var fallback_name: String = LessonPanel.get_player_facing_speaker_name(speaker_id)
	return {
		"id": speaker_id,
		"name": fallback_name.to_upper(),
		"subtitle": "CỐ VẤN HƯỚNG DẪN",
		"portrait_path": ""
	}

func configure_speaker(speaker_id: String, custom_name: String = "", custom_subtitle: String = "", custom_portrait_path: String = "") -> void:
	var cfg: Dictionary = get_speaker_config(speaker_id).duplicate()
	if not custom_name.is_empty():
		cfg["name"] = custom_name
	if not custom_subtitle.is_empty():
		cfg["subtitle"] = custom_subtitle
	if not custom_portrait_path.is_empty():
		cfg["portrait_path"] = custom_portrait_path
	_apply_speaker_config(cfg)

func set_speaker(speaker_id: String, custom_name: String = "", custom_subtitle: String = "", custom_portrait_path: String = "") -> void:
	configure_speaker(speaker_id, custom_name, custom_subtitle, custom_portrait_path)

func _apply_speaker_config(cfg: Dictionary) -> void:
	_active_speaker_id = str(cfg.get("id", "unknown"))
	_active_speaker_name = str(cfg.get("name", "CỐ VẤN"))
	_active_speaker_subtitle = str(cfg.get("subtitle", ""))
	var p_path: String = str(cfg.get("portrait_path", ""))

	if _speaker_label != null:
		_speaker_label.text = _active_speaker_name
	if _nameplate_name_label != null:
		_nameplate_name_label.text = _active_speaker_name
	if _nameplate_subtitle_label != null:
		_nameplate_subtitle_label.text = _active_speaker_subtitle

	if not p_path.is_empty():
		load_portrait(p_path)

func set_speaker_name(p_name: String) -> void:
	_active_speaker_name = p_name
	if _speaker_label != null:
		_speaker_label.text = p_name
	if _nameplate_name_label != null:
		_nameplate_name_label.text = p_name

func set_speaker_subtitle(p_sub: String) -> void:
	_active_speaker_subtitle = p_sub
	if _nameplate_subtitle_label != null:
		_nameplate_subtitle_label.text = p_sub

func set_dialogue_text(text: String) -> void:
	if _body_label != null:
		_body_label.text = text

func set_story_title(title: String, dungeon_label: String = "") -> void:
	if _stage_title_label != null:
		_stage_title_label.text = title
	if _dungeon_context_label != null and not dungeon_label.is_empty():
		_dungeon_context_label.text = dungeon_label

func set_portrait_texture(texture: Texture2D) -> void:
	if _draven_rect != null:
		_draven_rect.texture = texture
		_draven_rect.visible = (texture != null)

func load_portrait(path: String) -> bool:
	if path.is_empty():
		return false
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			set_portrait_texture(res as Texture2D)
			_active_portrait_path = path
			return true
	elif FileAccess.file_exists(path):
		var img: Image = Image.load_from_file(path)
		if img != null and not img.is_empty():
			var tex: ImageTexture = ImageTexture.create_from_image(img)
			set_portrait_texture(tex)
			_active_portrait_path = path
			return true
	return false

func is_input_isolated() -> bool:
	return mouse_filter == Control.MOUSE_FILTER_STOP and visible

func get_active_speaker_id() -> String:
	return _active_speaker_id

func get_active_speaker_name() -> String:
	return _active_speaker_name

func get_active_speaker_subtitle() -> String:
	return _active_speaker_subtitle

func get_active_portrait_path() -> String:
	return _active_portrait_path

func get_character_texture_rect() -> TextureRect:
	return _draven_rect

func get_character_slot() -> Control:
	return _character_slot

func get_nameplate_panel() -> Control:
	return _nameplate_panel

func _on_continue_pressed() -> void:
	if not next_step():
		continue_requested.emit()

func _on_pause_pressed() -> void:
	pause_requested.emit()

func get_top_bar() -> Control:
	return _top_bar

func get_mathos_brand_label() -> Label:
	return _mathos_brand_label

func get_dungeon_context_label() -> Label:
	return _dungeon_context_label

func get_stage_title_label() -> Label:
	return _stage_title_label

func get_phase_badge_label() -> Label:
	return _phase_badge_label

func get_pause_button() -> Button:
	return _pause_button

func get_draven_texture_rect() -> TextureRect:
	return _draven_rect

func get_draven_shader_material() -> ShaderMaterial:
	return _draven_shader_material

func get_draven_nameplate() -> Control:
	return _nameplate_panel

func get_nameplate_name_label() -> Label:
	return _nameplate_name_label

func get_nameplate_subtitle_label() -> Label:
	return _nameplate_subtitle_label

func get_dialogue_panel() -> Control:
	return _dialogue_panel

func get_speaker_label() -> Label:
	return _speaker_label

func get_body_text_label() -> RichTextLabel:
	return _body_label

func get_page_indicator_label() -> Label:
	return _page_indicator_label

func get_continue_button() -> Button:
	return _continue_button

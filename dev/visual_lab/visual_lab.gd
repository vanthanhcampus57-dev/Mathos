class_name VisualLab
extends Control

## Developer & QA Visual Asset Lab for Mathos Engine.
## Provides isolated diagnosis of visual presentation, fog overlays, frame inspection,
## procedural fog animation, side-by-side old vs new comparison, without mutating save/gameplay data.

enum LabMode { FOG_TEST, FUTURE_TAB_2, FUTURE_TAB_3 }
enum MotionMode { CURRENT_ATLAS_ANIMATION, STATIC_FRAME }
enum FogSourceMode { NEW_PROCEDURAL_LAYER, OLD_ATLAS_8F }

const D1_BG_PATH: String = "res://assets/backgrounds/dungeon_1/d1_misty_forest_bg.png"
const D1_BG_ALT_PATH: String = "res://assets/backgrounds/d1_misty_forest_bg.png"
const D1_FOG_PATH: String = "res://assets/backgrounds/dungeon_1/d1_misty_forest_fog_8f.png"
const D1_FOG_ALT_PATH: String = "res://assets/backgrounds/d1_misty_forest_fog_8f.png"
const D1_PROCEDURAL_FOG_PATH: String = "res://assets/backgrounds/dungeon_1/d1_misty_forest_fog_layer.png"
const D1_PROCEDURAL_FOG_ALT_PATH: String = "res://assets/backgrounds/d1_misty_forest_fog_layer.png"

const FOG_FRAME_WIDTH: int = 512
const FOG_FRAME_HEIGHT: int = 288
const FOG_ROWS: int = 2
const FOG_COLS: int = 4

# Production Default Parameters (Old Atlas)
const DEFAULT_FPS: float = 2.0
const DEFAULT_OLD_OPACITY: float = 2.2
const DEFAULT_MODULATE_R: float = 1.15
const DEFAULT_MODULATE_G: float = 1.25
const DEFAULT_MODULATE_B: float = 1.35

# Procedural Fog Default Parameters
const DEFAULT_PROC_OPACITY: float = 0.35
const DEFAULT_DRIFT_AMOUNT: float = 120.0
const DEFAULT_DRIFT_SPEED: float = 0.15
const DEFAULT_DISTORTION: float = 0.08
const DEFAULT_BREATHING: float = 0.05
const DEFAULT_LAYER_COUNT: int = 2

# Scene Nodes
var _bg_texture_rect: TextureRect = null
var _fog_texture_rect: TextureRect = null # Old atlas

# Procedural Fog Layer Nodes (3 layers max)
var _proc_container: Control = null
var _proc_layer_1: TextureRect = null
var _proc_layer_2: TextureRect = null
var _proc_layer_3: TextureRect = null

# Compare Mode Nodes
var _compare_container: HBoxContainer = null
var _compare_rect_a: TextureRect = null
var _compare_rect_b: TextureRect = null
var _compare_label_a: Label = null
var _compare_label_b: Label = null

# Compare Old vs New Nodes
var _compare_old_new_container: HBoxContainer = null
var _compare_old_bg: TextureRect = null
var _compare_old_fog: TextureRect = null
var _compare_new_bg: TextureRect = null
var _compare_new_proc_container: Control = null
var _compare_new_proc_l1: TextureRect = null
var _compare_new_proc_l2: TextureRect = null
var _compare_new_proc_l3: TextureRect = null

var _diag_label: Label = null

# Controls
var _fog_source_option: OptionButton = null
var _play_pause_btn: Button = null
var _prev_frame_btn: Button = null
var _next_frame_btn: Button = null
var _frame_spinbox: SpinBox = null
var _fps_slider: Slider = null
var _fps_spinbox: SpinBox = null
var _opacity_slider: Slider = null
var _opacity_spinbox: SpinBox = null
var _r_slider: Slider = null
var _g_slider: Slider = null
var _b_slider: Slider = null
var _bg_toggle: CheckBox = null
var _fog_toggle: CheckBox = null
var _compare_toggle: CheckBox = null
var _compare_old_new_toggle: CheckBox = null
var _reset_btn: Button = null
var _motion_option: OptionButton = null

# Procedural Controls
var _proc_ctrl_box: VBoxContainer = null
var _old_ctrl_box: VBoxContainer = null
var _proc_opacity_slider: Slider = null
var _proc_opacity_spinbox: SpinBox = null
var _drift_amount_slider: Slider = null
var _drift_amount_spinbox: SpinBox = null
var _drift_speed_slider: Slider = null
var _drift_speed_spinbox: SpinBox = null
var _distortion_slider: Slider = null
var _distortion_spinbox: SpinBox = null
var _breathing_slider: Slider = null
var _breathing_spinbox: SpinBox = null
var _layer_count_option: OptionButton = null

# State
var _current_lab_mode: LabMode = LabMode.FOG_TEST
var _fog_source_mode: FogSourceMode = FogSourceMode.NEW_PROCEDURAL_LAYER
var _current_motion_mode: MotionMode = MotionMode.CURRENT_ATLAS_ANIMATION
var _is_playing: bool = true

# Textures
var _bg_texture: Texture2D = null
var _fog_frames: Array[AtlasTexture] = []
var _fog_source_texture: Texture2D = null
var _procedural_texture: Texture2D = null

# Old Atlas State
var _fog_current_frame: int = 0
var _fog_frame_timer: float = 0.0
var _fps: float = DEFAULT_FPS
var _old_opacity: float = DEFAULT_OLD_OPACITY
var _mod_r: float = DEFAULT_MODULATE_R
var _mod_g: float = DEFAULT_MODULATE_G
var _mod_b: float = DEFAULT_MODULATE_B

# Procedural Fog State
var _procedural_time: float = 0.0
var _proc_opacity: float = DEFAULT_PROC_OPACITY
var _proc_mod_r: float = 1.0
var _proc_mod_g: float = 1.0
var _proc_mod_b: float = 1.0
var _drift_amount: float = DEFAULT_DRIFT_AMOUNT
var _drift_speed: float = DEFAULT_DRIFT_SPEED
var _distortion: float = DEFAULT_DISTORTION
var _breathing: float = DEFAULT_BREATHING
var _layer_count: int = DEFAULT_LAYER_COUNT

# Common Toggles
var _bg_visible: bool = true
var _fog_visible: bool = true
var _compare_mode: bool = false
var _compare_old_vs_new_mode: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_all_textures()
	_build_ui_hierarchy()
	_apply_parameters()
	_update_diagnostic_display()

func _load_all_textures() -> void:
	# 1. Background
	_bg_texture = _load_texture([D1_BG_PATH, D1_BG_ALT_PATH])

	# 2. Old Atlas Fog
	if _fog_frames.is_empty():
		_fog_source_texture = _load_texture([D1_FOG_PATH, D1_FOG_ALT_PATH])
		if _fog_source_texture != null:
			_fog_frames.clear()
			for row in range(FOG_ROWS):
				for col in range(FOG_COLS):
					var atlas_tex: AtlasTexture = AtlasTexture.new()
					atlas_tex.atlas = _fog_source_texture
					atlas_tex.region = Rect2(float(col * FOG_FRAME_WIDTH), float(row * FOG_FRAME_HEIGHT), float(FOG_FRAME_WIDTH), float(FOG_FRAME_HEIGHT))
					_fog_frames.append(atlas_tex)

	# 3. New Procedural Fog Layer
	_procedural_texture = _load_texture([D1_PROCEDURAL_FOG_PATH, D1_PROCEDURAL_FOG_ALT_PATH])

func _load_texture(paths: Array[String]) -> Texture2D:
	for p in paths:
		if FileAccess.file_exists(p) or ResourceLoader.exists(p):
			var tex: Texture2D = load(p) as Texture2D
			if tex != null:
				return tex
		var global_p: String = ProjectSettings.globalize_path(p)
		if FileAccess.file_exists(global_p):
			var tex: Texture2D = load(global_p) as Texture2D
			if tex != null:
				return tex
	return null

func get_procedural_texture() -> Texture2D:
	_load_all_textures()
	return _procedural_texture

func get_fog_frames() -> Array[AtlasTexture]:
	_load_all_textures()
	return _fog_frames

func _process(delta: float) -> void:
	if _current_lab_mode != LabMode.FOG_TEST:
		return

	if _is_playing:
		# Old atlas tick
		if not _fog_frames.is_empty() and _fps > 0.0 and _current_motion_mode == MotionMode.CURRENT_ATLAS_ANIMATION:
			_fog_frame_timer += delta
			var frame_dur: float = 1.0 / _fps
			if _fog_frame_timer >= frame_dur:
				_fog_frame_timer = fmod(_fog_frame_timer, frame_dur)
				_fog_current_frame = (_fog_current_frame + 1) % _fog_frames.size()
				_update_frame_display()

		# Procedural motion tick
		_procedural_time += delta
		_update_procedural_motion()

	_update_diagnostic_display()

func _update_procedural_motion() -> void:
	if _procedural_texture == null or not is_inside_tree():
		return

	var time: float = _procedural_time * _drift_speed
	var vp_size: Vector2 = get_viewport_rect().size

	# Layer 1 (Front)
	if _proc_layer_1 != null:
		var off_x1: float = sin(time * 0.7) * _drift_amount
		var off_y1: float = cos(time * 0.4) * (_distortion * 20.0)
		var scale1: float = 1.0 + sin(time * 0.3) * (_distortion * 0.05)
		var alpha1: float = clampf(_proc_opacity * (1.0 + sin(time * 0.8) * _breathing), 0.0, 1.0)
		_proc_layer_1.modulate = Color(_proc_mod_r, _proc_mod_g, _proc_mod_b, alpha1)
		_proc_layer_1.position = Vector2(off_x1, off_y1)
		_proc_layer_1.scale = Vector2(scale1, scale1)

	# Layer 2 (Mid)
	if _proc_layer_2 != null:
		var off_x2: float = cos(time * 0.5 + 1.5) * (_drift_amount * 0.8)
		var off_y2: float = sin(time * 0.3 + 2.0) * (_distortion * 15.0)
		var scale2: float = 1.05 + cos(time * 0.2) * (_distortion * 0.04)
		var alpha2: float = clampf((_proc_opacity * 0.65) * (1.0 + cos(time * 0.6) * _breathing), 0.0, 1.0)
		_proc_layer_2.modulate = Color(_proc_mod_r, _proc_mod_g, _proc_mod_b, alpha2)
		_proc_layer_2.position = Vector2(off_x2, off_y2)
		_proc_layer_2.scale = Vector2(scale2, scale2)
		_proc_layer_2.visible = (_layer_count >= 2)

	# Layer 3 (Back)
	if _proc_layer_3 != null:
		var off_x3: float = sin(time * 0.3 + 3.0) * (_drift_amount * 1.2)
		var off_y3: float = sin(time * 0.5 + 1.0) * (_distortion * 25.0)
		var scale3: float = 1.1 + sin(time * 0.1) * (_distortion * 0.03)
		var alpha3: float = clampf((_proc_opacity * 0.45) * (1.0 + sin(time * 0.4) * _breathing), 0.0, 1.0)
		_proc_layer_3.modulate = Color(_proc_mod_r, _proc_mod_g, _proc_mod_b, alpha3)
		_proc_layer_3.position = Vector2(off_x3, off_y3)
		_proc_layer_3.scale = Vector2(scale3, scale3)
		_proc_layer_3.visible = (_layer_count >= 3)

	# Compare Old vs New right panel
	if _compare_old_vs_new_mode and _compare_new_proc_container != null:
		if _compare_new_proc_l1 != null:
			_compare_new_proc_l1.modulate = _proc_layer_1.modulate
			_compare_new_proc_l1.position = _proc_layer_1.position * 0.5
		if _compare_new_proc_l2 != null:
			_compare_new_proc_l2.modulate = _proc_layer_2.modulate
			_compare_new_proc_l2.position = _proc_layer_2.position * 0.5
			_compare_new_proc_l2.visible = (_layer_count >= 2)
		if _compare_new_proc_l3 != null:
			_compare_new_proc_l3.modulate = _proc_layer_3.modulate
			_compare_new_proc_l3.position = _proc_layer_3.position * 0.5
			_compare_new_proc_l3.visible = (_layer_count >= 3)

func _build_ui_hierarchy() -> void:
	# 1. Background Texture Rect
	_bg_texture_rect = TextureRect.new()
	_bg_texture_rect.name = "BackgroundTextureRect"
	_bg_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture_rect.texture = _bg_texture
	add_child(_bg_texture_rect)

	# 2. Old Atlas Fog Overlay Texture Rect
	_fog_texture_rect = TextureRect.new()
	_fog_texture_rect.name = "FogOverlayTextureRect"
	_fog_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fog_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fog_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fog_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fog_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _fog_frames.is_empty():
		_fog_texture_rect.texture = _fog_frames[0]
	add_child(_fog_texture_rect)

	# 3. New Procedural Fog Layer Container
	_proc_container = Control.new()
	_proc_container.name = "ProceduralFogContainer"
	_proc_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_proc_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_proc_layer_3 = TextureRect.new()
	_proc_layer_3.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_proc_layer_3.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_proc_layer_3.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_proc_layer_3.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_proc_layer_3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_proc_layer_3.texture = _procedural_texture

	_proc_layer_2 = TextureRect.new()
	_proc_layer_2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_proc_layer_2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_proc_layer_2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_proc_layer_2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_proc_layer_2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_proc_layer_2.texture = _procedural_texture

	_proc_layer_1 = TextureRect.new()
	_proc_layer_1.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_proc_layer_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_proc_layer_1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_proc_layer_1.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_proc_layer_1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_proc_layer_1.texture = _procedural_texture

	_proc_container.add_child(_proc_layer_3)
	_proc_container.add_child(_proc_layer_2)
	_proc_container.add_child(_proc_layer_1)
	add_child(_proc_container)

	# 4. Compare Container (Atlas Frame N vs N+1)
	_compare_container = HBoxContainer.new()
	_compare_container.name = "CompareContainer"
	_compare_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compare_container.visible = false

	var box_a: VBoxContainer = VBoxContainer.new()
	box_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compare_label_a = Label.new(); _compare_label_a.text = "FRAME N"; _compare_label_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compare_rect_a = TextureRect.new(); _compare_rect_a.size_flags_vertical = Control.SIZE_EXPAND_FILL; _compare_rect_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _compare_rect_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box_a.add_child(_compare_label_a); box_a.add_child(_compare_rect_a)

	var box_b: VBoxContainer = VBoxContainer.new()
	box_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compare_label_b = Label.new(); _compare_label_b.text = "FRAME N+1"; _compare_label_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compare_rect_b = TextureRect.new(); _compare_rect_b.size_flags_vertical = Control.SIZE_EXPAND_FILL; _compare_rect_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _compare_rect_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box_b.add_child(_compare_label_b); box_b.add_child(_compare_rect_b)

	_compare_container.add_child(box_a); _compare_container.add_child(box_b)
	add_child(_compare_container)

	# 5. Compare Old vs New Container (Side-by-side decision view)
	_compare_old_new_container = HBoxContainer.new()
	_compare_old_new_container.name = "CompareOldVsNewContainer"
	_compare_old_new_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compare_old_new_container.visible = false

	# Left panel (Old Atlas)
	var left_side: SubViewportContainer = SubViewportContainer.new()
	left_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_side.stretch = true
	var vp_old: SubViewport = SubViewport.new()
	vp_old.size = Vector2i(640, 720)
	_compare_old_bg = TextureRect.new()
	_compare_old_bg.texture = _bg_texture
	_compare_old_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compare_old_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_compare_old_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_compare_old_fog = TextureRect.new()
	_compare_old_fog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compare_old_fog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_compare_old_fog.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if not _fog_frames.is_empty(): _compare_old_fog.texture = _fog_frames[0]
	var lbl_left: Label = Label.new()
	lbl_left.text = " OLD 8-FRAME ATLAS FOG "
	lbl_left.position = Vector2(16, 16)
	vp_old.add_child(_compare_old_bg)
	vp_old.add_child(_compare_old_fog)
	vp_old.add_child(lbl_left)
	left_side.add_child(vp_old)

	# Right panel (New Procedural)
	var right_side: SubViewportContainer = SubViewportContainer.new()
	right_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_side.stretch = true
	var vp_new: SubViewport = SubViewport.new()
	vp_new.size = Vector2i(640, 720)
	_compare_new_bg = TextureRect.new()
	_compare_new_bg.texture = _bg_texture
	_compare_new_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compare_new_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_compare_new_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	_compare_new_proc_container = Control.new()
	_compare_new_proc_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compare_new_proc_l3 = TextureRect.new(); _compare_new_proc_l3.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _compare_new_proc_l3.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _compare_new_proc_l3.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; _compare_new_proc_l3.texture = _procedural_texture
	_compare_new_proc_l2 = TextureRect.new(); _compare_new_proc_l2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _compare_new_proc_l2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _compare_new_proc_l2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; _compare_new_proc_l2.texture = _procedural_texture
	_compare_new_proc_l1 = TextureRect.new(); _compare_new_proc_l1.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _compare_new_proc_l1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _compare_new_proc_l1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; _compare_new_proc_l1.texture = _procedural_texture
	_compare_new_proc_container.add_child(_compare_new_proc_l3)
	_compare_new_proc_container.add_child(_compare_new_proc_l2)
	_compare_new_proc_container.add_child(_compare_new_proc_l1)

	var lbl_right: Label = Label.new()
	lbl_right.text = " NEW PROCEDURAL LAYER FOG "
	lbl_right.position = Vector2(16, 16)
	vp_new.add_child(_compare_new_bg)
	vp_new.add_child(_compare_new_proc_container)
	vp_new.add_child(lbl_right)
	right_side.add_child(vp_new)

	_compare_old_new_container.add_child(left_side)
	_compare_old_new_container.add_child(right_side)
	add_child(_compare_old_new_container)

	# 6. Top Header & Mode Tabs
	var top_bar: PanelContainer = PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 40.0
	var top_box: HBoxContainer = HBoxContainer.new()

	var title_lbl: Label = Label.new(); title_lbl.text = " 🔬 MATHOS VISUAL LAB "
	top_box.add_child(title_lbl)

	var tab_fog: Button = Button.new(); tab_fog.text = "FOG TEST"; tab_fog.pressed.connect(func(): set_lab_mode(LabMode.FOG_TEST))
	top_box.add_child(tab_fog)

	top_bar.add_child(top_box)
	add_child(top_bar)

	# 7. Developer Control Dock (Left Floating Panel)
	var ctrl_panel: PanelContainer = PanelContainer.new()
	ctrl_panel.name = "ControlDock"
	ctrl_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	ctrl_panel.offset_top = 48.0
	ctrl_panel.offset_right = 340.0
	ctrl_panel.offset_bottom = -16.0

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Fog Source Selector
	var src_lbl: Label = Label.new(); src_lbl.text = "FOG SOURCE:"
	_fog_source_option = OptionButton.new()
	_fog_source_option.add_item("New Procedural Layer", FogSourceMode.NEW_PROCEDURAL_LAYER)
	_fog_source_option.add_item("Old Atlas 8F", FogSourceMode.OLD_ATLAS_8F)
	_fog_source_option.select(0)
	_fog_source_option.item_selected.connect(_on_fog_source_selected)
	vbox.add_child(src_lbl)
	vbox.add_child(_fog_source_option)

	# Global Play/Pause
	var play_box: HBoxContainer = HBoxContainer.new()
	_play_pause_btn = Button.new(); _play_pause_btn.text = "Pause"; _play_pause_btn.pressed.connect(_on_play_pause_pressed)
	play_box.add_child(_play_pause_btn)
	vbox.add_child(play_box)

	# --- OLD ATLAS CONTROLS BOX ---
	_old_ctrl_box = VBoxContainer.new()
	_old_ctrl_box.name = "OldAtlasControls"
	_old_ctrl_box.visible = false

	var hdr_old: Label = Label.new(); hdr_old.text = "=== OLD ATLAS CONTROLS ==="
	_old_ctrl_box.add_child(hdr_old)

	var old_step_box: HBoxContainer = HBoxContainer.new()
	_prev_frame_btn = Button.new(); _prev_frame_btn.text = "< Prev"; _prev_frame_btn.pressed.connect(step_previous_frame); old_step_box.add_child(_prev_frame_btn)
	_next_frame_btn = Button.new(); _next_frame_btn.text = "Next >"; _next_frame_btn.pressed.connect(step_next_frame); old_step_box.add_child(_next_frame_btn)
	_old_ctrl_box.add_child(old_step_box)

	var frame_box: HBoxContainer = HBoxContainer.new()
	var frame_lbl: Label = Label.new(); frame_lbl.text = "Frame (0..7):"
	_frame_spinbox = SpinBox.new(); _frame_spinbox.min_value = 0; _frame_spinbox.max_value = 7; _frame_spinbox.step = 1; _frame_spinbox.value = 0; _frame_spinbox.value_changed.connect(_on_frame_spinbox_changed)
	frame_box.add_child(frame_lbl); frame_box.add_child(_frame_spinbox)
	_old_ctrl_box.add_child(frame_box)

	var motion_lbl: Label = Label.new(); motion_lbl.text = "Motion Mode:"
	_motion_option = OptionButton.new()
	_motion_option.add_item("CURRENT_ATLAS_ANIMATION", MotionMode.CURRENT_ATLAS_ANIMATION)
	_motion_option.add_item("STATIC_FRAME", MotionMode.STATIC_FRAME)
	_motion_option.item_selected.connect(_on_motion_mode_selected)
	_old_ctrl_box.add_child(motion_lbl); _old_ctrl_box.add_child(_motion_option)

	var fps_lbl: Label = Label.new(); fps_lbl.text = "FPS (0.5 -> 15):"
	var fps_box: HBoxContainer = HBoxContainer.new()
	_fps_slider = HSlider.new(); _fps_slider.min_value = 0.5; _fps_slider.max_value = 15.0; _fps_slider.step = 0.5; _fps_slider.value = DEFAULT_FPS; _fps_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fps_spinbox = SpinBox.new(); _fps_spinbox.min_value = 0.5; _fps_spinbox.max_value = 15.0; _fps_spinbox.step = 0.5; _fps_spinbox.value = DEFAULT_FPS
	_fps_slider.value_changed.connect(func(v): set_fps(v)); _fps_spinbox.value_changed.connect(func(v): set_fps(v))
	fps_box.add_child(_fps_slider); fps_box.add_child(_fps_spinbox)
	_old_ctrl_box.add_child(fps_lbl); _old_ctrl_box.add_child(fps_box)

	var op_old_lbl: Label = Label.new(); op_old_lbl.text = "Atlas Opacity (0 -> 2.5):"
	var op_old_box: HBoxContainer = HBoxContainer.new()
	_opacity_slider = HSlider.new(); _opacity_slider.min_value = 0.0; _opacity_slider.max_value = 2.5; _opacity_slider.step = 0.1; _opacity_slider.value = DEFAULT_OLD_OPACITY; _opacity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opacity_spinbox = SpinBox.new(); _opacity_spinbox.min_value = 0.0; _opacity_spinbox.max_value = 2.5; _opacity_spinbox.step = 0.1; _opacity_spinbox.value = DEFAULT_OLD_OPACITY
	_opacity_slider.value_changed.connect(func(v): set_opacity(v)); _opacity_spinbox.value_changed.connect(func(v): set_opacity(v))
	op_old_box.add_child(_opacity_slider); op_old_box.add_child(_opacity_spinbox)
	_old_ctrl_box.add_child(op_old_lbl); _old_ctrl_box.add_child(op_old_box)

	_compare_toggle = CheckBox.new(); _compare_toggle.text = "Compare Frames (N vs N+1)"; _compare_toggle.button_pressed = false; _compare_toggle.toggled.connect(func(t): set_compare_mode(t))
	_old_ctrl_box.add_child(_compare_toggle)

	vbox.add_child(_old_ctrl_box)

	# --- NEW PROCEDURAL CONTROLS BOX ---
	_proc_ctrl_box = VBoxContainer.new()
	_proc_ctrl_box.name = "ProceduralControls"

	var hdr_proc: Label = Label.new(); hdr_proc.text = "=== PROCEDURAL CONTROLS ==="
	_proc_ctrl_box.add_child(hdr_proc)

	# Procedural Opacity (0.00 -> 1.00)
	var op_proc_lbl: Label = Label.new(); op_proc_lbl.text = "Opacity (0.00 -> 1.00):"
	var op_proc_box: HBoxContainer = HBoxContainer.new()
	_proc_opacity_slider = HSlider.new(); _proc_opacity_slider.min_value = 0.0; _proc_opacity_slider.max_value = 1.0; _proc_opacity_slider.step = 0.01; _proc_opacity_slider.value = DEFAULT_PROC_OPACITY; _proc_opacity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_proc_opacity_spinbox = SpinBox.new(); _proc_opacity_spinbox.min_value = 0.0; _proc_opacity_spinbox.max_value = 1.0; _proc_opacity_spinbox.step = 0.01; _proc_opacity_spinbox.value = DEFAULT_PROC_OPACITY
	_proc_opacity_slider.value_changed.connect(func(v): set_procedural_opacity(v)); _proc_opacity_spinbox.value_changed.connect(func(v): set_procedural_opacity(v))
	op_proc_box.add_child(_proc_opacity_slider); op_proc_box.add_child(_proc_opacity_spinbox)
	_proc_ctrl_box.add_child(op_proc_lbl); _proc_ctrl_box.add_child(op_proc_box)

	# Drift Amount (0 -> 300 px)
	var drift_lbl: Label = Label.new(); drift_lbl.text = "Drift Amount (0 -> 300 px):"
	var drift_box: HBoxContainer = HBoxContainer.new()
	_drift_amount_slider = HSlider.new(); _drift_amount_slider.min_value = 0.0; _drift_amount_slider.max_value = 300.0; _drift_amount_slider.step = 5.0; _drift_amount_slider.value = DEFAULT_DRIFT_AMOUNT; _drift_amount_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drift_amount_spinbox = SpinBox.new(); _drift_amount_spinbox.min_value = 0.0; _drift_amount_spinbox.max_value = 300.0; _drift_amount_spinbox.step = 5.0; _drift_amount_spinbox.value = DEFAULT_DRIFT_AMOUNT
	_drift_amount_slider.value_changed.connect(func(v): set_drift_amount(v)); _drift_amount_spinbox.value_changed.connect(func(v): set_drift_amount(v))
	drift_box.add_child(_drift_amount_slider); drift_box.add_child(_drift_amount_spinbox)
	_proc_ctrl_box.add_child(drift_lbl); _proc_ctrl_box.add_child(drift_box)

	# Drift Speed (0.00 -> 1.00)
	var speed_lbl: Label = Label.new(); speed_lbl.text = "Drift Speed (0.00 -> 1.00):"
	var speed_box: HBoxContainer = HBoxContainer.new()
	_drift_speed_slider = HSlider.new(); _drift_speed_slider.min_value = 0.0; _drift_speed_slider.max_value = 1.0; _drift_speed_slider.step = 0.01; _drift_speed_slider.value = DEFAULT_DRIFT_SPEED; _drift_speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drift_speed_spinbox = SpinBox.new(); _drift_speed_spinbox.min_value = 0.0; _drift_speed_spinbox.max_value = 1.0; _drift_speed_spinbox.step = 0.01; _drift_speed_spinbox.value = DEFAULT_DRIFT_SPEED
	_drift_speed_slider.value_changed.connect(func(v): set_drift_speed(v)); _drift_speed_spinbox.value_changed.connect(func(v): set_drift_speed(v))
	speed_box.add_child(_drift_speed_slider); speed_box.add_child(_drift_speed_spinbox)
	_proc_ctrl_box.add_child(speed_lbl); _proc_ctrl_box.add_child(speed_box)

	# Distortion (0.00 -> 0.50)
	var dist_lbl: Label = Label.new(); dist_lbl.text = "Distortion (0.00 -> 0.50):"
	var dist_box: HBoxContainer = HBoxContainer.new()
	_distortion_slider = HSlider.new(); _distortion_slider.min_value = 0.0; _distortion_slider.max_value = 0.50; _distortion_slider.step = 0.01; _distortion_slider.value = DEFAULT_DISTORTION; _distortion_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_distortion_spinbox = SpinBox.new(); _distortion_spinbox.min_value = 0.0; _distortion_spinbox.max_value = 0.50; _distortion_spinbox.step = 0.01; _distortion_spinbox.value = DEFAULT_DISTORTION
	_distortion_slider.value_changed.connect(func(v): set_distortion(v)); _distortion_spinbox.value_changed.connect(func(v): set_distortion(v))
	dist_box.add_child(_distortion_slider); dist_box.add_child(_distortion_spinbox)
	_proc_ctrl_box.add_child(dist_lbl); _proc_ctrl_box.add_child(dist_box)

	# Breathing (0.00 -> 0.30)
	var breath_lbl: Label = Label.new(); breath_lbl.text = "Breathing (0.00 -> 0.30):"
	var breath_box: HBoxContainer = HBoxContainer.new()
	_breathing_slider = HSlider.new(); _breathing_slider.min_value = 0.0; _breathing_slider.max_value = 0.30; _breathing_slider.step = 0.01; _breathing_slider.value = DEFAULT_BREATHING; _breathing_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_breathing_spinbox = SpinBox.new(); _breathing_spinbox.min_value = 0.0; _breathing_spinbox.max_value = 0.30; _breathing_spinbox.step = 0.01; _breathing_spinbox.value = DEFAULT_BREATHING
	_breathing_slider.value_changed.connect(func(v): set_breathing(v)); _breathing_spinbox.value_changed.connect(func(v): set_breathing(v))
	breath_box.add_child(_breathing_slider); breath_box.add_child(_breathing_spinbox)
	_proc_ctrl_box.add_child(breath_lbl); _proc_ctrl_box.add_child(breath_box)

	# Layer Count (1 / 2 / 3)
	var layer_lbl: Label = Label.new(); layer_lbl.text = "Layer Count:"
	_layer_count_option = OptionButton.new()
	_layer_count_option.add_item("1 Layer", 1)
	_layer_count_option.add_item("2 Layers", 2)
	_layer_count_option.add_item("3 Layers", 3)
	_layer_count_option.select(1)
	_layer_count_option.item_selected.connect(func(idx): set_layer_count(idx + 1))
	_proc_ctrl_box.add_child(layer_lbl); _proc_ctrl_box.add_child(_layer_count_option)

	vbox.add_child(_proc_ctrl_box)

	# Global Toggles
	var hdr_glob: Label = Label.new(); hdr_glob.text = "=== GLOBAL TOGGLES ==="
	vbox.add_child(hdr_glob)

	_bg_toggle = CheckBox.new(); _bg_toggle.text = "Background"; _bg_toggle.button_pressed = true; _bg_toggle.toggled.connect(func(t): set_background_visible(t))
	vbox.add_child(_bg_toggle)

	_fog_toggle = CheckBox.new(); _fog_toggle.text = "Fog Layer"; _fog_toggle.button_pressed = true; _fog_toggle.toggled.connect(func(t): set_fog_visible(t))
	vbox.add_child(_fog_toggle)

	_compare_old_new_toggle = CheckBox.new(); _compare_old_new_toggle.text = "Compare Old vs New"; _compare_old_new_toggle.button_pressed = false; _compare_old_new_toggle.toggled.connect(func(t): set_compare_old_vs_new_mode(t))
	vbox.add_child(_compare_old_new_toggle)

	_reset_btn = Button.new(); _reset_btn.text = "[ Reset Defaults ]"; _reset_btn.pressed.connect(reset_defaults)
	vbox.add_child(_reset_btn)

	scroll.add_child(vbox)
	ctrl_panel.add_child(scroll)
	add_child(ctrl_panel)

	# 8. Diagnostic Label Overlay
	var diag_panel: PanelContainer = PanelContainer.new()
	diag_panel.name = "DiagPanel"
	diag_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	diag_panel.offset_left = -360.0
	diag_panel.offset_top = 48.0
	diag_panel.offset_right = -16.0

	_diag_label = Label.new(); _diag_label.text = "FOG DIAGNOSTICS"
	diag_panel.add_child(_diag_label)
	add_child(diag_panel)

func _on_fog_source_selected(idx: int) -> void:
	set_fog_source_mode(idx as FogSourceMode)

func set_fog_source_mode(mode: FogSourceMode) -> void:
	_fog_source_mode = mode
	if _fog_source_option != null and _fog_source_option.selected != int(_fog_source_mode):
		_fog_source_option.select(int(_fog_source_mode))

	if _proc_ctrl_box != null:
		_proc_ctrl_box.visible = (_fog_source_mode == FogSourceMode.NEW_PROCEDURAL_LAYER)
	if _old_ctrl_box != null:
		_old_ctrl_box.visible = (_fog_source_mode == FogSourceMode.OLD_ATLAS_8F)

	_apply_parameters()

func _apply_parameters() -> void:
	if _bg_texture_rect != null:
		_bg_texture_rect.visible = _bg_visible and not _compare_old_vs_new_mode

	if _fog_source_mode == FogSourceMode.OLD_ATLAS_8F:
		if _fog_texture_rect != null:
			_fog_texture_rect.visible = _fog_visible and not _compare_mode and not _compare_old_vs_new_mode
			_fog_texture_rect.modulate = Color(_mod_r, _mod_g, _mod_b, _old_opacity)
		if _proc_container != null:
			_proc_container.visible = false
		_update_frame_display()
	else:
		if _fog_texture_rect != null:
			_fog_texture_rect.visible = false
		if _proc_container != null:
			_proc_container.visible = _fog_visible and not _compare_old_vs_new_mode
		_update_procedural_motion()

func _update_frame_display() -> void:
	if _fog_frames.is_empty():
		return

	_fog_current_frame = clampi(_fog_current_frame, 0, _fog_frames.size() - 1)

	if _fog_texture_rect != null:
		_fog_texture_rect.texture = _fog_frames[_fog_current_frame]

	if _compare_old_fog != null:
		_compare_old_fog.texture = _fog_frames[_fog_current_frame]

	if _frame_spinbox != null and int(_frame_spinbox.value) != _fog_current_frame:
		_frame_spinbox.set_value_no_signal(_fog_current_frame)

	if _compare_mode:
		var next_idx: int = (_fog_current_frame + 1) % _fog_frames.size()
		if _compare_rect_a != null:
			_compare_rect_a.texture = _fog_frames[_fog_current_frame]
			_compare_rect_a.modulate = Color(_mod_r, _mod_g, _mod_b, _old_opacity)
		if _compare_rect_b != null:
			_compare_rect_b.texture = _fog_frames[next_idx]
			_compare_rect_b.modulate = Color(_mod_r, _mod_g, _mod_b, _old_opacity)
		if _compare_label_a != null:
			_compare_label_a.text = "FRAME %d / 7" % _fog_current_frame
		if _compare_label_b != null:
			_compare_label_b.text = "FRAME %d / 7" % next_idx

func _update_diagnostic_display() -> void:
	if _diag_label == null or not is_inside_tree():
		return

	var vp_size: Vector2 = get_viewport_rect().size

	if _compare_old_vs_new_mode:
		_diag_label.text = "\n".join([
			"COMPARE MODE: OLD vs NEW",
			"LEFT: Old 8-Frame Atlas",
			"RIGHT: New Procedural Layer",
			"PLAYING: %s" % str(_is_playing),
			"VIEWPORT: %.0fx%.0f" % [vp_size.x, vp_size.y]
		])
		return

	if _fog_source_mode == FogSourceMode.OLD_ATLAS_8F:
		var disp_rect: Rect2 = _fog_texture_rect.get_global_rect() if _fog_texture_rect != null else Rect2()
		var region_rect: Rect2 = _fog_frames[_fog_current_frame].region if not _fog_frames.is_empty() and _fog_current_frame < _fog_frames.size() else Rect2()
		_diag_label.text = "\n".join([
			"FOG SOURCE: Old Atlas 8F",
			"SHEET: 2048x576",
			"GRID: 4x2",
			"FRAME: 512x288",
			"ATLAS REGION: [P: (%.0f, %.0f), S: (%.0f, %.0f)]" % [region_rect.position.x, region_rect.position.y, region_rect.size.x, region_rect.size.y],
			"DISPLAY: %.0fx%.0f" % [disp_rect.size.x, disp_rect.size.y],
			"VIEWPORT: %.0fx%.0f" % [vp_size.x, vp_size.y],
			"FRAME INDEX: %d / 7" % _fog_current_frame,
			"FPS: %.1f" % _fps,
			"OPACITY: %.2f" % _old_opacity,
			"PLAYING: %s" % str(_is_playing),
			"VISIBLE: %s" % str(_fog_visible)
		])
	else:
		var disp_rect: Rect2 = _proc_layer_1.get_global_rect() if _proc_layer_1 != null else Rect2()
		var w: int = _procedural_texture.get_width() if _procedural_texture != null else 2048
		var h: int = _procedural_texture.get_height() if _procedural_texture != null else 720
		_diag_label.text = "\n".join([
			"FOG SOURCE: d1_misty_forest_fog_layer.png",
			"SOURCE SIZE: %dx%d" % [w, h],
			"DISPLAY RECT: %.0fx%.0f" % [disp_rect.size.x, disp_rect.size.y],
			"VIEWPORT: %.0fx%.0f" % [vp_size.x, vp_size.y],
			"OPACITY: %.2f" % _proc_opacity,
			"DRIFT AMOUNT: %.0f px" % _drift_amount,
			"DRIFT SPEED: %.2f" % _drift_speed,
			"DISTORTION: %.2f" % _distortion,
			"BREATHING: %.2f" % _breathing,
			"LAYERS: %d" % _layer_count,
			"ANIMATION TIME: %.1f s" % _procedural_time,
			"PLAYING: %s" % str(_is_playing),
			"VISIBLE: %s" % str(_fog_visible)
		])

# Control Actions
func _on_play_pause_pressed() -> void:
	set_playing(not _is_playing)

func set_playing(play: bool) -> void:
	_is_playing = play
	if _play_pause_btn != null:
		_play_pause_btn.text = "Pause" if _is_playing else "Play"

func step_next_frame() -> void:
	_load_all_textures()
	if _fog_frames.is_empty():
		return
	_fog_current_frame = (_fog_current_frame + 1) % _fog_frames.size()
	_update_frame_display()

func step_previous_frame() -> void:
	_load_all_textures()
	if _fog_frames.is_empty():
		return
	_fog_current_frame = (_fog_current_frame - 1 + _fog_frames.size()) % _fog_frames.size()
	_update_frame_display()

func set_frame_index(idx: int) -> void:
	_load_all_textures()
	if _fog_frames.is_empty():
		return
	_fog_current_frame = clampi(idx, 0, _fog_frames.size() - 1)
	_update_frame_display()

func _on_frame_spinbox_changed(val: float) -> void:
	set_frame_index(int(val))

func _on_motion_mode_selected(idx: int) -> void:
	set_motion_mode(idx as MotionMode)

func set_motion_mode(mode: MotionMode) -> void:
	_current_motion_mode = mode
	if _motion_option != null and _motion_option.selected != int(_current_motion_mode):
		_motion_option.select(int(_current_motion_mode))
	if _current_motion_mode == MotionMode.STATIC_FRAME:
		set_playing(false)

func set_fps(val: float) -> void:
	_fps = clampf(val, 0.5, 15.0)
	if _fps_slider != null and not is_equal_approx(_fps_slider.value, _fps): _fps_slider.set_value_no_signal(_fps)
	if _fps_spinbox != null and not is_equal_approx(_fps_spinbox.value, _fps): _fps_spinbox.set_value_no_signal(_fps)

func set_opacity(val: float) -> void:
	_old_opacity = clampf(val, 0.0, 2.5)
	if _opacity_slider != null and not is_equal_approx(_opacity_slider.value, _old_opacity): _opacity_slider.set_value_no_signal(_old_opacity)
	if _opacity_spinbox != null and not is_equal_approx(_opacity_spinbox.value, _old_opacity): _opacity_spinbox.set_value_no_signal(_old_opacity)
	_apply_parameters()

func set_procedural_opacity(val: float) -> void:
	_proc_opacity = clampf(val, 0.0, 1.0)
	if _proc_opacity_slider != null and not is_equal_approx(_proc_opacity_slider.value, _proc_opacity): _proc_opacity_slider.set_value_no_signal(_proc_opacity)
	if _proc_opacity_spinbox != null and not is_equal_approx(_proc_opacity_spinbox.value, _proc_opacity): _proc_opacity_spinbox.set_value_no_signal(_proc_opacity)
	_apply_parameters()

func set_drift_amount(val: float) -> void:
	_drift_amount = clampf(val, 0.0, 300.0)
	if _drift_amount_slider != null and not is_equal_approx(_drift_amount_slider.value, _drift_amount): _drift_amount_slider.set_value_no_signal(_drift_amount)
	if _drift_amount_spinbox != null and not is_equal_approx(_drift_amount_spinbox.value, _drift_amount): _drift_amount_spinbox.set_value_no_signal(_drift_amount)
	_apply_parameters()

func set_drift_speed(val: float) -> void:
	_drift_speed = clampf(val, 0.0, 1.0)
	if _drift_speed_slider != null and not is_equal_approx(_drift_speed_slider.value, _drift_speed): _drift_speed_slider.set_value_no_signal(_drift_speed)
	if _drift_speed_spinbox != null and not is_equal_approx(_drift_speed_spinbox.value, _drift_speed): _drift_speed_spinbox.set_value_no_signal(_drift_speed)
	_apply_parameters()

func set_distortion(val: float) -> void:
	_distortion = clampf(val, 0.0, 0.50)
	if _distortion_slider != null and not is_equal_approx(_distortion_slider.value, _distortion): _distortion_slider.set_value_no_signal(_distortion)
	if _distortion_spinbox != null and not is_equal_approx(_distortion_spinbox.value, _distortion): _distortion_spinbox.set_value_no_signal(_distortion)
	_apply_parameters()

func set_breathing(val: float) -> void:
	_breathing = clampf(val, 0.0, 0.30)
	if _breathing_slider != null and not is_equal_approx(_breathing_slider.value, _breathing): _breathing_slider.set_value_no_signal(_breathing)
	if _breathing_spinbox != null and not is_equal_approx(_breathing_spinbox.value, _breathing): _breathing_spinbox.set_value_no_signal(_breathing)
	_apply_parameters()

func set_layer_count(cnt: int) -> void:
	_layer_count = clampi(cnt, 1, 3)
	if _layer_count_option != null and _layer_count_option.selected != (_layer_count - 1):
		_layer_count_option.select(_layer_count - 1)
	_apply_parameters()

func set_background_visible(vis: bool) -> void:
	_bg_visible = vis
	if _bg_toggle != null and _bg_toggle.button_pressed != _bg_visible: _bg_toggle.set_pressed_no_signal(_bg_visible)
	if _bg_texture_rect != null: _bg_texture_rect.visible = _bg_visible and not _compare_old_vs_new_mode

func set_fog_visible(vis: bool) -> void:
	_fog_visible = vis
	if _fog_toggle != null and _fog_toggle.button_pressed != _fog_visible: _fog_toggle.set_pressed_no_signal(_fog_visible)
	_apply_parameters()

func set_compare_mode(enabled: bool) -> void:
	_compare_mode = enabled
	if _compare_toggle != null and _compare_toggle.button_pressed != _compare_mode: _compare_toggle.set_pressed_no_signal(_compare_mode)
	if _compare_container != null: _compare_container.visible = _compare_mode
	if _fog_texture_rect != null: _fog_texture_rect.visible = _fog_visible and not _compare_mode and not _compare_old_vs_new_mode and _fog_source_mode == FogSourceMode.OLD_ATLAS_8F
	_update_frame_display()

func set_compare_old_vs_new_mode(enabled: bool) -> void:
	_compare_old_vs_new_mode = enabled
	if _compare_old_new_toggle != null and _compare_old_new_toggle.button_pressed != _compare_old_vs_new_mode: _compare_old_new_toggle.set_pressed_no_signal(_compare_old_vs_new_mode)
	if _compare_old_new_container != null: _compare_old_new_container.visible = _compare_old_vs_new_mode
	_apply_parameters()

func set_lab_mode(mode: LabMode) -> void:
	_current_lab_mode = mode

func reset_defaults() -> void:
	_is_playing = true
	_fog_current_frame = 0
	_fog_frame_timer = 0.0
	_procedural_time = 0.0
	_fps = DEFAULT_FPS
	_old_opacity = DEFAULT_OLD_OPACITY
	_mod_r = DEFAULT_MODULATE_R
	_mod_g = DEFAULT_MODULATE_G
	_mod_b = DEFAULT_MODULATE_B

	_proc_opacity = DEFAULT_PROC_OPACITY
	_proc_mod_r = 1.0
	_proc_mod_g = 1.0
	_proc_mod_b = 1.0
	_drift_amount = DEFAULT_DRIFT_AMOUNT
	_drift_speed = DEFAULT_DRIFT_SPEED
	_distortion = DEFAULT_DISTORTION
	_breathing = DEFAULT_BREATHING
	_layer_count = DEFAULT_LAYER_COUNT

	_bg_visible = true
	_fog_visible = true
	_compare_mode = false
	_compare_old_vs_new_mode = false
	_fog_source_mode = FogSourceMode.NEW_PROCEDURAL_LAYER
	_current_motion_mode = MotionMode.CURRENT_ATLAS_ANIMATION

	if _play_pause_btn != null: _play_pause_btn.text = "Pause"
	if _fps_slider != null: _fps_slider.value = DEFAULT_FPS
	if _fps_spinbox != null: _fps_spinbox.value = DEFAULT_FPS
	if _opacity_slider != null: _opacity_slider.value = DEFAULT_OLD_OPACITY
	if _opacity_spinbox != null: _opacity_spinbox.value = DEFAULT_OLD_OPACITY
	if _r_slider != null: _r_slider.value = DEFAULT_MODULATE_R
	if _g_slider != null: _g_slider.value = DEFAULT_MODULATE_G
	if _b_slider != null: _b_slider.value = DEFAULT_MODULATE_B

	if _proc_opacity_slider != null: _proc_opacity_slider.value = DEFAULT_PROC_OPACITY
	if _proc_opacity_spinbox != null: _proc_opacity_spinbox.value = DEFAULT_PROC_OPACITY
	if _drift_amount_slider != null: _drift_amount_slider.value = DEFAULT_DRIFT_AMOUNT
	if _drift_amount_spinbox != null: _drift_amount_spinbox.value = DEFAULT_DRIFT_AMOUNT
	if _drift_speed_slider != null: _drift_speed_slider.value = DEFAULT_DRIFT_SPEED
	if _drift_speed_spinbox != null: _drift_speed_spinbox.value = DEFAULT_DRIFT_SPEED
	if _distortion_slider != null: _distortion_slider.value = DEFAULT_DISTORTION
	if _distortion_spinbox != null: _distortion_spinbox.value = DEFAULT_DISTORTION
	if _breathing_slider != null: _breathing_slider.value = DEFAULT_BREATHING
	if _breathing_spinbox != null: _breathing_spinbox.value = DEFAULT_BREATHING
	if _layer_count_option != null: _layer_count_option.select(1)

	if _bg_toggle != null: _bg_toggle.button_pressed = true
	if _fog_toggle != null: _fog_toggle.button_pressed = true
	if _compare_toggle != null: _compare_toggle.button_pressed = false
	if _compare_old_new_toggle != null: _compare_old_new_toggle.button_pressed = false
	if _fog_source_option != null: _fog_source_option.select(0)
	if _motion_option != null: _motion_option.select(0)

	_apply_parameters()

# Accessors for testing & verification
func get_fog_source_mode() -> FogSourceMode:
	return _fog_source_mode

func get_current_frame_index() -> int:
	return _fog_current_frame

func is_playing() -> bool:
	return _is_playing

func get_fps() -> float:
	return _fps

func get_opacity() -> float:
	return _old_opacity

func get_procedural_opacity() -> float:
	return _proc_opacity

func get_drift_amount() -> float:
	return _drift_amount

func get_drift_speed() -> float:
	return _drift_speed

func get_distortion() -> float:
	return _distortion

func get_breathing() -> float:
	return _breathing

func get_layer_count() -> int:
	return _layer_count

func is_compare_mode() -> bool:
	return _compare_mode

func is_compare_old_vs_new_mode() -> bool:
	return _compare_old_vs_new_mode

func get_motion_mode() -> MotionMode:
	return _current_motion_mode

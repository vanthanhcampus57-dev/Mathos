class_name VisualLab
extends Control

## Developer & QA Visual Asset Lab for Mathos Engine.
## Provides isolated diagnosis of visual presentation, fog overlays, frame inspection,
## procedural fog animation, side-by-side old vs new comparison,
## and Auth/Login Academy background real asset tuning (V4 Wiring), without mutating save/gameplay data.

enum LabMode { FOG_TEST, AUTH_LOGIN_BG, FUTURE_TAB_3 }
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
const DEFAULT_PROC_OPACITY: float = 0.48
const DEFAULT_DRIFT_AMOUNT: float = 120.0
const DEFAULT_DRIFT_SPEED: float = 0.15
const DEFAULT_DISTORTION: float = 0.08
const DEFAULT_BREATHING: float = 0.05
const DEFAULT_LAYER_COUNT: int = 3

# D1 Scene Nodes
var _bg_texture_rect: TextureRect = null
var _fog_texture_rect: TextureRect = null

# D1 Procedural Fog Layer Nodes (3 layers max)
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

# Auth Login Background Node
var _auth_bg_node: AuthLoginBackground = null

var _top_bar: PanelContainer = null
var _ctrl_panel: PanelContainer = null
var _diag_panel: PanelContainer = null
var _diag_label: Label = null
var _hide_controls_btn: Button = null

# Controls
var _fog_source_option: OptionButton = null
var _fog_source_box: VBoxContainer = null
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

# D1 Procedural Controls Box
var _proc_ctrl_box: VBoxContainer = null
var _old_ctrl_box: VBoxContainer = null
var _global_toggles_box: VBoxContainer = null
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

# Auth Login Background Controls Box (Sectioned V4 UI)
var _auth_ctrl_box: VBoxContainer = null

# State
var _current_lab_mode: LabMode = LabMode.FOG_TEST
var _fog_source_mode: FogSourceMode = FogSourceMode.NEW_PROCEDURAL_LAYER
var _current_motion_mode: MotionMode = MotionMode.CURRENT_ATLAS_ANIMATION
var _is_playing: bool = true
var _controls_visible: bool = true

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

# Diagnostics State Cash
var _last_diag_left_overscan: float = 0.0
var _last_diag_right_overscan: float = 0.0
var _last_diag_curr_offset: float = 0.0
var _last_diag_edge_safe: bool = true

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
	set_lab_mode(LabMode.FOG_TEST)
	_update_diagnostic_display()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			set_controls_visible(not _controls_visible)

func _load_all_textures() -> void:
	_bg_texture = _load_texture([D1_BG_PATH, D1_BG_ALT_PATH])

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

func get_auth_background() -> AuthLoginBackground:
	if _auth_bg_node == null:
		_auth_bg_node = AuthLoginBackground.new()
		_auth_bg_node.name = "AuthLoginBackground"
		_auth_bg_node.visible = false
		_auth_bg_node._ensure_nodes()
		add_child(_auth_bg_node)
	return _auth_bg_node

func calculate_overscan_info(vp_size: Vector2) -> Dictionary:
	var src_w: float = 2115.0
	var src_h: float = 744.0
	if _procedural_texture != null:
		src_w = float(_procedural_texture.get_width())
		src_h = float(_procedural_texture.get_height())

	var aspect: float = src_w / src_h
	var base_disp_height: float = vp_size.y
	var base_disp_width: float = base_disp_height * aspect

	var max_drift_mult: float = 1.2 if _layer_count >= 3 else (0.8 if _layer_count == 2 else 1.0)
	var max_drift_px: float = _drift_amount * max_drift_mult
	var max_distortion_px: float = _distortion * 25.0
	var max_offset_px: float = max_drift_px + max_distortion_px
	var safety_margin: float = 64.0

	var required_overscan_per_side: float = max_offset_px + safety_margin
	var required_total_width: float = vp_size.x + 2.0 * required_overscan_per_side

	var scale_factor: float = 1.0
	if base_disp_width < required_total_width:
		scale_factor = required_total_width / base_disp_width

	var final_disp_width: float = base_disp_width * scale_factor
	var final_disp_height: float = base_disp_height * scale_factor

	return {
		"aspect": aspect,
		"disp_width": final_disp_width,
		"disp_height": final_disp_height,
		"base_center_x": (vp_size.x - final_disp_width) / 2.0,
		"base_center_y": (vp_size.y - final_disp_height) / 2.0,
		"required_overscan": required_overscan_per_side,
		"required_width": required_total_width,
		"max_offset": max_offset_px
	}

func _process(delta: float) -> void:
	if _current_lab_mode == LabMode.FOG_TEST:
		if _is_playing:
			if not _fog_frames.is_empty() and _fps > 0.0 and _current_motion_mode == MotionMode.CURRENT_ATLAS_ANIMATION:
				_fog_frame_timer += delta
				var frame_dur: float = 1.0 / _fps
				if _fog_frame_timer >= frame_dur:
					_fog_frame_timer = fmod(_fog_frame_timer, frame_dur)
					_fog_current_frame = (_fog_current_frame + 1) % _fog_frames.size()
					_update_frame_display()

			_procedural_time += delta
			_update_procedural_motion()

	_update_diagnostic_display()

func _update_procedural_motion() -> void:
	_load_all_textures()
	if _procedural_texture == null or not is_inside_tree():
		return

	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		vp_size = Vector2(1280, 720)

	var overscan_info: Dictionary = calculate_overscan_info(vp_size)
	var disp_w: float = overscan_info["disp_width"]
	var disp_h: float = overscan_info["disp_height"]
	var center_x: float = overscan_info["base_center_x"]
	var center_y: float = overscan_info["base_center_y"]

	var time: float = _procedural_time * _drift_speed

	var layers: Array[TextureRect] = [_proc_layer_1, _proc_layer_2, _proc_layer_3]
	var layer_configs: Array[Dictionary] = [
		{
			"freq_x": 0.7, "drift_mult": 1.0,
			"freq_y": 0.4, "dist_mult": 20.0,
			"freq_s": 0.3, "scale_amp": 0.05, "base_scale": 1.0,
			"freq_a": 0.8, "alpha_mult": 1.0, "active": true
		},
		{
			"freq_x": 0.5, "phase_x": 1.5, "drift_mult": 0.8,
			"freq_y": 0.3, "phase_y": 2.0, "dist_mult": 15.0,
			"freq_s": 0.2, "scale_amp": 0.04, "base_scale": 1.05,
			"freq_a": 0.6, "alpha_mult": 0.65, "active": (_layer_count >= 2)
		},
		{
			"freq_x": 0.3, "phase_x": 3.0, "drift_mult": 1.2,
			"freq_y": 0.5, "phase_y": 1.0, "dist_mult": 25.0,
			"freq_s": 0.1, "scale_amp": 0.03, "base_scale": 1.10,
			"freq_a": 0.4, "alpha_mult": 0.45, "active": (_layer_count >= 3)
		}
	]

	var min_left_overscan: float = 99999.0
	var min_right_overscan: float = 99999.0
	var is_edge_safe: bool = true
	var curr_max_offset: float = 0.0

	for idx in range(3):
		var layer_node: TextureRect = layers[idx]
		var cfg: Dictionary = layer_configs[idx]

		if layer_node == null:
			continue

		var is_active: bool = cfg["active"]
		layer_node.visible = is_active
		if not is_active:
			continue

		var px_x: float = cfg.get("phase_x", 0.0)
		var px_y: float = cfg.get("phase_y", 0.0)

		var off_x: float = sin(time * cfg["freq_x"] + px_x) * (_drift_amount * cfg["drift_mult"])
		var off_y: float = cos(time * cfg["freq_y"] + px_y) * (_distortion * cfg["dist_mult"])

		var scale_delta: float = sin(time * cfg["freq_s"]) * (_distortion * cfg["scale_amp"])
		var layer_scale: float = maxf(0.8, cfg["base_scale"] + scale_delta)

		var alpha: float = clampf((_proc_opacity * cfg["alpha_mult"]) * (1.0 + sin(time * cfg["freq_a"]) * _breathing), 0.0, 1.0)

		layer_node.size = Vector2(disp_w, disp_h)
		layer_node.pivot_offset = Vector2(disp_w / 2.0, disp_h / 2.0)
		layer_node.position = Vector2(center_x + off_x, center_y + off_y)
		layer_node.scale = Vector2(layer_scale, layer_scale)
		layer_node.modulate = Color(_proc_mod_r, _proc_mod_g, _proc_mod_b, alpha)

		var phys_left: float = layer_node.position.x - (disp_w * (layer_scale - 1.0) / 2.0)
		var phys_right: float = layer_node.position.x + disp_w + (disp_w * (layer_scale - 1.0) / 2.0)

		var overscan_l: float = -phys_left
		var overscan_r: float = phys_right - vp_size.x

		if overscan_l < min_left_overscan:
			min_left_overscan = overscan_l
		if overscan_r < min_right_overscan:
			min_right_overscan = overscan_r

		if phys_left > 0.0 or phys_right < vp_size.x:
			is_edge_safe = false

		var layer_off_mag: float = absf(off_x)
		if layer_off_mag > curr_max_offset:
			curr_max_offset = layer_off_mag

	_last_diag_left_overscan = min_left_overscan
	_last_diag_right_overscan = min_right_overscan
	_last_diag_curr_offset = curr_max_offset
	_last_diag_edge_safe = is_edge_safe

func _build_ui_hierarchy() -> void:
	_bg_texture_rect = TextureRect.new()
	_bg_texture_rect.name = "BackgroundTextureRect"
	_bg_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_texture_rect.texture = _bg_texture
	add_child(_bg_texture_rect)

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

	_proc_container = Control.new()
	_proc_container.name = "ProceduralFogContainer"
	_proc_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_proc_container.clip_contents = true
	_proc_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_proc_layer_3 = TextureRect.new(); _proc_layer_3.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _proc_layer_3.stretch_mode = TextureRect.STRETCH_SCALE; _proc_layer_3.texture = _procedural_texture; _proc_layer_3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_proc_layer_2 = TextureRect.new(); _proc_layer_2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _proc_layer_2.stretch_mode = TextureRect.STRETCH_SCALE; _proc_layer_2.texture = _procedural_texture; _proc_layer_2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_proc_layer_1 = TextureRect.new(); _proc_layer_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _proc_layer_1.stretch_mode = TextureRect.STRETCH_SCALE; _proc_layer_1.texture = _procedural_texture; _proc_layer_1.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_proc_container.add_child(_proc_layer_3)
	_proc_container.add_child(_proc_layer_2)
	_proc_container.add_child(_proc_layer_1)
	add_child(_proc_container)

	_auth_bg_node = AuthLoginBackground.new()
	_auth_bg_node.name = "AuthLoginBackground"
	_auth_bg_node.visible = false
	_auth_bg_node._ensure_nodes()
	add_child(_auth_bg_node)

	_top_bar = PanelContainer.new()
	_top_bar.name = "TopBar"
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = 40.0
	var top_box: HBoxContainer = HBoxContainer.new()

	var title_lbl: Label = Label.new(); title_lbl.text = " 🔬 MATHOS VISUAL LAB "
	top_box.add_child(title_lbl)

	var tab_d1: Button = Button.new(); tab_d1.text = " D1 FOG LAB "; tab_d1.pressed.connect(func(): set_lab_mode(LabMode.FOG_TEST))
	top_box.add_child(tab_d1)

	var tab_auth: Button = Button.new(); tab_auth.text = " AUTH LOGIN BACKGROUND "; tab_auth.pressed.connect(func(): set_lab_mode(LabMode.AUTH_LOGIN_BG))
	top_box.add_child(tab_auth)

	_hide_controls_btn = Button.new(); _hide_controls_btn.text = " HIDE CONTROLS (Tab) "; _hide_controls_btn.pressed.connect(func(): set_controls_visible(not _controls_visible))
	top_box.add_child(_hide_controls_btn)

	_top_bar.add_child(top_box)
	add_child(_top_bar)

	_ctrl_panel = PanelContainer.new()
	_ctrl_panel.name = "ControlDock"
	_ctrl_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_ctrl_panel.offset_top = 48.0
	_ctrl_panel.offset_right = 360.0
	_ctrl_panel.offset_bottom = -16.0

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_fog_source_box = VBoxContainer.new()
	var src_lbl: Label = Label.new(); src_lbl.text = "FOG SOURCE:"
	_fog_source_option = OptionButton.new()
	_fog_source_option.add_item("New Procedural Layer", FogSourceMode.NEW_PROCEDURAL_LAYER)
	_fog_source_option.add_item("Old Atlas 8F", FogSourceMode.OLD_ATLAS_8F)
	_fog_source_option.select(0)
	_fog_source_option.item_selected.connect(_on_fog_source_selected)
	_fog_source_box.add_child(src_lbl)
	_fog_source_box.add_child(_fog_source_option)
	vbox.add_child(_fog_source_box)

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

	vbox.add_child(_old_ctrl_box)

	# --- D1 PROCEDURAL CONTROLS BOX ---
	_proc_ctrl_box = VBoxContainer.new()
	_proc_ctrl_box.name = "ProceduralControls"

	var hdr_proc: Label = Label.new(); hdr_proc.text = "=== D1 FOG CONTROLS ==="
	_proc_ctrl_box.add_child(hdr_proc)

	var op_proc_lbl: Label = Label.new(); op_proc_lbl.text = "Opacity (0.00 -> 1.00):"
	var op_proc_box: HBoxContainer = HBoxContainer.new()
	_proc_opacity_slider = HSlider.new(); _proc_opacity_slider.min_value = 0.0; _proc_opacity_slider.max_value = 1.0; _proc_opacity_slider.step = 0.01; _proc_opacity_slider.value = DEFAULT_PROC_OPACITY; _proc_opacity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_proc_opacity_spinbox = SpinBox.new(); _proc_opacity_spinbox.min_value = 0.0; _proc_opacity_spinbox.max_value = 1.0; _proc_opacity_spinbox.step = 0.01; _proc_opacity_spinbox.value = DEFAULT_PROC_OPACITY
	_proc_opacity_slider.value_changed.connect(func(v): set_procedural_opacity(v)); _proc_opacity_spinbox.value_changed.connect(func(v): set_procedural_opacity(v))
	op_proc_box.add_child(_proc_opacity_slider); op_proc_box.add_child(_proc_opacity_spinbox)
	_proc_ctrl_box.add_child(op_proc_lbl); _proc_ctrl_box.add_child(op_proc_box)

	var drift_lbl: Label = Label.new(); drift_lbl.text = "Drift Amount (0 -> 300 px):"
	var drift_box: HBoxContainer = HBoxContainer.new()
	_drift_amount_slider = HSlider.new(); _drift_amount_slider.min_value = 0.0; _drift_amount_slider.max_value = 300.0; _drift_amount_slider.step = 5.0; _drift_amount_slider.value = DEFAULT_DRIFT_AMOUNT; _drift_amount_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drift_amount_spinbox = SpinBox.new(); _drift_amount_spinbox.min_value = 0.0; _drift_amount_spinbox.max_value = 300.0; _drift_amount_spinbox.step = 5.0; _drift_amount_spinbox.value = DEFAULT_DRIFT_AMOUNT
	_drift_amount_slider.value_changed.connect(func(v): set_drift_amount(v)); _drift_amount_spinbox.value_changed.connect(func(v): set_drift_amount(v))
	drift_box.add_child(_drift_amount_slider); drift_box.add_child(_drift_amount_spinbox)
	_proc_ctrl_box.add_child(drift_lbl); _proc_ctrl_box.add_child(drift_box)

	var speed_lbl: Label = Label.new(); speed_lbl.text = "Drift Speed (0.00 -> 1.00):"
	var speed_box: HBoxContainer = HBoxContainer.new()
	_drift_speed_slider = HSlider.new(); _drift_speed_slider.min_value = 0.0; _drift_speed_slider.max_value = 1.0; _drift_speed_slider.step = 0.01; _drift_speed_slider.value = DEFAULT_DRIFT_SPEED; _drift_speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drift_speed_spinbox = SpinBox.new(); _drift_speed_spinbox.min_value = 0.0; _drift_speed_spinbox.max_value = 1.0; _drift_speed_spinbox.step = 0.01; _drift_speed_spinbox.value = DEFAULT_DRIFT_SPEED
	_drift_speed_slider.value_changed.connect(func(v): set_drift_speed(v)); _drift_speed_spinbox.value_changed.connect(func(v): set_drift_speed(v))
	speed_box.add_child(_drift_speed_slider); speed_box.add_child(_drift_speed_spinbox)
	_proc_ctrl_box.add_child(speed_lbl); _proc_ctrl_box.add_child(speed_box)

	var dist_lbl: Label = Label.new(); dist_lbl.text = "Distortion (0.00 -> 0.50):"
	var dist_box: HBoxContainer = HBoxContainer.new()
	_distortion_slider = HSlider.new(); _distortion_slider.min_value = 0.0; _distortion_slider.max_value = 0.50; _distortion_slider.step = 0.01; _distortion_slider.value = DEFAULT_DISTORTION; _distortion_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_distortion_spinbox = SpinBox.new(); _distortion_spinbox.min_value = 0.0; _distortion_spinbox.max_value = 0.50; _distortion_spinbox.step = 0.01; _distortion_spinbox.value = DEFAULT_DISTORTION
	_distortion_slider.value_changed.connect(func(v): set_distortion(v)); _distortion_spinbox.value_changed.connect(func(v): set_distortion(v))
	dist_box.add_child(_distortion_slider); dist_box.add_child(_distortion_spinbox)
	_proc_ctrl_box.add_child(dist_lbl); _proc_ctrl_box.add_child(dist_box)

	var breath_lbl: Label = Label.new(); breath_lbl.text = "Breathing (0.00 -> 0.30):"
	var breath_box: HBoxContainer = HBoxContainer.new()
	_breathing_slider = HSlider.new(); _breathing_slider.min_value = 0.0; _breathing_slider.max_value = 0.30; _breathing_slider.step = 0.01; _breathing_slider.value = DEFAULT_BREATHING; _breathing_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_breathing_spinbox = SpinBox.new(); _breathing_spinbox.min_value = 0.0; _breathing_spinbox.max_value = 0.30; _breathing_spinbox.step = 0.01; _breathing_spinbox.value = DEFAULT_BREATHING
	_breathing_slider.value_changed.connect(func(v): set_breathing(v)); _breathing_spinbox.value_changed.connect(func(v): set_breathing(v))
	breath_box.add_child(_breathing_slider); breath_box.add_child(_breathing_spinbox)
	_proc_ctrl_box.add_child(breath_lbl); _proc_ctrl_box.add_child(breath_box)

	var layer_lbl: Label = Label.new(); layer_lbl.text = "Layer Count:"
	_layer_count_option = OptionButton.new()
	_layer_count_option.add_item("1 Layer", 1)
	_layer_count_option.add_item("2 Layers", 2)
	_layer_count_option.add_item("3 Layers", 3)
	_layer_count_option.select(1)
	_layer_count_option.item_selected.connect(func(idx): set_layer_count(idx + 1))
	_proc_ctrl_box.add_child(layer_lbl); _proc_ctrl_box.add_child(_layer_count_option)

	vbox.add_child(_proc_ctrl_box)

	_global_toggles_box = VBoxContainer.new()
	var hdr_glob: Label = Label.new(); hdr_glob.text = "=== GLOBAL TOGGLES ==="
	_global_toggles_box.add_child(hdr_glob)

	_bg_toggle = CheckBox.new(); _bg_toggle.text = "Background"; _bg_toggle.button_pressed = true; _bg_toggle.toggled.connect(func(t): set_background_visible(t))
	_global_toggles_box.add_child(_bg_toggle)

	_fog_toggle = CheckBox.new(); _fog_toggle.text = "Fog Layer"; _fog_toggle.button_pressed = true; _fog_toggle.toggled.connect(func(t): set_fog_visible(t))
	_global_toggles_box.add_child(_fog_toggle)

	_compare_old_new_toggle = CheckBox.new(); _compare_old_new_toggle.text = "Compare Old vs New"; _compare_old_new_toggle.button_pressed = false; _compare_old_new_toggle.toggled.connect(func(t): set_compare_old_vs_new_mode(t))
	_global_toggles_box.add_child(_compare_old_new_toggle)

	_reset_btn = Button.new(); _reset_btn.text = "[ Reset Defaults ]"; _reset_btn.pressed.connect(reset_defaults)
	_global_toggles_box.add_child(_reset_btn)

	vbox.add_child(_global_toggles_box)

	# --- AUTH LOGIN BACKGROUND CONTROLS BOX (V4 Real Asset Wiring UI) ---
	_auth_ctrl_box = VBoxContainer.new()
	_auth_ctrl_box.name = "AuthLoginControls"
	_auth_ctrl_box.visible = false

	# SECTION 1: FOG CLUSTERS & TINT / BRIGHTNESS / SATURATION
	var hdr_auth_fog: Label = Label.new(); hdr_auth_fog.text = "=== FOG CLUSTERS & SHADER ==="
	_auth_ctrl_box.add_child(hdr_auth_fog)

	var afog_op_lbl: Label = Label.new(); afog_op_lbl.text = "Fog Master Opacity (0..1):"
	var afog_op_slider: HSlider = HSlider.new(); afog_op_slider.min_value = 0.0; afog_op_slider.max_value = 1.0; afog_op_slider.step = 0.02; afog_op_slider.value = AuthLoginBackground.DEFAULT_FOG_MASTER_OPACITY
	afog_op_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.fog_master_opacity = v)
	_auth_ctrl_box.add_child(afog_op_lbl); _auth_ctrl_box.add_child(afog_op_slider)

	var afog_bright_lbl: Label = Label.new(); afog_bright_lbl.text = "Fog Brightness (0.4..1.2):"
	var afog_bright_slider: HSlider = HSlider.new(); afog_bright_slider.min_value = 0.4; afog_bright_slider.max_value = 1.2; afog_bright_slider.step = 0.05; afog_bright_slider.value = AuthLoginBackground.DEFAULT_FOG_BRIGHTNESS
	afog_bright_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.fog_brightness = v)
	_auth_ctrl_box.add_child(afog_bright_lbl); _auth_ctrl_box.add_child(afog_bright_slider)

	var afog_sat_lbl: Label = Label.new(); afog_sat_lbl.text = "Fog Saturation (0.3..1.2):"
	var afog_sat_slider: HSlider = HSlider.new(); afog_sat_slider.min_value = 0.3; afog_sat_slider.max_value = 1.2; afog_sat_slider.step = 0.05; afog_sat_slider.value = AuthLoginBackground.DEFAULT_FOG_SATURATION
	afog_sat_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.fog_saturation = v)
	_auth_ctrl_box.add_child(afog_sat_lbl); _auth_ctrl_box.add_child(afog_sat_slider)

	var afog_cnt_lbl: Label = Label.new(); afog_cnt_lbl.text = "Visible Cluster Count (1..20):"
	var afog_cnt_spin: SpinBox = SpinBox.new(); afog_cnt_spin.min_value = 1; afog_cnt_spin.max_value = 20; afog_cnt_spin.value = AuthLoginBackground.DEFAULT_FOG_CLUSTER_COUNT
	afog_cnt_spin.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.set_fog_cluster_count(int(v)))
	_auth_ctrl_box.add_child(afog_cnt_lbl); _auth_ctrl_box.add_child(afog_cnt_spin)

	var reset_fog_btn: Button = Button.new(); reset_fog_btn.text = "RESET FOG DEFAULTS"
	reset_fog_btn.pressed.connect(func(): if _auth_bg_node: _auth_bg_node.fog_master_opacity = AuthLoginBackground.DEFAULT_FOG_MASTER_OPACITY; _auth_bg_node.fog_brightness = AuthLoginBackground.DEFAULT_FOG_BRIGHTNESS; _auth_bg_node.fog_saturation = AuthLoginBackground.DEFAULT_FOG_SATURATION; _auth_bg_node.set_fog_cluster_count(AuthLoginBackground.DEFAULT_FOG_CLUSTER_COUNT))
	_auth_ctrl_box.add_child(reset_fog_btn)

	# SECTION 2: BANNER A & BANNER B
	var hdr_banner: Label = Label.new(); hdr_banner.text = "=== REAL BANNERS & 4-CORNER WARP ==="
	_auth_ctrl_box.add_child(hdr_banner)

	var ban_a_bright_lbl: Label = Label.new(); ban_a_bright_lbl.text = "Banner A Brightness (0.4..1.6):"
	var ban_a_bright_slider: HSlider = HSlider.new(); ban_a_bright_slider.min_value = 0.4; ban_a_bright_slider.max_value = 1.6; ban_a_bright_slider.step = 0.05; ban_a_bright_slider.value = AuthLoginBackground.DEFAULT_BANNER_A_BRIGHTNESS
	ban_a_bright_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.banner_a_brightness = v)
	_auth_ctrl_box.add_child(ban_a_bright_lbl); _auth_ctrl_box.add_child(ban_a_bright_slider)

	var ban_b_bright_lbl: Label = Label.new(); ban_b_bright_lbl.text = "Banner B Brightness (0.4..1.6):"
	var ban_b_bright_slider: HSlider = HSlider.new(); ban_b_bright_slider.min_value = 0.4; ban_b_bright_slider.max_value = 1.6; ban_b_bright_slider.step = 0.05; ban_b_bright_slider.value = AuthLoginBackground.DEFAULT_BANNER_B_BRIGHTNESS
	ban_b_bright_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.banner_b_brightness = v)
	_auth_ctrl_box.add_child(ban_b_bright_lbl); _auth_ctrl_box.add_child(ban_b_bright_slider)

	var reset_ban_a_btn: Button = Button.new(); reset_ban_a_btn.text = "RESET BANNER A WARP"
	reset_ban_a_btn.pressed.connect(func(): if _auth_bg_node: _auth_bg_node.reset_banner_a_warp())
	_auth_ctrl_box.add_child(reset_ban_a_btn)

	var reset_ban_b_btn: Button = Button.new(); reset_ban_b_btn.text = "RESET BANNER B WARP"
	reset_ban_b_btn.pressed.connect(func(): if _auth_bg_node: _auth_bg_node.reset_banner_b_warp())
	_auth_ctrl_box.add_child(reset_ban_b_btn)

	# SECTION 3: REAL PIXEL ART PARTICLES
	var hdr_part: Label = Label.new(); hdr_part.text = "=== REAL PIXEL ART PARTICLES ==="
	_auth_ctrl_box.add_child(hdr_part)

	var part_type_lbl: Label = Label.new(); part_type_lbl.text = "Particle Type:"
	var part_type_opt: OptionButton = OptionButton.new()
	part_type_opt.add_item("MIXED", 0); part_type_opt.add_item("STAR", 1); part_type_opt.add_item("ORB", 2); part_type_opt.add_item("SPARKLE", 3)
	part_type_opt.select(0)
	part_type_opt.item_selected.connect(func(idx): if _auth_bg_node: _auth_bg_node.set_particle_type(part_type_opt.get_item_text(idx)))
	_auth_ctrl_box.add_child(part_type_lbl); _auth_ctrl_box.add_child(part_type_opt)

	var dust_chk: CheckBox = CheckBox.new(); dust_chk.text = "Particles Enabled"; dust_chk.button_pressed = true
	dust_chk.toggled.connect(func(t): if _auth_bg_node: _auth_bg_node.dust_enabled = t)
	_auth_ctrl_box.add_child(dust_chk)

	var dust_cnt_lbl: Label = Label.new(); dust_cnt_lbl.text = "Particle Count (1..50):"
	var dust_cnt_spin: SpinBox = SpinBox.new(); dust_cnt_spin.min_value = 1; dust_cnt_spin.max_value = 50; dust_cnt_spin.value = AuthLoginBackground.DEFAULT_DUST_COUNT
	dust_cnt_spin.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.set_particle_count(int(v)))
	_auth_ctrl_box.add_child(dust_cnt_lbl); _auth_ctrl_box.add_child(dust_cnt_spin)

	# SECTION 4: GLOBAL PLAYBACK
	var auth_act_hdr: Label = Label.new(); auth_act_hdr.text = "=== GLOBAL PLAYBACK ==="
	_auth_ctrl_box.add_child(auth_act_hdr)

	var auth_play_btn: Button = Button.new(); auth_play_btn.text = "Pause"
	auth_play_btn.pressed.connect(func(): if _auth_bg_node: _auth_bg_node.set_playing(not _auth_bg_node.is_playing()); auth_play_btn.text = "Pause" if _auth_bg_node.is_playing() else "Play")
	_auth_ctrl_box.add_child(auth_play_btn)

	var reset_auth_btn: Button = Button.new(); reset_auth_btn.text = "[ RESET ALL AUTH BG DEFAULTS ]"
	reset_auth_btn.pressed.connect(func(): if _auth_bg_node: _auth_bg_node.reset_defaults(); auth_play_btn.text = "Pause")
	_auth_ctrl_box.add_child(reset_auth_btn)

	vbox.add_child(_auth_ctrl_box)

	scroll.add_child(vbox)
	_ctrl_panel.add_child(scroll)
	add_child(_ctrl_panel)

	_diag_panel = PanelContainer.new()
	_diag_panel.name = "DiagPanel"
	_diag_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_diag_panel.offset_left = -380.0
	_diag_panel.offset_top = 48.0
	_diag_panel.offset_right = -16.0

	_diag_label = Label.new(); _diag_label.text = "VISUAL LAB DIAGNOSTICS"
	_diag_panel.add_child(_diag_label)
	add_child(_diag_panel)

func set_controls_visible(vis: bool) -> void:
	_controls_visible = vis
	if _top_bar != null: _top_bar.visible = _controls_visible
	if _ctrl_panel != null: _ctrl_panel.visible = _controls_visible
	if _diag_panel != null: _diag_panel.visible = _controls_visible
	if _hide_controls_btn != null:
		_hide_controls_btn.text = " HIDE CONTROLS (Tab) " if _controls_visible else " SHOW CONTROLS (Tab) "

func is_controls_visible() -> bool:
	return _controls_visible

func _on_fog_source_selected(idx: int) -> void:
	set_fog_source_mode(idx as FogSourceMode)

func set_fog_source_mode(mode: FogSourceMode) -> void:
	_fog_source_mode = mode
	if _fog_source_option != null and _fog_source_option.selected != int(_fog_source_mode):
		_fog_source_option.select(int(_fog_source_mode))

	if _proc_ctrl_box != null:
		_proc_ctrl_box.visible = (_fog_source_mode == FogSourceMode.NEW_PROCEDURAL_LAYER) and (_current_lab_mode == LabMode.FOG_TEST)
	if _old_ctrl_box != null:
		_old_ctrl_box.visible = (_fog_source_mode == FogSourceMode.OLD_ATLAS_8F) and (_current_lab_mode == LabMode.FOG_TEST)

	_apply_parameters()

func _apply_parameters() -> void:
	if _current_lab_mode == LabMode.AUTH_LOGIN_BG:
		if _bg_texture_rect != null: _bg_texture_rect.visible = false
		if _fog_texture_rect != null: _fog_texture_rect.visible = false
		if _proc_container != null: _proc_container.visible = false
		if _auth_bg_node != null: _auth_bg_node.visible = true
		return

	if _auth_bg_node != null:
		_auth_bg_node.visible = false

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

func set_lab_mode(mode: LabMode) -> void:
	_current_lab_mode = mode
	if _auth_ctrl_box != null:
		_auth_ctrl_box.visible = (_current_lab_mode == LabMode.AUTH_LOGIN_BG)
	if _fog_source_box != null:
		_fog_source_box.visible = (_current_lab_mode == LabMode.FOG_TEST)
	if _play_pause_btn != null:
		_play_pause_btn.visible = (_current_lab_mode == LabMode.FOG_TEST)
	if _global_toggles_box != null:
		_global_toggles_box.visible = (_current_lab_mode == LabMode.FOG_TEST)

	if _proc_ctrl_box != null:
		_proc_ctrl_box.visible = (_current_lab_mode == LabMode.FOG_TEST and _fog_source_mode == FogSourceMode.NEW_PROCEDURAL_LAYER)
	if _old_ctrl_box != null:
		_old_ctrl_box.visible = (_current_lab_mode == LabMode.FOG_TEST and _fog_source_mode == FogSourceMode.OLD_ATLAS_8F)

	_apply_parameters()

func get_lab_mode() -> LabMode:
	return _current_lab_mode

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

	if _current_lab_mode == LabMode.AUTH_LOGIN_BG:
		var bg_w: int = 1672
		var bg_h: int = 941
		if _auth_bg_node != null and _auth_bg_node.get_bg_texture() != null:
			bg_w = _auth_bg_node.get_bg_texture().get_width()
			bg_h = _auth_bg_node.get_bg_texture().get_height()

		var fog_cnt: int = _auth_bg_node.fog_asset_count if _auth_bg_node else 0
		var ban_cnt: int = _auth_bg_node.banner_asset_count if _auth_bg_node else 0
		var part_cnt: int = _auth_bg_node.particle_asset_count if _auth_bg_node else 0

		_diag_label.text = "\n".join([
			"MODE: AUTH LOGIN BACKGROUND LAB (REAL ASSET WIRING V4)",
			"VIEWPORT: %.0fx%.0f" % [vp_size.x, vp_size.y],
			"BACKGROUND: %dx%d (Aspect: %.3f)" % [bg_w, bg_h, float(bg_w) / float(bg_h)],
			"REAL FOG TEXTURES LOADED: %d / 15 (13 Clusters + 2 Ribbons)" % fog_cnt,
			"  Active Visible Instances: %d | Speed: %.2f | Opacity: %.2f" % [
				_auth_bg_node.get_fog_cluster_count() if _auth_bg_node else 0,
				_auth_bg_node.fog_global_speed if _auth_bg_node else 0.5,
				_auth_bg_node.fog_master_opacity if _auth_bg_node else 0.85
			],
			"  Fog Shader: Brightness=%.2f, Saturation=%.2f" % [
				_auth_bg_node.fog_brightness if _auth_bg_node else 0.75,
				_auth_bg_node.fog_saturation if _auth_bg_node else 0.75
			],
			"REAL BANNERS LOADED: %d / 2 (Nearest Pixel Art Sampling)" % ban_cnt,
			"  Banner A Brightness: %.2f | Banner B Brightness: %.2f",
			"CRYSTAL GLOW: Soft Radial Shaders (No ColorRect Boxes)",
			"REAL PARTICLES LOADED: %d / 8 (Nearest Pixel Art Sampling)",
			"  Type: %s | Active Count: %d | Opacity: %.2f",
			"FPS: %d | PLAYING: %s | UI CONTROLS: %s"
		]) % [
			_auth_bg_node.banner_a_brightness if _auth_bg_node else 0.75,
			_auth_bg_node.banner_b_brightness if _auth_bg_node else 0.72,
			part_cnt,
			_auth_bg_node.particle_type if _auth_bg_node else "MIXED",
			_auth_bg_node.get_particle_count() if _auth_bg_node else 14,
			_auth_bg_node.dust_opacity if _auth_bg_node else 0.35,
			Engine.get_frames_per_second(),
			str(_auth_bg_node.is_playing() if _auth_bg_node else true).to_lower(),
			"VISIBLE" if _controls_visible else "HIDDEN (Tab)"
		]
		return

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
		var overscan_info: Dictionary = calculate_overscan_info(vp_size)
		var disp_w: float = overscan_info["disp_width"]
		var disp_h: float = overscan_info["disp_height"]
		var w: int = _procedural_texture.get_width() if _procedural_texture != null else 2115
		var h: int = _procedural_texture.get_height() if _procedural_texture != null else 744

		var disp_w_str: String = "%.0f" % disp_w
		var disp_h_str: String = "%.0f" % disp_h

		_diag_label.text = "\n".join([
			"PRODUCTION PRESET: D1_FOG_V1 (0.48 / 120 / 0.15 / 0.08 / 0.05 / 3)",
			"FOG SOURCE: d1_misty_forest_fog_layer.png",
			"SOURCE SIZE: %dx%d" % [w, h],
			"VIEWPORT: %.0fx%.0f" % [vp_size.x, vp_size.y],
			"DISPLAY SIZE: %sx%s" % [disp_w_str, disp_h_str],
			"HORIZONTAL OVERSCAN LEFT: %.1f px" % _last_diag_left_overscan,
			"HORIZONTAL OVERSCAN RIGHT: %.1f px" % _last_diag_right_overscan,
			"CURRENT OFFSET: %.1f" % _last_diag_curr_offset,
			"REQUIRED OVERSCAN: %.1f" % overscan_info["required_overscan"],
			"EDGE SAFE: %s" % str(_last_diag_edge_safe).to_lower(),
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

func set_procedural_time(t: float) -> void:
	_procedural_time = t
	_update_procedural_motion()

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

	if _auth_bg_node != null:
		_auth_bg_node.reset_defaults()

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

func is_edge_safe() -> bool:
	return _last_diag_edge_safe

func get_left_overscan() -> float:
	return _last_diag_left_overscan

func get_right_overscan() -> float:
	return _last_diag_right_overscan

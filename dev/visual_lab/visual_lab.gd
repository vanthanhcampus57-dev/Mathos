class_name VisualLab
extends Control

## Developer & QA Visual Asset Lab for Mathos Engine.
## Provides isolated diagnosis of visual presentation, fog overlays, frame inspection,
## procedural fog animation, side-by-side old vs new comparison,
## and Auth/Login Academy background real asset tuning (V4 Wiring), without mutating save/gameplay data.

enum LabMode { FOG_TEST, AUTH_LOGIN_BG, FUTURE_TAB_3 }
enum MotionMode { CURRENT_ATLAS_ANIMATION, STATIC_FRAME }
enum FogSourceMode { NEW_PROCEDURAL_LAYER, OLD_ATLAS_8F }
enum BannerSelection { NONE, BANNER_A, BANNER_B, BANNER_C }
enum BannerCorner { NONE, TL, TR, BL, BR }
enum BannerDragMode { NONE, CORNER, WHOLE }
enum LightDragMode { NONE, CENTER, RADIUS }

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
var _ban_a_warp_spins: Array[SpinBox] = []
var _ban_b_warp_spins: Array[SpinBox] = []
var _ban_c_warp_spins: Array[SpinBox] = []
var _banner_selection: BannerSelection = BannerSelection.NONE
var _banner_warp_overlay: BannerWarpOverlay = null
var _banner_sel_status_label: Label = null
var _adv_warp_box: VBoxContainer = null
var _adv_toggle_btn: Button = null

# Local Light Spots UI State
var _active_light_index: int = -1
var _is_adding_light_spot: bool = false
var _light_status_lbl: Label = null
var _light_list_container: GridContainer = null
var _light_editor_box: VBoxContainer = null
var _light_intensity_slider: HSlider = null
var _light_softness_slider: HSlider = null
var _light_radius_slider: HSlider = null
var _light_del_btn: Button = null
var _add_light_btn: Button = null

# Preset Persistence State
var preset_directory: String = "D:/Mathos_Visual_Presets/AuthBackground"
var auto_load_on_startup: bool = true
var _autosave_enabled: bool = true
var _autosave_pending: bool = false
var _autosave_timer: float = 0.0
const AUTOSAVE_DELAY: float = 1.0
var _auth_session_loaded: bool = false
var _preset_status_lbl: Label = null
var _preset_dropdown: OptionButton = null
var _save_as_name_edit: LineEdit = null
var _save_current_btn: Button = null
var _restore_session_btn: Button = null
var _save_as_btn: Button = null
var _load_preset_btn: Button = null
var _autosave_chk: CheckBox = null

# Auth BG Controls References for UI Sync
var _afog_op_slider: HSlider = null
var _afog_bright_slider: HSlider = null
var _afog_sat_slider: HSlider = null
var _afog_cnt_spin: SpinBox = null
var _ban_a_bright_slider: HSlider = null
var _ban_b_bright_slider: HSlider = null
var _ban_c_bright_slider: HSlider = null
var _dust_chk: CheckBox = null
var _dust_cnt_spin: SpinBox = null
var _part_type_opt: OptionButton = null

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

# Diagnostics State Cash & Throttling
const DIAG_REFRESH_INTERVAL: float = 0.2 # 5 Hz refresh throttle
var _diag_refresh_timer: float = 0.0
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
	if _ctrl_panel == null:
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
	if _autosave_pending and _autosave_enabled:
		_autosave_timer -= delta
		if _autosave_timer <= 0.0:
			_autosave_pending = false
			save_current()

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

	_diag_refresh_timer += delta
	if _diag_refresh_timer >= DIAG_REFRESH_INTERVAL:
		_diag_refresh_timer = 0.0
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

func _create_warp_corner_row(corner_label: String, get_val: Callable, set_val_x: Callable, set_val_y: Callable) -> Dictionary:
	var row: HBoxContainer = HBoxContainer.new()
	var lbl: Label = Label.new()
	lbl.text = "%-3s:" % corner_label
	lbl.custom_minimum_size = Vector2(36, 0)
	row.add_child(lbl)

	var lx: Label = Label.new(); lx.text = "X"
	row.add_child(lx)
	var spin_x: SpinBox = SpinBox.new()
	spin_x.min_value = -100.0
	spin_x.max_value = 100.0
	spin_x.step = 1.0
	spin_x.value = get_val.call().x
	spin_x.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_x.value_changed.connect(func(v):
		set_val_x.call(v)
		if _banner_warp_overlay != null: _banner_warp_overlay.queue_redraw()
		schedule_autosave()
	)
	row.add_child(spin_x)

	var ly: Label = Label.new(); ly.text = "Y"
	row.add_child(ly)
	var spin_y: SpinBox = SpinBox.new()
	spin_y.min_value = -100.0
	spin_y.max_value = 100.0
	spin_y.step = 1.0
	spin_y.value = get_val.call().y
	spin_y.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_y.value_changed.connect(func(v):
		set_val_y.call(v)
		if _banner_warp_overlay != null: _banner_warp_overlay.queue_redraw()
		schedule_autosave()
	)
	row.add_child(spin_y)

	return {"row": row, "spin_x": spin_x, "spin_y": spin_y}

# ==============================================================================
# Direct Mouse-Driven Interactive Visual Banner Warp Overlay
# ==============================================================================
class BannerWarpOverlay extends Control:
	var lab: VisualLab = null
	var drag_mode: BannerDragMode = BannerDragMode.NONE
	var drag_corner: BannerCorner = BannerCorner.NONE
	var drag_start_mouse: Vector2 = Vector2.ZERO
	var drag_start_tl: Vector2 = Vector2.ZERO
	var drag_start_tr: Vector2 = Vector2.ZERO
	var drag_start_bl: Vector2 = Vector2.ZERO
	var drag_start_br: Vector2 = Vector2.ZERO

	# Light Dragging State
	var drag_light_mode: LightDragMode = LightDragMode.NONE
	var drag_start_light_pos: Vector2 = Vector2.ZERO
	var drag_start_light_rad: float = 140.0

	var hovered_corner: BannerCorner = BannerCorner.NONE
	var hovered_banner: BannerSelection = BannerSelection.NONE

	const HANDLE_RADIUS: float = 8.0
	const HANDLE_HOVER_RADIUS: float = 14.0

	func _init(p_lab: VisualLab = null) -> void:
		lab = p_lab
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if lab == null:
			return
		var auth_bg: AuthLoginBackground = lab.get_auth_background()
		if auth_bg == null or not auth_bg.visible:
			return

		var m_pos: Vector2 = auth_bg.get_global_transform().affine_inverse() * event.global_position

		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					# 0. If in Add Light Spot Mode, create light at click position
					if lab.is_adding_light_spot():
						var new_idx: int = auth_bg.add_light_spot(m_pos, 140.0, 1.0, Color(0.25, 0.75, 1.0, 1.0), 0.8)
						lab.select_light(new_idx)
						lab.cancel_adding_light_spot()
						lab.schedule_autosave()
						accept_event()
						queue_redraw()
						return

					var cur_l_idx: int = lab.get_active_light_index()
					var current_sel: BannerSelection = lab.get_banner_selection()

					# 1. Selected light handle interaction (radius handle or center handle)
					if cur_l_idx >= 0 and cur_l_idx < auth_bg.get_light_spot_count():
						var sl: Dictionary = auth_bg.get_light_spot(cur_l_idx)
						var r_hpos: Vector2 = sl["position"] + Vector2(sl["radius"], 0.0)
						if m_pos.distance_to(r_hpos) <= 14.0:
							drag_light_mode = LightDragMode.RADIUS
							drag_start_mouse = m_pos
							drag_start_light_rad = sl["radius"]
							accept_event()
							queue_redraw()
							return
						if m_pos.distance_to(sl["position"]) <= 14.0:
							drag_light_mode = LightDragMode.CENTER
							drag_start_mouse = m_pos
							drag_start_light_pos = sl["position"]
							accept_event()
							queue_redraw()
							return

					# 2. Click any unselected light center handle to select and drag
					for i in range(auth_bg.get_light_spot_count()):
						var lspot: Dictionary = auth_bg.get_light_spot(i)
						if m_pos.distance_to(lspot["position"]) <= 14.0:
							lab.select_light(i)
							drag_light_mode = LightDragMode.CENTER
							drag_start_mouse = m_pos
							drag_start_light_pos = lspot["position"]
							accept_event()
							queue_redraw()
							return

					# 3. If banner is selected, test corner handles first
					if current_sel != BannerSelection.NONE:
						var quad: Dictionary = _get_raw_banner_quad(current_sel, auth_bg)
						var hit_c: BannerCorner = _hit_test_corners(m_pos, quad)
						if hit_c != BannerCorner.NONE:
							drag_mode = BannerDragMode.CORNER
							drag_corner = hit_c
							drag_start_mouse = m_pos
							_save_drag_start_offsets(current_sel, auth_bg)
							accept_event()
							queue_redraw()
							return

					# 4. If banner is selected, test interior drag (whole banner translation)
					if current_sel != BannerSelection.NONE:
						var quad: Dictionary = _get_raw_banner_quad(current_sel, auth_bg)
						if _is_point_in_quad(m_pos, quad):
							drag_mode = BannerDragMode.WHOLE
							drag_start_mouse = m_pos
							_save_drag_start_offsets(current_sel, auth_bg)
							accept_event()
							queue_redraw()
							return

					# 5. Direct canvas selection with overlap priority: C above B above A
					var c_quad: Dictionary = auth_bg.get_banner_c_quad_points()
					if _is_point_in_quad(m_pos, c_quad):
						lab.select_banner_c()
						drag_mode = BannerDragMode.WHOLE
						drag_start_mouse = m_pos
						_save_drag_start_offsets(BannerSelection.BANNER_C, auth_bg)
						accept_event()
						queue_redraw()
						return

					var b_quad: Dictionary = auth_bg.get_banner_b_quad_points()
					if _is_point_in_quad(m_pos, b_quad):
						lab.select_banner_b()
						drag_mode = BannerDragMode.WHOLE
						drag_start_mouse = m_pos
						_save_drag_start_offsets(BannerSelection.BANNER_B, auth_bg)
						accept_event()
						queue_redraw()
						return

					var a_quad: Dictionary = auth_bg.get_banner_a_quad_points()
					if _is_point_in_quad(m_pos, a_quad):
						lab.select_banner_a()
						drag_mode = BannerDragMode.WHOLE
						drag_start_mouse = m_pos
						_save_drag_start_offsets(BannerSelection.BANNER_A, auth_bg)
						accept_event()
						queue_redraw()
						return

					# 6. If clicked inside selected light's influence radius, allow whole light drag
					if cur_l_idx >= 0 and cur_l_idx < auth_bg.get_light_spot_count():
						var sl: Dictionary = auth_bg.get_light_spot(cur_l_idx)
						if m_pos.distance_to(sl["position"]) <= sl["radius"]:
							drag_light_mode = LightDragMode.CENTER
							drag_start_mouse = m_pos
							drag_start_light_pos = sl["position"]
							accept_event()
							queue_redraw()
							return

					# 7. Empty background clicked -> deselect everything
					lab.deselect_banner()
					lab.deselect_light()
					drag_mode = BannerDragMode.NONE
					drag_light_mode = LightDragMode.NONE
					accept_event()
					queue_redraw()
				else:
					# Release mouse drag
					var was_dragging: bool = (drag_mode != BannerDragMode.NONE or drag_light_mode != LightDragMode.NONE)
					drag_mode = BannerDragMode.NONE
					drag_corner = BannerCorner.NONE
					drag_light_mode = LightDragMode.NONE
					if was_dragging and lab != null:
						lab.schedule_autosave()
					accept_event()
					queue_redraw()

		elif event is InputEventMouseMotion:
			if drag_light_mode != LightDragMode.NONE:
				var delta: Vector2 = m_pos - drag_start_mouse
				var active_idx: int = lab.get_active_light_index()
				if active_idx >= 0 and active_idx < auth_bg.get_light_spot_count():
					if drag_light_mode == LightDragMode.CENTER:
						auth_bg.set_light_spot_position(active_idx, drag_start_light_pos + delta)
					elif drag_light_mode == LightDragMode.RADIUS:
						var cur_l: Dictionary = auth_bg.get_light_spot(active_idx)
						var new_rad: float = (m_pos - cur_l["position"]).length()
						auth_bg.set_light_spot_radius(active_idx, clampf(new_rad, 20.0, 600.0))
				lab._update_light_ui()
				accept_event()
				queue_redraw()
			elif drag_mode != BannerDragMode.NONE:
				var delta: Vector2 = m_pos - drag_start_mouse
				var current_sel: BannerSelection = lab.get_banner_selection()

				if drag_mode == BannerDragMode.CORNER:
					match drag_corner:
						BannerCorner.TL:
							if current_sel == BannerSelection.BANNER_A: auth_bg.banner_a_warp_tl = drag_start_tl + delta
							elif current_sel == BannerSelection.BANNER_B: auth_bg.banner_b_warp_tl = drag_start_tl + delta
							elif current_sel == BannerSelection.BANNER_C: auth_bg.banner_c_warp_tl = drag_start_tl + delta
						BannerCorner.TR:
							if current_sel == BannerSelection.BANNER_A: auth_bg.banner_a_warp_tr = drag_start_tr + delta
							elif current_sel == BannerSelection.BANNER_B: auth_bg.banner_b_warp_tr = drag_start_tr + delta
							elif current_sel == BannerSelection.BANNER_C: auth_bg.banner_c_warp_tr = drag_start_tr + delta
						BannerCorner.BL:
							if current_sel == BannerSelection.BANNER_A: auth_bg.banner_a_warp_bl = drag_start_bl + delta
							elif current_sel == BannerSelection.BANNER_B: auth_bg.banner_b_warp_bl = drag_start_bl + delta
							elif current_sel == BannerSelection.BANNER_C: auth_bg.banner_c_warp_bl = drag_start_bl + delta
						BannerCorner.BR:
							if current_sel == BannerSelection.BANNER_A: auth_bg.banner_a_warp_br = drag_start_br + delta
							elif current_sel == BannerSelection.BANNER_B: auth_bg.banner_b_warp_br = drag_start_br + delta
							elif current_sel == BannerSelection.BANNER_C: auth_bg.banner_c_warp_br = drag_start_br + delta
				elif drag_mode == BannerDragMode.WHOLE:
					if current_sel == BannerSelection.BANNER_A:
						auth_bg.banner_a_warp_tl = drag_start_tl + delta
						auth_bg.banner_a_warp_tr = drag_start_tr + delta
						auth_bg.banner_a_warp_bl = drag_start_bl + delta
						auth_bg.banner_a_warp_br = drag_start_br + delta
					elif current_sel == BannerSelection.BANNER_B:
						auth_bg.banner_b_warp_tl = drag_start_tl + delta
						auth_bg.banner_b_warp_tr = drag_start_tr + delta
						auth_bg.banner_b_warp_bl = drag_start_bl + delta
						auth_bg.banner_b_warp_br = drag_start_br + delta
					elif current_sel == BannerSelection.BANNER_C:
						auth_bg.banner_c_warp_tl = drag_start_tl + delta
						auth_bg.banner_c_warp_tr = drag_start_tr + delta
						auth_bg.banner_c_warp_bl = drag_start_bl + delta
						auth_bg.banner_c_warp_br = drag_start_br + delta

				lab._sync_spinboxes_from_bg()
				accept_event()
				queue_redraw()
			else:
				_update_hover_state(m_pos, auth_bg)
				queue_redraw()

	func _hit_test_corners(p: Vector2, quad: Dictionary) -> BannerCorner:
		if p.distance_to(quad["TL"]) <= HANDLE_HOVER_RADIUS:
			return BannerCorner.TL
		if p.distance_to(quad["TR"]) <= HANDLE_HOVER_RADIUS:
			return BannerCorner.TR
		if p.distance_to(quad["BL"]) <= HANDLE_HOVER_RADIUS:
			return BannerCorner.BL
		if p.distance_to(quad["BR"]) <= HANDLE_HOVER_RADIUS:
			return BannerCorner.BR
		return BannerCorner.NONE

	func _is_point_in_quad(p: Vector2, quad: Dictionary) -> bool:
		var poly: PackedVector2Array = PackedVector2Array([
			quad["TL"],
			quad["TR"],
			quad["BR"],
			quad["BL"]
		])
		return Geometry2D.is_point_in_polygon(p, poly)

	func _get_raw_banner_quad(sel: BannerSelection, auth_bg: AuthLoginBackground) -> Dictionary:
		if sel == BannerSelection.BANNER_A: return auth_bg.get_banner_a_quad_points()
		elif sel == BannerSelection.BANNER_B: return auth_bg.get_banner_b_quad_points()
		elif sel == BannerSelection.BANNER_C: return auth_bg.get_banner_c_quad_points()
		return {}

	func _save_drag_start_offsets(sel: BannerSelection, auth_bg: AuthLoginBackground) -> void:
		if sel == BannerSelection.BANNER_A:
			drag_start_tl = auth_bg.banner_a_warp_tl
			drag_start_tr = auth_bg.banner_a_warp_tr
			drag_start_bl = auth_bg.banner_a_warp_bl
			drag_start_br = auth_bg.banner_a_warp_br
		elif sel == BannerSelection.BANNER_B:
			drag_start_tl = auth_bg.banner_b_warp_tl
			drag_start_tr = auth_bg.banner_b_warp_tr
			drag_start_bl = auth_bg.banner_b_warp_bl
			drag_start_br = auth_bg.banner_b_warp_br
		elif sel == BannerSelection.BANNER_C:
			drag_start_tl = auth_bg.banner_c_warp_tl
			drag_start_tr = auth_bg.banner_c_warp_tr
			drag_start_bl = auth_bg.banner_c_warp_bl
			drag_start_br = auth_bg.banner_c_warp_br

	func _update_hover_state(m_pos: Vector2, auth_bg: AuthLoginBackground) -> void:
		if lab.is_adding_light_spot():
			mouse_default_cursor_shape = Control.CURSOR_CROSS
			return

		var current_light_idx: int = lab.get_active_light_index()
		if current_light_idx >= 0 and current_light_idx < auth_bg.get_light_spot_count():
			var sl: Dictionary = auth_bg.get_light_spot(current_light_idx)
			var r_handle_pos: Vector2 = sl["position"] + Vector2(sl["radius"], 0.0)
			if m_pos.distance_to(r_handle_pos) <= 14.0:
				mouse_default_cursor_shape = Control.CURSOR_HSIZE
				return
			if m_pos.distance_to(sl["position"]) <= 14.0:
				mouse_default_cursor_shape = Control.CURSOR_CROSS
				return

		for i in range(auth_bg.get_light_spot_count()):
			var lspot: Dictionary = auth_bg.get_light_spot(i)
			if m_pos.distance_to(lspot["position"]) <= 14.0:
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				return

		var current_sel: BannerSelection = lab.get_banner_selection()
		hovered_corner = BannerCorner.NONE
		hovered_banner = BannerSelection.NONE

		if current_sel != BannerSelection.NONE:
			var quad: Dictionary = _get_raw_banner_quad(current_sel, auth_bg)
			hovered_corner = _hit_test_corners(m_pos, quad)
			if hovered_corner != BannerCorner.NONE:
				mouse_default_cursor_shape = Control.CURSOR_CROSS
				return
			if _is_point_in_quad(m_pos, quad):
				mouse_default_cursor_shape = Control.CURSOR_MOVE
				return

		var c_quad: Dictionary = auth_bg.get_banner_c_quad_points()
		if _is_point_in_quad(m_pos, c_quad):
			hovered_banner = BannerSelection.BANNER_C
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			return

		var b_quad: Dictionary = auth_bg.get_banner_b_quad_points()
		if _is_point_in_quad(m_pos, b_quad):
			hovered_banner = BannerSelection.BANNER_B
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			return

		var a_quad: Dictionary = auth_bg.get_banner_a_quad_points()
		if _is_point_in_quad(m_pos, a_quad):
			hovered_banner = BannerSelection.BANNER_A
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			return

		mouse_default_cursor_shape = Control.CURSOR_ARROW

	func _to_overlay(p: Vector2, auth_bg: AuthLoginBackground) -> Vector2:
		var global_pos: Vector2 = auth_bg.get_global_transform() * p
		return get_global_transform().affine_inverse() * global_pos

	func _get_overlay_quad(sel: BannerSelection, auth_bg: AuthLoginBackground) -> Dictionary:
		var raw: Dictionary = _get_raw_banner_quad(sel, auth_bg)
		return {
			"TL": _to_overlay(raw["TL"], auth_bg),
			"TR": _to_overlay(raw["TR"], auth_bg),
			"BL": _to_overlay(raw["BL"], auth_bg),
			"BR": _to_overlay(raw["BR"], auth_bg)
		}

	func _draw() -> void:
		if lab == null:
			return
		var auth_bg: AuthLoginBackground = lab.get_auth_background()
		if auth_bg == null or not auth_bg.visible:
			return

		var current_sel: BannerSelection = lab.get_banner_selection()
		var active_light_idx: int = lab.get_active_light_index()

		# 1. Unselected banner hover hints
		if hovered_banner != BannerSelection.NONE and hovered_banner != current_sel:
			var hint_text: String = "Banner C (Click to select)" if hovered_banner == BannerSelection.BANNER_C else ("Banner B (Click to select)" if hovered_banner == BannerSelection.BANNER_B else "Banner A (Click to select)")
			_draw_hover_guide(_get_overlay_quad(hovered_banner, auth_bg), hint_text)

		# 2. Selected banner quad outline, fill, 4 corner handles and labels
		if current_sel != BannerSelection.NONE:
			var quad: Dictionary = _get_overlay_quad(current_sel, auth_bg)
			var banner_title: String = "BANNER A" if current_sel == BannerSelection.BANNER_A else ("BANNER B" if current_sel == BannerSelection.BANNER_B else "BANNER C")
			var theme_col: Color = Color(0.18, 0.85, 1.0, 0.95) if current_sel == BannerSelection.BANNER_A else (Color(1.0, 0.78, 0.22, 0.95) if current_sel == BannerSelection.BANNER_B else Color(0.85, 0.45, 1.0, 0.95))
			var fill_col: Color = Color(theme_col.r, theme_col.g, theme_col.b, 0.12)

			var poly: PackedVector2Array = PackedVector2Array([quad["TL"], quad["TR"], quad["BR"], quad["BL"]])
			draw_colored_polygon(poly, fill_col)

			draw_line(quad["TL"], quad["TR"], theme_col, 2.0, true)
			draw_line(quad["TR"], quad["BR"], theme_col, 2.0, true)
			draw_line(quad["BR"], quad["BL"], theme_col, 2.0, true)
			draw_line(quad["BL"], quad["TL"], theme_col, 2.0, true)

			var top_mid: Vector2 = (quad["TL"] + quad["TR"]) * 0.5
			var badge_pos: Vector2 = top_mid + Vector2(-40, -22)
			draw_rect(Rect2(badge_pos, Vector2(80, 18)), Color(0.06, 0.06, 0.10, 0.85), true)
			draw_rect(Rect2(badge_pos, Vector2(80, 18)), theme_col, false, 1.0)
			draw_string(ThemeDB.fallback_font, badge_pos + Vector2(40, 13), banner_title, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, theme_col)

			_draw_handle("TL", quad["TL"], theme_col, BannerCorner.TL, Vector2(-24, -8))
			_draw_handle("TR", quad["TR"], theme_col, BannerCorner.TR, Vector2(10, -8))
			_draw_handle("BL", quad["BL"], theme_col, BannerCorner.BL, Vector2(-24, 18))
			_draw_handle("BR", quad["BR"], theme_col, BannerCorner.BR, Vector2(10, 18))

		# 3. Local Light Spots overlay rendering
		var light_cnt: int = auth_bg.get_light_spot_count()
		for i in range(light_cnt):
			var l: Dictionary = auth_bg.get_light_spot(i)
			var ov_pos: Vector2 = _to_overlay(l["position"], auth_bg)
			var scale_factor: float = auth_bg.get_global_transform().get_scale().x
			var ov_radius: float = l["radius"] * scale_factor

			if i == active_light_idx:
				# Selected light: circular boundary, soft tinted fill, center handle, radius handle
				draw_arc(ov_pos, ov_radius, 0.0, TAU, 64, Color(0.3, 0.88, 1.0, 0.85), 2.0)
				draw_circle(ov_pos, ov_radius, Color(0.2, 0.75, 1.0, 0.06 * l.get("intensity", 1.0)))

				# Center handle
				draw_circle(ov_pos, 9.0, Color(0.04, 0.04, 0.08, 0.95))
				draw_circle(ov_pos, 7.0, Color(0.25, 0.85, 1.0, 1.0))
				draw_circle(ov_pos, 3.0, Color.WHITE)

				# Radius handle at circumference
				var r_handle_pos: Vector2 = ov_pos + Vector2(ov_radius, 0.0)
				draw_circle(r_handle_pos, 7.0, Color(0.04, 0.04, 0.08, 0.95))
				draw_circle(r_handle_pos, 5.0, Color(1.0, 0.85, 0.3, 1.0))
				draw_string(ThemeDB.fallback_font, r_handle_pos + Vector2(8, 4), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.85, 0.3, 1.0))

				# Info badge
				var info_txt: String = "Light %d (R=%.0f, Int=%.2f)" % [i + 1, l["radius"], l["intensity"]]
				draw_string(ThemeDB.fallback_font, ov_pos + Vector2(0, -14), info_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.4, 0.95, 1.0, 1.0))
			else:
				# Unselected light: compact center dot with label
				draw_circle(ov_pos, 6.0, Color(0.04, 0.04, 0.08, 0.9))
				draw_circle(ov_pos, 4.0, Color(0.25, 0.75, 1.0, 0.75))
				draw_string(ThemeDB.fallback_font, ov_pos + Vector2(8, 4), "L%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.8, 1.0, 0.75))

		# 4. Placement mode cursor preview
		if lab.is_adding_light_spot():
			var m_local: Vector2 = get_local_mouse_position()
			var preview_rad: float = 140.0 * (auth_bg.get_global_transform().get_scale().x if auth_bg else 1.0)
			draw_arc(m_local, preview_rad, 0.0, TAU, 48, Color(0.3, 0.9, 1.0, 0.5), 1.5)
			draw_circle(m_local, 5.0, Color(0.3, 0.9, 1.0, 0.9))
			draw_string(ThemeDB.fallback_font, m_local + Vector2(12, -8), "Click canvas to place Light Spot", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.95, 1.0, 0.95))

	func _draw_handle(label: String, pos: Vector2, col: Color, corner: BannerCorner, lbl_offset: Vector2) -> void:
		var is_active: bool = (drag_corner == corner) or (hovered_corner == corner)
		var rad: float = HANDLE_RADIUS + (2.0 if is_active else 0.0)
		var highlight_col: Color = Color(1.0, 0.95, 0.35, 1.0) if is_active else col

		draw_circle(pos, rad + 2.5, Color(0.04, 0.04, 0.08, 0.92))
		draw_circle(pos, rad, highlight_col)
		draw_circle(pos, rad * 0.4, Color(1.0, 1.0, 1.0, 1.0))

		var badge_rect: Rect2 = Rect2(pos + lbl_offset + Vector2(-2, -9), Vector2(24, 14))
		draw_rect(badge_rect, Color(0.05, 0.05, 0.08, 0.85), true)
		draw_rect(badge_rect, highlight_col, false, 1.0)
		draw_string(ThemeDB.fallback_font, pos + lbl_offset + Vector2(12, 2), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.0, 1.0, 1.0, 1.0))

	func _draw_hover_guide(quad: Dictionary, hint: String) -> void:
		var guide_col: Color = Color(1.0, 1.0, 1.0, 0.45)
		draw_line(quad["TL"], quad["TR"], guide_col, 1.5, true)
		draw_line(quad["TR"], quad["BR"], guide_col, 1.5, true)
		draw_line(quad["BR"], quad["BL"], guide_col, 1.5, true)
		draw_line(quad["BL"], quad["TL"], guide_col, 1.5, true)
		var top_mid: Vector2 = (quad["TL"] + quad["TR"]) * 0.5
		draw_string(ThemeDB.fallback_font, top_mid + Vector2(0, -8), hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, guide_col)

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

	_banner_warp_overlay = BannerWarpOverlay.new(self)
	_banner_warp_overlay.name = "BannerWarpOverlay"
	_banner_warp_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_warp_overlay.visible = false
	add_child(_banner_warp_overlay)

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

	# SECTION 0: PRESETS & PERSISTENCE
	var hdr_presets: Label = Label.new()
	hdr_presets.text = "=== PRESETS & PERSISTENCE ==="
	_auth_ctrl_box.add_child(hdr_presets)

	_preset_status_lbl = Label.new()
	_preset_status_lbl.text = "Preset: Ready"
	_preset_status_lbl.modulate = Color(0.4, 0.9, 0.6, 1.0)
	_auth_ctrl_box.add_child(_preset_status_lbl)

	# Save Current & Restore Last Session Row
	var p_row1: HBoxContainer = HBoxContainer.new()
	_save_current_btn = Button.new()
	_save_current_btn.text = "SAVE CURRENT"
	_save_current_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_current_btn.pressed.connect(func():
		var ok: bool = save_current()
		if ok:
			_preset_status_lbl.text = "Saved: last_session.json"
			_preset_status_lbl.modulate = Color(0.4, 0.9, 0.6, 1.0)
			_refresh_preset_dropdown()
		else:
			_preset_status_lbl.text = "Failed to save preset!"
			_preset_status_lbl.modulate = Color(1.0, 0.4, 0.4, 1.0)
	)
	p_row1.add_child(_save_current_btn)

	_restore_session_btn = Button.new()
	_restore_session_btn.text = "RESTORE LAST SESSION"
	_restore_session_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_restore_session_btn.pressed.connect(func():
		var ok: bool = restore_last_session()
		if ok:
			_preset_status_lbl.text = "Restored: last_session.json"
			_preset_status_lbl.modulate = Color(0.4, 0.9, 0.6, 1.0)
		else:
			_preset_status_lbl.text = "No last_session.json found!"
			_preset_status_lbl.modulate = Color(1.0, 0.6, 0.3, 1.0)
	)
	p_row1.add_child(_restore_session_btn)
	_auth_ctrl_box.add_child(p_row1)

	# Save As Preset Row
	var p_row2: HBoxContainer = HBoxContainer.new()
	_save_as_name_edit = LineEdit.new()
	_save_as_name_edit.placeholder_text = "preset_name"
	_save_as_name_edit.text = "preset_custom"
	_save_as_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_row2.add_child(_save_as_name_edit)

	_save_as_btn = Button.new()
	_save_as_btn.text = "SAVE AS"
	_save_as_btn.custom_minimum_size = Vector2(90, 0)
	_save_as_btn.pressed.connect(func():
		var name_str: String = _save_as_name_edit.text.strip_edges()
		if name_str.is_empty():
			name_str = "preset_custom"
		var ok: bool = save_as_preset(name_str)
		if ok:
			_preset_status_lbl.text = "Saved as: %s" % (name_str if name_str.ends_with(".json") else name_str + ".json")
			_preset_status_lbl.modulate = Color(0.4, 0.9, 0.6, 1.0)
			_refresh_preset_dropdown()
		else:
			_preset_status_lbl.text = "Failed to save as preset!"
			_preset_status_lbl.modulate = Color(1.0, 0.4, 0.4, 1.0)
	)
	p_row2.add_child(_save_as_btn)
	_auth_ctrl_box.add_child(p_row2)

	# Load Preset Row
	var p_row3: HBoxContainer = HBoxContainer.new()
	_preset_dropdown = OptionButton.new()
	_preset_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_row3.add_child(_preset_dropdown)

	_load_preset_btn = Button.new()
	_load_preset_btn.text = "LOAD PRESET"
	_load_preset_btn.custom_minimum_size = Vector2(90, 0)
	_load_preset_btn.pressed.connect(func():
		if _preset_dropdown.item_count > 0:
			var sel_idx: int = _preset_dropdown.selected
			if sel_idx >= 0 and sel_idx < _preset_dropdown.item_count:
				var fname: String = _preset_dropdown.get_item_text(sel_idx)
				var ok: bool = load_preset(fname)
				if ok:
					_preset_status_lbl.text = "Loaded: %s" % fname
					_preset_status_lbl.modulate = Color(0.4, 0.9, 0.6, 1.0)
				else:
					_preset_status_lbl.text = "Failed to load: %s" % fname
					_preset_status_lbl.modulate = Color(1.0, 0.4, 0.4, 1.0)
	)
	p_row3.add_child(_load_preset_btn)
	_auth_ctrl_box.add_child(p_row3)

	# Auto-Save Toggle
	_autosave_chk = CheckBox.new()
	_autosave_chk.text = "Auto-save on edit"
	_autosave_chk.button_pressed = _autosave_enabled
	_autosave_chk.toggled.connect(func(t: bool):
		set_autosave_enabled(t)
		if not t:
			_preset_status_lbl.text = "Auto-save disabled"
		else:
			_preset_status_lbl.text = "Auto-save enabled"
	)
	_auth_ctrl_box.add_child(_autosave_chk)

	_refresh_preset_dropdown()

	# SECTION 1: FOG CLUSTERS & TINT / BRIGHTNESS / SATURATION
	var hdr_auth_fog: Label = Label.new(); hdr_auth_fog.text = "=== FOG CLUSTERS & SHADER ==="
	_auth_ctrl_box.add_child(hdr_auth_fog)

	var afog_op_lbl: Label = Label.new(); afog_op_lbl.text = "Fog Master Opacity (0..1):"
	_afog_op_slider = HSlider.new(); _afog_op_slider.min_value = 0.0; _afog_op_slider.max_value = 1.0; _afog_op_slider.step = 0.02; _afog_op_slider.value = AuthLoginBackground.DEFAULT_FOG_MASTER_OPACITY
	_afog_op_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.fog_master_opacity = v; schedule_autosave())
	_auth_ctrl_box.add_child(afog_op_lbl); _auth_ctrl_box.add_child(_afog_op_slider)

	var afog_bright_lbl: Label = Label.new(); afog_bright_lbl.text = "Fog Brightness (0.4..1.2):"
	_afog_bright_slider = HSlider.new(); _afog_bright_slider.min_value = 0.4; _afog_bright_slider.max_value = 1.2; _afog_bright_slider.step = 0.05; _afog_bright_slider.value = AuthLoginBackground.DEFAULT_FOG_BRIGHTNESS
	_afog_bright_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.fog_brightness = v; schedule_autosave())
	_auth_ctrl_box.add_child(afog_bright_lbl); _auth_ctrl_box.add_child(_afog_bright_slider)

	var afog_sat_lbl: Label = Label.new(); afog_sat_lbl.text = "Fog Saturation (0.3..1.2):"
	_afog_sat_slider = HSlider.new(); _afog_sat_slider.min_value = 0.3; _afog_sat_slider.max_value = 1.2; _afog_sat_slider.step = 0.05; _afog_sat_slider.value = AuthLoginBackground.DEFAULT_FOG_SATURATION
	_afog_sat_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.fog_saturation = v; schedule_autosave())
	_auth_ctrl_box.add_child(afog_sat_lbl); _auth_ctrl_box.add_child(_afog_sat_slider)

	var afog_cnt_lbl: Label = Label.new(); afog_cnt_lbl.text = "Visible Cluster Count (1..20):"
	_afog_cnt_spin = SpinBox.new(); _afog_cnt_spin.min_value = 1; _afog_cnt_spin.max_value = 20; _afog_cnt_spin.value = AuthLoginBackground.DEFAULT_FOG_CLUSTER_COUNT
	_afog_cnt_spin.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.set_fog_cluster_count(int(v)); schedule_autosave())
	_auth_ctrl_box.add_child(afog_cnt_lbl); _auth_ctrl_box.add_child(_afog_cnt_spin)

	var reset_fog_btn: Button = Button.new(); reset_fog_btn.text = "RESET FOG DEFAULTS"
	reset_fog_btn.pressed.connect(func(): if _auth_bg_node: _auth_bg_node.fog_master_opacity = AuthLoginBackground.DEFAULT_FOG_MASTER_OPACITY; _auth_bg_node.fog_brightness = AuthLoginBackground.DEFAULT_FOG_BRIGHTNESS; _auth_bg_node.fog_saturation = AuthLoginBackground.DEFAULT_FOG_SATURATION; _auth_bg_node.set_fog_cluster_count(AuthLoginBackground.DEFAULT_FOG_CLUSTER_COUNT); _sync_all_auth_controls_from_bg())
	_auth_ctrl_box.add_child(reset_fog_btn)
	# SECTION 2: BANNER A, B & C (Direct Visual Warp + Collapsible Advanced Section)
	var hdr_banner: Label = Label.new()
	hdr_banner.text = "=== REAL BANNERS & VISUAL WARP ==="
	_auth_ctrl_box.add_child(hdr_banner)

	# Active Banner Status Indicator
	_banner_sel_status_label = Label.new()
	_banner_sel_status_label.text = "Active Banner: NONE (Click canvas or button below)"
	_banner_sel_status_label.modulate = Color(0.75, 0.85, 0.95, 1.0)
	_auth_ctrl_box.add_child(_banner_sel_status_label)

	# Quick Select Buttons Row
	var sel_btn_row: HBoxContainer = HBoxContainer.new()
	var sel_a_btn: Button = Button.new()
	sel_a_btn.text = "Select Banner A"
	sel_a_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_a_btn.pressed.connect(func(): select_banner_a())
	sel_btn_row.add_child(sel_a_btn)

	var sel_b_btn: Button = Button.new()
	sel_b_btn.text = "Select Banner B"
	sel_b_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_b_btn.pressed.connect(func(): select_banner_b())
	sel_btn_row.add_child(sel_b_btn)

	var sel_c_btn: Button = Button.new()
	sel_c_btn.text = "Select Banner C"
	sel_c_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_c_btn.pressed.connect(func(): select_banner_c())
	sel_btn_row.add_child(sel_c_btn)

	var desel_btn: Button = Button.new()
	desel_btn.text = "Deselect"
	desel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desel_btn.pressed.connect(func(): deselect_banner())
	sel_btn_row.add_child(desel_btn)
	_auth_ctrl_box.add_child(sel_btn_row)

	# Interactive Usage Hint
	var warp_hint_lbl: Label = Label.new()
	warp_hint_lbl.text = "Direct Mouse Interaction:\n  • Click banner on canvas to select\n  • Drag 4 corner handles (TL/TR/BL/BR) to warp\n  • Drag inside quad to translate entire banner\n  • Click empty space to deselect"
	warp_hint_lbl.modulate = Color(0.7, 0.85, 1.0, 0.85)
	_auth_ctrl_box.add_child(warp_hint_lbl)

	# Independent Reset Buttons
	var reset_row: HBoxContainer = HBoxContainer.new()
	var reset_ban_a_btn: Button = Button.new()
	reset_ban_a_btn.text = "Reset Banner A"
	reset_ban_a_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_ban_a_btn.pressed.connect(func(): reset_banner_a())
	reset_row.add_child(reset_ban_a_btn)

	var reset_ban_b_btn: Button = Button.new()
	reset_ban_b_btn.text = "Reset Banner B"
	reset_ban_b_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_ban_b_btn.pressed.connect(func(): reset_banner_b())
	reset_row.add_child(reset_ban_b_btn)

	var reset_ban_c_btn: Button = Button.new()
	reset_ban_c_btn.text = "Reset Banner C"
	reset_ban_c_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_ban_c_btn.pressed.connect(func(): reset_banner_c())
	reset_row.add_child(reset_ban_c_btn)
	_auth_ctrl_box.add_child(reset_row)

	var reset_both_btn: Button = Button.new()
	reset_both_btn.text = "[ RESET ALL BANNERS ]"
	reset_both_btn.pressed.connect(func(): reset_all_banners())
	_auth_ctrl_box.add_child(reset_both_btn)

	# Brightness Controls
	var ban_a_bright_lbl: Label = Label.new(); ban_a_bright_lbl.text = "Banner A Brightness (0.4..1.6):"
	_ban_a_bright_slider = HSlider.new(); _ban_a_bright_slider.min_value = 0.4; _ban_a_bright_slider.max_value = 1.6; _ban_a_bright_slider.step = 0.05; _ban_a_bright_slider.value = AuthLoginBackground.DEFAULT_BANNER_A_BRIGHTNESS
	_ban_a_bright_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.banner_a_brightness = v; schedule_autosave())
	_auth_ctrl_box.add_child(ban_a_bright_lbl); _auth_ctrl_box.add_child(_ban_a_bright_slider)

	var ban_b_bright_lbl: Label = Label.new(); ban_b_bright_lbl.text = "Banner B Brightness (0.4..1.6):"
	_ban_b_bright_slider = HSlider.new(); _ban_b_bright_slider.min_value = 0.4; _ban_b_bright_slider.max_value = 1.6; _ban_b_bright_slider.step = 0.05; _ban_b_bright_slider.value = AuthLoginBackground.DEFAULT_BANNER_B_BRIGHTNESS
	_ban_b_bright_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.banner_b_brightness = v; schedule_autosave())
	_auth_ctrl_box.add_child(ban_b_bright_lbl); _auth_ctrl_box.add_child(_ban_b_bright_slider)

	var ban_c_bright_lbl: Label = Label.new(); ban_c_bright_lbl.text = "Banner C Brightness (0.4..1.6):"
	_ban_c_bright_slider = HSlider.new(); _ban_c_bright_slider.min_value = 0.4; _ban_c_bright_slider.max_value = 1.6; _ban_c_bright_slider.step = 0.05; _ban_c_bright_slider.value = AuthLoginBackground.DEFAULT_BANNER_C_BRIGHTNESS
	_ban_c_bright_slider.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.banner_c_brightness = v; schedule_autosave())
	_auth_ctrl_box.add_child(ban_c_bright_lbl); _auth_ctrl_box.add_child(_ban_c_bright_slider)

	# Collapsible Advanced Warp SpinBoxes (Preserved for compatibility & exact debugging, collapsed by default)
	_adv_toggle_btn = Button.new()
	_adv_toggle_btn.text = "▶ ADVANCED / PRECISE VALUES (Collapsed)"
	_adv_toggle_btn.pressed.connect(func():
		_adv_warp_box.visible = not _adv_warp_box.visible
		_adv_toggle_btn.text = "▼ ADVANCED / PRECISE VALUES (Expanded)" if _adv_warp_box.visible else "▶ ADVANCED / PRECISE VALUES (Collapsed)"
	)
	_auth_ctrl_box.add_child(_adv_toggle_btn)

	_adv_warp_box = VBoxContainer.new()
	_adv_warp_box.name = "AdvancedWarpBox"
	_adv_warp_box.visible = false

	var hdr_ban_a_warp: Label = Label.new(); hdr_ban_a_warp.text = "--- BANNER A WARP (8 Controls) ---"
	_adv_warp_box.add_child(hdr_ban_a_warp)
	_ban_a_warp_spins.clear()

	for corner in ["TL", "TR", "BL", "BR"]:
		var getter: Callable
		var setter_x: Callable
		var setter_y: Callable
		match corner:
			"TL":
				getter = func(): return _auth_bg_node.banner_a_warp_tl if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_a_warp_tl = Vector2(v, _auth_bg_node.banner_a_warp_tl.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_a_warp_tl = Vector2(_auth_bg_node.banner_a_warp_tl.x, v)
			"TR":
				getter = func(): return _auth_bg_node.banner_a_warp_tr if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_a_warp_tr = Vector2(v, _auth_bg_node.banner_a_warp_tr.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_a_warp_tr = Vector2(_auth_bg_node.banner_a_warp_tr.x, v)
			"BL":
				getter = func(): return _auth_bg_node.banner_a_warp_bl if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_a_warp_bl = Vector2(v, _auth_bg_node.banner_a_warp_bl.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_a_warp_bl = Vector2(_auth_bg_node.banner_a_warp_bl.x, v)
			"BR":
				getter = func(): return _auth_bg_node.banner_a_warp_br if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_a_warp_br = Vector2(v, _auth_bg_node.banner_a_warp_br.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_a_warp_br = Vector2(_auth_bg_node.banner_a_warp_br.x, v)
		var res: Dictionary = _create_warp_corner_row(corner, getter, setter_x, setter_y)
		_adv_warp_box.add_child(res["row"] as Control)
		_ban_a_warp_spins.append(res["spin_x"] as SpinBox)
		_ban_a_warp_spins.append(res["spin_y"] as SpinBox)

	var hdr_ban_b_warp: Label = Label.new(); hdr_ban_b_warp.text = "--- BANNER B WARP (8 Controls) ---"
	_adv_warp_box.add_child(hdr_ban_b_warp)
	_ban_b_warp_spins.clear()

	for corner in ["TL", "TR", "BL", "BR"]:
		var getter: Callable
		var setter_x: Callable
		var setter_y: Callable
		match corner:
			"TL":
				getter = func(): return _auth_bg_node.banner_b_warp_tl if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_b_warp_tl = Vector2(v, _auth_bg_node.banner_b_warp_tl.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_b_warp_tl = Vector2(_auth_bg_node.banner_b_warp_tl.x, v)
			"TR":
				getter = func(): return _auth_bg_node.banner_b_warp_tr if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_b_warp_tr = Vector2(v, _auth_bg_node.banner_b_warp_tr.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_b_warp_tr = Vector2(_auth_bg_node.banner_b_warp_tr.x, v)
			"BL":
				getter = func(): return _auth_bg_node.banner_b_warp_bl if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_b_warp_bl = Vector2(v, _auth_bg_node.banner_b_warp_bl.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_b_warp_bl = Vector2(_auth_bg_node.banner_b_warp_bl.x, v)
			"BR":
				getter = func(): return _auth_bg_node.banner_b_warp_br if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_b_warp_br = Vector2(v, _auth_bg_node.banner_b_warp_br.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_b_warp_br = Vector2(_auth_bg_node.banner_b_warp_br.x, v)
		var res: Dictionary = _create_warp_corner_row(corner, getter, setter_x, setter_y)
		_adv_warp_box.add_child(res["row"] as Control)
		_ban_b_warp_spins.append(res["spin_x"] as SpinBox)
		_ban_b_warp_spins.append(res["spin_y"] as SpinBox)

	var hdr_ban_c_warp: Label = Label.new(); hdr_ban_c_warp.text = "--- BANNER C WARP (8 Controls) ---"
	_adv_warp_box.add_child(hdr_ban_c_warp)
	_ban_c_warp_spins.clear()

	for corner in ["TL", "TR", "BL", "BR"]:
		var getter: Callable
		var setter_x: Callable
		var setter_y: Callable
		match corner:
			"TL":
				getter = func(): return _auth_bg_node.banner_c_warp_tl if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_c_warp_tl = Vector2(v, _auth_bg_node.banner_c_warp_tl.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_c_warp_tl = Vector2(_auth_bg_node.banner_c_warp_tl.x, v)
			"TR":
				getter = func(): return _auth_bg_node.banner_c_warp_tr if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_c_warp_tr = Vector2(v, _auth_bg_node.banner_c_warp_tr.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_c_warp_tr = Vector2(_auth_bg_node.banner_c_warp_tr.x, v)
			"BL":
				getter = func(): return _auth_bg_node.banner_c_warp_bl if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_c_warp_bl = Vector2(v, _auth_bg_node.banner_c_warp_bl.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_c_warp_bl = Vector2(_auth_bg_node.banner_c_warp_bl.x, v)
			"BR":
				getter = func(): return _auth_bg_node.banner_c_warp_br if _auth_bg_node else Vector2.ZERO
				setter_x = func(v): if _auth_bg_node: _auth_bg_node.banner_c_warp_br = Vector2(v, _auth_bg_node.banner_c_warp_br.y)
				setter_y = func(v): if _auth_bg_node: _auth_bg_node.banner_c_warp_br = Vector2(_auth_bg_node.banner_c_warp_br.x, v)
		var res: Dictionary = _create_warp_corner_row(corner, getter, setter_x, setter_y)
		_adv_warp_box.add_child(res["row"] as Control)
		_ban_c_warp_spins.append(res["spin_x"] as SpinBox)
		_ban_c_warp_spins.append(res["spin_y"] as SpinBox)

	_auth_ctrl_box.add_child(_adv_warp_box)

	# SECTION 3: LOCAL LIGHT SPOTS (Procedural Environmental Illumination)
	var hdr_lights: Label = Label.new()
	hdr_lights.text = "=== LOCAL LIGHT SPOTS ==="
	_auth_ctrl_box.add_child(hdr_lights)

	_light_status_lbl = Label.new()
	_light_status_lbl.text = "Lights: 0 / 16 (Click '+ LIGHT SPOT' then click canvas)"
	_light_status_lbl.modulate = Color(0.7, 0.9, 1.0, 1.0)
	_auth_ctrl_box.add_child(_light_status_lbl)

	var light_action_row: HBoxContainer = HBoxContainer.new()
	_add_light_btn = Button.new()
	_add_light_btn.text = "+ LIGHT SPOT"
	_add_light_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_light_btn.pressed.connect(func(): start_adding_light_spot())
	light_action_row.add_child(_add_light_btn)

	_light_del_btn = Button.new()
	_light_del_btn.text = "DELETE LIGHT"
	_light_del_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_light_del_btn.disabled = true
	_light_del_btn.pressed.connect(func(): delete_active_light())
	light_action_row.add_child(_light_del_btn)

	var reset_lights_btn: Button = Button.new()
	reset_lights_btn.text = "RESET LIGHTS"
	reset_lights_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_lights_btn.pressed.connect(func(): reset_lights())
	light_action_row.add_child(reset_lights_btn)
	_auth_ctrl_box.add_child(light_action_row)

	# Compact Light Selection Grid Container (Wrapped 5 columns)
	_light_list_container = GridContainer.new()
	_light_list_container.columns = 5
	_auth_ctrl_box.add_child(_light_list_container)

	# Selected Light Editor Box
	_light_editor_box = VBoxContainer.new()
	_light_editor_box.visible = false

	var hdr_sel_light: Label = Label.new()
	hdr_sel_light.text = "--- SELECTED LIGHT PROPERTIES ---"
	_light_editor_box.add_child(hdr_sel_light)

	var int_lbl: Label = Label.new(); int_lbl.text = "Intensity (0.0 .. 2.5):"
	_light_intensity_slider = HSlider.new()
	_light_intensity_slider.min_value = 0.0
	_light_intensity_slider.max_value = 2.5
	_light_intensity_slider.step = 0.05
	_light_intensity_slider.value = 1.0
	_light_intensity_slider.value_changed.connect(func(v):
		if _active_light_index >= 0 and _auth_bg_node:
			_auth_bg_node.set_light_spot_intensity(_active_light_index, v)
			if _banner_warp_overlay: _banner_warp_overlay.queue_redraw()
			schedule_autosave()
	)
	_light_editor_box.add_child(int_lbl); _light_editor_box.add_child(_light_intensity_slider)

	var soft_lbl: Label = Label.new(); soft_lbl.text = "Softness / Falloff (0.2 .. 2.0):"
	_light_softness_slider = HSlider.new()
	_light_softness_slider.min_value = 0.2
	_light_softness_slider.max_value = 2.0
	_light_softness_slider.step = 0.05
	_light_softness_slider.value = 0.8
	_light_softness_slider.value_changed.connect(func(v):
		if _active_light_index >= 0 and _auth_bg_node:
			_auth_bg_node.set_light_spot_softness(_active_light_index, v)
			if _banner_warp_overlay: _banner_warp_overlay.queue_redraw()
			schedule_autosave()
	)
	_light_editor_box.add_child(soft_lbl); _light_editor_box.add_child(_light_softness_slider)

	var rad_lbl: Label = Label.new(); rad_lbl.text = "Radius (20 .. 500 px):"
	_light_radius_slider = HSlider.new()
	_light_radius_slider.min_value = 20.0
	_light_radius_slider.max_value = 500.0
	_light_radius_slider.step = 5.0
	_light_radius_slider.value = 140.0
	_light_radius_slider.value_changed.connect(func(v):
		if _active_light_index >= 0 and _auth_bg_node:
			_auth_bg_node.set_light_spot_radius(_active_light_index, v)
			if _banner_warp_overlay: _banner_warp_overlay.queue_redraw()
			schedule_autosave()
	)
	_light_editor_box.add_child(rad_lbl); _light_editor_box.add_child(_light_radius_slider)

	var col_lbl: Label = Label.new(); col_lbl.text = "Color Palette Presets:"
	_light_editor_box.add_child(col_lbl)

	var col_row: HBoxContainer = HBoxContainer.new()
	var cyan_btn: Button = Button.new(); cyan_btn.text = "Cyan"; cyan_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cyan_btn.pressed.connect(func(): _set_active_light_color(Color(0.25, 0.75, 1.0, 1.0)))
	col_row.add_child(cyan_btn)

	var amber_btn: Button = Button.new(); amber_btn.text = "Gold"; amber_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amber_btn.pressed.connect(func(): _set_active_light_color(Color(1.0, 0.8, 0.3, 1.0)))
	col_row.add_child(amber_btn)

	var white_btn: Button = Button.new(); white_btn.text = "White"; white_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	white_btn.pressed.connect(func(): _set_active_light_color(Color(1.0, 1.0, 1.0, 1.0)))
	col_row.add_child(white_btn)

	var violet_btn: Button = Button.new(); violet_btn.text = "Violet"; violet_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	violet_btn.pressed.connect(func(): _set_active_light_color(Color(0.75, 0.4, 1.0, 1.0)))
	col_row.add_child(violet_btn)
	_light_editor_box.add_child(col_row)

	_auth_ctrl_box.add_child(_light_editor_box)

	# SECTION 3: REAL PIXEL ART PARTICLES
	var hdr_part: Label = Label.new(); hdr_part.text = "=== REAL PIXEL ART PARTICLES ==="
	_auth_ctrl_box.add_child(hdr_part)

	var part_type_lbl: Label = Label.new(); part_type_lbl.text = "Particle Type:"
	_part_type_opt = OptionButton.new()
	_part_type_opt.add_item("MIXED", 0); _part_type_opt.add_item("STAR", 1); _part_type_opt.add_item("ORB", 2); _part_type_opt.add_item("SPARKLE", 3)
	_part_type_opt.select(0)
	_part_type_opt.item_selected.connect(func(idx): if _auth_bg_node: _auth_bg_node.set_particle_type(_part_type_opt.get_item_text(idx)); schedule_autosave())
	_auth_ctrl_box.add_child(part_type_lbl); _auth_ctrl_box.add_child(_part_type_opt)

	_dust_chk = CheckBox.new(); _dust_chk.text = "Particles Enabled"; _dust_chk.button_pressed = true
	_dust_chk.toggled.connect(func(t): if _auth_bg_node: _auth_bg_node.dust_enabled = t; schedule_autosave())
	_auth_ctrl_box.add_child(_dust_chk)

	var dust_cnt_lbl: Label = Label.new(); dust_cnt_lbl.text = "Particle Count (1..50):"
	_dust_cnt_spin = SpinBox.new(); _dust_cnt_spin.min_value = 1; _dust_cnt_spin.max_value = 50; _dust_cnt_spin.value = AuthLoginBackground.DEFAULT_DUST_COUNT
	_dust_cnt_spin.value_changed.connect(func(v): if _auth_bg_node: _auth_bg_node.set_particle_count(int(v)); schedule_autosave())
	_auth_ctrl_box.add_child(dust_cnt_lbl); _auth_ctrl_box.add_child(_dust_cnt_spin)

	# SECTION 4: GLOBAL PLAYBACK
	var auth_act_hdr: Label = Label.new(); auth_act_hdr.text = "=== GLOBAL PLAYBACK ==="
	_auth_ctrl_box.add_child(auth_act_hdr)

	var auth_play_btn: Button = Button.new(); auth_play_btn.text = "Pause"
	auth_play_btn.pressed.connect(func(): if _auth_bg_node: _auth_bg_node.set_playing(not _auth_bg_node.is_playing()); auth_play_btn.text = "Pause" if _auth_bg_node.is_playing() else "Play")
	_auth_ctrl_box.add_child(auth_play_btn)

	var reset_auth_btn: Button = Button.new(); reset_auth_btn.text = "[ RESET ALL AUTH BG DEFAULTS ]"
	reset_auth_btn.pressed.connect(func():
		if _auth_bg_node: _auth_bg_node.reset_defaults()
		auth_play_btn.text = "Pause"
		for s in _ban_a_warp_spins:
			if s != null: s.set_value_no_signal(0.0)
		for s in _ban_b_warp_spins:
			if s != null: s.set_value_no_signal(0.0)
		for s in _ban_c_warp_spins:
			if s != null: s.set_value_no_signal(0.0)
		_update_light_ui()
	)
	_auth_ctrl_box.add_child(reset_auth_btn)

	vbox.add_child(_auth_ctrl_box)

	scroll.add_child(vbox)
	_ctrl_panel.add_child(scroll)
	add_child(_ctrl_panel)

	_diag_panel = PanelContainer.new()
	_diag_panel.name = "DiagPanel"
	_diag_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_diag_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_diag_panel.offset_left = -380.0
	_diag_panel.offset_top = 48.0
	_diag_panel.offset_right = -16.0

	_diag_label = Label.new(); _diag_label.text = "VISUAL LAB DIAGNOSTICS"
	_diag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	if _ctrl_panel == null:
		_build_ui_hierarchy()
	_current_lab_mode = mode
	if _current_lab_mode == LabMode.AUTH_LOGIN_BG:
		if not _auth_session_loaded:
			_auth_session_loaded = true
			if _should_autoload_session() and has_last_session():
				restore_last_session()
	if _auth_ctrl_box != null:
		_auth_ctrl_box.visible = (_current_lab_mode == LabMode.AUTH_LOGIN_BG)
	if _banner_warp_overlay != null:
		_banner_warp_overlay.visible = (_current_lab_mode == LabMode.AUTH_LOGIN_BG)
		_banner_warp_overlay.queue_redraw()
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

	if _ctrl_panel != null and _diag_panel != null:
		if _current_lab_mode == LabMode.AUTH_LOGIN_BG:
			# Dock control panel on the right so left-side banners are completely unobstructed
			_ctrl_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
			_ctrl_panel.offset_left = -360.0
			_ctrl_panel.offset_right = 0.0
			_ctrl_panel.offset_top = 48.0
			_ctrl_panel.offset_bottom = -16.0
			# Place diagnostics at bottom left
			_diag_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			_diag_panel.offset_left = 16.0
			_diag_panel.offset_top = -280.0
			_diag_panel.offset_right = 440.0
			_diag_panel.offset_bottom = -16.0
		else:
			# Default left dock for D1 fog lab
			_ctrl_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
			_ctrl_panel.offset_left = 0.0
			_ctrl_panel.offset_right = 360.0
			_ctrl_panel.offset_top = 48.0
			_ctrl_panel.offset_bottom = -16.0
			# Default top right for diagnostics
			_diag_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			_diag_panel.offset_left = -380.0
			_diag_panel.offset_top = 48.0
			_diag_panel.offset_right = -16.0
			_diag_panel.offset_bottom = 0.0

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

	cancel_autosave()
	if _auth_bg_node != null:
		_auth_bg_node.reset_defaults()

	_banner_selection = BannerSelection.NONE
	_update_banner_sel_ui()
	_sync_all_auth_controls_from_bg()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

	for s in _ban_a_warp_spins:
		if s != null: s.set_value_no_signal(0.0)
	for s in _ban_b_warp_spins:
		if s != null: s.set_value_no_signal(0.0)
	for s in _ban_c_warp_spins:
		if s != null: s.set_value_no_signal(0.0)

	_apply_parameters()

# Direct Banner Warp Manipulation & Selection Accessors
func get_banner_selection() -> BannerSelection:
	return _banner_selection

func set_banner_selection(sel: BannerSelection) -> void:
	_banner_selection = sel
	_update_banner_sel_ui()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

func select_banner_a() -> void:
	set_banner_selection(BannerSelection.BANNER_A)

func select_banner_b() -> void:
	set_banner_selection(BannerSelection.BANNER_B)

func select_banner_c() -> void:
	set_banner_selection(BannerSelection.BANNER_C)

func deselect_banner() -> void:
	set_banner_selection(BannerSelection.NONE)

func reset_banner_a() -> void:
	if _auth_bg_node != null:
		_auth_bg_node.reset_banner_a_warp()
	_sync_spinboxes_from_bg()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

func reset_banner_b() -> void:
	if _auth_bg_node != null:
		_auth_bg_node.reset_banner_b_warp()
	_sync_spinboxes_from_bg()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

func reset_banner_c() -> void:
	if _auth_bg_node != null:
		_auth_bg_node.reset_banner_c_warp()
	_sync_spinboxes_from_bg()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

func reset_all_banners() -> void:
	if _auth_bg_node != null:
		_auth_bg_node.reset_all_banners_warp()
	_sync_spinboxes_from_bg()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

func reset_both_banners() -> void:
	reset_all_banners()

# Local Light Spots Management & Accessors
func start_adding_light_spot() -> void:
	if _is_adding_light_spot:
		cancel_adding_light_spot()
		return
	_is_adding_light_spot = true
	_banner_selection = BannerSelection.NONE
	_update_banner_sel_ui()
	if _add_light_btn != null:
		_add_light_btn.text = "CANCEL PLACEMENT"
	if _light_status_lbl != null:
		_light_status_lbl.text = "Click anywhere on canvas to place light spot"
		_light_status_lbl.modulate = Color(1.0, 0.9, 0.3, 1.0)
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

func cancel_adding_light_spot() -> void:
	_is_adding_light_spot = false
	if _add_light_btn != null:
		_add_light_btn.text = "+ LIGHT SPOT"
	_update_light_ui()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

func is_adding_light_spot() -> bool:
	return _is_adding_light_spot

func select_light(idx: int) -> void:
	_is_adding_light_spot = false
	if _add_light_btn != null:
		_add_light_btn.text = "+ LIGHT SPOT"
	_active_light_index = idx
	_banner_selection = BannerSelection.NONE
	_update_banner_sel_ui()
	_update_light_ui()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

func deselect_light() -> void:
	_active_light_index = -1
	_update_light_ui()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

func get_active_light_index() -> int:
	return _active_light_index

func get_light_count() -> int:
	if _auth_bg_node != null:
		return _auth_bg_node.get_light_spot_count()
	return 0

func delete_active_light() -> void:
	if _active_light_index >= 0 and _auth_bg_node != null:
		_auth_bg_node.remove_light_spot(_active_light_index)
		_active_light_index = -1
		_update_light_ui()
		if _banner_warp_overlay != null:
			_banner_warp_overlay.queue_redraw()
		schedule_autosave()

func reset_lights() -> void:
	cancel_autosave()
	if _auth_bg_node != null:
		_auth_bg_node.reset_lights()
	_active_light_index = -1
	_is_adding_light_spot = false
	if _add_light_btn != null:
		_add_light_btn.text = "+ LIGHT SPOT"
	_update_light_ui()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

func _set_active_light_color(col: Color) -> void:
	if _active_light_index >= 0 and _auth_bg_node != null:
		_auth_bg_node.set_light_spot_color(_active_light_index, col)
		if _banner_warp_overlay != null:
			_banner_warp_overlay.queue_redraw()
		schedule_autosave()

func _update_light_ui() -> void:
	if _auth_bg_node == null:
		return
	var count: int = _auth_bg_node.get_light_spot_count()
	if _light_status_lbl != null:
		if _active_light_index >= 0 and _active_light_index < count:
			var cur_l: Dictionary = _auth_bg_node.get_light_spot(_active_light_index)
			_light_status_lbl.text = "Active: Light %d (R=%.0f, Int=%.2f) - Drag center to move, 'R' to resize" % [
				_active_light_index + 1, cur_l.get("radius", 140.0), cur_l.get("intensity", 1.0)
			]
			_light_status_lbl.modulate = Color(0.35, 0.95, 1.0, 1.0)
		else:
			_light_status_lbl.text = "Lights: %d / 16 (Click '+ LIGHT SPOT' or select light)" % count
			_light_status_lbl.modulate = Color(0.7, 0.9, 1.0, 1.0)

	if _light_del_btn != null:
		_light_del_btn.disabled = (_active_light_index < 0 or _active_light_index >= count)

	if _light_editor_box != null:
		var has_sel: bool = (_active_light_index >= 0 and _active_light_index < count)
		_light_editor_box.visible = has_sel
		if has_sel:
			var lspot: Dictionary = _auth_bg_node.get_light_spot(_active_light_index)
			if _light_intensity_slider != null:
				_light_intensity_slider.set_value_no_signal(lspot.get("intensity", 1.0))
			if _light_softness_slider != null:
				_light_softness_slider.set_value_no_signal(lspot.get("softness", 0.8))
			if _light_radius_slider != null:
				_light_radius_slider.set_value_no_signal(lspot.get("radius", 140.0))

	if _light_list_container != null:
		for c in _light_list_container.get_children():
			_light_list_container.remove_child(c)
			c.queue_free()
		for i in range(count):
			var l_btn: Button = Button.new()
			l_btn.name = "LightBtn_%d" % (i + 1)
			l_btn.text = "L%d" % (i + 1)
			l_btn.custom_minimum_size = Vector2(40, 28)
			if i == _active_light_index:
				l_btn.modulate = Color(0.3, 0.9, 1.0, 1.0)
			else:
				l_btn.modulate = Color(0.8, 0.8, 0.8, 0.8)
			var idx_capture: int = i
			l_btn.pressed.connect(func(): select_light(idx_capture))
			_light_list_container.add_child(l_btn)

func get_banner_warp_overlay() -> Control:
	if _banner_warp_overlay == null and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _banner_warp_overlay

func get_advanced_warp_box() -> VBoxContainer:
	if _adv_warp_box == null and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _adv_warp_box

func get_advanced_toggle_button() -> Button:
	if _adv_toggle_btn == null and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _adv_toggle_btn

func _sync_spinboxes_from_bg() -> void:
	if _auth_bg_node == null:
		return
	if _ban_a_warp_spins.size() >= 8:
		_ban_a_warp_spins[0].set_value_no_signal(_auth_bg_node.banner_a_warp_tl.x)
		_ban_a_warp_spins[1].set_value_no_signal(_auth_bg_node.banner_a_warp_tl.y)
		_ban_a_warp_spins[2].set_value_no_signal(_auth_bg_node.banner_a_warp_tr.x)
		_ban_a_warp_spins[3].set_value_no_signal(_auth_bg_node.banner_a_warp_tr.y)
		_ban_a_warp_spins[4].set_value_no_signal(_auth_bg_node.banner_a_warp_bl.x)
		_ban_a_warp_spins[5].set_value_no_signal(_auth_bg_node.banner_a_warp_bl.y)
		_ban_a_warp_spins[6].set_value_no_signal(_auth_bg_node.banner_a_warp_br.x)
		_ban_a_warp_spins[7].set_value_no_signal(_auth_bg_node.banner_a_warp_br.y)
	if _ban_b_warp_spins.size() >= 8:
		_ban_b_warp_spins[0].set_value_no_signal(_auth_bg_node.banner_b_warp_tl.x)
		_ban_b_warp_spins[1].set_value_no_signal(_auth_bg_node.banner_b_warp_tl.y)
		_ban_b_warp_spins[2].set_value_no_signal(_auth_bg_node.banner_b_warp_tr.x)
		_ban_b_warp_spins[3].set_value_no_signal(_auth_bg_node.banner_b_warp_tr.y)
		_ban_b_warp_spins[4].set_value_no_signal(_auth_bg_node.banner_b_warp_bl.x)
		_ban_b_warp_spins[5].set_value_no_signal(_auth_bg_node.banner_b_warp_bl.y)
		_ban_b_warp_spins[6].set_value_no_signal(_auth_bg_node.banner_b_warp_br.x)
		_ban_b_warp_spins[7].set_value_no_signal(_auth_bg_node.banner_b_warp_br.y)
	if _ban_c_warp_spins.size() >= 8:
		_ban_c_warp_spins[0].set_value_no_signal(_auth_bg_node.banner_c_warp_tl.x)
		_ban_c_warp_spins[1].set_value_no_signal(_auth_bg_node.banner_c_warp_tl.y)
		_ban_c_warp_spins[2].set_value_no_signal(_auth_bg_node.banner_c_warp_tr.x)
		_ban_c_warp_spins[3].set_value_no_signal(_auth_bg_node.banner_c_warp_tr.y)
		_ban_c_warp_spins[4].set_value_no_signal(_auth_bg_node.banner_c_warp_bl.x)
		_ban_c_warp_spins[5].set_value_no_signal(_auth_bg_node.banner_c_warp_bl.y)
		_ban_c_warp_spins[6].set_value_no_signal(_auth_bg_node.banner_c_warp_br.x)
		_ban_c_warp_spins[7].set_value_no_signal(_auth_bg_node.banner_c_warp_br.y)

func _update_banner_sel_ui() -> void:
	if _banner_sel_status_label == null:
		return
	match _banner_selection:
		BannerSelection.BANNER_A:
			_banner_sel_status_label.text = "Active Banner: BANNER A (TL/TR/BL/BR active)"
			_banner_sel_status_label.modulate = Color(0.3, 0.9, 1.0, 1.0)
		BannerSelection.BANNER_B:
			_banner_sel_status_label.text = "Active Banner: BANNER B (TL/TR/BL/BR active)"
			_banner_sel_status_label.modulate = Color(1.0, 0.85, 0.3, 1.0)
		BannerSelection.BANNER_C:
			_banner_sel_status_label.text = "Active Banner: BANNER C (TL/TR/BL/BR active)"
			_banner_sel_status_label.modulate = Color(0.85, 0.45, 1.0, 1.0)
		_:
			_banner_sel_status_label.text = "Active Banner: NONE (Click canvas or button below)"
			_banner_sel_status_label.modulate = Color(0.75, 0.85, 0.95, 1.0)

# Accessors for testing & verification
func get_banner_a_warp_spins() -> Array[SpinBox]:
	if _ban_a_warp_spins.is_empty() and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _ban_a_warp_spins

func get_banner_b_warp_spins() -> Array[SpinBox]:
	if _ban_b_warp_spins.is_empty() and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _ban_b_warp_spins

func get_banner_c_warp_spins() -> Array[SpinBox]:
	if _ban_c_warp_spins.is_empty() and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _ban_c_warp_spins

func get_all_warp_spins() -> Array[SpinBox]:
	if _ban_a_warp_spins.is_empty() or _ban_b_warp_spins.is_empty():
		if _ctrl_panel == null:
			_build_ui_hierarchy()
	var res: Array[SpinBox] = []
	res.append_array(_ban_a_warp_spins)
	res.append_array(_ban_b_warp_spins)
	return res

func get_all_warp_spins_with_c() -> Array[SpinBox]:
	if _ban_a_warp_spins.is_empty() or _ban_b_warp_spins.is_empty() or _ban_c_warp_spins.is_empty():
		if _ctrl_panel == null:
			_build_ui_hierarchy()
	var res: Array[SpinBox] = []
	res.append_array(_ban_a_warp_spins)
	res.append_array(_ban_b_warp_spins)
	res.append_array(_ban_c_warp_spins)
	return res

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

# ==============================================================================
# Preset Persistence & Session State Methods
# ==============================================================================

func get_preset_dir() -> String:
	return preset_directory

func set_preset_dir(dir_path: String) -> void:
	preset_directory = dir_path
	_refresh_preset_dropdown()

func _should_autoload_session() -> bool:
	if not auto_load_on_startup:
		return false
	var args := OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i] == "-s" and i + 1 < args.size() and args[i + 1].contains("tests/"):
			if not args.has("--visual-lab") and preset_directory == "D:/Mathos_Visual_Presets/AuthBackground":
				return false
	return true

func save_preset(filename: String, is_backup: bool = false) -> bool:
	if _auth_bg_node == null:
		return false
	if not DirAccess.dir_exists_absolute(preset_directory):
		var err := DirAccess.make_dir_recursive_absolute(preset_directory)
		if err != OK:
			push_warning("Failed to create preset directory: %s" % preset_directory)
			return false
	var file_path := preset_directory.path_join(filename)
	var data: Dictionary = _auth_bg_node.to_preset_dict()
	var json_str := JSON.stringify(data, "\t")
	var f := FileAccess.open(file_path, FileAccess.WRITE)
	if f == null:
		push_warning("Failed to open file for writing: %s (Error: %s)" % [file_path, FileAccess.get_open_error()])
		return false
	f.store_string(json_str)
	f.close()
	if not is_backup:
		_refresh_preset_dropdown()
	return true

func save_current() -> bool:
	if _auth_bg_node == null:
		return false
	_create_backup_before_overwrite()
	var ok := save_preset("last_session.json", false)
	if ok and _preset_status_lbl != null:
		_preset_status_lbl.text = "Saved: last_session.json"
		_preset_status_lbl.modulate = Color(0.4, 0.9, 0.6, 1.0)
	return ok

func restore_last_session() -> bool:
	return load_preset("last_session.json")

func has_last_session() -> bool:
	var path := preset_directory.path_join("last_session.json")
	return FileAccess.file_exists(path)

func save_as_preset(custom_name: String) -> bool:
	var trimmed := custom_name.strip_edges()
	if trimmed.is_empty():
		return false
	var filename := trimmed if trimmed.ends_with(".json") else trimmed + ".json"
	return save_preset(filename, false)

func load_preset(filename: String) -> bool:
	if _auth_bg_node == null:
		return false
	var file_path := preset_directory.path_join(filename)
	if not FileAccess.file_exists(file_path):
		return false
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return false
	var content := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(content)
	if not (parsed is Dictionary):
		return false
	var ok: bool = _auth_bg_node.apply_preset_dict(parsed as Dictionary)
	if ok:
		_sync_all_auth_controls_from_bg()
		if _preset_status_lbl != null:
			_preset_status_lbl.text = "Loaded: %s" % filename
			_preset_status_lbl.modulate = Color(0.4, 0.9, 0.6, 1.0)
	return ok

func _create_backup_before_overwrite() -> void:
	var last_session_path := preset_directory.path_join("last_session.json")
	if not FileAccess.file_exists(last_session_path):
		return
	var f := FileAccess.open(last_session_path, FileAccess.READ)
	if f == null:
		return
	var old_content := f.get_as_text()
	f.close()
	if old_content.strip_edges().is_empty():
		return

	var dt := Time.get_datetime_dict_from_system()
	var base_name := "auth_bg_%04d-%02d-%02d_%02d%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"]]
	var backup_filename := base_name + ".json"
	var backup_path := preset_directory.path_join(backup_filename)

	if FileAccess.file_exists(backup_path):
		base_name = "auth_bg_%04d-%02d-%02d_%02d%02d%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"], dt["second"]]
		backup_filename = base_name + ".json"
		backup_path = preset_directory.path_join(backup_filename)

	var bf := FileAccess.open(backup_path, FileAccess.WRITE)
	if bf != null:
		bf.store_string(old_content)
		bf.close()

	_prune_old_backups(15)

func _prune_old_backups(max_keep: int = 15) -> void:
	if not DirAccess.dir_exists_absolute(preset_directory):
		return
	var dir := DirAccess.open(preset_directory)
	if dir == null:
		return
	var backups: Array[String] = []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.begins_with("auth_bg_") and f.ends_with(".json"):
			backups.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	backups.sort()
	while backups.size() > max_keep:
		var oldest := backups[0]
		dir.remove(oldest)
		backups.remove_at(0)

func get_available_presets() -> Array[String]:
	var list: Array[String] = []
	if not DirAccess.dir_exists_absolute(preset_directory):
		return list
	var dir := DirAccess.open(preset_directory)
	if dir != null:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if not dir.current_is_dir() and f.ends_with(".json"):
				list.append(f)
			f = dir.get_next()
		dir.list_dir_end()
	list.sort()
	return list

func _refresh_preset_dropdown() -> void:
	if _preset_dropdown == null:
		return
	_preset_dropdown.clear()
	var list := get_available_presets()
	for i in range(list.size()):
		_preset_dropdown.add_item(list[i], i)

func schedule_autosave() -> void:
	if not _autosave_enabled:
		return
	_autosave_pending = true
	_autosave_timer = AUTOSAVE_DELAY

func cancel_autosave() -> void:
	_autosave_pending = false
	_autosave_timer = 0.0

func is_autosave_pending() -> bool:
	return _autosave_pending

func set_autosave_enabled(en: bool) -> void:
	_autosave_enabled = en
	if not en:
		cancel_autosave()

func is_autosave_enabled() -> bool:
	return _autosave_enabled

func add_light_spot(pos: Vector2 = Vector2.ZERO, radius: float = 140.0, intensity: float = 1.0, color: Color = Color(0.25, 0.75, 1.0, 1.0), softness: float = 0.8) -> int:
	if _auth_bg_node == null:
		return -1
	var idx: int = _auth_bg_node.add_light_spot(pos, radius, intensity, color, softness)
	select_light(idx)
	schedule_autosave()
	return idx

func get_light_list_container() -> Control:
	if _light_list_container == null and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _light_list_container

func get_save_current_button() -> Button:
	if _save_current_btn == null and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _save_current_btn

func get_restore_session_button() -> Button:
	if _restore_session_btn == null and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _restore_session_btn

func get_save_as_button() -> Button:
	if _save_as_btn == null and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _save_as_btn

func get_load_preset_button() -> Button:
	if _load_preset_btn == null and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _load_preset_btn

func get_autosave_checkbox() -> CheckBox:
	if _autosave_chk == null and _ctrl_panel == null:
		_build_ui_hierarchy()
	return _autosave_chk

func _sync_all_auth_controls_from_bg() -> void:
	if _auth_bg_node == null:
		return
	_sync_spinboxes_from_bg()
	if _afog_op_slider != null:
		_afog_op_slider.set_value_no_signal(_auth_bg_node.fog_master_opacity)
	if _afog_bright_slider != null:
		_afog_bright_slider.set_value_no_signal(_auth_bg_node.fog_brightness)
	if _afog_sat_slider != null:
		_afog_sat_slider.set_value_no_signal(_auth_bg_node.fog_saturation)
	if _afog_cnt_spin != null:
		_afog_cnt_spin.set_value_no_signal(_auth_bg_node.fog_cluster_count)
	if _ban_a_bright_slider != null:
		_ban_a_bright_slider.set_value_no_signal(_auth_bg_node.banner_a_brightness)
	if _ban_b_bright_slider != null:
		_ban_b_bright_slider.set_value_no_signal(_auth_bg_node.banner_b_brightness)
	if _ban_c_bright_slider != null:
		_ban_c_bright_slider.set_value_no_signal(_auth_bg_node.banner_c_brightness)
	if _dust_chk != null:
		_dust_chk.set_pressed_no_signal(_auth_bg_node.dust_enabled)
	if _dust_cnt_spin != null:
		_dust_cnt_spin.set_value_no_signal(_auth_bg_node.dust_count)
	if _part_type_opt != null:
		for i in range(_part_type_opt.item_count):
			if _part_type_opt.get_item_text(i) == _auth_bg_node.particle_type:
				_part_type_opt.select(i)
				break
	_update_light_ui()
	if _banner_warp_overlay != null:
		_banner_warp_overlay.queue_redraw()

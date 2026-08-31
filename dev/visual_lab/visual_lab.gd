class_name VisualLab
extends Control

## Developer & QA Visual Asset Lab for Mathos Engine.
## Provides isolated diagnosis of visual presentation, fog overlays, frame inspection,
## side-by-side frame comparison, and motion test modes without mutating save/gameplay data.

enum LabMode { FOG_TEST, FUTURE_TAB_2, FUTURE_TAB_3 }
enum MotionMode { CURRENT_ATLAS_ANIMATION, STATIC_FRAME }

const D1_BG_PATH: String = "res://assets/backgrounds/dungeon_1/d1_misty_forest_bg.png"
const D1_FOG_PATH: String = "res://assets/backgrounds/dungeon_1/d1_misty_forest_fog_8f.png"
const FOG_FRAME_WIDTH: int = 512
const FOG_FRAME_HEIGHT: int = 288
const FOG_ROWS: int = 2
const FOG_COLS: int = 4

# Production Default Parameters
const DEFAULT_FPS: float = 2.0
const DEFAULT_OPACITY: float = 2.2
const DEFAULT_MODULATE_R: float = 1.15
const DEFAULT_MODULATE_G: float = 1.25
const DEFAULT_MODULATE_B: float = 1.35

# Scene Nodes
var _bg_texture_rect: TextureRect = null
var _fog_texture_rect: TextureRect = null
var _compare_container: HBoxContainer = null
var _compare_rect_a: TextureRect = null
var _compare_rect_b: TextureRect = null
var _compare_label_a: Label = null
var _compare_label_b: Label = null
var _diag_label: Label = null

# Controls
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
var _reset_btn: Button = null
var _motion_option: OptionButton = null

# State
var _current_lab_mode: LabMode = LabMode.FOG_TEST
var _current_motion_mode: MotionMode = MotionMode.CURRENT_ATLAS_ANIMATION
var _is_playing: bool = true
var _fog_frames: Array[AtlasTexture] = []
var _fog_source_texture: Texture2D = null
var _fog_current_frame: int = 0
var _fog_frame_timer: float = 0.0
var _fps: float = DEFAULT_FPS
var _opacity: float = DEFAULT_OPACITY
var _mod_r: float = DEFAULT_MODULATE_R
var _mod_g: float = DEFAULT_MODULATE_G
var _mod_b: float = DEFAULT_MODULATE_B
var _bg_visible: bool = true
var _fog_visible: bool = true
var _compare_mode: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_init_fog_frames()
	_build_ui_hierarchy()
	_apply_parameters()
	_update_diagnostic_display()

func _init_fog_frames() -> void:
	if not _fog_frames.is_empty():
		return

	if FileAccess.file_exists(D1_FOG_PATH) or ResourceLoader.exists(D1_FOG_PATH):
		_fog_source_texture = load(D1_FOG_PATH) as Texture2D

	if _fog_source_texture == null:
		push_error("VisualLab: Failed to load fog texture from '%s'" % D1_FOG_PATH)
		return

	_fog_frames.clear()
	for row in range(FOG_ROWS):
		for col in range(FOG_COLS):
			var atlas_tex: AtlasTexture = AtlasTexture.new()
			atlas_tex.atlas = _fog_source_texture
			atlas_tex.region = Rect2(float(col * FOG_FRAME_WIDTH), float(row * FOG_FRAME_HEIGHT), float(FOG_FRAME_WIDTH), float(FOG_FRAME_HEIGHT))
			_fog_frames.append(atlas_tex)

func _process(delta: float) -> void:
	if _current_lab_mode != LabMode.FOG_TEST:
		return

	if _is_playing and _current_motion_mode == MotionMode.CURRENT_ATLAS_ANIMATION and not _fog_frames.is_empty() and _fps > 0.0:
		_fog_frame_timer += delta
		var frame_dur: float = 1.0 / _fps
		if _fog_frame_timer >= frame_dur:
			_fog_frame_timer = fmod(_fog_frame_timer, frame_dur)
			_fog_current_frame = (_fog_current_frame + 1) % _fog_frames.size()
			_update_frame_display()

	_update_diagnostic_display()

func _build_ui_hierarchy() -> void:
	# 1. Background Texture Rect
	_bg_texture_rect = TextureRect.new()
	_bg_texture_rect.name = "BackgroundTextureRect"
	_bg_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if FileAccess.file_exists(D1_BG_PATH) or ResourceLoader.exists(D1_BG_PATH):
		_bg_texture_rect.texture = load(D1_BG_PATH) as Texture2D
	add_child(_bg_texture_rect)

	# 2. Fog Overlay Texture Rect
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

	# 3. Compare Container (Side-by-side view)
	_compare_container = HBoxContainer.new()
	_compare_container.name = "CompareContainer"
	_compare_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_compare_container.visible = false

	var box_a: VBoxContainer = VBoxContainer.new()
	box_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compare_label_a = Label.new()
	_compare_label_a.text = "FRAME N"
	_compare_label_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compare_rect_a = TextureRect.new()
	_compare_rect_a.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_compare_rect_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_compare_rect_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box_a.add_child(_compare_label_a)
	box_a.add_child(_compare_rect_a)

	var box_b: VBoxContainer = VBoxContainer.new()
	box_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compare_label_b = Label.new()
	_compare_label_b.text = "FRAME N+1"
	_compare_label_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compare_rect_b = TextureRect.new()
	_compare_rect_b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_compare_rect_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_compare_rect_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box_b.add_child(_compare_label_b)
	box_b.add_child(_compare_rect_b)

	_compare_container.add_child(box_a)
	_compare_container.add_child(box_b)
	add_child(_compare_container)

	# 4. Top Header & Mode Tabs
	var top_bar: PanelContainer = PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 40.0
	var top_box: HBoxContainer = HBoxContainer.new()

	var title_lbl: Label = Label.new()
	title_lbl.text = " 🔬 MATHOS VISUAL LAB "
	top_box.add_child(title_lbl)

	var tab_fog: Button = Button.new()
	tab_fog.text = "FOG TEST"
	tab_fog.pressed.connect(func(): set_lab_mode(LabMode.FOG_TEST))
	top_box.add_child(tab_fog)

	var tab_karl: Button = Button.new()
	tab_karl.text = "(Future: Karl)"
	tab_karl.disabled = true
	top_box.add_child(tab_karl)

	var tab_part: Button = Button.new()
	tab_part.text = "(Future: Particles)"
	tab_part.disabled = true
	top_box.add_child(tab_part)

	top_bar.add_child(top_box)
	add_child(top_bar)

	# 5. Developer Control Dock (Left Floating Panel)
	var ctrl_panel: PanelContainer = PanelContainer.new()
	ctrl_panel.name = "ControlDock"
	ctrl_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	ctrl_panel.offset_top = 48.0
	ctrl_panel.offset_right = 320.0
	ctrl_panel.offset_bottom = -16.0

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hdr_ctrl: Label = Label.new()
	hdr_ctrl.text = "=== FOG CONTROLS ==="
	vbox.add_child(hdr_ctrl)

	# Play / Pause & Frame Stepping
	var play_box: HBoxContainer = HBoxContainer.new()
	_play_pause_btn = Button.new()
	_play_pause_btn.text = "Pause"
	_play_pause_btn.pressed.connect(_on_play_pause_pressed)
	play_box.add_child(_play_pause_btn)

	_prev_frame_btn = Button.new()
	_prev_frame_btn.text = "< Prev"
	_prev_frame_btn.pressed.connect(step_previous_frame)
	play_box.add_child(_prev_frame_btn)

	_next_frame_btn = Button.new()
	_next_frame_btn.text = "Next >"
	_next_frame_btn.pressed.connect(step_next_frame)
	play_box.add_child(_next_frame_btn)
	vbox.add_child(play_box)

	# Frame Selector SpinBox
	var frame_box: HBoxContainer = HBoxContainer.new()
	var frame_lbl: Label = Label.new()
	frame_lbl.text = "Frame (0..7):"
	_frame_spinbox = SpinBox.new()
	_frame_spinbox.min_value = 0
	_frame_spinbox.max_value = 7
	_frame_spinbox.step = 1
	_frame_spinbox.value = 0
	_frame_spinbox.value_changed.connect(_on_frame_spinbox_changed)
	frame_box.add_child(frame_lbl)
	frame_box.add_child(_frame_spinbox)
	vbox.add_child(frame_box)

	# Motion Mode Option
	var motion_lbl: Label = Label.new()
	motion_lbl.text = "Motion Mode:"
	_motion_option = OptionButton.new()
	_motion_option.add_item("CURRENT_ATLAS_ANIMATION", MotionMode.CURRENT_ATLAS_ANIMATION)
	_motion_option.add_item("STATIC_FRAME", MotionMode.STATIC_FRAME)
	_motion_option.item_selected.connect(_on_motion_mode_selected)
	vbox.add_child(motion_lbl)
	vbox.add_child(_motion_option)

	# FPS Control
	var fps_lbl: Label = Label.new()
	fps_lbl.text = "FPS (0.5 -> 15):"
	var fps_box: HBoxContainer = HBoxContainer.new()
	_fps_slider = HSlider.new()
	_fps_slider.min_value = 0.5
	_fps_slider.max_value = 15.0
	_fps_slider.step = 0.5
	_fps_slider.value = DEFAULT_FPS
	_fps_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fps_spinbox = SpinBox.new()
	_fps_spinbox.min_value = 0.5
	_fps_spinbox.max_value = 15.0
	_fps_spinbox.step = 0.5
	_fps_spinbox.value = DEFAULT_FPS
	_fps_slider.value_changed.connect(func(v): set_fps(v))
	_fps_spinbox.value_changed.connect(func(v): set_fps(v))
	fps_box.add_child(_fps_slider)
	fps_box.add_child(_fps_spinbox)
	vbox.add_child(fps_lbl)
	vbox.add_child(fps_box)

	# Opacity Control
	var op_lbl: Label = Label.new()
	op_lbl.text = "Opacity / Alpha (0 -> 2.5):"
	var op_box: HBoxContainer = HBoxContainer.new()
	_opacity_slider = HSlider.new()
	_opacity_slider.min_value = 0.0
	_opacity_slider.max_value = 2.5
	_opacity_slider.step = 0.1
	_opacity_slider.value = DEFAULT_OPACITY
	_opacity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opacity_spinbox = SpinBox.new()
	_opacity_spinbox.min_value = 0.0
	_opacity_spinbox.max_value = 2.5
	_opacity_spinbox.step = 0.1
	_opacity_spinbox.value = DEFAULT_OPACITY
	_opacity_slider.value_changed.connect(func(v): set_opacity(v))
	_opacity_spinbox.value_changed.connect(func(v): set_opacity(v))
	op_box.add_child(_opacity_slider)
	op_box.add_child(_opacity_spinbox)
	vbox.add_child(op_lbl)
	vbox.add_child(op_box)

	# RGB Modulate Controls
	var rgb_lbl: Label = Label.new()
	rgb_lbl.text = "Fog Modulate RGB:"
	vbox.add_child(rgb_lbl)

	# R
	var r_box: HBoxContainer = HBoxContainer.new()
	var r_l: Label = Label.new(); r_l.text = "R:"
	_r_slider = HSlider.new(); _r_slider.min_value = 0.0; _r_slider.max_value = 3.0; _r_slider.step = 0.05; _r_slider.value = DEFAULT_MODULATE_R
	_r_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_r_slider.value_changed.connect(func(v): _mod_r = v; _apply_parameters())
	r_box.add_child(r_l); r_box.add_child(_r_slider)
	vbox.add_child(r_box)

	# G
	var g_box: HBoxContainer = HBoxContainer.new()
	var g_l: Label = Label.new(); g_l.text = "G:"
	_g_slider = HSlider.new(); _g_slider.min_value = 0.0; _g_slider.max_value = 3.0; _g_slider.step = 0.05; _g_slider.value = DEFAULT_MODULATE_G
	_g_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_g_slider.value_changed.connect(func(v): _mod_g = v; _apply_parameters())
	g_box.add_child(g_l); g_box.add_child(_g_slider)
	vbox.add_child(g_box)

	# B
	var b_box: HBoxContainer = HBoxContainer.new()
	var b_l: Label = Label.new(); b_l.text = "B:"
	_b_slider = HSlider.new(); _b_slider.min_value = 0.0; _b_slider.max_value = 3.0; _b_slider.step = 0.05; _b_slider.value = DEFAULT_MODULATE_B
	_b_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_b_slider.value_changed.connect(func(v): _mod_b = v; _apply_parameters())
	b_box.add_child(b_l); b_box.add_child(_b_slider)
	vbox.add_child(b_box)

	# Toggles
	_bg_toggle = CheckBox.new()
	_bg_toggle.text = "Background"
	_bg_toggle.button_pressed = true
	_bg_toggle.toggled.connect(func(t): set_background_visible(t))
	vbox.add_child(_bg_toggle)

	_fog_toggle = CheckBox.new()
	_fog_toggle.text = "Fog"
	_fog_toggle.button_pressed = true
	_fog_toggle.toggled.connect(func(t): set_fog_visible(t))
	vbox.add_child(_fog_toggle)

	_compare_toggle = CheckBox.new()
	_compare_toggle.text = "Compare Frames (Side-by-Side)"
	_compare_toggle.button_pressed = false
	_compare_toggle.toggled.connect(func(t): set_compare_mode(t))
	vbox.add_child(_compare_toggle)

	# Reset Button
	_reset_btn = Button.new()
	_reset_btn.text = "[ Reset Defaults ]"
	_reset_btn.pressed.connect(reset_defaults)
	vbox.add_child(_reset_btn)

	scroll.add_child(vbox)
	ctrl_panel.add_child(scroll)
	add_child(ctrl_panel)

	# 6. Diagnostic Label Overlay (Right Floating Panel)
	var diag_panel: PanelContainer = PanelContainer.new()
	diag_panel.name = "DiagPanel"
	diag_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	diag_panel.offset_left = -340.0
	diag_panel.offset_top = 48.0
	diag_panel.offset_right = -16.0

	_diag_label = Label.new()
	_diag_label.text = "FOG DIAGNOSTICS"
	diag_panel.add_child(_diag_label)
	add_child(diag_panel)

func _apply_parameters() -> void:
	if _bg_texture_rect != null:
		_bg_texture_rect.visible = _bg_visible

	if _fog_texture_rect != null:
		_fog_texture_rect.visible = _fog_visible
		_fog_texture_rect.modulate = Color(_mod_r, _mod_g, _mod_b, _opacity)

	_update_frame_display()

func _update_frame_display() -> void:
	if _fog_frames.is_empty():
		return

	_fog_current_frame = clampi(_fog_current_frame, 0, _fog_frames.size() - 1)

	if _fog_texture_rect != null:
		_fog_texture_rect.texture = _fog_frames[_fog_current_frame]

	if _frame_spinbox != null and int(_frame_spinbox.value) != _fog_current_frame:
		_frame_spinbox.set_value_no_signal(_fog_current_frame)

	if _compare_mode:
		var next_idx: int = (_fog_current_frame + 1) % _fog_frames.size()
		if _compare_rect_a != null:
			_compare_rect_a.texture = _fog_frames[_fog_current_frame]
			_compare_rect_a.modulate = Color(_mod_r, _mod_g, _mod_b, _opacity)
		if _compare_rect_b != null:
			_compare_rect_b.texture = _fog_frames[next_idx]
			_compare_rect_b.modulate = Color(_mod_r, _mod_g, _mod_b, _opacity)
		if _compare_label_a != null:
			_compare_label_a.text = "FRAME %d / 7" % _fog_current_frame
		if _compare_label_b != null:
			_compare_label_b.text = "FRAME %d / 7" % next_idx

func _update_diagnostic_display() -> void:
	if _diag_label == null:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var disp_rect: Rect2 = _fog_texture_rect.get_global_rect() if _fog_texture_rect != null else Rect2()
	var region_rect: Rect2 = _fog_frames[_fog_current_frame].region if not _fog_frames.is_empty() and _fog_current_frame < _fog_frames.size() else Rect2()

	var lines: Array[String] = [
		"FOG SOURCE:",
		"  d1_misty_forest_fog_8f.png",
		"SHEET: 2048x576",
		"GRID: 4x2",
		"FRAME: 512x288",
		"ATLAS REGION: [P: (%.0f, %.0f), S: (%.0f, %.0f)]" % [region_rect.position.x, region_rect.position.y, region_rect.size.x, region_rect.size.y],
		"DISPLAY: %.0fx%.0f" % [disp_rect.size.x, disp_rect.size.y],
		"VIEWPORT: %.0fx%.0f" % [vp_size.x, vp_size.y],
		"FRAME INDEX: %d / 7" % _fog_current_frame,
		"FPS: %.1f" % _fps,
		"OPACITY: %.2f" % _opacity,
		"MODULATE RGB: (%.2f, %.2f, %.2f)" % [_mod_r, _mod_g, _mod_b],
		"PLAYING: %s" % str(_is_playing),
		"MOTION MODE: %s" % ("CURRENT_ATLAS_ANIMATION" if _current_motion_mode == MotionMode.CURRENT_ATLAS_ANIMATION else "STATIC_FRAME"),
		"COMPARE MODE: %s" % str(_compare_mode),
		"VISIBLE: %s" % str(_fog_visible and (_fog_texture_rect != null and _fog_texture_rect.visible))
	]

	_diag_label.text = "\n".join(lines)

# Control Actions
func _on_play_pause_pressed() -> void:
	set_playing(not _is_playing)

func set_playing(play: bool) -> void:
	_is_playing = play
	if _play_pause_btn != null:
		_play_pause_btn.text = "Pause" if _is_playing else "Play"

func step_next_frame() -> void:
	_init_fog_frames()
	if _fog_frames.is_empty():
		return
	_fog_current_frame = (_fog_current_frame + 1) % _fog_frames.size()
	_update_frame_display()

func step_previous_frame() -> void:
	_init_fog_frames()
	if _fog_frames.is_empty():
		return
	_fog_current_frame = (_fog_current_frame - 1 + _fog_frames.size()) % _fog_frames.size()
	_update_frame_display()

func set_frame_index(idx: int) -> void:
	_init_fog_frames()
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
	if _fps_slider != null and not is_equal_approx(_fps_slider.value, _fps):
		_fps_slider.set_value_no_signal(_fps)
	if _fps_spinbox != null and not is_equal_approx(_fps_spinbox.value, _fps):
		_fps_spinbox.set_value_no_signal(_fps)

func set_opacity(val: float) -> void:
	_opacity = clampf(val, 0.0, 2.5)
	if _opacity_slider != null and not is_equal_approx(_opacity_slider.value, _opacity):
		_opacity_slider.set_value_no_signal(_opacity)
	if _opacity_spinbox != null and not is_equal_approx(_opacity_spinbox.value, _opacity):
		_opacity_spinbox.set_value_no_signal(_opacity)
	_apply_parameters()

func set_background_visible(vis: bool) -> void:
	_bg_visible = vis
	if _bg_toggle != null and _bg_toggle.button_pressed != _bg_visible:
		_bg_toggle.set_pressed_no_signal(_bg_visible)
	if _bg_texture_rect != null:
		_bg_texture_rect.visible = _bg_visible

func set_fog_visible(vis: bool) -> void:
	_fog_visible = vis
	if _fog_toggle != null and _fog_toggle.button_pressed != _fog_visible:
		_fog_toggle.set_pressed_no_signal(_fog_visible)
	if _fog_texture_rect != null:
		_fog_texture_rect.visible = _fog_visible

func set_compare_mode(enabled: bool) -> void:
	_compare_mode = enabled
	if _compare_toggle != null and _compare_toggle.button_pressed != _compare_mode:
		_compare_toggle.set_pressed_no_signal(_compare_mode)
	if _compare_container != null:
		_compare_container.visible = _compare_mode
	if _fog_texture_rect != null:
		_fog_texture_rect.visible = _fog_visible and not _compare_mode
	_update_frame_display()

func set_lab_mode(mode: LabMode) -> void:
	_current_lab_mode = mode

func reset_defaults() -> void:
	_is_playing = true
	_fog_current_frame = 0
	_fog_frame_timer = 0.0
	_fps = DEFAULT_FPS
	_opacity = DEFAULT_OPACITY
	_mod_r = DEFAULT_MODULATE_R
	_mod_g = DEFAULT_MODULATE_G
	_mod_b = DEFAULT_MODULATE_B
	_bg_visible = true
	_fog_visible = true
	_compare_mode = false
	_current_motion_mode = MotionMode.CURRENT_ATLAS_ANIMATION

	if _play_pause_btn != null: _play_pause_btn.text = "Pause"
	if _fps_slider != null: _fps_slider.value = DEFAULT_FPS
	if _fps_spinbox != null: _fps_spinbox.value = DEFAULT_FPS
	if _opacity_slider != null: _opacity_slider.value = DEFAULT_OPACITY
	if _opacity_spinbox != null: _opacity_spinbox.value = DEFAULT_OPACITY
	if _r_slider != null: _r_slider.value = DEFAULT_MODULATE_R
	if _g_slider != null: _g_slider.value = DEFAULT_MODULATE_G
	if _b_slider != null: _b_slider.value = DEFAULT_MODULATE_B
	if _bg_toggle != null: _bg_toggle.button_pressed = true
	if _fog_toggle != null: _fog_toggle.button_pressed = true
	if _compare_toggle != null: _compare_toggle.button_pressed = false
	if _motion_option != null: _motion_option.select(0)

	_apply_parameters()

# Accessors for testing & verification
func get_fog_frames() -> Array[AtlasTexture]:
	_init_fog_frames()
	return _fog_frames

func get_current_frame_index() -> int:
	return _fog_current_frame

func is_playing() -> bool:
	return _is_playing

func get_fps() -> float:
	return _fps

func get_opacity() -> float:
	return _opacity

func is_compare_mode() -> bool:
	return _compare_mode

func get_motion_mode() -> MotionMode:
	return _current_motion_mode

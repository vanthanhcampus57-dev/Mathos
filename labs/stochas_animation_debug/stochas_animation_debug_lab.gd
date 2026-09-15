extends Control

## ==============================================================================
## STOCHAS ANIMATION DEBUG & INSPECTION LAB
## TASK_ID: MATHOS-STOCHAS-ULTIMATE-CHARGE-FINAL-INTEGRATE-239L
##
## Dedicated diagnostic studio for inspecting, timing, and refining STOCHAS
## boss animation states, distinct spell profiles, speed scaling, and the
## human-approved 6-frame Ultimate Charge sequence (F01 - F06).
## ==============================================================================

# Assets
const ASSET_STOCHAS_BOSS: String = "res://assets/characters/bosses/dungeon_1/stochas_boss.png"
const ASSET_STOCHAS_ULTIMATE_SEQUENCE: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_sequence.png"

# WAD2 Human-Approved Final Ultimate Charge Frames (6 Independent Textures)
const ASSET_STOCHAS_ULTIMATE_CHARGE_F01: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f01.png"
const ASSET_STOCHAS_ULTIMATE_CHARGE_F02: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f02.png"
const ASSET_STOCHAS_ULTIMATE_CHARGE_F03: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f03.png"
const ASSET_STOCHAS_ULTIMATE_CHARGE_F04: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f04.png"
const ASSET_STOCHAS_ULTIMATE_CHARGE_F05: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f05.png"
const ASSET_STOCHAS_ULTIMATE_CHARGE_F06: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f06.png"

const ASSET_VFX_BOLT: String = "res://assets/vfx/combat/stochas_arcane_bolt.png"
const ASSET_VFX_ORB: String = "res://assets/vfx/combat/stochas_probability_orb.png"
const ASSET_VFX_RIFT: String = "res://assets/vfx/combat/stochas_void_rift.png"
const ASSET_VFX_SWEEP: String = "res://assets/vfx/combat/stochas_arcane_sweep.png"
const ASSET_BG: String = "res://assets/ui/combat/boss_combat_bg_placeholder.png"

# Geometry & Layout (1280 x 720)
const BOSS_BASE_POS: Vector2 = Vector2(180.0, 50.0)
const BOSS_BASE_SIZE: Vector2 = Vector2(520.0, 560.0)
const BASELINE_Y: float = 610.0 # 50.0 + 560.0 = 610.0

# WAD2 ULTIMATE_CHARGE Presentation Normalization (Task 239N)
# Canonical IDLE visible height in 512 canvas = 512px. F01..F06 visible height = 450px.
# Scaling factor S = 512 / 450 = 1.137778 (~1.1378).
# Bottom Y = 488 (24px above canvas bottom). Position Y = BOSS_BASE_POS.y - 8.09 = 41.91.
const CHARGE_BASE_POS: Vector2 = Vector2(180.0, 41.91)
const CHARGE_BASE_SCALE: Vector2 = Vector2(1.1378, 1.1378)

# Thresholded Alpha Bounding Boxes (in 512x512 texture space)
const FRAME_ALPHA_BBOXES: Dictionary = {
	-1: Rect2(58.0, 3.0, 449.0, 509.0), # Canonical IDLE boss
	0: Rect2(67.0, 38.0, 377.0, 450.0), # F01
	1: Rect2(63.0, 24.0, 385.0, 464.0), # F02
	2: Rect2(75.0, 25.0, 362.0, 463.0), # F03
	3: Rect2(51.0, 26.0, 408.0, 461.0), # F04
	4: Rect2(44.0, 26.0, 418.0, 461.0), # F05
	5: Rect2(36.0, 28.0, 435.0, 459.0), # F06
}

# 11 Selectable Animation States
enum AnimationState {
	IDLE,
	CAST_BOLT,
	CAST_ORB,
	CAST_RIFT,
	CAST_SWEEP,
	HIT,
	STUN,
	ENRAGED,
	ULTIMATE_CHARGE,
	ULTIMATE_RELEASE,
	ULTIMATE_FULL
}

const STATE_NAMES: Dictionary = {
	AnimationState.IDLE: "IDLE",
	AnimationState.CAST_BOLT: "CAST_BOLT",
	AnimationState.CAST_ORB: "CAST_ORB",
	AnimationState.CAST_RIFT: "CAST_RIFT",
	AnimationState.CAST_SWEEP: "CAST_SWEEP",
	AnimationState.HIT: "HIT",
	AnimationState.STUN: "STUN",
	AnimationState.ENRAGED: "ENRAGED",
	AnimationState.ULTIMATE_CHARGE: "ULTIMATE_CHARGE",
	AnimationState.ULTIMATE_RELEASE: "ULTIMATE_RELEASE",
	AnimationState.ULTIMATE_FULL: "ULTIMATE_FULL"
}

# Distinct Spell Motion Profiles
const SPELL_PROFILES: Dictionary = {
	AnimationState.CAST_BOLT: {
		"name": "ARCANE_BOLT",
		"description": "Fast/snappy, backward anticipation, rapid forward snap, cyan projectile flare",
		"duration": 0.45,
		"anticipation_offset": Vector2(16.0, 0.0),
		"anticipation_rotation": -1.5,
		"anticipation_time": 0.12,
		"snap_offset": Vector2(-32.0, 0.0),
		"snap_rotation": 2.5,
		"snap_time": 0.15,
		"recoil_time": 0.18,
		"max_lateral_displacement": 48.0,
		"max_rotation_swing": 4.0,
		"vfx_type": "cyan_flare_projectile"
	},
	AnimationState.CAST_ORB: {
		"name": "PROBABILITY_ORB",
		"description": "Ritual/controlled, vertical float, scale expansion, circular orbiting orb VFX",
		"duration": 0.80,
		"float_offset": Vector2(0.0, -26.0),
		"float_rotation": -2.5,
		"float_time": 0.35,
		"peak_scale": Vector2(1.05, 1.05),
		"release_offset": Vector2(10.0, -10.0),
		"release_rotation": 0.0,
		"release_time": 0.25,
		"recoil_time": 0.20,
		"max_lateral_displacement": 10.0,
		"max_rotation_swing": 2.5,
		"vfx_type": "circular_orbiting_orb"
	},
	AnimationState.CAST_RIFT: {
		"name": "VOID_RIFT",
		"description": "Heavy summon/hold, lateral torso lean, downward sink, held pose while rift opens",
		"duration": 0.95,
		"sink_offset": Vector2(22.0, 20.0),
		"sink_rotation": 3.8,
		"windup_time": 0.30,
		"hold_duration": 0.40,
		"recoil_time": 0.25,
		"max_lateral_displacement": 22.0,
		"max_rotation_swing": 3.8,
		"vfx_type": "void_rift_portal"
	},
	AnimationState.CAST_SWEEP: {
		"name": "ARCANE_SWEEP",
		"description": "Wide/forceful, strong wind-up, massive lateral sweep, wide arc sweep VFX",
		"duration": 1.00,
		"windup_offset": Vector2(40.0, -5.0),
		"windup_rotation": -6.2,
		"windup_scale": Vector2(1.08, 0.96),
		"windup_time": 0.35,
		"sweep_offset": Vector2(-45.0, 5.0),
		"sweep_rotation": 5.5,
		"sweep_scale": Vector2(0.96, 1.04),
		"sweep_time": 0.35,
		"recoil_time": 0.30,
		"max_lateral_displacement": 85.0,
		"max_rotation_swing": 11.7,
		"vfx_type": "wide_arc_slash"
	}
}

# State Durations
const STATE_DURATIONS: Dictionary = {
	AnimationState.IDLE: 3.20,
	AnimationState.CAST_BOLT: 0.45,
	AnimationState.CAST_ORB: 0.80,
	AnimationState.CAST_RIFT: 0.95,
	AnimationState.CAST_SWEEP: 1.00,
	AnimationState.HIT: 0.35,
	AnimationState.STUN: 1.00,
	AnimationState.ENRAGED: 1.80,
	AnimationState.ULTIMATE_CHARGE: 1.20,
	AnimationState.ULTIMATE_RELEASE: 1.02, # 0.72s frames + 0.30s recovery
	AnimationState.ULTIMATE_FULL: 3.42 # 2.40s charge + 1.02s release/recovery
}

# Runtime Variables
var current_state: AnimationState = AnimationState.IDLE
var playback_speed: float = 1.0
var is_paused: bool = false
var is_loop_enabled: bool = false
var is_compare_casts_active: bool = false
var compare_step_idx: int = 0
var compare_timer: float = 0.0
var compare_sequence: Array[AnimationState] = [
	AnimationState.CAST_BOLT,
	AnimationState.CAST_ORB,
	AnimationState.CAST_RIFT,
	AnimationState.CAST_SWEEP
]

var current_atlas_frame: int = -1 # -1 = canonical boss / charge frame, 0..7 = release atlas frames
var current_charge_frame: int = -1 # -1 = canonical boss / atlas frame, 0..5 = F01..F06
var elapsed_time: float = 0.0
var state_duration: float = 3.20
var active_tween: Tween = null
var is_animating: bool = false

# Motion Path Overlay
var motion_path_enabled: bool = false
var motion_trail_points: Array[Vector2] = []
const MAX_MOTION_POINTS: int = 150

# Loaded Assets
var canonical_boss_tex: Texture2D = null
var stochas_ultimate_frames: Array[AtlasTexture] = []
var stochas_ultimate_charge_frames: Array[Texture2D] = []
var vfx_bolt_tex: Texture2D = null
var vfx_orb_tex: Texture2D = null
var vfx_rift_tex: Texture2D = null
var vfx_sweep_tex: Texture2D = null
var bg_tex: Texture2D = null

# Scene Node References
var bg_rect: TextureRect = null
var pedestal_panel: Panel = null
var baseline_marker: ColorRect = null
var boss_rect: TextureRect = null
var boss_vfx_container: Control = null
var stun_overlay: Control = null
var stun_stars: Array[Label] = []
var dim_overlay: ColorRect = null
var motion_path_line: Line2D = null

# UI Control Elements
var right_panel: PanelContainer = null
var state_buttons: Dictionary = {}
var speed_slider: HSlider = null
var speed_label: Label = null
var btn_pause: Button = null
var btn_loop: Button = null
var btn_compare: Button = null
var btn_motion_path: Button = null
var btn_prev_frame: Button = null
var btn_next_frame: Button = null
var btn_reset_baseline: Button = null

# Diagnostic Readout UI
var bottom_panel: PanelContainer = null
var lbl_diag_state: Label = null
var lbl_diag_details: Label = null

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_resources()
	_build_ui_environment()
	_build_boss_preview()
	_build_controls_ui()
	_build_diagnostic_ui()
	load_tuning_config()
	restore_canonical_baseline()
	_apply_initial_status_panel_state()
	play_animation(AnimationState.IDLE)

func _load_resources() -> void:
	if ResourceLoader.exists(ASSET_BG):
		bg_tex = load(ASSET_BG)
	if ResourceLoader.exists(ASSET_STOCHAS_BOSS):
		canonical_boss_tex = load(ASSET_STOCHAS_BOSS)
	if ResourceLoader.exists(ASSET_VFX_BOLT):
		vfx_bolt_tex = load(ASSET_VFX_BOLT)
	if ResourceLoader.exists(ASSET_VFX_ORB):
		vfx_orb_tex = load(ASSET_VFX_ORB)
	if ResourceLoader.exists(ASSET_VFX_RIFT):
		vfx_rift_tex = load(ASSET_VFX_RIFT)
	if ResourceLoader.exists(ASSET_VFX_SWEEP):
		vfx_sweep_tex = load(ASSET_VFX_SWEEP)

	# 1. Load 6 Independent WAD2 Ultimate Charge Textures (F01 - F06)
	stochas_ultimate_charge_frames.clear()
	var charge_paths: Array[String] = [
		ASSET_STOCHAS_ULTIMATE_CHARGE_F01,
		ASSET_STOCHAS_ULTIMATE_CHARGE_F02,
		ASSET_STOCHAS_ULTIMATE_CHARGE_F03,
		ASSET_STOCHAS_ULTIMATE_CHARGE_F04,
		ASSET_STOCHAS_ULTIMATE_CHARGE_F05,
		ASSET_STOCHAS_ULTIMATE_CHARGE_F06
	]
	for p in charge_paths:
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p) as Texture2D
			stochas_ultimate_charge_frames.append(tex)
		elif FileAccess.file_exists(p):
			var img: Image = Image.load_from_file(p)
			if img != null and not img.is_empty():
				var tex: ImageTexture = ImageTexture.create_from_image(img)
				stochas_ultimate_charge_frames.append(tex)

	# 2. Slice 8 frames of 384x384 Ultimate Release sequence
	stochas_ultimate_frames.clear()
	if ResourceLoader.exists(ASSET_STOCHAS_ULTIMATE_SEQUENCE):
		var full_seq = load(ASSET_STOCHAS_ULTIMATE_SEQUENCE)
		for i in range(8):
			var at = AtlasTexture.new()
			at.atlas = full_seq
			at.region = Rect2(i * 384.0, 0.0, 384.0, 384.0)
			stochas_ultimate_frames.append(at)

func _build_ui_environment() -> void:
	# Studio dark background
	var studio_bg = ColorRect.new()
	studio_bg.name = "StudioBackground"
	studio_bg.size = Vector2(1280, 720)
	studio_bg.color = Color(0.07, 0.07, 0.10, 1.0)
	add_child(studio_bg)

	if bg_tex != null:
		bg_rect = TextureRect.new()
		bg_rect.name = "CombatBGSubtle"
		bg_rect.texture = bg_tex
		bg_rect.size = Vector2(1280, 720)
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_rect.modulate = Color(0.35, 0.35, 0.45, 0.40) # Muted studio backdrop
		add_child(bg_rect)

	# Studio ground pedestal & baseline marker
	pedestal_panel = Panel.new()
	pedestal_panel.name = "StudioPedestal"
	pedestal_panel.position = Vector2(140.0, 600.0)
	pedestal_panel.size = Vector2(600.0, 18.0)
	var ped_style = StyleBoxFlat.new()
	ped_style.bg_color = Color(0.12, 0.14, 0.20, 0.90)
	ped_style.border_color = Color(0.30, 0.50, 0.85, 0.80)
	ped_style.border_width_top = 2
	ped_style.corner_radius_top_left = 6
	ped_style.corner_radius_top_right = 6
	pedestal_panel.add_theme_stylebox_override("panel", ped_style)
	add_child(pedestal_panel)

	# Baseline Y=610 marker
	baseline_marker = ColorRect.new()
	baseline_marker.name = "BaselineMarker"
	baseline_marker.position = Vector2(140.0, BASELINE_Y)
	baseline_marker.size = Vector2(600.0, 2.0)
	baseline_marker.color = Color(0.40, 0.80, 1.0, 0.70)
	add_child(baseline_marker)

	var baseline_lbl = Label.new()
	baseline_lbl.text = "GROUND BASELINE Y = 610.0"
	baseline_lbl.position = Vector2(145.0, BASELINE_Y + 4.0)
	baseline_lbl.add_theme_font_size_override("font_size", 10)
	baseline_lbl.modulate = Color(0.5, 0.8, 1.0, 0.8)
	add_child(baseline_lbl)

	# Dim overlay for Ultimate charge
	dim_overlay = ColorRect.new()
	dim_overlay.name = "UltimateDimOverlay"
	dim_overlay.size = Vector2(1280, 720)
	dim_overlay.color = Color(0.02, 0.02, 0.05, 1.0)
	dim_overlay.modulate.a = 0.0
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim_overlay)

	# Motion path line
	motion_path_line = Line2D.new()
	motion_path_line.name = "MotionPathLine"
	motion_path_line.width = 3.0
	motion_path_line.default_color = Color(0.2, 0.9, 1.0, 0.75)
	motion_path_line.visible = false
	add_child(motion_path_line)



func _build_boss_preview() -> void:
	# Ghost TextureRect for Previous-Frame Onion Skin Overlay (Task 239P)
	boss_ghost_rect = TextureRect.new()
	boss_ghost_rect.name = "StochasGhostBoss"
	boss_ghost_rect.position = BOSS_BASE_POS
	boss_ghost_rect.size = BOSS_BASE_SIZE
	boss_ghost_rect.custom_minimum_size = BOSS_BASE_SIZE
	boss_ghost_rect.pivot_offset = BOSS_BASE_SIZE * 0.5
	boss_ghost_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_ghost_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boss_ghost_rect.visible = false
	boss_ghost_rect.modulate = Color(0.7, 0.85, 1.0, 0.25)
	boss_ghost_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(boss_ghost_rect)

	boss_rect = TextureRect.new()
	boss_rect.name = "StochasPreviewBoss"
	boss_rect.position = BOSS_BASE_POS
	boss_rect.size = BOSS_BASE_SIZE
	boss_rect.custom_minimum_size = BOSS_BASE_SIZE
	boss_rect.pivot_offset = BOSS_BASE_SIZE * 0.5
	boss_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boss_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if canonical_boss_tex != null:
		boss_rect.texture = canonical_boss_tex
	add_child(boss_rect)

	# Interactive Transform Gizmo Control (Task 239R & 239R1)
	# Placed AFTER boss_rect so it sits on top in z-order and receives pointer events
	gizmo_overlay = Control.new()
	gizmo_overlay.name = "GizmoOverlay"
	gizmo_overlay.position = Vector2(0.0, 0.0)
	gizmo_overlay.size = Vector2(750.0, 620.0)
	gizmo_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	gizmo_overlay.draw.connect(Callable(self, "_on_draw_gizmo_overlay"))
	gizmo_overlay.gui_input.connect(Callable(self, "_on_gui_input_gizmo_overlay"))
	add_child(gizmo_overlay)

	# Boss VFX container attached to boss
	boss_vfx_container = Control.new()
	boss_vfx_container.name = "BossVFXContainer"
	boss_vfx_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_vfx_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_rect.add_child(boss_vfx_container)

	# Stun overlay (stars circling above head)
	stun_overlay = Control.new()
	stun_overlay.name = "StunOverlay"
	stun_overlay.position = Vector2(BOSS_BASE_SIZE.x * 0.5, 30.0)
	stun_overlay.visible = false
	boss_rect.add_child(stun_overlay)

	for i in range(3):
		var star = Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", 28)
		star.modulate = Color(1.0, 0.88, 0.25, 0.95)
		star.position = Vector2((i - 1) * 35.0 - 10.0, -15.0)
		stun_overlay.add_child(star)
		stun_stars.append(star)

func _build_controls_ui() -> void:
	right_panel = PanelContainer.new()
	right_panel.name = "ControlPanel"
	right_panel.position = Vector2(750.0, 15.0)
	right_panel.size = Vector2(510.0, 680.0)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.10, 0.14, 0.95)
	panel_style.border_color = Color(0.22, 0.28, 0.40, 0.90)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	right_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(right_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	right_panel.add_child(margin)

	var scroll = ScrollContainer.new()
	scroll.name = "RightPanelScroll"
	scroll.custom_minimum_size = Vector2(480, 655)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	# Header Title
	var title = Label.new()
	title.text = "STOCHAS ANIMATION STUDIO [DEBUG LAB]"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(0.4, 0.8, 1.0, 1.0)
	vbox.add_child(title)

	# Section 1: Animation States Grid
	var sec1 = Label.new()
	sec1.text = "ANIMATION STATES (11)"
	sec1.add_theme_font_size_override("font_size", 12)
	sec1.modulate = Color(0.8, 0.8, 0.9, 0.8)
	vbox.add_child(sec1)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	for state in [
		AnimationState.IDLE, AnimationState.CAST_BOLT, AnimationState.CAST_ORB,
		AnimationState.CAST_RIFT, AnimationState.CAST_SWEEP, AnimationState.HIT,
		AnimationState.STUN, AnimationState.ENRAGED, AnimationState.ULTIMATE_CHARGE,
		AnimationState.ULTIMATE_RELEASE, AnimationState.ULTIMATE_FULL
	]:
		var btn = Button.new()
		btn.text = STATE_NAMES[state]
		btn.custom_minimum_size = Vector2(148, 30)
		btn.add_theme_font_size_override("font_size", 11)
		var s_capture = state
		btn.pressed.connect(func(): play_animation(s_capture))
		grid.add_child(btn)
		state_buttons[state] = btn

	# Section 2: Speed Controls
	var sec2 = Label.new()
	sec2.text = "PLAYBACK SPEED (0.10x – 2.00x) [Keys 1-5]"
	sec2.add_theme_font_size_override("font_size", 12)
	sec2.modulate = Color(0.8, 0.8, 0.9, 0.8)
	vbox.add_child(sec2)

	var speed_box = HBoxContainer.new()
	speed_box.add_theme_constant_override("separation", 6)
	vbox.add_child(speed_box)

	for spd in [0.10, 0.25, 0.50, 1.00, 2.00]:
		var spd_btn = Button.new()
		spd_btn.text = "%.2fx" % spd
		spd_btn.custom_minimum_size = Vector2(65, 26)
		spd_btn.add_theme_font_size_override("font_size", 11)
		var spd_val = spd
		spd_btn.pressed.connect(func(): set_playback_speed(spd_val))
		speed_box.add_child(spd_btn)

	var slider_row = HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 8)
	vbox.add_child(slider_row)

	speed_slider = HSlider.new()
	speed_slider.min_value = 0.10
	speed_slider.max_value = 2.00
	speed_slider.step = 0.05
	speed_slider.value = 1.00
	speed_slider.custom_minimum_size = Vector2(340, 24)
	speed_slider.value_changed.connect(func(val): set_playback_speed(val))
	slider_row.add_child(speed_slider)

	speed_label = Label.new()
	speed_label.text = "1.00x"
	speed_label.custom_minimum_size = Vector2(60, 24)
	speed_label.add_theme_font_size_override("font_size", 12)
	slider_row.add_child(speed_label)

	# Section 3: Transport & Stepping Controls
	var sec3 = Label.new()
	sec3.text = "TRANSPORT & FRAME STEPPING"
	sec3.add_theme_font_size_override("font_size", 12)
	sec3.modulate = Color(0.8, 0.8, 0.9, 0.8)
	vbox.add_child(sec3)

	var trans_row1 = HBoxContainer.new()
	trans_row1.add_theme_constant_override("separation", 8)
	vbox.add_child(trans_row1)

	btn_pause = Button.new()
	btn_pause.text = "PAUSE [Space]"
	btn_pause.custom_minimum_size = Vector2(130, 28)
	btn_pause.pressed.connect(toggle_pause)
	trans_row1.add_child(btn_pause)

	btn_loop = Button.new()
	btn_loop.text = "LOOP: OFF [L]"
	btn_loop.custom_minimum_size = Vector2(120, 28)
	btn_loop.pressed.connect(toggle_loop)
	trans_row1.add_child(btn_loop)

	btn_compare = Button.new()
	btn_compare.text = "COMPARE CASTS [V]"
	btn_compare.custom_minimum_size = Vector2(160, 28)
	btn_compare.pressed.connect(start_compare_casts)
	trans_row1.add_child(btn_compare)

	var trans_row2 = HBoxContainer.new()
	trans_row2.add_theme_constant_override("separation", 8)
	vbox.add_child(trans_row2)

	btn_prev_frame = Button.new()
	btn_prev_frame.text = "PREV FRAME [<-]"
	btn_prev_frame.custom_minimum_size = Vector2(130, 28)
	btn_prev_frame.pressed.connect(func(): step_frame(-1))
	trans_row2.add_child(btn_prev_frame)

	btn_next_frame = Button.new()
	btn_next_frame.text = "NEXT FRAME [->]"
	btn_next_frame.custom_minimum_size = Vector2(130, 28)
	btn_next_frame.pressed.connect(func(): step_frame(1))
	trans_row2.add_child(btn_next_frame)

	btn_motion_path = Button.new()
	btn_motion_path.text = "PATH: OFF [M]"
	btn_motion_path.custom_minimum_size = Vector2(120, 28)
	btn_motion_path.pressed.connect(toggle_motion_path)
	trans_row2.add_child(btn_motion_path)

	btn_reset_baseline = Button.new()
	btn_reset_baseline.text = "RESET BASELINE [R]"
	btn_reset_baseline.custom_minimum_size = Vector2(430, 30)
	btn_reset_baseline.pressed.connect(func():
		restore_canonical_baseline()
		play_animation(AnimationState.IDLE)
	)
	vbox.add_child(btn_reset_baseline)

	_build_tuner_ui_section(vbox)


# ==============================================================================
# ULTIMATE_CHARGE PER-FRAME TRANSFORM TUNER (Task 239O)
# ==============================================================================
const CONFIG_PATH: String = "user://stochas_ultimate_charge_tuning.json"

var charge_frame_transforms: Array[Dictionary] = [
	{"scale": 1.1378, "x": 180.0, "y": 41.91},
	{"scale": 1.1378, "x": 180.0, "y": 41.91},
	{"scale": 1.1378, "x": 180.0, "y": 41.91},
	{"scale": 1.1378, "x": 180.0, "y": 41.91},
	{"scale": 1.1378, "x": 180.0, "y": 41.91},
	{"scale": 1.1378, "x": 180.0, "y": 41.91}
]

var selected_tuner_frame_idx: int = 0
var tuner_frame_buttons: Array[Button] = []
var spin_tuner_scale: SpinBox = null
var spin_tuner_x: SpinBox = null
var spin_tuner_y: SpinBox = null
var lbl_tuner_readout: Label = null
var lbl_tuner_status: Label = null
var is_updating_tuner_ui: bool = false

func get_frame_transform(idx: int) -> Dictionary:
	if idx >= 0 and idx < charge_frame_transforms.size():
		return charge_frame_transforms[idx]
	return {"scale": 1.1378, "x": 180.0, "y": 41.91}

func set_frame_transform(idx: int, scale_val: float, pos_x: float, pos_y: float) -> void:
	if idx >= 0 and idx < charge_frame_transforms.size():
		charge_frame_transforms[idx] = {
			"scale": clampf(scale_val, 0.50, 1.80),
			"x": pos_x,
			"y": pos_y
		}
		if current_charge_frame == idx:
			_set_charge_frame(idx)
		else:
			_update_ghost_overlay()
		_update_tuner_ui_readout()

func select_tuner_frame(idx: int) -> void:
	if idx < 0 or idx >= 6:
		return
	selected_tuner_frame_idx = idx
	# Stop active tween & auto pause for live tuning inspection
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	is_paused = true
	if btn_pause != null:
		btn_pause.text = "RESUME [Space]"
		btn_pause.modulate = Color(1.3, 0.8, 0.3)

	current_state = AnimationState.ULTIMATE_CHARGE
	_set_charge_frame(idx)
	_update_tuner_ui_readout()

func nudge_tuner_scale(delta_scale: float) -> void:
	var tf = get_frame_transform(selected_tuner_frame_idx)
	var new_sc = clampf(tf["scale"] + delta_scale, 0.50, 1.80)
	set_frame_transform(selected_tuner_frame_idx, new_sc, tf["x"], tf["y"])

func nudge_tuner_pos(delta_x: float, delta_y: float) -> void:
	var tf = get_frame_transform(selected_tuner_frame_idx)
	set_frame_transform(selected_tuner_frame_idx, tf["scale"], tf["x"] + delta_x, tf["y"] + delta_y)

func reset_current_frame_tuner() -> void:
	set_frame_transform(selected_tuner_frame_idx, 1.1378, 180.0, 41.91)
	if lbl_tuner_status != null:
		lbl_tuner_status.text = "Reset F0%d to default transform." % (selected_tuner_frame_idx + 1)

func reset_all_tuner_frames() -> void:
	_reset_all_transforms_to_default()
	if lbl_tuner_status != null:
		lbl_tuner_status.text = "Reset all F01..F06 to default transforms."

func copy_current_tuner_to_all() -> void:
	var cur_tf = get_frame_transform(selected_tuner_frame_idx)
	for i in range(6):
		charge_frame_transforms[i] = {"scale": cur_tf["scale"], "x": cur_tf["x"], "y": cur_tf["y"]}
	if current_charge_frame >= 0:
		_set_charge_frame(current_charge_frame)
	_update_tuner_ui_readout()
	if lbl_tuner_status != null:
		lbl_tuner_status.text = "Copied F0%d transform to all frames!" % (selected_tuner_frame_idx + 1)

func copy_previous_tuner_frame() -> void:
	if selected_tuner_frame_idx > 0:
		var prev_tf = get_frame_transform(selected_tuner_frame_idx - 1)
		charge_frame_transforms[selected_tuner_frame_idx] = {"scale": prev_tf["scale"], "x": prev_tf["x"], "y": prev_tf["y"]}
		_set_charge_frame(selected_tuner_frame_idx)
		_update_tuner_ui_readout()
		if lbl_tuner_status != null:
			lbl_tuner_status.text = "Copied F0%d transform to F0%d!" % [selected_tuner_frame_idx, selected_tuner_frame_idx + 1]
	else:
		if lbl_tuner_status != null:
			lbl_tuner_status.text = "F01 has no previous frame to copy from."

func load_tuning_config() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file != null:
			var json_str = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_str)
			if parse_result == OK and json.data is Dictionary:
				var data: Dictionary = json.data
				for i in range(6):
					var key = "F0%d" % (i + 1)
					if data.has(key) and data[key] is Dictionary:
						var entry: Dictionary = data[key]
						var sc = float(entry.get("scale", 1.1378))
						var px = float(entry.get("x", 180.0))
						var py = float(entry.get("y", 41.91))
						charge_frame_transforms[i] = {"scale": sc, "x": px, "y": py}
				show_prev_ghost = bool(data.get("show_prev_ghost", data.get("show_reference_ghost", true)))
				current_frame_opacity = float(data.get("current_frame_opacity", 1.00))
				reference_frame_opacity = float(data.get("reference_frame_opacity", data.get("ghost_opacity", 0.25)))
				_update_ghost_ui_controls()
				print("[TUNER] Loaded tuning config from %s" % CONFIG_PATH)
				if current_charge_frame >= 0:
					_set_charge_frame(current_charge_frame)
				_update_tuner_ui_readout()
				_update_ghost_overlay()
				if lbl_tuner_status != null:
					lbl_tuner_status.text = "Loaded tuning from saved config file!"
				return
	_reset_all_transforms_to_default()

func save_tuning_config() -> void:
	var data: Dictionary = {}
	for i in range(6):
		var key = "F0%d" % (i + 1)
		data[key] = charge_frame_transforms[i]
	data["show_prev_ghost"] = show_prev_ghost
	data["current_frame_opacity"] = current_frame_opacity
	data["reference_frame_opacity"] = reference_frame_opacity
	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("[TUNER] Saved tuning config to %s" % CONFIG_PATH)
		if lbl_tuner_status != null:
			lbl_tuner_status.text = "Saved tuning to user:// config file!"

func reset_saved_tuning_config() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(CONFIG_PATH)
	show_prev_ghost = true
	current_frame_opacity = 1.00
	reference_frame_opacity = 0.25
	_update_ghost_ui_controls()
	_reset_all_transforms_to_default()
	if lbl_tuner_status != null:
		lbl_tuner_status.text = "Reset saved config & restored defaults!"

func copy_tuning_values() -> String:
	var lines: Array[String] = []
	for i in range(6):
		var tf = charge_frame_transforms[i]
		lines.append("F0%d scale=%.4f x=%.2f y=%.2f" % [i + 1, tf["scale"], tf["x"], tf["y"]])
	var output = "\n".join(lines)
	print("=== ULTIMATE_CHARGE TUNING VALUES ===")
	print(output)
	print("=====================================")
	DisplayServer.clipboard_set(output)
	if lbl_tuner_status != null:
		lbl_tuner_status.text = "Copied tuning values to clipboard & console!"
	return output

func _reset_all_transforms_to_default() -> void:
	for i in range(6):
		charge_frame_transforms[i] = {"scale": 1.1378, "x": 180.0, "y": 41.91}
	if current_charge_frame >= 0 and current_charge_frame < 6:
		_set_charge_frame(current_charge_frame)
	_update_tuner_ui_readout()

func _update_tuner_ui_readout() -> void:
	var tf = get_frame_transform(selected_tuner_frame_idx)
	is_updating_tuner_ui = true
	if spin_tuner_scale != null:
		spin_tuner_scale.value = tf["scale"]
	if spin_tuner_x != null:
		spin_tuner_x.value = tf["x"]
	if spin_tuner_y != null:
		spin_tuner_y.value = tf["y"]
	is_updating_tuner_ui = false

	if lbl_tuner_readout != null:
		lbl_tuner_readout.text = "F0%d | Scale: %.4f | X: %.2f | Y: %.2f" % [
			selected_tuner_frame_idx + 1,
			tf["scale"],
			tf["x"],
			tf["y"]
		]

	for i in range(tuner_frame_buttons.size()):
		if tuner_frame_buttons[i] != null:
			tuner_frame_buttons[i].modulate = Color(1.4, 1.2, 0.3) if i == selected_tuner_frame_idx else Color.WHITE


# Ghost / Onion Skin Variables (Task 239P & 239Q Dual Opacity)
var boss_ghost_rect: TextureRect = null
var show_prev_ghost: bool = true
var current_frame_opacity: float = 1.00
var reference_frame_opacity: float = 0.25
var btn_ghost_toggle: Button = null
var slider_current_opacity: HSlider = null
var slider_reference_opacity: HSlider = null
var lbl_ghost_readout: Label = null
var lbl_opacity_readout: Label = null

func toggle_ghost_overlay() -> void:
	set_ghost_enabled(not show_prev_ghost)

func set_ghost_enabled(enabled: bool) -> void:
	show_prev_ghost = enabled
	_update_ghost_ui_controls()
	_update_ghost_overlay()

func set_current_frame_opacity(val: float) -> void:
	current_frame_opacity = clampf(val, 0.00, 1.00)
	_update_ghost_ui_controls()
	_apply_current_frame_opacity()

func set_reference_frame_opacity(val: float) -> void:
	reference_frame_opacity = clampf(val, 0.00, 1.00)
	_update_ghost_ui_controls()
	_update_ghost_overlay()

func set_ghost_opacity(val: float) -> void:
	set_reference_frame_opacity(val)

func is_ghost_enabled() -> bool:
	return show_prev_ghost

func get_current_frame_opacity() -> float:
	return current_frame_opacity

func get_reference_frame_opacity() -> float:
	return reference_frame_opacity

func get_ghost_opacity() -> float:
	return reference_frame_opacity

func _apply_current_frame_opacity() -> void:
	if boss_rect == null:
		return
	if is_paused or active_tween == null or not active_tween.is_valid():
		boss_rect.modulate.a = current_frame_opacity

func _update_ghost_ui_controls() -> void:
	if btn_ghost_toggle != null:
		btn_ghost_toggle.text = "SHOW REF GHOST: ON [G]" if show_prev_ghost else "SHOW REF GHOST: OFF [G]"
		btn_ghost_toggle.modulate = Color(0.4, 1.2, 0.6) if show_prev_ghost else Color.WHITE
	if slider_current_opacity != null and not is_equal_approx(slider_current_opacity.value, current_frame_opacity):
		slider_current_opacity.value = current_frame_opacity
	if slider_reference_opacity != null and not is_equal_approx(slider_reference_opacity.value, reference_frame_opacity):
		slider_reference_opacity.value = reference_frame_opacity

	if lbl_opacity_readout != null:
		lbl_opacity_readout.text = "Cur Alpha: %.2f | Ref Alpha: %.2f" % [current_frame_opacity, reference_frame_opacity]

func _update_ghost_overlay() -> void:
	if boss_ghost_rect == null:
		return

	if current_state != AnimationState.ULTIMATE_CHARGE or not show_prev_ghost or current_charge_frame < 0:
		boss_ghost_rect.visible = false
		if lbl_ghost_readout != null:
			lbl_ghost_readout.text = "CURRENT = %s | REFERENCE = NONE" % STATE_NAMES.get(current_state, "N/A")
		return

	if current_charge_frame == 0:
		# Task 239Q Gate 1 & 2: F01 reference MUST be CANONICAL IDLE boss frame with original transform
		if canonical_boss_tex != null:
			boss_ghost_rect.texture = canonical_boss_tex
			boss_ghost_rect.position = BOSS_BASE_POS
			boss_ghost_rect.scale = Vector2.ONE
			boss_ghost_rect.modulate = Color(0.7, 0.85, 1.0, reference_frame_opacity)
			boss_ghost_rect.visible = (reference_frame_opacity > 0.001)
		else:
			boss_ghost_rect.visible = false
		if lbl_ghost_readout != null:
			lbl_ghost_readout.text = "CURRENT = F01 | REFERENCE = CANONICAL IDLE"
	else:
		# F02..F06: Reference ghost is previous frame F0(x-1) with its tuned transform
		var prev_idx: int = current_charge_frame - 1
		if prev_idx >= 0 and prev_idx < stochas_ultimate_charge_frames.size():
			var prev_tf = get_frame_transform(prev_idx)
			boss_ghost_rect.texture = stochas_ultimate_charge_frames[prev_idx]
			boss_ghost_rect.scale = Vector2(prev_tf["scale"], prev_tf["scale"])
			boss_ghost_rect.position = Vector2(prev_tf["x"], prev_tf["y"])
			boss_ghost_rect.modulate = Color(0.7, 0.85, 1.0, reference_frame_opacity)
			boss_ghost_rect.visible = (reference_frame_opacity > 0.001)
			if lbl_ghost_readout != null:
				lbl_ghost_readout.text = "CURRENT = F0%d | REFERENCE = F0%d" % [current_charge_frame + 1, prev_idx + 1]
		else:
			boss_ghost_rect.visible = false


# Task 239R & 239R1 Interactive Transform Gizmo & Layout Variables
var gizmo_overlay: Control = null
var is_gizmo_dragging_move: bool = false
var is_gizmo_dragging_resize: bool = false
var gizmo_drag_handle_idx: int = -1
var gizmo_drag_start_mouse: Vector2 = Vector2.ZERO
var gizmo_drag_start_pos: Vector2 = Vector2.ZERO
var gizmo_drag_start_scale: float = 1.1378
var is_status_panel_collapsed: bool = true # Task 239R1: DEFAULT COLLAPSED
var btn_status_toggle: Button = null

func _apply_initial_status_panel_state() -> void:
	is_status_panel_collapsed = true
	if bottom_panel != null:
		bottom_panel.position = Vector2(40.0, 675.0)
		bottom_panel.size = Vector2(680.0, 35.0)
		bottom_panel.custom_minimum_size = Vector2(680.0, 35.0)
		if lbl_diag_details != null:
			lbl_diag_details.visible = false
	if btn_status_toggle != null:
		btn_status_toggle.text = "STATUS [SHOW]"

func toggle_status_panel_collapse() -> void:
	is_status_panel_collapsed = not is_status_panel_collapsed
	if bottom_panel != null:
		if is_status_panel_collapsed:
			bottom_panel.position = Vector2(40.0, 675.0)
			bottom_panel.size = Vector2(680.0, 35.0)
			bottom_panel.custom_minimum_size = Vector2(680.0, 35.0)
			if lbl_diag_details != null:
				lbl_diag_details.visible = false
		else:
			bottom_panel.position = Vector2(40.0, 615.0)
			bottom_panel.size = Vector2(680.0, 95.0)
			bottom_panel.custom_minimum_size = Vector2(680.0, 95.0)
			if lbl_diag_details != null:
				lbl_diag_details.visible = true
	if btn_status_toggle != null:
		btn_status_toggle.text = "STATUS [SHOW]" if is_status_panel_collapsed else "STATUS [HIDE]"

func get_frame_art_gizmo_rect(frame_idx: int) -> Rect2:
	if boss_rect == null or gizmo_overlay == null:
		return Rect2()

	var alpha_rect: Rect2 = FRAME_ALPHA_BBOXES.get(frame_idx, Rect2(0.0, 0.0, 512.0, 512.0))
	var tex_size: Vector2 = Vector2(512.0, 512.0)
	if boss_rect.texture != null:
		tex_size = boss_rect.texture.get_size()

	var container_size: Vector2 = boss_rect.size # (520, 560)
	var aspect_scale: float = minf(container_size.x / tex_size.x, container_size.y / tex_size.y)
	var drawn_size: Vector2 = tex_size * aspect_scale
	var drawn_offset: Vector2 = (container_size - drawn_size) * 0.5

	# Map alpha bbox to unscaled local coords inside boss_rect
	var local_tl: Vector2 = drawn_offset + alpha_rect.position * aspect_scale
	var local_br: Vector2 = drawn_offset + (alpha_rect.position + alpha_rect.size) * aspect_scale

	# Transform relative to boss_rect.pivot_offset by boss_rect.scale
	var pivot: Vector2 = boss_rect.pivot_offset
	var tl_from_pivot: Vector2 = (local_tl - pivot) * boss_rect.scale
	var br_from_pivot: Vector2 = (local_br - pivot) * boss_rect.scale

	# Global center of boss_rect
	var center_global: Vector2 = boss_rect.position + pivot
	var global_tl: Vector2 = center_global + tl_from_pivot
	var global_br: Vector2 = center_global + br_from_pivot

	# Convert to local gizmo_overlay coordinates using global_position
	var gizmo_origin: Vector2 = gizmo_overlay.global_position
	var gizmo_tl: Vector2 = global_tl - gizmo_origin
	var gizmo_br: Vector2 = global_br - gizmo_origin

	return Rect2(gizmo_tl, gizmo_br - gizmo_tl)

func queue_gizmo_redraw() -> void:
	if gizmo_overlay != null:
		gizmo_overlay.queue_redraw()

func _on_draw_gizmo_overlay() -> void:
	if gizmo_overlay == null or boss_rect == null:
		return

	# Show gizmo ONLY during ULTIMATE_CHARGE and when paused / manual frame inspection mode
	if current_state != AnimationState.ULTIMATE_CHARGE or current_charge_frame < 0:
		return
	if not is_paused and active_tween != null and active_tween.is_valid():
		return

	# Task 239R1: Calculate tight artwork bounding box in local gizmo_overlay coordinates
	var art_rect: Rect2 = get_frame_art_gizmo_rect(selected_tuner_frame_idx)
	if art_rect.size.x <= 0.0 or art_rect.size.y <= 0.0:
		return

	var rect_tl = art_rect.position
	var rect_br = art_rect.position + art_rect.size
	var center_local = art_rect.position + art_rect.size * 0.5

	# 1. Draw Bright Cyan Bounding Box Outline around tight artwork
	gizmo_overlay.draw_rect(art_rect, Color(0.2, 0.9, 1.0, 0.95), false, 2.0)

	# 2. Draw 4 Corner Handles (TL, TR, BL, BR) - 10x10px visible rect
	var corners = [
		rect_tl,
		Vector2(rect_br.x, rect_tl.y),
		Vector2(rect_tl.x, rect_br.y),
		rect_br
	]
	for c in corners:
		gizmo_overlay.draw_rect(Rect2(c - Vector2(5, 5), Vector2(10, 10)), Color(1.0, 1.0, 0.3, 0.95), true)
		gizmo_overlay.draw_rect(Rect2(c - Vector2(5, 5), Vector2(10, 10)), Color(0.1, 0.1, 0.1, 0.9), false, 1.5)

	# 3. Draw Center Move Handle (Crosshair)
	gizmo_overlay.draw_circle(center_local, 5.0, Color(0.2, 0.9, 1.0, 0.95))
	gizmo_overlay.draw_line(center_local - Vector2(10, 0), center_local + Vector2(10, 0), Color(0.2, 0.9, 1.0, 0.95), 1.5)
	gizmo_overlay.draw_line(center_local - Vector2(0, 10), center_local + Vector2(0, 10), Color(0.2, 0.9, 1.0, 0.95), 1.5)

	# 4. Draw Live Drag Info Readout
	var tf = get_frame_transform(selected_tuner_frame_idx)
	var mode_str = "IDLE"
	if is_gizmo_dragging_move:
		mode_str = "DRAG MOVE"
	elif is_gizmo_dragging_resize:
		mode_str = "CORNER RESIZE"

	var info_text = "[%s] F0%d | Scale: %.4f | Pos: (%.1f, %.1f)" % [mode_str, selected_tuner_frame_idx + 1, tf["scale"], tf["x"], tf["y"]]
	var font = get_theme_default_font()
	if font != null:
		gizmo_overlay.draw_string(font, rect_tl + Vector2(0, -8), info_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 1.0, 0.6, 0.95))

func _on_gui_input_gizmo_overlay(event: InputEvent) -> void:
	if current_state != AnimationState.ULTIMATE_CHARGE or current_charge_frame < 0 or boss_rect == null:
		return
	if not is_paused and active_tween != null and active_tween.is_valid():
		return

	var art_rect: Rect2 = get_frame_art_gizmo_rect(selected_tuner_frame_idx)
	var rect_tl = art_rect.position
	var rect_br = art_rect.position + art_rect.size
	var center_local = art_rect.position + art_rect.size * 0.5

	var corners = [
		rect_tl,
		Vector2(rect_br.x, rect_tl.y),
		Vector2(rect_tl.x, rect_br.y),
		rect_br
	]

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check corner handles hit (28px diameter / 14px radius hit area around each corner)
				gizmo_drag_handle_idx = -1
				for i in range(corners.size()):
					if event.position.distance_to(corners[i]) <= 14.0:
						gizmo_drag_handle_idx = i
						break

				if gizmo_drag_handle_idx >= 0:
					is_gizmo_dragging_resize = true
					gizmo_drag_start_mouse = event.position
					gizmo_drag_start_scale = get_frame_transform(selected_tuner_frame_idx)["scale"]
					gizmo_overlay.accept_event()
				elif art_rect.has_point(event.position):
					is_gizmo_dragging_move = true
					gizmo_drag_start_mouse = event.position
					var tf = get_frame_transform(selected_tuner_frame_idx)
					gizmo_drag_start_pos = Vector2(tf["x"], tf["y"])
					gizmo_overlay.accept_event()
			else:
				if is_gizmo_dragging_move or is_gizmo_dragging_resize:
					gizmo_overlay.accept_event()
				is_gizmo_dragging_move = false
				is_gizmo_dragging_resize = false
				gizmo_drag_handle_idx = -1
				queue_gizmo_redraw()

	elif event is InputEventMouseMotion:
		# Update cursor shape feedback
		var hover_corner = false
		for c in corners:
			if event.position.distance_to(c) <= 14.0:
				hover_corner = true
				break
		if hover_corner or is_gizmo_dragging_resize:
			gizmo_overlay.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		elif art_rect.has_point(event.position) or is_gizmo_dragging_move:
			gizmo_overlay.mouse_default_cursor_shape = Control.CURSOR_MOVE
		else:
			gizmo_overlay.mouse_default_cursor_shape = Control.CURSOR_ARROW

		var speed_mult: float = 1.0
		if Input.is_key_pressed(KEY_SHIFT):
			speed_mult = 0.20
		elif Input.is_key_pressed(KEY_CTRL):
			speed_mult = 0.05

		if is_gizmo_dragging_move:
			var mouse_delta = (event.position - gizmo_drag_start_mouse) * speed_mult
			var new_x = gizmo_drag_start_pos.x + mouse_delta.x
			var new_y = gizmo_drag_start_pos.y + mouse_delta.y
			var cur_sc = get_frame_transform(selected_tuner_frame_idx)["scale"]
			set_frame_transform(selected_tuner_frame_idx, cur_sc, new_x, new_y)
			gizmo_overlay.accept_event()
			queue_gizmo_redraw()

		elif is_gizmo_dragging_resize:
			var dist_start = gizmo_drag_start_mouse.distance_to(center_local)
			var dist_curr = event.position.distance_to(center_local)
			var ratio = (dist_curr / dist_start) if dist_start > 0.001 else 1.0
			var delta_ratio = (ratio - 1.0) * speed_mult
			var new_scale = clampf(gizmo_drag_start_scale * (1.0 + delta_ratio), 0.50, 1.80)
			var cur_tf = get_frame_transform(selected_tuner_frame_idx)
			set_frame_transform(selected_tuner_frame_idx, new_scale, cur_tf["x"], cur_tf["y"])
			gizmo_overlay.accept_event()
			queue_gizmo_redraw()


func _build_tuner_ui_section(vbox: VBoxContainer) -> void:
	var sec_title = Label.new()
	sec_title.text = "ULTIMATE_CHARGE FRAME TUNER"
	sec_title.add_theme_font_size_override("font_size", 12)
	sec_title.modulate = Color(0.4, 0.9, 1.0, 0.9)
	vbox.add_child(sec_title)

	# Section: ONION SKIN REFERENCE GHOST & DUAL OPACITY (Task 239Q)
	var ghost_toggle_row = HBoxContainer.new()
	ghost_toggle_row.add_theme_constant_override("separation", 8)
	vbox.add_child(ghost_toggle_row)

	btn_ghost_toggle = Button.new()
	btn_ghost_toggle.text = "SHOW REF GHOST: ON [G]" if show_prev_ghost else "SHOW REF GHOST: OFF [G]"
	btn_ghost_toggle.custom_minimum_size = Vector2(180, 26)
	btn_ghost_toggle.add_theme_font_size_override("font_size", 11)
	btn_ghost_toggle.modulate = Color(0.4, 1.2, 0.6) if show_prev_ghost else Color.WHITE
	btn_ghost_toggle.pressed.connect(toggle_ghost_overlay)
	ghost_toggle_row.add_child(btn_ghost_toggle)

	lbl_ghost_readout = Label.new()
	lbl_ghost_readout.text = "CURRENT = F01 | REFERENCE = CANONICAL IDLE"
	lbl_ghost_readout.add_theme_font_size_override("font_size", 11)
	lbl_ghost_readout.modulate = Color(0.7, 0.85, 1.0, 0.9)
	ghost_toggle_row.add_child(lbl_ghost_readout)

	# Dual Opacity Sliders (Current Frame Alpha & Reference Frame Alpha)
	var opacity_box = HBoxContainer.new()
	opacity_box.add_theme_constant_override("separation", 10)
	vbox.add_child(opacity_box)

	# Current Frame Opacity Slider
	var cur_op_box = HBoxContainer.new()
	cur_op_box.add_theme_constant_override("separation", 4)
	opacity_box.add_child(cur_op_box)

	var cur_lbl = Label.new()
	cur_lbl.text = "Current Alpha:"
	cur_lbl.add_theme_font_size_override("font_size", 11)
	cur_op_box.add_child(cur_lbl)

	slider_current_opacity = HSlider.new()
	slider_current_opacity.min_value = 0.00
	slider_current_opacity.max_value = 1.00
	slider_current_opacity.step = 0.01
	slider_current_opacity.value = current_frame_opacity
	slider_current_opacity.custom_minimum_size = Vector2(110, 24)
	slider_current_opacity.value_changed.connect(set_current_frame_opacity)
	cur_op_box.add_child(slider_current_opacity)

	# Reference Frame Opacity Slider
	var ref_op_box = HBoxContainer.new()
	ref_op_box.add_theme_constant_override("separation", 4)
	opacity_box.add_child(ref_op_box)

	var ref_lbl = Label.new()
	ref_lbl.text = "Ref Alpha:"
	ref_lbl.add_theme_font_size_override("font_size", 11)
	ref_op_box.add_child(ref_lbl)

	slider_reference_opacity = HSlider.new()
	slider_reference_opacity.min_value = 0.00
	slider_reference_opacity.max_value = 1.00
	slider_reference_opacity.step = 0.01
	slider_reference_opacity.value = reference_frame_opacity
	slider_reference_opacity.custom_minimum_size = Vector2(110, 24)
	slider_reference_opacity.value_changed.connect(set_reference_frame_opacity)
	ref_op_box.add_child(slider_reference_opacity)

	lbl_opacity_readout = Label.new()
	lbl_opacity_readout.text = "Cur Alpha: 1.00 | Ref Alpha: 0.25"
	lbl_opacity_readout.add_theme_font_size_override("font_size", 11)
	lbl_opacity_readout.modulate = Color(1.0, 0.9, 0.5, 0.9)
	vbox.add_child(lbl_opacity_readout)

	# Frame Selector Buttons (F01 .. F06)
	var f_box = HBoxContainer.new()
	f_box.add_theme_constant_override("separation", 6)
	vbox.add_child(f_box)

	tuner_frame_buttons.clear()
	for i in range(6):
		var btn = Button.new()
		btn.text = "F0%d" % (i + 1)
		btn.custom_minimum_size = Vector2(65, 26)
		btn.add_theme_font_size_override("font_size", 11)
		var f_idx = i
		btn.pressed.connect(func(): select_tuner_frame(f_idx))
		f_box.add_child(btn)
		tuner_frame_buttons.append(btn)

	# Readout Label
	lbl_tuner_readout = Label.new()
	lbl_tuner_readout.text = "F01 | Scale: 1.1378 | X: 180.0 | Y: 41.91"
	lbl_tuner_readout.add_theme_font_size_override("font_size", 12)
	lbl_tuner_readout.modulate = Color(1.0, 0.9, 0.4, 1.0)
	vbox.add_child(lbl_tuner_readout)

	# SpinBoxes Row (Scale, X, Y)
	var spin_row = HBoxContainer.new()
	spin_row.add_theme_constant_override("separation", 8)
	vbox.add_child(spin_row)

	# Scale SpinBox
	var sc_lbl = Label.new()
	sc_lbl.text = "Scale:"
	sc_lbl.add_theme_font_size_override("font_size", 11)
	spin_row.add_child(sc_lbl)

	spin_tuner_scale = SpinBox.new()
	spin_tuner_scale.min_value = 0.50
	spin_tuner_scale.max_value = 1.80
	spin_tuner_scale.step = 0.005
	spin_tuner_scale.value = 1.1378
	spin_tuner_scale.custom_minimum_size = Vector2(90, 26)
	spin_tuner_scale.value_changed.connect(func(val):
		if not is_updating_tuner_ui:
			var tf = get_frame_transform(selected_tuner_frame_idx)
			set_frame_transform(selected_tuner_frame_idx, val, tf["x"], tf["y"])
	)
	spin_row.add_child(spin_tuner_scale)

	# X SpinBox
	var x_lbl = Label.new()
	x_lbl.text = "X:"
	x_lbl.add_theme_font_size_override("font_size", 11)
	spin_row.add_child(x_lbl)

	spin_tuner_x = SpinBox.new()
	spin_tuner_x.min_value = -500.0
	spin_tuner_x.max_value = 1000.0
	spin_tuner_x.step = 1.0
	spin_tuner_x.value = 180.0
	spin_tuner_x.custom_minimum_size = Vector2(90, 26)
	spin_tuner_x.value_changed.connect(func(val):
		if not is_updating_tuner_ui:
			var tf = get_frame_transform(selected_tuner_frame_idx)
			set_frame_transform(selected_tuner_frame_idx, tf["scale"], val, tf["y"])
	)
	spin_row.add_child(spin_tuner_x)

	# Y SpinBox
	var y_lbl = Label.new()
	y_lbl.text = "Y:"
	y_lbl.add_theme_font_size_override("font_size", 11)
	spin_row.add_child(y_lbl)

	spin_tuner_y = SpinBox.new()
	spin_tuner_y.min_value = -500.0
	spin_tuner_y.max_value = 1000.0
	spin_tuner_y.step = 1.0
	spin_tuner_y.value = 41.91
	spin_tuner_y.custom_minimum_size = Vector2(90, 26)
	spin_tuner_y.value_changed.connect(func(val):
		if not is_updating_tuner_ui:
			var tf = get_frame_transform(selected_tuner_frame_idx)
			set_frame_transform(selected_tuner_frame_idx, tf["scale"], tf["x"], val)
	)
	spin_row.add_child(spin_tuner_y)

	# Nudge Row 1: Position Nudges
	var nudge_pos_row = HBoxContainer.new()
	nudge_pos_row.add_theme_constant_override("separation", 4)
	vbox.add_child(nudge_pos_row)

	var btn_left1 = Button.new()
	btn_left1.text = "LEFT -1"
	btn_left1.custom_minimum_size = Vector2(65, 24)
	btn_left1.add_theme_font_size_override("font_size", 10)
	btn_left1.pressed.connect(func(): nudge_tuner_pos(-1.0, 0.0))
	nudge_pos_row.add_child(btn_left1)

	var btn_right1 = Button.new()
	btn_right1.text = "RIGHT +1"
	btn_right1.custom_minimum_size = Vector2(65, 24)
	btn_right1.add_theme_font_size_override("font_size", 10)
	btn_right1.pressed.connect(func(): nudge_tuner_pos(1.0, 0.0))
	nudge_pos_row.add_child(btn_right1)

	var btn_up1 = Button.new()
	btn_up1.text = "UP -1"
	btn_up1.custom_minimum_size = Vector2(65, 24)
	btn_up1.add_theme_font_size_override("font_size", 10)
	btn_up1.pressed.connect(func(): nudge_tuner_pos(0.0, -1.0))
	nudge_pos_row.add_child(btn_up1)

	var btn_down1 = Button.new()
	btn_down1.text = "DOWN +1"
	btn_down1.custom_minimum_size = Vector2(65, 24)
	btn_down1.add_theme_font_size_override("font_size", 10)
	btn_down1.pressed.connect(func(): nudge_tuner_pos(0.0, 1.0))
	nudge_pos_row.add_child(btn_down1)

	var btn_left5 = Button.new()
	btn_left5.text = "X -5"
	btn_left5.custom_minimum_size = Vector2(50, 24)
	btn_left5.add_theme_font_size_override("font_size", 10)
	btn_left5.pressed.connect(func(): nudge_tuner_pos(-5.0, 0.0))
	nudge_pos_row.add_child(btn_left5)

	var btn_right5 = Button.new()
	btn_right5.text = "X +5"
	btn_right5.custom_minimum_size = Vector2(50, 24)
	btn_right5.add_theme_font_size_override("font_size", 10)
	btn_right5.pressed.connect(func(): nudge_tuner_pos(5.0, 0.0))
	nudge_pos_row.add_child(btn_right5)

	var btn_up5 = Button.new()
	btn_up5.text = "Y -5"
	btn_up5.custom_minimum_size = Vector2(50, 24)
	btn_up5.add_theme_font_size_override("font_size", 10)
	btn_up5.pressed.connect(func(): nudge_tuner_pos(0.0, -5.0))
	nudge_pos_row.add_child(btn_up5)

	var btn_down5 = Button.new()
	btn_down5.text = "Y +5"
	btn_down5.custom_minimum_size = Vector2(50, 24)
	btn_down5.add_theme_font_size_override("font_size", 10)
	btn_down5.pressed.connect(func(): nudge_tuner_pos(0.0, 5.0))
	nudge_pos_row.add_child(btn_down5)

	# Nudge Row 2: Scale Nudges
	var nudge_sc_row = HBoxContainer.new()
	nudge_sc_row.add_theme_constant_override("separation", 6)
	vbox.add_child(nudge_sc_row)

	var btn_sc_sub005 = Button.new()
	btn_sc_sub005.text = "SCALE -0.005"
	btn_sc_sub005.custom_minimum_size = Vector2(100, 24)
	btn_sc_sub005.add_theme_font_size_override("font_size", 10)
	btn_sc_sub005.pressed.connect(func(): nudge_tuner_scale(-0.005))
	nudge_sc_row.add_child(btn_sc_sub005)

	var btn_sc_add005 = Button.new()
	btn_sc_add005.text = "SCALE +0.005"
	btn_sc_add005.custom_minimum_size = Vector2(100, 24)
	btn_sc_add005.add_theme_font_size_override("font_size", 10)
	btn_sc_add005.pressed.connect(func(): nudge_tuner_scale(0.005))
	nudge_sc_row.add_child(btn_sc_add005)

	var btn_sc_sub01 = Button.new()
	btn_sc_sub01.text = "SCALE -0.01"
	btn_sc_sub01.custom_minimum_size = Vector2(95, 24)
	btn_sc_sub01.add_theme_font_size_override("font_size", 10)
	btn_sc_sub01.pressed.connect(func(): nudge_tuner_scale(-0.01))
	nudge_sc_row.add_child(btn_sc_sub01)

	var btn_sc_add01 = Button.new()
	btn_sc_add01.text = "SCALE +0.01"
	btn_sc_add01.custom_minimum_size = Vector2(95, 24)
	btn_sc_add01.add_theme_font_size_override("font_size", 10)
	btn_sc_add01.pressed.connect(func(): nudge_tuner_scale(0.01))
	nudge_sc_row.add_child(btn_sc_add01)

	# Utility Buttons Row 1: Transform Manipulation
	var util_row1 = HBoxContainer.new()
	util_row1.add_theme_constant_override("separation", 6)
	vbox.add_child(util_row1)

	var btn_rst_cur = Button.new()
	btn_rst_cur.text = "RESET FRAME"
	btn_rst_cur.custom_minimum_size = Vector2(100, 26)
	btn_rst_cur.add_theme_font_size_override("font_size", 10)
	btn_rst_cur.pressed.connect(reset_current_frame_tuner)
	util_row1.add_child(btn_rst_cur)

	var btn_rst_all = Button.new()
	btn_rst_all.text = "RESET ALL"
	btn_rst_all.custom_minimum_size = Vector2(90, 26)
	btn_rst_all.add_theme_font_size_override("font_size", 10)
	btn_rst_all.pressed.connect(reset_all_tuner_frames)
	util_row1.add_child(btn_rst_all)

	var btn_copy_all = Button.new()
	btn_copy_all.text = "COPY TO ALL"
	btn_copy_all.custom_minimum_size = Vector2(100, 26)
	btn_copy_all.add_theme_font_size_override("font_size", 10)
	btn_copy_all.pressed.connect(copy_current_tuner_to_all)
	util_row1.add_child(btn_copy_all)

	var btn_copy_prev = Button.new()
	btn_copy_prev.text = "COPY PREVIOUS"
	btn_copy_prev.custom_minimum_size = Vector2(110, 26)
	btn_copy_prev.add_theme_font_size_override("font_size", 10)
	btn_copy_prev.pressed.connect(copy_previous_tuner_frame)
	util_row1.add_child(btn_copy_prev)

	# Save / Persistence Row
	var save_row = HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 6)
	vbox.add_child(save_row)

	var btn_save = Button.new()
	btn_save.text = "SAVE TUNING"
	btn_save.custom_minimum_size = Vector2(130, 26)
	btn_save.add_theme_font_size_override("font_size", 11)
	btn_save.modulate = Color(0.4, 1.2, 0.5)
	btn_save.pressed.connect(save_tuning_config)
	save_row.add_child(btn_save)

	var btn_reload = Button.new()
	btn_reload.text = "RELOAD TUNING"
	btn_reload.custom_minimum_size = Vector2(130, 26)
	btn_reload.add_theme_font_size_override("font_size", 11)
	btn_reload.pressed.connect(load_tuning_config)
	save_row.add_child(btn_reload)

	var btn_rst_save = Button.new()
	btn_rst_save.text = "RESET SAVED TUNING"
	btn_rst_save.custom_minimum_size = Vector2(150, 26)
	btn_rst_save.add_theme_font_size_override("font_size", 11)
	btn_rst_save.pressed.connect(reset_saved_tuning_config)
	save_row.add_child(btn_rst_save)

	# Copyable Output Button
	var btn_copy_out = Button.new()
	btn_copy_out.text = "COPY TUNING VALUES (PRINT & CLIPBOARD)"
	btn_copy_out.custom_minimum_size = Vector2(430, 28)
	btn_copy_out.add_theme_font_size_override("font_size", 11)
	btn_copy_out.modulate = Color(1.2, 1.1, 0.4)
	btn_copy_out.pressed.connect(func(): copy_tuning_values())
	vbox.add_child(btn_copy_out)

	# Status Toast Label
	lbl_tuner_status = Label.new()
	lbl_tuner_status.text = "Tuner ready. Select frame F01..F06 to adjust."
	lbl_tuner_status.add_theme_font_size_override("font_size", 11)
	lbl_tuner_status.modulate = Color(0.6, 0.8, 1.0, 0.8)
	vbox.add_child(lbl_tuner_status)

func _build_diagnostic_ui() -> void:
	bottom_panel = PanelContainer.new()
	bottom_panel.name = "DiagnosticPanel"
	bottom_panel.position = Vector2(40.0, 675.0)
	bottom_panel.size = Vector2(680.0, 35.0)
	bottom_panel.custom_minimum_size = Vector2(680.0, 35.0)

	var bg_box = StyleBoxFlat.new()
	bg_box.bg_color = Color(0.06, 0.07, 0.10, 0.95)
	bg_box.border_color = Color(0.25, 0.35, 0.50, 0.85)
	bg_box.border_width_left = 2
	bg_box.border_width_top = 2
	bg_box.border_width_right = 2
	bg_box.border_width_bottom = 2
	bg_box.corner_radius_top_left = 6
	bg_box.corner_radius_top_right = 6
	bg_box.corner_radius_bottom_left = 6
	bg_box.corner_radius_bottom_right = 6
	bottom_panel.add_theme_stylebox_override("panel", bg_box)
	add_child(bottom_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	bottom_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	vbox.add_child(top_row)

	btn_status_toggle = Button.new()
	btn_status_toggle.text = "STATUS [SHOW]"
	btn_status_toggle.custom_minimum_size = Vector2(120, 24)
	btn_status_toggle.add_theme_font_size_override("font_size", 10)
	btn_status_toggle.pressed.connect(toggle_status_panel_collapse)
	top_row.add_child(btn_status_toggle)

	lbl_diag_state = Label.new()
	lbl_diag_state.text = "STATE: IDLE | SPEED: 1.00x | FRAME: Canonical (stochas_boss.png) | ELAPSED: 0.00s / 3.20s"
	lbl_diag_state.add_theme_font_size_override("font_size", 11)
	lbl_diag_state.clip_text = true
	lbl_diag_state.custom_minimum_size = Vector2(500, 24)
	lbl_diag_state.modulate = Color(0.3, 0.9, 1.0, 1.0)
	top_row.add_child(lbl_diag_state)

	lbl_diag_details = Label.new()
	lbl_diag_details.text = "POS: (180.0, 50.0) [d: +0.0, +0.0] | ROT: 0.0 deg | SCALE: (1.00, 1.00) | MOD: (1.0, 1.0, 1.0) | FLAGS: Loop: OFF | Paused: NO | Compare: NO"
	lbl_diag_details.add_theme_font_size_override("font_size", 10)
	lbl_diag_details.clip_text = true
	lbl_diag_details.custom_minimum_size = Vector2(650, 24)
	lbl_diag_details.modulate = Color(0.75, 0.85, 0.95, 0.90)
	vbox.add_child(lbl_diag_details)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				toggle_pause()
			KEY_1:
				set_playback_speed(0.10)
			KEY_2:
				set_playback_speed(0.25)
			KEY_3:
				set_playback_speed(0.50)
			KEY_4:
				set_playback_speed(1.00)
			KEY_5:
				set_playback_speed(2.00)
			KEY_L:
				toggle_loop()
			KEY_V:
				start_compare_casts()
			KEY_G:
				toggle_ghost_overlay()
			KEY_M:
				toggle_motion_path()
			KEY_LEFT:
				step_frame(-1)
			KEY_RIGHT:
				step_frame(1)
			KEY_R:
				restore_canonical_baseline()
				play_animation(AnimationState.IDLE)

func _process(delta: float) -> void:
	if stun_overlay != null and stun_overlay.visible:
		var t = Time.get_ticks_msec() / 1000.0 * 4.0 * playback_speed
		for i in range(stun_stars.size()):
			var star = stun_stars[i]
			var angle = t + (i * TAU / 3.0)
			star.position = Vector2(cos(angle) * 35.0 - 10.0, sin(angle) * 10.0 - 15.0)

	if is_compare_casts_active and not is_paused:
		compare_timer -= delta * playback_speed
		if compare_timer <= 0.0:
			_advance_compare_cast()

	if not is_paused and active_tween != null and active_tween.is_valid():
		elapsed_time += delta * playback_speed
		if motion_path_enabled and boss_rect != null:
			var pt = boss_rect.position + boss_rect.pivot_offset
			if motion_trail_points.is_empty() or motion_trail_points.back().distance_to(pt) > 3.0:
				motion_trail_points.append(pt)
				if motion_trail_points.size() > MAX_MOTION_POINTS:
					motion_trail_points.pop_front()
				if motion_path_line != null:
					motion_path_line.points = PackedVector2Array(motion_trail_points)

	_update_diagnostic_labels()

func _update_diagnostic_labels() -> void:
	if lbl_diag_state == null or lbl_diag_details == null or boss_rect == null:
		return

	var frame_desc: String = get_frame_display_text()

	if is_status_panel_collapsed:
		lbl_diag_state.text = "STATE: %s | FRAME: %s" % [STATE_NAMES[current_state], frame_desc]
	else:
		lbl_diag_state.text = "STATE: %s | SPEED: %.2fx | FRAME: %s | ELAPSED: %.2fs / %.2fs" % [
			STATE_NAMES[current_state],
			playback_speed,
			frame_desc,
			minf(elapsed_time, state_duration),
			state_duration
		]

	var delta_pos: Vector2 = boss_rect.position - BOSS_BASE_POS
	lbl_diag_details.text = "POS: (%.1f, %.1f) [d: %+.1f, %+.1f] | ROT: %+.1f deg | SCALE: (%.2f, %.2f) | MOD: (%.1f, %.1f, %.1f) | FLAGS: Loop: %s | Paused: %s | Compare: %s" % [
		boss_rect.position.x,
		boss_rect.position.y,
		delta_pos.x,
		delta_pos.y,
		boss_rect.rotation_degrees,
		boss_rect.scale.x,
		boss_rect.scale.y,
		boss_rect.modulate.r,
		boss_rect.modulate.g,
		boss_rect.modulate.b,
		"ON" if is_loop_enabled else "OFF",
		"YES" if is_paused else "NO",
		"YES" if is_compare_casts_active else "NO"
	]

# ==============================================================================
# ANIMATION CONTROLLER
# ==============================================================================

func play_animation(state: AnimationState) -> void:
	current_state = state
	elapsed_time = 0.0
	state_duration = STATE_DURATIONS.get(state, 1.0)
	_clear_transient_vfx()

	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	# Highlight current button
	for s in state_buttons:
		if state_buttons[s] != null:
			state_buttons[s].modulate = Color(1.3, 1.2, 0.4) if s == state else Color.WHITE

	match state:
		AnimationState.IDLE:
			_play_idle()
		AnimationState.CAST_BOLT:
			_play_cast_bolt()
		AnimationState.CAST_ORB:
			_play_cast_orb()
		AnimationState.CAST_RIFT:
			_play_cast_rift()
		AnimationState.CAST_SWEEP:
			_play_cast_sweep()
		AnimationState.HIT:
			_play_hit()
		AnimationState.STUN:
			_play_stun()
		AnimationState.ENRAGED:
			_play_enraged()
		AnimationState.ULTIMATE_CHARGE:
			_play_ultimate_charge()
		AnimationState.ULTIMATE_RELEASE:
			_play_ultimate_release()
		AnimationState.ULTIMATE_FULL:
			_play_ultimate_full()

	if active_tween != null and active_tween.is_valid():
		active_tween.set_speed_scale(playback_speed)
		if is_paused:
			active_tween.pause()

func _play_idle() -> void:
	restore_canonical_baseline()
	state_duration = 3.20

	active_tween = create_tween().set_loops()
	var half_dur: float = 1.60
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y - 6.0, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2(1.008, 0.995), half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_cast_bolt() -> void:
	restore_canonical_baseline()
	var prof = SPELL_PROFILES[AnimationState.CAST_BOLT]
	state_duration = prof["duration"]

	active_tween = create_tween()
	# Anticipation backward (+16px, -1.5 deg)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["anticipation_offset"], prof["anticipation_time"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["anticipation_rotation"], prof["anticipation_time"])

	# Rapid forward snap (-32px, +2.5 deg) + cyan flare
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["snap_offset"], prof["snap_time"]).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["snap_rotation"], prof["snap_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.2, 1.8, 2.2), prof["snap_time"])
	active_tween.parallel().tween_callback(Callable(self, "_spawn_bolt_vfx"))

	# Recoil back to baseline
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, prof["recoil_time"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, prof["recoil_time"])

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_cast_orb() -> void:
	restore_canonical_baseline()
	var prof = SPELL_PROFILES[AnimationState.CAST_ORB]
	state_duration = prof["duration"]

	active_tween = create_tween()
	# Float upward (-26px Y, -2.5 deg) + scale expansion
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["float_offset"], prof["float_time"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["float_rotation"], prof["float_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", prof["peak_scale"], prof["float_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.3, 1.3, 1.0), prof["float_time"])
	active_tween.parallel().tween_callback(Callable(self, "_spawn_orb_vfx"))

	# Controlled forward release (+10px X, -10px Y)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["release_offset"], prof["release_time"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["release_rotation"], prof["release_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2(1.02, 1.02), prof["release_time"])

	# Settle back to baseline
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, prof["recoil_time"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, prof["recoil_time"])

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_cast_rift() -> void:
	restore_canonical_baseline()
	var prof = SPELL_PROFILES[AnimationState.CAST_RIFT]
	state_duration = prof["duration"]

	active_tween = create_tween()
	# Heavy summon windup & sink (+22px X, +20px Y, +3.8 deg)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["sink_offset"], prof["windup_time"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["sink_rotation"], prof["windup_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(0.85, 0.70, 1.15), prof["windup_time"])

	# Held pose for 0.40s while rift opens
	active_tween.tween_callback(Callable(self, "_spawn_rift_vfx"))
	active_tween.tween_interval(prof["hold_duration"])

	# Settle back to baseline
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, prof["recoil_time"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, prof["recoil_time"])

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_cast_sweep() -> void:
	restore_canonical_baseline()
	var prof = SPELL_PROFILES[AnimationState.CAST_SWEEP]
	state_duration = prof["duration"]

	active_tween = create_tween()
	# Strong windup (+40px X, -5px Y, -6.2 deg)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["windup_offset"], prof["windup_time"]).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["windup_rotation"], prof["windup_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", prof["windup_scale"], prof["windup_time"])

	# Massive lateral sweep across (-45px X, +5px Y, +5.5 deg)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["sweep_offset"], prof["sweep_time"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["sweep_rotation"], prof["sweep_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", prof["sweep_scale"], prof["sweep_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.35, 1.10, 1.70), prof["sweep_time"])
	active_tween.parallel().tween_callback(Callable(self, "_spawn_sweep_vfx"))

	# Settle back to baseline
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, prof["recoil_time"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, prof["recoil_time"])

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_hit() -> void:
	restore_canonical_baseline()
	state_duration = STATE_DURATIONS[AnimationState.HIT]

	active_tween = create_tween()
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(18.0, -8.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", -3.0, 0.15)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(2.2, 0.6, 0.6), 0.15)

	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, 0.20)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, 0.20)

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_stun() -> void:
	restore_canonical_baseline()
	state_duration = STATE_DURATIONS[AnimationState.STUN]

	active_tween = create_tween()
	# Slump forward and stay
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(-15.0, 15.0), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", -4.5, 0.30)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(0.70, 0.70, 0.90), 0.30)
	active_tween.parallel().tween_callback(func():
		if stun_overlay != null:
			stun_overlay.visible = true
	)

func _play_enraged() -> void:
	restore_canonical_baseline()
	state_duration = STATE_DURATIONS[AnimationState.ENRAGED]
	boss_rect.modulate = Color(1.35, 0.85, 0.85)

	active_tween = create_tween().set_loops()
	var half_dur: float = 0.90
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y - 10.0, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2(1.03, 0.97), half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_ultimate_charge() -> void:
	restore_canonical_baseline()
	state_duration = STATE_DURATIONS[AnimationState.ULTIMATE_CHARGE] # 1.20s
	_set_charge_frame(0)

	active_tween = create_tween()

	# WAD2 Human-Approved 6 Independent Charge Frames (F01 -> F06)
	# Single stable transform across F01..F06 to match IDLE body size & baseline
	boss_rect.position = CHARGE_BASE_POS
	boss_rect.scale = CHARGE_BASE_SCALE

	# Visual duration 1.20s at 1.00x speed (6 frames * 0.20s = 1.20s)

	# F01 (0.00s - 0.20s): Initiate rise & dim overlay
	active_tween.tween_callback(func(): _set_charge_frame(0))
	active_tween.tween_property(dim_overlay, "modulate:a", 0.45, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# F02 (0.20s - 0.40s)
	active_tween.tween_callback(func(): _set_charge_frame(1))
	active_tween.tween_interval(0.20)

	# F03 (0.40s - 0.60s)
	active_tween.tween_callback(func(): _set_charge_frame(2))
	active_tween.tween_property(boss_rect, "modulate", Color(1.30, 1.20, 1.60), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# F04 (0.60s - 0.80s)
	active_tween.tween_callback(func(): _set_charge_frame(3))
	active_tween.tween_property(boss_rect, "modulate", Color(1.50, 1.40, 1.80), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# F05 (0.80s - 1.00s)
	active_tween.tween_callback(func(): _set_charge_frame(4))
	active_tween.tween_property(boss_rect, "modulate", Color(1.70, 1.50, 2.00), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# F06 (1.00s - 1.20s): Peak charge hold
	active_tween.tween_callback(func(): _set_charge_frame(5))
	active_tween.tween_property(boss_rect, "modulate", Color(1.80, 1.60, 2.20), 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_ultimate_release() -> void:
	state_duration = STATE_DURATIONS[AnimationState.ULTIMATE_RELEASE]

	active_tween = create_tween()
	# Frame 4: Anticipation hold (0.12s)
	active_tween.tween_callback(func(): _set_atlas_frame(4))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.08, 1.08), 0.12)

	# Frame 5: Discharge flash (0.15s)
	active_tween.tween_callback(func(): _set_atlas_frame(5))
	active_tween.tween_property(boss_rect, "modulate", Color(2.5, 2.5, 3.0), 0.15)

	# Frame 6: Peak impact (0.25s)
	active_tween.tween_callback(func():
		_set_atlas_frame(6)
		_spawn_sweep_vfx()
	)
	active_tween.tween_property(boss_rect, "modulate", Color(1.8, 1.4, 2.2), 0.25)

	# Frame 7: Follow-through (0.20s)
	active_tween.tween_callback(func(): _set_atlas_frame(7))
	active_tween.tween_interval(0.20)

	# Recovery Phase (0.30s) -> Restores canonical boss texture & baseline
	active_tween.tween_callback(func():
		_set_canonical_boss()
	)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, 0.30)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, 0.30)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, 0.30)
	active_tween.parallel().tween_property(dim_overlay, "modulate:a", 0.0, 0.30)

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_ultimate_full() -> void:
	restore_canonical_baseline()
	state_duration = STATE_DURATIONS[AnimationState.ULTIMATE_FULL] # 3.42s
	_set_charge_frame(0)

	active_tween = create_tween()

	# 1. Charge Phase (2.40s) using 6 independent frames (F01 -> F06)
	active_tween.tween_callback(func(): _set_charge_frame(0))
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y - 20.0, 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(dim_overlay, "modulate:a", 0.45, 0.40)

	active_tween.tween_callback(func(): _set_charge_frame(1))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.04, 1.04), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	active_tween.tween_callback(func(): _set_charge_frame(2))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.07, 1.07), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.30, 1.20, 1.60), 0.40)

	active_tween.tween_callback(func(): _set_charge_frame(3))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.10, 1.10), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.50, 1.40, 1.80), 0.40)

	active_tween.tween_callback(func(): _set_charge_frame(4))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.12, 1.12), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.70, 1.50, 2.00), 0.40)

	active_tween.tween_callback(func(): _set_charge_frame(5))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.10, 1.10), 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.80, 1.60, 2.20), 0.40)

	# 2. Release Phase (0.72s)
	active_tween.tween_callback(func(): _set_atlas_frame(4))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.08, 1.08), 0.12)

	active_tween.tween_callback(func(): _set_atlas_frame(5))
	active_tween.tween_property(boss_rect, "modulate", Color(2.5, 2.5, 3.0), 0.15)

	active_tween.tween_callback(func():
		_set_atlas_frame(6)
		_spawn_sweep_vfx()
	)
	active_tween.tween_property(boss_rect, "modulate", Color(1.8, 1.4, 2.2), 0.25)

	active_tween.tween_callback(func(): _set_atlas_frame(7))
	active_tween.tween_interval(0.20)

	# 3. Recovery Phase (0.30s)
	active_tween.tween_callback(func(): _set_canonical_boss())
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, 0.30)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, 0.30)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, 0.30)
	active_tween.parallel().tween_property(dim_overlay, "modulate:a", 0.0, 0.30)

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _on_animation_finished() -> void:
	if is_compare_casts_active:
		# Wait 0.5s before next compare cast
		compare_timer = 0.50
		return

	if is_loop_enabled:
		play_animation(current_state)
	else:
		if current_state == AnimationState.ULTIMATE_CHARGE:
			# Hold on F06 / remain in ULTIMATE_CHARGE without auto-transitioning
			current_charge_frame = 5
			_set_charge_frame(5)
			elapsed_time = state_duration
		else:
			restore_canonical_baseline()
			play_animation(AnimationState.IDLE)

# ==============================================================================
# SPEED & TRANSPORT CONTROLS
# ==============================================================================

func set_playback_speed(speed: float) -> void:
	playback_speed = clampf(speed, 0.10, 2.00)
	if speed_slider != null and not is_equal_approx(speed_slider.value, playback_speed):
		speed_slider.value = playback_speed
	if speed_label != null:
		speed_label.text = "%.2fx" % playback_speed
	if active_tween != null and active_tween.is_valid():
		active_tween.set_speed_scale(playback_speed)

func get_playback_speed() -> float:
	return playback_speed

func toggle_pause() -> void:
	set_paused(not is_paused)

func set_paused(paused: bool) -> void:
	is_paused = paused
	if btn_pause != null:
		btn_pause.text = "RESUME [Space]" if is_paused else "PAUSE [Space]"
		btn_pause.modulate = Color(1.3, 0.8, 0.3) if is_paused else Color.WHITE
	if active_tween != null and active_tween.is_valid():
		if is_paused:
			active_tween.pause()
		else:
			active_tween.play()

func is_paused_active() -> bool:
	return is_paused

func toggle_loop() -> void:
	set_loop(not is_loop_enabled)

func set_loop(enabled: bool) -> void:
	is_loop_enabled = enabled
	if btn_loop != null:
		btn_loop.text = "LOOP: ON [L]" if is_loop_enabled else "LOOP: OFF [L]"
		btn_loop.modulate = Color(0.4, 1.2, 0.4) if is_loop_enabled else Color.WHITE

func is_loop_active() -> bool:
	return is_loop_enabled

func step_frame(direction: int) -> void:
	# Stop active playback to inspect static frames
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	if current_state == AnimationState.ULTIMATE_CHARGE or current_charge_frame >= 0:
		if current_charge_frame < 0:
			current_charge_frame = 0 if direction >= 0 else 5
		else:
			var next_f: int = current_charge_frame + direction
			if next_f > 5:
				current_charge_frame = 0 if is_loop_enabled else 5
			elif next_f < 0:
				current_charge_frame = 5 if is_loop_enabled else 0
			else:
				current_charge_frame = next_f
		_set_charge_frame(current_charge_frame)
	else:
		if current_atlas_frame < 0:
			current_atlas_frame = 0 if direction >= 0 else 7
		else:
			var next_a: int = current_atlas_frame + direction
			if next_a > 7:
				current_atlas_frame = 0 if is_loop_enabled else 7
			elif next_a < 0:
				current_atlas_frame = 7 if is_loop_enabled else 0
			else:
				current_atlas_frame = next_a
		_set_atlas_frame(current_atlas_frame)

func get_current_atlas_frame() -> int:
	return current_atlas_frame

func get_current_charge_frame() -> int:
	return current_charge_frame

func get_frame_display_text() -> String:
	if current_charge_frame >= 0 and current_charge_frame < stochas_ultimate_charge_frames.size():
		return "Charge Frame %d / 6 (F0%d)" % [current_charge_frame + 1, current_charge_frame + 1]
	if current_atlas_frame >= 0 and current_atlas_frame < stochas_ultimate_frames.size():
		return "Release Atlas Frame %d / 8" % (current_atlas_frame + 1)
	return "Canonical (stochas_boss.png)"

func toggle_motion_path() -> void:
	motion_path_enabled = not motion_path_enabled
	if btn_motion_path != null:
		btn_motion_path.text = "PATH: ON [M]" if motion_path_enabled else "PATH: OFF [M]"
		btn_motion_path.modulate = Color(0.3, 1.0, 1.0) if motion_path_enabled else Color.WHITE
	if motion_path_line != null:
		motion_path_line.visible = motion_path_enabled
		if not motion_path_enabled:
			motion_trail_points.clear()
			motion_path_line.points = PackedVector2Array()

func is_motion_path_active() -> bool:
	return motion_path_enabled

func start_compare_casts() -> void:
	is_compare_casts_active = true
	compare_step_idx = 0
	compare_timer = 0.0
	if btn_compare != null:
		btn_compare.modulate = Color(1.3, 1.1, 0.3)
	_play_next_compare_cast()

func is_compare_casts_running() -> bool:
	return is_compare_casts_active

func _play_next_compare_cast() -> void:
	if compare_step_idx < compare_sequence.size():
		var next_state = compare_sequence[compare_step_idx]
		play_animation(next_state)
	else:
		# Sequence completed
		is_compare_casts_active = false
		if btn_compare != null:
			btn_compare.modulate = Color.WHITE
		restore_canonical_baseline()
		play_animation(AnimationState.IDLE)

func _advance_compare_cast() -> void:
	compare_step_idx += 1
	_play_next_compare_cast()

# ==============================================================================
# BASELINE & FRAME HELPERS
# ==============================================================================

func restore_canonical_baseline() -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	if boss_rect != null:
		boss_rect.position = BOSS_BASE_POS
		boss_rect.rotation = 0.0
		boss_rect.scale = Vector2.ONE
		boss_rect.modulate = Color.WHITE
		_set_canonical_boss()

	if dim_overlay != null:
		dim_overlay.modulate.a = 0.0
	if stun_overlay != null:
		stun_overlay.visible = false
	if boss_ghost_rect != null:
		boss_ghost_rect.visible = false

	_clear_transient_vfx()

func _set_canonical_boss() -> void:
	current_atlas_frame = -1
	current_charge_frame = -1
	if boss_rect != null and canonical_boss_tex != null:
		boss_rect.texture = canonical_boss_tex

func _set_charge_frame(idx: int) -> void:
	current_charge_frame = idx
	current_atlas_frame = -1
	if boss_rect != null:
		var tf: Dictionary = get_frame_transform(idx)
		boss_rect.scale = Vector2(tf["scale"], tf["scale"])
		boss_rect.position = Vector2(tf["x"], tf["y"])
		if idx >= 0 and idx < stochas_ultimate_charge_frames.size():
			boss_rect.texture = stochas_ultimate_charge_frames[idx]
		_apply_current_frame_opacity()
	_update_ghost_overlay()
	queue_gizmo_redraw()

func _set_atlas_frame(idx: int) -> void:
	current_atlas_frame = idx
	current_charge_frame = -1
	if boss_rect != null and idx >= 0 and idx < stochas_ultimate_frames.size():
		boss_rect.texture = stochas_ultimate_frames[idx]

func _clear_transient_vfx() -> void:
	if boss_vfx_container != null:
		for child in boss_vfx_container.get_children():
			child.queue_free()

func _spawn_bolt_vfx() -> void:
	if vfx_bolt_tex == null or boss_vfx_container == null:
		return
	var bolt = TextureRect.new()
	bolt.texture = vfx_bolt_tex
	bolt.size = Vector2(160, 80)
	bolt.position = Vector2(50.0, 240.0)
	bolt.modulate = Color(1.3, 1.8, 2.4, 0.95)
	boss_vfx_container.add_child(bolt)

	var t = create_tween()
	t.set_speed_scale(playback_speed)
	t.tween_property(bolt, "position:x", -280.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(bolt, "modulate:a", 0.0, 0.25)
	t.tween_callback(bolt.queue_free)

func _spawn_orb_vfx() -> void:
	if vfx_orb_tex == null or boss_vfx_container == null:
		return
	var orb = TextureRect.new()
	orb.texture = vfx_orb_tex
	orb.size = Vector2(120, 120)
	orb.position = Vector2(200.0, 150.0)
	orb.modulate = Color(1.4, 1.4, 0.9, 0.95)
	boss_vfx_container.add_child(orb)

	var t = create_tween()
	t.set_speed_scale(playback_speed)
	t.tween_property(orb, "position", Vector2(-150.0, 180.0), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(orb, "scale", Vector2(1.3, 1.3), 0.45)
	t.parallel().tween_property(orb, "modulate:a", 0.0, 0.45)
	t.tween_callback(orb.queue_free)

func _spawn_rift_vfx() -> void:
	if vfx_rift_tex == null or boss_vfx_container == null:
		return
	var rift = TextureRect.new()
	rift.texture = vfx_rift_tex
	rift.size = Vector2(200, 160)
	rift.position = Vector2(-80.0, 360.0)
	rift.modulate = Color(1.2, 0.8, 2.0, 0.0)
	boss_vfx_container.add_child(rift)

	var t = create_tween()
	t.set_speed_scale(playback_speed)
	t.tween_property(rift, "modulate:a", 0.90, 0.20)
	t.tween_interval(0.40)
	t.tween_property(rift, "modulate:a", 0.0, 0.25)
	t.tween_callback(rift.queue_free)

func _spawn_sweep_vfx() -> void:
	if vfx_sweep_tex == null or boss_vfx_container == null:
		return
	var sweep = TextureRect.new()
	sweep.texture = vfx_sweep_tex
	sweep.size = Vector2(380, 220)
	sweep.position = Vector2(-220.0, 180.0)
	sweep.modulate = Color(1.4, 1.0, 2.2, 0.95)
	sweep.scale = Vector2(0.5, 0.5)
	sweep.pivot_offset = Vector2(190.0, 110.0)
	boss_vfx_container.add_child(sweep)

	var t = create_tween()
	t.set_speed_scale(playback_speed)
	t.tween_property(sweep, "scale", Vector2(1.2, 1.2), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(sweep, "rotation_degrees", 25.0, 0.30)
	t.parallel().tween_property(sweep, "modulate:a", 0.0, 0.30)
	t.tween_callback(sweep.queue_free)

# ==============================================================================
# PUBLIC GETTERS FOR HEADLESS TESTING & VERIFICATION
# ==============================================================================

func get_current_state() -> AnimationState:
	return current_state

func get_current_state_name() -> String:
	return STATE_NAMES.get(current_state, "UNKNOWN")

func get_boss_base_position() -> Vector2:
	return BOSS_BASE_POS

func get_boss_position() -> Vector2:
	return boss_rect.position if boss_rect != null else BOSS_BASE_POS

func get_boss_rotation() -> float:
	return boss_rect.rotation_degrees if boss_rect != null else 0.0

func get_boss_scale() -> Vector2:
	return boss_rect.scale if boss_rect != null else Vector2.ONE

func get_boss_modulate() -> Color:
	return boss_rect.modulate if boss_rect != null else Color.WHITE

func get_boss_texture() -> Texture2D:
	return boss_rect.texture if boss_rect != null else null

func get_boss_size() -> Vector2:
	return boss_rect.size if boss_rect != null else BOSS_BASE_SIZE

func get_baseline_y() -> float:
	return BASELINE_Y

func get_spell_profile(state: AnimationState) -> Dictionary:
	return SPELL_PROFILES.get(state, {})

func get_animation_duration(state: AnimationState) -> float:
	return STATE_DURATIONS.get(state, 0.0)

func get_diagnostic_text() -> String:
	var t1 = lbl_diag_state.text if lbl_diag_state != null else ""
	var t2 = lbl_diag_details.text if lbl_diag_details != null else ""
	return t1 + "\n" + t2

func get_ultimate_frames() -> Array[AtlasTexture]:
	return stochas_ultimate_frames

func get_ultimate_charge_frames() -> Array[Texture2D]:
	return stochas_ultimate_charge_frames

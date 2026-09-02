class_name BootSequence
extends Control

## Standalone Production Boot Sequence for Mathos.
## Handles GODOT splash -> Asian School splash -> MATHOS splash -> Application Entry transition.
## Enforces aspect-ratio preservation, resolution safety (1024x600, 1280x720, 1920x1080),
## non-skippable input isolation, and zero save/progression mutation.

signal boot_completed()
signal stage_changed(stage_name: String)

enum Stage {
	IDLE,
	GODOT,
	ASIAN_SCHOOL,
	MATHOS,
	COMPLETED
}

const GODOT_LOGO_PATH: String = "res://assets/branding/godot_logo.png"
const ASIAN_SCHOOL_LOGO_PATH: String = "res://assets/branding/asian_school_logo.png"
const MATHOS_LOGO_PATH: String = "res://assets/branding/mathos_logo_main.png"

const GODOT_BG_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const ASIAN_SCHOOL_BG_COLOR: Color = Color(0.96, 0.97, 0.98, 1.0)
const MATHOS_BG_COLOR: Color = Color(0.06, 0.08, 0.12, 1.0)

const GODOT_WHITE_PRE_HOLD: float = 0.35
const GODOT_FADE_IN: float = 0.35
const GODOT_HOLD: float = 0.80
const GODOT_FADE_OUT: float = 0.30

const ASIAN_SCHOOL_FADE_IN: float = 0.30
const ASIAN_SCHOOL_HOLD: float = 1.40
const ASIAN_SCHOOL_FADE_OUT: float = 0.30

const MATHOS_FADE_IN: float = 0.35
const MATHOS_HOLD: float = 1.65
const MATHOS_FADE_OUT: float = 0.35

var _current_stage: Stage = Stage.IDLE
var _bg_rect: ColorRect = null
var _logo_rect: TextureRect = null
var _fade_overlay: ColorRect = null
var _godot_logo_tex: Texture2D = null
var _asian_school_tex: Texture2D = null
var _mathos_logo_tex: Texture2D = null
var _is_running: bool = false
var _active_tween: Tween = null
var _time_scale: float = 1.0

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	_ensure_nodes()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_UNPARENTED or what == NOTIFICATION_EXIT_TREE:
		_is_running = false
		if _active_tween != null and _active_tween.is_valid():
			_active_tween.kill()

func _ensure_nodes() -> void:
	if _bg_rect == null:
		_bg_rect = get_node_or_null("BackgroundRect") as ColorRect
		if _bg_rect == null:
			_bg_rect = ColorRect.new()
			_bg_rect.name = "BackgroundRect"
			_bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_bg_rect.mouse_filter = MOUSE_FILTER_IGNORE
			_bg_rect.color = GODOT_BG_COLOR
			add_child(_bg_rect)

	var center: CenterContainer = get_node_or_null("CenterContainer") as CenterContainer
	if center == null:
		center = CenterContainer.new()
		center.name = "CenterContainer"
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(center)

	var margin: MarginContainer = center.get_node_or_null("MarginContainer") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "MarginContainer"
		margin.mouse_filter = MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 64)
		margin.add_theme_constant_override("margin_right", 64)
		margin.add_theme_constant_override("margin_top", 48)
		margin.add_theme_constant_override("margin_bottom", 48)
		center.add_child(margin)

	if _logo_rect == null:
		_logo_rect = margin.get_node_or_null("LogoTextureRect") as TextureRect
		if _logo_rect == null:
			_logo_rect = TextureRect.new()
			_logo_rect.name = "LogoTextureRect"
			_logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_logo_rect.custom_minimum_size = Vector2(640, 258)
			_logo_rect.mouse_filter = MOUSE_FILTER_IGNORE
			margin.add_child(_logo_rect)

	if _fade_overlay == null:
		_fade_overlay = get_node_or_null("FadeOverlay") as ColorRect
		if _fade_overlay == null:
			_fade_overlay = ColorRect.new()
			_fade_overlay.name = "FadeOverlay"
			_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_fade_overlay.mouse_filter = MOUSE_FILTER_IGNORE
			_fade_overlay.color = Color(1.0, 1.0, 1.0, 1.0)
			add_child(_fade_overlay)

	if _godot_logo_tex == null and ResourceLoader.exists(GODOT_LOGO_PATH):
		_godot_logo_tex = load(GODOT_LOGO_PATH) as Texture2D

	if _asian_school_tex == null and ResourceLoader.exists(ASIAN_SCHOOL_LOGO_PATH):
		_asian_school_tex = load(ASIAN_SCHOOL_LOGO_PATH) as Texture2D

	if _mathos_logo_tex == null and ResourceLoader.exists(MATHOS_LOGO_PATH):
		_mathos_logo_tex = load(MATHOS_LOGO_PATH) as Texture2D

func start_boot_sequence(fast_time_scale: float = 1.0) -> void:
	if _is_running:
		return
	_ensure_nodes()
	_is_running = true
	_time_scale = clamp(fast_time_scale, 0.01, 200.0)
	_show_godot_stage()

func advance_to_next_stage() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()

	if _current_stage == Stage.IDLE or _current_stage == Stage.GODOT:
		_show_asian_school_stage()
	elif _current_stage == Stage.ASIAN_SCHOOL:
		_show_mathos_stage()
	elif _current_stage == Stage.MATHOS:
		_show_completed_stage()

func skip_sequence() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_show_completed_stage()

func _show_godot_stage() -> void:
	_current_stage = Stage.GODOT
	stage_changed.emit("GODOT")
	_bg_rect.color = GODOT_BG_COLOR
	if _logo_rect != null and _godot_logo_tex != null:
		_logo_rect.texture = _godot_logo_tex
		_logo_rect.custom_minimum_size = Vector2(640, 258)

	# First-frame contract: fade overlay is fully opaque white (alpha = 1.0)
	_fade_overlay.color = Color(1.0, 1.0, 1.0, 1.0)

	var g_pre_hold: float = GODOT_WHITE_PRE_HOLD / _time_scale
	var g_in: float = GODOT_FADE_IN / _time_scale
	var g_hold: float = GODOT_HOLD / _time_scale
	var g_out: float = GODOT_FADE_OUT / _time_scale

	# 1. Pure White Pre-Hold (alpha = 1.0, logo completely hidden behind overlay)
	if g_pre_hold > 0.0 and is_inside_tree() and get_tree() != null:
		await get_tree().create_timer(g_pre_hold).timeout
	if _current_stage != Stage.GODOT:
		return

	# 2. Fade In (alpha 1.0 -> 0.0)
	_active_tween = create_tween()
	_active_tween.tween_property(_fade_overlay, "color:a", 0.0, g_in)
	await _active_tween.finished

	if _current_stage != Stage.GODOT:
		return

	# 3. Hold Fully Visible
	if g_hold > 0.0 and is_inside_tree() and get_tree() != null:
		await get_tree().create_timer(g_hold).timeout
	if _current_stage != Stage.GODOT:
		return

	# 4. Fade Out (interpolating to Asian School background color)
	_active_tween = create_tween()
	_active_tween.tween_property(_fade_overlay, "color", ASIAN_SCHOOL_BG_COLOR, g_out)
	await _active_tween.finished

	if _current_stage == Stage.GODOT:
		_show_asian_school_stage()

func _show_asian_school_stage() -> void:
	_current_stage = Stage.ASIAN_SCHOOL
	stage_changed.emit("ASIAN_SCHOOL")
	_bg_rect.color = ASIAN_SCHOOL_BG_COLOR
	if _logo_rect != null and _asian_school_tex != null:
		_logo_rect.texture = _asian_school_tex
		_logo_rect.custom_minimum_size = Vector2(680, 250)
	_fade_overlay.color = ASIAN_SCHOOL_BG_COLOR

	var as_in: float = ASIAN_SCHOOL_FADE_IN / _time_scale
	var as_hold: float = ASIAN_SCHOOL_HOLD / _time_scale
	var as_out: float = ASIAN_SCHOOL_FADE_OUT / _time_scale

	_active_tween = create_tween()
	_active_tween.tween_property(_fade_overlay, "color:a", 0.0, as_in)
	await _active_tween.finished

	if _current_stage != Stage.ASIAN_SCHOOL:
		return

	if as_hold > 0.0 and is_inside_tree() and get_tree() != null:
		await get_tree().create_timer(as_hold).timeout
	if _current_stage != Stage.ASIAN_SCHOOL:
		return

	_active_tween = create_tween()
	_active_tween.tween_property(_fade_overlay, "color", MATHOS_BG_COLOR, as_out)
	await _active_tween.finished

	if _current_stage == Stage.ASIAN_SCHOOL:
		_show_mathos_stage()

func _show_mathos_stage() -> void:
	_current_stage = Stage.MATHOS
	stage_changed.emit("MATHOS")
	_bg_rect.color = MATHOS_BG_COLOR
	if _logo_rect != null and _mathos_logo_tex != null:
		_logo_rect.texture = _mathos_logo_tex
		_logo_rect.custom_minimum_size = Vector2(500, 240)

	var m_in: float = MATHOS_FADE_IN / _time_scale
	var m_hold: float = MATHOS_HOLD / _time_scale
	var m_out: float = MATHOS_FADE_OUT / _time_scale

	_active_tween = create_tween()
	_active_tween.tween_property(_fade_overlay, "color:a", 0.0, m_in)
	await _active_tween.finished

	if _current_stage != Stage.MATHOS:
		return

	if m_hold > 0.0 and is_inside_tree() and get_tree() != null:
		await get_tree().create_timer(m_hold).timeout
	if _current_stage != Stage.MATHOS:
		return

	_active_tween = create_tween()
	_active_tween.tween_property(_fade_overlay, "color:a", 1.0, m_out)
	await _active_tween.finished

	if _current_stage == Stage.MATHOS:
		_show_completed_stage()

func _show_completed_stage() -> void:
	_current_stage = Stage.COMPLETED
	_is_running = false
	visible = false
	stage_changed.emit("COMPLETED")
	boot_completed.emit()

func get_current_stage() -> Stage:
	return _current_stage

func is_running() -> bool:
	return _is_running

func get_godot_texture() -> Texture2D:
	_ensure_nodes()
	return _godot_logo_tex

func get_asian_school_texture() -> Texture2D:
	_ensure_nodes()
	return _asian_school_tex

func get_mathos_texture() -> Texture2D:
	_ensure_nodes()
	return _mathos_logo_tex

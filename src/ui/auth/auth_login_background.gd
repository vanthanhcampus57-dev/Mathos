class_name AuthLoginBackground
extends Control

## Standalone Animated Auth/Login Academy Background Component (Visual Quality V3).
## Renders clean Academy background, 4-corner perspective-warped & top-pinned swaying banners,
## procedural soft radial crystal glow, irregular fog cluster pool with fallback detection,
## and magic light particles without ColorRect boxes.
## Enforces zero save/progress mutation, zero per-frame resource allocations, and edge safety.

# Default Constants
const BG_ASSET_PATH: String = "res://assets/backgrounds/auth/login_academy_bg_clean.png"
const FOG_FALLBACK_PATH: String = "res://assets/backgrounds/auth/login_ground_fog.png"
const BANNER_ASSET_PATH: String = "res://assets/backgrounds/auth/login_academy_banner.png"
const FOG_CLUSTERS_DIR: String = "res://assets/backgrounds/auth/fog_clusters/"
const PARTICLES_DIR: String = "res://assets/backgrounds/auth/particles/"

# Shader for 4-Corner Quad Warp + Banner Top-Pin Sway + Brightness & Tint
const BANNER_SHADER_CODE: String = """shader_type canvas_item;

uniform float sway_amplitude : hint_range(0.0, 30.0) = 3.5;
uniform float sway_speed : hint_range(0.0, 3.0) = 0.45;
uniform float ripple_amplitude : hint_range(0.0, 10.0) = 0.8;
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;
uniform float brightness : hint_range(0.4, 1.6) = 1.0;
uniform float banner_opacity : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform vec2 tl_offset = vec2(0.0, 0.0);
uniform vec2 tr_offset = vec2(0.0, 0.0);
uniform vec2 bl_offset = vec2(0.0, 0.0);
uniform vec2 br_offset = vec2(0.0, 0.0);

void vertex() {
	// 1. Four-corner quad warp deformation
	vec2 quad_warp = mix(mix(tl_offset, tr_offset, UV.x), mix(bl_offset, br_offset, UV.x), UV.y);
	VERTEX += quad_warp;

	// 2. Top 12% is fixed (rod attachment protection)
	float pin_factor = smoothstep(0.12, 0.95, UV.y);
	float t = TIME * sway_speed + time_offset;
	float sway = sin(t + VERTEX.y * 0.005) * sway_amplitude * pin_factor;
	float ripple = sin(t * 2.3 + VERTEX.y * 0.02) * ripple_amplitude * pin_factor;
	VERTEX.x += sway + ripple;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	tex_color.rgb *= brightness;
	tex_color.rgb *= tint_color.rgb;
	tex_color.a *= banner_opacity;
	COLOR = tex_color;
}
"""

# Shader for Soft Radial Crystal Glow (No ColorRect Boxes!)
const CRYSTAL_GLOW_SHADER_CODE: String = """shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.2, 0.85, 1.0, 1.0);
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	float alpha = smoothstep(0.5, 0.0, dist) * pulse_intensity;
	COLOR = vec4(glow_color.rgb, glow_color.a * alpha);
}
"""

# Default Parameter Values
const DEFAULT_FOG_MASTER_OPACITY: float = 0.85
const DEFAULT_FOG_CLUSTER_COUNT: int = 8
const DEFAULT_FOG_GLOBAL_SPEED: float = 0.50
const DEFAULT_FOG_DRIFT_RANGE: float = 120.0
const DEFAULT_FOG_SCALE_MIN: float = 0.8
const DEFAULT_FOG_SCALE_MAX: float = 1.6
const DEFAULT_FOG_BREATHING: float = 0.04
const DEFAULT_FOG_SEED: int = 1337
const DEFAULT_FOG_DEPTH_SPREAD: float = 0.5
const DEFAULT_FOG_FG_ENABLE: bool = true
const DEFAULT_FOG_MG_ENABLE: bool = true

const DEFAULT_BANNER_A_VISIBLE: bool = true
const DEFAULT_BANNER_B_VISIBLE: bool = true
const DEFAULT_BANNER_BRIGHTNESS: float = 1.00
const DEFAULT_BANNER_OPACITY: float = 1.00
const DEFAULT_BANNER_SWAY: float = 3.5
const DEFAULT_BANNER_SPEED: float = 0.45
const DEFAULT_BANNER_RIPPLE: float = 0.8

const DEFAULT_CRYSTAL_MASTER: float = 0.65
const DEFAULT_CRYSTAL_PULSE_AMT: float = 0.35
const DEFAULT_CRYSTAL_PULSE_SPEED: float = 0.6

const DEFAULT_PARTICLE_TYPE: String = "Mixed"
const DEFAULT_DUST_ENABLE: bool = true
const DEFAULT_DUST_COUNT: int = 16
const DEFAULT_DUST_OPACITY: float = 0.35
const DEFAULT_DUST_SCALE_MIN: float = 1.0
const DEFAULT_DUST_SCALE_MAX: float = 2.5
const DEFAULT_DUST_TWINKLE_AMT: float = 0.5
const DEFAULT_DUST_TWINKLE_SPD: float = 1.0
const DEFAULT_DUST_DRIFT_SPD: float = 18.0

# Node References
var _bg_rect: TextureRect = null
var _crystal_container: Control = null
var _crystal_glow_nodes: Array[ColorRect] = []
var _crystal_materials: Array[ShaderMaterial] = []
var _banner_container: Control = null
var _banner_a: TextureRect = null
var _banner_b: TextureRect = null
var _banner_mat_a: ShaderMaterial = null
var _banner_mat_b: ShaderMaterial = null
var _fog_container: Control = null
var _fog_cluster_nodes: Array[TextureRect] = []
var _fog_cluster_data: Array[Dictionary] = []
var _dust_particles: CPUParticles2D = null

# Shared Loaded Textures & Shaders
var _bg_texture: Texture2D = null
var _fog_fallback_texture: Texture2D = null
var _banner_texture: Texture2D = null
var _fog_cluster_textures: Array[Texture2D] = []
var _particle_textures: Array[Texture2D] = []
var _banner_shader: Shader = null
var _crystal_shader: Shader = null

# Pack Installation Status
var fog_asset_pack_installed: bool = false
var particle_asset_pack_installed: bool = false

# State Variables
var _is_playing: bool = true
var _accum_time: float = 0.0

# Adjustable Fog Parameters
var fog_master_opacity: float = DEFAULT_FOG_MASTER_OPACITY
var fog_cluster_count: int = DEFAULT_FOG_CLUSTER_COUNT
var fog_global_speed: float = DEFAULT_FOG_GLOBAL_SPEED
var fog_drift_range: float = DEFAULT_FOG_DRIFT_RANGE
var fog_scale_min: float = DEFAULT_FOG_SCALE_MIN
var fog_scale_max: float = DEFAULT_FOG_SCALE_MAX
var fog_breathing: float = DEFAULT_FOG_BREATHING
var fog_seed: int = DEFAULT_FOG_SEED
var fog_depth_spread: float = DEFAULT_FOG_DEPTH_SPREAD
var fog_fg_enabled: bool = DEFAULT_FOG_FG_ENABLE
var fog_mg_enabled: bool = DEFAULT_FOG_MG_ENABLE

# Adjustable Banner Parameters
var banner_a_visible: bool = DEFAULT_BANNER_A_VISIBLE
var banner_b_visible: bool = DEFAULT_BANNER_B_VISIBLE
var banner_brightness: float = DEFAULT_BANNER_BRIGHTNESS
var banner_opacity: float = DEFAULT_BANNER_OPACITY
var banner_sway: float = DEFAULT_BANNER_SWAY
var banner_speed: float = DEFAULT_BANNER_SPEED
var banner_ripple: float = DEFAULT_BANNER_RIPPLE

# Banner Four-Corner Quad Warp Offsets (TL, TR, BL, BR Vector2s)
var banner_a_warp_tl: Vector2 = Vector2.ZERO
var banner_a_warp_tr: Vector2 = Vector2.ZERO
var banner_a_warp_bl: Vector2 = Vector2.ZERO
var banner_a_warp_br: Vector2 = Vector2.ZERO

var banner_b_warp_tl: Vector2 = Vector2.ZERO
var banner_b_warp_tr: Vector2 = Vector2.ZERO
var banner_b_warp_bl: Vector2 = Vector2.ZERO
var banner_b_warp_br: Vector2 = Vector2.ZERO

# Adjustable Crystal Glow Parameters
var crystal_master_opacity: float = DEFAULT_CRYSTAL_MASTER
var crystal_pulse_amount: float = DEFAULT_CRYSTAL_PULSE_AMT
var crystal_pulse_speed: float = DEFAULT_CRYSTAL_PULSE_SPEED

# Adjustable Particle Parameters
var particle_type: String = DEFAULT_PARTICLE_TYPE
var dust_enabled: bool = DEFAULT_DUST_ENABLE
var dust_count: int = DEFAULT_DUST_COUNT
var dust_opacity: float = DEFAULT_DUST_OPACITY
var dust_scale_min: float = DEFAULT_DUST_SCALE_MIN
var dust_scale_max: float = DEFAULT_DUST_SCALE_MAX
var dust_twinkle_amount: float = DEFAULT_DUST_TWINKLE_AMT
var dust_twinkle_speed: float = DEFAULT_DUST_TWINKLE_SPD
var dust_drift_speed: float = DEFAULT_DUST_DRIFT_SPD

func _ready() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if _bg_rect != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_load_resources()
	_build_layer_hierarchy()
	reset_defaults()

func _process(delta: float) -> void:
	if _is_playing:
		_accum_time += delta
	_update_animations(_accum_time)

func _load_resources() -> void:
	if _bg_texture == null:
		_bg_texture = _load_texture_safe(BG_ASSET_PATH)
	if _fog_fallback_texture == null:
		_fog_fallback_texture = _load_texture_safe(FOG_FALLBACK_PATH)
	if _banner_texture == null:
		_banner_texture = _load_texture_safe(BANNER_ASSET_PATH)

	# Scan for WAD2 fog clusters
	_fog_cluster_textures.clear()
	fog_asset_pack_installed = false
	var fog_dir_access: DirAccess = DirAccess.open(FOG_CLUSTERS_DIR)
	if fog_dir_access != null:
		fog_dir_access.list_dir_begin()
		var fname: String = fog_dir_access.get_next()
		while fname != "":
			if not fog_dir_access.current_is_dir() and fname.ends_with(".png"):
				var tex: Texture2D = _load_texture_safe(FOG_CLUSTERS_DIR + fname)
				if tex != null:
					_fog_cluster_textures.append(tex)
			fname = fog_dir_access.get_next()
		fog_dir_access.list_dir_end()
		if not _fog_cluster_textures.is_empty():
			fog_asset_pack_installed = true

	# Scan for WAD2 particle textures
	_particle_textures.clear()
	particle_asset_pack_installed = false
	var part_dir_access: DirAccess = DirAccess.open(PARTICLES_DIR)
	if part_dir_access != null:
		part_dir_access.list_dir_begin()
		var pfname: String = part_dir_access.get_next()
		while pfname != "":
			if not part_dir_access.current_is_dir() and pfname.ends_with(".png"):
				var ptex: Texture2D = _load_texture_safe(PARTICLES_DIR + pfname)
				if ptex != null:
					_particle_textures.append(ptex)
			pfname = part_dir_access.get_next()
		part_dir_access.list_dir_end()
		if not _particle_textures.is_empty():
			particle_asset_pack_installed = true

	if _banner_shader == null:
		_banner_shader = Shader.new()
		_banner_shader.code = BANNER_SHADER_CODE

	if _crystal_shader == null:
		_crystal_shader = Shader.new()
		_crystal_shader.code = CRYSTAL_GLOW_SHADER_CODE

func _load_texture_safe(p: String) -> Texture2D:
	if ResourceLoader.exists(p) or FileAccess.file_exists(p):
		var tex: Texture2D = load(p) as Texture2D
		if tex != null:
			return tex
	var global_p: String = ProjectSettings.globalize_path(p)
	if FileAccess.file_exists(global_p):
		var tex: Texture2D = load(global_p) as Texture2D
		if tex != null:
			return tex
	return null

func _build_layer_hierarchy() -> void:
	# 1. STATIC ACADEMY BG
	_bg_rect = TextureRect.new()
	_bg_rect.name = "AcademyBackground"
	_bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.texture = _bg_texture
	_bg_rect.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	# 2. CRYSTAL GLOW CONTAINER (Soft Radial Shaders — ZERO ColorRect Debug Blocks!)
	_crystal_container = Control.new()
	_crystal_container.name = "CrystalGlowContainer"
	_crystal_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_crystal_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_crystal_container)

	var crystal_positions: Array[Vector2] = [
		Vector2(0.12, 0.32),
		Vector2(0.24, 0.42),
		Vector2(0.31, 0.58),
		Vector2(0.08, 0.52)
	]
	_crystal_glow_nodes.clear()
	_crystal_materials.clear()
	for i in range(crystal_positions.size()):
		var glow: ColorRect = ColorRect.new()
		glow.name = "CrystalGlow_%d" % i
		glow.custom_minimum_size = Vector2(64, 64)
		glow.mouse_filter = MOUSE_FILTER_IGNORE

		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = _crystal_shader
		mat.set_shader_parameter("glow_color", Color(0.2, 0.85, 1.0, 0.8))
		mat.set_shader_parameter("pulse_intensity", 0.5)

		glow.material = mat
		_crystal_container.add_child(glow)
		_crystal_glow_nodes.append(glow)
		_crystal_materials.append(mat)

	# 3. BANNERS CONTAINER
	_banner_container = Control.new()
	_banner_container.name = "BannerContainer"
	_banner_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_banner_container)

	_banner_mat_a = ShaderMaterial.new()
	_banner_mat_a.shader = _banner_shader
	_banner_mat_a.set_shader_parameter("time_offset", 0.0)

	_banner_a = TextureRect.new()
	_banner_a.name = "Banner_A"
	_banner_a.texture = _banner_texture
	_banner_a.material = _banner_mat_a
	_banner_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_banner_a.custom_minimum_size = Vector2(130, 260)
	_banner_a.mouse_filter = MOUSE_FILTER_IGNORE
	_banner_container.add_child(_banner_a)

	_banner_mat_b = ShaderMaterial.new()
	_banner_mat_b.shader = _banner_shader
	_banner_mat_b.set_shader_parameter("time_offset", 1.85)

	_banner_b = TextureRect.new()
	_banner_b.name = "Banner_B"
	_banner_b.texture = _banner_texture
	_banner_b.material = _banner_mat_b
	_banner_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_banner_b.custom_minimum_size = Vector2(110, 220)
	_banner_b.mouse_filter = MOUSE_FILTER_IGNORE
	_banner_container.add_child(_banner_b)

	# 4. GROUND FOG CLUSTER CONTAINER
	_fog_container = Control.new()
	_fog_container.name = "GroundFogClusterContainer"
	_fog_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fog_container.mouse_filter = MOUSE_FILTER_IGNORE
	_fog_container.clip_contents = true
	add_child(_fog_container)

	_rebuild_fog_clusters()

	# 5. MAGIC LIGHT PARTICLES (CPUParticles2D — ZERO ColorRect Boxes!)
	_dust_particles = CPUParticles2D.new()
	_dust_particles.name = "MagicLightParticles"
	_dust_particles.amount = DEFAULT_DUST_COUNT
	_dust_particles.lifetime = 4.0
	_dust_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust_particles.emission_rect_extents = Vector2(250, 200)
	_dust_particles.gravity = Vector2(0, -8.0)
	_dust_particles.direction = Vector2(-0.2, -1.0)
	_dust_particles.spread = 25.0
	_dust_particles.initial_velocity_min = 10.0
	_dust_particles.initial_velocity_max = 25.0
	_dust_particles.scale_amount_min = DEFAULT_DUST_SCALE_MIN
	_dust_particles.scale_amount_max = DEFAULT_DUST_SCALE_MAX
	_dust_particles.color = Color(0.4, 0.9, 1.0, 0.4)
	add_child(_dust_particles)

func _rebuild_fog_clusters() -> void:
	if _fog_container == null:
		return

	# Clear existing cluster nodes
	for node in _fog_cluster_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_fog_cluster_nodes.clear()
	_fog_cluster_data.clear()

	var count: int = clampi(fog_cluster_count, 1, 25)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = fog_seed

	for i in range(count):
		var cluster_rect: TextureRect = TextureRect.new()
		cluster_rect.name = "FogCluster_%d" % i
		cluster_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cluster_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		cluster_rect.mouse_filter = MOUSE_FILTER_IGNORE

		# Assign texture from pool if available, or fallback
		if fog_asset_pack_installed and not _fog_cluster_textures.is_empty():
			var tex_idx: int = rng.randi() % _fog_cluster_textures.size()
			cluster_rect.texture = _fog_cluster_textures[tex_idx]
		else:
			cluster_rect.texture = _fog_fallback_texture

		_fog_container.add_child(cluster_rect)
		_fog_cluster_nodes.append(cluster_rect)

		# Randomize cluster dynamic data
		var base_pos_norm: Vector2 = Vector2(
			rng.randf_range(-0.1, 0.9),
			rng.randf_range(0.4, 0.9)
		)
		var base_scale: float = rng.randf_range(fog_scale_min, fog_scale_max)
		var phase: float = rng.randf_range(0.0, TAU)
		var speed_mult: float = rng.randf_range(0.7, 1.3)
		var is_fg: bool = (i % 2 == 0)

		_fog_cluster_data.append({
			"base_pos_norm": base_pos_norm,
			"base_scale": base_scale,
			"phase": phase,
			"speed_mult": speed_mult,
			"is_fg": is_fg
		})

func reset_defaults() -> void:
	fog_master_opacity = DEFAULT_FOG_MASTER_OPACITY
	fog_cluster_count = DEFAULT_FOG_CLUSTER_COUNT
	fog_global_speed = DEFAULT_FOG_GLOBAL_SPEED
	fog_drift_range = DEFAULT_FOG_DRIFT_RANGE
	fog_scale_min = DEFAULT_FOG_SCALE_MIN
	fog_scale_max = DEFAULT_FOG_SCALE_MAX
	fog_breathing = DEFAULT_FOG_BREATHING
	fog_seed = DEFAULT_FOG_SEED
	fog_depth_spread = DEFAULT_FOG_DEPTH_SPREAD
	fog_fg_enabled = DEFAULT_FOG_FG_ENABLE
	fog_mg_enabled = DEFAULT_FOG_MG_ENABLE

	banner_a_visible = DEFAULT_BANNER_A_VISIBLE
	banner_b_visible = DEFAULT_BANNER_B_VISIBLE
	banner_brightness = DEFAULT_BANNER_BRIGHTNESS
	banner_opacity = DEFAULT_BANNER_OPACITY
	banner_sway = DEFAULT_BANNER_SWAY
	banner_speed = DEFAULT_BANNER_SPEED
	banner_ripple = DEFAULT_BANNER_RIPPLE

	reset_banner_a_warp()
	reset_banner_b_warp()

	crystal_master_opacity = DEFAULT_CRYSTAL_MASTER
	crystal_pulse_amount = DEFAULT_CRYSTAL_PULSE_AMT
	crystal_pulse_speed = DEFAULT_CRYSTAL_PULSE_SPEED

	particle_type = DEFAULT_PARTICLE_TYPE
	dust_enabled = DEFAULT_DUST_ENABLE
	dust_count = DEFAULT_DUST_COUNT
	dust_opacity = DEFAULT_DUST_OPACITY
	dust_scale_min = DEFAULT_DUST_SCALE_MIN
	dust_scale_max = DEFAULT_DUST_SCALE_MAX
	dust_twinkle_amount = DEFAULT_DUST_TWINKLE_AMT
	dust_twinkle_speed = DEFAULT_DUST_TWINKLE_SPD
	dust_drift_speed = DEFAULT_DUST_DRIFT_SPD

	_rebuild_fog_clusters()
	_update_animations(_accum_time)

func reset_banner_a_warp() -> void:
	banner_a_warp_tl = Vector2.ZERO
	banner_a_warp_tr = Vector2.ZERO
	banner_a_warp_bl = Vector2.ZERO
	banner_a_warp_br = Vector2.ZERO

func reset_banner_b_warp() -> void:
	banner_b_warp_tl = Vector2.ZERO
	banner_b_warp_tr = Vector2.ZERO
	banner_b_warp_bl = Vector2.ZERO
	banner_b_warp_br = Vector2.ZERO

func set_fog_cluster_count(cnt: int) -> void:
	fog_cluster_count = clampi(cnt, 1, 25)
	_rebuild_fog_clusters()

func set_fog_seed(sd: int) -> void:
	fog_seed = sd
	_rebuild_fog_clusters()

func _update_animations(time: float) -> void:
	var vp_size: Vector2 = size if size.x > 0 and size.y > 0 else Vector2(1280, 720)

	# 1. FOG CLUSTERS ANIMATION (Independent Bounded Motion)
	for i in range(_fog_cluster_nodes.size()):
		if i >= _fog_cluster_data.size():
			continue
		var cluster_node: TextureRect = _fog_cluster_nodes[i]
		var data: Dictionary = _fog_cluster_data[i]

		var is_fg: bool = data["is_fg"]
		var active: bool = (is_fg and fog_fg_enabled) or ((not is_fg) and fog_mg_enabled)
		cluster_node.visible = active
		if not active:
			continue

		var speed: float = fog_global_speed * data["speed_mult"]
		var phase: float = data["phase"]

		# Independent sine/cosine drift & breathing
		var drift_x: float = sin(time * speed * 0.4 + phase) * fog_drift_range
		var drift_y: float = cos(time * speed * 0.3 + phase * 1.5) * (fog_drift_range * 0.25)
		var scale_delta: float = sin(time * speed * 0.8 + phase) * fog_breathing

		var curr_scale: float = clampf(data["base_scale"] + scale_delta, 0.4, 4.0)
		var base_pos: Vector2 = Vector2(data["base_pos_norm"].x * vp_size.x, data["base_pos_norm"].y * vp_size.y)
		var pos: Vector2 = base_pos + Vector2(drift_x, drift_y)

		var base_w: float = 600.0 * curr_scale
		var base_h: float = 300.0 * curr_scale

		cluster_node.custom_minimum_size = Vector2(base_w, base_h)
		cluster_node.size = Vector2(base_w, base_h)
		cluster_node.position = pos

		# Calculate opacity with layer depth spread
		var layer_opacity: float = (0.28 if is_fg else 0.16) * fog_master_opacity
		var alpha: float = clampf(layer_opacity * (1.0 + sin(time * speed * 0.6 + phase) * 0.15), 0.0, 1.0)
		cluster_node.modulate = Color(1.0, 1.0, 1.0, alpha)

	# 2. BANNERS SHADER, WARP & POSITIONS
	if _banner_a != null:
		_banner_a.visible = banner_a_visible
		_banner_a.position = Vector2(vp_size.x * 0.16, vp_size.y * 0.22)
		if _banner_mat_a != null:
			_banner_mat_a.set_shader_parameter("sway_amplitude", banner_sway)
			_banner_mat_a.set_shader_parameter("sway_speed", banner_speed)
			_banner_mat_a.set_shader_parameter("ripple_amplitude", banner_ripple)
			_banner_mat_a.set_shader_parameter("brightness", banner_brightness)
			_banner_mat_a.set_shader_parameter("banner_opacity", banner_opacity)
			_banner_mat_a.set_shader_parameter("tl_offset", banner_a_warp_tl)
			_banner_mat_a.set_shader_parameter("tr_offset", banner_a_warp_tr)
			_banner_mat_a.set_shader_parameter("bl_offset", banner_a_warp_bl)
			_banner_mat_a.set_shader_parameter("br_offset", banner_a_warp_br)

	if _banner_b != null:
		_banner_b.visible = banner_b_visible
		_banner_b.position = Vector2(vp_size.x * 0.34, vp_size.y * 0.26)
		if _banner_mat_b != null:
			_banner_mat_b.set_shader_parameter("sway_amplitude", banner_sway * 0.85)
			_banner_mat_b.set_shader_parameter("sway_speed", banner_speed * 1.1)
			_banner_mat_b.set_shader_parameter("ripple_amplitude", banner_ripple * 0.9)
			_banner_mat_b.set_shader_parameter("brightness", banner_brightness)
			_banner_mat_b.set_shader_parameter("banner_opacity", banner_opacity)
			_banner_mat_b.set_shader_parameter("tl_offset", banner_b_warp_tl)
			_banner_mat_b.set_shader_parameter("tr_offset", banner_b_warp_tr)
			_banner_mat_b.set_shader_parameter("bl_offset", banner_b_warp_bl)
			_banner_mat_b.set_shader_parameter("br_offset", banner_b_warp_br)

	# 3. SOFT RADIAL CRYSTAL GLOW PULSES (Phase Offsets — Zero Debug ColorRect Boxes!)
	var crystal_positions: Array[Vector2] = [
		Vector2(vp_size.x * 0.12 - 32, vp_size.y * 0.32 - 32),
		Vector2(vp_size.x * 0.24 - 32, vp_size.y * 0.42 - 32),
		Vector2(vp_size.x * 0.31 - 32, vp_size.y * 0.58 - 32),
		Vector2(vp_size.x * 0.08 - 32, vp_size.y * 0.52 - 32)
	]
	var phase_offsets: Array[float] = [0.0, 1.25, 2.7, 4.1]

	for i in range(_crystal_glow_nodes.size()):
		if i < crystal_positions.size() and i < _crystal_materials.size():
			var glow: ColorRect = _crystal_glow_nodes[i]
			var mat: ShaderMaterial = _crystal_materials[i]
			glow.position = crystal_positions[i]
			var pulse: float = sin(time * crystal_pulse_speed * TAU + phase_offsets[i]) * 0.5 + 0.5
			var pulse_val: float = crystal_master_opacity * (1.0 - crystal_pulse_amount + crystal_pulse_amount * pulse)
			mat.set_shader_parameter("pulse_intensity", pulse_val)

	# 4. MAGIC LIGHT PARTICLES (Zero ColorRect Boxes!)
	if _dust_particles != null:
		_dust_particles.emitting = dust_enabled and _is_playing
		_dust_particles.visible = dust_enabled
		_dust_particles.position = Vector2(vp_size.x * 0.22, vp_size.y * 0.55)
		_dust_particles.amount = max(1, dust_count)
		_dust_particles.scale_amount_min = dust_scale_min
		_dust_particles.scale_amount_max = dust_scale_max
		_dust_particles.initial_velocity_min = dust_drift_speed * 0.6
		_dust_particles.initial_velocity_max = dust_drift_speed * 1.3
		_dust_particles.color = Color(0.4, 0.9, 1.0, dust_opacity)

func set_playing(playing: bool) -> void:
	_is_playing = playing
	if _dust_particles != null:
		_dust_particles.emitting = playing and dust_enabled

func is_playing() -> bool:
	return _is_playing

func get_bg_texture() -> Texture2D:
	_load_resources()
	return _bg_texture

func get_fog_texture() -> Texture2D:
	_load_resources()
	return _fog_fallback_texture

func get_banner_texture() -> Texture2D:
	_load_resources()
	return _banner_texture

func get_fog_cluster_count() -> int:
	return _fog_cluster_nodes.size()

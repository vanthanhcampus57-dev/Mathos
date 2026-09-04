class_name AuthLoginBackground
extends Control

## Real Asset-Backed Animated Auth/Login Academy Background Component (V4 Asset Wiring).
## Renders clean Academy background, 4-corner perspective-warped & top-pinned swaying banners
## (login_banner_a.png & login_banner_b.png with nearest pixel filtering),
## soft radial crystal glow, irregular fog cluster & ribbon pool system (15 textures with fog tint/brightness/saturation shader),
## and pixel-art magic particles (8 textures: stars, orbs, sparkles).
## Enforces zero save/progress mutation, zero per-frame resource allocations, and edge safety.

# Asset Directory Paths
const BG_ASSET_PATH: String = "res://assets/backgrounds/auth/login_academy_bg_clean.png"
const FOG_CLUSTERS_DIR: String = "res://assets/backgrounds/auth/fog_clusters/"
const BANNERS_DIR: String = "res://assets/backgrounds/auth/banners/"
const PARTICLES_DIR: String = "res://assets/backgrounds/auth/particles/"

const BANNER_A_ASSET_PATH: String = "res://assets/backgrounds/auth/banners/login_banner_a.png"
const BANNER_B_ASSET_PATH: String = "res://assets/backgrounds/auth/banners/login_banner_b.png"
const PRODUCTION_PRESET_PATH: String = "res://config/auth/auth_bg_production_preset.json"

# Shader for 4-Corner Quad Warp + Banner Top-Pin Sway + Brightness & Tint + Local Light Spots
const BANNER_SHADER_CODE: String = """shader_type canvas_item;

uniform float sway_amplitude : hint_range(0.0, 30.0) = 3.5;
uniform float sway_speed : hint_range(0.0, 3.0) = 0.45;
uniform float ripple_amplitude : hint_range(0.0, 10.0) = 0.8;
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;
uniform float brightness : hint_range(0.4, 1.6) = 0.75;
uniform float banner_opacity : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform vec2 tl_offset = vec2(0.0, 0.0);
uniform vec2 tr_offset = vec2(0.0, 0.0);
uniform vec2 bl_offset = vec2(0.0, 0.0);
uniform vec2 br_offset = vec2(0.0, 0.0);

// Local Light Spots (up to 16 spots)
uniform int num_lights = 0;
uniform vec2 light_positions[16];
uniform float light_radii[16];
uniform float light_intensities[16];
uniform vec4 light_colors[16];
uniform float light_softness[16];

uniform vec2 banner_world_pos = vec2(0.0);

varying vec2 v_pos;

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

	// Track animated position in background reference space
	v_pos = banner_world_pos + VERTEX;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	tex_color.rgb *= brightness;
	tex_color.rgb *= tint_color.rgb;

	// Calculate diffuse environmental illumination from local light spots
	vec3 light_acc = vec3(0.0);
	for (int i = 0; i < 16; i++) {
		if (i >= num_lights) {
			break;
		}
		float d = distance(v_pos, light_positions[i]);
		float r = max(light_radii[i], 1.0);
		if (d < r) {
			float norm_d = d / r;
			// Smooth gaussian-style falloff
			float falloff = exp(-pow(norm_d * (1.5 / max(light_softness[i], 0.1)), 2.0));
			// Clamp falloff smoothly to zero at the boundary
			falloff *= smoothstep(1.0, 0.7, norm_d);
			vec3 light_col = light_colors[i].rgb;
			float intensity = light_intensities[i];
			// Subtle tint and illumination
			light_acc += light_col * (intensity * falloff);
		}
	}
	// Clamp total contribution to prevent blown-out highlights
	light_acc = clamp(light_acc, vec3(0.0), vec3(1.5));

	// Environmental lighting: base texture + soft brightness boost + subtle tint
	// Multiplying and adding preserve shadows & artwork details while brightening
	vec3 illuminated = tex_color.rgb + (tex_color.rgb * light_acc * 0.6) + (light_acc * 0.12 * tex_color.a);
	tex_color.rgb = clamp(illuminated, vec3(0.0), vec3(1.0));

	tex_color.a *= banner_opacity;
	COLOR = tex_color;
}
"""

# Shader for Fog Clusters with Tint, Brightness, Saturation
const FOG_SHADER_CODE: String = """shader_type canvas_item;

uniform float brightness : hint_range(0.4, 1.2) = 0.75;
uniform float saturation : hint_range(0.3, 1.2) = 0.75;
uniform vec4 tint_color : source_color = vec4(0.7, 0.88, 1.0, 1.0);
uniform float fog_opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec3 rgb = tex_color.rgb * brightness;
	float gray = dot(rgb, vec3(0.299, 0.587, 0.114));
	rgb = mix(vec3(gray), rgb, saturation);
	rgb *= tint_color.rgb;
	COLOR = vec4(rgb, tex_color.a * fog_opacity);
}
"""

# Shader for Soft Radial Crystal Glow (No ColorRect Debug Boxes!)
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
const DEFAULT_FOG_CLUSTER_COUNT: int = 10
const DEFAULT_FOG_GLOBAL_SPEED: float = 0.50
const DEFAULT_FOG_DRIFT_RANGE: float = 120.0
const DEFAULT_FOG_SCALE_MIN: float = 0.8
const DEFAULT_FOG_SCALE_MAX: float = 1.6
const DEFAULT_FOG_BREATHING: float = 0.04
const DEFAULT_FOG_SEED: int = 1337
const DEFAULT_FOG_DEPTH_SPREAD: float = 0.5
const DEFAULT_FOG_FG_ENABLE: bool = true
const DEFAULT_FOG_MG_ENABLE: bool = true

const DEFAULT_FOG_BRIGHTNESS: float = 0.75
const DEFAULT_FOG_SATURATION: float = 0.75
const DEFAULT_FOG_TINT: Color = Color(0.70, 0.88, 1.00, 1.00)

const DEFAULT_BANNER_A_VISIBLE: bool = true
const DEFAULT_BANNER_B_VISIBLE: bool = true
const DEFAULT_BANNER_C_VISIBLE: bool = true
const DEFAULT_BANNER_A_BRIGHTNESS: float = 0.75
const DEFAULT_BANNER_B_BRIGHTNESS: float = 0.72
const DEFAULT_BANNER_C_BRIGHTNESS: float = 0.72
const DEFAULT_BANNER_OPACITY: float = 1.00
const DEFAULT_BANNER_SWAY: float = 3.5
const DEFAULT_BANNER_SPEED: float = 0.45
const DEFAULT_BANNER_RIPPLE: float = 0.8
const BANNER_A_BASE_SIZE: Vector2 = Vector2(130, 260)
const BANNER_B_BASE_SIZE: Vector2 = Vector2(110, 220)
const BANNER_C_BASE_SIZE: Vector2 = Vector2(110, 220)

const MAX_LIGHT_SPOTS: int = 16

const DEFAULT_CRYSTAL_MASTER: float = 0.65
const DEFAULT_CRYSTAL_PULSE_AMT: float = 0.35
const DEFAULT_CRYSTAL_PULSE_SPEED: float = 0.6

const DEFAULT_PARTICLE_TYPE: String = "MIXED"
const DEFAULT_DUST_ENABLE: bool = true
const DEFAULT_DUST_COUNT: int = 14
const DEFAULT_DUST_OPACITY: float = 0.35
const DEFAULT_DUST_SCALE_MIN: float = 0.8
const DEFAULT_DUST_SCALE_MAX: float = 1.5
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
var _banner_c: TextureRect = null
var _banner_mat_a: ShaderMaterial = null
var _banner_mat_b: ShaderMaterial = null
var _banner_mat_c: ShaderMaterial = null
var _fog_container: Control = null
var _fog_cluster_nodes: Array[TextureRect] = []
var _fog_cluster_materials: Array[ShaderMaterial] = []
var _fog_cluster_data: Array[Dictionary] = []
var _particle_container: Control = null
var _particle_nodes: Array[TextureRect] = []
var _particle_data: Array[Dictionary] = []

# Loaded Real Asset Pools
var _bg_texture: Texture2D = null
var _banner_a_texture: Texture2D = null
var _banner_b_texture: Texture2D = null

var _fog_cluster_textures: Array[Texture2D] = []
var _fog_ribbon_textures: Array[Texture2D] = []

var _particle_star_textures: Array[Texture2D] = []
var _particle_orb_textures: Array[Texture2D] = []
var _particle_sparkle_textures: Array[Texture2D] = []
var _particle_all_textures: Array[Texture2D] = []

var _banner_shader: Shader = null
var _fog_shader: Shader = null
var _crystal_shader: Shader = null

# Asset Counts Verification
var fog_asset_count: int = 0
var banner_asset_count: int = 0
var particle_asset_count: int = 0

# State & Profiling Tracking Variables
var _resources_loaded: bool = false
var resource_load_count: int = 0
var shader_compilation_count: int = 0
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

var fog_brightness: float = DEFAULT_FOG_BRIGHTNESS
var fog_saturation: float = DEFAULT_FOG_SATURATION
var fog_tint: Color = DEFAULT_FOG_TINT

# Adjustable Banner Parameters
var banner_a_visible: bool = DEFAULT_BANNER_A_VISIBLE
var banner_b_visible: bool = DEFAULT_BANNER_B_VISIBLE
var banner_c_visible: bool = DEFAULT_BANNER_C_VISIBLE
var banner_a_brightness: float = DEFAULT_BANNER_A_BRIGHTNESS
var banner_b_brightness: float = DEFAULT_BANNER_B_BRIGHTNESS
var banner_c_brightness: float = DEFAULT_BANNER_C_BRIGHTNESS
var banner_opacity: float = DEFAULT_BANNER_OPACITY
var banner_sway: float = DEFAULT_BANNER_SWAY
var banner_speed: float = DEFAULT_BANNER_SPEED
var banner_ripple: float = DEFAULT_BANNER_RIPPLE

# Banner Four-Corner Quad Warp Offsets
var banner_a_warp_tl: Vector2 = Vector2.ZERO
var banner_a_warp_tr: Vector2 = Vector2.ZERO
var banner_a_warp_bl: Vector2 = Vector2.ZERO
var banner_a_warp_br: Vector2 = Vector2.ZERO

var banner_b_warp_tl: Vector2 = Vector2.ZERO
var banner_b_warp_tr: Vector2 = Vector2.ZERO
var banner_b_warp_bl: Vector2 = Vector2.ZERO
var banner_b_warp_br: Vector2 = Vector2.ZERO

var banner_c_warp_tl: Vector2 = Vector2.ZERO
var banner_c_warp_tr: Vector2 = Vector2.ZERO
var banner_c_warp_bl: Vector2 = Vector2.ZERO
var banner_c_warp_br: Vector2 = Vector2.ZERO

# Local Light Spots System (Procedural Environmental Illumination)
var local_lights: Array[Dictionary] = []
var _next_light_id: int = 1

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
var auto_load_production_preset: bool = true

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
	if auto_load_production_preset and _should_autoload_production():
		load_production_preset()

func _process(delta: float) -> void:
	if _is_playing:
		_accum_time += delta
	_update_animations(_accum_time)

func _load_resources() -> void:
	if _resources_loaded:
		return
	_resources_loaded = true
	resource_load_count += 1

	if _bg_texture == null:
		_bg_texture = _load_texture_safe(BG_ASSET_PATH)

	# 1. Banners Directory (Expected: login_banner_a.png, login_banner_b.png)
	if _banner_a_texture == null:
		_banner_a_texture = _load_texture_safe(BANNER_A_ASSET_PATH)
	if _banner_b_texture == null:
		_banner_b_texture = _load_texture_safe(BANNER_B_ASSET_PATH)

	banner_asset_count = 0
	if _banner_a_texture != null: banner_asset_count += 1
	if _banner_b_texture != null: banner_asset_count += 1

	# 2. Fog Directory (Expected: 13 clusters, 2 ribbons = 15 total)
	_fog_cluster_textures.clear()
	_fog_ribbon_textures.clear()

	for i in range(1, 14):
		var path: String = FOG_CLUSTERS_DIR + "auth_fog_cluster_%02d.png" % i
		var tex: Texture2D = _load_texture_safe(path)
		if tex != null:
			_fog_cluster_textures.append(tex)

	for i in range(1, 3):
		var rpath: String = FOG_CLUSTERS_DIR + "auth_fog_ribbon_%02d.png" % i
		var rtex: Texture2D = _load_texture_safe(rpath)
		if rtex != null:
			_fog_ribbon_textures.append(rtex)

	fog_asset_count = _fog_cluster_textures.size() + _fog_ribbon_textures.size()

	# 3. Particle Directory (Expected: 3 stars, 2 orbs, 3 sparkles = 8 total)
	_particle_star_textures.clear()
	_particle_orb_textures.clear()
	_particle_sparkle_textures.clear()
	_particle_all_textures.clear()

	for i in range(1, 4):
		var spath: String = PARTICLES_DIR + "pixel_star_%02d.png" % i
		var stex: Texture2D = _load_texture_safe(spath)
		if stex != null:
			_particle_star_textures.append(stex)
			_particle_all_textures.append(stex)

	for i in range(1, 3):
		var opath: String = PARTICLES_DIR + "pixel_orb_%02d.png" % i
		var otex: Texture2D = _load_texture_safe(opath)
		if otex != null:
			_particle_orb_textures.append(otex)
			_particle_all_textures.append(otex)

	for i in range(1, 4):
		var kpath: String = PARTICLES_DIR + "pixel_sparkle_%02d.png" % i
		var ktex: Texture2D = _load_texture_safe(kpath)
		if ktex != null:
			_particle_sparkle_textures.append(ktex)
			_particle_all_textures.append(ktex)

	particle_asset_count = _particle_all_textures.size()

	# 4. Shaders (Instantiated ONCE)
	if _banner_shader == null:
		_banner_shader = Shader.new()
		_banner_shader.code = BANNER_SHADER_CODE
		shader_compilation_count += 1

	if _fog_shader == null:
		_fog_shader = Shader.new()
		_fog_shader.code = FOG_SHADER_CODE
		shader_compilation_count += 1

	if _crystal_shader == null:
		_crystal_shader = Shader.new()
		_crystal_shader.code = CRYSTAL_GLOW_SHADER_CODE
		shader_compilation_count += 1

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

	# 3. BANNERS CONTAINER (Nearest Pixel Art Sampling)
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
	_banner_a.texture = _banner_a_texture
	_banner_a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	_banner_b.texture = _banner_b_texture
	_banner_b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_banner_b.material = _banner_mat_b
	_banner_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_banner_b.custom_minimum_size = Vector2(110, 220)
	_banner_b.mouse_filter = MOUSE_FILTER_IGNORE
	_banner_container.add_child(_banner_b)

	_banner_mat_c = ShaderMaterial.new()
	_banner_mat_c.shader = _banner_shader
	_banner_mat_c.set_shader_parameter("time_offset", 3.40)

	_banner_c = TextureRect.new()
	_banner_c.name = "Banner_C"
	_banner_c.texture = _banner_b_texture
	_banner_c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_banner_c.material = _banner_mat_c
	_banner_c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner_c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_banner_c.custom_minimum_size = BANNER_C_BASE_SIZE
	_banner_c.mouse_filter = MOUSE_FILTER_IGNORE
	_banner_container.add_child(_banner_c)

	# 4. GROUND FOG CLUSTER & RIBBON CONTAINER
	_fog_container = Control.new()
	_fog_container.name = "GroundFogClusterContainer"
	_fog_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fog_container.mouse_filter = MOUSE_FILTER_IGNORE
	_fog_container.clip_contents = true
	add_child(_fog_container)

	_rebuild_fog_clusters()

	# 5. REAL PIXEL ART PARTICLES CONTAINER (Nearest Sampling — ZERO ColorRect Boxes!)
	_particle_container = Control.new()
	_particle_container.name = "RealParticleContainer"
	_particle_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_particle_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_particle_container)

	_rebuild_particles()

func _rebuild_fog_clusters() -> void:
	if _fog_container == null:
		return

	for node in _fog_cluster_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_fog_cluster_nodes.clear()
	_fog_cluster_materials.clear()
	_fog_cluster_data.clear()

	var count: int = clampi(fog_cluster_count, 1, 25)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = fog_seed

	for i in range(count):
		var cluster_rect: TextureRect = TextureRect.new()
		cluster_rect.name = "FogCluster_%d" % i
		cluster_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cluster_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		cluster_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		cluster_rect.mouse_filter = MOUSE_FILTER_IGNORE

		# Assign texture: ribbons for i % 5 == 0, clusters for rest
		var is_ribbon: bool = (i % 5 == 0) and not _fog_ribbon_textures.is_empty()
		if is_ribbon:
			var r_idx: int = rng.randi() % _fog_ribbon_textures.size()
			cluster_rect.texture = _fog_ribbon_textures[r_idx]
		elif not _fog_cluster_textures.is_empty():
			var c_idx: int = rng.randi() % _fog_cluster_textures.size()
			cluster_rect.texture = _fog_cluster_textures[c_idx]

		var fmat: ShaderMaterial = ShaderMaterial.new()
		fmat.shader = _fog_shader
		cluster_rect.material = fmat
		_fog_cluster_materials.append(fmat)

		_fog_container.add_child(cluster_rect)
		_fog_cluster_nodes.append(cluster_rect)

		var base_pos_norm: Vector2 = Vector2(
			rng.randf_range(-0.05, 0.85),
			rng.randf_range(0.40, 0.88)
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
			"is_fg": is_fg,
			"is_ribbon": is_ribbon
		})

func _rebuild_particles() -> void:
	if _particle_container == null:
		return

	for pnode in _particle_nodes:
		if is_instance_valid(pnode):
			pnode.queue_free()
	_particle_nodes.clear()
	_particle_data.clear()

	var count: int = clampi(dust_count, 1, 50)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = fog_seed + 999

	var pool: Array[Texture2D] = []
	match particle_type.to_upper():
		"STAR": pool = _particle_star_textures
		"ORB": pool = _particle_orb_textures
		"SPARKLE": pool = _particle_sparkle_textures
		_: pool = _particle_all_textures

	if pool.is_empty():
		pool = _particle_all_textures

	for i in range(count):
		var prect: TextureRect = TextureRect.new()
		prect.name = "PixelParticle_%d" % i
		prect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		prect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		prect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		prect.mouse_filter = MOUSE_FILTER_IGNORE

		if not pool.is_empty():
			prect.texture = pool[rng.randi() % pool.size()]

		_particle_container.add_child(prect)
		_particle_nodes.append(prect)

		var pos_norm: Vector2 = Vector2(
			rng.randf_range(0.05, 0.45), # Placed on left Academy architecture
			rng.randf_range(0.20, 0.75)
		)
		var scale_val: float = rng.randf_range(dust_scale_min, dust_scale_max)
		var phase: float = rng.randf_range(0.0, TAU)
		var speed_val: float = rng.randf_range(0.5, 1.5)

		_particle_data.append({
			"pos_norm": pos_norm,
			"scale_val": scale_val,
			"phase": phase,
			"speed_val": speed_val
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

	fog_brightness = DEFAULT_FOG_BRIGHTNESS
	fog_saturation = DEFAULT_FOG_SATURATION
	fog_tint = DEFAULT_FOG_TINT

	banner_a_visible = DEFAULT_BANNER_A_VISIBLE
	banner_b_visible = DEFAULT_BANNER_B_VISIBLE
	banner_c_visible = DEFAULT_BANNER_C_VISIBLE
	banner_a_brightness = DEFAULT_BANNER_A_BRIGHTNESS
	banner_b_brightness = DEFAULT_BANNER_B_BRIGHTNESS
	banner_c_brightness = DEFAULT_BANNER_C_BRIGHTNESS
	banner_opacity = DEFAULT_BANNER_OPACITY
	banner_sway = DEFAULT_BANNER_SWAY
	banner_speed = DEFAULT_BANNER_SPEED
	banner_ripple = DEFAULT_BANNER_RIPPLE

	reset_all_banners_warp()
	clear_light_spots()

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
	_rebuild_particles()
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

func reset_banner_c_warp() -> void:
	banner_c_warp_tl = Vector2.ZERO
	banner_c_warp_tr = Vector2.ZERO
	banner_c_warp_bl = Vector2.ZERO
	banner_c_warp_br = Vector2.ZERO

func reset_all_banners_warp() -> void:
	reset_banner_a_warp()
	reset_banner_b_warp()
	reset_banner_c_warp()

func reset_both_banners_warp() -> void:
	reset_all_banners_warp()

func set_fog_cluster_count(cnt: int) -> void:
	fog_cluster_count = clampi(cnt, 1, 25)
	_rebuild_fog_clusters()

func set_particle_count(cnt: int) -> void:
	dust_count = clampi(cnt, 1, 50)
	_rebuild_particles()

func set_particle_type(ptype: String) -> void:
	particle_type = ptype
	_rebuild_particles()

func set_fog_seed(sd: int) -> void:
	fog_seed = sd
	_rebuild_fog_clusters()
	_rebuild_particles()

func _update_animations(time: float) -> void:
	var vp_size: Vector2 = size if size.x > 0 and size.y > 0 else Vector2(1280, 720)

	# 1. FOG CLUSTERS ANIMATION (Shader Tint/Brightness/Saturation & Bounded Motion)
	for i in range(_fog_cluster_nodes.size()):
		if i >= _fog_cluster_data.size() or i >= _fog_cluster_materials.size():
			continue
		var cluster_node: TextureRect = _fog_cluster_nodes[i]
		var fmat: ShaderMaterial = _fog_cluster_materials[i]
		var data: Dictionary = _fog_cluster_data[i]

		var is_fg: bool = data["is_fg"]
		var active: bool = (is_fg and fog_fg_enabled) or ((not is_fg) and fog_mg_enabled)
		cluster_node.visible = active
		if not active:
			continue

		var speed: float = fog_global_speed * data["speed_mult"]
		var phase: float = data["phase"]

		var drift_x: float = sin(time * speed * 0.4 + phase) * fog_drift_range
		var drift_y: float = cos(time * speed * 0.3 + phase * 1.5) * (fog_drift_range * 0.25)
		var scale_delta: float = sin(time * speed * 0.8 + phase) * fog_breathing

		var curr_scale: float = clampf(data["base_scale"] + scale_delta, 0.4, 4.0)
		var base_pos: Vector2 = Vector2(data["base_pos_norm"].x * vp_size.x, data["base_pos_norm"].y * vp_size.y)
		var pos: Vector2 = base_pos + Vector2(drift_x, drift_y)

		var base_w: float = (550.0 if not data["is_ribbon"] else 750.0) * curr_scale
		var base_h: float = (280.0 if not data["is_ribbon"] else 180.0) * curr_scale

		cluster_node.custom_minimum_size = Vector2(base_w, base_h)
		cluster_node.size = Vector2(base_w, base_h)
		cluster_node.position = pos

		var layer_opacity: float = (0.28 if is_fg else 0.16) * fog_master_opacity
		var alpha: float = clampf(layer_opacity * (1.0 + sin(time * speed * 0.6 + phase) * 0.15), 0.0, 1.0)

		if fmat != null:
			fmat.set_shader_parameter("brightness", fog_brightness)
			fmat.set_shader_parameter("saturation", fog_saturation)
			fmat.set_shader_parameter("tint_color", fog_tint)
			fmat.set_shader_parameter("fog_opacity", alpha)

	# 2. BANNERS SHADER, WARP, LOCAL LIGHTS & POSITIONS
	var active_light_positions: Array[Vector2] = []
	var active_light_radii: Array[float] = []
	var active_light_intensities: Array[float] = []
	var active_light_colors: Array[Color] = []
	var active_light_softness: Array[float] = []
	var num_active_lights: int = 0

	for l in local_lights:
		if l.get("enabled", true) and num_active_lights < MAX_LIGHT_SPOTS:
			active_light_positions.append(l.get("position", Vector2.ZERO))
			active_light_radii.append(l.get("radius", 140.0))
			active_light_intensities.append(l.get("intensity", 1.0))
			active_light_colors.append(l.get("color", Color(0.25, 0.75, 1.0, 1.0)))
			active_light_softness.append(l.get("softness", 0.8))
			num_active_lights += 1

	while active_light_positions.size() < MAX_LIGHT_SPOTS:
		active_light_positions.append(Vector2.ZERO)
		active_light_radii.append(1.0)
		active_light_intensities.append(0.0)
		active_light_colors.append(Color.BLACK)
		active_light_softness.append(1.0)

	if _banner_a != null:
		_banner_a.visible = banner_a_visible
		_banner_a.position = Vector2(vp_size.x * 0.16, vp_size.y * 0.22)
		_banner_a.size = BANNER_A_BASE_SIZE
		if _banner_mat_a != null:
			_banner_mat_a.set_shader_parameter("sway_amplitude", banner_sway)
			_banner_mat_a.set_shader_parameter("sway_speed", banner_speed)
			_banner_mat_a.set_shader_parameter("ripple_amplitude", banner_ripple)
			_banner_mat_a.set_shader_parameter("brightness", banner_a_brightness)
			_banner_mat_a.set_shader_parameter("banner_opacity", banner_opacity)
			_banner_mat_a.set_shader_parameter("tl_offset", banner_a_warp_tl)
			_banner_mat_a.set_shader_parameter("tr_offset", banner_a_warp_tr)
			_banner_mat_a.set_shader_parameter("bl_offset", banner_a_warp_bl)
			_banner_mat_a.set_shader_parameter("br_offset", banner_a_warp_br)
			_banner_mat_a.set_shader_parameter("banner_world_pos", _banner_a.position)
			_banner_mat_a.set_shader_parameter("num_lights", num_active_lights)
			_banner_mat_a.set_shader_parameter("light_positions", active_light_positions)
			_banner_mat_a.set_shader_parameter("light_radii", active_light_radii)
			_banner_mat_a.set_shader_parameter("light_intensities", active_light_intensities)
			_banner_mat_a.set_shader_parameter("light_colors", active_light_colors)
			_banner_mat_a.set_shader_parameter("light_softness", active_light_softness)

	if _banner_b != null:
		_banner_b.visible = banner_b_visible
		_banner_b.position = Vector2(vp_size.x * 0.34, vp_size.y * 0.26)
		_banner_b.size = BANNER_B_BASE_SIZE
		if _banner_mat_b != null:
			_banner_mat_b.set_shader_parameter("sway_amplitude", banner_sway * 0.85)
			_banner_mat_b.set_shader_parameter("sway_speed", banner_speed * 1.1)
			_banner_mat_b.set_shader_parameter("ripple_amplitude", banner_ripple * 0.9)
			_banner_mat_b.set_shader_parameter("brightness", banner_b_brightness)
			_banner_mat_b.set_shader_parameter("banner_opacity", banner_opacity)
			_banner_mat_b.set_shader_parameter("tl_offset", banner_b_warp_tl)
			_banner_mat_b.set_shader_parameter("tr_offset", banner_b_warp_tr)
			_banner_mat_b.set_shader_parameter("bl_offset", banner_b_warp_bl)
			_banner_mat_b.set_shader_parameter("br_offset", banner_b_warp_br)
			_banner_mat_b.set_shader_parameter("banner_world_pos", _banner_b.position)
			_banner_mat_b.set_shader_parameter("num_lights", num_active_lights)
			_banner_mat_b.set_shader_parameter("light_positions", active_light_positions)
			_banner_mat_b.set_shader_parameter("light_radii", active_light_radii)
			_banner_mat_b.set_shader_parameter("light_intensities", active_light_intensities)
			_banner_mat_b.set_shader_parameter("light_colors", active_light_colors)
			_banner_mat_b.set_shader_parameter("light_softness", active_light_softness)

	if _banner_c != null:
		_banner_c.visible = banner_c_visible
		_banner_c.position = Vector2(vp_size.x * 0.26, vp_size.y * 0.20)
		_banner_c.size = BANNER_C_BASE_SIZE
		if _banner_mat_c != null:
			_banner_mat_c.set_shader_parameter("sway_amplitude", banner_sway * 0.9)
			_banner_mat_c.set_shader_parameter("sway_speed", banner_speed * 0.95)
			_banner_mat_c.set_shader_parameter("ripple_amplitude", banner_ripple * 0.85)
			_banner_mat_c.set_shader_parameter("brightness", banner_c_brightness)
			_banner_mat_c.set_shader_parameter("banner_opacity", banner_opacity)
			_banner_mat_c.set_shader_parameter("tl_offset", banner_c_warp_tl)
			_banner_mat_c.set_shader_parameter("tr_offset", banner_c_warp_tr)
			_banner_mat_c.set_shader_parameter("bl_offset", banner_c_warp_bl)
			_banner_mat_c.set_shader_parameter("br_offset", banner_c_warp_br)
			_banner_mat_c.set_shader_parameter("banner_world_pos", _banner_c.position)
			_banner_mat_c.set_shader_parameter("num_lights", num_active_lights)
			_banner_mat_c.set_shader_parameter("light_positions", active_light_positions)
			_banner_mat_c.set_shader_parameter("light_radii", active_light_radii)
			_banner_mat_c.set_shader_parameter("light_intensities", active_light_intensities)
			_banner_mat_c.set_shader_parameter("light_colors", active_light_colors)
			_banner_mat_c.set_shader_parameter("light_softness", active_light_softness)

	# 3. SOFT RADIAL CRYSTAL GLOW PULSES
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

	# 4. PIXEL ART MAGIC LIGHT PARTICLES (Zero ColorRect Boxes!)
	if _particle_container != null:
		_particle_container.visible = dust_enabled
		for i in range(_particle_nodes.size()):
			if i >= _particle_data.size():
				continue
			var pnode: TextureRect = _particle_nodes[i]
			var pdata: Dictionary = _particle_data[i]

			var phase: float = pdata["phase"]
			var p_speed: float = pdata["speed_val"] * dust_twinkle_speed

			# Asynchronous twinkle and drift
			var twinkle: float = sin(time * p_speed * TAU + phase) * 0.5 + 0.5
			var drift_offset_y: float = -fmod(time * dust_drift_speed * p_speed, 80.0)
			var drift_offset_x: float = sin(time * 0.5 + phase) * 12.0

			var base_pos: Vector2 = Vector2(pdata["pos_norm"].x * vp_size.x, pdata["pos_norm"].y * vp_size.y)
			pnode.position = base_pos + Vector2(drift_offset_x, drift_offset_y)

			var s_val: float = pdata["scale_val"] * (16.0) # Base 16px sprite size
			pnode.custom_minimum_size = Vector2(s_val, s_val)
			pnode.size = Vector2(s_val, s_val)

			var alpha: float = dust_opacity * (1.0 - dust_twinkle_amount + dust_twinkle_amount * twinkle)
			pnode.modulate = Color(1.0, 1.0, 1.0, alpha)

func set_playing(playing: bool) -> void:
	_is_playing = playing

func is_playing() -> bool:
	return _is_playing

func get_bg_texture() -> Texture2D:
	_load_resources()
	return _bg_texture

func get_banner_a_texture() -> Texture2D:
	_load_resources()
	return _banner_a_texture

func get_banner_b_texture() -> Texture2D:
	_load_resources()
	return _banner_b_texture

func get_fog_cluster_count() -> int:
	return _fog_cluster_nodes.size()

func get_particle_count() -> int:
	return _particle_nodes.size()

func get_banner_a_rect() -> TextureRect:
	return _banner_a

func get_banner_b_rect() -> TextureRect:
	return _banner_b

func get_banner_a_base_rect() -> Rect2:
	var vp_size: Vector2 = size if size.x > 0 and size.y > 0 else Vector2(1280, 720)
	var pos: Vector2 = Vector2(vp_size.x * 0.16, vp_size.y * 0.22)
	return Rect2(pos, BANNER_A_BASE_SIZE)

func get_banner_b_base_rect() -> Rect2:
	var vp_size: Vector2 = size if size.x > 0 and size.y > 0 else Vector2(1280, 720)
	var pos: Vector2 = Vector2(vp_size.x * 0.34, vp_size.y * 0.26)
	return Rect2(pos, BANNER_B_BASE_SIZE)

func get_banner_a_quad_points() -> Dictionary:
	var r: Rect2 = get_banner_a_base_rect()
	return {
		"TL": r.position + banner_a_warp_tl,
		"TR": r.position + Vector2(r.size.x, 0.0) + banner_a_warp_tr,
		"BL": r.position + Vector2(0.0, r.size.y) + banner_a_warp_bl,
		"BR": r.position + r.size + banner_a_warp_br
	}

func get_banner_b_quad_points() -> Dictionary:
	var r: Rect2 = get_banner_b_base_rect()
	return {
		"TL": r.position + banner_b_warp_tl,
		"TR": r.position + Vector2(r.size.x, 0.0) + banner_b_warp_tr,
		"BL": r.position + Vector2(0.0, r.size.y) + banner_b_warp_bl,
		"BR": r.position + r.size + banner_b_warp_br
	}

func get_banner_c_texture() -> Texture2D:
	_load_resources()
	return _banner_b_texture

func get_banner_c_rect() -> TextureRect:
	return _banner_c

func get_banner_c_base_rect() -> Rect2:
	var vp_size: Vector2 = size if size.x > 0 and size.y > 0 else Vector2(1280, 720)
	var pos: Vector2 = Vector2(vp_size.x * 0.26, vp_size.y * 0.20)
	return Rect2(pos, BANNER_C_BASE_SIZE)

func get_banner_c_quad_points() -> Dictionary:
	var r: Rect2 = get_banner_c_base_rect()
	return {
		"TL": r.position + banner_c_warp_tl,
		"TR": r.position + Vector2(r.size.x, 0.0) + banner_c_warp_tr,
		"BL": r.position + Vector2(0.0, r.size.y) + banner_c_warp_bl,
		"BR": r.position + r.size + banner_c_warp_br
	}

# ==============================================================================
# LOCAL LIGHT SPOTS API
# ==============================================================================

func add_light_spot(pos: Vector2, radius: float = 140.0, intensity: float = 1.0, color: Color = Color(0.25, 0.75, 1.0, 1.0), softness: float = 0.8) -> int:
	var light_id: int = _next_light_id
	_next_light_id += 1
	var spot: Dictionary = {
		"id": light_id,
		"position": pos,
		"radius": maxf(radius, 10.0),
		"intensity": clampf(intensity, 0.0, 3.0),
		"color": color,
		"softness": clampf(softness, 0.1, 2.0),
		"enabled": true
	}
	local_lights.append(spot)
	return local_lights.size() - 1

func remove_light_spot(index: int) -> bool:
	if index >= 0 and index < local_lights.size():
		local_lights.remove_at(index)
		return true
	return false

func clear_light_spots() -> void:
	local_lights.clear()

func reset_lights() -> void:
	clear_light_spots()

func get_light_spot_count() -> int:
	return local_lights.size()

func get_light_spots() -> Array[Dictionary]:
	return local_lights

func get_light_spot(index: int) -> Dictionary:
	if index >= 0 and index < local_lights.size():
		return local_lights[index]
	return {}

func set_light_spot_position(index: int, pos: Vector2) -> void:
	if index >= 0 and index < local_lights.size():
		local_lights[index]["position"] = pos

func set_light_spot_radius(index: int, radius: float) -> void:
	if index >= 0 and index < local_lights.size():
		local_lights[index]["radius"] = maxf(radius, 10.0)

func set_light_spot_intensity(index: int, intensity: float) -> void:
	if index >= 0 and index < local_lights.size():
		local_lights[index]["intensity"] = clampf(intensity, 0.0, 3.0)

func set_light_spot_color(index: int, color: Color) -> void:
	if index >= 0 and index < local_lights.size():
		local_lights[index]["color"] = color

func set_light_spot_softness(index: int, softness: float) -> void:
	if index >= 0 and index < local_lights.size():
		local_lights[index]["softness"] = clampf(softness, 0.1, 2.0)

func set_light_spot_enabled(index: int, enabled: bool) -> void:
	if index >= 0 and index < local_lights.size():
		local_lights[index]["enabled"] = enabled

# ==============================================================================
# PRESET SERIALIZATION & PERSISTENCE API
# ==============================================================================

func to_preset_dict() -> Dictionary:
	var lights_arr: Array = []
	for l in local_lights:
		var pos: Vector2 = l.get("position", Vector2.ZERO)
		var col: Color = l.get("color", Color(0.25, 0.75, 1.0, 1.0))
		lights_arr.append({
			"id": l.get("id", 0),
			"position": {"x": pos.x, "y": pos.y},
			"radius": l.get("radius", 140.0),
			"intensity": l.get("intensity", 1.0),
			"softness": l.get("softness", 0.8),
			"color": {"r": col.r, "g": col.g, "b": col.b, "a": col.a},
			"enabled": l.get("enabled", true)
		})

	return {
		"version": 1,
		"banner_a": {
			"warp_tl": {"x": banner_a_warp_tl.x, "y": banner_a_warp_tl.y},
			"warp_tr": {"x": banner_a_warp_tr.x, "y": banner_a_warp_tr.y},
			"warp_bl": {"x": banner_a_warp_bl.x, "y": banner_a_warp_bl.y},
			"warp_br": {"x": banner_a_warp_br.x, "y": banner_a_warp_br.y},
			"brightness": banner_a_brightness,
			"visible": banner_a_visible
		},
		"banner_b": {
			"warp_tl": {"x": banner_b_warp_tl.x, "y": banner_b_warp_tl.y},
			"warp_tr": {"x": banner_b_warp_tr.x, "y": banner_b_warp_tr.y},
			"warp_bl": {"x": banner_b_warp_bl.x, "y": banner_b_warp_bl.y},
			"warp_br": {"x": banner_b_warp_br.x, "y": banner_b_warp_br.y},
			"brightness": banner_b_brightness,
			"visible": banner_b_visible
		},
		"banner_c": {
			"warp_tl": {"x": banner_c_warp_tl.x, "y": banner_c_warp_tl.y},
			"warp_tr": {"x": banner_c_warp_tr.x, "y": banner_c_warp_tr.y},
			"warp_bl": {"x": banner_c_warp_bl.x, "y": banner_c_warp_bl.y},
			"warp_br": {"x": banner_c_warp_br.x, "y": banner_c_warp_br.y},
			"brightness": banner_c_brightness,
			"visible": banner_c_visible
		},
		"banner_motion": {
			"opacity": banner_opacity,
			"sway": banner_sway,
			"speed": banner_speed,
			"ripple": banner_ripple
		},
		"local_lights": lights_arr,
		"fog": {
			"master_opacity": fog_master_opacity,
			"cluster_count": fog_cluster_count,
			"global_speed": fog_global_speed,
			"drift_range": fog_drift_range,
			"scale_min": fog_scale_min,
			"scale_max": fog_scale_max,
			"breathing": fog_breathing,
			"seed": fog_seed,
			"depth_spread": fog_depth_spread,
			"fg_enabled": fog_fg_enabled,
			"mg_enabled": fog_mg_enabled,
			"brightness": fog_brightness,
			"saturation": fog_saturation,
			"tint": {"r": fog_tint.r, "g": fog_tint.g, "b": fog_tint.b, "a": fog_tint.a}
		},
		"crystals": {
			"master_opacity": crystal_master_opacity,
			"pulse_amount": crystal_pulse_amount,
			"pulse_speed": crystal_pulse_speed
		},
		"particles": {
			"type": particle_type,
			"enabled": dust_enabled,
			"count": dust_count,
			"opacity": dust_opacity,
			"scale_min": dust_scale_min,
			"scale_max": dust_scale_max,
			"twinkle_amount": dust_twinkle_amount,
			"twinkle_speed": dust_twinkle_speed,
			"drift_speed": dust_drift_speed
		}
	}

func apply_preset_dict(d: Dictionary) -> bool:
	if d.is_empty():
		return false

	if d.has("banner_a"):
		var ba: Dictionary = d["banner_a"]
		if ba.has("warp_tl"): banner_a_warp_tl = _parse_vec2(ba["warp_tl"], banner_a_warp_tl)
		if ba.has("warp_tr"): banner_a_warp_tr = _parse_vec2(ba["warp_tr"], banner_a_warp_tr)
		if ba.has("warp_bl"): banner_a_warp_bl = _parse_vec2(ba["warp_bl"], banner_a_warp_bl)
		if ba.has("warp_br"): banner_a_warp_br = _parse_vec2(ba["warp_br"], banner_a_warp_br)
		if ba.has("brightness"): banner_a_brightness = float(ba["brightness"])
		if ba.has("visible"): banner_a_visible = bool(ba["visible"])

	if d.has("banner_b"):
		var bb: Dictionary = d["banner_b"]
		if bb.has("warp_tl"): banner_b_warp_tl = _parse_vec2(bb["warp_tl"], banner_b_warp_tl)
		if bb.has("warp_tr"): banner_b_warp_tr = _parse_vec2(bb["warp_tr"], banner_b_warp_tr)
		if bb.has("warp_bl"): banner_b_warp_bl = _parse_vec2(bb["warp_bl"], banner_b_warp_bl)
		if bb.has("warp_br"): banner_b_warp_br = _parse_vec2(bb["warp_br"], banner_b_warp_br)
		if bb.has("brightness"): banner_b_brightness = float(bb["brightness"])
		if bb.has("visible"): banner_b_visible = bool(bb["visible"])

	if d.has("banner_c"):
		var bc: Dictionary = d["banner_c"]
		if bc.has("warp_tl"): banner_c_warp_tl = _parse_vec2(bc["warp_tl"], banner_c_warp_tl)
		if bc.has("warp_tr"): banner_c_warp_tr = _parse_vec2(bc["warp_tr"], banner_c_warp_tr)
		if bc.has("warp_bl"): banner_c_warp_bl = _parse_vec2(bc["warp_bl"], banner_c_warp_bl)
		if bc.has("warp_br"): banner_c_warp_br = _parse_vec2(bc["warp_br"], banner_c_warp_br)
		if bc.has("brightness"): banner_c_brightness = float(bc["brightness"])
		if bc.has("visible"): banner_c_visible = bool(bc["visible"])

	if d.has("banner_motion"):
		var bm: Dictionary = d["banner_motion"]
		if bm.has("opacity"): banner_opacity = float(bm["opacity"])
		if bm.has("sway"): banner_sway = float(bm["sway"])
		if bm.has("speed"): banner_speed = float(bm["speed"])
		if bm.has("ripple"): banner_ripple = float(bm["ripple"])

	if d.has("local_lights"):
		local_lights.clear()
		var lights_raw: Array = d["local_lights"] as Array
		var max_id: int = 0
		for item in lights_raw:
			if item is Dictionary:
				var l_id: int = int(item.get("id", max_id + 1))
				max_id = maxi(max_id, l_id)
				var l_pos: Vector2 = _parse_vec2(item.get("position", {}), Vector2.ZERO)
				var l_rad: float = float(item.get("radius", 140.0))
				var l_int: float = float(item.get("intensity", 1.0))
				var l_soft: float = float(item.get("softness", 0.8)) if item.has("softness") else 0.8
				var l_col: Color = _parse_color(item.get("color", {}), Color(0.25, 0.75, 1.0, 1.0)) if item.has("color") else Color(0.25, 0.75, 1.0, 1.0)
				var l_en: bool = bool(item.get("enabled", true))
				local_lights.append({
					"id": l_id,
					"position": l_pos,
					"radius": maxf(l_rad, 10.0),
					"intensity": clampf(l_int, 0.0, 3.0),
					"color": l_col,
					"softness": clampf(l_soft, 0.1, 2.0),
					"enabled": l_en
				})
		_next_light_id = max_id + 1

	if d.has("fog"):
		var f: Dictionary = d["fog"]
		if f.has("master_opacity"): fog_master_opacity = float(f["master_opacity"])
		if f.has("cluster_count"): fog_cluster_count = int(f["cluster_count"])
		if f.has("global_speed"): fog_global_speed = float(f["global_speed"])
		if f.has("drift_range"): fog_drift_range = float(f["drift_range"])
		if f.has("scale_min"): fog_scale_min = float(f["scale_min"])
		if f.has("scale_max"): fog_scale_max = float(f["scale_max"])
		if f.has("breathing"): fog_breathing = float(f["breathing"])
		if f.has("seed"): fog_seed = int(f["seed"])
		if f.has("depth_spread"): fog_depth_spread = float(f["depth_spread"])
		if f.has("fg_enabled"): fog_fg_enabled = bool(f["fg_enabled"])
		if f.has("mg_enabled"): fog_mg_enabled = bool(f["mg_enabled"])
		if f.has("brightness"): fog_brightness = float(f["brightness"])
		if f.has("saturation"): fog_saturation = float(f["saturation"])
		if f.has("tint"): fog_tint = _parse_color(f["tint"], DEFAULT_FOG_TINT)
		_rebuild_fog_clusters()

	if d.has("crystals"):
		var c: Dictionary = d["crystals"]
		if c.has("master_opacity"): crystal_master_opacity = float(c["master_opacity"])
		if c.has("pulse_amount"): crystal_pulse_amount = float(c["pulse_amount"])
		if c.has("pulse_speed"): crystal_pulse_speed = float(c["pulse_speed"])

	if d.has("particles"):
		var p: Dictionary = d["particles"]
		if p.has("type"): particle_type = str(p["type"])
		if p.has("enabled"): dust_enabled = bool(p["enabled"])
		if p.has("count"): dust_count = int(p["count"])
		if p.has("opacity"): dust_opacity = float(p["opacity"])
		if p.has("scale_min"): dust_scale_min = float(p["scale_min"])
		if p.has("scale_max"): dust_scale_max = float(p["scale_max"])
		if p.has("twinkle_amount"): dust_twinkle_amount = float(p["twinkle_amount"])
		if p.has("twinkle_speed"): dust_twinkle_speed = float(p["twinkle_speed"])
		if p.has("drift_speed"): dust_drift_speed = float(p["drift_speed"])
		_rebuild_particles()

	_update_animations(_accum_time)
	return true

func _parse_vec2(val: Variant, fallback: Vector2) -> Vector2:
	if val is Dictionary:
		return Vector2(float(val.get("x", fallback.x)), float(val.get("y", fallback.y)))
	elif val is Vector2:
		return val
	return fallback

func _parse_color(val: Variant, fallback: Color) -> Color:
	if val is Dictionary:
		return Color(
			float(val.get("r", fallback.r)),
			float(val.get("g", fallback.g)),
			float(val.get("b", fallback.b)),
			float(val.get("a", fallback.a))
		)
	elif val is Color:
		return val
	elif val is String:
		return Color.from_string(val, fallback)
	return fallback

func _should_autoload_production() -> bool:
	var args := OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i] == "-s" and i + 1 < args.size():
			var s: String = args[i + 1]
			if s.contains("test_visual_lab") or s.contains("test_runner") or s.contains("test_banner_direct_warp") or s.contains("test_banner_c_and_local_lights"):
				return false
	return true

## Loads and applies the production Auth background preset snapshot (res://config/auth/auth_bg_production_preset.json).
## Returns true if the preset was successfully read, parsed, and applied.
func load_production_preset(custom_path: String = PRODUCTION_PRESET_PATH) -> bool:
	var target_path: String = custom_path
	if not FileAccess.file_exists(target_path):
		var global_p: String = ProjectSettings.globalize_path(target_path)
		if FileAccess.file_exists(global_p):
			target_path = global_p
		else:
			return false
	var f: FileAccess = FileAccess.open(target_path, FileAccess.READ)
	if f == null:
		return false
	var text: String = f.get_as_text()
	f.close()
	var json: JSON = JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		return false
	var data: Variant = json.data
	if data is Dictionary:
		return apply_preset_dict(data)
	return false


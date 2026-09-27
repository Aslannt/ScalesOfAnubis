class_name WorldMaterials
extends RefCounted
## Materiales con shader compartidos por todo el mundo (PROMPT_PULIDO.md
## punto 3: viento, agua animada, sombras de nubes). Cacheados para que cien
## juncos compartan un solo material.

const TEX_DIR := "res://assets/textures/"
const TERRAIN_SHADER := preload("res://assets/shaders/terrain.gdshader")
const WATER_SHADER := preload("res://assets/shaders/water.gdshader")
const WIND_SHADER := preload("res://assets/shaders/wind_foliage.gdshader")
const GRASS_SHADER := preload("res://assets/shaders/grass_blades.gdshader")
const SPRITE_WIND_SHADER := preload("res://assets/shaders/sprite_wind.gdshader")

static var _cache: Dictionary = {}
static var _noise: NoiseTexture2D = null


## Ruido suave y tileable para nubes y agua (se genera una sola vez).
static func noise_texture() -> NoiseTexture2D:
	if _noise == null:
		var fn := FastNoiseLite.new()
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		fn.frequency = 0.012
		fn.fractal_octaves = 3
		fn.seed = 7
		_noise = NoiseTexture2D.new()
		_noise.width = 256
		_noise.height = 256
		_noise.seamless = true
		_noise.normalize = true
		_noise.noise = fn
	return _noise


static func terrain(tex_name: String, uv_scale: Vector2) -> ShaderMaterial:
	var key := "terrain|%s|%s" % [tex_name, uv_scale]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = TERRAIN_SHADER
	m.set_shader_parameter("albedo_tex", load(TEX_DIR + tex_name + ".png"))
	m.set_shader_parameter("uv_scale", uv_scale)
	m.set_shader_parameter("cloud_tex", noise_texture())
	_cache[key] = m
	return m


static func water(shore_x: float) -> ShaderMaterial:
	var key := "water|%s" % shore_x
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = WATER_SHADER
	m.set_shader_parameter("noise_tex", noise_texture())
	m.set_shader_parameter("shore_x", shore_x)
	_cache[key] = m
	return m


## Material con viento para vegetacion: color plano o textura, y cuanto se
## dobla por metro de altura.
static func wind(color: Color, sway: float = 0.06, tex_name: String = "", uv_scale: Vector2 = Vector2.ONE) -> ShaderMaterial:
	var key := "wind|%s|%s|%s|%s" % [color, sway, tex_name, uv_scale]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = WIND_SHADER
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("sway", sway)
	if tex_name != "":
		m.set_shader_parameter("albedo_tex", load(TEX_DIR + tex_name + ".png"))
		m.set_shader_parameter("uv_scale", uv_scale)
	_cache[key] = m
	return m


static func grass(atlas: Texture2D, frames: int) -> ShaderMaterial:
	var key := "grass|%s" % atlas.resource_path
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = GRASS_SHADER
	m.set_shader_parameter("atlas", atlas)
	m.set_shader_parameter("frames", float(frames))
	_cache[key] = m
	return m


## Material nuevo (no cacheado) para un sprite con viento: cada parcela
## cambia su propia region (etapa de crecimiento).
static func sprite_wind(sheet: Texture2D, sway: float = 0.1) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SPRITE_WIND_SHADER
	m.set_shader_parameter("sheet", sheet)
	m.set_shader_parameter("sway", sway)
	return m

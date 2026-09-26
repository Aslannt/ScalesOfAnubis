class_name SpritesheetLoader
extends RefCounted
## Construye un SpriteFrames a partir de una tira horizontal (PNG) + un
## layout en JSON generado por tools/gen_characters.py, tools/gen_enemies.py,
## etc.: {"frame_w": W, "frame_h": H, "frames": ["south_idle_0", ...]}.
##
## IMPORTANTE: antes el layout era un .txt suelto leido con FileAccess, pero
## un .txt sin extension reconocida como resource NO se empaqueta en el PCK
## exportado (--export-release), asi que en el juego exportado todos los
## personajes/enemigos/antorchas quedaban invisibles (SpriteFrames vacio,
## sin ninguna animacion). Los .json SI se empaquetan (se ve en
## data/*.json, que siempre funciono en el build exportado), asi que el
## layout ahora usa el mismo formato. Ver DECISIONES.md.

const DEFAULT_FPS := 8.0


static func build(sheet_path: String, layout_path: String, fps: float = DEFAULT_FPS) -> SpriteFrames:
	var texture := load(sheet_path) as Texture2D
	var layout_file := FileAccess.open(layout_path, FileAccess.READ)
	if texture == null or layout_file == null:
		push_error("SpritesheetLoader: no se pudo cargar %s o %s" % [sheet_path, layout_path])
		return SpriteFrames.new()

	var parsed = JSON.parse_string(layout_file.get_as_text())
	if not (parsed is Dictionary):
		push_error("SpritesheetLoader: layout invalido en %s" % layout_path)
		return SpriteFrames.new()

	var frame_w: int = int(parsed.get("frame_w", 0))
	var frame_h: int = int(parsed.get("frame_h", 0))
	var frame_names: Array = parsed.get("frames", [])

	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	var anim_order: Array = []
	var anim_frames: Dictionary = {}

	for i in range(frame_names.size()):
		var line := String(frame_names[i]).strip_edges()
		if line == "":
			continue
		var idx := line.rfind("_")
		var anim_name := line.substr(0, idx)
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		if not anim_frames.has(anim_name):
			anim_frames[anim_name] = []
			anim_order.append(anim_name)
		anim_frames[anim_name].append(atlas)

	for anim_name in anim_order:
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, not anim_name.ends_with("attack"))
		for atlas in anim_frames[anim_name]:
			frames.add_frame(anim_name, atlas)

	return frames

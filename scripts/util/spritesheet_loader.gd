class_name SpritesheetLoader
extends RefCounted
## Construye un SpriteFrames a partir de una tira horizontal (PNG) + un archivo
## de layout generado por tools/gen_characters.py, tools/gen_enemies.py, etc.
## Formato del layout: primera linea "frame_w=W frame_h=H", luego una linea por
## frame con nombre "{grupo}_{anim}_{indice}" (ej: "south_walk_0").

const DEFAULT_FPS := 8.0


static func build(sheet_path: String, layout_path: String, fps: float = DEFAULT_FPS) -> SpriteFrames:
	var texture := load(sheet_path) as Texture2D
	var layout_file := FileAccess.open(layout_path, FileAccess.READ)
	if texture == null or layout_file == null:
		push_error("SpritesheetLoader: no se pudo cargar %s o %s" % [sheet_path, layout_path])
		return SpriteFrames.new()

	var lines := layout_file.get_as_text().split("\n")
	var header := lines[0]
	var frame_w := 0
	var frame_h := 0
	for part in header.split(" "):
		var kv := part.split("=")
		if kv.size() != 2:
			continue
		if kv[0] == "frame_w":
			frame_w = int(kv[1])
		elif kv[0] == "frame_h":
			frame_h = int(kv[1])

	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	var anim_order: Array = []
	var anim_frames: Dictionary = {}

	for i in range(1, lines.size()):
		var line := lines[i].strip_edges()
		if line == "":
			continue
		var idx := line.rfind("_")
		var anim_name := line.substr(0, idx)
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2((i - 1) * frame_w, 0, frame_w, frame_h)
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

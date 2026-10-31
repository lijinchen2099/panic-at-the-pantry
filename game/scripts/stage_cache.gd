extends Node
## Rasterize the unchanged vector scenery once at the actual output resolution.
## One reusable render target bounds memory use across boss and window changes.

class Painter:
	extends "res://scripts/art.gd"
	var course = 1

	func _draw() -> void:
		stage(course)

const DESIGN_SIZE = Vector2i(1600, 900)
var viewport: SubViewport
var painter: Painter
var course = 0
var pixel_size = Vector2i.ZERO
var preparations = 0

func prepare(next_course: int, next_size: Vector2i, antialiasing: int) -> void:
	if DisplayServer.get_name() == "headless":
		return
	next_size = next_size.max(Vector2i(2, 2))
	if next_course == course and next_size == pixel_size and is_instance_valid(viewport) and viewport.msaa_2d == antialiasing:
		return
	if not is_instance_valid(viewport):
		viewport = SubViewport.new()
		viewport.name = "CachedScenery"
		viewport.disable_3d = true
		viewport.gui_disable_input = true
		viewport.world_2d = World2D.new()
		viewport.size_2d_override = DESIGN_SIZE
		viewport.size_2d_override_stretch = true
		add_child(viewport)
		painter = Painter.new()
		viewport.add_child(painter)
	course = next_course
	pixel_size = next_size
	viewport.size = pixel_size
	viewport.msaa_2d = antialiasing
	painter.course = course
	painter.queue_redraw()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	preparations += 1

func texture() -> Texture2D:
	return viewport.get_texture() if is_instance_valid(viewport) else null

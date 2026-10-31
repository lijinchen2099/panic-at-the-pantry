extends SceneTree
## Native GPU checks: exact scenery pixels, one-shot caching, and resize reuse.

const Cache = preload("res://scripts/stage_cache.gd")
var checks = 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error("FAIL: " + description)

func rendered() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Render cache verification requires native GPU rendering.")
		quit(1)
		return
	var cache = Cache.new()
	root.add_child(cache)
	var reference = SubViewport.new()
	reference.disable_3d = true
	reference.gui_disable_input = true
	reference.world_2d = World2D.new()
	reference.size = Vector2i(3840, 2160)
	reference.size_2d_override = Vector2i(1600, 900)
	reference.size_2d_override_stretch = true
	reference.msaa_2d = root.msaa_2d
	root.add_child(reference)
	var painter = Cache.Painter.new()
	reference.add_child(painter)
	var previous_hash = 0
	for level in range(1, 6):
		cache.prepare(level, Vector2i(3840, 2160), root.msaa_2d)
		painter.course = level
		painter.queue_redraw()
		reference.render_target_update_mode = SubViewport.UPDATE_ONCE
		await rendered()
		var actual = cache.texture().get_image()
		var expected = reference.get_texture().get_image()
		check(actual.get_size() == Vector2i(3840, 2160), "Boss %d background is rendered at native 4K" % level)
		check(actual.get_data() == expected.get_data(), "Boss %d cached scenery exactly matches direct vector rendering" % level)
		var image_hash = hash(actual.get_data())
		check(image_hash != previous_hash, "Switching to boss %d refreshes the background" % level)
		previous_hash = image_hash
		# The node retains UPDATE_ONCE; the rendering server disables its backing target.
		check(RenderingServer.viewport_get_update_mode(cache.viewport.get_viewport_rid()) == RenderingServer.VIEWPORT_UPDATE_DISABLED, "Boss %d background stops rendering after preparation" % level)
		var preparations = cache.preparations
		cache.prepare(level, Vector2i(3840, 2160), root.msaa_2d)
		await rendered()
		check(cache.preparations == preparations, "Unchanged boss %d does not rebuild the cache" % level)
	cache.prepare(5, Vector2i(1280, 720), root.msaa_2d)
	await rendered()
	check(cache.texture().get_image().get_size() == Vector2i(1280, 720), "Shrinking the window resizes the cached background")
	cache.prepare(5, Vector2i(3840, 2160), root.msaa_2d)
	await rendered()
	check(cache.texture().get_image().get_data() == reference.get_texture().get_image().get_data(), "Returning to 4K restores full-resolution scenery")
	check(cache.get_child_count() == 1 and cache.preparations == 7, "Boss and resolution changes reuse one bounded render target")
	var game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	await rendered()
	check(game.stage_cache.pixel_size == root.size, "The real game caches actual window pixels instead of multiplying the design-canvas scale")
	reference.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	game.reparent(reference)
	await rendered()
	check(game.stage_cache.pixel_size == Vector2i(3840, 2160), "Moving the game to a 4K viewport refreshes its cache at exactly 4K")
	game.free()
	cache.free()
	reference.free()
	await create_timer(0.1).timeout
	print("RENDER CACHE TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

extends SceneTree
## Frame actual native-rendered game screens at a Mac App Store accepted size.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Store screenshots require native rendering.")
		quit(1)
		return
	var game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	root.size = Vector2i(1440, 900)
	var destination = ProjectSettings.globalize_path("res://../output/app-store/screenshots")
	DirAccess.make_dir_recursive_absolute(destination)
	game.spicy_clears.fill(true)
	game.difficulty = 1
	for level in range(1, 6):
		game.start_fight(level)
		game.elapsed = 8.5
		game.intro = 0
		game.fight_time = 24.6
		game.quip_time = 0
		for pattern in range(mini(2, game.encounter().warnings.size())):
			game._spawn_volley(pattern, 2)
		game.step_fight(0.45)
		game._prepare_stage()
		game._sync_boss_selector()
		game.queue_redraw()
		for frame in range(3):
			await process_frame
			game.mode = "fight"
			game._sync_boss_selector()
			game.queue_redraw()
			await RenderingServer.frame_post_draw
		var image = root.get_texture().get_image()
		# Godot omits the window's letterbox area from the viewport texture.
		# Preserve the gameplay aspect ratio inside a plain 16:10 store canvas.
		var fit = minf(1440.0 / image.get_width(), 900.0 / image.get_height())
		image.resize(roundi(image.get_width() * fit), roundi(image.get_height() * fit), Image.INTERPOLATE_LANCZOS)
		image.convert(Image.FORMAT_RGB8)
		var canvas = Image.create(1440, 900, false, Image.FORMAT_RGB8)
		canvas.fill(Color("fff4d9"))
		canvas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), (canvas.get_size() - image.get_size()) / 2)
		var path = destination.path_join("%02d-boss.png" % level)
		if canvas.save_png(path) != OK:
			push_error("Could not save " + path)
			quit(1)
			return
		print("Saved actual game screenshot: " + path)
	game.free()
	await create_timer(0.1).timeout
	quit()

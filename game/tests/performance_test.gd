extends SceneTree
## Real Metal rendering into a verified 3840×2160 target, even on a 1080p monitor.

class BenchGame:
	extends "res://scripts/main.gd"
	var active = false
	var target_phase = 1
	var stress = false
	var draw_ms: Array[float] = []
	var tick_ms: Array[float] = []

	func _draw() -> void:
		var began = Time.get_ticks_usec()
		super._draw()
		draw_ms.append((Time.get_ticks_usec() - began) / 1000.0)

	func _physics_process(dt: float) -> void:
		if active:
			mode = "fight"
			hurt_timer = 999
			boss_hp = boss_max_hp * (0.85 if target_phase == 1 else 0.4)
			pressed[key_bindings.shoot] = true
			if charge >= MAX_CHARGE:
				taps[key_bindings.super] = true
			if stress and particles.size() < 450:
				burst(Vector2(800, 460), 450 - particles.size(), GOLD, 550)
		var began = Time.get_ticks_usec()
		super._physics_process(dt)
		tick_ms.append((Time.get_ticks_usec() - began) / 1000.0)

var game
var target: SubViewport
var seconds = 4.0
var only_level = 0
var stress_only = false
var results: Array[Dictionary] = []
var output_path = "res://../build/performance-4k.json"

func _initialize() -> void:
	_run.call_deferred()

func stats(values: Array) -> Dictionary:
	if values.is_empty():
		return {}
	values.sort()
	var total = 0.0
	for value in values:
		total += value
	return {"mean": snapped(total / values.size(), 0.001), "p95": snapped(values[mini(values.size() - 1, int(values.size() * 0.95))], 0.001), "p99": snapped(values[mini(values.size() - 1, int(values.size() * 0.99))], 0.001), "max": snapped(values[-1], 0.001)}

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("4K performance checks require native GPU rendering.")
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seconds="):
			seconds = maxf(1.0, float(argument.trim_prefix("--seconds=")))
		elif argument.begins_with("--level="):
			only_level = int(argument.trim_prefix("--level="))
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
		elif argument == "--stress-only":
			stress_only = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	target = SubViewport.new()
	target.size = Vector2i(3840, 2160)
	target.size_2d_override = Vector2i(1600, 900)
	target.size_2d_override_stretch = true
	target.disable_3d = true
	target.gui_disable_input = true
	target.msaa_2d = root.msaa_2d
	target.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(target)
	var preview = TextureRect.new()
	preview.texture = target.get_texture()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(1600, 900)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(preview)
	game = BenchGame.new()
	game.test_mode = true
	target.add_child(game)
	game.spicy_clears.fill(true)
	game.difficulty = 2
	root.gui_disable_input = true
	var failed = false
	for level in range(1, 6):
		if only_level != 0 and only_level != level:
			continue
		for profile in (["stress"] if stress_only else ["phase-1", "phase-2", "stress"]):
			game.active = false
			game.start_fight(level)
			game.intro = 0
			game.target_phase = 1 if profile == "phase-1" else 2
			game.phase = game.target_phase
			game.stress = profile == "stress"
			for pattern in range(game.encounter().warnings.size()):
				game._spawn_volley(pattern, 3)
			game.active = true
			# Exclude first-use pipeline compilation and background cache preparation.
			await create_timer(1.25).timeout
			game.draw_ms.clear()
			game.tick_ms.clear()
			var frames: Array[float] = []
			var calls: Array[float] = []
			var max_hazards = 0
			var max_particles = 0
			var last = Time.get_ticks_usec()
			var began = last
			while Time.get_ticks_usec() - began < int(seconds * 1000000):
				await RenderingServer.frame_post_draw
				var now = Time.get_ticks_usec()
				frames.append((now - last) / 1000.0)
				calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
				max_hazards = maxi(max_hazards, game.hazards.size())
				max_particles = maxi(max_particles, game.particles.size())
				last = now
			var wall_seconds = (last - began) / 1000000.0
			var frame_stats = stats(frames)
			var fps = frames.size() / wall_seconds
			var exact_resolution = Vector2i(target.get_texture().get_size()) == Vector2i(3840, 2160) and game.stage_cache.pixel_size == Vector2i(3840, 2160)
			var passed = exact_resolution and fps >= 60.0 and frame_stats.p95 <= 1000.0 / 60.0
			failed = failed or not passed
			var row = {"level": level, "profile": profile, "resolution": str(target.get_texture().get_size()), "background_resolution": str(game.stage_cache.pixel_size), "fps": snapped(fps, 0.1), "frame_ms": frame_stats, "draw_cpu_ms": stats(game.draw_ms.duplicate()), "physics_cpu_ms": stats(game.tick_ms.duplicate()), "draw_calls": stats(calls), "max_hazards": max_hazards, "max_particles": max_particles, "passed": passed}
			results.append(row)
			print(JSON.stringify(row))
			if level == 3 and profile == "stress":
				target.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../build/combat-4k.png"))
	var report = {"render_target": {"width": target.size.x, "height": target.size.y, "msaa": target.msaa_2d}, "renderer": RenderingServer.get_current_rendering_method(), "gpu": RenderingServer.get_video_adapter_name(), "godot": Engine.get_version_info().string, "seconds_per_profile": seconds, "target_fps": 60, "all_passed": not failed, "results": results}
	var destination = ProjectSettings.globalize_path(output_path)
	var file = FileAccess.open(destination, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	game.active = false
	game.free()
	await create_timer(0.1).timeout
	print("4K PERFORMANCE: %d profiles, %s. Report: %s" % [results.size(), "PASS" if not failed else "FAIL", destination])
	quit(1 if failed else 0)

extends SceneTree
## Campaign progression, the second boss, and save migration using a temp file.

var game
var checks = 0
var failures: Array[String] = []
const DT = 1.0 / 120.0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error("FAIL: " + description)

func key(code: int, held: bool = true) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = held
	game._input(event)

func tick(count: int = 1) -> void:
	for i in range(count):
		game.step_fight(DT)
		game.taps.clear()

func prepare(level: int = 2) -> void:
	game.start_fight(level)
	game.intro = 0
	game.attack_clock = 1000

func shoot_to_victory() -> bool:
	game.hurt_timer = 999
	key(KEY_F)
	var saw_second_phase = false
	for i in range(120 * 75):
		if game.charge >= 5:
			key(KEY_Q)
			key(KEY_Q, false)
		tick()
		saw_second_phase = saw_second_phase or game.phase == 2
		if game.mode != "fight":
			break
	return game.mode == "win" and saw_second_phase

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.muted = true
	game._apply_mute()
	game.difficulty = 0
	game.spicy_clears.fill(false)
	game.unlocked_level = 1
	game.selected_level = 1
	game.best_time = 0
	game.second_best_time = 0
	game.third_best_time = 0
	key(KEY_2)
	check(game.selected_level == 2, "Second course can be selected on a fresh profile")
	key(KEY_1)
	key(KEY_ENTER)
	game.intro = 0
	check(game.current_level == 1, "New campaign starts with the toaster")
	check(shoot_to_victory(), "Real bullets and charged supers complete both toaster phases with attacks active")
	check(game.unlocked_level == 2, "Toaster victory unlocks the second course")
	check(game.best_time > 0 and game.second_best_time == 0, "First-course victory records only first-course time")
	var first_record = game.best_time
	game.charge = 3
	game.health = 1
	key(KEY_ENTER)
	check(game.current_level == 2 and game.mode == "fight", "Enter advances directly to Duke de Blend")
	check(game.health == game.max_health and game.charge == 0, "Next course restores hearts and resets super meter")
	check(game.hazards.is_empty() and game.shots.is_empty(), "Transition clears first-course attacks and bullets")
	check(game.phase == 1 and game.intro > 0 and game.boss_hp == 460, "Blender starts with a fresh two-phase encounter")
	check(game.encounter().boss == "DUKE DE BLEND", "Second encounter uses its own boss identity")
	game.intro = 0
	check(shoot_to_victory(), "Real bullets and charged supers complete both blender phases with attacks active")
	check(game.fight_time < 65, "Blender fight can finish within the balance target")
	check(game.best_time == first_record and game.second_best_time > 0, "Second-course record does not overwrite toaster record")
	key(KEY_R)
	check(game.current_level == 2 and game.boss_hp == 460, "R can replay the blender instead of advancing")
	key(KEY_ESCAPE)
	key(KEY_BACKSPACE)
	key(KEY_2)
	check(game.mode == "title" and game.selected_level == 2, "Unlocked blender can be selected from title")
	key(KEY_ENTER)
	check(game.current_level == 2, "Title selection launches the second level")
	for pattern in range(3):
		prepare()
		game._begin_attack(pattern)
		tick()
		var expected = ["banana", "smoothie", "berry"][pattern]
		check(not game.hazards.is_empty() and game.hazards[0].kind == expected, "Blender pattern %d creates %s" % [pattern, expected])
		if pattern == 1:
			check(game.hazards.size() == 3 and game.hazards[0].v != game.hazards[2].v, "Smoothie spray fans out into three distinct paths")
	prepare()
	game.hurt_timer = 999
	game._spawn_blender_volley(0, 1)
	check(game.hazards[0].v.x < 0, "Banana initially travels toward Sunny")
	tick(500)
	check(not game.hazards.is_empty() and game.hazards[0].v.x > 0, "Banana turns and returns instead of flying straight")
	for test_difficulty in [0, 1, 2]:
		game.difficulty = test_difficulty
		for test_phase in [1, 2]:
			for lane in [1, 2]:
				prepare()
				game.phase = test_phase
				game._spawn_blender_volley(0, lane)
				tick(360)
				check(game.health == game.max_health - 1, "Banana lane %d hits a grounded player in difficulty %d, phase %d" % [lane, test_difficulty, test_phase])
	game.difficulty = 0
	for lane in [1, 2]:
		prepare()
		game._spawn_blender_volley(0, lane)
		var jumped = false
		for i in range(360):
			if game.hazards.is_empty():
				break
			if not jumped and game.hazards[0].p.x < 360:
				key(KEY_SPACE)
				jumped = true
			tick()
			if not game.hazards.is_empty() and game.hazards[0].p.x < game.player.x - 65:
				break
		check(jumped and game.health == game.max_health, "A timed jump clears grounded banana lane %d" % lane)
	prepare()
	game.hurt_timer = 999
	game._spawn_blender_volley(2, 2)
	tick(180)
	check(not game.hazards.is_empty() and game.hazards[0].bounces > 0, "Berries bounce off the counter")
	for test_difficulty in [0, 1, 2]:
		game.difficulty = test_difficulty
		for test_phase in [1, 2]:
			prepare()
			game.phase = test_phase
			game.attack_clock = 0
			game.hurt_timer = 999
			var seen: Dictionary = {}
			var allowed = true
			for i in range(120 * 40):
				tick()
				for hazard in game.hazards:
					seen[hazard.kind] = true
					allowed = allowed and hazard.kind in ["banana", "smoothie", "berry"]
				allowed = allowed and not game.warning.contains("ICE")
			check(allowed and seen.size() == 3 and game.attack_index >= 7, "Blender cycles through three attacks without ice in difficulty %d, phase %d" % [test_difficulty, test_phase])
	game.difficulty = 0
	for kind in ["banana", "smoothie", "berry"]:
		prepare()
		game._hazard(Vector2(600, 600), Vector2(-350, 0), kind, false, 25, 0)
		game.shots.append({"p": Vector2(500, 600), "v": Vector2(24000, 0), "life": 1.0})
		tick()
		check(game.hazards.size() == (1 if kind == "banana" else 0) and game.shots.is_empty(), "Bullets respect the blender's shootable food and armored bananas: " + kind)
	for kind in ["smoothie", "berry"]:
		prepare()
		game._hazard(game.player - Vector2(0, 54), Vector2.ZERO, kind, true, 24, 0)
		key(KEY_G)
		tick()
		check(game.hazards.is_empty() and game.charge >= 1.25, "G parries pink blender attack: " + kind)
	prepare()
	game.boss_hp = 229
	tick()
	check(game.phase == 2 and game.warning.contains("TURBO"), "Half health announces blender turbo mode")
	prepare()
	game.shots.append({"p": Vector2(1050, 420), "v": Vector2(24000, 0), "life": 1.0})
	tick()
	check(game.boss_hp < game.boss_max_hp, "Blender pitcher has a hittable collision area")
	prepare()
	game.charge = 5
	key(KEY_Q)
	tick()
	check(game.boss_hp == 460 and game.energy_balls.size() == 1, "Blender super launches without immediate damage")
	tick(150)
	check(game.boss_hp == 340 and game.charge == 0, "Energy ball hits the blender for heavy damage")
	prepare()
	game.health = 1
	game._hazard(game.player - Vector2(0, 53), Vector2.ZERO, "berry", false, 24, 0)
	tick()
	check(game.mode == "lose", "Blender attacks can defeat Sunny")
	key(KEY_ENTER)
	check(game.current_level == 2 and game.health == 5 and game.phase == 1, "Retry stays on level two and restores the encounter")
	game.difficulty = 2
	key(KEY_R)
	check(game.current_level == 2 and game.health == 3, "R restarts current course with Spicy difficulty")
	# Exercise the real save methods against a disposable file, never the profile.
	var save_path = "/private/tmp/pantry-level-test-%d.cfg" % OS.get_process_id()
	game.unlocked_level = 3
	game.selected_level = 2
	var second_record = game.second_best_time
	game._save_settings(save_path)
	game.unlocked_level = 1
	game.selected_level = 1
	game.best_time = 0
	game.second_best_time = 0
	game._load_settings(save_path)
	check(game.unlocked_level == 3 and game.selected_level == 2, "Unlocked and selected courses survive a save/load round trip")
	check(is_equal_approx(game.best_time, first_record) and is_equal_approx(game.second_best_time, second_record), "Both course records survive a save/load round trip")
	var legacy = ConfigFile.new()
	legacy.set_value("records", "best_time", 31.5)
	legacy.set_value("records", "best_rank", "A")
	legacy.save(save_path)
	game.unlocked_level = 1
	game._load_settings(save_path)
	check(game.unlocked_level == 2 and game.best_time == 31.5 and game.best_rank == "A", "A win from the old one-level game unlocks the blender")
	check(game.second_best_time == 0, "Legacy save starts with an empty blender record")
	DirAccess.remove_absolute(save_path)
	game.free()
	await create_timer(0.1).timeout
	print("LEVEL TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

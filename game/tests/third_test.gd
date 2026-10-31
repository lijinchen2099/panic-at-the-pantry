extends SceneTree
## Third-course progression, attacks, damage, and migration of existing saves.

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

func prepare() -> void:
	game.start_fight(3)
	game.intro = 0
	game.attack_clock = 1000

func fight_to_victory() -> bool:
	game.hurt_timer = 999
	key(KEY_F)
	var saw_second_phase = false
	for i in range(120 * 90):
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
	game.best_time = 38.0
	game.best_rank = "A"
	game.second_best_time = 0
	game.third_best_time = 0
	game.unlocked_level = 2
	game.selected_level = 2
	key(KEY_3)
	check(game.selected_level == 3, "Third course can be selected before the blender is defeated")
	key(KEY_2)
	key(KEY_ENTER)
	game.intro = 0
	check(fight_to_victory(), "Blender remains winnable with bullets and charged energy balls")
	check(game.unlocked_level == 3 and game.second_best_time > 0, "Blender victory unlocks Madame Whistle")
	var second_record = game.second_best_time
	game.health = 1
	game.charge = 4
	key(KEY_ENTER)
	check(game.current_level == 3 and game.encounter().boss == "MADAME WHISTLE", "Enter advances from the blender to the new boss")
	check(game.health == 5 and game.charge == 0, "Third course starts with fresh hearts and an empty meter")
	check(game.hazards.is_empty() and game.shots.is_empty() and game.energy_balls.is_empty(), "Transition clears all earlier projectiles")
	check(game.boss_hp == 500 and game.phase == 1 and game.intro > 0, "Third boss starts a fresh 500-health encounter")
	game.intro = 0
	check(fight_to_victory(), "Madame Whistle can be defeated through both phases with real bullets and energy balls")
	check(game.fight_time < 65, "Third fight stays within the prototype balance target")
	check(game.third_best_time > 0 and game.best_time == 38 and game.second_best_time == second_record, "Third record is separate from earlier course records")
	key(KEY_ENTER)
	check(game.current_level == 4 and game.encounter().boss == "SIR SIZZLE", "Third-course victory advances to Sir Sizzle")
	key(KEY_ESCAPE)
	key(KEY_BACKSPACE)
	key(KEY_1)
	check(game.selected_level == 1 and game.unlocked_level == 4, "Selecting an older course preserves fourth-course campaign progress")
	key(KEY_3)
	key(KEY_ENTER)
	check(game.current_level == 3 and game.mode == "fight", "The 3 key selects the unlocked teapot from the title")
	for pattern in range(2):
		prepare()
		game._begin_attack(pattern)
		tick()
		check(not game.hazards.is_empty() and game.hazards[0].kind == ["tea", "biscuit"][pattern], "Teapot pattern %d creates its own attack" % pattern)
	for test_difficulty in [0, 1, 2]:
		game.difficulty = test_difficulty
		for test_phase in [1, 2]:
			for pattern in range(2):
				prepare()
				game.phase = test_phase
				game._spawn_kettle_volley(pattern, 1)
				tick(360)
				check(game.health == game.max_health - 1, "Teapot attack %d can hit a grounded player in difficulty %d, phase %d" % [pattern, test_difficulty, test_phase])
			prepare()
			game.phase = test_phase
			game.hurt_timer = 999
			game.attack_clock = 0
			var seen: Dictionary = {}
			var allowed = true
			for i in range(120 * 38):
				tick()
				for hazard in game.hazards:
					seen[hazard.kind] = true
					allowed = allowed and hazard.kind in ["tea", "biscuit"]
				allowed = allowed and not game.warning.contains("LEMON")
			check(allowed and seen.size() == 2 and game.attack_index >= 7, "Third boss cycles tea and biscuits without lemons in difficulty %d, phase %d" % [test_difficulty, test_phase])
	game.difficulty = 0
	prepare()
	game.hurt_timer = 999
	game._spawn_kettle_volley(0, 1)
	check(game.hazards[0].v.y < 0 and game.hazards[0].g > 0, "Tea begins as an upward arc")
	tick(150)
	check(game.hazards[0].v.y > 0, "Tea curves down toward Sunny")
	prepare()
	game.hurt_timer = 999
	game._spawn_kettle_volley(1, 1)
	var upward = false
	var downward = false
	for i in range(120):
		tick()
		upward = upward or game.hazards[0].v.y < 0
		downward = downward or game.hazards[0].v.y > 0
	check(upward and downward, "Biscuits wobble vertically as they cross the counter")
	for kind in ["tea", "biscuit"]:
		prepare()
		game._hazard(Vector2(600, 600), Vector2.ZERO, kind, false, 25, 0)
		game.shots.append({"p": Vector2(500, 600), "v": Vector2(24000, 0), "life": 1.0})
		tick()
		check(game.hazards.is_empty() and game.shots.is_empty(), "Bullets destroy the teapot's " + kind)
	for kind in ["tea", "biscuit"]:
		prepare()
		game._hazard(game.player - Vector2(0, 54), Vector2.ZERO, kind, true, 24, 0)
		key(KEY_G)
		tick()
		check(game.hazards.is_empty() and game.charge >= 1.25, "G parries pink " + kind)
	prepare()
	game.boss_hp = 249
	tick()
	check(game.phase == 2 and game.warning.contains("BOILING"), "Half health announces the boiling-point phase")
	prepare()
	game.health = 1
	game._hazard(game.player - Vector2(0, 53), Vector2.ZERO, "biscuit", false, 25, 0)
	tick()
	check(game.mode == "lose", "Third-boss attacks can defeat Sunny")
	key(KEY_ENTER)
	check(game.current_level == 3 and game.health == 5 and game.boss_hp == 500, "Retry stays on the third boss")
	var save_path = "/private/tmp/pantry-third-test-%d.cfg" % OS.get_process_id()
	game.unlocked_level = 3
	game.selected_level = 3
	var third_record = game.third_best_time
	game._save_settings(save_path)
	game.unlocked_level = 1
	game.selected_level = 1
	game.third_best_time = 0
	game._load_settings(save_path)
	check(game.unlocked_level == 4 and game.selected_level == 3, "Third-course victory and selection survive saving and prepare the fourth course")
	check(is_equal_approx(game.third_best_time, third_record), "Third-course record survives saving")
	var old_save = ConfigFile.new()
	old_save.set_value("records", "best_time", 38.0)
	old_save.set_value("records", "level_2_best_time", 47.0)
	old_save.set_value("progress", "unlocked_level", 2)
	old_save.save(save_path)
	game._load_settings(save_path)
	check(game.unlocked_level == 3 and game.third_best_time == 0, "A saved blender victory from the two-course game unlocks the new boss")
	old_save.set_value("progress", "unlocked_level", 3)
	old_save.save(save_path)
	game._load_settings(save_path)
	check(game.unlocked_level == 3, "Loading an earlier toaster record cannot downgrade a third-course unlock")
	DirAccess.remove_absolute(save_path)
	game.free()
	await create_timer(0.1).timeout
	print("THIRD TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

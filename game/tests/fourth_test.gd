extends SceneTree
## Fourth-course attacks, progression, records, and old-save compatibility.

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

func prepare() -> void:
	game.start_fight(4)
	game.intro = 0
	game.attack_clock = 1000

func tick(count: int = 1) -> void:
	for i in range(count):
		game.step_fight(DT)
		game.taps.clear()

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
	game.difficulty = 0
	game.spicy_clears.fill(false)
	game.best_time = 38
	game.second_best_time = 43
	game.third_best_time = 49
	game.fourth_best_time = 0
	game.start_fight(3)
	game.fight_time = 50
	game._win()
	key(KEY_ENTER)
	check(game.current_level == 4 and game.encounter().boss == "SIR SIZZLE", "Enter advances from Madame Whistle to Sir Sizzle")
	check(game.health == 5 and game.boss_hp == 540 and game.charge == 0 and game.phase == 1, "Fourth course starts with fresh hearts, full boss health, and an empty super")
	check(game.hazards.is_empty() and game.energy_balls.is_empty() and game.shots.is_empty(), "Fourth course clears previous projectiles")
	game.intro = 0
	check(fight_to_victory(), "Sir Sizzle can be defeated with real bullets and energy balls across both phases")
	check(game.fourth_best_time > 0 and game.third_best_time == 49 and game.best_time == 38, "Fourth-course record is separate from earlier bosses")
	var fourth_record = game.fourth_best_time
	key(KEY_ENTER)
	check(game.mode == "title" and game.current_level == 4 and not game.chef_unlocked(), "Cozy victory returns to boss selection while the Chef stays locked")
	for setting in [0, 1, 2]:
		game.difficulty = setting
		for test_phase in [1, 2]:
			for pattern in range(2):
				prepare()
				game.phase = test_phase
				game._spawn_skillet_volley(pattern, 2)
				check(game.hazards[0].kind == ["pancake", "oil"][pattern], "Mode %d phase %d pattern %d creates the correct attack" % [setting, test_phase, pattern])
				tick(360)
				check(game.health < game.max_health, "Mode %d phase %d pattern %d can hit grounded Sunny" % [setting, test_phase, pattern])
			prepare()
			game.phase = test_phase
			game.attack_clock = 0
			game.hurt_timer = 999
			var seen = {}
			var allowed = true
			for i in range(120 * 35):
				tick()
				for hazard in game.hazards:
					seen[hazard.kind] = true
					allowed = allowed and hazard.kind in ["pancake", "oil"] and hazard.breakable
				allowed = allowed and not game.warning.contains("SPATULA")
			check(allowed and seen.size() == 2 and game.attack_index >= 7, "Mode %d phase %d cycles shootable pancakes and oil without armored spatulas" % [setting, test_phase])
	game.difficulty = 0
	for kind in ["pancake", "oil"]:
		prepare()
		game._hazard(Vector2(600, 600), Vector2.ZERO, kind, false, 25, 0)
		game.shots.append({"p": Vector2(500, 600), "v": Vector2(24000, 0), "life": 1.0})
		tick()
		check(game.hazards.is_empty(), "Bullets destroy " + kind)
		prepare()
		game._hazard(game.player - Vector2(0, 54), Vector2.ZERO, kind, true, 24, 0)
		key(KEY_G)
		tick()
		check(game.charge >= 1.25 and game.hazards.is_empty(), "G parries pink " + kind)
	prepare()
	game.boss_hp = game.boss_max_hp * 0.5
	tick()
	check(game.phase == 2 and game.warning.contains("FRENZY"), "Half health announces Frying Frenzy")
	prepare()
	game.health = 1
	game._hazard(game.player - Vector2(0, 53), Vector2.ZERO, "oil", false, 20, 0)
	tick()
	check(game.mode == "lose", "Sir Sizzle can defeat Sunny")
	key(KEY_ENTER)
	check(game.current_level == 4 and game.health == 5 and game.boss_hp == 540, "Retry restores the fourth encounter")
	var save_path = "/private/tmp/pantry-fourth-test-%d.cfg" % OS.get_process_id()
	game._save_settings(save_path)
	game.fourth_best_time = 0
	game.selected_level = 1
	game._load_settings(save_path)
	check(game.selected_level == 4 and is_equal_approx(game.fourth_best_time, fourth_record), "Fourth-course selection and record survive saving")
	var old_save = ConfigFile.new()
	old_save.set_value("records", "best_time", 38.0)
	old_save.set_value("records", "level_2_best_time", 43.0)
	old_save.set_value("records", "level_3_best_time", 49.0)
	old_save.set_value("settings", "difficulty_id", "regular")
	old_save.set_value("settings", "selected_level", 3)
	old_save.set_value("progress", "unlocked_level", 3)
	old_save.save(save_path)
	game._load_settings(save_path)
	check(game.unlocked_level == 4 and game.third_best_time == 49 and game.fourth_best_time == 0, "A three-course save preserves records and prepares the fourth course")
	check(game.difficulty == 1 and game.selected_level == 3, "Upgrade preserves chosen difficulty and boss")
	DirAccess.remove_absolute(save_path)
	game.free()
	await create_timer(0.1).timeout
	print("FOURTH TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

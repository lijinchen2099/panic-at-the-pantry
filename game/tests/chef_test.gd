extends SceneTree
## Spicy-only unlock enforcement, saved progress, and the complete fifth fight.

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

func victory(level: int, setting: int) -> void:
	game.difficulty = setting
	game.start_fight(level)
	game.intro = 0
	game.hurt_timer = 999
	game.boss_hp = 0
	tick()

func prepare(setting: int = 0, test_phase: int = 1) -> void:
	game.difficulty = setting
	game.start_fight(5)
	game.intro = 0
	game.phase = test_phase
	game.attack_clock = 1000

func fight_to_victory() -> bool:
	game.hurt_timer = 999
	game.attack_clock = 0
	key(KEY_F)
	var saw_second_phase = false
	for i in range(120 * 110):
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
	var save_path = "/private/tmp/pantry-chef-test-%d.cfg" % OS.get_process_id()
	var fresh = ConfigFile.new()
	fresh.save(save_path)
	game._load_settings(save_path)
	check(not game.chef_unlocked() and not game.level_available(5), "Fresh profiles cannot play level five")
	check(not game.start_fight(5) and game.mode == "title", "Central fight entry rejects the locked Chef")
	key(KEY_KP_5)
	key(KEY_ENTER)
	check(game.selected_level == 5 and game.mode == "title", "Number-pad selection and Enter cannot bypass the lock")
	for setting in [0, 1]:
		for level in [1, 2, 3, 4]:
			victory(level, setting)
			check(game.spicy_clears.count(true) == 0, "Mode %d victory against boss %d does not count as Spicy" % [setting, level])
		key(KEY_ENTER)
		check(game.mode == "title" and not game.chef_unlocked(), "Completing boss four in mode %d leaves the Chef locked" % setting)
	for missing in range(4):
		game.spicy_clears.assign([true, true, true, true])
		game.spicy_clears[missing] = false
		check(not game.chef_unlocked() and not game.start_fight(5), "Missing Spicy win %d blocks level five even with the other three" % (missing + 1))
	game.spicy_clears.fill(false)
	game.difficulty = 2
	game.start_fight(1)
	game.intro = 0
	game.health = 0
	tick()
	check(game.mode == "lose" and game.spicy_clears.count(true) == 0, "A Spicy defeat earns no unlock credit")
	game.start_fight(1)
	key(KEY_B)
	check(game.spicy_clears.count(true) == 0, "Leaving a Spicy fight earns no unlock credit")
	game.difficulty = 1
	game.start_fight(1)
	game.difficulty = 2
	game.boss_hp = 0
	game.intro = 0
	tick()
	check(not game.spicy_clears[0], "Credit uses difficulty at fight start, not a later settings value")
	game.spicy_clears.fill(false)
	for level in [3, 1, 4, 2]:
		var previous_count = game.spicy_clears.count(true)
		victory(level, 2)
		check(game.mode == "win" and game.spicy_clears[level - 1], "Spicy victory records boss %d" % level)
		check(game.spicy_clears.count(true) == previous_count + 1, "Each distinct Spicy victory adds exactly one checklist entry")
		check(game.chef_unlocked() == (previous_count == 3), "Chef unlocks only after the fourth distinct Spicy win")
		var expected = game.spicy_clears.duplicate()
		game._save_settings(save_path)
		game.spicy_clears.fill(false)
		game._load_settings(save_path)
		check(game.spicy_clears == expected, "Partial Spicy progress for boss %d survives saving and loading" % level)
		victory(level, 2)
		check(game.spicy_clears == expected, "Repeating boss %d cannot substitute for another Spicy victory" % level)
	check(game.chef_unlocked() and game.unlocked_level == 5, "All four saved Spicy clears unlock level five")
	game._show_boss_selection()
	key(KEY_5)
	check(game.selected_level == 5 and not game.start_button.disabled, "Unlocked Chef can be selected with 5 and has an enabled start button")
	key(KEY_ENTER)
	check(game.current_level == 5 and game.mode == "fight" and game.fight_difficulty == 2, "Enter starts the unlocked Chef on Spicy")
	key(KEY_B)
	game.difficulty = 1
	game._sync_boss_selector()
	check(game.difficulty_button.disabled and game.difficulty_button.text.contains("SPICY ONLY"), "Chef preview shows a disabled Spicy-only difficulty control")
	key(KEY_C)
	check(game.effective_difficulty() == 2 and game.difficulty == 1, "C cannot lower the Chef difficulty or replace the other bosses' preference")
	game._save_settings(save_path)
	game.difficulty = 0
	game._load_settings(save_path)
	check(game.selected_level == 5 and game.effective_difficulty() == 2 and game.difficulty == 1, "Chef selection reloads as Spicy while preserving Regular for other bosses")
	key(KEY_1)
	check(not game.difficulty_button.disabled and game.effective_difficulty() == 1, "Returning to another boss restores the preferred difficulty and enables its control")
	victory(4, 2)
	key(KEY_ENTER)
	check(game.current_level == 5 and game.mode == "fight" and game.fight_difficulty == 2, "Enter advances from Sir Sizzle into a Spicy Chef encounter")
	for setting in [0, 1, 2]:
		prepare(setting)
		check(game.boss_hp == 1728 and game.boss_max_hp == 1728 and game.health == 3 and game.effective_difficulty() == 2 and game.fight_difficulty == 2, "Chef has doubled Spicy health and three hearts when requested from mode %d" % setting)
		check(fight_to_victory(), "Spicy Chef can be defeated through both phases when entered from mode %d" % setting)
		key(KEY_ENTER)
		check(game.current_level == 5 and game.mode == "fight" and game.fight_difficulty == 2 and game.health == 3, "Final victory replays the Chef on Spicy when entered from mode %d" % setting)
		for test_phase in [1, 2]:
			for pattern in range(3):
				prepare(setting, test_phase)
				game._spawn_volley(pattern, 2)
				check(game.hazards[0].kind == ["ravioli", "sauce", "whisk"][pattern], "Chef mode %d phase %d pattern %d creates the correct projectile" % [setting, test_phase, pattern])
				tick(360)
				check(game.health < game.max_health, "Chef mode %d phase %d pattern %d can hit grounded Sunny" % [setting, test_phase, pattern])
	for test_phase in [1, 2]:
		prepare(2, test_phase)
		game.hurt_timer = 999
		game.attack_clock = 0
		var seen = {}
		var allowed = true
		for i in range(120 * 35):
			tick()
			for hazard in game.hazards:
				seen[hazard.kind] = true
				allowed = allowed and hazard.kind in ["ravioli", "sauce", "whisk"]
			allowed = allowed and not game.warning.contains("PEPPER")
		check(allowed and seen.size() == 3 and game.attack_index >= 7, "Chef phase %d cycles all remaining attacks without pepper" % test_phase)
	for kind in ["ravioli", "sauce"]:
		prepare()
		game._hazard(Vector2(600, 600), Vector2.ZERO, kind, false, 25, 0)
		game.shots.append({"p": Vector2(500, 600), "v": Vector2(24000, 0), "life": 1.0})
		tick()
		check(game.hazards.is_empty(), "Chef's " + kind + " can be shot")
		prepare()
		game._hazard(game.player - Vector2(0, 54), Vector2.ZERO, kind, true, 25, 0)
		key(KEY_G)
		tick()
		check(game.charge >= 1.25 and game.hazards.is_empty(), "Chef's pink " + kind + " can be parried")
	prepare()
	game.boss_hp = game.boss_max_hp * 0.5
	tick()
	check(game.phase == 2 and game.warning.contains("DINNER RUSH"), "Chef announces Dinner Rush at half health")
	game._damage_boss(10)
	check(game.boss_hp == game.boss_max_hp * 0.5 - 10, "Chef takes full damage at exactly half health")
	game._damage_boss(10)
	check(game.boss_hp == game.boss_max_hp * 0.5 - 15, "Chef halves Sunny's damage below half health")
	var fifth_record = game.fifth_best_time
	game._save_settings(save_path)
	game.fifth_best_time = 0
	game.spicy_clears.fill(false)
	game._load_settings(save_path)
	check(game.chef_unlocked(), "Earned Chef unlock survives loading")
	check(game.selected_level == 5, "Chef selection survives loading")
	check(is_equal_approx(game.fifth_best_time, fifth_record) and fifth_record > 0, "Chef record survives loading with floating-point save precision")
	var legacy = ConfigFile.new()
	for record in ["best_time", "level_2_best_time", "level_3_best_time", "level_4_best_time", "level_5_best_time"]:
		legacy.set_value("records", record, 40.0)
	legacy.set_value("settings", "difficulty_id", "spicy")
	legacy.set_value("settings", "selected_level", 5)
	legacy.set_value("progress", "unlocked_level", 5)
	legacy.save(save_path)
	game._load_settings(save_path)
	check(not game.chef_unlocked() and game.unlocked_level == 4, "Legacy times and a Spicy preference do not invent Spicy victory evidence")
	check(game.best_time == 40 and game.fourth_best_time == 40, "Legacy migration preserves earlier best-time records")
	check(not game.start_fight(5), "A saved selected level or old unlock integer cannot bypass Chef requirements")
	for state in ["lose", "paused", "win"]:
		game.current_level = 5
		game.mode = state
		key(KEY_R)
		check(game.mode == "title", "Restart from %s cannot bypass a missing unlock" % state)
	DirAccess.remove_absolute(save_path)
	game.free()
	await create_timer(0.1).timeout
	print("CHEF TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

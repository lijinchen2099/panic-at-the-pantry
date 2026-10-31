extends SceneTree
## Difficulty balance across every boss, attack, phase, and saved profile.

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

func key(code: int) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._input(event)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	game._input(event)

func tick(count: int = 1) -> void:
	for i in range(count):
		game.step_fight(DT)
		game.taps.clear()

func prepare(level: int, setting: int) -> void:
	game.difficulty = setting
	game.start_fight(level)
	game.intro = 0
	game.attack_clock = 1000

func win_with_super() -> bool:
	game.hurt_timer = 999
	var fire = InputEventKey.new()
	fire.physical_keycode = KEY_F
	fire.pressed = true
	game._input(fire)
	var saw_second_phase = false
	for i in range(120 * 90):
		if game.charge >= 5:
			key(KEY_Q)
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
	# Unlock the Chef only in this balance fixture; chef_test checks the real gate.
	game.spicy_clears.assign([true, true, true, true])
	game.mode = "title"
	game.selected_level = 1
	game.difficulty = 0
	key(KEY_C)
	check(game.difficulty == 1 and game.difficulty_settings().name == "REGULAR", "C cycles Cozy to Regular")
	key(KEY_C)
	check(game.difficulty == 2 and game.difficulty_settings().name == "SPICY", "C cycles Regular to Spicy")
	key(KEY_C)
	check(game.difficulty == 0, "C cycles Spicy back to Cozy")
	for level in [1, 2, 3, 4]:
		prepare(level, 1)
		check(game.health == 4 and game.max_health == 4, "Boss %d supports Regular with four hearts" % level)
		key(KEY_C)
		check(game.difficulty == 1, "C does not change difficulty during boss %d combat" % level)
		game._damage()
		tick(156)
		game._damage()
		check(game.health == 3, "Regular hit protection prevents another hit after 1.3 seconds against boss %d" % level)
		tick(30)
		game._damage()
		check(game.health == 2, "Regular hit protection ends before 1.55 seconds against boss %d" % level)
		key(KEY_R)
		check(game.difficulty == 1 and game.health == 4, "Restart retains Regular difficulty for boss %d" % level)
		for test_phase in [1, 2]:
			for pattern in range(game.encounter(level).warnings.size()):
				var speeds: Array[float] = []
				var volleys: Array[int] = []
				var intervals: Array[float] = []
				for setting in [0, 1, 2]:
					prepare(level, setting)
					game.phase = test_phase
					game._spawn_volley(pattern, 2)
					speeds.append(absf(game.hazards[0].v.x))
					game._begin_attack(pattern)
					volleys.append(game.volley_remaining)
					game._update_boss(0)
					intervals.append(game.volley_clock)
				check(speeds[0] < speeds[1] and speeds[1] < speeds[2], "Boss %d pattern %d phase %d has a distinct intermediate Regular speed" % [level, pattern, test_phase])
				check(volleys[1] == volleys[0] + 1 and volleys[2] == volleys[0] + 2, "Boss %d pattern %d phase %d fires extra volleys in Regular and Spicy" % [level, pattern, test_phase])
				check(intervals[0] > intervals[1] and intervals[1] > intervals[2], "Boss %d pattern %d phase %d fires volleys more frequently in harder modes" % [level, pattern, test_phase])
			var cycles: Array[float] = []
			for setting in [0, 1, 2]:
				prepare(level, setting)
				game.phase = test_phase
				game.attack_clock = 0
				game._update_boss(0)
				cycles.append(game.attack_clock)
			check(cycles[0] > cycles[1] and cycles[1] > cycles[2], "Boss %d phase %d has less downtime in harder modes" % [level, test_phase])
			prepare(level, 1)
			game.phase = test_phase
			game._spawn_volley(0, 2)
			tick(360)
			check(game.health == 3, "Regular attacks can hit a standing player against boss %d, phase %d" % [level, test_phase])
		var warnings: Array[float] = []
		var protection: Array[float] = []
		for setting in [0, 1, 2]:
			prepare(level, setting)
			check(game.health == [5, 4, 3][setting], "Boss %d starts difficulty %d with the intended hearts" % [level, setting])
			check(game.boss_hp == roundf(game.encounter().hp * [1.0, 1.15, 1.35][setting]), "Boss %d difficulty %d has the intended tougher health pool" % [level, setting])
			game.attack_clock = 0
			game._update_boss(0)
			warnings.append(game.warning_time)
			game._damage()
			protection.append(game.hurt_timer)
		check(warnings[0] > warnings[1] and warnings[1] > warnings[2], "Boss %d Regular warning time lies between Cozy and Spicy" % level)
		check(protection[0] > protection[1] and protection[1] > protection[2], "Boss %d Regular protection time lies between Cozy and Spicy" % level)
		for setting in [1, 2]:
			prepare(level, setting)
			game.boss_hp = game.boss_max_hp * 0.5
			game._damage_boss(10)
			check(is_equal_approx(game.boss_hp, game.boss_max_hp * 0.5 - 10), "Boss %d difficulty %d still takes full damage at exactly half its scaled health" % [level, setting])
			game._damage_boss(10)
			check(is_equal_approx(game.boss_hp, game.boss_max_hp * 0.5 - 15), "Boss %d difficulty %d halves Sunny's damage below scaled half health" % [level, setting])
			prepare(level, setting)
			check(win_with_super(), "Boss %d can be completed in difficulty %d through both phases" % [level, setting])
			key(KEY_ENTER)
			check(game.difficulty == setting and game.health == (3 if game.current_level == 5 else [5, 4, 3][setting]), "Advancing boss %d refreshes hearts for the next boss's allowed difficulty and preserves preference %d" % [level, setting])
	var save_path = "/private/tmp/pantry-difficulty-test-%d.cfg" % OS.get_process_id()
	for setting in [0, 1, 2]:
		game.difficulty = setting
		game._save_settings(save_path)
		game.difficulty = -1
		game._load_settings(save_path)
		check(game.difficulty == setting, "New-format difficulty %d survives saving and loading" % setting)
	for legacy_setting in [0, 1]:
		var legacy = ConfigFile.new()
		legacy.set_value("settings", "difficulty", legacy_setting)
		legacy.set_value("records", "best_time", 37.5)
		legacy.set_value("records", "level_2_best_time", 46.5)
		legacy.save(save_path)
		game._load_settings(save_path)
		check(game.difficulty == (0 if legacy_setting == 0 else 2), "Old difficulty %d retains its Cozy or Spicy meaning" % legacy_setting)
		check(game.best_time == 37.5 and game.second_best_time == 46.5 and game.unlocked_level == 3, "Old difficulty migration preserves records and unlocks")
	var fresh = ConfigFile.new()
	fresh.save(save_path)
	game._load_settings(save_path)
	check(game.difficulty == 1, "Profiles without a difficulty setting default to Regular")
	fresh.set_value("settings", "difficulty_id", "unknown")
	fresh.save(save_path)
	game._load_settings(save_path)
	check(game.difficulty == 1, "Unknown difficulty identifiers safely fall back to Regular")
	DirAccess.remove_absolute(save_path)
	game.free()
	await create_timer(0.1).timeout
	print("DIFFICULTY TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

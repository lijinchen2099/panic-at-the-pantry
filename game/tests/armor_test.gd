extends SceneTree
## Shielded hazards survive weapons, remain dangerous, and can be dodged.

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

func prepare(level: int = 1) -> void:
	game.start_fight(level)
	game.intro = 0
	game.attack_clock = 1000

func tick(count: int = 1) -> void:
	for i in range(count):
		game.step_fight(DT)
		game.taps.clear()

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.difficulty = 0
	game.spicy_clears.assign([true, true, true, true])
	for case_index in range(3):
		var level = [1, 2, 5][case_index]
		var pattern = [2, 0, 2][case_index]
		var kind = ["wave", "banana", "whisk"][case_index]
		for setting in [0, 1, 2]:
			game.difficulty = setting
			prepare(level)
			game._spawn_volley(pattern, 2)
			check(game.hazards[0].kind == kind and not game.hazards[0].breakable and not game.hazards[0].pink, "Boss %d difficulty %d spawns its shielded attack" % [level, setting])
			game.hazards[0].p = Vector2(600, 600)
			game.shots.append({"p": Vector2(500, 600), "v": Vector2(24000, 0), "life": 1.0})
			tick()
			check(game.hazards.size() == 1 and game.shots.is_empty(), "High-speed bullet is blocked by %s in difficulty %d" % [kind, setting])
		prepare(level)
		game._hazard(Vector2(600, 671), Vector2.ZERO, kind, false, 28, 0)
		game._hazard(Vector2(750, 671), Vector2.ZERO, "toast", false, 26, 0)
		game.energy_balls.append({"p": Vector2(400, 671), "v": Vector2(860, 0), "life": 2.6, "age": 0.0})
		game.hurt_timer = 999
		tick(150)
		check(game.hazards.size() == 1 and game.hazards[0].kind == kind, "Energy ball preserves %s while destroying ordinary food" % kind)
		check(game.boss_hp == game.boss_max_hp - 120 and game.energy_balls.is_empty(), "Energy ball still reaches boss %d after passing a shielded attack" % level)
		prepare(level)
		game._hazard(game.player - Vector2(0, 53), Vector2.ZERO, kind, false, 28, 0)
		tick()
		check(game.health == game.max_health - 1 and game.hazards.size() == 1, "Touching %s hurts Sunny without destroying the shielded attack" % kind)
		prepare(level)
		game._hazard(Vector2(385, 692), Vector2(-400, 0), kind, false, 28, 0)
		key(KEY_D)
		tick(60)
		check(game.health == game.max_health, "D dashes safely through " + kind)
		prepare(level)
		game._hazard(Vector2(385, 710), Vector2(-400, 0), kind, false, 28, 0)
		key(KEY_SPACE)
		tick(96)
		check(game.health == game.max_health, "Space jumps safely over " + kind)
		prepare(level)
		game._hazard(Vector2(-99, 700), Vector2(-400, 0), kind, false, 28, 0)
		tick()
		check(game.hazards.is_empty(), "Off-screen %s is cleaned up normally" % kind)
	prepare()
	game._hazard(Vector2(600, 600), Vector2.ZERO, "wave", false, 28, 0)
	game._hazard(Vector2(700, 600), Vector2.ZERO, "toast", false, 26, 0)
	game.shots.append({"p": Vector2(500, 600), "v": Vector2(48000, 0), "life": 1.0})
	tick()
	check(game.hazards.size() == 2, "A shield consumes the bullet before it can hit food behind it")
	prepare()
	game._hazard(Vector2(700, 600), Vector2.ZERO, "wave", false, 28, 0)
	game._hazard(Vector2(600, 600), Vector2.ZERO, "toast", false, 26, 0)
	game.shots.append({"p": Vector2(500, 600), "v": Vector2(48000, 0), "life": 1.0})
	tick()
	check(game.hazards.size() == 1 and game.hazards[0].kind == "wave", "A bullet destroys normal food that is in front of a shield")
	game.free()
	await create_timer(0.1).timeout
	print("ARMOR TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

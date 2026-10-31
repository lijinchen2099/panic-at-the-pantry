extends SceneTree
## Charge from firing, physical energy-ball flight, and impact behavior.

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

func prepare(level: int = 1) -> void:
	game.start_fight(level)
	game.intro = 0
	game.attack_clock = 1000

func launch() -> void:
	game.charge = 5
	key(KEY_Q)
	tick()
	key(KEY_Q, false)

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.muted = true
	game._apply_mute()
	game.difficulty = 0
	prepare()
	tick(120)
	check(game.charge == 0, "Waiting without shooting does not charge the super")
	game.charge = 2
	key(KEY_Q)
	tick()
	check(game.charge == 2 and game.energy_balls.is_empty(), "Q needs a full meter and preserves a partial charge")
	prepare()
	game.facing = -1
	key(KEY_F)
	tick(120)
	check(game.charge > 0 and game.boss_hp == game.boss_max_hp, "Shooting away from the boss still charges the meter")
	var previous_charge = game.charge
	key(KEY_F, false)
	tick(120)
	check(game.charge == previous_charge, "Charge stops growing when firing stops")
	key(KEY_F)
	tick(800)
	check(game.charge == 5, "Repeated missed shots fill all five cards")
	tick(240)
	check(game.charge == 5 and game.energy_balls.is_empty(), "Full charge is capped and waits for Q")
	key(KEY_F, false)
	game.facing = 1
	key(KEY_Q)
	tick()
	check(game.charge == 0 and game.energy_balls.size() == 1, "Q consumes the full charge and launches one energy ball")
	check(game.boss_hp == game.boss_max_hp, "Launch does not damage the boss from across the arena")
	var initial_position: Vector2 = game.energy_balls[0].p
	tick(10)
	check(game.energy_balls[0].p.x > initial_position.x, "Energy ball visibly travels toward the boss")
	tick(150)
	check(game.energy_balls.is_empty() and game.boss_hp == game.boss_max_hp - 120, "Boss impact deals 120 damage and consumes the energy ball")
	tick(120)
	check(game.boss_hp == game.boss_max_hp - 120, "Holding Q cannot repeat the cast or damage")
	for level in [1, 2, 3, 4]:
		prepare(level)
		game.boss_hp = game.boss_max_hp * 0.5 - 1
		var previous_hp = game.boss_hp
		launch()
		tick(150)
		check(is_equal_approx(previous_hp - game.boss_hp, 60), "Boss %d takes 60 energy damage below half health" % level)
		prepare(level)
		launch()
		game.boss_hp = game.boss_max_hp * 0.5 - 1
		previous_hp = game.boss_hp
		tick(150)
		check(is_equal_approx(previous_hp - game.boss_hp, 60), "Boss %d damage reduction is evaluated at impact, not launch" % level)
	prepare()
	game.facing = -1
	launch()
	check(game.energy_balls[0].v.x < 0, "Energy ball follows Sunny's facing direction")
	tick(400)
	check(game.energy_balls.is_empty() and game.boss_hp == game.boss_max_hp, "A missed energy ball expires without damaging the boss")
	prepare()
	game._hazard(Vector2(600, 671), Vector2.ZERO, "toast", false, 26, 0)
	game._hazard(Vector2(850, 690), Vector2.ZERO, "berry", false, 24, 0)
	game._hazard(Vector2(700, 400), Vector2.ZERO, "jam", false, 21, 0)
	launch()
	check(game.hazards.size() == 3, "Launching does not instantly clear every attack")
	tick(150)
	check(game.hazards.size() == 1 and game.hazards[0].kind == "jam", "Energy ball pierces attacks on its path and leaves distant food alone")
	check(game.boss_hp == game.boss_max_hp - 120 and game.charge == 0, "Piercing food preserves boss damage and cannot recharge its own super")
	prepare()
	launch()
	game.energy_balls[0].v = Vector2(240000, 0)
	tick()
	check(game.energy_balls.is_empty() and game.boss_hp == game.boss_max_hp - 120, "Swept collision catches an energy ball crossing the boss in one tick")
	prepare()
	launch()
	var before_pause: Vector2 = game.energy_balls[0].p
	key(KEY_ESCAPE)
	game._physics_process(1.0)
	check(game.mode == "paused" and game.energy_balls[0].p == before_pause, "Pause freezes the energy ball in flight")
	key(KEY_ESCAPE)
	tick(150)
	check(game.boss_hp == game.boss_max_hp - 120, "Energy ball continues after resuming")
	prepare()
	launch()
	key(KEY_R)
	check(game.energy_balls.is_empty() and game.charge == 0 and game.boss_hp == game.boss_max_hp, "Restart clears active energy balls and charge")
	prepare()
	launch()
	game.start_fight(2)
	check(game.energy_balls.is_empty() and game.charge == 0, "Changing course clears the previous energy ball")
	game.free()
	await create_timer(0.1).timeout
	print("SUPER TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

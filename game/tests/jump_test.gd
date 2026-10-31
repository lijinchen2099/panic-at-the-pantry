extends SceneTree
## Real keyboard double jumps, landing resets, and dash/parry interactions.

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

func first_jump() -> void:
	key(KEY_SPACE)
	tick(20)
	key(KEY_SPACE, false)
	tick(20)

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.spicy_clears.assign([true, true, true, true])
	for level in [1, 2, 3, 4, 5]:
		for setting in ([2] if level == 5 else [0, 1, 2]):
			game.difficulty = setting
			prepare(level)
			first_jump()
			check(game.player.y < game.FLOOR_Y and game.air_jump_available, "Boss %d mode %d first jump leaves the air jump ready" % [level, setting])
			var first_height = game.player.y
			key(KEY_SPACE)
			tick()
			check(game.velocity.y < -800 and not game.air_jump_available, "Boss %d mode %d second Space press launches the air jump" % [level, setting])
			tick(12)
			check(game.player.y < first_height - 50, "Boss %d mode %d double jump gains useful extra height" % [level, setting])
			key(KEY_SPACE, false)
			tick()
			check(game.velocity.y >= -340, "Releasing the second jump still controls its height")
			var previous_velocity = game.velocity.y
			key(KEY_Z)
			tick()
			check(game.velocity.y > previous_velocity and not game.air_jump_available, "Boss %d mode %d cannot triple jump by switching keys" % [level, setting])
			key(KEY_Z, false)
			tick(180)
			check(game.player.y == game.FLOOR_Y and game.air_jump_available, "Boss %d mode %d landing restores the air jump" % [level, setting])
	prepare()
	key(KEY_SPACE)
	tick(180)
	check(game.player.y == game.FLOOR_Y and game.air_jump_available, "Holding Space neither spends the second jump nor auto-jumps after landing")
	prepare()
	key(KEY_Z)
	tick(20)
	key(KEY_Z, false)
	tick(20)
	key(KEY_Z)
	tick()
	check(game.velocity.y < -800 and not game.air_jump_available, "Z supports both jumps without needing Space")
	prepare()
	first_jump()
	var echo = InputEventKey.new()
	echo.physical_keycode = KEY_SPACE
	echo.pressed = true
	echo.echo = true
	game._input(echo)
	tick()
	check(game.air_jump_available, "Keyboard auto-repeat cannot trigger the second jump")
	prepare()
	first_jump()
	key(KEY_D)
	tick()
	key(KEY_SPACE)
	tick()
	check(game.air_jump_available and game.dash_timer > 0, "A jump press during a dash does not consume the air jump")
	key(KEY_SPACE, false)
	tick(24)
	key(KEY_SPACE)
	tick()
	check(game.velocity.y < -800 and not game.air_jump_available, "The second jump works after the dash finishes")
	key(KEY_SPACE, false)
	game._hazard(game.player - Vector2(0, 54), Vector2.ZERO, "jam", true, 21, 0)
	key(KEY_G)
	tick()
	check(not game.air_jump_available and game.velocity.y < 0, "A parry bounces Sunny without granting a third jump")
	key(KEY_SPACE)
	tick()
	check(not game.air_jump_available and game.velocity.y > -800, "A spent double jump stays spent after parrying")
	key(KEY_R)
	check(game.air_jump_available and game.player.y == game.FLOOR_Y, "Restart resets double-jump availability")
	prepare()
	first_jump()
	key(KEY_SPACE)
	tick()
	key(KEY_SPACE, false)
	game.player.y = game.FLOOR_Y - 3
	game.velocity.y = 100
	key(KEY_SPACE)
	tick(4)
	check(game.player.y < game.FLOOR_Y and game.velocity.y < -800 and game.air_jump_available, "A jump buffered just before landing becomes a fresh ground jump")
	game.free()
	await create_timer(0.1).timeout
	print("JUMP TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

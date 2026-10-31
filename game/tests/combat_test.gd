extends SceneTree
## Run against the actual scene and fixed-step combat, without rendering.

var game
var failures: Array[String] = []
var checks = 0
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

func reset() -> void:
	game.start_fight(1)
	game.intro = 0
	game.attack_clock = 1000

func shot(p: Vector2, velocity: Vector2) -> void:
	game.shots.append({"p": p, "v": velocity, "life": 1.0})

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.muted = true
	game._apply_mute()
	game.difficulty = 0
	game.selected_level = 1
	check(game.mode == "title", "Scene starts at title")
	key(KEY_ENTER)
	check(game.menu_page == "bosses" and game.mode == "title", "Start Game opens boss selection")
	key(KEY_ENTER)
	check(game.mode == "fight", "Enter starts the fight")
	game.intro = 0
	game.attack_clock = 1000
	key(KEY_RIGHT)
	tick(60)
	check(game.player.x > 410, "Right arrow moves player right")
	key(KEY_RIGHT, false)
	key(KEY_SPACE)
	tick(24)
	check(game.player.y < 620, "Held jump reaches a useful height")
	key(KEY_SPACE, false)
	tick(180)
	check(is_equal_approx(game.player.y, game.FLOOR_Y), "Player lands exactly on counter")
	reset()
	key(KEY_LEFT)
	tick(180)
	check(game.player.x >= 60, "Left arena boundary contains player")
	check(game.facing == -1, "Left arrow faces player left")
	reset()
	key(KEY_D)
	tick(1)
	check(game.dash_timer > 0 and game.dash_cooldown > 0, "D activates dash with cooldown")
	var hp = game.health
	game._damage()
	check(game.health == hp, "Dash grants invulnerability")
	tick(28)
	game._damage()
	check(game.health == hp - 1, "Damage resumes after dash")
	game._damage()
	check(game.health == hp - 1, "Hit grace period prevents repeated damage")
	tick(120)
	check(game.velocity.x == 0, "Holding D does not become a right-movement input")
	reset()
	key(KEY_F)
	tick(24)
	check(game.shots.size() >= 2, "Holding F fires repeated bullets")
	var shot_count = game.shots.size()
	key(KEY_F, false)
	tick(24)
	check(game.shots.size() == shot_count, "Releasing F stops firing")
	reset()
	key(KEY_LEFT)
	key(KEY_F)
	tick()
	check(game.velocity.x < 0 and game.shots[0].v.x < 0, "Left arrow and F move and fire left together")
	reset()
	key(KEY_DOWN)
	key(KEY_F)
	tick()
	check(game.shots[0].v.y > 0, "Down arrow aims bullets toward low attacks")
	reset()
	key(KEY_X)
	key(KEY_E)
	tick()
	check(game.shots.is_empty() and game.parry_timer == 0, "Replaced X and E bindings are inactive")
	reset()
	game._hazard(game.player - Vector2(0, 54), Vector2.ZERO, "jam", true, 21, 0)
	key(KEY_G)
	tick()
	check(game.hazards.is_empty() and game.charge > 1.0, "G parries pink food and adds charge")
	check(game.velocity.y < 0, "Parry bounces player upward")
	for kind in ["toast", "jam", "ball"]:
		reset()
		game._hazard(Vector2(600, 600), Vector2(-350, 0), kind, false, 25, 0)
		shot(Vector2(500, 600), Vector2(24000, 0))
		tick()
		check(game.hazards.is_empty() and game.shots.is_empty(), "Bullet destroys %s and is consumed, even at high speed" % kind)
	reset()
	game._hazard(Vector2(600, 600), Vector2.ZERO, "jam", true, 21, 0)
	shot(Vector2(500, 600), Vector2(24000, 0))
	tick()
	check(game.hazards.is_empty(), "Pink food can also be destroyed by bullets")
	reset()
	game._hazard(Vector2(700, 600), Vector2.ZERO, "toast", false, 26, 0)
	game._hazard(Vector2(600, 600), Vector2.ZERO, "jam", false, 21, 0)
	shot(Vector2(500, 600), Vector2(48000, 0))
	tick()
	check(game.hazards.size() == 1 and game.hazards[0].kind == "toast", "Bullet hits nearest food first regardless of array order")
	reset()
	game._hazard(Vector2(1100, 671), Vector2.ZERO, "toast", false, 26, 0)
	shot(Vector2(1050, 671), Vector2(24000, 0))
	tick()
	check(game.hazards.is_empty() and game.boss_hp == game.BOSS_MAX_HP, "Food shields the boss and a consumed bullet cannot hit both")
	reset()
	game._hazard(Vector2(1500, 671), Vector2.ZERO, "toast", false, 26, 0)
	shot(Vector2(1050, 671), Vector2(72000, 0))
	tick()
	check(game.hazards.size() == 1 and game.boss_hp < game.BOSS_MAX_HP, "Boss takes the first hit when food is behind him")
	reset()
	game._hazard(Vector2(600, 400), Vector2.ZERO, "toast", false, 26, 0)
	shot(Vector2(500, 600), Vector2(24000, 0))
	tick()
	check(game.hazards.size() == 1 and game.shots.size() == 1, "Off-target bullets leave food intact")
	reset()
	game._hazard(Vector2(600, 600), Vector2(-24000, 0), "toast", false, 26, 0)
	shot(Vector2(500, 600), Vector2(1200, 0))
	tick()
	check(game.hazards.is_empty(), "Opposing fast movement cannot tunnel through a bullet")
	reset()
	game._hazard(game.player - Vector2(0, 53), Vector2.ZERO, "toast", false, 26, 0)
	shot(game.player - Vector2(35, 53), Vector2(6000, 0))
	tick()
	check(game.hazards.is_empty() and game.health == game.max_health, "Food destroyed this tick cannot damage Sunny afterward")
	reset()
	game._hazard(Vector2(600, 600), Vector2.ZERO, "toast", false, 26, 0)
	shot(Vector2(700, 600), Vector2(-24000, 0))
	tick()
	check(game.hazards.is_empty(), "Left-facing bullets also destroy food")
	reset()
	game._hazard(Vector2(370, 721), Vector2.ZERO, "wave", false, 25, 0)
	key(KEY_DOWN)
	key(KEY_F)
	tick(12)
	check(game.hazards.size() == 1 and not game.hazards[0].breakable, "Real F-fired downward bullet cannot destroy a shielded crumb wave")
	reset()
	game.charge = 5
	game._hazard(Vector2(800, 671), Vector2.ZERO, "toast", false, 26, 0)
	key(KEY_Q)
	tick()
	check(game.boss_hp == game.BOSS_MAX_HP and game.energy_balls.size() == 1, "Q launches an energy ball before dealing damage")
	check(game.charge == 0, "Energy ball consumes the full super meter")
	tick(150)
	check(game.boss_hp == game.BOSS_MAX_HP - 120, "Energy ball deals heavy damage on impact")
	check(game.hazards.is_empty() and game.energy_balls.is_empty(), "Energy ball destroys food on its path and bursts on the boss")
	for level in [1, 2, 3, 4]:
		for health_offset in [1.0, 0.0, -1.0]:
			game.start_fight(level)
			game.intro = 0
			game.attack_clock = 1000
			var starting_hp = game.boss_max_hp * 0.5 + health_offset
			game.boss_hp = starting_hp
			shot(Vector2(1050, 671), Vector2(24000, 0))
			tick()
			var expected_damage = 0.95 if health_offset < 0 else 1.9
			check(is_equal_approx(starting_hp - game.boss_hp, expected_damage), "Boss %d takes correct bullet damage at half-health offset %.1f" % [level, health_offset])
			game.start_fight(level)
			game.intro = 0
			game.attack_clock = 1000
			game.boss_hp = starting_hp
			game.charge = 5
			key(KEY_Q)
			tick()
			tick(150)
			expected_damage = 60.0 if health_offset < 0 else 120.0
			check(is_equal_approx(starting_hp - game.boss_hp, expected_damage), "Boss %d takes correct super damage at half-health offset %.1f" % [level, health_offset])
		game.start_fight(level)
		game.intro = 0
		game.attack_clock = 1000
		var starting_hp = game.boss_max_hp * 0.5 + 1.0
		game.boss_hp = starting_hp
		shot(Vector2(1050, 671), Vector2(24000, 0))
		shot(Vector2(1050, 671), Vector2(24000, 0))
		tick()
		check(is_equal_approx(starting_hp - game.boss_hp, 2.85), "Boss %d switches to half damage between hits in the same tick" % level)
		game.start_fight(level)
		game.intro = 0
		game.attack_clock = 1000
		game.boss_hp = 0.5
		shot(Vector2(1050, 671), Vector2(24000, 0))
		tick()
		check(game.boss_hp == 0 and game.mode == "win", "Reduced bullets can still finish boss %d without negative health" % level)
	reset()
	game.boss_hp = 200
	tick()
	check(game.phase == 2 and game.warning_time > 0, "Half health starts phase two with warning")
	for pattern in range(4):
		reset()
		game._begin_attack(pattern)
		tick()
		check(not game.hazards.is_empty(), "Attack pattern %d spawns hazards" % pattern)
	reset()
	game._hazard(Vector2(800, 714), Vector2(-100, 300), "ball", false, 25, 700)
	tick(3)
	check(game.hazards[0].bounces > 0 and game.hazards[0].v.y < 0, "Breakfast balls bounce off counter")
	reset()
	game.health = 1
	game._hazard(game.player - Vector2(0, 53), Vector2.ZERO, "toast", false, 26, 0)
	tick()
	check(game.mode == "lose", "Final hit produces defeat screen")
	key(KEY_R)
	check(game.health == game.max_health and game.boss_hp == game.BOSS_MAX_HP and game.mode == "fight", "Restart resets combat")
	game.intro = 0
	key(KEY_ESCAPE)
	var time_before = game.fight_time
	game._physics_process(1.0)
	check(game.mode == "paused" and game.fight_time == time_before, "Pause freezes combat time")
	key(KEY_ESCAPE)
	check(game.mode == "fight", "Escape resumes combat")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.mode == "paused" and game.pressed.is_empty(), "Focus loss pauses and releases held keys")
	reset()
	# Full actual projectile-to-boss collision path, with player damage disabled.
	game.hurt_timer = 999
	key(KEY_F)
	var saw_phase_two = false
	for i in range(120 * 75):
		tick()
		saw_phase_two = saw_phase_two or game.phase == 2
		if game.mode == "win":
			break
	check(saw_phase_two and game.mode == "win", "Continuous shots complete both phases and victory")
	check(game.fight_time > 40 and game.fight_time < 65, "Battle remains completable with reduced damage in its second half")
	game.difficulty = 2
	reset()
	check(game.health == 3, "Spicy mode starts with three hearts")
	game.free()
	await create_timer(0.1).timeout
	print("COMBAT TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

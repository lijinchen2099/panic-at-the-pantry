extends SceneTree
## Real menu clicks, configurable controls, save compatibility, and Quit Game.

var game
var checks = 0
var failures: Array[String] = []

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

func click(button: Button) -> void:
	var point = button.get_global_rect().get_center()
	var motion = InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for held in [true, false]:
		var event = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = held
		root.push_input(event, true)
		await process_frame

func tick(count: int = 1) -> void:
	for index in range(count):
		game.step_fight(1.0 / 120.0)
		game.taps.clear()

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	game.selected_level = 1
	game.difficulty = 1
	game._sync_boss_selector()
	await process_frame
	check(game.menu_page == "home" and game.home_controls.visible and not game.title_controls.visible, "Launch shows the home menu instead of boss selection")
	check(not game.options_controls.visible and not game.keyboard_controls.visible, "Settings stay hidden until Options is opened")
	await click(game.options_button)
	check(game.menu_page == "options" and game.options_controls.visible and not game.home_controls.visible, "Options opens through its real button")
	await click(game.difficulty_button)
	check(game.difficulty == 2, "Difficulty can be changed in Options")
	var was_muted = game.muted
	await click(game.sound_button)
	check(game.muted != was_muted and game.sound_button.text == ("Off" if game.muted else "On"), "Sound toggles and its label updates")
	if DisplayServer.get_name() != "headless":
		var previous_mode = DisplayServer.window_get_mode()
		await click(game.fullscreen_button)
		await process_frame
		check(DisplayServer.window_get_mode() != previous_mode, "Fullscreen changes through the Options button")
		game._toggle_fullscreen()
		await process_frame
	await click(game.keyboard_button)
	check(game.menu_page == "keyboard" and game.keyboard_controls.visible, "Keyboard opens the key configuration page")
	await click(game.binding_buttons.shoot)
	key(KEY_H)
	check(game.binding_action == "shoot" and not game.help_open, "Menu shortcuts are rejected while assigning a gameplay key")
	key(KEY_ESCAPE)
	check(game.binding_action.is_empty() and game.menu_page == "keyboard", "Escape cancels key capture without leaving Keyboard")
	await click(game.binding_buttons.shoot)
	key(KEY_D)
	check(game.key_bindings.shoot == KEY_D and game.key_bindings.dash == KEY_F, "Assigning an occupied key swaps the two controls")
	var custom = {"move_left": KEY_J, "move_right": KEY_L, "jump": KEY_K, "shoot": KEY_A, "aim_up": KEY_I, "aim_down": KEY_O, "dash": KEY_S, "parry": KEY_P, "super": KEY_V}
	for action in custom:
		await click(game.binding_buttons[action])
		key(custom[action])
		check(game.key_bindings[action] == custom[action] and game.binding_action.is_empty(), "Custom key takes effect for " + action)
	var save_path = "/private/tmp/pantry-options-test-%d.cfg" % OS.get_process_id()
	game.best_time = 31.5
	game.spicy_clears.assign([true, false, true, false])
	game._save_settings(save_path)
	game.key_bindings = game.DEFAULT_KEYS.duplicate()
	game.difficulty = 0
	game.muted = was_muted
	game._load_settings(save_path)
	check(game.key_bindings.shoot == KEY_A and game.key_bindings.move_left == KEY_J and game.difficulty == 2 and game.muted != was_muted, "Keyboard, difficulty, and sound settings survive loading")
	check(game.best_time == 31.5 and game.spicy_clears == [true, false, true, false], "Saving Options preserves records and Chef progress")
	key(KEY_ESCAPE)
	check(game.menu_page == "options", "Keyboard Back returns to Options")
	key(KEY_ESCAPE)
	check(game.menu_page == "home" and game.home_controls.visible, "Options Back returns to the home menu")
	await click(game.home_start_button)
	check(game.menu_page == "bosses" and game.title_controls.visible, "Start Game opens boss selection")
	await click(game.start_button)
	check(game.mode == "fight" and game.health == 3, "Play starts the chosen boss using the configured difficulty")
	game.intro = 0
	game.attack_clock = 1000
	key(KEY_J)
	tick(36)
	key(KEY_J, false)
	check(game.player.x < 200, "The custom left key moves Sunny")
	var left_position = game.player.x
	key(KEY_L)
	tick(36)
	key(KEY_L, false)
	check(game.player.x > left_position and game.velocity.x > 0, "The custom right key moves Sunny")
	key(KEY_K)
	tick(10)
	key(KEY_K, false)
	check(game.player.y < game.FLOOR_Y and game.air_jump_available, "The custom jump key starts a grounded jump")
	key(KEY_F)
	tick()
	key(KEY_F, false)
	check(game.shots.is_empty(), "The old shoot key no longer fires")
	key(KEY_I)
	key(KEY_A)
	tick()
	key(KEY_A, false)
	key(KEY_I, false)
	check(game.shots.size() == 1 and game.shots[0].v.y < 0, "Custom shoot and aim keys create an upward shot")
	key(KEY_S)
	tick()
	check(game.dash_timer > 0, "The custom dash key triggers a dash")
	game.charge = game.MAX_CHARGE
	key(KEY_V)
	tick()
	check(game.energy_balls.size() == 1 and game.charge == 0, "The custom super key casts an energy ball")
	game._hazard(game.player - Vector2(0, 54), Vector2.ZERO, "jam", true, 25, 0)
	key(KEY_P)
	tick()
	check(game.charge >= 1.25 and game.hazards.is_empty(), "The custom parry key parries pink food")
	game._show_boss_selection()
	game._show_options()
	game._show_keyboard()
	await click(game.keyboard_controls.get_child(10))
	check(game.key_bindings == game.DEFAULT_KEYS, "Reset Keys restores every default control")
	var legacy = ConfigFile.new()
	legacy.set_value("records", "best_time", 44.0)
	legacy.set_value("settings", "difficulty_id", "regular")
	legacy.save(save_path)
	game._load_settings(save_path)
	check(game.key_bindings == game.DEFAULT_KEYS and game.best_time == 44.0, "Older saves receive default controls and preserve records")
	legacy.set_value("keyboard", "shoot", KEY_B)
	legacy.save(save_path)
	game._load_settings(save_path)
	check(game.key_bindings == game.DEFAULT_KEYS, "Invalid saved bindings safely fall back to defaults")
	DirAccess.remove_absolute(save_path)
	game._show_home()
	await click(game.quit_button)
	check(game.shutting_down, "Quit Game begins a clean shutdown")
	print("OPTIONS TEST: %d checks, %d failures" % [checks, failures.size()])
	if not failures.is_empty():
		quit(1)
		return
	await create_timer(1.0).timeout
	push_error("Quit Game did not exit")
	quit(1)

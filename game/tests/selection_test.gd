extends SceneTree
## Select every boss on a new profile through real UI and keyboard input.

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

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	var save_path = "/private/tmp/pantry-selection-test-%d.cfg" % OS.get_process_id()
	var fresh = ConfigFile.new()
	fresh.save(save_path)
	game._load_settings(save_path)
	game._show_boss_selection()
	await process_frame
	check(game.unlocked_level == 1 and game.best_time == 0, "Fixture has no campaign wins")
	check(game.boss_buttons.size() == 5 and game.title_controls.visible, "Title exposes four bosses and a locked Chef preview")
	await click(game.help_button)
	check(game.help_open and game.help_controls.visible and not game.title_controls.visible, "Clicking Help opens controls and hides the menu hitboxes")
	var help_level = game.selected_level
	var help_difficulty = game.difficulty
	key(KEY_4)
	key(KEY_C)
	key(KEY_R)
	check(game.mode == "title" and game.selected_level == help_level and game.difficulty == help_difficulty, "Help blocks boss selection, difficulty changes, and restarts underneath it")
	var was_muted = game.muted
	key(KEY_M)
	check(game.muted != was_muted and game.help_open, "Sound can be toggled while reading Help")
	key(KEY_M)
	key(KEY_ENTER)
	check(not game.help_open and game.mode == "title" and game.title_controls.visible, "Enter closes Help without starting a fight")
	key(KEY_F1)
	await click(game.close_help_button)
	check(not game.help_open and game.pressed.is_empty() and game.taps.is_empty(), "F1 opens Help and its Back button clears held keys")
	for level in [1, 2, 3, 4]:
		key([KEY_1, KEY_2, KEY_3, KEY_4][level - 1])
		check(game.selected_level == level, "Number key selects boss %d on a new profile" % level)
		key(KEY_ENTER)
		check(game.current_level == level and game.mode == "fight", "Enter launches chosen boss %d" % level)
		check(not game.title_controls.visible, "Boss selector is hidden during fight %d" % level)
		key(KEY_LEFT)
		check(game.down([KEY_LEFT]) and game.current_level == level, "Left arrow still controls movement in fight %d" % level)
		key(KEY_B)
		check(game.mode == "title" and game.title_controls.visible and game.pressed.is_empty() and game.taps.is_empty(), "B returns from boss %d and clears held combat input" % level)
	key(KEY_RIGHT)
	check(game.selected_level == 5 and game.start_button.disabled, "Arrow keys preview the locked Chef without allowing play")
	key(KEY_RIGHT)
	check(game.selected_level == 1, "Right arrow wraps the last boss to the first")
	key(KEY_LEFT)
	check(game.selected_level == 5, "Left arrow wraps the first boss to the Chef preview")
	key(KEY_ENTER)
	check(game.mode == "title", "Enter cannot start the locked Chef")
	await click(game.boss_buttons[4])
	await click(game.start_button)
	check(game.selected_level == 5 and game.mode == "title", "Clicking the Chef and disabled start button cannot bypass the lock")
	for level in [1, 2, 3, 4]:
		key([KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4][level - 1])
		check(game.selected_level == level, "Number pad selects boss %d" % level)
	for level in [3, 4, 1, 2]:
		await click(game.boss_buttons[level - 1])
		check(game.selected_level == level, "Mouse click selects boss %d through its real button hitbox" % level)
		check(game.boss_buttons[level - 1].get_theme_stylebox("normal").bg_color == game.GREEN, "Clicked boss %d is highlighted" % level)
	var selected_difficulty = game.difficulty
	game._show_options()
	await click(game.difficulty_button)
	check(game.difficulty == (selected_difficulty + 1) % 3, "Difficulty button cycles modes with the mouse")
	game._show_boss_selection()
	await click(game.start_button)
	check(game.mode == "fight" and game.current_level == 2, "Clicking the start button launches the selected boss")
	key(KEY_F)
	key(KEY_H)
	check(game.mode == "paused" and game.help_open and game.pressed.is_empty() and game.taps.is_empty(), "Help pauses combat and clears shooting input")
	var frozen_time = game.fight_time
	game._physics_process(1.0)
	check(game.fight_time == frozen_time, "Combat stays frozen while Help is open")
	key(KEY_B)
	key(KEY_R)
	check(game.help_open and game.current_level == 2 and game.mode == "paused", "Help blocks boss navigation and retry during a fight")
	key(KEY_ESCAPE)
	check(not game.help_open and game.mode == "paused" and game.pause_controls.visible, "Closing Help returns to pause without resuming combat")
	await click(game.pause_help_button)
	await click(game.close_help_button)
	check(game.mode == "paused" and not game.help_open, "The pause Help and Back buttons preserve the paused fight")
	await click(game.pause_controls.get_child(0))
	check(game.mode == "fight" and not game.pause_controls.visible, "The Resume button returns to combat")
	key(KEY_ESCAPE)
	key(KEY_B)
	check(game.mode == "title" and game.selected_level == 2, "B returns from pause with the current boss selected")
	for result in ["win", "lose"]:
		game.mode = result
		key(KEY_B)
		check(game.mode == "title" and game.title_controls.visible, "B returns from the %s screen" % result)
	game.difficulty = 1
	game.best_time = 35.5
	game.third_best_time = 0
	game.unlocked_level = 1
	game._select_boss(4)
	game._save_settings(save_path)
	game.selected_level = 1
	game._load_settings(save_path)
	check(game.selected_level == 4, "Boss four selection survives loading a profile without campaign completion")
	check(game.best_time == 35.5 and game.difficulty == 1, "Selection preserves records and difficulty")
	fresh.set_value("settings", "selected_level", 4)
	fresh.set_value("progress", "unlocked_level", 1)
	fresh.save(save_path)
	game._load_settings(save_path)
	check(game.selected_level == 4 and game.unlocked_level == 1, "Saved boss choice is independent of historical campaign progress")
	DirAccess.remove_absolute(save_path)
	game.free()
	await create_timer(0.1).timeout
	print("SELECTION TEST: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

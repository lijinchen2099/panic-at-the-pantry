extends "res://scripts/art.gd"
## Deterministic 120 Hz game simulation; vector rendering remains independent.

const FLOOR_Y = 740.0
const GRAVITY = 2050.0
const BOSS_MAX_HP = 420.0
const BULLET_RADIUS = 7.0
const MAX_CHARGE = 5.0
const SHOT_CHARGE = 0.1
const SUPER_DAMAGE = 120.0
const ENERGY_BALL_RADIUS = 42.0
const ARMORED_ATTACKS = ["wave", "banana", "whisk"]
enum Difficulty { COZY, REGULAR, SPICY }
const DIFFICULTIES = [
	{"id": "cozy", "name": "COZY", "hearts": 5, "speed_blend": 0.0, "warning": 0.95, "hit_grace": 1.65, "boss_health_scale": 1.0, "speed_scale": 1.0, "cycle_scale": 1.0, "volley_scale": 1.0, "extra_volleys": 0},
	{"id": "regular", "name": "REGULAR", "hearts": 4, "speed_blend": 0.5, "warning": 0.825, "hit_grace": 1.45, "boss_health_scale": 1.15, "speed_scale": 1.10, "cycle_scale": 0.90, "volley_scale": 0.90, "extra_volleys": 1},
	{"id": "spicy", "name": "SPICY", "hearts": 3, "speed_blend": 1.0, "warning": 0.7, "hit_grace": 1.25, "boss_health_scale": 1.35, "speed_scale": 1.20, "cycle_scale": 0.78, "volley_scale": 0.75, "extra_volleys": 2}
]
const SAVE_PATH = "user://pantry.cfg"
const DEFAULT_KEYS = {
	"move_left": KEY_LEFT, "move_right": KEY_RIGHT, "jump": KEY_SPACE, "jump_alt": KEY_Z,
	"shoot": KEY_F, "aim_up": KEY_UP, "aim_down": KEY_DOWN, "dash": KEY_D, "parry": KEY_G, "super": KEY_Q
}
const KEY_ACTIONS = ["move_left", "move_right", "jump", "jump_alt", "shoot", "aim_up", "aim_down", "dash", "parry", "super"]
const KEY_LABELS = ["Move left", "Move right", "Jump", "Jump (alt)", "Shoot", "Aim up", "Aim down", "Dash", "Parry", "Super"]
const RESERVED_KEYS = [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_BACKSPACE, KEY_B, KEY_R, KEY_C, KEY_H, KEY_F1, KEY_M, KEY_F11, KEY_META, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_CAPSLOCK, KEY_TAB]
const QUIPS = ["YOU'RE TOAST!", "CRUMBS OF GLORY!", "I'M ON A ROLL!", "BUTTER LUCK NEXT TIME!", "LET'S GET THIS BREAD!"]
const ENCOUNTERS = {
	1: {
		"boss": "BARON VON TOAST", "name": "Baron von Toast", "title": "A CRUMBY SITUATION", "hp": 420.0,
		"quips": QUIPS,
		"warnings": ["TOAST!", "JAM!", "JUMP / DASH", "BREAKFAST!"]
	},
	2: {
		"boss": "DUKE DE BLEND", "name": "Duke de Blend", "title": "A SMOOTHIE CRIMINAL", "hp": 460.0,
		"quips": ["PREPARE TO BE PULPED!", "YOU DRIVE ME BANANAS!", "BERRY BAD NEWS FOR YOU!", "YOU'VE MET YOUR MASH!", "I HAVE NO CHILL!"],
		"warnings": ["JUMP / DASH", "SMOOTHIE!", "BERRIES!"]
	},
	3: {
		"boss": "MADAME WHISTLE", "name": "Madame Whistle", "title": "A STORM IN A TEACUP", "hp": 500.0,
		"quips": ["I'M A LITTLE STEAMED!", "YOU'RE NOT MY CUP OF TEA!", "SIP HAPPENS!", "STEEP YOUR DISTANCE!", "TIME FOR A TEA-RRIFIC TANTRUM!"],
		"warnings": ["HOT TEA!", "BISCUITS!"]
	},
	4: {
		"boss": "SIR SIZZLE", "name": "Sir Sizzle", "title": "PAN-DEMONIUM", "hp": 540.0,
		"quips": ["OUT OF THE FRYING PAN!", "YOU'VE FLIPPED YOUR LID!", "I'M A PAN OF MANY TALENTS!", "NO MORE MR. FRY GUY!", "THIS IS MY JAM... PAN!"],
		"warnings": ["PANCAKES!", "HOT OIL!"]
	},
	5: {
		"boss": "CHEF PEPPERPOT", "name": "Chef Pepperpot", "title": "THE FINAL WHISK", "hp": 1280.0,
		"quips": ["ORDER UP, EGG DOWN!", "I'M WHISKING IT ALL!", "SOUP-ER BAD NEWS!", "THIS KITCHEN BITES!", "YOU'RE THE SPECIAL TODAY!"],
		"warnings": ["RAVIOLI!", "SAUCE!", "JUMP / DASH"]
	}
}

var mode = "title"
var elapsed = 0.0
var fight_time = 0.0
var title_time = 0.0
var intro = 0.0
var player = Vector2(260, FLOOR_Y)
var velocity = Vector2.ZERO
var facing = 1.0
var health = 5
var max_health = 5
var boss_hp = BOSS_MAX_HP
var boss_max_hp = BOSS_MAX_HP
var current_level = 1
var selected_level = 1
var unlocked_level = 1
var phase = 1
var boss_position = Vector2(1290, 712)
var hurt_timer = 0.0
var boss_hurt = 0.0
var fire_cooldown = 0.0
var dash_timer = 0.0
var dash_cooldown = 0.0
var parry_timer = 0.0
var jump_buffer = 0.0
var coyote = 0.0
var air_jump_available = true
var charge = 0.0
var attack_clock = 2.4
var attack_index = 0
var warning = ""
var warning_time = 0.0
var pending_attack = -1
var volley_remaining = 0
var volley_clock = 0.0
var volley_kind = 0
var quip = "YOU'RE TOAST!"
var quip_time = 0.0
var shake = 0.0
var flash = 0.0
var result_time = 0.0
var difficulty = Difficulty.REGULAR
var fight_difficulty = Difficulty.REGULAR
var spicy_clears: Array[bool] = [false, false, false, false]
var muted = false
var fullscreen_enabled = true
var shots: Array[Dictionary] = []
var energy_balls: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var floating_text: Array[Dictionary] = []
var pressed: Dictionary = {}
var taps: Dictionary = {}
var rng = RandomNumberGenerator.new()
var sounds: Dictionary = {}
var sound_players: Array[AudioStreamPlayer] = []
var sound_index = 0
var music: AudioStreamPlayer
var best_time = 0.0
var best_rank = "—"
var second_best_time = 0.0
var second_best_rank = "—"
var third_best_time = 0.0
var third_best_rank = "—"
var fourth_best_time = 0.0
var fourth_best_rank = "—"
var fifth_best_time = 0.0
var fifth_best_rank = "—"
var capture_path = ""
var test_mode = false
var shutting_down = false
var title_controls: Control
var boss_buttons: Array[Button] = []
var difficulty_button: Button
var start_button: Button
var menu_style: StyleBoxFlat
var selected_style: StyleBoxFlat
var selector_state = ""
var help_open = false
var pause_controls: Control
var help_controls: Control
var help_button: Button
var pause_help_button: Button
var close_help_button: Button
var menu_page = "home"
var home_controls: Control
var options_controls: Control
var keyboard_controls: Control
var home_start_button: Button
var options_button: Button
var quit_button: Button
var sound_button: Button
var fullscreen_button: Button
var keyboard_button: Button
var binding_buttons: Dictionary = {}
var key_bindings: Dictionary = DEFAULT_KEYS.duplicate()
var binding_action = ""
var binding_message = ""
var stage_cache

func _ready() -> void:
	rng.seed = 7342
	get_tree().auto_accept_quit = false
	test_mode = test_mode or OS.get_cmdline_user_args().has("--self-test")
	_load_settings()
	if test_mode:
		key_bindings = DEFAULT_KEYS.duplicate()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled and not test_mode else DisplayServer.WINDOW_MODE_WINDOWED)
	_build_boss_selector()
	for action in ["shoot", "jump", "dash", "hit", "parry", "win", "pop", "super"]:
		var path = "res://assets/audio/" + action + ".wav"
		if ResourceLoader.exists(path):
			sounds[action] = load(path)
	for i in range(12):
		var audio = AudioStreamPlayer.new()
		audio.volume_db = -13.0
		add_child(audio)
		sound_players.append(audio)
	music = AudioStreamPlayer.new()
	music.volume_db = -18.0
	add_child(music)
	if ResourceLoader.exists("res://assets/audio/breakfast_swing.wav"):
		var track: AudioStreamWAV = load("res://assets/audio/breakfast_swing.wav")
		track.loop_mode = AudioStreamWAV.LOOP_FORWARD
		track.loop_end = int(track.get_length() * track.mix_rate)
		music.stream = track
		if not test_mode:
			music.play()
	_apply_mute()
	stage_cache = preload("res://scripts/stage_cache.gd").new()
	add_child(stage_cache)
	_prepare_stage()
	var preview_level = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			preview_level = clampi(int(arg.trim_prefix("--level=")), 1, ENCOUNTERS.size())
		elif arg.begins_with("--capture="):
			capture_path = arg.trim_prefix("--capture=")
	if OS.get_cmdline_user_args().has("--arena"):
		start_fight(preview_level)
		intro = 0
	if not capture_path.is_empty():
		_capture.call_deferred()

func _exit_tree() -> void:
	_stop_audio()

func _stop_audio() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for audio in sound_players:
		audio.stop()
		audio.stream = null

func _shutdown() -> void:
	if shutting_down:
		return
	shutting_down = true
	set_physics_process(false)
	_stop_audio()
	# Let the audio mixer release active playback before engine teardown.
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()

func _capture() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_path)
	_shutdown()

func _load_settings(path: String = SAVE_PATH) -> void:
	var config = ConfigFile.new()
	key_bindings = DEFAULT_KEYS.duplicate()
	if config.load(path) == OK:
		var loaded_keys: Dictionary = {}
		for action in KEY_ACTIONS:
			var code = int(config.get_value("keyboard", action, DEFAULT_KEYS[action]))
			if code <= 0 or code in RESERVED_KEYS or code in loaded_keys.values():
				loaded_keys.clear()
				break
			loaded_keys[action] = code
		if loaded_keys.size() == DEFAULT_KEYS.size():
			key_bindings = loaded_keys
		muted = config.get_value("settings", "muted", false)
		fullscreen_enabled = bool(config.get_value("settings", "fullscreen", true))
		difficulty = Difficulty.REGULAR
		var difficulty_id = str(config.get_value("settings", "difficulty_id", ""))
		if difficulty_id.is_empty():
			# Earlier builds used 1 for Spicy. Preserve that choice after inserting Regular.
			var legacy = int(config.get_value("settings", "difficulty", -1))
			if legacy == 0:
				difficulty = Difficulty.COZY
			elif legacy in [1, 2]:
				difficulty = Difficulty.SPICY
		else:
			for index in range(DIFFICULTIES.size()):
				if DIFFICULTIES[index].id == difficulty_id:
					difficulty = index
					break
		best_time = config.get_value("records", "best_time", 0.0)
		best_rank = config.get_value("records", "best_rank", "—")
		second_best_time = config.get_value("records", "level_2_best_time", 0.0)
		second_best_rank = config.get_value("records", "level_2_best_rank", "—")
		third_best_time = config.get_value("records", "level_3_best_time", 0.0)
		third_best_rank = config.get_value("records", "level_3_best_rank", "—")
		fourth_best_time = config.get_value("records", "level_4_best_time", 0.0)
		fourth_best_rank = config.get_value("records", "level_4_best_rank", "—")
		fifth_best_time = config.get_value("records", "level_5_best_time", 0.0)
		fifth_best_rank = config.get_value("records", "level_5_best_rank", "—")
		# Old records contain no difficulty evidence; only explicit Spicy wins count.
		for index in range(4):
			spicy_clears[index] = bool(config.get_value("progress", "spicy_boss_%d" % (index + 1), false))
		# Earlier builds recorded only toaster victories, so those wins count.
		unlocked_level = clampi(int(config.get_value("progress", "unlocked_level", 1)), 1, 4)
		if best_time > 0:
			unlocked_level = maxi(unlocked_level, 2)
		if second_best_time > 0:
			unlocked_level = maxi(unlocked_level, 3)
		if third_best_time > 0:
			unlocked_level = maxi(unlocked_level, 4)
		if chef_unlocked():
			unlocked_level = 5
		selected_level = clampi(int(config.get_value("settings", "selected_level", 1)), 1, ENCOUNTERS.size())

func _save_settings(path: String = SAVE_PATH) -> void:
	if test_mode and path == SAVE_PATH:
		return
	var config = ConfigFile.new()
	config.set_value("settings", "muted", muted)
	config.set_value("settings", "fullscreen", fullscreen_enabled)
	config.set_value("settings", "difficulty", difficulty)
	config.set_value("settings", "difficulty_id", DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)].id)
	config.set_value("records", "best_time", best_time)
	config.set_value("records", "best_rank", best_rank)
	config.set_value("records", "level_2_best_time", second_best_time)
	config.set_value("records", "level_2_best_rank", second_best_rank)
	config.set_value("records", "level_3_best_time", third_best_time)
	config.set_value("records", "level_3_best_rank", third_best_rank)
	config.set_value("records", "level_4_best_time", fourth_best_time)
	config.set_value("records", "level_4_best_rank", fourth_best_rank)
	config.set_value("records", "level_5_best_time", fifth_best_time)
	config.set_value("records", "level_5_best_rank", fifth_best_rank)
	for index in range(4):
		config.set_value("progress", "spicy_boss_%d" % (index + 1), spicy_clears[index])
	config.set_value("progress", "unlocked_level", unlocked_level)
	config.set_value("settings", "selected_level", selected_level)
	for action in KEY_ACTIONS:
		config.set_value("keyboard", action, key_bindings[action])
	config.save(path)

func _apply_mute() -> void:
	AudioServer.set_bus_mute(0, muted)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_shutdown()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		pressed.clear()
		taps.clear()
		if mode == "fight":
			mode = "paused"
			_sync_boss_selector()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if event.pressed:
		pressed[key] = true
	else:
		pressed.erase(key)
	if not event.pressed or event.echo:
		return
	if mode == "title" and menu_page == "keyboard" and not binding_action.is_empty():
		_capture_binding(key)
		return
	if key in [KEY_H, KEY_F1] and mode in ["title", "fight", "paused"]:
		_toggle_help()
		return
	if help_open and key not in [KEY_M, KEY_F11]:
		if key in [KEY_ESCAPE, KEY_ENTER]:
			_toggle_help()
		return
	if mode == "title" and menu_page in ["options", "keyboard"] and key not in [KEY_ESCAPE, KEY_BACKSPACE, KEY_C, KEY_M, KEY_F11]:
		return
	taps[key] = true
	match key:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5:
			if mode == "title":
				menu_page = "bosses"
				_select_boss({KEY_1: 1, KEY_2: 2, KEY_3: 3, KEY_4: 4, KEY_5: 5, KEY_KP_1: 1, KEY_KP_2: 2, KEY_KP_3: 3, KEY_KP_4: 4, KEY_KP_5: 5}[key])
		KEY_LEFT, KEY_RIGHT:
			if mode == "title" and menu_page == "bosses":
				_select_boss(wrapi(selected_level - 1 + (-1 if key == KEY_LEFT else 1), 0, ENCOUNTERS.size()) + 1)
		KEY_B:
			_show_boss_selection()
		KEY_F11:
			_toggle_fullscreen()
		KEY_M:
			_toggle_sound()
		KEY_C:
			_cycle_difficulty()
		KEY_ESCAPE:
			if mode == "title":
				_menu_back()
			elif mode == "fight":
				mode = "paused"
			elif mode == "paused":
				mode = "fight"
			elif mode in ["win", "lose"]:
				_show_boss_selection()
		KEY_ENTER:
			if mode == "title":
				if menu_page == "home":
					_show_boss_selection()
				elif menu_page == "bosses":
					start_fight(selected_level)
			elif mode == "win":
				if current_level == 4 and not chef_unlocked():
					_show_boss_selection()
				else:
					start_fight(mini(current_level + 1, ENCOUNTERS.size()))
			elif mode == "lose":
				start_fight()
			elif mode == "paused":
				mode = "fight"
		KEY_R:
			if mode != "title":
				start_fight()
		KEY_BACKSPACE:
			if mode == "title":
				_menu_back()
			elif mode == "paused":
				_show_boss_selection()
	_sync_boss_selector()

func _build_boss_selector() -> void:
	menu_style = StyleBoxFlat.new()
	menu_style.bg_color = Color("ded8bb")
	menu_style.set_corner_radius_all(10)
	selected_style = menu_style.duplicate()
	selected_style.bg_color = GREEN
	var hover_style: StyleBoxFlat = menu_style.duplicate()
	hover_style.bg_color = GOLD
	title_controls = Control.new()
	title_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_controls)
	for course in range(1, ENCOUNTERS.size() + 1):
		var button = _title_button("%d   %s" % [course, ["TOASTER", "BLENDER", "TEAPOT", "SKILLET", "CHEF"][course - 1]], Rect2(95 + (course - 1) * 124, 480, 115, 46), hover_style)
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(_select_boss.bind(course))
		boss_buttons.append(button)
	start_button = _title_button("ENTER   Play", Rect2(95, 566, 634, 69), hover_style)
	start_button.add_theme_stylebox_override("normal", selected_style)
	start_button.add_theme_color_override("font_color", CREAM)
	start_button.add_theme_font_size_override("font_size", 18)
	start_button.pressed.connect(func(): start_fight(selected_level))
	difficulty_button = _title_button("", Rect2(475, 576, 254, 49), hover_style)
	difficulty_button.add_theme_font_size_override("font_size", 18)
	difficulty_button.pressed.connect(_cycle_difficulty)
	help_button = _title_button("H   Help", Rect2(285, 741, 170, 44), hover_style)
	help_button.pressed.connect(_toggle_help)
	var home_back = _title_button("ESC   Back", Rect2(95, 741, 170, 44), hover_style)
	home_back.pressed.connect(_show_home)
	var boss_options = _title_button("Options", Rect2(475, 741, 254, 44), hover_style)
	boss_options.pressed.connect(_show_options)
	home_controls = Control.new()
	home_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(home_controls)
	home_start_button = _title_button("Start Game", Rect2(95, 480, 634, 64), hover_style, home_controls)
	home_start_button.add_theme_stylebox_override("normal", selected_style)
	home_start_button.add_theme_color_override("font_color", CREAM)
	home_start_button.pressed.connect(_show_boss_selection)
	options_button = _title_button("Options", Rect2(95, 574, 634, 64), hover_style, home_controls)
	options_button.pressed.connect(_show_options)
	quit_button = _title_button("Quit Game", Rect2(95, 668, 634, 64), hover_style, home_controls)
	quit_button.pressed.connect(_shutdown)
	for button in [home_start_button, options_button, quit_button]:
		button.add_theme_font_size_override("font_size", 24)
	options_controls = Control.new()
	options_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(options_controls)
	difficulty_button.reparent(options_controls)
	difficulty_button.position = Vector2(850, 360)
	difficulty_button.size = Vector2(300, 54)
	keyboard_button = _title_button("Change keys", Rect2(850, 278, 300, 54), hover_style, options_controls)
	keyboard_button.pressed.connect(_show_keyboard)
	sound_button = _title_button("", Rect2(850, 442, 300, 54), hover_style, options_controls)
	sound_button.pressed.connect(_toggle_sound)
	fullscreen_button = _title_button("", Rect2(850, 524, 300, 54), hover_style, options_controls)
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	var options_back = _title_button("ESC   Back", Rect2(640, 650, 320, 58), hover_style, options_controls)
	options_back.pressed.connect(_show_home)
	keyboard_controls = Control.new()
	keyboard_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(keyboard_controls)
	for index in range(KEY_ACTIONS.size()):
		var action = KEY_ACTIONS[index]
		var button = _title_button("", Rect2(565 + (0 if index < 5 else 500), 235 + (index % 5) * 70, 170, 50), hover_style, keyboard_controls)
		button.pressed.connect(_begin_binding.bind(action))
		binding_buttons[action] = button
	var reset_keys = _title_button("Reset Keys", Rect2(504, 710, 280, 54), hover_style, keyboard_controls)
	reset_keys.pressed.connect(_reset_bindings)
	var keyboard_back = _title_button("ESC   Back", Rect2(816, 710, 280, 54), hover_style, keyboard_controls)
	keyboard_back.pressed.connect(_show_options)
	pause_controls = Control.new()
	pause_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pause_controls)
	var resume_button = _title_button("ESC   Resume", Rect2(600, 340, 400, 60), hover_style, pause_controls)
	resume_button.add_theme_stylebox_override("normal", selected_style)
	resume_button.add_theme_color_override("font_color", CREAM)
	resume_button.add_theme_font_size_override("font_size", 22)
	resume_button.pressed.connect(_resume_fight)
	var retry_button = _title_button("R   Retry", Rect2(600, 417, 192, 52), hover_style, pause_controls)
	retry_button.pressed.connect(func(): start_fight())
	var bosses_button = _title_button("B   Bosses", Rect2(808, 417, 192, 52), hover_style, pause_controls)
	bosses_button.pressed.connect(_show_boss_selection)
	pause_help_button = _title_button("H   Help", Rect2(664, 520, 272, 48), hover_style, pause_controls)
	pause_help_button.pressed.connect(_toggle_help)
	help_controls = Control.new()
	help_controls.size = Vector2(1600, 900)
	help_controls.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(help_controls)
	close_help_button = _title_button("ESC   Back", Rect2(664, 720, 272, 52), hover_style, help_controls)
	close_help_button.pressed.connect(_toggle_help)
	_sync_boss_selector()

func _title_button(words: String, rect: Rect2, hover_style: StyleBoxFlat, parent: Control = null) -> Button:
	var button = Button.new()
	button.text = words
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", body_font)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", menu_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", selected_style)
	button.add_theme_color_override("font_color", GREEN)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", CREAM)
	button.add_theme_stylebox_override("disabled", menu_style)
	button.add_theme_color_override("font_disabled_color", Color("747865"))
	(title_controls if parent == null else parent).add_child(button)
	return button

func _sync_boss_selector() -> void:
	if not is_instance_valid(title_controls):
		return
	var state = "%s:%s:%d:%d:%s:%s:%s:%s:%s" % [mode, menu_page, selected_level, difficulty, str(spicy_clears), str(help_open), str(muted), str(DisplayServer.window_get_mode()), binding_action + str(key_bindings)]
	if state == selector_state:
		return
	selector_state = state
	title_controls.visible = mode == "title" and menu_page == "bosses" and not help_open
	home_controls.visible = mode == "title" and menu_page == "home" and not help_open
	options_controls.visible = mode == "title" and menu_page == "options" and not help_open
	keyboard_controls.visible = mode == "title" and menu_page == "keyboard" and not help_open
	pause_controls.visible = mode == "paused" and not help_open
	help_controls.visible = help_open
	for index in range(boss_buttons.size()):
		var selected = selected_level == index + 1
		boss_buttons[index].add_theme_stylebox_override("normal", selected_style if selected else menu_style)
		boss_buttons[index].add_theme_color_override("font_color", CREAM if selected else GREEN)
	boss_buttons[4].text = "5   CHEF" if chef_unlocked() else "5   LOCKED"
	boss_buttons[4].tooltip_text = "Win bosses 1–4 on Spicy."
	start_button.disabled = not level_available(selected_level)
	start_button.text = "ENTER   Play" if not start_button.disabled else "Locked"
	difficulty_button.disabled = selected_level == 5
	difficulty_button.text = "SPICY ONLY" if selected_level == 5 else "C   %s" % difficulty_settings().name
	sound_button.text = "Off" if muted else "On"
	fullscreen_button.text = "On" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "Off"
	for action in KEY_ACTIONS:
		binding_buttons[action].text = "Press a key…" if binding_action == action else key_name(key_bindings[action])
		binding_buttons[action].disabled = not binding_action.is_empty() and binding_action != action
	queue_redraw()

func _show_home() -> void:
	menu_page = "home"
	_leave_menu_page()

func _show_options() -> void:
	menu_page = "options"
	_leave_menu_page()

func _show_keyboard() -> void:
	menu_page = "keyboard"
	_leave_menu_page()

func _leave_menu_page() -> void:
	help_open = false
	binding_action = ""
	binding_message = ""
	pressed.clear()
	taps.clear()
	_sync_boss_selector()

func _menu_back() -> void:
	if menu_page == "keyboard":
		_show_options()
	else:
		_show_home()

func _toggle_sound() -> void:
	muted = not muted
	_apply_mute()
	_save_settings()
	_sync_boss_selector()

func _toggle_fullscreen() -> void:
	var full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_enabled = not full
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
	_save_settings()
	_sync_boss_selector()

func key_name(code: int) -> String:
	match code:
		KEY_LEFT: return "←"
		KEY_RIGHT: return "→"
		KEY_UP: return "↑"
		KEY_DOWN: return "↓"
	return OS.get_keycode_string(code)

func _begin_binding(action: String) -> void:
	binding_action = action
	binding_message = "Press a key. Esc cancels."
	pressed.clear()
	taps.clear()
	_sync_boss_selector()

func _capture_binding(code: int) -> void:
	pressed.clear()
	taps.clear()
	if code == KEY_ESCAPE:
		binding_action = ""
		binding_message = ""
	elif code <= 0 or code in RESERVED_KEYS:
		binding_message = "That key is used by the menu."
	else:
		var old_key = key_bindings[binding_action]
		for action in KEY_ACTIONS:
			if action != binding_action and key_bindings[action] == code:
				key_bindings[action] = old_key
				break
		key_bindings[binding_action] = code
		binding_action = ""
		binding_message = ""
		_save_settings()
	_sync_boss_selector()
	queue_redraw()

func _reset_bindings() -> void:
	key_bindings = DEFAULT_KEYS.duplicate()
	binding_action = ""
	binding_message = ""
	_save_settings()
	_sync_boss_selector()

func _toggle_help() -> void:
	if mode == "fight":
		mode = "paused"
	help_open = not help_open
	pressed.clear()
	taps.clear()
	_sync_boss_selector()

func _resume_fight() -> void:
	mode = "fight"
	pressed.clear()
	taps.clear()
	_sync_boss_selector()

func _select_boss(level: int) -> void:
	if mode != "title":
		return
	selected_level = clampi(level, 1, ENCOUNTERS.size())
	_save_settings()
	_sync_boss_selector()

func _cycle_difficulty() -> void:
	if mode != "title" or selected_level == 5:
		return
	difficulty = (difficulty + 1) % DIFFICULTIES.size()
	_save_settings()
	_sync_boss_selector()

func _show_boss_selection() -> void:
	mode = "title"
	menu_page = "bosses"
	help_open = false
	pressed.clear()
	taps.clear()
	_save_settings()
	_sync_boss_selector()

func down(keys: Array) -> bool:
	for key in keys:
		if pressed.has(key):
			return true
	return false

func tapped(keys: Array) -> bool:
	for key in keys:
		if taps.has(key):
			return true
	return false

func action_keys(action: String) -> Array:
	return [key_bindings.jump, key_bindings.jump_alt] if action == "jump" else [key_bindings[action]]

func action_down(action: String) -> bool:
	return down(action_keys(action))

func action_tapped(action: String) -> bool:
	return tapped(action_keys(action))

func encounter(level: int = 0) -> Dictionary:
	return ENCOUNTERS[current_level if level == 0 else level]

func difficulty_settings() -> Dictionary:
	return DIFFICULTIES[effective_difficulty()]

func effective_difficulty() -> int:
	var level = selected_level if mode == "title" else current_level
	return Difficulty.SPICY if level == 5 else clampi(difficulty, 0, DIFFICULTIES.size() - 1)

func chef_unlocked() -> bool:
	return spicy_clears.all(func(won): return won)

func level_available(level: int) -> bool:
	return level >= 1 and (level <= 4 or (level == 5 and chef_unlocked()))

func spicy_checklist() -> String:
	var words = "SPICY WINS: "
	for index in range(4):
		words += "%d [%s]   " % [index + 1, "✓" if spicy_clears[index] else "–"]
	return words + ("CHEF UNLOCKED!" if chef_unlocked() else "CHEF LOCKED")

func _damage_boss(base_damage: float) -> void:
	var multiplier = 0.5 if boss_hp < boss_max_hp * 0.5 else 1.0
	boss_hp = maxf(0, boss_hp - base_damage * multiplier)

func _add_charge(amount: float) -> void:
	var was_full = charge >= MAX_CHARGE
	charge = minf(MAX_CHARGE, charge + amount)
	if is_equal_approx(charge, MAX_CHARGE):
		charge = MAX_CHARGE
	if not was_full and charge >= MAX_CHARGE:
		burst(player - Vector2(0, 65), 18, GOLD, 180)
		sfx("parry", 1.3)

func boss_hitbox() -> Rect2:
	if current_level == 5:
		return Rect2(boss_position + Vector2(-135, -340), Vector2(270, 310))
	if current_level == 4:
		return Rect2(boss_position + Vector2(-145, -295), Vector2(290, 265))
	if current_level == 3:
		return Rect2(boss_position + Vector2(-145, -280), Vector2(290, 254))
	if current_level == 2:
		return Rect2(boss_position + Vector2(-125, -347), Vector2(250, 320))
	return Rect2(boss_position + Vector2(-145, -248), Vector2(290, 220))

func start_fight(level: int = 0) -> bool:
	var requested = clampi(level if level > 0 else current_level, 1, ENCOUNTERS.size())
	if not level_available(requested):
		selected_level = requested
		_show_boss_selection()
		return false
	current_level = requested
	selected_level = current_level
	mode = "fight"
	help_open = false
	fight_difficulty = effective_difficulty()
	player = Vector2(260, FLOOR_Y)
	velocity = Vector2.ZERO
	facing = 1.0
	max_health = difficulty_settings().hearts
	health = max_health
	boss_max_hp = roundf(encounter().hp * difficulty_settings().boss_health_scale)
	boss_hp = boss_max_hp
	phase = 1
	fight_time = 0
	intro = 2.0
	hurt_timer = 0
	boss_hurt = 0
	fire_cooldown = 0
	dash_timer = 0
	dash_cooldown = 0
	parry_timer = 0
	jump_buffer = 0
	coyote = 0
	air_jump_available = true
	charge = 0
	attack_clock = 2.3 * difficulty_settings().cycle_scale
	attack_index = 0
	warning = ""
	warning_time = 0
	pending_attack = -1
	volley_remaining = 0
	volley_clock = 0
	quip = encounter().quips[0]
	quip_time = 2
	shake = 0
	flash = 0
	result_time = 0
	shots.clear()
	energy_balls.clear()
	hazards.clear()
	particles.clear()
	floating_text.clear()
	taps.clear()
	pressed.clear()
	rng.seed = 7342 + (current_level - 1) * 100
	if is_instance_valid(music):
		music.pitch_scale = [1.0, 1.08, 1.13, 1.18, 1.22][current_level - 1]
	_sync_boss_selector()
	return true

func _prepare_stage() -> void:
	if not is_instance_valid(stage_cache):
		return
	var viewport = get_viewport()
	# Window texture sizes include the design-canvas stretch transform in Godot;
	# the concrete viewport size gives actual pixels without accidental supersampling.
	var pixel_size = (viewport as Window).size if viewport is Window else (viewport as SubViewport).size
	stage_cache.prepare(selected_level if mode == "title" else current_level, pixel_size, viewport.msaa_2d)

func _process(_dt: float) -> void:
	_prepare_stage()
	_sync_boss_selector()
	queue_redraw()

func _physics_process(dt: float) -> void:
	elapsed += dt
	if mode == "title":
		title_time += dt
	elif mode == "fight":
		step_fight(dt)
	elif mode in ["win", "lose"]:
		result_time += dt
		_update_particles(dt)
	taps.clear()

func step_fight(dt: float) -> void:
	hurt_timer = maxf(0, hurt_timer - dt)
	boss_hurt = maxf(0, boss_hurt - dt)
	shake = maxf(0, shake - dt * 24)
	flash = maxf(0, flash - dt * 2)
	quip_time = maxf(0, quip_time - dt)
	_update_particles(dt)
	if intro > 0:
		intro -= dt
		return
	fight_time += dt
	_update_player(dt)
	_update_boss(dt)
	_update_shots(dt)
	_update_energy_balls(dt)
	_update_hazards(dt)
	if health <= 0 and mode == "fight":
		mode = "lose"
		result_time = 0
		shake = 12
		sfx("hit")
	elif boss_hp <= 0 and mode == "fight":
		_win()

func _update_player(dt: float) -> void:
	fire_cooldown -= dt
	dash_cooldown = maxf(0, dash_cooldown - dt)
	parry_timer = maxf(0, parry_timer - dt)
	jump_buffer = maxf(0, jump_buffer - dt)
	var direction = float(action_down("move_right")) - float(action_down("move_left"))
	if direction != 0 and dash_timer <= 0:
		facing = direction
	if player.y >= FLOOR_Y:
		coyote = 0.09
		air_jump_available = true
	else:
		coyote = maxf(0, coyote - dt)
	if action_tapped("jump"):
		jump_buffer = 0.12
	if jump_buffer > 0 and dash_timer <= 0 and not action_tapped("dash") and (coyote > 0 or (air_jump_available and player.y < FLOOR_Y)):
		var air_jump = coyote <= 0
		if air_jump:
			air_jump_available = false
		velocity.y = -860
		jump_buffer = 0
		coyote = 0
		burst(player - Vector2(0, 5), 16 if air_jump else 8, GOLD if air_jump else CREAM, 190 if air_jump else 150)
		sfx("jump", 1.2 if air_jump else 1.0)
	if not action_down("jump") and velocity.y < -340:
		velocity.y = -340
	if action_tapped("dash") and dash_cooldown <= 0:
		dash_timer = 0.18
		dash_cooldown = 0.85
		burst(player - Vector2(0, 48), 9, CREAM, 200)
		sfx("dash")
	if action_tapped("parry"):
		parry_timer = 0.22
		for h in hazards:
			if h.pink and not h.dead and h.p.distance_to(player - Vector2(0, 54)) < 112:
				h.dead = true
				_add_charge(1.25)
				velocity.y = -650
				hurt_timer = maxf(hurt_timer, 0.3)
				burst(h.p, 22, Color("f2a8ad"), 350)
				floating("PARRY!", h.p, Color("ffe0e3"))
				sfx("parry")
				break
	if action_tapped("super") and charge >= MAX_CHARGE:
		charge = 0
		var origin = player + Vector2(80 * facing, -69)
		energy_balls.append({"p": origin, "v": Vector2(facing * 860, 0), "life": 2.6, "age": 0.0})
		hurt_timer = maxf(hurt_timer, 0.65)
		shake = 5
		burst(origin, 24, Color("a1e7e8"), 300)
		sfx("super")
	if dash_timer > 0:
		dash_timer = maxf(0, dash_timer - dt)
		velocity.x = facing * 1100
		velocity.y = 0
		if rng.randf() < 0.5:
			burst(player - Vector2(0, 50), 1, Color("d8e6b3"), 60)
	else:
		velocity.x = move_toward(velocity.x, direction * 390, dt * 3400)
		velocity.y += GRAVITY * dt
	player += velocity * dt
	player.x = clampf(player.x, 60, 1525)
	if player.y >= FLOOR_Y:
		player.y = FLOOR_Y
		velocity.y = 0
		air_jump_available = true
	if action_down("shoot") and fire_cooldown <= 0:
		fire_cooldown = 0.125
		var vertical_aim = float(action_down("aim_down")) - float(action_down("aim_up"))
		var aim = Vector2(facing, vertical_aim * 0.8).normalized()
		shots.append({"p": player + Vector2(74 * facing, -69), "v": aim * 1150, "life": 1.5})
		_add_charge(SHOT_CHARGE)
		burst(player + Vector2(80 * facing, -69), 2, GOLD, 90)
		sfx("shoot", rng.randf_range(0.92, 1.08))
	var contact = boss_hitbox().grow(5) if current_level >= 3 else (Rect2(boss_position + Vector2(-132, -347), Vector2(264, 360)) if current_level == 2 else Rect2(boss_position + Vector2(-148, -245), Vector2(296, 260)))
	if contact.has_point(player - Vector2(0, 48)):
		_damage()

func _update_boss(dt: float) -> void:
	if phase == 1 and boss_hp <= boss_max_hp * 0.5:
		phase = 2
		warning = ["OVERHEATING!", "TURBO!", "BOILING!", "FRYING FRENZY!", "DINNER RUSH!"][current_level - 1]
		warning_time = 1.6
		pending_attack = -1
		attack_clock = 2.1 * difficulty_settings().cycle_scale
		volley_remaining = 0
		quip = ["NOW I'M REALLY HEATED!", "TIME TO LOSE MY LID!", "THAT'S MY BOILING POINT!", "NO MORE MR. FRY GUY!", "THIS KITCHEN BITES!"][current_level - 1]
		quip_time = 2.5
		flash = 0.2
		shake = 7
		sfx("pop")
	attack_clock -= dt
	if warning_time > 0:
		warning_time -= dt
		if warning_time <= 0:
			warning = ""
			if pending_attack >= 0:
				_begin_attack(pending_attack)
				pending_attack = -1
	if attack_clock <= 0 and warning_time <= 0:
		var pattern = attack_index % encounter().warnings.size()
		attack_index += 1
		pending_attack = pattern
		warning = encounter().warnings[pattern]
		warning_time = difficulty_settings().warning
		attack_clock = ([3.6, 3.9, 3.8, 3.7, 3.8][current_level - 1] if phase == 1 else [2.9, 3.1, 3.0, 2.9, 2.9][current_level - 1]) * difficulty_settings().cycle_scale + warning_time
		quip = encounter().quips[attack_index % encounter().quips.size()]
		quip_time = 2.1
	if volley_remaining > 0:
		volley_clock -= dt
		if volley_clock <= 0:
			_spawn_volley(volley_kind, volley_remaining)
			volley_remaining -= 1
			var intervals = [[0.38, 0.38, 0.38, 0.38], [0.58, 0.48, 0.46], [0.52, 0.40], [0.48, 0.55], [0.50, 0.60, 0.60]]
			volley_clock = intervals[current_level - 1][volley_kind] * (1.0 if phase == 1 else [0.28 / 0.38, 0.8, 0.78, 0.78, 0.76][current_level - 1]) * difficulty_settings().volley_scale

func _begin_attack(kind: int) -> void:
	volley_kind = kind
	var counts = [[4, 4, 2, 5], [3, 3, 4], [3, 5], [4, 3], [4, 3, 3]]
	volley_remaining = counts[current_level - 1][kind] + (1 if phase == 2 else 0) + difficulty_settings().extra_volleys
	volley_clock = 0
	sfx("pop")

func _spawn_volley(kind: int, index: int) -> void:
	if current_level == 5:
		_spawn_chef_volley(kind, index)
		return
	if current_level == 4:
		_spawn_skillet_volley(kind, index)
		return
	if current_level == 3:
		_spawn_kettle_volley(kind, index)
		return
	if current_level == 2:
		_spawn_blender_volley(kind, index)
		return
	var speed = _attack_speed(350.0, 430.0, 70.0)
	match kind:
		0:
			var y = 659.0 if index % 2 == 0 else 530.0
			_hazard(Vector2(1110, y), Vector2(-speed, 0), "toast", false, 26, 0)
		1:
			var target = player - Vector2(0, 52)
			var origin = Vector2(1110, 538)
			_hazard(origin, (target - origin).normalized() * speed * 0.85, "jam", index % 2 == 0, 21, 0)
		2:
			_hazard(Vector2(1120, 721), Vector2(-speed * 1.5, 0), "wave", false, 25, 0)
			shake = 6
		3:
			_hazard(Vector2(1100, 411), Vector2(-speed * rng.randf_range(0.8, 1.3), -rng.randf_range(130, 270)), "ball", index == 3, 25, 700)

func _spawn_blender_volley(kind: int, index: int) -> void:
	var speed = _attack_speed(370.0, 450.0, 55.0)
	match kind:
		0:
			var banana_speed = speed + 200
			var banana_y = FLOOR_Y - (42.0 if index % 2 == 1 else 64.0)
			_hazard(Vector2(1105, banana_y), Vector2(-banana_speed, 0), "banana", false, 30, 0)
			# Slow down, turn, then sweep back across the counter.
			hazards.back().ax = banana_speed * banana_speed / 2000.0
		1:
			var origin = Vector2(1138, 504)
			var direction = (player - Vector2(0, 53) - origin).normalized()
			for spread in [-1, 0, 1]:
				_hazard(origin, direction.rotated(spread * 0.17) * speed * 0.9, "smoothie", spread == 0 and index % 2 == 1, 19, 0)
		2:
			_hazard(Vector2(1120, 440), Vector2(-speed * rng.randf_range(0.85, 1.1), -290), "berry", index == 2, 24, 850)

func _spawn_kettle_volley(kind: int, index: int) -> void:
	var speed = _attack_speed(390.0, 460.0, 55.0)
	match kind:
		0:
			var origin = Vector2(1107, 494)
			var target = player - Vector2(0, 53)
			var travel_time = maxf(0.4, absf(target.x - origin.x) / speed)
			var gravity = 350.0
			var launch_velocity = Vector2((target.x - origin.x) / travel_time, (target.y - origin.y - 0.5 * gravity * travel_time * travel_time) / travel_time)
			_hazard(origin, launch_velocity, "tea", index == 2, 23, gravity)
		1:
			_hazard(Vector2(1115, 680 if index % 2 == 0 else 694), Vector2(-speed * 0.95, 95), "biscuit", index == 3, 25, 0)

func _spawn_skillet_volley(kind: int, index: int) -> void:
	var speed = _attack_speed(400.0, 475.0, 60.0)
	match kind:
		0:
			_hazard(Vector2(1112, 681 if index % 2 == 0 else 705), Vector2(-speed * 0.95, 0), "pancake", index == 2, 26, 0)
		1:
			var origin = Vector2(1120, 512)
			var direction = (player - Vector2(0, 53) - origin).normalized()
			for spread in [-1, 0, 1]:
				_hazard(origin, direction.rotated(spread * 0.18) * speed * 0.93, "oil", spread == 0 and index % 2 == 1, 20, 0)

func _spawn_chef_volley(kind: int, index: int) -> void:
	var speed = _attack_speed(415.0, 490.0, 65.0)
	match kind:
		0:
			_hazard(Vector2(1115, 690), Vector2(-speed * 0.92, -170), "ravioli", index == 2, 25, 850)
		1:
			var origin = Vector2(1110, 430)
			var target = player - Vector2(0, 53)
			var travel_time = maxf(0.4, absf(target.x - origin.x) / speed)
			var gravity = 480.0
			var launch_velocity = Vector2((target.x - origin.x) / travel_time, (target.y - origin.y - 0.5 * gravity * travel_time * travel_time) / travel_time)
			_hazard(origin, launch_velocity, "sauce", index % 2 == 1, 24, gravity)
		2:
			_hazard(Vector2(1115, 682 if index % 2 == 0 else 548), Vector2(-speed * 1.15, 0), "whisk", false, 30, 0)

func _attack_speed(cozy_speed: float, spicy_speed: float, phase_bonus: float) -> float:
	return (lerpf(cozy_speed, spicy_speed, difficulty_settings().speed_blend) + (phase_bonus if phase == 2 else 0.0)) * difficulty_settings().speed_scale

func _hazard(p: Vector2, v: Vector2, kind: String, pink: bool, radius: float, gravity: float) -> void:
	var breakable = kind not in ARMORED_ATTACKS
	hazards.append({"p": p, "v": v, "kind": kind, "pink": pink and breakable, "breakable": breakable, "r": radius, "g": gravity, "ax": 0.0, "age": 0.0, "bounces": 0, "dead": false})

func _hazard_velocity(h: Dictionary, dt: float) -> Vector2:
	var next_velocity: Vector2 = h.v + Vector2(h.ax, h.g) * dt
	if h.kind == "biscuit":
		next_velocity.y = cos((h.age + dt) * 4.8) * 95.0
	elif h.kind == "pancake":
		next_velocity.y = sin((h.age + dt) * 6.0) * 65.0
	return next_velocity

func _update_shots(dt: float) -> void:
	var boss_rect = boss_hitbox()
	for shot in shots:
		if shot.life <= 0:
			continue
		var travel_time = minf(dt, shot.life)
		var start: Vector2 = shot.p
		var finish: Vector2 = start + shot.v * travel_time
		var hit_time = _segment_rect_hit(start, finish, boss_rect.grow(BULLET_RADIUS))
		var hit_food: Dictionary = {}
		# Sweep against relative motion so fast bullets and incoming food cannot
		# pass through each other between physics ticks. Resolve the first hit.
		for h in hazards:
			if h.dead:
				continue
			var food_motion = _hazard_velocity(h, travel_time) * travel_time
			var food_hit = _segment_circle_hit(start - h.p, finish - h.p - food_motion, h.r + BULLET_RADIUS)
			if food_hit < hit_time:
				hit_time = food_hit
				hit_food = h
		shot.p = start.lerp(finish, hit_time) if hit_time != INF else finish
		shot.life -= dt
		if hit_time == INF:
			continue
		shot.life = -1
		if not hit_food.is_empty():
			if not hit_food.breakable:
				burst(shot.p, 5, Color("a1e7e8"), 170)
				sfx("pop", 1.8)
				continue
			hit_food.dead = true
			var crumb_color = Color("f2a8ad") if hit_food.pink else (RED if hit_food.kind in ["jam", "smoothie", "berry"] else GOLD)
			burst(shot.p, 14, crumb_color, 240)
			sfx("pop", rng.randf_range(1.15, 1.4))
		else:
			_damage_boss(1.9)
			boss_hurt = 0.06
			burst(shot.p, 3, GOLD, 160)
	shots = shots.filter(func(s): return s.life > 0 and s.p.x > -80 and s.p.x < 1680 and s.p.y > -80)

func _update_energy_balls(dt: float) -> void:
	for ball in energy_balls:
		var travel_time = minf(dt, ball.life)
		var start: Vector2 = ball.p
		var finish: Vector2 = start + ball.v * travel_time
		var boss_hit = _segment_rect_hit(start, finish, boss_hitbox().grow(ENERGY_BALL_RADIUS))
		# The energy ball passes armored attacks without destroying them.
		for h in hazards:
			if h.dead or not h.breakable:
				continue
			var food_motion = _hazard_velocity(h, travel_time) * travel_time
			var food_hit = _segment_circle_hit(start - h.p, finish - h.p - food_motion, h.r + ENERGY_BALL_RADIUS)
			if food_hit != INF and food_hit <= boss_hit:
				h.dead = true
				burst(start.lerp(finish, food_hit), 12, Color("a1e7e8"), 260)
		ball.p = start.lerp(finish, boss_hit) if boss_hit != INF else finish
		ball.life -= dt
		ball.age += dt
		if boss_hit != INF:
			var previous_hp = boss_hp
			_damage_boss(SUPER_DAMAGE)
			ball.life = -1
			boss_hurt = 0.35
			shake = 13
			flash = 0.16
			burst(ball.p, 50, Color("a1e7e8"), 560)
			burst(ball.p, 22, GOLD, 430)
			floating("SUPER!  -%d" % roundi(previous_hp - boss_hp), ball.p - Vector2(0, 100), GREEN)
			sfx("pop", 0.7)
	energy_balls = energy_balls.filter(func(b): return b.life > 0 and b.p.x > -180 and b.p.x < 1780 and b.p.y > -180 and b.p.y < 1080)

func _segment_circle_hit(start: Vector2, finish: Vector2, radius: float) -> float:
	var c = start.length_squared() - radius * radius
	if c <= 0:
		return 0.0
	var motion = finish - start
	var a = motion.length_squared()
	if a <= 0.000001:
		return INF
	var b = 2.0 * start.dot(motion)
	var discriminant = b * b - 4.0 * a * c
	if discriminant < 0:
		return INF
	var hit = (-b - sqrt(discriminant)) / (2.0 * a)
	return hit if hit >= 0 and hit <= 1 else INF

func _segment_rect_hit(start: Vector2, finish: Vector2, rect: Rect2) -> float:
	var motion = finish - start
	var first = 0.0
	var last = 1.0
	for axis in range(2):
		if absf(motion[axis]) < 0.000001:
			if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]:
				return INF
		else:
			var near_time = (rect.position[axis] - start[axis]) / motion[axis]
			var far_time = (rect.end[axis] - start[axis]) / motion[axis]
			first = maxf(first, minf(near_time, far_time))
			last = minf(last, maxf(near_time, far_time))
			if first > last:
				return INF
	return first

func _update_hazards(dt: float) -> void:
	var body = player - Vector2(0, 53)
	for h in hazards:
		if h.dead:
			continue
		h.v = _hazard_velocity(h, dt)
		h.p += h.v * dt
		h.age += dt
		var max_bounces = 3 if h.kind in ["berry", "ravioli"] else 2
		if h.kind in ["ball", "berry", "ravioli"] and h.p.y > FLOOR_Y - h.r and h.bounces < max_bounces:
			h.p.y = FLOOR_Y - h.r
			h.v.y = -absf(h.v.y) * 0.75
			h.bounces += 1
			burst(h.p, 5, GOLD, 130)
		elif h.kind == "ravioli" and h.p.y > FLOOR_Y - h.r:
			# After three hops, pasta slides along the counter instead of falling through.
			h.p.y = FLOOR_Y - h.r
			h.v.y = 0
			h.g = 0
		var dx = absf(body.x - h.p.x)
		var dy = absf(body.y - h.p.y)
		# Character collision is deliberately kinder than the illustration.
		if dx < h.r + 18 and dy < h.r + 30 and dash_timer <= 0:
			if h.pink and parry_timer > 0:
				h.dead = true
				_add_charge(1.25)
				velocity.y = -650
				hurt_timer = maxf(hurt_timer, 0.3)
				burst(h.p, 20, Color("f2a8ad"), 350)
				floating("PARRY!", h.p, Color("ffe0e3"))
				sfx("parry")
			elif hurt_timer <= 0:
				_damage()
				h.dead = h.breakable
	hazards = hazards.filter(func(h): return not h.dead and h.age < 9 and h.p.x > -100 and h.p.x < 1720 and h.p.y < 1050)

func _damage() -> void:
	if hurt_timer > 0 or dash_timer > 0:
		return
	health -= 1
	hurt_timer = difficulty_settings().hit_grace
	shake = 8
	flash = 0.12
	burst(player - Vector2(0, 50), 18, RED, 270)
	floating("OW, MY YOLK!", player - Vector2(0, 145), CREAM)
	sfx("hit")

func rank_result() -> String:
	if health == max_health and fight_time < 65:
		return "S"
	if health >= max_health - 1:
		return "A"
	return "B" if health > 1 else "C"

func _win() -> void:
	mode = "win"
	result_time = 0
	shake = 13
	sfx("win")
	for i in range(85):
		particles.append({"p": Vector2(rng.randf_range(50, 1550), rng.randf_range(-100, 200)), "v": Vector2(rng.randf_range(-80, 80), rng.randf_range(80, 220)), "life": 5.0, "max": 5.0, "color": [GOLD, RED, CREAM, Color("93b9a5")][i % 4], "r": rng.randf_range(4, 9)})
	if current_level <= 4 and fight_difficulty == Difficulty.SPICY:
		spicy_clears[current_level - 1] = true
	unlocked_level = maxi(unlocked_level, mini(current_level + 1, 5 if chef_unlocked() else 4))
	if current_level == 1:
		if best_time == 0 or fight_time < best_time:
			best_time = fight_time
			best_rank = rank_result()
	elif current_level == 2:
		if second_best_time == 0 or fight_time < second_best_time:
			second_best_time = fight_time
			second_best_rank = rank_result()
	elif current_level == 3:
		if third_best_time == 0 or fight_time < third_best_time:
			third_best_time = fight_time
			third_best_rank = rank_result()
	elif current_level == 4:
		if fourth_best_time == 0 or fight_time < fourth_best_time:
			fourth_best_time = fight_time
			fourth_best_rank = rank_result()
	elif fifth_best_time == 0 or fight_time < fifth_best_time:
		fifth_best_time = fight_time
		fifth_best_rank = rank_result()
	_save_settings()

func burst(p: Vector2, count: int, color: Color, speed: float) -> void:
	for i in range(count):
		var angle = rng.randf() * TAU
		var life = rng.randf_range(0.2, 0.6)
		particles.append({"p": p, "v": Vector2(cos(angle), sin(angle)) * rng.randf_range(speed * 0.2, speed), "life": life, "max": life, "color": color, "r": rng.randf_range(2.5, 6.0)})
	if particles.size() > 450:
		particles = particles.slice(particles.size() - 450)

func floating(words: String, p: Vector2, color: Color) -> void:
	floating_text.append({"text": words, "p": p, "color": color, "life": 0.9})

func _update_particles(dt: float) -> void:
	for particle in particles:
		particle.p += particle.v * dt
		particle.v.y += 240 * dt
		particle.life -= dt
	particles = particles.filter(func(p): return p.life > 0)
	for item in floating_text:
		item.p.y -= dt * 48
		item.life -= dt
	floating_text = floating_text.filter(func(item): return item.life > 0)

func sfx(name_value: String, pitch: float = 1.0) -> void:
	if test_mode or not sounds.has(name_value) or muted or sound_players.is_empty():
		return
	var audio = sound_players[sound_index % sound_players.size()]
	sound_index += 1
	audio.stream = sounds[name_value]
	audio.pitch_scale = pitch
	audio.volume_db = -24 if name_value == "shoot" else -12
	audio.play()

func _draw_boss(level: int, p: Vector2, s: float = 1.0, preview: bool = false) -> void:
	var drawn_phase = 1 if preview else phase
	var windup = sin(elapsed * 1.4) > 0.8 if preview else warning_time > 0
	var hurt = false if preview else boss_hurt > 0
	var defeated = false if preview else mode == "win"
	match level:
		1:
			toaster(p, elapsed, drawn_phase, windup, hurt, defeated, s)
		2:
			blender(p, elapsed, drawn_phase, windup, hurt, defeated, s)
		3:
			kettle(p, elapsed, drawn_phase, windup, hurt, defeated, s)
		4:
			skillet(p, elapsed, drawn_phase, windup, hurt, defeated, s)
		5:
			chef(p, elapsed, drawn_phase, windup, hurt, defeated, s)

func _draw() -> void:
	var background: Texture2D = stage_cache.texture() if is_instance_valid(stage_cache) else null
	if background != null:
		draw_texture_rect(background, Rect2(0, 0, 1600, 900), false)
	else:
		stage(selected_level if mode == "title" else current_level)
	if mode == "title":
		if menu_page == "options":
			_draw_options()
		elif menu_page == "keyboard":
			_draw_keyboard()
		else:
			_draw_title()
		if help_open:
			_draw_help()
		return
	# Subtle soft shadows keep moving objects grounded.
	oval(Vector2(player.x, FLOOR_Y + 6), Vector2(45, 9), Color(0.12, 0.23, 0.18, 0.23))
	oval(boss_position + Vector2(0, 20), Vector2(170, 17), Color(0.12, 0.23, 0.18, 0.25))
	var drawn_boss = boss_position + Vector2(sin(elapsed * 71) * shake * 0.5, 0)
	_draw_boss(current_level, drawn_boss)
	if phase == 2:
		for i in range(4):
			var rise = fmod(elapsed * 70 + i * 37, 140)
			var puff_color = [Color("4a5445"), Color("ce6d96"), CREAM, Color("f0ac65"), Color("e6bb75")][current_level - 1]
			puff_color.a = (1.0 - rise / 140) * 0.65
			oval(boss_position + Vector2(-70 + i * 46 + sin(elapsed * 3 + i) * 12, -[325, 415, 375, 400, 420][current_level - 1] - rise), Vector2(12 + rise * 0.1, 9 + rise * 0.09), puff_color)
	for shot in shots:
		line([shot.p - shot.v.normalized() * 23, shot.p], Color("edbe58"), 13)
		line([shot.p - shot.v.normalized() * 17, shot.p], CREAM, 5)
	for ball in energy_balls:
		_draw_energy_ball(ball)
	for h in hazards:
		_draw_hazard(h)
	if dash_timer > 0:
		for i in range(3):
			line([player + Vector2(-facing * (70 + i * 15), -33 - i * 20), player + Vector2(-facing * (130 + i * 20), -33 - i * 20)], CREAM, 4)
	if parry_timer > 0:
		draw_arc(player - Vector2(0, 52), 65, 0, TAU, 40, Color("f2a8ad"), 5, true)
	egg(player, elapsed, absf(velocity.x) > 30, player.y < FLOOR_Y - 1, facing, hurt_timer > 0, dash_timer > 0)
	_draw_particles()
	_draw_hud()
	if warning_time > 0:
		box(Rect2(620, 162, 360, 50), RED if warning == "JUMP / DASH" else GREEN, 25)
		center(warning, 195, 23, CREAM)
		if warning == "JUMP / DASH":
			shield_marker(Vector2(652, 187))
	if flash > 0:
		draw_rect(Rect2(0, 142, 1600, 725), Color(1, 0.91, 0.65, flash))
	if intro > 0:
		_draw_intro()
	if help_open:
		_draw_help()
	elif mode == "paused":
		_draw_pause()
	elif mode in ["win", "lose"]:
		_draw_result()

func _draw_energy_ball(ball: Dictionary) -> void:
	var p: Vector2 = ball.p
	var direction: Vector2 = ball.v.normalized()
	var pulse = sin(ball.age * 20) * 3
	for i in range(4, 0, -1):
		var tail = p - direction * (38 + i * 16)
		draw_circle(tail, 31 - i * 4, Color(0.25, 0.69, 0.73, 0.45 - i * 0.07))
	draw_circle(p, 66 + pulse, Color(0.35, 0.82, 0.82, 0.13))
	draw_circle(p, 53 + pulse, Color(0.35, 0.82, 0.82, 0.22))
	draw_circle(p, ENERGY_BALL_RADIUS, Color("275c64"))
	draw_circle(p, ENERGY_BALL_RADIUS - 4, Color("69d3d6"))
	draw_circle(p - direction * 3, 29 + pulse * 0.4, Color("b8f0e8"))
	draw_circle(p + direction * 7, 19, Color("fff8dc"))
	var spin = ball.age * 8
	draw_arc(p, 48, spin, spin + PI * 0.75, 24, CREAM, 4, true)
	draw_arc(p, 48, spin + PI, spin + PI * 1.75, 24, Color("398b96"), 4, true)
	star(p + Vector2(sin(spin), cos(spin)) * 54, 8, CREAM, spin)

func _draw_hazard(h: Dictionary) -> void:
	var color = Color("efa8b5") if h.pink else GOLD
	if h.pink:
		draw_arc(h.p, h.r + 9 + sin(elapsed * 7) * 2, 0, TAU, 32, Color("ffe0e3"), 3, true)
	match h.kind:
		"toast":
			toast(h.p, 0.8, sin(h.age * 5) * 0.2, phase == 2)
		"jam":
			oval(h.p, Vector2(25, 20), color if h.pink else RED, 3)
			oval(h.p + Vector2(-7, -6), Vector2(7, 4), CREAM)
			line([h.p + Vector2(20, 0), h.p + Vector2(38, -4)], color, 5)
		"ball":
			draw_circle(h.p, 25, INK)
			draw_circle(h.p, 21, color)
			for i in range(3):
				var a = i * TAU / 3 + h.age * 3
				draw_line(h.p + Vector2(cos(a), sin(a)) * 4, h.p + Vector2(cos(a), sin(a)) * 17, Color("af7737"), 3)
		"wave":
			var points = PackedVector2Array([h.p + Vector2(-34, 22), h.p + Vector2(-26, -6), h.p + Vector2(-12, 6), h.p + Vector2(1, -36), h.p + Vector2(18, -10), h.p + Vector2(27, -24), h.p + Vector2(41, 22)])
			draw_colored_polygon(points, GOLD)
			draw_polyline(points, INK, 4, true)
			line([h.p + Vector2(48, 5), h.p + Vector2(78, 5)], CREAM, 4)
		"banana":
			banana(h.p, h.age * 4.5, 0.85)
		"smoothie":
			oval(h.p, Vector2(23, 18), color if h.pink else Color("a66d99"), 3)
			oval(h.p + Vector2(-6, -6), Vector2(7, 4), CREAM)
			for i in range(2):
				draw_circle(h.p - h.v.normalized() * (30 + i * 14), 5 - i, color if h.pink else Color("a66d99"))
		"berry":
			draw_circle(h.p, 25, INK)
			draw_circle(h.p, 21, color if h.pink else Color("bc5361"))
			star(h.p + Vector2(0, -21), 13, GREEN, h.age)
			for offset in [Vector2(-10, -5), Vector2(7, -8), Vector2(0, 9)]:
				oval(h.p + offset, Vector2(2, 3), CREAM)
		"tea":
			oval(h.p, Vector2(24, 18), Color("efb3bf") if h.pink else Color("b77942"), 3)
			oval(h.p + Vector2(-6, -6), Vector2(7, 4), CREAM)
			draw_circle(h.p - h.v.normalized() * 28, 6, Color("efb3bf") if h.pink else Color("c69356"))
		"biscuit":
			biscuit(h.p, h.age * 4, h.pink)
		"pancake":
			pancake(h.p, h.age * 6, h.pink)
		"oil":
			oval(h.p, Vector2(23, 18), Color("f1adc4") if h.pink else Color("d79537"), 3)
			oval(h.p + Vector2(-6, -6), Vector2(7, 4), CREAM)
			line([h.p - h.v.normalized() * 28, h.p - h.v.normalized() * 44], GOLD, 4)
		"ravioli":
			ravioli(h.p, h.age * 3, h.pink)
		"sauce":
			oval(h.p, Vector2(26, 21), Color("f3a8bd") if h.pink else RED, 3)
			oval(h.p + Vector2(-7, -6), Vector2(8, 5), CREAM)
			for i in range(2):
				draw_circle(h.p - h.v.normalized() * (30 + i * 12), 6 - i, Color("f3a8bd") if h.pink else RED)
		"whisk":
			flying_whisk(h.p, h.age * 5)
	if not h.breakable:
		draw_arc(h.p, h.r + 8, 0, TAU, 36, Color("a1e7e8"), 3, true)
		shield_marker(h.p + Vector2(0, -h.r - 17))

func _draw_particles() -> void:
	for particle in particles:
		var color: Color = particle.color
		color.a *= minf(1, particle.life / particle.max * 2)
		draw_circle(particle.p, particle.r * minf(1, particle.life / particle.max * 2), color)
	for item in floating_text:
		center(item.text, item.p.y, 22, item.color, false, item.p.x)

func _draw_title() -> void:
	# Storybook cover, with the living kitchen visible around its edges.
	box(Rect2(48, 85, 728, 730), Color(0.99, 0.95, 0.83), 28, 3)
	label_at("Panic at", Vector2(91, 290), 91, INK, true)
	label_at("the Pantry", Vector2(86, 394), 100, RED, true)
	line([Vector2(96, 423), Vector2(704, 423)], INK, 2)
	if menu_page == "bosses":
		label_at("Boss", Vector2(96, 458), 20, GREEN)
		if selected_level == 5:
			label_at("Chef unlocked!" if chef_unlocked() else "Win bosses 1–4 on Spicy.", Vector2(96, 670), 18, GREEN)
			_draw_spicy_progress(Vector2(540, 663))
		var hint = "%s %s  Move     %s  Jump ×2     %s  Shoot" % [key_name(key_bindings.move_left), key_name(key_bindings.move_right), key_name(key_bindings.jump), key_name(key_bindings.shoot)]
		var hint_width = body_font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		label_at(hint, Vector2(96, 707), mini(19, int(19 * 630 / maxf(630, hint_width))))
	# Large animated cast illustration.
	oval(Vector2(1192, 749), Vector2(237, 24), Color(0.13, 0.23, 0.18, 0.2))
	_draw_boss(selected_level, Vector2(1208, 715 if selected_level == 1 else 737), [1.21, 1.05, 1.10, 1.0, 1.0][selected_level - 1], true)
	egg(Vector2(864, 751 + sin(elapsed * 3) * 4), elapsed, false, false)
	star(Vector2(964, 329), 17, GOLD, elapsed * 0.25)
	star(Vector2(1486, 408), 12, RED, -elapsed * 0.25)
	if menu_page == "bosses":
		center(encounter(selected_level).boss, 800, 22, CREAM, false, 1209)
	var record_time = [best_time, second_best_time, third_best_time, fourth_best_time, fifth_best_time][selected_level - 1]
	var record_rank = [best_rank, second_best_rank, third_best_rank, fourth_best_rank, fifth_best_rank][selected_level - 1]
	if record_time > 0 and menu_page == "bosses":
		center("Best: %s · %.1fs" % [record_rank, record_time], 842, 16, CREAM, false, 1209)

func _draw_options() -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.12, 0.2, 0.17, 0.65))
	box(Rect2(360, 140, 880, 620), CREAM, 30, 4)
	center("Options", 225, 52, INK, true)
	for index in range(4):
		label_at(["Keyboard", "Difficulty", "Sound", "Fullscreen"][index], Vector2(430, 313 + index * 82), 25, GREEN)

func _draw_keyboard() -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.12, 0.2, 0.17, 0.65))
	box(Rect2(250, 75, 1100, 750), CREAM, 30, 4)
	center("Keyboard", 160, 48, INK, true)
	center("Click a key to change it.", 204, 21, GREEN)
	for index in range(KEY_ACTIONS.size()):
		label_at(KEY_LABELS[index], Vector2(315 + (0 if index < 5 else 500), 268 + (index % 5) * 70), 22, GREEN)
	if not binding_message.is_empty():
		center(binding_message, 665, 22, RED)

func _draw_spicy_progress(p: Vector2) -> void:
	for index in range(4):
		var point = p + Vector2(index * 45, 0)
		draw_circle(point, 16, GREEN if spicy_clears[index] else Color("ded8bb"))
		if spicy_clears[index]:
			line([point + Vector2(-7, 0), point + Vector2(-2, 5), point + Vector2(7, -5)], CREAM, 3)
		else:
			center(str(index + 1), point.y + 6, 16, GREEN, false, point.x)

func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, 1600, 142), CREAM)
	line([Vector2(0, 141), Vector2(1600, 141)], INK, 3)
	for i in range(max_health):
		heart(Vector2(57 + i * 40, 64), RED if i < health else Color("d8d3b9"), 0.83)
	label_at(difficulty_settings().name, Vector2(42, 117), 13, GREEN)
	center(encounter().boss, 38, 26, INK, true)
	box(Rect2(500, 53, 600, 23), INK, 11)
	var health_color = [RED, Color("629789"), Color("b98768"), Color("b77d46"), Color("b67d42")][current_level - 1] if phase == 1 else [Color("bc4537"), Color("9b638f"), Color("a3546c"), Color("d76a38"), Color("b64c40")][current_level - 1]
	box(Rect2(504, 57, maxf(0, 592 * boss_hp / boss_max_hp), 15), health_color, 7)
	label_at("%.1fs" % fight_time, Vector2(1178, 42), 24, INK, true)
	label_at("ESC  Pause", Vector2(1400, 35), 16, GREEN)
	label_at("H  Help", Vector2(1400, 65), 16, GREEN)
	for i in range(5):
		box(Rect2(1190 + i * 31, 81, 23, 29), Color("dfd9be"), 5, 2)
		var progress = clampf(charge - i, 0, 1)
		if progress > 0:
			box(Rect2(1193 + i * 31, 84 + 23 * (1 - progress), 17, 23 * progress), GOLD, 2)
	label_at(key_name(key_bindings.super) + "  SUPER", Vector2(1360, 103), 18, RED if charge >= MAX_CHARGE else GREEN)
	if charge >= MAX_CHARGE:
		star(Vector2(1550, 95), 10 + sin(elapsed * 8) * 2, GOLD, elapsed)
	if dash_cooldown > 0:
		box(Rect2(player.x - 26, player.y + 18, 52, 6), INK, 3)
		box(Rect2(player.x - 24, player.y + 20, 48 * (1 - dash_cooldown / 0.85), 2), CREAM, 1)

func _draw_intro() -> void:
	var text_value = encounter().boss if intro > 0.9 else "GO!"
	box(Rect2(360, 315, 880, 158), GREEN, 22, 4)
	center(text_value, 413, 50, CREAM, true)

func _draw_pause() -> void:
	draw_rect(Rect2(0, 142, 1600, 726), Color(0.12, 0.2, 0.17, 0.62))
	box(Rect2(500, 210, 600, 430), CREAM, 30, 4)
	center("Paused", 300, 59, INK, true)

func _draw_help() -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.12, 0.2, 0.17, 0.78))
	box(Rect2(320, 110, 960, 700), CREAM, 30, 4)
	center("Controls", 190, 48, INK, true)
	var keys = [[key_name(key_bindings.move_left) + " " + key_name(key_bindings.move_right), key_name(key_bindings.jump) + " / " + key_name(key_bindings.jump_alt), "Hold " + key_name(key_bindings.shoot), key_name(key_bindings.dash), key_name(key_bindings.parry), key_name(key_bindings.super)], [key_name(key_bindings.aim_up) + " " + key_name(key_bindings.aim_down), "ESC", "R", "B", "M", "F11"]]
	var actions = [["Move", "Jump ×2", "Shoot", "Dash", "Parry pink", "Super"], ["Aim", "Pause", "Retry", "Bosses", "Sound: " + ("off" if muted else "on"), "Fullscreen"]]
	for column in range(2):
		var x = 380 + column * 440
		for row in range(6):
			var y = 226 + row * 59
			box(Rect2(x, y, 136, 42), Color("ded8bb"), 10)
			var key_width = body_font.get_string_size(keys[column][row], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			center(keys[column][row], y + 28, mini(18, int(18 * 120 / maxf(120, key_width))), GREEN, false, x + 68)
			label_at(actions[column][row], Vector2(x + 158, y + 28), 22)
	center("Shoot to fill your super cards.", 637, 21, GREEN)
	shield_marker(Vector2(563, 675))
	label_at("Shields block shots. Jump or dash.", Vector2(589, 682), 21, GREEN)

func _draw_result() -> void:
	if result_time < 0.65:
		return
	var won = mode == "win"
	var next_course = won and current_level < ENCOUNTERS.size() and level_available(current_level + 1)
	draw_rect(Rect2(0, 142, 1600, 726), Color(0.12, 0.2, 0.17, 0.6))
	box(Rect2(411, 203, 778, 543), CREAM, 30, 4)
	center(("Kitchen cleared!" if current_level == 5 else "Victory!") if won else "Try again!", 316, 59, INK, true)
	if won and current_level == 4:
		center("Chef unlocked!" if chef_unlocked() else "Chef: win bosses 1–4 on Spicy.", 373, 21, GREEN)
	if won:
		draw_circle(Vector2(800, 484), 69, GREEN)
		center(rank_result(), 513, 79, CREAM, true)
		center("%.1fs · %d hearts" % [fight_time, health], 584, 22)
		if current_level == 4:
			_draw_spicy_progress(Vector2(733, 605))
	else:
		box(Rect2(510, 438, 580, 27), INK, 13)
		box(Rect2(515, 443, maxf(0, 570 * (1 - boss_hp / boss_max_hp)), 17), RED, 8)
		center("%d%% done" % int((1 - boss_hp / boss_max_hp) * 100), 513, 24, GREEN)
	box(Rect2(560, 625, 480, 59), GREEN, 13)
	var action = "ENTER   Next" if next_course else ("ENTER   Bosses" if won and current_level == 4 else "ENTER   Retry")
	center(action, 663, 20, CREAM)
	center("R  Retry     B  Bosses" if next_course else "B  Bosses", 720, 18, GREEN)

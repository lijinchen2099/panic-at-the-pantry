extends SceneTree
## Native-rendered layout fixtures. No changes are written to the player's save.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_physics_process(false)
	var destination = ProjectSettings.globalize_path("res://../build/visual-checks")
	DirAccess.make_dir_recursive_absolute(destination)
	var saved_difficulty = game.difficulty
	var fixtures = ["home", "options", "keyboard", "keyboard-capture", "title-fresh", "title-blender", "title-kettle", "title-skillet", "title-chef-locked", "title-chef-partial", "title-chef-unlocked", "title-help", "paused-help", "regular-title", "regular-toaster", "regular-blender", "regular-kettle", "regular-skillet", "spicy-chef", "chef", "chef-rush", "chef-intro", "chef-win", "chef-defeat", "chef-unlock", "paused-selector", "blender", "blender-turbo", "kettle", "kettle-boiling", "skillet", "skillet-frenzy", "skillet-intro", "skillet-defeat", "armored-attacks", "super-ready", "energy-ball", "next-course", "third-unlocked", "kettle-win", "kitchen-cleared", "blender-defeat", "kettle-defeat"]
	for fixture in fixtures:
		game.difficulty = 1 if fixture.begins_with("regular") else saved_difficulty
		game.spicy_clears.fill(fixture.contains("chef") and fixture not in ["title-chef-locked", "title-chef-partial"])
		if fixture == "title-chef-partial":
			game.spicy_clears.assign([true, false, true, false])
		var third_course = fixture in ["title-kettle", "regular-kettle", "kettle", "kettle-boiling", "kettle-defeat", "kettle-win"]
		var fourth_course = fixture.contains("skillet") or fixture in ["kitchen-cleared", "chef-unlock"]
		var fifth_course = fixture.contains("chef") and fixture != "chef-unlock"
		game.start_fight(5 if fifth_course else (4 if fourth_course else (3 if third_course else (1 if fixture in ["title-fresh", "regular-title", "regular-toaster", "next-course", "armored-attacks"] else 2))))
		game.elapsed = 8.5
		game.intro = 0
		game.result_time = 1
		game.fight_time = 36.4
		game.quip_time = 2
		game.help_open = false
		game.binding_action = ""
		game.binding_message = ""
		game.menu_page = "bosses"
		if fixture in ["home", "options", "keyboard", "keyboard-capture"]:
			game.mode = "title"
			game.menu_page = "keyboard" if fixture.begins_with("keyboard") else fixture
			if fixture == "keyboard-capture":
				game._begin_binding("shoot")
		elif fixture.begins_with("title") or fixture == "regular-title":
			game.mode = "title"
			game.unlocked_level = {"title-fresh": 1, "title-blender": 2, "title-kettle": 3, "title-skillet": 1, "regular-title": 4}.get(fixture, 5 if game.chef_unlocked() else 4)
			game.help_open = fixture == "title-help"
		elif fixture == "paused-help":
			game.mode = "paused"
			game.help_open = true
		elif fixture == "paused-selector":
			game.mode = "paused"
		elif fixture == "blender-turbo":
			game.phase = 2
			game.boss_hp = 170
			game.quip = "TIME TO LOSE MY LID!"
		elif fixture == "kettle-boiling":
			game.phase = 2
			game.boss_hp = 200
			game.quip = "THAT'S MY BOILING POINT!"
		elif fixture == "skillet-frenzy":
			game.phase = 2
			game.boss_hp = 200
			game.quip = "NO MORE MR. FRY GUY!"
		elif fixture == "skillet-intro":
			game.intro = 1.5
		elif fixture == "chef-rush":
			game.phase = 2
			game.boss_hp = 230
			game.quip = "THIS KITCHEN BITES!"
		elif fixture == "chef-intro":
			game.intro = 1.5
		elif fixture in ["next-course", "third-unlocked", "kettle-win", "kitchen-cleared", "chef-win", "chef-unlock"]:
			game.mode = "win"
			game.boss_hp = 0
		elif fixture in ["blender-defeat", "kettle-defeat", "skillet-defeat", "chef-defeat"]:
			game.mode = "lose"
			game.boss_hp = 160
			game.health = 0
		elif fixture in ["super-ready", "energy-ball"]:
			game._add_charge(5)
			if fixture == "energy-ball":
				var event = InputEventKey.new()
				event.physical_keycode = KEY_Q
				event.pressed = true
				game._input(event)
				game.step_fight(0.4)
				game.elapsed = 8.6
		if fixture in ["blender", "blender-turbo"]:
			for pattern in range(3):
				game._spawn_blender_volley(pattern, 2)
			game.hazards[0].p.x = 665
			game.hazards[1].p = Vector2(935, 555)
			game.hazards[2].p = Vector2(842, 522)
			game.hazards[3].p = Vector2(750, 489)
			game.hazards[4].p = Vector2(555, 464)
		if fixture in ["kettle", "kettle-boiling"]:
			for pattern in range(2):
				game._spawn_kettle_volley(pattern, 2)
			game.hazards[0].p = Vector2(635, 510)
			game.hazards[1].p.x = 480
		if fixture in ["skillet", "skillet-frenzy"]:
			for pattern in range(2):
				game._spawn_skillet_volley(pattern, 2)
			game.hazards[0].p = Vector2(665, 674)
			game.hazards[1].p = Vector2(935, 555)
			game.hazards[2].p = Vector2(842, 522)
			game.hazards[3].p = Vector2(750, 489)
		if fixture == "armored-attacks":
			game._spawn_volley(2, 2)
			game.hazards[0].p = Vector2(700, 721)
			game.warning = game.encounter().warnings[2]
			game.warning_time = 0.8
		if fixture in ["chef", "chef-rush"]:
			for pattern in range(3):
				game._spawn_chef_volley(pattern, 2)
			game.hazards[0].p = Vector2(685, 678)
			game.hazards[1].p = Vector2(790, 460)
			game.hazards[2].p = Vector2(930, 548)
		game._sync_boss_selector()
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var result = root.get_texture().get_image().save_png(destination.path_join(fixture + ".png"))
		if result != OK:
			push_error("Could not save fixture: " + fixture)
			quit(1)
			return
	print("VISUAL CHECK: rendered %d fixtures to %s" % [fixtures.size(), destination])
	game.free()
	await create_timer(0.1).timeout
	quit()

# Panic at the Pantry

An original native macOS cartoon boss adventure, made for Leo. Play Sunny, an egg
with a chef's beret and a finger gun, through five complete kitchen boss encounters.
Each course has its own setting and a faster second phase. The toaster has four
attack patterns; the blender has three, and the teapot and skillet each have two. The final Chef
has three patterns and unlocks after four Spicy victories.

## Play

Double-click **`build/Panic at the Pantry.app`**, or double-click **`Play.command`**.
The main menu has **Start Game**, **Options**, and **Quit Game**. Start Game opens
boss selection. Choose a boss by clicking its button, pressing **1 / 2 / 3 / 4 / 5**,
or using the **left / right arrows**. Press **Enter** or click **Play** to fight.
Options contains saved keyboard bindings, difficulty, sound, and fullscreen settings.
Click a key in **Options → Keyboard**, then press its replacement. Occupied keys swap;
**Reset Keys** restores defaults. Menu shortcuts stay fixed. Press **H** for optional
controls help; opening help during combat pauses the fight. Press **F11** for fullscreen. No account, internet
connection, or additional runtime is needed to play the built app.

**Course 1 — A Crumby Situation:** fight Baron von Toast in the breakfast kitchen.
Defeat him, then press **Enter** on the victory screen to start Course 2 with fresh
hearts. **R** replays the current course instead.

**Course 2 — A Smoothie Criminal:** fight **Duke de Blend**, a crowned blender with
a completely unnecessary moustache, at The Daily Blend smoothie bar. Dodge returning
banana boomerangs at standing height, smoothie fans, and bouncing berries.
Shielded bananas cannot be destroyed; jump or dash past them. The Duke switches
to **TURBO** at half health. Smoothie and berries can be shot, and pink ones
can be parried.

**Course 3 — A Storm in a Teacup:** defeat **Madame Whistle**, a teapot diva with a
flowered bonnet and a teaspoon baton, in The Steep End tea room. She lobs arcing
tea splashes and fires wobbling biscuits. Pink tea and
biscuits can be parried. At half health she reaches **BOILING POINT** and speeds up.

**Course 4 — Pan-demonium:** face **Sir Sizzle**, a moustached frying-pan chef
with a short fuse, at The Sizzle Reel diner. He flips wobbling pancakes and fires
aimed oil fans. Both attacks can be shot, and pink ones can be parried. At half health he
turns red hot and enters **FRYING FRENZY**. Press **Enter** after Madame Whistle
to advance with fresh hearts, or select **4** directly from the title screen.

**Course 5 — The Final Whisk:** challenge **Chef Pepperpot**, the human head chef,
at The Head Table. Dodge hopping ravioli, arcing secret
sauce, and whisks in alternating lanes. Ravioli and sauce can be shot, and pink
ones can be parried. Whisks are shielded. At half health the
Chef enters **DINNER RUSH** with faster attacks.

**Unlock rule:** defeat each of bosses **1, 2, 3, and 4 on Spicy**. Victories count
in any order and across sessions. Cozy and Regular wins do not count, and
repeating one boss cannot replace another. The Chef preview and fourth-boss victory
screen show four saved progress markers. You can preview the Chef while locked, but
starting the fight is blocked through buttons, number keys, retries, and level
transitions. After unlocking, press **5**, then **Enter**, or advance after
Sir Sizzle. **The Chef is Spicy only:** three hearts, 1,728 boss health, and Spicy
attack speeds and timing. His difficulty control is fixed, and every entry or
retry automatically uses Spicy. Your preferred difficulty for bosses 1–4 is
preserved when selecting the Chef.

Earlier builds saved best times without their difficulty, so those records are
preserved but cannot establish past Spicy victories. Explicit Spicy-win tracking
starts with this version.

Defeat Duke de Blend, then press **Enter** to start Course 3 with fresh hearts.
Bosses 1–4 are available immediately; the Chef requires the Spicy checklist.
Press **B** during a fight, pause, or result screen to choose a different boss.
Your chosen boss, difficulty, campaign progress, and separate best times persist
between sessions. Existing records are preserved when upgrading.

The following are the default gameplay keys; customize them in Options.

| Action | Keyboard |
| --- | --- |
| Move | Left / right arrows |
| Jump / double jump (hold for height) | Space or Z; press again in midair for a second jump |
| Shoot continuously | Hold F |
| Aim diagonally up / down | Hold up / down arrow while shooting |
| Dash through danger | D |
| Parry nearby pink food | G |
| Energy ball (five full cards) | Q |
| Pause / resume | Esc |
| Controls help | H or F1; Esc closes help |
| Restart encounter | R |
| Fullscreen / window | F11 (Fn + F11 on some Mac keyboards) |
| Toggle all sound | M |
| Cycle Cozy / Regular / Spicy | Options → Difficulty; C also works on menu screens |
| Select boss / preview locked Chef | 1 / 2 / 3 / 4 / 5, number pad, left / right arrows, or click on title screen |
| Choose another boss | B; also Backspace while paused or Esc after a result |

Sunny can jump once more in midair by pressing **Space** or **Z** again.
Landing restores the second jump. Holding a jump key controls height and does
not automatically spend the second jump. Dashing and parrying preserve the
remaining air jump; a third jump requires landing first.

Ordinary food attacks can be destroyed by bullets. **A blue outline and shield
icon mark indestructible attacks:** the toaster's crumb waves, the blender's
bananas, and the Chef's whisks. Bullets spark against
them; the energy ball passes through them without destroying them. Jump over
these low attacks or dash through them with **D**. Short warnings and shield icons
mark these attacks; the full rule is in Help. Dashing makes Sunny briefly invulnerable.
Pink marmalade and pink breakfast balls can be parried to bounce upward and
charge the super meter. Every bullet fired charges the meter, even if it misses;
50 shots fill all five cards. The cards fill gradually; a chime sounds and the
**SUPER** prompt lights up when ready, showing your current key. Press **Q** to launch a large energy ball in Sunny's
facing direction. It blasts through ordinary food, passes shielded attacks, and
deals **120 damage on boss impact**.
It can miss, and each cast consumes the full meter. All bosses get faster
at half health. Once a boss is below 50% health, Sunny's bullets and super deal
half damage: 0.95 per bullet and 60 per energy ball. At exactly 50%, damage is still normal.
Bosses 1–4 support three difficulty levels. The Chef always uses Spicy:

| Difficulty | Hearts | Boss health | Attacks and reaction time |
| --- | --- | --- | --- |
| Cozy | 5 | Original health | Slower attacks, longer warnings and hit protection |
| Regular | 4 | 15% more | One extra volley per attack, faster projectiles, less downtime |
| Spicy | 3 | 35% more | Two extra volleys per attack, fastest projectiles, shortest warnings and downtime |

Regular projectiles are 10% faster than in the previous Regular build, with
10% shorter gaps between volleys. Spicy projectiles are 20% faster than before,
with 25% shorter gaps between volleys. These changes apply to all bosses and both
phases. The banana lanes stay close to the ground, and ice attacks remain removed.

New profiles default to Regular. Your existing Cozy or Spicy selection is
preserved when upgrading. Use **Options → Difficulty** to change difficulty;
it carries through the campaign and remains selected on retry.
The game pauses automatically when it loses focus.

Includes original vector characters and kitchen artwork, a generated swing
soundtrack, cartoon sound effects, hit particles, attack warnings, ranks, and
best-time records for each course. All interactions are available from the keyboard.

## Graphics and technology

Godot **4.7.2 stable**, native **Metal** rendering, a 1600 × 900 design canvas,
HiDPI support, antialiased vector graphics, and 120 Hz gameplay simulation.
The artwork scales with the window and fullscreen display. The built app uses a
universal binary supporting Apple Silicon and Intel; this build was tested on
the user's M4 Mac. Intel hardware has not been tested.

Read `docs/TECHNOLOGY.md` for the engine comparison, installed tools, and sources.
This prototype is packaged for local play with an ad-hoc signature. A public
release would need distribution testing and Apple Developer signing/notarization.

## Edit and build

Double-click **`Edit Game.command`** to open the project in the bundled editor.
The complete editable project is in `game/`. The editor is installed inside
`.tools/Godot.app`; it is self-contained. The verified macOS export template is
installed in Godot's standard application-support directory.

Double-click **`Build Game.command`** to rebuild the standalone app after edits.

Main files:

- `game/scripts/main.gd`: input, fixed-step combat, menu, HUD, and effects.
- `game/scripts/art.gd`: original vector characters and kitchen illustration.
- `game/project.godot`: display, graphics, audio, and project settings.
- `tools/make_audio.py`: reproducible original music and sound generation (NumPy).
- `game/tests/combat_test.gd`: movement, controls, bullet collisions, and combat checks.
- `game/tests/levels_test.gd`: the first two bosses, course progression, and records.
- `game/tests/super_test.gd`: charge from firing, energy-ball flight, impacts, and damage.
- `game/tests/third_test.gd`: the teapot, third-course progression, attacks, and save migration.
- `game/tests/difficulty_test.gd`: health scaling, attack speeds and cadence, all modes, and old-save migration.
- `game/tests/selection_test.gd`: direct boss selection, real mouse clicks, keyboard controls, and persistence.
- `game/tests/fourth_test.gd`: Sir Sizzle, attack patterns, progression, and save compatibility.
- `game/tests/armor_test.gd`: indestructible attacks, bullet blocking, super behavior, and dodging.
- `game/tests/chef_test.gd`: Spicy-only unlock, partial progress, saved records, entry restrictions, and the Chef fight.
- `game/tests/jump_test.gd`: double jumps, landing, variable height, and dash/parry interactions.
- `game/tests/options_test.gd`: main menu, saved keyboard settings, remapped combat, and clean quitting.

Run the gameplay checks from this folder:

```sh
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/combat_test.gd -- --self-test
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/levels_test.gd -- --self-test
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/super_test.gd -- --self-test
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/third_test.gd -- --self-test
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/difficulty_test.gd -- --self-test
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/selection_test.gd -- --self-test
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/fourth_test.gd -- --self-test
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/armor_test.gd -- --self-test
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/chef_test.gd -- --self-test
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/jump_test.gd -- --self-test
.tools/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy \
  --path game --script res://tests/options_test.gd -- --self-test
```

Settings and records are stored locally in
`~/Library/Application Support/Godot/app_userdata/Panic at the Pantry/pantry.cfg`.
Self-tests do not write settings or records.

## Credits

Game, characters, vector art, music, and effects were created for this project.
The game draws inspiration from classic cartoon run-and-gun boss battles.
It uses original characters and assets.

Made with [Godot Engine](https://godotengine.org), available under the
[MIT license](https://godotengine.org/license/). System fonts are resolved from
macOS and are not bundled. See `docs/GODOT-LICENSE.txt` for the engine license.

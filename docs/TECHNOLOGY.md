# Technology investigation — 29 October 2026

## Recommendation

Use **Godot 4.7.2 stable with GDScript and native Metal rendering** for this game.
The user selected a 2D cartoon boss fight, a kitchen theme, sharp graphics, and
fullscreen play. A dedicated 3D modeling pipeline is optional for later work.

The current Mac is a **Mac mini with Apple M4, 10 CPU cores, 10 GPU cores, 16 GB
unified memory, and macOS 26.5.2**. Godot launches natively on this machine.
Metal rendering was verified in the running game. The workspace initially had
no game engine, Homebrew, Blender, or active Xcode developer tools.

| Option | Current evidence | Fit for this project |
| --- | --- | --- |
| Godot | Official macOS download lists 4.7.2, supports Apple Silicon and Intel, and is self-contained. MIT licensed. | Selected: dedicated 2D tools, scriptable animation, native export, and no account or subscription needed. |
| Unity | Unity Personal supports game development; its current eligibility limit is less than US$200,000 annual revenue/funding. | Capable alternative, especially for a larger C# team. Its extra setup is unnecessary for this prototype. |
| Unreal Engine | Epic recommends 32 GB or more on macOS and lists 16 GB as the minimum. Its development workflow requires a compatible Xcode version. | Strong 3D option; the minimum-memory configuration and added setup make it a less practical starting point here. |
| Blender | Blender 5.0+ supports Apple Silicon on macOS 13 or later; Blender 5.2 is an LTS release. | Useful later for modeled backgrounds or 3D characters. This 2D build creates all artwork in code, so Blender was not required or installed. |

These are implementation judgments based on the selected scope, not measured
benchmarks between engines. High visual quality depends on art and animation
work as well as the engine.

## Installed and verified

- Official Godot **4.7.2 stable**, universal macOS editor, in `.tools/Godot.app`.
- Matching official macOS export template in
  `~/Library/Application Support/Godot/export_templates/4.7.2.stable/macos.zip`.
- The editor and full downloaded template archive were verified with the
  publisher's SHA-512 checksums. Download metadata and checksums are in `.tools/`.
- A standalone universal Mac app is produced in `build/`.
- No paid software, external asset packs, 3D utilities, or Xcode installation
  was needed for this local prototype. The existing bundled Python/NumPy
  runtime generated original audio.

Only the Mac template was extracted from the cross-platform template archive.
The larger downloaded archive is retained in `.tools/` for reproducibility.

## Implementation

The game has a 1600 × 900 reference canvas with HiDPI and proportional fullscreen
scaling. Artwork uses native vectors so its edges stay crisp at larger sizes.
Gameplay uses a fixed 120 Hz simulation. The project renders through Godot's
Mobile renderer with Apple's Metal driver; this renderer name also covers
desktop applications. Music and effects are local WAV resources.

The current build includes five complete boss courses. Baron von Toast fights in
the breakfast kitchen; Duke de Blend fights in a smoothie bar; Madame Whistle
fights in a separate tea-room setting. Sir Sizzle is a cast-iron frying-pan chef
at The Sizzle Reel diner, with flipping pancakes and aimed oil fans.
Chef Pepperpot, the human head chef, fights at The Head Table with
hopping ravioli, ballistic sauce, and whisks. The Chef has 1,728 health on his
mandatory Spicy setting. All bosses have a
faster second phase.
The toaster has four attack patterns. The blender has returning bananas,
smoothie fans, and bouncing berries. The teapot uses aimed ballistic tea arcs
and biscuits with sinusoidal motion. Projectile
prediction and movement share the same velocity calculation for accurate hits.
Ordinary food is shootable, while crumb waves, bananas, and whisks
survive bullets and supers. These attacks carry a blue outline and shield badge,
and their warnings tell the player to jump or dash. Bullets resolve the nearest
shield impact with sparks. Supers pass shields without removing them, retaining
their damage against the boss. Shared features include three
difficulty settings (Cozy, Regular, and Spicy), double jumping, jump height control, buffered jumps, coyote time,
invulnerable dashes, pink parries, a super meter filled by firing, a physical
energy-ball super with swept collision, pause/restart, and
victory and defeat results. Bosses 1–4 are directly available from the title
screen through real clickable controls, number keys, or arrow keys; B returns
to that selector during play. Level five requires explicit Spicy victory flags
for each of bosses 1–4. Those flags are saved separately from times, earned using
the fight's starting difficulty, and checked at the central fight entry point.
Older records do not infer difficulty; partial unlock progress persists across
sessions. The locked Chef can be previewed, with an on-screen checklist and a
disabled start button. The Chef's effective difficulty is always Spicy, including
direct entry, advancement, retries, and replays. His difficulty control is fixed;
the saved preference for bosses 1–4 remains separate. Individual records and campaign progress persist,
with automatic migration of wins saved by the earlier one- and two-course
versions. Regular adds 15% boss health, one extra volley per attack, and faster
projectiles and attack cadence. Spicy adds 35% boss health and two extra volleys,
with further increases in speed and frequency. Both phases use these settings.

The built app uses Godot's built-in ad-hoc signing. Broader distribution would
need compatibility testing and an Apple Developer signing/notarization workflow.
Intel hardware has not been performance-tested.

## Rendering optimization — 31 October 2026

The original tea-room wallpaper regenerated hundreds of 49-vertex ellipse
polygons inside the full-scene draw call every frame. A local 4K stress test
measured 8.7 fps before optimization. The update:

- Renders scenery into one reusable SubViewport at the exact output resolution,
  with the existing 4× MSAA, then disables updates until the boss or pixel size changes.
- Uses native ellipse primitives for characters and scenery instead of rebuilding
  polygon points and triangulating each ellipse in GDScript.
- Reuses rounded-panel styles instead of allocating them on every draw.
- Requests redraws per rendered frame while retaining the 120 Hz gameplay simulation.

The native render-cache test compares every pixel of all five cached 4K
backgrounds with direct vector rendering, and checks boss changes, resizing,
one-shot rendering, and reuse of a single render target. The performance test
renders all five bosses in both phases and with 450 particles into a verified
3840 × 2160 target. V-sync is disabled for measurement; each profile has a
1.25-second warm-up followed by four seconds of samples. Passing requires
at least 60 fps on average and a 95th-percentile frame time no greater than
16.67 ms. Benchmark artifacts are saved under `build/`.

The test machine is Apple M4, 10 GPU cores, 16 GB unified memory, running
macOS 27.2. Its connected monitor is 1920 × 1080 at 120 Hz. The benchmark uses
real 4K GPU render targets and a scaled preview; physical 4K display presentation
and other hardware are outside this measurement.

Measured results: all 15 profiles passed, with averages of **120.1–285.4 fps**.
The worst 95th-percentile frame time was **8.806 ms** and the worst 99th-percentile
frame time was **12.272 ms**. The 450-particle stress profiles averaged at least
120.1 fps. The tea-room stress profile improved from 8.7 to 161.4 fps.
The original and optimized stress samples used two and four seconds respectively,
so these figures describe these local runs rather than a hardware-wide guarantee.

## Primary sources

Checked during implementation:

- [Godot's current macOS release and installation instructions](https://godotengine.org/download/macos/)
- [Godot Engine license](https://godotengine.org/license/)
- [Godot system requirements](https://docs.godotengine.org/en/stable/about/system_requirements.html)
- [Godot macOS export, signing, and notarization](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html)
- [Official Godot 4.7.2 release assets and checksums](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)
- [Unity Personal eligibility and capabilities](https://unity.com/products/unity-personal)
- [Unreal Engine macOS requirements](https://dev.epicgames.com/documentation/en-us/unreal-engine/macos-development-requirements-for-unreal-engine)
- [Blender hardware and macOS requirements](https://www.blender.org/download/requirements/)
- [Blender 5.2 LTS](https://www.blender.org/releases/5-2/)

# Testing

## Target, aiming and Instinct update
The workflow exercises the physical primary target and witness, legacy saves, mouse aim/fire input, centre-ray impact and wall obstruction, hold/release Instinct, target discovery and item proximity in both missions, and cinematic grounding/scene content. Read the Actions result for the exact commit: scripted runtime checks are not a human playthrough or visual-quality signoff. Windows export, physical mouse feel, colour accessibility, real audio review and target laptop performance remain unverified.

## Current gameplay update

[Actions run 43702084074](https://github.com/CoolgamerProXD/Stealty-Assasin-redesigned-computing-machine-Beta/actions/runs/43702084074), commit `0c1ee7b5605f48edb7a6c64fce2e6b1515a746d2`, passed official Godot 4.4.1 import and startup, six Python data checks, **110/110** headless behavioral checks and **11/11** scripted virtual-display camera/scene checks. The headless suite sends synthetic input for equipment, witness and cinematic skip; it also samples the cinematic timeline directly. It checks migration of completed legacy Meridian saves, replay and equipment persistence through an isolated file. An earlier run failed because synthetic input assertions sampled too early; waiting through a physics frame fixed the test timing, and the reruns passed. No human or Windows playtest was performed.

The workflow includes synthetic input events for equipment and witness interaction, mission objective/legacy save checks, both mission HUDs, a skippable Ruby scene and scripted virtual-display scene checks. Results are only established by a successful run on the commit under test; direct timeline sampling and synthetic input are not a manual playthrough. Real audio quality, visual composition, asset quality, both full player routes, Windows export and target-device performance require human verification. Prior results below describe older commits.

## Campaign expansion verification scope

[Actions run 43700503344](https://github.com/CoolgamerProXD/Stealty-Assasin-redesigned-computing-machine-Beta/actions/runs/43700503344) on `a6c6ca95aa9de847ee47ed152ff3e9660e96d3a4` passed: six Python data checks, official 4.4.1 headless import and menu startup, 87/87 Godot behavioral assertions, and 5/5 scripted Xvfb camera checks. The headless tests include a standing-clearance obstruction and isolated campaign scene/debrief transition. Run 43700434097 failed one guard movement assertion because it began measuring after the guard arrived; the test was changed to measure from the initial route position and rerun. These are automated checks, not manual playtesting.

The Godot 4.4.1 workflow runs the existing Meridian regression suite and added checks for campaign order/restore, equipment metadata restrictions, Initiation's two NPCs and one moving guard, objective gating, checkpoint restoration, crouch, and campaign scene transitions/pause/debrief. See the Actions run for exact results for the commit being evaluated; earlier runs below describe earlier commits. Direct calls to interaction handlers and scene transitions are automated functional checks, not a human playthrough. GUI usability, full routes, overhead-clearance edge cases, AI escalation and blocked paths, Windows export/content packaging, real audio and target-device performance still require further work and manual verification. Isolated campaign saves in the integration test are deleted after use.

## Automated

With Godot 4.4.1 installed, from the repository root:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/run_tests.gd
```

The first command imports resources and registers global script classes. The second must exit 0 and print the check/failure totals. It exercises access, inventory, objective uniqueness and extraction, memory expiry, versioned/corrupt saves and backup recovery, snapshot restoration, FOV decisions, NPC reaction/recovery, disguise permissions, physics input, navigation detours, actual ray occlusion and the world's interaction path. It is not a substitute for an interactive graphics/navigation playtest. Save tests use uniquely named `user://assassin_test_*.json` files and remove them and their `.bak`/`.tmp` files; they do not touch the playable save.

## Historical results before runtime verification

This sandbox initially had no Godot, Blender, .NET or Windows installation. Git 2.39.5, Python 3.11.2, GCC, npm and curl are present; 20 GiB was available at initial inspection. A Godot 4.4.1 binary download was blocked at the release-asset host. A source build was attempted separately outside the repository, initially stopped before completion, and restarted during the continuation. A background process is configured to run the headless import and behavioral tests if compilation succeeds; no result was available at this checkpoint. `gdtoolkit`'s `gdparse` successfully parsed all GDScript files; this is syntax parsing only, not Godot type checking or runtime validation. Five Python data checks passed (`python3 -m unittest discover -s tests -p "test_*.py" -v`): identity uniqueness, schedule schema, coordinates within the declared navmesh, partition clearance and entry-scene references. These checks do not execute gameplay. At that earlier checkpoint, headless Godot tests and graphical playtesting had not been run.

## Manual scenario (not yet executed)

Run the project in the editor. Confirm movement, mouse capture, collisions and camera; observe NPC schedule movement; visit staff space as a visitor while in an NPC's view and observe suspicion/investigation/recovery; equip the uniform and confirm staff access, then test secure access; inspect two different gold records and extract at the green marker. Repeat with different records. Verify that walls occlude vision and that exiting without two records is rejected. Record reproducible failures and hardware details. Try both openings in each partition, save using F5, alter the mission, and load with F9. Confirm a blocked view and an unobstructed view separately.

## Historical audit session — 2026-11-15

- `python3 -m unittest discover -s tests -p 'test_*.py' -v`: six tests passed. These validate authored data and references, not GDScript behavior or physics.
- `PYTHONPATH=/tmp/assassin-tools/gdtoolkit /tmp/assassin-tools/gdtoolkit/bin/gdparse <file>` for every GDScript file: syntax parsing passed. This is not Godot's parser/type checker.
- `gdcorrect validate-project . --format pretty --fail-on none`, `gdcorrect validate-scenes . --format pretty --fail-on none`, and `gdcorrect lint . --format pretty --fail-on none`: each reported zero findings. This external offline static checker does not execute Godot or prove runtime correctness.
- The updated headless test runner includes missing/invalid mission configuration, actual configured spawning, unique collection, inventory-full behavior, 3-of-3 display versus required two, repeat extraction, movement speeds and collision, sight/routing, F5/F9 event handlers, backup/version checks, and snapshot consistency. **At that earlier audit checkpoint, these tests had not yet been run in Godot.** The previous source build is still running outside the repository. The standard Linux binary download was blocked; the target Windows executable and laptop are not accessible here.

Before exporting, verify both JSON configuration files are included in the export and test the Windows build; no export preset or Windows export has yet been validated.

## Godot runtime regression — 2026-11-15

[GitHub Actions run 43699069502](https://github.com/CoolgamerProXD/Stealty-Assasin-redesigned-computing-machine-Beta/actions/runs/43699069502), commit `af7972243780b908b18462703d27973cc42ace0d`, succeeded using the official SHA-512-verified **4.4.1.stable.official.49a5bc7b6** Linux binary. The runner used Ubuntu, 4 reported CPUs, approximately 15.6 GiB RAM and Mesa llvmpipe under Xvfb; it is not the Windows laptop. The local source build remained incomplete.

Commands executed by `.github/workflows/godot-regression.yml` (with `GODOT` set to the downloaded official binary):

```sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
"$GODOT" --headless --editor --path . --quit
/usr/bin/time timeout 90 "$GODOT" --headless --path . --quit-after 120
timeout 120 "$GODOT" --headless --path . --script res://tests/run_tests.gd
xvfb-run -a --server-args="-screen 0 1280x720x24" /usr/bin/time timeout 120 "$GODOT" --audio-driver Dummy --rendering-method gl_compatibility --path . --script res://tests/camera_display_test.gd
```

Results: data **6/6**, main-scene import/startup **passed**, behavioral **63/63**, synthetic camera/display **5/5**. Checks cover 3 spawned records and 2 required, unique/unknown/full inventory conditions, HUD and extraction, movement, collision, perception and routine return, permissions, and F5/F9 plus corrupt/backup/version and snapshot paths. The Xvfb checks exercise capture, yaw/pitch, clamp, release and spring-arm wall collision with synthetic events. These are automated runtime tests, not a human interactive playtest or Windows validation.

The initial Godot run reported **61/61 assertions passed** but failed CI because corrupt JSON intentionally caused `JSON.parse_string()` to emit engine errors. The isolated save-reader change uses `JSON.new().parse()` so malformed saves still trigger fallback without error-log spam; the following runs passed the strict error-log gate. The runner warned about software-display VSync support and checkout action Node version; neither is a game error.

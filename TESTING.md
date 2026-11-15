# Testing

## Automated

With Godot 4.4.1 installed, from the repository root:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/run_tests.gd
```

The first command imports resources and registers global script classes. The second must exit 0 and print the check/failure totals. It exercises access, inventory, objective uniqueness and extraction, memory expiry, versioned/corrupt saves and backup recovery, snapshot restoration, FOV decisions, NPC reaction/recovery, disguise permissions, physics input, navigation detours, actual ray occlusion and the world's interaction path. It is not a substitute for an interactive graphics/navigation playtest. Save tests use uniquely named `user://assassin_test_*.json` files and remove them and their `.bak`/`.tmp` files; they do not touch the playable save.

## Session results

This sandbox initially had no Godot, Blender, .NET or Windows installation. Git 2.39.5, Python 3.11.2, GCC, npm and curl are present; 20 GiB was available at initial inspection. A Godot 4.4.1 binary download was blocked at the release-asset host. A source build was attempted separately outside the repository, initially stopped before completion, and restarted during the continuation. A background process is configured to run the headless import and behavioral tests if compilation succeeds; no result was available at this checkpoint. `gdtoolkit`'s `gdparse` successfully parsed all GDScript files; this is syntax parsing only, not Godot type checking or runtime validation. Five Python data checks passed (`python3 -m unittest discover -s tests -p "test_*.py" -v`): identity uniqueness, schedule schema, coordinates within the declared navmesh, partition clearance and entry-scene references. These checks do not execute gameplay. Headless Godot tests and graphical playtesting have not been run.

## Manual scenario (not yet executed)

Run the project in the editor. Confirm movement, mouse capture, collisions and camera; observe NPC schedule movement; visit staff space as a visitor while in an NPC's view and observe suspicion/investigation/recovery; equip the uniform and confirm staff access, then test secure access; inspect two different gold records and extract at the green marker. Repeat with different records. Verify that walls occlude vision and that exiting without two records is rejected. Record reproducible failures and hardware details. Try both openings in each partition, save using F5, alter the mission, and load with F9. Confirm a blocked view and an unobstructed view separately.

## Audit session — 2026-11-15

- `python3 -m unittest discover -s tests -p 'test_*.py' -v`: six tests passed. These validate authored data and references, not GDScript behavior or physics.
- `PYTHONPATH=/tmp/assassin-tools/gdtoolkit /tmp/assassin-tools/gdtoolkit/bin/gdparse <file>` for every GDScript file: syntax parsing passed. This is not Godot's parser/type checker.
- `gdcorrect validate-project . --format pretty --fail-on none`, `gdcorrect validate-scenes . --format pretty --fail-on none`, and `gdcorrect lint . --format pretty --fail-on none`: each reported zero findings. This external offline static checker does not execute Godot or prove runtime correctness.
- The updated headless test runner includes missing/invalid mission configuration, actual configured spawning, unique collection, inventory-full behavior, 3-of-3 display versus required two, repeat extraction, movement speeds and collision, sight/routing, F5/F9 event handlers, backup/version checks, and snapshot consistency. **These tests have not been run in Godot at this checkpoint.** The previous source build is still running outside the repository. The standard Linux binary download was blocked; the target Windows executable and laptop are not accessible here.

Before exporting, verify both JSON configuration files are included in the export and test the Windows build; no export preset or Windows export has yet been validated.

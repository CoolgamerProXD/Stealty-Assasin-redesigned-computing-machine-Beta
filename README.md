# PROJECT ASSASSIN

An offline Godot 4.4.1 stealth-sandbox prototype. BLACKLINE is the player's employer; Ruby is the handler and the Covenant is a separate organization. The playable campaign contains **01 Initiation** and **02 The Meridian**. Later assignments are not playable.

## Play

Open `project.godot` in Godot 4.4.1 and press F5. Choose Campaign or a mission from Mission Selection. Ruby's briefing identifies the target; the mission HUD tracks the target, evidence, awareness, equipment and interaction prompts.

- **Initiation:** disable the moving assessment unit (E nearby or a training pulse within range), collect all three records and reach the exit. Two guards patrol. Completion unlocks Meridian and Quiet Line, then starts the skippable Ruby meeting.
- **The Meridian:** question records employee **Ivo Chen**, collect any two of the three records and reach the exit. The uniform grants staff access, not secure access. Ivo is an existing hotel employee and witness to the missing archive, not a new assassin target.
- **Equipment:** the unsuppressed training sidearm has five fictional pulses; Q uses one, alerts nearby NPCs and disables the assessment unit if it is within range and unobstructed. After Initiation, choose Quiet Line in Loadout before deploying to Meridian. Press 1 or 2 to equip; Q with Quiet Line temporarily incapacitates a nearby unobstructed NPC without graphic effects. There is no projectile aiming or real-world weapon simulation. Quiet Line is not permitted in Initiation; the sidearm is always issued.
- WASD moves, mouse looks, Shift runs, C crouches, E interacts, F5 saves, F9 loads and Escape pauses. The Ruby scene can be skipped with Escape or its button.

Campaign and settings have separate versioned saves. Meridian retains `user://meridian_save.json`; Initiation uses `user://initiation_save.json`. Checkpoints retain player position, role, records, target completion, equipped items and remaining charges. NPCs' schedules, suspicions and temporary incapacitation are transient. An already-extracted legacy Meridian save is recognized as complete; a legacy in-progress save must meet the new witness objective.

## Status

This is still a prototype, **not a finished visual overhaul**. The characters are original articulated low-poly figures with simple procedural limb motion, not textured, skinned production models or full animation sets. Environments remain primitive greyboxes despite added trim and ceilings. The Ruby scene uses an in-engine moving camera, doors and characters, subtitles and synthesized tones, not voice acting or polished authored animation. No third-party assets have been imported; see [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md).

No human interactive playtest, Windows export verification or target Iris Xe benchmark has been performed. Equipment, visibility and pacing need a hands-on playtest; full NPC escalation and blocked-path recovery remain unfinished. See [TESTING.md](TESTING.md), [AUDIT.md](AUDIT.md), and [PERFORMANCE.md](PERFORMANCE.md).

# PROJECT ASSASSIN

An offline Godot 4.4.1 stealth-sandbox prototype. BLACKLINE is the player's employer; Ruby is the handler and the Covenant is a separate organization. The playable campaign contains **01 Initiation** and **02 The Meridian**. Later assignments are not playable.

## Play

Open `project.godot` in Godot 4.4.1 and press F5. Choose Campaign or a mission from Mission Selection. Ruby's briefing identifies the target; the mission HUD tracks the target, evidence, awareness, equipment and interaction prompts.

- **Initiation:** disable the moving assessment unit (E nearby or a well-aimed training pulse), collect all three records and reach the exit. Two guards patrol. Completion unlocks Meridian and Quiet Line, then starts the skippable Ruby meeting.
- **The Meridian:** confront or tag primary target **Adrian Locke**, the operations director who authorized the archive transfer. Question records employee **Ivo Chen** as a separate witness, collect any two of the three records and reach the exit. The uniform grants staff access, not secure access.
- **Equipment:** press 1 for the unsuppressed, five-charge fictional training sidearm. Hold **right mouse** to aim, then press **left mouse** to fire an instantaneous pulse along the centre crosshair. It is blocked by walls, disables the unit and temporarily incapacitates people; nearby NPCs react to the noise. After Initiation, choose Quiet Line in Loadout before deploying to Meridian. Press 2 to equip it and Q to temporarily incapacitate a nearby unobstructed NPC. Quiet Line is not permitted in Initiation; the sidearm is always issued. A successful pulse on Locke completes the primary target objective; Quiet Line only incapacitates him temporarily.
- Hold **left Ctrl** for Instinct: the briefing-identified primary target appears as a red character silhouette through solid geometry; nearby visible, unobstructed intel and the uniform appear yellow (default range four metres). Ordinary NPCs and undiscovered items are not revealed. WASD moves, mouse looks, Shift runs, C crouches, E interacts, F5 saves, F9 loads and Escape pauses. The Ruby scene can be skipped with Escape or its button.

Settings offer persisted LOW, MEDIUM and HIGH rendering scales (70%, 85%, 100%), shadow toggles/atlas sizes, HIGH 2× MSAA, and a persisted FPS-counter toggle. These are modest prototype presets: reflections and scene detail do not yet scale.

Campaign and settings have separate versioned saves. Meridian retains `user://meridian_save.json`; Initiation uses `user://initiation_save.json`. Checkpoints retain player position, role, records, target completion, equipped items and remaining charges. Target identification and completion persist. NPC schedules, suspicion and temporary incapacitation are transient. Already-extracted legacy Meridian saves remain complete; in-progress saves must meet the current primary-target and witness objectives.

## Status

This is still a prototype, **not a finished visual overhaul**. The characters are original articulated low-poly figures with simple procedural limb motion, not textured, skinned production models or full animation sets. Environments remain primitive greyboxes despite added trim and ceilings. The Ruby scene has an original low-poly exterior, sky, opening doors, characters, subtitles and synthesized tones, not voice acting or polished authored animation. No third-party assets have been imported; see [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md).

No human interactive playtest, Windows export verification or target Iris Xe benchmark has been performed. Aim feel, visual quality, cinematic composition and full routes need hands-on testing; full NPC escalation and blocked-path recovery remain unfinished. See [TESTING.md](TESTING.md), [AUDIT.md](AUDIT.md), and [PERFORMANCE.md](PERFORMANCE.md).

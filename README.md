# PROJECT ASSASSIN

An original, offline Godot 4 stealth-sandbox **prototype**. BLACKLINE is the player's intelligence employer; Ruby is the handler. The Covenant is a separate, mysterious organization. The playable campaign foundation contains **01 Initiation** and **02 The Meridian**; later assignments are classified, not playable.

## Run

1. Open `project.godot` in Godot **4.4.1** and press F5, or run `godot --path .`.
2. From Campaign or Mission Selection, deploy to Initiation. Collect all three gold records and disable the moving blue assessment unit, then use the green exit. Two guards follow routes. Completion unlocks Meridian and the Quiet Line loadout entry.
3. In Meridian, collect any two of three records and return to the exit. The blue marker supplies a staff disguise; secure space remains restricted.
4. WASD moves, mouse looks, Shift runs, C crouches, E interacts, F5 saves, F9 loads, and Escape opens pause (resume, save, load, settings, or return to menu). Bindings are in Project Settings → Input Map.

Campaign and settings use separate versioned saves. Meridian retains its original `user://meridian_save.json`; Initiation uses `user://initiation_save.json`. Existing Meridian saves are not erased or automatically treated as campaign completion. Use Continue to load the last mission's checkpoint or choose a mission to start/replay it. Checkpoints retain position, role, records and Initiation's unit state; NPC states remain transient.

**Incomplete:** menus and missions are greybox foundations, not a finished campaign. Equipment selection and restrictions are data only: the training sidearm and Quiet Line cannot be used in play. The debrief is a skippable results screen, not a cinematic camera sequence. Meridian has not received the requested significant expansion. No audio assets, graphics presets, full NPC warning/escalation/recovery, or target-hardware benchmark are implemented. There has been no human interactive playtest or Windows export verification. See [TESTING.md](TESTING.md), [AUDIT.md](AUDIT.md), and [PERFORMANCE.md](PERFORMANCE.md).

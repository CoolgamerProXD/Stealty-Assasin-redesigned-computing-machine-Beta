# Gameplay

The Meridian Hotel's fictional archive has disappeared. Three records are available: the ledger, staff memo and archive terminal. Collect any two different records, then interact with the exit. The HUD distinguishes collected versus available records from the number required. The blue marker changes the visitor into a staff role; the visitor has public access, staff can also enter the staff zone, and only security/manager roles can enter the secure zone. Access is independent from NPC suspicion. Entering without permission is possible but may be observed. HUD awareness is a prototype aggregate, not an in-world report.

WASD, mouse look, Shift run, C crouch, E interact, F5 save, F9 load, Escape opens the pause menu during campaign play. Controls can be edited in the Godot Input Map. Gold markers are records, blue is the uniform and green is extraction. These markers, capsule characters, hard-coded positional area boundaries and abstract observations are placeholders. Crouching does not alter detection. There is no combat or graphic content.

Two openings in each partition allow alternate routes; the walls also block vision and interaction rays. Saving covers mission clues, player position, role and collected markers. Loading leaves NPCs in their current transient states. Settings and campaign progression are persisted separately.

## Initiation and campaign foundation

Ruby briefs the player on the Civic Evaluation Annex. Collect all three unique records, disable the moving assessment unit and return to the exit; the two guards are standard scheduled NPCs. An optional action flag and its markers survive checkpoints. Completing Initiation unlocks Meridian and the Quiet Line menu entry; completed missions remain replayable. A results/debrief screen can be skipped. Equipment is not operational, despite the saved selection and restrictions; no shots, charges, gadget effects or AI response to equipment exist.

Crouch smoothly changes the existing capsule, visual height and camera pivot, and checks overhead obstruction before standing. It changes speed and geometry, not NPC awareness by an arbitrary multiplier. The existing vision ray remains obstruction-aware. The Initiation guards use existing positional area permissions, not a fully designed assessment-specific AI. The robot moves on a simple sinusoidal path; it does not detect or respond to the player.

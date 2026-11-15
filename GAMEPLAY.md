# Gameplay

## Current target and controls
Confront Adrian Locke (primary), question Ivo Chen (witness), collect any two records and extract at the Meridian. The Initiation primary remains the assessment unit. Hold right mouse to aim and left-click to fire a center-ray assessment pulse; Q is now only for Quiet Line. Left Ctrl enables Instinct while held. Red is a discovered primary target; yellow marks important, visible, unobstructed items within four metres by default. Highlights are depth-tested. Earlier descriptions below may be historical.

## Current critical gameplay update
The Meridian now requires questioning Ivo Chen as well as two records. The assessment unit and witness are displayed in the HUD. The training sidearm has five abstract unsuppressed pulses; Q uses one, nearby NPCs investigate, and a nearby unobstructed unit can be disabled. Select the unlocked Quiet Line in the loadout for Meridian, choose it with 2 and use Q near a person to temporarily incapacitate them. The sidearm remains slot 1. These are simplified prototype interactions rather than ballistic or physical restraint simulations. Ruby's post-Initiation meeting uses timed 3D actor and door movement with subtitles and can be skipped without losing progression. Older descriptions below are historical where they conflict with these rules.

The Meridian Hotel's fictional archive has disappeared. Three records are available: the ledger, staff memo and archive terminal. Question Ivo Chen and collect any two different records, then interact with the exit. The HUD distinguishes collected versus available records from the number required. The blue marker changes the visitor into a staff role; the visitor has public access, staff can also enter the staff zone, and only security/manager roles can enter the secure zone. Access is independent from NPC suspicion. Entering without permission is possible but may be observed. HUD awareness is a prototype aggregate, not an in-world report.

WASD, mouse look, Shift run, C crouch, E interact, F5 save, F9 load, Escape opens the pause menu during campaign play. Controls can be edited in the Godot Input Map. Gold markers are records, blue is the uniform and green is extraction. These markers, low-poly characters, hard-coded positional area boundaries and abstract observations are placeholders. Crouching does not alter detection. There is no combat or graphic content.

Two openings in each partition allow alternate routes; the walls also block vision and interaction rays. Saving covers mission clues, player position, role and collected markers. Loading leaves NPCs in their current transient states. Settings and campaign progression are persisted separately.

## Initiation and campaign foundation

Ruby briefs the player on the Civic Evaluation Annex. Collect all three unique records, disable the moving assessment unit and return to the exit; the two guards are standard scheduled NPCs. An optional action flag and its markers survive checkpoints. Completing Initiation unlocks Meridian and the Quiet Line menu entry; completed missions remain replayable. A results/debrief screen can be skipped. The equipment implementation is described above; it remains a simplified game mechanic.

Crouch smoothly changes the existing capsule, visual height and camera pivot, and checks overhead obstruction before standing. It changes speed and geometry, not NPC awareness by an arbitrary multiplier. The existing vision ray remains obstruction-aware. The Initiation guards use existing positional area permissions, not a fully designed assessment-specific AI. The robot moves on a simple sinusoidal path and reacts to a nearby unobstructed player by scanning and slowing down.

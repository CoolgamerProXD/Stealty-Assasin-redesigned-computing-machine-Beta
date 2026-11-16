# Current additions: Initiation coins and Hong Kong clues

Initiation's existing evaluation, sensor-log and dispatch records are the three labelled assessment lesson milestones. Each grants one permanent coin, at most three, recorded separately from USB keys and mission equipment. An existing completed campaign save receives all three; an in-progress Initiation checkpoint awards only its validated saved records when loaded. Use LOADOUT to cycle equipped coins between zero and the earned total. In later missions press **G** to toss a fictional coin forward: nearby eligible NPCs investigate its landing point, the mission stock decreases, and a fresh deployment replenishes the equipped amount. A checkpoint preserves remaining stock; the permanent count is never spent.

Each Hong Kong operation adds a witness and optional evidence clue. These are optional and do not award keys; complete the primary objective, physically secure that mission's single key, and use extraction. Tung Chung also requires the train contact. The new city lookout intel is reached via a ramp in the attached neighbourhood. A second exterior ramp leads to an upper service room containing an optional staff disguise, which permits staff areas but not secure areas and survives that mission's checkpoint. Debriefs distinguish optional evidence and witness status. The extraction camera runs after progression is saved and may be skipped with Escape.

# Current Hong Kong gameplay

After Initiation, the five operations unlock in order. Press E to confront the named target, then separately collect that mission's key from the indicated target, bodyguard or safe. Reach the marked extraction after both objectives. In Tung Chung the platform transition leads to a fictional carriage, where the train contact must be questioned before the exit. The USB HUD displays all five persistent keys; the final extraction opens a skippable secure-channel event without a fabricated revelation. F5/F9 save/load that operation only. Escape skips an entry camera or opens pause after the camera. Loadout, aim/fire and Instinct remain available.

Staff and security may warn a visible trespasser and point toward a permitted area. Security enters a stylized alert after about three seconds; leaving de-escalates. Visitors and staff who lack access seek help locally. Security can fire a fictional pulse that briefly staggers an exposed player; cover blocks it. There is no health, injury, coordinated backup or full pursuit combat. The historical preview notes below refer to the separately selectable exploration scenes, not the new campaign operations.

# Second-pass gameplay notes

The Meridian west wing has two additional locally scheduled people and one stationary upstairs guest. There is no NPC route between floors; Locke is still in the suite. Restaurant tables, seating and beds have selected collision, while many decorative details are not solid. The lobby and original mission positions are retained. Player crouch is represented by bent knees and a lowered torso, while the existing capsule/ceiling clearance rules determine physical stance. Sounds and poses remain stylized approximations.

The city and mountain scenes have a few moving public-space visitors, while the station retains its scheduled crowd; all three are separately selectable exploration previews, not playable campaign assignments. Their routes and geography are fictional. The statue is a static landmark, not a target. No preview unlocks campaign progress.

# Meridian and map previews — current

Use Mission Selection to open any of the three separate map previews; Escape returns to Mission Selection. They do not start campaign missions or save story progress. Meridian retains its objectives, witness, target-state and save paths. The west ramp connects the original lobby to two storeys of added space; Adrian remains in the upper private suite. The central top HUD shows mission guidance, bottom-left reports only actual local access/awareness, bottom-right reports selected equipment and real charges, and contextual interaction appears top-left. There is no health system or radar.

# Historical direction and preview

Hong Kong is the planned campaign direction; Meridian remains optional legacy content. The main-menu Tung Chung entry is a map preview, not a mission. E observes either nearby character, and Escape returns to the menu; it has no combat, Instinct, save, mission goals, train story or opportunities. See HONG_KONG_MAP_PLAN.md.

A Meridian target completed by a pulse remains incapacitated and cannot resume its routine; a target completed by conversation remains standing but exits active AI. Completion and pose survive checkpoints. Quiet Line and non-target pulse incapacitation remain temporary.

# Gameplay

The shoulder and FOV interpolate during aim, and the sidearm's procedural pose draws, raises, recoils and lowers with the selected equipment. The fixed five-charge assessment device does not reload. Visible incapacitated people can prompt nearby NPC investigations; use actual cover rather than relying on crouch alone. The HUD's local-alert wording is not a guarantee that no other NPC can see you.


## Current target and controls
Confront or pulse-tag Adrian Locke (primary), question Ivo Chen (witness), collect any two records and extract at the Meridian. The Initiation primary remains the assessment unit. Hold right mouse to aim and left-click to fire a center-ray assessment pulse; Q is now only for Quiet Line. Left Ctrl enables Instinct while held. Red is the briefing-identified primary target, including through walls; yellow marks important, visible, unobstructed items within four metres by default. Yellow item overlays remain depth-tested and never reveal items through walls. Earlier descriptions below may be historical.

## Current critical gameplay update
The Meridian now requires questioning Ivo Chen as well as two records. The assessment unit and witness are displayed in the HUD. The training sidearm has five abstract unsuppressed pulses; Q uses one, nearby NPCs investigate, and a nearby unobstructed unit can be disabled. Select the unlocked Quiet Line in the loadout for Meridian, choose it with 2 and use Q near a person to temporarily incapacitate them. The sidearm remains slot 1. These are simplified prototype interactions rather than ballistic or physical restraint simulations. Ruby's post-Initiation meeting uses timed 3D actor and door movement with subtitles and can be skipped without losing progression. Older descriptions below are historical where they conflict with these rules.

The Meridian Hotel's fictional archive has disappeared. Three records are available: the ledger, staff memo and archive terminal. Question Ivo Chen and collect any two different records, then interact with the exit. The HUD distinguishes collected versus available records from the number required. The blue marker changes the visitor into a staff role; the visitor has public access, staff can also enter the staff zone, and only security/manager roles can enter the secure zone. Access is independent from NPC suspicion. Entering without permission is possible but may be observed. HUD awareness is a prototype aggregate, not an in-world report.

WASD, mouse look, Shift run, C crouch, E interact, F5 save, F9 load, Escape opens the pause menu during campaign play. Controls can be edited in the Godot Input Map. Gold markers are records, blue is the uniform and green is extraction. These markers, low-poly characters, hard-coded positional area boundaries and abstract observations are placeholders. Crouching does not alter detection. There is no combat or graphic content.

Two openings in each partition allow alternate routes; the walls also block vision and interaction rays. Saving covers mission clues, player position, role and collected markers. Loading leaves NPCs in their current transient states. Settings and campaign progression are persisted separately.

## Initiation and campaign foundation

Ruby briefs the player on the Civic Evaluation Annex. Collect all three unique records, disable the moving assessment unit and return to the exit; the two guards are standard scheduled NPCs. An optional action flag and its markers survive checkpoints. Completing Initiation unlocks Meridian and the Quiet Line menu entry; completed missions remain replayable. A results/debrief screen can be skipped. The equipment implementation is described above; it remains a simplified game mechanic.

Crouch smoothly changes the existing capsule, visual height and camera pivot, and checks overhead obstruction before standing. It changes speed and geometry, not NPC awareness by an arbitrary multiplier. The existing vision ray remains obstruction-aware. The Initiation guards use existing positional area permissions, not a fully designed assessment-specific AI. The robot moves on a simple sinusoidal path and reacts to a nearby unobstructed player by scanning and slowing down.

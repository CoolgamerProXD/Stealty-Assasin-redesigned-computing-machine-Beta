## Second-pass prototype status

The Meridian west wing has additional original architectural dressing and a small floor-local population. Articulated crouch and gait-synchronized synthesized steps replace vertical character squashing; the three independent map previews have additional public-space detail and visitors. These remain low-poly procedural prototypes, not completed AAA levels, and NPCs do not navigate between hotel floors. See `TESTING.md` for automated coverage and limitations, and `PERFORMANCE.md` for explicitly labelled software-rendered samples. A human playthrough and Windows/Iris Xe benchmarking are still needed.

# PROJECT ASSASSIN

An offline Godot 4.4.1 stealth-sandbox prototype. BLACKLINE is the player's employer; Ruby is the handler and the Covenant is a separate organization. The playable content is **01 Initiation** and the optional legacy **The Meridian**. Mission Selection also offers three clearly labelled Hong Kong map previews, not completed campaign missions.

## Play

Open `project.godot` in Godot 4.4.1 and press F5. Choose Campaign or a mission from Mission Selection. Ruby's briefing identifies the target; the mission HUD tracks the target, evidence, awareness, equipment and interaction prompts.

- **Initiation:** disable the moving assessment unit (E nearby or a well-aimed training pulse), collect all three records and reach the exit. Two guards patrol. Completion unlocks legacy Meridian and Quiet Line, then starts the skippable Ruby meeting.
- **The Meridian:** explore the original hotel and connected west wing, including the upper guest rooms. Follow the ramp in the west wing to the private suite. Confront or tag primary target **Adrian Locke**, the operations director who authorized the archive transfer. Question records employee **Ivo Chen** as a separate witness, collect any two of the three records and reach the exit. The uniform grants staff access, not secure access.
- **Equipment:** press 1 for the unsuppressed, five-charge fictional training sidearm. Hold **right mouse** to aim, then press **left mouse** to fire an instantaneous pulse along the centre crosshair. It is blocked by walls, disables the unit and temporarily incapacitates people; nearby NPCs react to the noise. After Initiation, choose Quiet Line in Loadout before deploying to Meridian. Press 2 to equip it and Q to temporarily incapacitate a nearby unobstructed NPC. Quiet Line is not permitted in Initiation; the sidearm is always issued. A successful pulse on Locke completes the primary objective and leaves him permanently incapacitated for that checkpoint; Quiet Line only incapacitates him temporarily. A nonviolent confrontation completes his objective without a downed pose.
- Hold **left Ctrl** for Instinct: the briefing-identified primary target appears as a red character silhouette through solid geometry; nearby visible, unobstructed intel and the uniform appear yellow (default range four metres). Ordinary NPCs and undiscovered items are not revealed. WASD moves, mouse looks, Shift runs, C crouches, E interacts, F5 saves, F9 loads and Escape pauses. The Ruby scene can be skipped with Escape or its button. Actual cover can block an NPC's sight of a crouched player; crouching has no automatic visibility bonus. NPCs can notice visible incapacitated people and investigate locally.

Settings offer persisted LOW, MEDIUM and HIGH rendering scales (70%, 85%, 100%), shadow toggles/atlas sizes, optional practical lights, HIGH fine decoration and FXAA, and an FPS-counter toggle. The experimental lobby probe was removed after it made HIGH unacceptably dark.

Campaign and settings have separate versioned saves. Meridian retains `user://meridian_save.json`; Initiation uses `user://initiation_save.json`. Checkpoints retain player position, role, records, target completion, equipped items and remaining charges. Target identification and completion persist. NPC schedules, suspicion and temporary incapacitation are transient; the completed primary target state and its pose persist. Already-extracted legacy Meridian saves remain complete; in-progress saves must meet the current primary-target and witness objectives.

## Hong Kong direction

Mission Selection offers **three labelled exploration previews**: Tung Chung station, a rough Hong Kong city blockout and a stylized Ngong Ping mountain/village and Buddha landmark. Escape returns to Mission Selection. These are not completed missions: story, objectives, checkpoints and campaign unlocks remain unimplemented. The station retains scheduled passenger characters; the city and mountain currently have no crowds. See [HONG_KONG_MAP_PLAN.md](HONG_KONG_MAP_PLAN.md).

## Meridian expansion and interface
The original hotel coordinates and mission objectives remain. A connected west wing adds a dining/lounge area, upper guest rooms and an upstairs private suite for Locke. The two levels provide roughly seven times the original single-floor gross surface area, while the horizontal footprint is roughly 3.5 times larger; wall and stairwell space reduce actual walkable area. The ramp is a traversable incline, not animated stairs. This remains low-poly, with incomplete room detail, some visual-only furniture and an NPC navigation mesh that does not connect floors. Upper-floor save validation is approximate. The target stays in the suite; existing NPCs remain on the original floor.

The HUD uses contextual prompts, top-centre objectives, local awareness and equipment/charges. No health or omniscient radar was invented. Documents and the archive/sensor terminal use original procedural geometry; some assessment and exit markers remain abstract. Player acceleration, visual turning, gait and footstep cadence were adjusted, but motion and camera feel need human assessment.

## Status

This remains a stylized prototype, **not an AAA production**. The original low-poly characters have tapered jackets, role-specific clothing, locomotion and procedural weapon/idle poses, not textured skinned production models. The Meridian now has a reception, lounge, wayfinding, corridor trim, artwork and workspaces; the annex has cooler workstations and assessment-lane dressing. Much of this remains simple, non-colliding procedural geometry over the original layouts. The Ruby scene has an original low-poly exterior, sky, opening doors, characters, subtitles and synthesized tones, not voice acting or polished authored animation. No third-party assets have been imported; see [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md).

No human interactive playtest or target Iris Xe benchmark has been performed. A Windows export smoke-test workflow is provided; consult its run results rather than assuming it succeeded. Aim feel, visual quality, cinematic composition and full routes need hands-on testing; full NPC escalation and blocked-path recovery remain unfinished. See [TESTING.md](TESTING.md), [AUDIT.md](AUDIT.md), and [PERFORMANCE.md](PERFORMANCE.md).

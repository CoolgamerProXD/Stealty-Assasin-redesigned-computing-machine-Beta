# NPC simulation

## Target and shooting
Adrian Locke is a separate manager with an authored schedule and the existing local perception/response system. A training pulse temporarily incapacitates a struck NPC; nearby NPCs hear the pulse and investigate its origin. The target must be conscious for confrontation. NPC suspicion, route state and incapacitation remain transient on load.

## Critical gameplay update
A nearby unsuppressed training pulse causes NPCs to investigate the player's position. Quiet Line temporarily disables a nearby unobstructed NPC for 12 seconds, after which it returns toward its schedule. Incapacitation and other NPC state are not saved. The assessment unit scans nearby unobstructed players and slows its patrol; it does not conduct a full guard-like investigation.

## Initiation reuse and remaining work
The two Initiation guards reuse the same deterministic individual perception, memory and navigation implementation. They use positional visitor/staff/secure areas, not a mission-specific permission model. Existing simulation is not full warning/escalation or reliable blocked/unreachable recovery; investigate/recovery and last known locations remain basic. The moving assessment unit is not an NPC and does not react to observations. Crouch changes physical stance; there is no special detection multiplier.

Profiles contain identity, occupation, personality fields and an ordered schedule of destinations, activities and durations. The hotel JSON is loaded at startup into reusable Resources. The three example actors navigate on a manually tiled NavigationRegion3D around two physical partitions. They walk to each entry, remain for its duration, then advance cyclically.

Every 0.4 seconds an NPC checks whether the player lacks permission at their current positional zone, then uses a 7 m, 120-degree horizontal field of view and a physics ray for line of sight. On observation it stores a local direct memory, increases suspicion using alertness, and moves to the observed position. The state sequence is suspicious → investigating → returning → walking / scheduled activity. Repeated visible trespass refreshes the investigation. Curiosity extends the investigation, after which suspicion falls and the interrupted schedule resumes. Memory expires independently.

This is a deliberately small deterministic prototype. Perception only knows about player trespass, there are no hearing, direct social recognition, communications, beliefs, separate intentions, alert escalation, simulation tiers, day clock, group conversations or persistent NPC state. Other profile traits and category-specific policies remain future work. Routine activities are labels rather than animations or interactions. Schedules currently pause during interruptions rather than progressing on a shared clock.

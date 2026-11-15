# Meridian upper floor

Adrian Locke has one long-duration stationary schedule in his upper private suite. The original ground-floor agents retain their local routines. An upper navigation region supports the stationary target, but cross-floor NPC routing and collision-aware pathfinding around all new furniture are not implemented. Completed targets remain terminal and checkpointed; ordinary temporary incapacitation still expires.

# NPC simulation

Completed physical targets enter `objective_completed`, stop AI/perception and cannot be temporarily incapacitated again. A pulse leaves the completed target down; confrontation leaves them standing. The mission checkpoint stores completion and pose, and loading an earlier checkpoint deliberately restores the target to active simulation. Ordinary NPC and Quiet Line incapacitation still expire. The Tung Chung preview reuses schedules but has no mission target state yet.

A throttled local observation pass lets an NPC notice an incapacitated person only within range, field of view and unobstructed physics line of sight. That observer records a disturbance and investigates; there is no global broadcast. Player sight aims at a point derived from the actual capsule stance, so solid low cover can block a crouched silhouette while an exposed crouched player remains detectable. Schedule states also drive simple idle gestures; these are not simulated conversations.


## Target and shooting
Adrian Locke is a separate manager with an authored schedule and the existing local perception/response system. A training pulse temporarily incapacitates an ordinary struck NPC; nearby NPCs hear the pulse and investigate its origin. The target must be conscious for confrontation; a successful training pulse independently completes the primary target objective. Quiet Line does not. NPC suspicion, route state and temporary incapacitation remain transient on load; completed target outcomes persist.

## Critical gameplay update
A nearby unsuppressed training pulse causes NPCs to investigate the player's position. Quiet Line temporarily disables a nearby unobstructed NPC for 12 seconds, after which it returns toward its schedule. Temporary incapacitation and routine state are not saved; completed primary target state is saved. The assessment unit scans nearby unobstructed players and slows its patrol; it does not conduct a full guard-like investigation.

## Initiation reuse and remaining work
The two Initiation guards reuse the same deterministic individual perception, memory and navigation implementation. They use positional visitor/staff/secure areas, not a mission-specific permission model. Existing simulation is not full warning/escalation or reliable blocked/unreachable recovery; investigate/recovery and last known locations remain basic. The moving assessment unit is not an NPC and does not react to observations. Crouch changes physical stance; there is no special detection multiplier.

Profiles contain identity, occupation, personality fields and an ordered schedule of destinations, activities and durations. The hotel JSON is loaded at startup into reusable Resources. The three example actors navigate on a manually tiled NavigationRegion3D around two physical partitions. They walk to each entry, remain for its duration, then advance cyclically.

Every 0.4 seconds an NPC checks whether the player lacks permission at their current positional zone, then uses a 7 m, 120-degree horizontal field of view and a physics ray for line of sight. On observation it stores a local direct memory, increases suspicion using alertness, and moves to the observed position. The state sequence is suspicious → investigating → returning → walking / scheduled activity. Repeated visible trespass refreshes the investigation. Curiosity extends the investigation, after which suspicion falls and the interrupted schedule resumes. Memory expires independently.

This is a deliberately small deterministic prototype. Perception only knows about player trespass, there are no hearing, direct social recognition, communications, beliefs, separate intentions, alert escalation, simulation tiers, day clock, group conversations or persistent NPC state. Other profile traits and category-specific policies remain future work. Routine activities are labels rather than animations or interactions. Schedules currently pause during interruptions rather than progressing on a shared clock.

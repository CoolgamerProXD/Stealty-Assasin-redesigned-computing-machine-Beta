# Current local reporting

Visitors who see trespass or an incapacitated person can seek a nearby, available security NPC in the same scene. A report is delivered once only within 2.5 metres and unobstructed line of sight; security begins a bounded local investigation, not automatic global hostility. If no guard is nearby, the visitor retreats toward a schedule point and eventually resumes. Security still warns trespassers for about three seconds, de-escalates when they leave and uses short, cover-blocked fictional stagger pulses only during unresolved alert. Navigation and social coordination remain local and incomplete; no global search, realistic combat or comprehensive crowd simulation is claimed.

# Current trespass behavior

Visible restricted-area trespass creates a local memory. Authorized staff/security issue a warning with an exit direction and a three-second grace period that does not restart on each sighting. Leaving de-escalates; security otherwise raises a stylized alert pose, while other roles seek help on a bounded local route. Visitors do not immediately become hostile. Alerted security can fire a non-graphic, cover-blocked pulse that briefly staggers the player. There is no player health, coordinated backup, full pursuit combat or comprehensive obstacle avoidance. Station navigation now excludes the information island and pillars; other navigation remains partial.

# Historical second-pass local routes

Two Meridian wing visitors use a dedicated ground-floor navigation strip, away from the restaurant furniture. An upstairs visitor walks a separate clear gallery route; no cross-floor connection is claimed. Locke stays in the suite and mission completion/persistence remains separate from these background actors. City and Ngong Ping previews each use a few deterministic floor-local visitor routes within the open central space, without story behavior or simulation of a real crowd. Station passengers use short, separated local routes; no crowd simulation or complete obstacle-aware station navmesh is claimed. NPC knowledge remains local; these additions do not share observations globally.

# Meridian upper floor

Adrian Locke walks a short deterministic route entirely within his upper private suite, with pauses at each end. The original ground-floor agents retain their local routines. An upper navigation region supports the suite target and one gallery guest, but cross-floor NPC routing and collision-aware pathfinding around all new furniture are not implemented. Completed targets remain terminal and checkpointed; ordinary temporary incapacitation still expires.

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

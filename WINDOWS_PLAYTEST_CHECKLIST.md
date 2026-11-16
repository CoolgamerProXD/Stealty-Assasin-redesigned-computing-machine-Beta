# Windows / Iris Xe local playtest checklist

No interactive Windows session or Intel Iris Xe hardware was available to this agent. The CI Windows export/launch is headless and does not measure input feel, visual quality, audio or performance. Use the latest successful Windows artifact linked in TESTING.md and extract all files together. Verify the source commit before comparing results.

## Configuration and measurements
1. Plug the i5-1335U / 16 GB / Iris Xe laptop into power, close heavy background applications, record Windows and GPU driver versions, power mode and display refresh rate. Launch at 1280 × 720 with FPS enabled.
2. For LOW, MEDIUM and HIGH separately, test the same 60-second route in each city neighbourhood, the busy station/train and the Buddha approach. Repeat with MEDIUM/HIGH shadows on and off, and local lights on and off. Report average FPS, 1% low (or minimum with sampling method), frame-time graph and process memory using a trusted Windows overlay or profiler. Note thermal throttling and route/crowd density. The in-game FPS counter is instantaneous, not a benchmark recorder.
3. Record stutters at cinematic transitions, aiming, entering new neighbourhoods and loading saves. Capture screenshots with settings and context; do not equate software-rendered CI numbers with Iris Xe.

## Functional pass
1. Start a new campaign. In Initiation collect each of the three labelled lesson records separately, verify each earns exactly one coin, save/restart, replay and verify no duplicate. Finish the assessment. Test an older completed save and, separately, an old partial Initiation checkpoint; make backups before testing migration.
2. In LOADOUT cycle 0 through the earned amount and verify a higher selection is unavailable. Deploy into Meridian and Hong Kong, toss with G near NPCs, verify investigation, save/load remaining stock, restart the mission and check that the loadout replenishes while the permanent rewards remain. Test 0, 1, 2 and 3 coins.
3. Complete the five Hong Kong operations in order. Verify each entry cinematic and Escape skip; speak to each physical witness and find optional intel; confront/tag the target, confirm that this alone awards no key, physically collect the one described key, and extract. In Tung Chung speak to the train contact. Save/restart at several points; confirm checkpoints do not overwrite Initiation, Meridian or other operations.
4. Walk the city gates, both room entrances, alleys and lookout ramps in both directions, including crouching and camera collision. Test the station stairs, train collision, mountain slopes, field-office entrance and monument approach. Look for clipping, inaccessible objects and NPCs getting stuck.
5. In restricted areas test visitor, staff and security responses with and without disguises: warning, approximately three-second grace, leaving, staying, cover-blocked security pulses and eventual return to routine. Test coin and incapacitation witnesses without assuming perfect guard coordination.
6. Check all five extraction presentations and skips, mission debriefs, USB key display and final secure-channel event. Play Initiation and Meridian end-to-end, test aiming, Quiet Line, settings, audio, menus, save/load and legacy migration.

Document bugs with exact mission, save state, steps, resolution, preset, screenshots/video and measured data. Do not describe a successful launch as a complete playthrough or performance certification.

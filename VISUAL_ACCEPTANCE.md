# Visual overhaul acceptance report — checkpoint 1

**Overall: INCOMPLETE / PARTIAL PROTOTYPE.** This report is intentionally conservative. The changes below are the first implementation step, not the requested campaign-wide quality upgrade. No photorealism, complete-overhaul, target-device performance, or human visual-acceptance claim is made.

## Work present in source

- Researched and documented project facts, technical tradeoffs, visual direction, pipeline, and asset provenance in `VISUAL_RESEARCH.md`, `ART_DIRECTION.md`, `RENDERING_PIPELINE.md`, and `ASSET_PROVENANCE.md`.
- Added a renderer-compatible screen-space Instinct grade helper and shader; wired it into hotel and campaign operations while leaving mission-specific object eligibility/highlighting logic in place.
- Added a few original seeded face/hair-shape variations and roughness settings to the existing procedural primitive character. This remains a stylized, primitive-built character, not a realistic skinned human or garment system.
- Extended the existing rendered Instinct regression with easing-state assertions. No unrelated external asset was downloaded or added.

## Automated checks

- Python data tests: **9/9 passed** locally (`python3 -m unittest discover -s tests -p 'test_*.py' -v`).
- `git diff --check`: passed before commit.
- Godot 4.4.1 workflow run [44042285895](https://github.com/CoolgamerProXD/Stealty-Assasin-reimagined-Beta/actions/runs/44042285895): workflow conclusion **success**. Headless job passed import, main-scene startup, behavioral regression, integrated Hong Kong campaign, outfit/facility, coin progression, NPC route soak, camera/display sampling, through-wall Instinct rendering, cinematic captures, and Hong Kong staged environment captures. This is CI automation using the hosted Linux/Xvfb environment, not human review or target-device evidence.
- In run [44042990998](https://github.com/CoolgamerProXD/Stealty-Assasin-reimagined-Beta/actions/runs/44042990998), both headless and Windows jobs concluded **success**. The Windows job verified official Godot 4.4.1 and export templates, imported/exported the project, and launched its configured scenes headlessly from the Windows release executable. This validates automated Windows export/smoke coverage; it is not a Windows interactive visual playtest and not a benchmark on the specified Iris Xe laptop. The prior run's Windows job was skipped because the workflow gates it on `[windows]` in the commit message.
- Local sandbox had no Godot executable; Godot runtime testing was performed by CI, not locally.

## Visual evidence and review

- The required **18 paired, equivalent-condition before/after views have not been captured**. No baseline/candidate comparison set exists yet. The CI artifact captures are targeted regression screenshots, not this complete old/new matrix.
- Automated rendering assertions passed in CI. No human visual review has been performed. No interactive playtest has been performed for this visual change.
- The user-provided 18-scenario list is not reproduced in this checkpoint's available session context. The 18-item proposed matrix in `RENDERING_PIPELINE.md` is a coverage aid, not a claim that it exactly matches the user's original list; reconcile the scenario names before visual sign-off.

## Performance and platform

- Target: Windows 11, i5-1335U, 16 GB, Intel Iris Xe, 1280×720.
- **No benchmark on this target laptop was performed.** No Windows renderer comparison, route frame-time distribution, memory measurement, GPU-driver test, or power-mode test has been made for the prototype.
- CI Xvfb/Mesa results are software-rendered hosted-runner results and are not Iris Xe performance. Existing historical measurements in `PERFORMANCE.md` remain caveated and do not measure this prototype or the target laptop.

## Unmet acceptance criteria / next work

- Trigger and pass the Windows Godot 4.4.1 export plus exported-scene smoke suite.
- Inspect actual screen-shader output and overlay/HUD composition; validate in Compatibility and chosen target renderer, including focus-loss, pause, transitions and all missions.
- Capture all 18 user scenarios before and after at the same camera, lighting, player/NPC, renderer, preset and resolution; human-review them and save labeled evidence.
- Build a genuinely improved, varied human/garment pipeline and apply it throughout campaign NPCs without breaking outfit permissions, persistence, animation, or full civilian coverage.
- Upgrade coherent architecture/materials/lighting across every campaign family; current changes do not do this.
- Conduct interactive disguise, movement, NPC, mission, save/load, discovery and secret-facility playtests.
- Benchmark the exact Windows/Iris Xe laptop and report measured results; if inaccessible, explicitly leave the target performance criterion unverified.

**Release gate:** keep this checkpoint partial until the unmet criteria are tested and reviewed. A passing build or selected scene improvement alone does not constitute completion.

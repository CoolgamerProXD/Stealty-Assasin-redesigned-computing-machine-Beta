# Performance

## Target/Instinct update caveat

CI run 43704290753 (`aaff1c2`) used Godot 4.4.1 on Ubuntu with AMD EPYC 9V45, 4 reported CPUs, ~15.6 GiB RAM and Mesa llvmpipe under Xvfb at 1280×720. The scripted Meridian camera sample of 120 frames measured mean **18.987 ms / 52.67 FPS**, p95 **19.942 ms**, p99 **20.392 ms**; engine clock to first test frame **2,965.374 ms**. Headless 120-frame menu startup process: **1.10 s**, **95,036 KiB** peak RSS. Synthetic CI only: no conclusions about Intel Iris Xe, the cinematic or actual play.

The new moving camera, hit feedback, material overlays, additional NPC and cinematic exterior have not been measured on the target laptop. Any CI software-rendering sample is not a target-hardware benchmark. Renderer comparisons and a human performance pass remain outstanding.

## Critical gameplay update CI sample
Actions run 43702084074 (`0c1ee7b`) used Godot 4.4.1, Linux GitHub VM with AMD EPYC 9V74, 4 reported CPUs and ~15.6 GiB RAM, Xvfb 1280×720 and Mesa llvmpipe Compatibility software rendering. The scripted Meridian camera sample of 120 frames measured mean **22.495 ms / 44.45 FPS**, p95 **23.614 ms**, p99 **26.099 ms**; first test frame was **5,032.842 ms** on the engine clock. The headless 120-frame menu process took **1.10 s**, peak **94,428 KiB**. These are synthetic CI measurements, not the Windows/Iris Xe target. Full gameplay, Initiation, cutscene and target-hardware performance are not benchmarked. Renderer comparisons are still outstanding.

## Campaign expansion caveat

CI run 43700503344 (`a6c6ca9`): Ubuntu VM, AMD EPYC 9V74, 4 reported CPUs, ~15.6 GiB RAM; 1280×720 Xvfb, Godot 4.4.1 Compatibility, Mesa llvmpipe. Scripted Meridian camera: 120 samples, mean 22.160 ms (45.13 FPS), p95 24.501 ms, p99 25.423 ms; peak RSS 300,348 KiB, first test frame 2,468.572 ms. Headless menu 120-frame process: 1.10 s and 94,760 KiB peak RSS. These are software-rendered synthetic CI measurements, not user-device results.

The historical results below apply to earlier Meridian builds, not the expanded campaign or target Windows/Iris Xe hardware. Main-menu startup and a scripted Meridian camera sample on a CI VM do not measure Initiation or establish playable FPS. Forward+, Mobile and Compatibility have not been benchmarked on the target machine; do not infer a winner. No scalable graphics-quality presets have been added. Compatibility remains provisional.

No representative target-laptop FPS, memory, renderer comparison or load-time benchmark has been measured. The development workspace is a Debian 12 sandbox with 2 reported CPUs and 3.8 GiB RAM, not the specified Windows 11 / Iris Xe laptop. Target Windows version and actual hardware configuration were not inspectable. Goals of 720p, 30–60 FPS and 20–40 NPCs are unverified.

Compatibility is a provisional conservative starting point, **not a benchmark-based selection**. Shadows are disabled, lighting is simple, geometry/materials are primitive, navigation uses a small manually tiled mesh and NPC vision runs every 0.4 seconds. There are only three NPCs and no simulation LOD or quality presets.

On the target laptop, use the same representative scene and camera for Forward+, Mobile and Compatibility. Warm up, then record frame time median, 95th/99th percentiles, FPS, memory, renderer, resolution, power profile, NPC count and build version. Capture a repeatable route and scale population to 20 and 40 before selecting the renderer or optimization. Do not infer target results from headless execution.

Audit sandbox: Debian Linux x86-64, Intel Xeon virtual CPU (2 reported cores), 3.85 GiB RAM. A Godot 4.4.1 source build was still compiling during the audit, so startup time, game memory, frame time, NPC overhead and rendering overhead could not be measured. NPC memory expiry was changed to remove expired entries in place rather than creating a filtered array each physics tick; this is a code-level allocation reduction, **not a measured speedup**.

## Virtual runner baseline — 2026-11-15

In [run 43699069502](https://github.com/CoolgamerProXD/Stealty-Assasin-redesigned-computing-machine-Beta/actions/runs/43699069502), commit `af7972243780b908b18462703d27973cc42ace0d`, the official Godot 4.4.1 Linux binary ran the three-NPC scene on a GitHub-hosted Ubuntu VM (AMD EPYC 9V74, 4 reported logical CPUs, about 15.6 GiB RAM) using a 1280×720 Xvfb display and Mesa 26.0.8 llvmpipe software OpenGL Compatibility renderer. VSync was unavailable on that virtual display.

- Engine clock to the first test-scene process frame: **4,829.935 ms** (approximation; not time-to-player-control).
- After 30 warm-up process frames, 120 sampled frames: mean **22.573 ms** / **44.30 FPS**, p95 **24.503 ms**, p99 **26.014 ms**. These are process-frame intervals in a synthetic camera test, not a repeatable gameplay route.
- Entire virtual-display test process: **10.55 s**, peak RSS **299,296 KiB**. Separate headless 120-frame startup/run: **1.15 s**, peak RSS **99,224 KiB**. Neither is a standalone startup or GPU-memory measurement.

The runner CPU and software renderer are not the Windows Iris Xe system. No renderer comparison, GPU/rendering breakdown, NPC-only overhead, 20–40 NPC stress test, or target-hardware performance has been measured. Do not infer laptop FPS from these numbers.

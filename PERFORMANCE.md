# Performance

No FPS, memory, renderer comparison, hardware or load-time benchmark has been measured. The development workspace is a Debian 12 sandbox with 2 reported CPUs and 3.8 GiB RAM, not the specified Windows 11 / Iris Xe laptop. Target Windows version and actual hardware configuration were not inspectable. Goals of 720p, 30–60 FPS and 20–40 NPCs are unverified.

Compatibility is a provisional conservative starting point, **not a benchmark-based selection**. Shadows are disabled, lighting is simple, geometry/materials are primitive, navigation uses a small manually tiled mesh and NPC vision runs every 0.4 seconds. There are only three NPCs and no simulation LOD or quality presets.

On the target laptop, use the same representative scene and camera for Forward+, Mobile and Compatibility. Warm up, then record frame time median, 95th/99th percentiles, FPS, memory, renderer, resolution, power profile, NPC count and build version. Capture a repeatable route and scale population to 20 and 40 before selecting the renderer or optimization. Do not infer target results from headless execution.

# Tung Chung visual direction — PROJECT ASSASSIN

**References reviewed:** the three user-provided screenshots for the Blood Money-era underground interior, Absolution-style nocturnal service alley, and World of Assassination suburban autumn street. They are references for authored visual principles only. No geometry, composition, texture or asset is copied from them.

## Reference observations

### 1. Enclosed underground interior (Blood Money)

- **Light:** dim warm practical pools against deep, broad shadow; a clear warm source near the back wall helps the player read the corridor's depth.
- **Surfaces/geometry:** repeated brick, thick piers, arched openings, battered work furniture and a deliberately low enclosed ceiling create a specific, coherent place rather than a large generic room.
- **Composition:** the player's back is a foreground anchor; the far wall and bright lamp establish a readable focal point; the seated NPC and open door provide secondary points of interest.
- **Atmosphere/detail:** restrained palette and uneven surfaces imply age and use without covering every surface in clutter.
- **Character:** the player silhouette and stance are recognizable against the room, though this older reference is not a modern character-quality target.

### 2. Nocturnal urban alley (Absolution)

- **Light and colour:** strong warm red/orange practical accents contrast with cool teal/blue ambient depth. The brightest sign pulls the eye toward the vanishing point; localized pools do not wash the whole alley evenly.
- **Material response:** wet pavement catches broken red/blue reflections. Brick, metal bins, painted surfaces and masonry have visibly different roughness and value; not everything is polished.
- **Architecture/density:** close, tall walls, pipes, fire escapes, signs, cables and overhangs frame a layered narrow route. Silhouette-rich objects create foreground, middle-ground and distance separation.
- **Camera/hierarchy:** a centered over-shoulder figure occupies the lower foreground while the path and sign lead into atmospheric haze. Reflections reinforce perspective.
- **Atmosphere:** haze and distance soften far forms while nearer brick and trash retain contrast. Density is organized around a navigable corridor rather than a prop pile.

### 3. Autumn residential exterior (World of Assassination)

- **Light:** bright natural late-day illumination filters through trees, creating a warm canopy and broken ground shadows; sky/open distance keeps the road legible.
- **Materials/detail:** foliage, grass, pavement, houses, vehicles and street furniture each read as different material families. Small street objects support the impression of an inhabited neighborhood.
- **Composition:** cinematic letterboxing and the over-shoulder silhouette establish a deliberate establishing shot. The street's perspective creates a strong route; the player remains a dark, readable foreground shape against the bright environment.
- **Colour/depth:** warm yellow/orange foliage is balanced by cool shade and distant neutral buildings. Repeated trees and houses recede into a visually layered background.
- **Character:** the modern reference communicates a tailored silhouette and an idle, composed stance, but screenshot review alone cannot establish animation quality.

## PROJECT ASSASSIN interpretation

Tung Chung is a fictional enclosed transit concourse, not a sewer, alley or copied real station. The environment will borrow the references' **principles**: Blood Money's enclosed rhythm and warm practical pools; Absolution's warm/cool contrast, material separation and layered route framing; World of Assassination's deliberate camera hierarchy and strong player silhouette. The game's own identity is a restrained **BLACKLINE transit noir** palette: graphite/blue-green tile, pale mineral terrazzo, dark brushed metal, muted amber wayfinding, selective coral-red service accents, cool cyan glass and grounded warm interior fixtures.

Implementation priorities for this pass:

1. Give every large plane a readable, material-specific finish and physically plausible roughness; reserve metallic response for metal.
2. Add station-wide architectural rhythm (vault ribs, piers, ceiling services, framed shopfronts, fare control, platform edges) that holds up when the camera turns.
3. Use a small number of non-shadowing local practicals plus the existing preset-controlled directional shadows; emissive surfaces sell fixtures without adding a light per prop.
4. Let the player route remain the compositional spine: entrances, ticketing, platform and train connection must be obvious and collision-safe.
5. Give train windows, seat fabric, door framing and carriage thresholds real geometry and material variation, not just entrance-facing detail.
6. Preserve the project's Compatibility renderer and low preset. Do not add real-time reflections, volumetric fog, many shadow-casting lights or post effects without measuring cost.

## Constraints and review checklist

- All new maps in `assets/procedural/` are generated by the checked-in deterministic standard-library script `tools/generate_tung_chung_textures.py`; no user image or game screenshot was used as a texture.
- A good introduction camera is not evidence that the rest of the concourse works. Inspect the entrance, ticketing side, stair/ramp, platform, door threshold, both carriages, return view and every 360° turn.
- Verify every visible architectural addition has deliberately chosen collision/navigation behavior; decorative geometry may be non-colliding but must not suggest a traversable route.
- Review the same spaces at LOW, MEDIUM and HIGH and at 1280×720. Actual Intel Iris Xe performance remains a separate, unmeasured item.
- The uploaded references depict copyrighted game footage. They are visual analysis only; no copied assets, maps, logos, signage, characters or exact camera shot is shipped.

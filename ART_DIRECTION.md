# Art direction — Project Assassin

**Version:** 0.1 research-led proposal. This defines a target and guardrails; it is not a claim of completion, realism, or visual approval. The goal is an original, coherent stealth-action presentation with grounded contemporary environments and readable human silhouettes, using HITMAN: Codename 47 only as a high-level quality aspiration. Do not reproduce its models, maps, compositions, textures, UI, sound, or proprietary techniques.

## Visual promise

A believable fictional contemporary Hong Kong campaign: populated spaces with human-scale architecture, material-specific surfaces, motivated light, and distinct but coherent location identities. People should read as individual humans first and mission roles second; a role should be legible at play distance without turning every person into a color-coded icon. Environments should feel built and inhabited, not simply decorated with unrelated props. The image remains legible in motion at 1280×720 and in both normal play and Instinct.

## Style pillars

1. **Grounded, not documentary.** Use plausible scale, construction logic, locally researched visual cues and lived-in wear. The district and facility remain fictional. Do not imply that the concealed facility exists beneath a real religious/cultural landmark. Use respectful cultural review for landmark-adjacent depiction and avoid turning a sacred public figure into a gimmick or destructible target.
2. **Material truth.** Distinguish painted plaster, concrete, stone, glass, brushed metal, rubber, tile, paper, leather and textiles through shape, roughness, reflectance and restrained texture. Do not add noisy grunge uniformly. Albedo must not contain fake lighting/shadows; wear needs a plausible contact/weather story.
3. **Human variety with continuity.** Vary body build, facial structure, skin tone, age cues, hair silhouette, posture, and garment cut. Keep those features independent of occupation/outfit identity. Disguise identity is functional gameplay state; visual layers must not rewrite role permissions or persistence.
4. **Readable cinematic light.** Use warm/cool contrast and practical sources with protected shadow detail. Preserve face, garment, stairs, exits, clues and combat/stealth cues. Avoid excessive bloom, tinted darkness, flat ambient fill, and a forest of shadowed local lights.
5. **Quiet visual hierarchy.** Environment carries the normal-play image. UI and Instinct are reserved signals, not permanent outlines. Color never stands alone as the only permission or discovery cue.

## Palette and lighting language

- **Normal exploration:** restrained warm-neutral interiors, cooler shaded exteriors, naturally varied but low-chroma architecture; reserve saturated color for signage, service roles, mission accents and light sources.
- **Tung Chung/station:** cool mineral tile/metal/fabric foundation, warm kiosk/wood accents and controlled high-value signs; maintain existing original procedural map identity.
- **Market/commercial/harbour:** sun-warmed stone, muted painted shutters/awnings, weathered metals and modest local accent colors. Keep fictional signage legible and avoid invented text presented as authentic local language.
- **Ngong Ping/public landmark environs:** open-air daylight, stone/vegetation and calm material contrast; architectural/cultural review before elevating landmark detail. The secret facility interior has a separate fictional, restrained industrial language and must not visually assert a real subterranean space.
- **Hotel/office interiors:** warm practical pools against neutral surroundings, subtle reflective accents, layered sightlines and believable service/guest zones.
- **Instinct:** environmental chroma fades smoothly and moderately; only mission-authorized target/object overlays remain. Use distinct, accessible colors with a restrained pulse or edge/label cue. No generic silhouettes through walls; do not highlight unknown NPCs or secret content.

These are directional palette relationships, not fixed sampled real-world color values. Final colors are checked in game under the actual renderer/display pipeline.

## Character and garment principles

- Establish a consistent human scale and proportion guide before producing detailed figures. Preserve natural head/body proportions, distinct shoulders/waists/hips, hands/feet, neck/jaw, and facial planes; avoid featureless spheres, box limbs and visibly intersecting garments.
- Build a small reusable, rig-compatible base with intentional variation sets. Hair, brows, face and footwear require enough silhouette/shape to read in gameplay camera shots. Avoid a unique high-cost mesh for every NPC.
- Garments should have recognizable cut and layering: collars/lapels/seams, hems, cuffs, pockets, belts, closures, folds at articulation, and fabric-appropriate drape. Distinguish uniform types through cut, fit, accessories and material, not hue alone. Accessories must remain attached during movement and disguise changes.
- Skin is a non-metallic, moderately rough material. Cloth is matte/rough with subtle weave only where resolution supports it; polished leather, coated fabric and metal trims are different. Any subsurface effect is optional and renderer-gated; fallback materials must remain credible.
- Animation quality must be demonstrated in idle, walk, turn, crouch, interact, incapacitated/stunned and weapon/tool poses as applicable. No limb penetration, foot skating that dominates the shot, stiff mannequin gait, or animation-dependent loss of role/outfit markers.
- Civilian underwear replacement remains fully covering and non-revealing, including during animation, camera changes and outfit transitions.

## Environment principles

- Architecture follows a small kit of consistent wall, floor, trim, opening, railing, roof and stair modules, sized to player/camera/navigation needs. Avoid hollow facades, floating trims, impossible joins, paper-thin walls, repeated window grids without interior logic, and unwalkable decorative clutter.
- Sightlines, routes and mission interactions are designed first; art cannot block doors, NavMesh passages, line-of-sight, collision, disguises, NPC schedules, extraction, or facility traversability.
- Use focal composition and a foreground/midground/background depth structure. Add detail where the player can approach or read it; distant forms use silhouette/value grouping rather than expensive micro-detail.
- Dress spaces with purposeful furniture/props and restrained wear. Props have physical contact, plausible support, scale, collision policy and shared material vocabulary. Avoid clutter that obscures interactables.
- Distinct campaign districts share exposure, contrast, texture density, roughness conventions and UI treatment so the campaign reads as one game.

## Instinct and readability guardrails

The mission system, not the post shader, owns eligibility. Keep primary target discovery, mission completion, item usage, role permissions, distance, view/occlusion and secret discovery semantics intact. Smooth fade-in/out is a visual parameter only. Keep environmental desaturation separate from HUD; label the mode and provide a visible but discreet state indicator. Red/yellow/other colors must preserve existing semantics and be distinguishable with shape/icon/label where needed. Prohibit revealing all NPCs, undiscovered facility secrets, unknown routes, ordinary scenery, or arbitrary collectibles. Test each mission's existing exceptions rather than imposing one global highlight rule.

## Review gates

1. **Blockout gate:** correct scale, layout, silhouettes, traversability and mission readability; no detail pass before this.
2. **Material gate:** shared material swatches evaluated under neutral/warm/cool light and Instinct; no arbitrary per-mesh tuning.
3. **Human gate:** turnaround/front/side/back, outfit and disguise catalogue, animation states, face and close gameplay-distance review; consent/cultural sensitivity as appropriate.
4. **Campaign gate:** side-by-side equivalent-condition shots for the capture matrix in `RENDERING_PIPELINE.md`; inspect all named locations, player views and Instinct states.
5. **Gameplay gate:** manual walkthrough checks stealth routes, permissions, discovery, collisions, navigation, save/load and civilian coverage.
6. **Performance gate:** release-build route measurements on Windows 11/i5-1335U/16 GB/Iris Xe at 1280×720; record exact renderer, preset and frame-time distribution. CI is not target hardware.

A pass on headless tests is not a human visual sign-off. A partial selected-area improvement is not campaign completion. Report each gate as not run, failed, partial or passed and attach evidence.

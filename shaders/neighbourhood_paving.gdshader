shader_type spatial;
render_mode diffuse_burley;

// Project-original, inexpensive world-space paving; no textures or extra lights.
uniform vec4 paving_color : source_color = vec4(0.38, 0.38, 0.35, 1.0);
varying vec2 pavement_position;

void vertex() {
 pavement_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
 vec2 tile = abs(fract(pavement_position * 0.5) - vec2(0.5));
 float joint = step(0.486, max(tile.x, tile.y));
 vec2 cell = floor(pavement_position * 0.5);
 float variation = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
 ALBEDO = paving_color.rgb * (0.94 + variation * 0.12) * (1.0 - joint * 0.19);
 ROUGHNESS = 0.95;
}

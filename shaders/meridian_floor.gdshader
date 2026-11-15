shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Original, texture-free world-space finish. Large slabs keep a consistent
// scale without hundreds of extra floor meshes or per-object texture imports.
varying vec3 world_position;

void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
 vec2 p = world_position.xz;
 bool upstairs = world_position.y > 3.0;
 bool dining = world_position.x < -12.0 && world_position.z < -6.0;
 if (upstairs || dining) {
  // Broad timber boards with quiet tonal variation, not high-contrast stripes.
  float board = floor(p.y * 1.35);
  float variation = sin(board * 3.13) * 0.035 + sin(p.x * 2.0 + board) * 0.012;
  float seam = 1.0 - smoothstep(0.0, 0.035, min(fract(p.y * 1.35), 1.0 - fract(p.y * 1.35)));
  vec3 wood = vec3(0.35, 0.255, 0.19) + vec3(variation);
  ALBEDO = mix(wood, wood * 0.68, seam * 0.6);
  ROUGHNESS = 0.68;
 } else {
  // Warm honed stone, with fine grout and restrained cloudy variation.
  vec2 tile = p * 0.67;
  vec2 edge = min(fract(tile), 1.0 - fract(tile));
  float joint = 1.0 - smoothstep(0.0, 0.012, min(edge.x, edge.y));
  float cloud = sin(p.x * 1.15 + sin(p.y * 0.7)) * sin(p.y * 0.9) * 0.025;
  vec3 stone = vec3(0.48, 0.46, 0.40) + vec3(cloud);
  ALBEDO = mix(stone, stone * 0.75, joint * 0.75);
  ROUGHNESS = 0.57;
  SPECULAR = 0.34;
 }
}

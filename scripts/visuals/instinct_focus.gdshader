shader_type canvas_item;

// A restrained, renderer-compatible screen-space focus grade. This shader
// changes only the image's color; it never discovers or draws world objects.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float focus_amount : hint_range(0.0, 1.0) = 0.0;
uniform float desaturation : hint_range(0.0, 1.0) = 0.48;
uniform float exposure_scale : hint_range(0.75, 1.0) = 0.96;

void fragment() {
    vec4 source = texture(screen_texture, SCREEN_UV);
    float luminance = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 muted = mix(source.rgb, vec3(luminance), focus_amount * desaturation);
    muted *= mix(1.0, exposure_scale, focus_amount);
    COLOR = vec4(muted, source.a);
}

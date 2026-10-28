shader_type canvas_item;
render_mode blend_mix;
// Neutral ENGINE phase misalignment, original review shader.
// Mathematically shares #411's bounded radial lens technique; no character motif.
uniform float phase_progress : hint_range(0.0, 1.0) = 0.49;
uniform float opacity_budget : hint_range(0.0, 1.0) = 0.68;
uniform vec4 copper_tint : source_color = vec4(0.95, 0.72, 0.36, 1.0);
uniform vec4 harmonic_tint : source_color = vec4(0.62, 0.91, 0.88, 1.0);
void fragment() {
    vec2 point = (UV - vec2(0.5)) * 2.0;
    vec2 stretch = vec2(point.x, point.y * 1.35);
    float radius = length(stretch);
    float azimuth = atan(stretch.y, stretch.x);
    float ring = exp(-pow((radius - 0.48) * 13.0, 2.0));
    float misalignment = 0.5 + 0.5 * sin(azimuth * 8.0 + phase_progress * 5.0);
    float interference = pow(misalignment, 7.0);
    float rim = 1.0 - smoothstep(0.79, 1.04, radius);
    float alpha = clamp((0.16 * ring + 0.10 * interference * exp(-radius * radius * 4.0)) * opacity_budget * rim, 0.0, 0.23);
    float mix_amount = clamp(0.25 + 0.40 * interference, 0.0, 1.0);
    COLOR = vec4(mix(copper_tint.rgb, harmonic_tint.rgb, mix_amount), alpha);
}

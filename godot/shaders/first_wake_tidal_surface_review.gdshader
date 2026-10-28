shader_type canvas_item;
render_mode unshaded;

// Review-only layered water material. Drawn beneath the real RigidBody2D ship.
// No buoyancy, collision, time-of-day or ocean navigation authority.
uniform vec4 deep_color : source_color = vec4(0.035, 0.16, 0.23, 1.0);
uniform vec4 upper_color : source_color = vec4(0.16, 0.39, 0.47, 1.0);
uniform vec4 foam_color : source_color = vec4(0.62, 0.86, 0.82, 1.0);
uniform vec4 amber_color : source_color = vec4(0.89, 0.71, 0.46, 1.0);
uniform float motion_scale : hint_range(0.0, 1.0) = 0.45;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.46;

void fragment() {
    vec2 p = UV;
    float t = TIME * motion_scale;
    float near_depth = smoothstep(0.08, 0.98, p.y);
    // Ocean surface reads as compressed near-horizontal swell bands.
    // Break the bands with lateral current, rather than diagonal glitter tiles.
    float fold = sin(p.x * 18.0 + p.y * 12.0 + t * 1.15);
    float swell = sin(p.y * 79.0 + sin(p.x * 15.0 + t) * 1.1 - t * 2.1);
    float ripple = sin(p.y * 192.0 + sin(p.x * 28.0 - t * 0.6) * 0.65 + t * 3.2);
    float chop = 0.50 + 0.36 * swell + 0.14 * ripple;
    vec3 water = mix(upper_color.rgb, deep_color.rgb, near_depth * 0.83 + 0.11);
    water += 0.055 * fold * (1.0 - near_depth * 0.45);
    float glint_column = exp(-pow((p.x - 0.79) / (0.065 + p.y * 0.30), 2.0));
    float glints = smoothstep(0.76, 0.96, chop) * glint_column;
    water = mix(water, amber_color.rgb, glints * specular_strength * (1.0 - near_depth * 0.48));
    float streaks = smoothstep(0.82, 0.97, chop);
    water = mix(water, foam_color.rgb, streaks * 0.13 * (0.3 + near_depth));
    float horizon_foam = (1.0 - smoothstep(0.0, 0.047, p.y)) * (0.38 + 0.12 * fold);
    water = mix(water, foam_color.rgb, horizon_foam);
    COLOR = vec4(clamp(water, vec3(0.0), vec3(1.0)), 1.0);
}

shader_type canvas_item;
render_mode blend_mix;
// Noncanonical 2D adapter for ORIGINAL source-controlled PNGs.
// No new terrain/world bathymetry, time, state, input or game collision.
uniform sampler2D micro_detail : filter_nearest, repeat_enable;
uniform sampler2D region_detail : filter_nearest, repeat_enable;
uniform int surface_family = 0; // 0 = water, 1 = existing planter foliage.
uniform float material_strength : hint_range(0.0, 1.0) = 0.65;
uniform float mask_quality : hint_range(0.0, 1.0) = 1.0;
void fragment() {
    vec2 uv = UV;
    // Two separated texture frequencies break the old 128px stretched patch.
    vec3 grain = texture(micro_detail, uv * vec2(1.75, 1.18)).rgb;
    vec3 macro = texture(region_detail, uv * vec2(0.65, 0.80)).rgb;
    float micro = grain.g * 0.70 + grain.r * 0.30;
    float regional = macro.b * 0.60 + macro.r * 0.40;
    // Soft, irregular *local* footprint: zero at every patch rectangle edge.
    // Irregularity bends the interior fade, never creates a gameplay coast.
    float width_noise = (regional - 0.5) * 0.065;
    float x_mask = smoothstep(0.03 + width_noise, 0.30 + width_noise, uv.x)
        * (1.0 - smoothstep(0.70 - width_noise, 0.97 - width_noise, uv.x));
    float y_mask = smoothstep(0.02, 0.24, uv.y)
        * (1.0 - smoothstep(0.75, 0.99, uv.y));
    float footprint = x_mask * y_mask;
    float grain_contrast = mix(0.80, 1.20, micro);
    vec3 water_color = mix(vec3(0.17, 0.42, 0.46),
        vec3(0.26, 0.53, 0.55), regional);
    vec3 leaf_color = mix(vec3(0.18, 0.35, 0.21),
        vec3(0.38, 0.51, 0.29), regional);
    vec3 tone = mix(water_color, leaf_color, float(surface_family));
    float group_shape = 1.0;
    if (surface_family == 1) {
        // Clustered material—not a full rectangular painted planter stamp.
        vec2 ellipse = (uv - vec2(0.50, 0.53)) * vec2(1.38, 1.03);
        group_shape = 1.0 - smoothstep(0.22, 0.72, length(ellipse)
            + (macro.g - 0.5) * 0.16);
    }
    float intensity = (surface_family == 1 ? 0.56 : 0.30);
    // Reduced-quality bypass uses the original stage beneath the adapter.
    float alpha = clamp(footprint * group_shape * grain_contrast * intensity
        * material_strength * mask_quality, 0.0, 0.45);
    COLOR = vec4(tone * grain_contrast, alpha);
}

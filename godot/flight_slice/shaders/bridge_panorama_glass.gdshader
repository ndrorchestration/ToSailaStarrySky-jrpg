shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Public-safe artistic reflection study. No refraction, pressure rating,
// reflected environment probe or hidden ship ability is represented here.
uniform vec4 glass_tint : source_color = vec4(0.43, 0.65, 0.71, 1.0);
uniform float face_alpha : hint_range(0.0, 0.50) = 0.13;
uniform float edge_alpha : hint_range(0.0, 0.35) = 0.12;
uniform float highlight_gain : hint_range(0.0, 1.0) = 0.30;

void fragment() {
    float facing = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
    float rim = pow(1.0 - facing, 3.2);
    vec3 pane = mix(glass_tint.rgb, COLOR.rgb, 0.30);
    ALBEDO = pane;
    ALPHA = clamp(face_alpha + COLOR.a * 0.09 + edge_alpha * rim, 0.05, 0.49);
    ROUGHNESS = 0.18 + 0.10 * (1.0 - highlight_gain);
    SPECULAR = 0.25 + highlight_gain * 0.29;
    METALLIC = 0.04;
    EMISSION = pane * (0.008 + 0.022 * rim);
}

shader_type canvas_item;
render_mode blend_mix;

// Original low-cost radial lens. Review art only: not HDR bloom/postprocessing.
uniform vec4 core_tint : source_color = vec4(0.73, 0.68, 1.0, 1.0);
uniform vec4 accent_tint : source_color = vec4(1.0, 0.93, 0.8, 1.0);
uniform float phase_progress : hint_range(0.0, 1.0) = 0.29;
uniform float energy : hint_range(0.0, 1.0) = 0.75;
uniform int motif = 0;

void fragment() {
    vec2 v = (UV - vec2(0.5)) * 2.0;
    float r = length(v);
    float angle = atan(v.y, v.x);
    float fog = exp(-r * r * 5.5);
    float halo = exp(-pow((r - 0.57) * 7.0, 2.0));
    float filaments = 0.0;
    if (motif == 0) {
        // Spirit: gentle radial pathways converging into an auroral center.
        filaments = pow(0.5 + 0.5 * cos(angle * 5.0 + r * 4.0 - phase_progress * 1.9), 8.0);
    } else if (motif == 1) {
        // Water: horizontally stretched interference bands, not fire or shards.
        filaments = pow(0.5 + 0.5 * sin(v.y * 23.0 + sin(v.x * 7.0) * 1.2 - phase_progress * 3.0), 6.0);
    } else if (motif == 2) {
        // Earth: faceted fourfold crystalline refraction.
        filaments = pow(abs(cos(angle * 4.0 + r * 2.0)), 12.0);
    } else if (motif == 3) {
        // Fire: vertical plume texture without strobing or full-frame exposure.
        filaments = pow(0.5 + 0.5 * sin(v.x * 16.0 + v.y * 13.0 + phase_progress * 5.0), 7.0);
    } else {
        // Air: asymmetrical aerodynamic shear, distinct from the tidal bands.
        filaments = pow(0.5 + 0.5 * sin(angle * 3.0 + r * 19.0 - phase_progress * 3.3), 8.0);
    }
    float edge = 1.0 - smoothstep(0.72, 1.02, r);
    float blend_t = clamp(0.33 + 0.43 * filaments, 0.0, 1.0);
    vec3 tone = mix(core_tint.rgb, accent_tint.rgb, blend_t);
    float opacity = clamp((fog * 0.13 + halo * 0.24 + filaments * 0.11 * fog) * energy * edge, 0.0, 0.32);
    COLOR = vec4(tone, opacity);
}

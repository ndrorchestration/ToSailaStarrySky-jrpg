shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

// Purely visual local-ocean study. Not a buoyancy or physical-water model.
uniform vec4 deep_water : source_color = vec4(0.032, 0.176, 0.245, 1.0);
uniform vec4 shallow_water : source_color = vec4(0.115, 0.405, 0.467, 1.0);
uniform vec4 foam_tint : source_color = vec4(0.68, 0.86, 0.83, 1.0);
uniform float wave_height : hint_range(0.0, 0.6) = 0.12;
uniform float wave_speed : hint_range(0.0, 2.0) = 0.45;
uniform float foam_strength : hint_range(0.0, 1.0) = 0.16;
varying vec2 local_xz;
varying float crest;

void vertex() {
    local_xz = VERTEX.xz;
    float p = VERTEX.x * 0.30 + VERTEX.z * 0.22 + TIME * wave_speed;
    float q = VERTEX.x * -0.17 + VERTEX.z * 0.36 - TIME * wave_speed * 0.76;
    float a = sin(p);
    float b = sin(q);
    VERTEX.y += wave_height * (a + 0.48 * b);
    crest = a * 0.65 + b * 0.35;
    float dx = wave_height * (0.30 * cos(p) - 0.0816 * cos(q));
    float dz = wave_height * (0.22 * cos(p) + 0.1728 * cos(q));
    NORMAL = normalize(vec3(-dx, 1.0, -dz));
}

void fragment() {
    float variation = 0.5 + 0.5 * sin(local_xz.x * 0.57 + TIME * 0.36)
                              * cos(local_xz.y * 0.43 - TIME * 0.27);
    float lit_crest = smoothstep(0.28, 0.90, crest);
    vec3 base = mix(deep_water.rgb, shallow_water.rgb, 0.28 + 0.42 * variation);
    ALBEDO = mix(base, foam_tint.rgb, lit_crest * foam_strength);
    METALLIC = 0.04;
    ROUGHNESS = mix(0.29, 0.43, variation);
    SPECULAR = 0.75;
    EMISSION = foam_tint.rgb * lit_crest * 0.035;
}

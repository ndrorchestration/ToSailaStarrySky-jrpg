shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform vec3 mineral_tint = vec3(0.55, 0.57, 0.52);
uniform float wetness = 0.0;
varying vec3 world_position;
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
    // Controlled, subtle color noise: original rock surfaces remain legible
    // without texture downloads, glowing edges, transparency or animation.
    float grain = 0.5 + 0.5 * sin(world_position.x * 3.13
        + world_position.z * 2.41 + world_position.y * 1.71);
    float strata = 0.5 + 0.5 * sin(world_position.y * 6.3
        + world_position.x * 0.44 - world_position.z * 0.26);
    float weathering = mix(0.85, 1.05, grain * 0.63 + strata * 0.37);
    ALBEDO = COLOR.rgb * mineral_tint * weathering;
    ROUGHNESS = mix(0.95, 0.76, wetness);
    SPECULAR = mix(0.10, 0.22, wetness);
}

shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform float study_time = 0.0;
uniform float motion_scale = 1.0;
uniform sampler2D foliage_microdetail : filter_linear_mipmap, repeat_enable;
uniform float texture_detail_strength : hint_range(0.0, 1.0) = 0.65;
varying vec3 world_position;
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    // Local-height weighting anchors each frond at its root.
    float flex = clamp(VERTEX.y, 0.0, 1.0);
    float phase = study_time * 1.3 + world_position.x * 0.47 + world_position.z * 0.31;
    VERTEX.x += sin(phase) * flex * 0.043 * motion_scale;
    VERTEX.z += cos(phase * 0.83) * flex * 0.026 * motion_scale;
}
void fragment() {
    // Fixed tileable authored foliage microtexture; no alpha sorting,
    // emissive foliage or screen-space noise.
    float variation = 0.5 + 0.5 * sin(world_position.x * 1.43 + world_position.z * 0.93);
    vec3 forest_floor = mix(vec3(0.25, 0.34, 0.23), vec3(0.47, 0.55, 0.32), variation);
    vec3 fiber=texture(foliage_microdetail,
        world_position.xz*0.62+world_position.y*0.17).rgb;
    ALBEDO = COLOR.rgb * forest_floor * mix(1.0,
        0.79+fiber.g*0.45,texture_detail_strength);
    ROUGHNESS = 0.96;
    SPECULAR = 0.08;
}

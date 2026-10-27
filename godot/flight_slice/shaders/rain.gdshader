shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
// Bounded translucent rain impostor; opt-in and hidden for reduced motion.
uniform float study_time = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
void vertex() {
    // Phase-stagger 112 existing instances rather than spawning particles.
    float index = float(INSTANCE_ID);
    VERTEX.y -= mod(study_time * 7.0 + index * 0.77, 12.0);
    VERTEX.x += sin(study_time * 0.31 + index * 1.31) * 0.16;
}
void fragment() {
    float taper = smoothstep(0.0, 0.24, UV.y)
        * (1.0 - smoothstep(0.76, 1.0, UV.y));
    ALBEDO = vec3(0.67, 0.79, 0.87);
    ALPHA = 0.12 * opacity * taper;
}

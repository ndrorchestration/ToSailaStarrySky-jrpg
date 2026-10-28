shader_type canvas_item;
// Subtle screen-space color integration for STATIC creator-source cutouts only.
// No source pixel repaint, sprite animation, anatomy generation or physics change.
uniform float sunset_warmth : hint_range(0.0, 0.5) = 0.23;
uniform float lower_ambient : hint_range(0.0, 0.5) = 0.12;
void fragment() {
    vec4 source = texture(TEXTURE, UV);
    // Golden-hour light is strongest on upper-left costume and hair edges.
    float left_light = pow(clamp(1.0 - UV.x, 0.0, 1.0), 1.4);
    float upper_light = 1.0 - smoothstep(0.05, 0.85, UV.y);
    float beam = left_light * upper_light;
    vec3 sun = vec3(1.13, 1.055, 0.91);
    vec3 light = mix(vec3(1.0), sun, clamp(beam * sunset_warmth, 0.0, 1.0));
    // Very mild blue coastal bounce at the boots; keep creator colors recognizable.
    float low = smoothstep(0.38, 0.99, UV.y);
    light *= mix(vec3(1.0), vec3(0.86, 0.94, 1.03), low * lower_ambient);
    COLOR = vec4(clamp(source.rgb * light, vec3(0.0), vec3(1.0)), source.a);
}

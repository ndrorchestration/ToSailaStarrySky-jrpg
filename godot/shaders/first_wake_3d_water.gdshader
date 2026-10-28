shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

// First Wake experimental real 3D water: low-poly displaced wave surface.
// Standalone 3D visual study; never affects original 2D water-contact physics.
uniform vec4 deep_water : source_color = vec4(0.022, 0.132, 0.218, 1.0);
uniform vec4 shallow_water : source_color = vec4(0.115, 0.325, 0.378, 1.0);
uniform vec4 sun_reflection : source_color = vec4(0.92, 0.68, 0.40, 1.0);
uniform float amplitude : hint_range(0.0, 0.3) = 0.085;
uniform float wave_scale : hint_range(0.2, 4.0) = 1.45;
uniform float wave_speed : hint_range(0.0, 3.0) = 0.65;

varying vec3 world_space;
varying float crest;

void vertex() {
    float a = sin(VERTEX.x * wave_scale * 0.72 + TIME * wave_speed);
    float b = cos(VERTEX.z * wave_scale * 0.86 - TIME * wave_speed * 0.76);
    float small = sin((VERTEX.x + VERTEX.z) * 2.31 + TIME * 0.43);
    VERTEX.y += (a * 0.58 + b * 0.35 + small * 0.07) * amplitude;
    crest = (a + b) * 0.5;
    world_space = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float flow = sin(world_space.x * 0.18 + TIME * 0.18) *
                 cos(world_space.z * 0.22 - TIME * 0.13);
    float depth_mix = clamp(0.34 + 0.20 * flow + crest * 0.15, 0.0, 1.0);
    vec3 water = mix(deep_water.rgb, shallow_water.rgb, depth_mix);
    float sparkle = pow(max(sin(world_space.x * 2.2 + TIME * 0.55) *
                            cos(world_space.z * 1.7 + TIME * 0.40), 0.0), 15.0);
    water += sun_reflection.rgb * sparkle * 0.09;
    ALBEDO = water;
    ROUGHNESS = 0.22;
    METALLIC = 0.06;
    SPECULAR = 0.66;
}

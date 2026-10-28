shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

// Original staged 128x128 water ripple art from PR #476 / source manifest.
// Atmospheric shader is an original opt-in interpretation, not source shader.
uniform sampler2D ripple_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 deep_water : source_color = vec4(0.045, 0.185, 0.242, 1.0);
uniform vec4 shallow_water : source_color = vec4(0.126, 0.392, 0.442, 1.0);
uniform vec4 sunset_reflection : source_color = vec4(0.95, 0.63, 0.31, 1.0);
uniform float wave_height : hint_range(0.0, 0.15) = 0.065;
uniform float current_speed : hint_range(0.0, 2.0) = 0.55;
uniform float surface_brightness : hint_range(0.0, 2.0) = 0.9;

varying vec3 sea_world;

void vertex() {
    float wave_a = sin(VERTEX.x * 0.17 + TIME * current_speed) * wave_height;
    float wave_b = sin(VERTEX.z * 0.24 - TIME * current_speed * 0.71) * wave_height * 0.45;
    VERTEX.y += wave_a + wave_b;
    sea_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 tile = sea_world.xz * 0.12;
    vec2 flow = vec2(TIME * current_speed * 0.045, -TIME * current_speed * 0.025);
    vec3 ripple_a = textureLod(ripple_tex, tile + flow, 1.2).rgb;
    vec3 ripple_b = textureLod(ripple_tex, tile * 1.41 - flow * 0.65, 1.0).rgb;
    float detail = dot(ripple_a, vec3(0.299, 0.587, 0.114));
    float secondary = dot(ripple_b, vec3(0.299, 0.587, 0.114));
    float current = sin(sea_world.x * 0.19 + sea_world.z * 0.11 + TIME * 0.33);
    float tint = clamp(detail * 0.31 + secondary * 0.17 + current * 0.10 + 0.31, 0.0, 1.0);
    vec3 albedo = mix(deep_water.rgb, shallow_water.rgb, tint);
    float bright = pow(max(detail * secondary, 0.0), 3.0);
    float sunband = pow(max(0.0, sin(sea_world.x * 0.032 + TIME * 0.10)), 18.0);
    albedo += sunset_reflection.rgb * sunband * (bright * 0.17 + 0.025);
    ALBEDO = albedo * surface_brightness;
    ROUGHNESS = mix(0.23, 0.42, 1.0 - tint);
    METALLIC = 0.13;
    SPECULAR = 0.82;
    // Micro-normal from two source textures; no particle or fluid simulation.
    NORMAL = normalize(vec3((detail - secondary) * 0.15, 1.0, (secondary - 0.50) * 0.12));
    EMISSION = sunset_reflection.rgb * bright * sunband * 0.045;
}

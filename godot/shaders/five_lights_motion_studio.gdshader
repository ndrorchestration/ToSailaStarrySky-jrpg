shader_type canvas_item;
// Procedural harbor nocturne for a bounded artist-review scene.
// This shader has no authority over physics or character/sprite source pixels.
uniform bool reduced_motion = false;
float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
    vec2 uv = UV;
    float t = reduced_motion ? 0.0 : TIME * 0.10;
    vec3 sky = mix(vec3(0.008, 0.019, 0.043), vec3(0.067, 0.115, 0.162), smoothstep(0.05, 0.65, uv.y));
    vec2 stars = floor(uv * vec2(189.0, 94.0));
    float glint = step(0.995, hash21(stars)) * (1.0 - smoothstep(0.32, 0.56, uv.y));
    sky += glint * vec3(0.62, 0.72, 0.82);
    float veil_y = 0.19 + 0.027 * sin(uv.x * 9.0 + t * 0.3);
    float veil = exp(-pow((uv.y - veil_y) * 16.0, 2.0));
    sky += veil * vec3(0.015, 0.052, 0.076);
    float moon = exp(-length((uv - vec2(0.81, 0.19)) * vec2(1.75, 1.0)) * 6.9);
    sky += vec3(0.078, 0.106, 0.145) * moon;
    float bank = exp(-pow((uv.y - 0.425) * 22.0, 2.0));
    sky += bank * vec3(0.040, 0.052, 0.058);
    float wave = sin(uv.x * 79.0 + uv.y * 41.0 + t) * sin(uv.y * 186.0 + t * 0.4);
    vec3 water = vec3(0.030, 0.081, 0.123) + wave * vec3(0.008, 0.016, 0.023);
    vec3 scene = mix(sky, water, smoothstep(0.43, 0.50, uv.y));
    float plank = 1.0 - smoothstep(0.012, 0.035, abs(fract(uv.y * 19.0) - 0.5));
    float grain = (hash21(floor(uv * vec2(210.0, 60.0))) - 0.5) * 0.016;
    vec3 wood = mix(vec3(0.105, 0.088, 0.076), vec3(0.15, 0.118, 0.088), uv.y) + vec3(grain - plank * 0.029);
    scene = mix(scene, wood, smoothstep(0.65, 0.685, uv.y));
    for (int k = 0; k < 5; k++) {
        float center = 0.14 + float(k) * 0.18;
        float dsq = pow((uv.x - center) * 5.5, 2.0) + pow((uv.y - 0.68) * 5.7, 2.0);
        scene += vec3(0.065, 0.049, 0.033) * exp(-dsq * 2.7);
    }
    float lantern_left = exp(-pow((uv.x - 0.036) * 7.0, 2.0) - pow((uv.y - 0.56) * 5.0, 2.0));
    float lantern_right = exp(-pow((uv.x - 0.965) * 7.0, 2.0) - pow((uv.y - 0.56) * 5.0, 2.0));
    scene += vec3(0.175, 0.090, 0.029) * (lantern_left + lantern_right);
    float radius = length((uv - 0.5) * vec2(1.3, 1.05));
    scene *= 1.0 - 0.26 * smoothstep(0.35, 0.78, radius);
    COLOR = vec4(scene, 1.0);
}

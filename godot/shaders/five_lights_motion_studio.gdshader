shader_type canvas_item;
// Isolated night-harbor presentation; does not change any actor pixels.
uniform bool reduced_motion = false;
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void fragment() {
    vec2 uv = UV;
    vec3 c = mix(vec3(0.011,0.027,0.058), vec3(0.055,0.101,0.16), smoothstep(0.0,0.8,uv.y));
    c += vec3(0.07,0.11,0.17) * exp(-length((uv-vec2(0.77,0.18))*vec2(1.6,1.0))*6.0);
    float star = step(0.996, hash21(floor(uv*vec2(170.0,90.0)))) * (1.0-smoothstep(0.3,0.5,uv.y));
    c += star*vec3(0.65,0.71,0.8);
    float t = reduced_motion ? 0.0 : TIME*0.15;
    float wave = sin(uv.x*74.0 + uv.y*39.0 + t)*sin(uv.y*175.0);
    c = mix(c, vec3(0.03,0.08,0.12)+wave*vec3(0.013,0.023,0.04),smoothstep(0.50,0.56,uv.y));
    float seam = 1.0-smoothstep(0.01,0.03,abs(fract(uv.y*25.0)-0.5));
    c = mix(c, vec3(0.11,0.096,0.089)-seam*0.023,smoothstep(0.59,0.63,uv.y));
    float glow = exp(-pow((uv.x-0.04)*7.0,2.0)-pow((uv.y-0.51)*5.0,2.0))
      + exp(-pow((uv.x-0.96)*7.0,2.0)-pow((uv.y-0.51)*5.0,2.0));
    c += vec3(0.16,0.08,0.023)*glow;
    COLOR = vec4(c,1.0);
}

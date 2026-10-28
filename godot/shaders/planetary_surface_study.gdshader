shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// NONCANON P2 material: strength 0 is same-shader visual baseline.
// World-space hash noise avoids per-cube-face UV seams and banded waves.
// Nothing displaces vertices or authors physical terrain.
uniform float effect_strength : hint_range(0.0, 1.0) = 0.0;
uniform int surface_family = 0; // 0=base, 1=snow, 2=sand, 3=wet soil
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform vec3 global_wind = vec3(0.7,0.17,-0.69);
varying vec3 planet_position;

float hash3(vec3 p) {
    return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);
}
float value_noise(vec3 p) {
    vec3 cell=floor(p);
    vec3 f=fract(p);
    f=f*f*(3.0-2.0*f);
    float n000=hash3(cell);
    float n100=hash3(cell+vec3(1.0,0.0,0.0));
    float n010=hash3(cell+vec3(0.0,1.0,0.0));
    float n110=hash3(cell+vec3(1.0,1.0,0.0));
    float n001=hash3(cell+vec3(0.0,0.0,1.0));
    float n101=hash3(cell+vec3(1.0,0.0,1.0));
    float n011=hash3(cell+vec3(0.0,1.0,1.0));
    float n111=hash3(cell+vec3(1.0,1.0,1.0));
    float near_z=mix(mix(n000,n100,f.x),mix(n010,n110,f.x),f.y);
    float far_z=mix(mix(n001,n101,f.x),mix(n011,n111,f.x),f.y);
    return mix(near_z,far_z,f.z);
}

void vertex() {
    planet_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec3 base = COLOR.rgb;
    float strength = clamp(effect_strength,0.0,1.0);
    vec3 wind=normalize(global_wind);
    vec3 sample_point=planet_position+wind*0.003;
    float broad=value_noise(sample_point*29.0);
    float fine=value_noise(sample_point*108.0);
    vec3 result_color = base;
    float roughness = 0.87;
    if (surface_family == 1) {
        // Natural irregular crust variation: deliberately low contrast.
        float frost=0.945+0.065*broad+0.025*fine;
        result_color = mix(base,base*frost,strength);
        roughness = mix(roughness,0.82,strength);
    } else if (surface_family == 2) {
        // Grain impression without repetitive sinusoidal bands.
        float sand=0.89+0.11*broad+0.025*fine;
        result_color = mix(base,base*sand,strength*0.8);
        roughness = mix(roughness,0.91,strength);
    } else if (surface_family == 3) {
        float damp = clamp(wetness,0.0,1.0)*strength;
        result_color = mix(base,base*(0.58+0.075*broad),damp);
        roughness = mix(roughness,0.52,damp);
    }
    ALBEDO = result_color;
    ROUGHNESS = roughness;
    METALLIC = 0.02;
}

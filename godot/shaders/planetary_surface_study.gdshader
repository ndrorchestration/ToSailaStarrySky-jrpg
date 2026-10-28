shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// ISOLATED P2: same shader with strength 0 gives an exact within-run baseline.
// No displacement; all surface positions and collision remain outside material.
uniform float effect_strength : hint_range(0.0, 1.0) = 0.0;
uniform int surface_family = 0; // 0=base, 1=snow, 2=sand, 3=wet ground
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform vec3 global_wind = vec3(0.7,0.17,-0.69);
varying vec3 planet_position;

void vertex() {
    planet_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec3 base = COLOR.rgb;
    float strength = clamp(effect_strength,0.0,1.0);
    vec3 w = normalize(global_wind);
    // Evaluated in one shared planet-space frame, independent of cube-face UV.
    float crust = 0.5 + 0.5*sin(dot(planet_position,w)*124.0 +
        sin(dot(planet_position,vec3(0.6,-0.3,0.74))*49.0)*0.65);
    float grit = 0.5 + 0.5*sin(dot(planet_position,vec3(0.31,0.79,-0.53))*188.0);
    vec3 result_color = base;
    float roughness = 0.87;
    if (surface_family == 1) {
        float snow_variation = mix(0.93,1.055,crust*0.67+grit*0.33);
        result_color = mix(base,base*snow_variation,strength);
        roughness = mix(roughness,0.81,strength);
    } else if (surface_family == 2) {
        float ripple = mix(0.81,1.04,crust);
        result_color = mix(base,base*ripple,strength*0.8);
        roughness = mix(roughness,0.91,strength);
    } else if (surface_family == 3) {
        float damp = clamp(wetness,0.0,1.0)*strength;
        result_color = mix(base,base*(0.55+0.14*crust),damp);
        roughness = mix(roughness,0.48,damp);
    }
    ALBEDO = result_color;
    ROUGHNESS = roughness;
    METALLIC = 0.02;
}

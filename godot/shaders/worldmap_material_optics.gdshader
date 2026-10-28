shader_type spatial;
render_mode diffuse_burley, cull_disabled;

// NONCANON native globe local-3D surface P0 optics study. Original native
// terrain vertex colors, mesh geometry and water surfaces remain authoritative.
uniform int surface_mode = 0; // 0 reference, 1 sand, 2 snow, 3 rainy ground
uniform float optics_strength = 0.0;
uniform float rain_intensity = 0.0;
uniform bool low_quality = false;
uniform vec2 wind_tangent = vec2(0.8, 0.6); // x east, y north
uniform vec3 sun_direction = vec3(0.65, 0.43, -0.70);
varying vec3 local_ground_pos;
varying vec3 normal_world;

float ground_hash(vec2 p) {
    return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float ground_noise(vec2 p) {
    vec2 i=floor(p), f=fract(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(ground_hash(i),ground_hash(i+vec2(1.0,0.0)),f.x),
        mix(ground_hash(i+vec2(0.0,1.0)),ground_hash(i+vec2(1.0,1.0)),f.x),f.y);
}
void vertex() {
    local_ground_pos=VERTEX;
    normal_world=normalize(mat3(MODEL_MATRIX)*NORMAL);
}
void fragment() {
    // Preserve Cart.sample vertex colors (and the original shade) before
    // applying any optional material effects, no climate-driven repainting.
    ALBEDO=COLOR.rgb;
    ROUGHNESS=0.89;
    SPECULAR=0.11;
    METALLIC=0.02;
    float strength=low_quality ? 0.0 : clamp(optics_strength,0.0,1.0);
    if (strength > 0.001 && surface_mode != 0) {
        vec2 p=local_ground_pos.xz;
        // Globe mode-4 local frame: X east and negative Z north.
        vec2 w=normalize(vec2(wind_tangent.x,-wind_tangent.y));
        vec2 across=vec2(-w.y,w.x);
        float noise_a=ground_noise(p*2.2);
        float noise_b=ground_noise(p*9.0);
        float fine_lod=1.0-smoothstep(0.55,1.8,
            max(fwidth(p.x*56.0),fwidth(p.y*56.0)));
        vec3 n=normalize(normal_world);
        float warp=(noise_a-0.5)*2.0+(noise_b-0.5)*0.38;
        if (surface_mode == 1 || surface_mode == 2) {
            bool packed_snow=surface_mode==2;
            float frequency=packed_snow ? 23.0 : 35.0;
            float phase=dot(p,across)*frequency+warp*2.4;
            float ripple_lod=1.0-smoothstep(0.7,2.4,fwidth(phase));
            float patch=smoothstep(0.25,0.73,ground_noise(p*5.1));
            vec3 cross_grad=vec3(across.x,0.0,across.y);
            float strength_n=packed_snow ? 0.037 : 0.075;
            vec3 grad=cross_grad*cos(phase)*ripple_lod*patch*strength_n;
            vec2 cell=floor(p*56.0);
            vec3 tiny=vec3(ground_hash(cell+vec2(7.0,3.0))-0.5,
                0.0,ground_hash(cell+vec2(4.0,19.0))-0.5);
            grad+=tiny*fine_lod*(packed_snow ? 0.018 : 0.031);
            grad-=n*dot(n,grad);
            vec3 opt_normal=normalize(n-grad*strength);
            NORMAL=normalize(mat3(VIEW_MATRIX)*opt_normal);
            float light=clamp(dot(opt_normal,normalize(sun_direction)),0.0,1.0);
            float scatter=(packed_snow ? 0.975 : 0.953)+
                (packed_snow ? 0.04 : 0.085)*smoothstep(0.08,0.94,light);
            ALBEDO*=mix(1.0,scatter+sin(phase)*0.016*patch,strength);
            ROUGHNESS=mix(0.89,packed_snow ? 0.84 : 0.72,strength);
            SPECULAR=mix(0.11,packed_snow ? 0.16 : 0.21,strength);
            RIM=strength*(packed_snow ? 0.095 : 0.068);
            RIM_TINT=packed_snow ? 0.52 : 0.62;
            // Deterministic, sparse and intentionally low-energy.
            float sparkle=smoothstep(0.995,0.999,
                ground_hash(cell+vec2(23.0,41.0)));
            vec3 light_view=normalize(mat3(VIEW_MATRIX)*normalize(sun_direction));
            vec3 n_view=normalize(mat3(VIEW_MATRIX)*opt_normal);
            float glint=pow(max(dot(reflect(-light_view,n_view),
                normalize(VIEW)),0.0),26.0);
            EMISSION=(packed_snow ? vec3(0.06,0.10,0.14) :
                vec3(0.13,0.10,0.06))*sparkle*glint*fine_lod*strength*0.10;
        } else if (surface_mode == 3) {
            float pores=ground_noise(p*18.0);
            float channels=ground_noise(p*vec2(6.0,23.0));
            float broken=smoothstep(0.28,0.75,
                pores*0.39+channels*0.61);
            float wet=clamp(rain_intensity,0.0,1.0)*strength*
                (0.25+0.65*broken);
            // Dampen the *real biome* color, do not replace with a studio
            // grey/metal. A broad nonmetallic highlight at wet patches.
            ALBEDO=mix(ALBEDO,ALBEDO*vec3(0.55,0.63,0.68),wet*0.68);
            ROUGHNESS=mix(0.89,0.52,wet*0.78);
            SPECULAR=mix(0.11,0.19,wet);
            vec3 slope=vec3((ground_noise(p*vec2(22.0,8.0))-0.5)*0.055,
                0.0,(channels-0.5)*0.045)*wet*fine_lod;
            slope-=n*dot(n,slope);
            NORMAL=normalize(mat3(VIEW_MATRIX)*normalize(n-slope));
        }
    }
}

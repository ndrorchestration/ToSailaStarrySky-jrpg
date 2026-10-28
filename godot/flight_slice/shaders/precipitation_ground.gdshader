shader_type spatial;
render_mode diffuse_burley;

// Noncanonical precipitation material laboratory. Standalone shader, not a
// replacement for existing terrain/forest/ocean art. No vertex displacement.
uniform int weather_mode = 0; // 0 packed snow; 1 soaked soil/stone
uniform float weather_optics_strength = 1.0; // 0 exact unmodified base
uniform bool low_quality = false;
uniform vec2 prevailing_wind = vec2(0.93, 0.37);
uniform vec3 sun_direction = vec3(0.65, 0.43, -0.70);
uniform float study_time = 0.0;
varying vec3 world_pos;
varying vec3 world_normal;

float weather_hash(vec2 p) {
    return fract(sin(dot(p,vec2(151.7,297.1)))*43758.5453);
}
float weather_noise(vec2 p) {
    vec2 i=floor(p), f=fract(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(weather_hash(i),weather_hash(i+vec2(1.0,0.0)),f.x),
        mix(weather_hash(i+vec2(0.0,1.0)),weather_hash(i+vec2(1.0,1.0)),f.x),f.y);
}
void vertex() {
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal=normalize(mat3(MODEL_MATRIX)*NORMAL);
}
void fragment() {
    vec2 p=world_pos.xz;
    bool snow=weather_mode==0;
    float macro=weather_noise(p*0.19);
    float tint=weather_noise(p*0.82);
    vec3 base_snow=mix(vec3(0.56,0.67,0.77),
        vec3(0.79,0.84,0.87),macro*0.69+tint*0.31);
    vec3 base_ground=mix(vec3(0.29,0.29,0.27),
        vec3(0.43,0.42,0.36),macro*0.65+tint*0.35);
    ALBEDO=snow ? base_snow : base_ground;
    ROUGHNESS=snow ? 0.93 : 0.91;
    SPECULAR=snow ? 0.10 : 0.14;
    float optical=low_quality ? 0.0 :
        clamp(weather_optics_strength,0.0,1.0);
    if (optical>0.001) {
        vec2 wind=normalize(prevailing_wind);
        vec2 across=vec2(-wind.y,wind.x);
        vec3 normal_world=normalize(world_normal);
        if (snow) {
            // A snowfield and a sand dune share scale cues, not optical color.
            // Soft, warped sastrugi change the normal response to glancing sun.
            float phase=dot(p,across)*4.3+
                (weather_noise(p*0.28)-0.5)*2.9+
                (weather_noise(p*0.81)-0.5)*0.8;
            float stripe_lod=1.0-smoothstep(0.9,2.1,fwidth(phase));
            float crest=sin(phase)*stripe_lod;
            vec2 frost_grid=floor(p*10.0);
            float frost_lod=1.0-smoothstep(0.38,1.55,
                max(fwidth(p.x*10.0),fwidth(p.y*10.0)));
            float fleck=weather_hash(frost_grid+vec2(13.0,5.0));
            vec3 grain_tilt=vec3(
                weather_hash(frost_grid+vec2(4.0,11.0))-0.5,0.0,
                weather_hash(frost_grid+vec2(8.0,3.0))-0.5);
            vec3 bump=vec3(across.x,0.0,across.y)*
                (cos(phase)*stripe_lod*0.042)+
                grain_tilt*frost_lod*0.031;
            bump-=normal_world*dot(normal_world,bump);
            vec3 adjusted=normalize(normal_world-bump*optical);
            NORMAL=normalize(mat3(VIEW_MATRIX)*adjusted);
            float key=clamp(dot(adjusted,normalize(sun_direction)),0.0,1.0);
            ALBEDO=mix(ALBEDO,
                ALBEDO*(0.975+0.038*smoothstep(0.1,0.9,key)
                    +crest*0.012),optical);
            // Powder scattering is broad and cool, never a mirror finish.
            ROUGHNESS=mix(ROUGHNESS,0.84,optical);
            SPECULAR=mix(SPECULAR,0.15,optical);
            RIM=optical*0.105;
            RIM_TINT=0.65;
            vec3 view_normal=normalize(mat3(VIEW_MATRIX)*adjusted);
            vec3 sun_view=normalize(mat3(VIEW_MATRIX)*normalize(sun_direction));
            float glimmer=pow(max(dot(reflect(-sun_view,view_normal),
                normalize(VIEW)),0.0),22.0);
            float rare=smoothstep(0.992,0.999,fleck);
            EMISSION=vec3(0.09,0.14,0.19)*
                (rare*glimmer*frost_lod*optical*0.13);
        } else {
            // Broken damp patches and tiny runnels follow gravity-like slope
            // cues. No water volume, rain gameplay or real fluid simulation.
            float pores=weather_noise(p*vec2(1.6,2.1));
            float streak=weather_noise(p*vec2(0.42,1.9)
                +vec2(weather_noise(p*0.24)*0.18,0.0));
            float soaked=smoothstep(0.22,0.76,
                pores*0.42+streak*0.58);
            float thin_rivulets=smoothstep(0.76,0.94,
                weather_noise(p*vec2(1.1,3.8)))*0.34;
            float wet=clamp((0.38+0.55*soaked+thin_rivulets)*
                optical,0.0,1.0);
            vec3 damp_tone=mix(vec3(0.15,0.19,0.20),
                vec3(0.23,0.25,0.24),macro);
            ALBEDO=mix(ALBEDO,damp_tone,wet*0.72);
            ROUGHNESS=mix(ROUGHNESS,0.31,wet*0.82);
            SPECULAR=mix(SPECULAR,0.33,wet);
            float fine_lod=1.0-smoothstep(0.7,2.2,
                max(fwidth(p.x*3.1),fwidth(p.y*3.1)));
            vec3 rivulet_tilt=vec3(
                (weather_noise(p*vec2(2.4,0.8))-0.5)*0.07,
                0.0,
                (streak-0.5)*0.085);
            rivulet_tilt*=fine_lod*wet;
            rivulet_tilt-=normal_world*dot(normal_world,rivulet_tilt);
            NORMAL=normalize(mat3(VIEW_MATRIX)*
                normalize(normal_world-rivulet_tilt));
            RIM=wet*0.045;
            RIM_TINT=0.40;
        }
    }
}

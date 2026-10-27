shader_type sky;
render_mode disable_fog;
// P0 CINEMATIC STUDY — bounded golden-hour atmospheric look, not planetary scattering.
// Preserve the same sun direction, scene clock and reduced-quality controls.
uniform float study_time = 0.0;
uniform bool low_quality = false;
uniform float cloud_depth_strength : hint_range(0.0, 1.0) = 1.0;
uniform float time_palette : hint_range(0.0, 3.0) = 0.0;
uniform float weather_strength : hint_range(0.0, 1.0) = 0.0;
uniform float magic_veil_strength : hint_range(0.0, 1.0) = 0.0;
uniform float sun_visibility : hint_range(0.0, 1.0) = 1.0; // 0 = reference sky, 1 = layered distant banks
uniform vec3 sun_direction = vec3(0.65, 0.43, -0.70);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
float clouds(vec2 p) {
    float n=noise(p)*0.58+noise(p*2.03+7.0)*0.28;
    if (!low_quality) { n+=noise(p*4.11-3.0)*0.14; }
    return n;
}
void sky() {
    vec3 d=normalize(EYEDIR), sun=normalize(sun_direction);
    float altitude=clamp(d.y,0.0,1.0);
    float horizon=exp(-abs(d.y)*10.0);
    float solar=max(dot(d,sun),0.0);
    // Dark upper dome, distant aerial perspective and a deliberately narrow
    // golden scattering band. No tone change implies a planet-wide time of day.
    vec3 upper=vec3(0.035,0.105,0.225);
    vec3 middle=vec3(0.115,0.255,0.365);
    vec3 distant=vec3(0.52,0.65,0.67);
    // Four hand-authored lighting grades; no computed orbit, lunar phase or clock.
    float noon=1.0-clamp(abs(time_palette-1.0),0.0,1.0);
    float blue=1.0-clamp(abs(time_palette-2.0),0.0,1.0);
    float night=1.0-clamp(abs(time_palette-3.0),0.0,1.0);
    upper=mix(upper,vec3(0.085,0.23,0.44),noon);
    middle=mix(middle,vec3(0.26,0.46,0.68),noon);
    distant=mix(distant,vec3(0.72,0.79,0.83),noon);
    upper=mix(upper,vec3(0.027,0.062,0.19),blue);
    middle=mix(middle,vec3(0.085,0.16,0.34),blue);
    distant=mix(distant,vec3(0.33,0.41,0.58),blue);
    upper=mix(upper,vec3(0.008,0.014,0.070),night);
    middle=mix(middle,vec3(0.019,0.043,0.14),night);
    distant=mix(distant,vec3(0.065,0.11,0.22),night);
    vec3 c=mix(middle,upper,smoothstep(0.04,0.78,altitude));
    c=mix(c,distant,horizon*0.89);
    float aureole=pow(solar,7.0)*exp(-abs(d.y-sun.y)*2.7);
    c+=vec3(0.31,0.145,0.045)*aureole*sun_visibility;
    c+=vec3(0.22,0.135,0.075)*horizon*pow(solar,2.0)*sun_visibility;

    if (d.y>0.025 && !AT_CUBEMAP_PASS) {
        vec2 p=d.xz/(d.y+0.22)*2.2+vec2(study_time*0.008,0.0);
        float n=clouds(p);
        float body=smoothstep(0.47-weather_strength*0.13,
            0.72-weather_strength*0.08,n)*smoothstep(0.03,0.17,d.y);
        float edge=clouds(p+vec2(0.12,-0.08));
        float solar_rim=smoothstep(0.18,0.86,solar);
        vec3 underside=vec3(0.31,0.40,0.52);
        vec3 lit=vec3(0.87,0.85,0.75);
        vec3 warm=vec3(1.0,0.77,0.52);
        vec3 cloud_color=mix(underside,lit,smoothstep(0.35,0.69,edge));
        cloud_color=mix(cloud_color,warm,solar_rim*0.33);
        cloud_color=mix(cloud_color,vec3(0.20,0.29,0.43),weather_strength*0.63);
        // Suppress sunlit white cloud banks after dark; preserve their form.
        cloud_color=mix(cloud_color,cloud_color*vec3(0.15,0.24,0.40),night*0.92);
        c=mix(c,cloud_color,body*0.89);
        // Atmospheric perspective: a separate lower, broader cloud deck.
        // This is a 2D directional impostor, NOT real volumetric cloud geometry.
        // It is disabled in low-quality mode to bound shader evaluations.
        if (!low_quality && cloud_depth_strength>0.001) {
            vec2 distant_p=p*0.47+vec2(8.7,-4.9)
                +vec2(-study_time*0.0025,study_time*0.0011);
            float bank_noise=clouds(distant_p);
            float horizon_band=smoothstep(0.018,0.085,d.y)
                *(1.0-smoothstep(0.17,0.34,d.y));
            float bank_shape=smoothstep(0.43,0.68,bank_noise)*horizon_band;
            // Edge tint catches the same authored sun direction as the ocean.
            float rim_noise=clouds(distant_p+vec2(0.08,-0.06));
            float rim=max(rim_noise-bank_noise,0.0);
            float backlight=pow(solar,4.0)
                *smoothstep(0.01,0.09,rim);
            vec3 bank_shadow=vec3(0.29,0.39,0.51);
            vec3 bank_highlight=vec3(0.77,0.76,0.71);
            vec3 bank_tone=mix(bank_shadow,bank_highlight,
                smoothstep(0.43,0.72,rim_noise));
            bank_tone=mix(bank_tone,vec3(0.96,0.73,0.49),backlight*0.48*sun_visibility);
            bank_tone=mix(bank_tone,vec3(0.10,0.15,0.29),night*0.85);
            c=mix(c,bank_tone,bank_shape*0.76*cloud_depth_strength);
            // Thin haze along the lower cloud edge, not a flat fog-colored
            // horizontal stripe or a fake planet curvature outline.
            float mist=noise(p*0.35+vec2(4.0,-3.0));
            float distant_mist=(1.0-smoothstep(0.065,0.17,d.y))
                *smoothstep(0.025,0.09,d.y)
                *smoothstep(0.32,0.69,mist);
            c=mix(c,vec3(0.49,0.60,0.66),
                distant_mist*0.19*cloud_depth_strength);
        }
        if (!low_quality) {
            // High thin cloud filaments are subordinate to the larger masses.
            float stratus=noise(p*vec2(0.6,5.0)+vec2(12.0,study_time*0.003));
            float wisps=smoothstep(0.66,0.85,stratus)
                *smoothstep(0.04,0.22,d.y)*(1.0-body);
            c=mix(c,mix(vec3(0.73,0.78,0.82),vec3(0.13,0.20,0.32),night),wisps*0.075);
        }
    }
    // Weather controls cloud, haze and muted light; no gameplay visibility change.
    c=mix(c,c*vec3(0.65,0.73,0.86),weather_strength*0.39);
    if (!low_quality && magic_veil_strength>0.001) {
        // Decorative magical haze: deliberately NOT a navigable auroral lane.
        // Slow, nonflashing ribbons are absent in quality fallback.
        float azimuth=atan(d.z,d.x);
        float veil_center=0.21+0.075*sin(azimuth*3.1+study_time*0.009);
        float ribbon=exp(-pow((d.y-veil_center)*7.0,2.0));
        float wisp=0.68+0.32*sin(azimuth*9.0+study_time*0.012);
        float altitude_mask=smoothstep(0.10,0.23,d.y)
            *(1.0-smoothstep(0.70,0.90,d.y));
        vec3 veil=mix(vec3(0.28,0.71,0.76),vec3(0.58,0.40,0.83),wisp);
        c+=veil*ribbon*altitude_mask*magic_veil_strength*(0.18+0.62*night);
    }
    float disk=smoothstep(0.9991,0.9997,dot(d,sun));
    c+=vec3(1.0,0.75,0.40)*disk*1.5*sun_visibility;
    c+=vec3(0.13,0.075,0.035)*pow(solar,140.0)*sun_visibility;
    COLOR=max(c,vec3(0.0));
}

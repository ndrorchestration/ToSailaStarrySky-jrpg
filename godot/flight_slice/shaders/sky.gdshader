shader_type sky;
render_mode disable_fog;
// P0 CINEMATIC STUDY — bounded golden-hour atmospheric look, not planetary scattering.
// Preserve the same sun direction, scene clock and reduced-quality controls.
uniform float study_time = 0.0;
uniform bool low_quality = false;
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
    vec3 c=mix(middle,upper,smoothstep(0.04,0.78,altitude));
    c=mix(c,distant,horizon*0.89);
    float aureole=pow(solar,7.0)*exp(-abs(d.y-sun.y)*2.7);
    c+=vec3(0.31,0.145,0.045)*aureole;
    c+=vec3(0.22,0.135,0.075)*horizon*pow(solar,2.0);

    if (d.y>0.025 && !AT_CUBEMAP_PASS) {
        vec2 p=d.xz/(d.y+0.22)*2.2+vec2(study_time*0.008,0.0);
        float n=clouds(p);
        float body=smoothstep(0.47,0.72,n)*smoothstep(0.03,0.17,d.y);
        float edge=clouds(p+vec2(0.12,-0.08));
        float solar_rim=smoothstep(0.18,0.86,solar);
        vec3 underside=vec3(0.31,0.40,0.52);
        vec3 lit=vec3(0.87,0.85,0.75);
        vec3 warm=vec3(1.0,0.77,0.52);
        vec3 cloud_color=mix(underside,lit,smoothstep(0.35,0.69,edge));
        cloud_color=mix(cloud_color,warm,solar_rim*0.33);
        c=mix(c,cloud_color,body*0.89);
        if (!low_quality) {
            // High thin cloud filaments are subordinate to the larger masses.
            float stratus=noise(p*vec2(0.6,5.0)+vec2(12.0,study_time*0.003));
            float wisps=smoothstep(0.66,0.85,stratus)
                *smoothstep(0.04,0.22,d.y)*(1.0-body);
            c=mix(c,vec3(0.73,0.78,0.82),wisps*0.075);
        }
    }
    float disk=smoothstep(0.9991,0.9997,dot(d,sun));
    c+=vec3(1.0,0.75,0.40)*disk*1.5;
    c+=vec3(0.13,0.075,0.035)*pow(solar,140.0);
    COLOR=max(c,vec3(0.0));
}

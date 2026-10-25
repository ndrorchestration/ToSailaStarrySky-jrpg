shader_type sky;
render_mode disable_fog;
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
    float height=max(d.y,0.0);
    float haze=pow(1.0-height,5.0);
    vec3 c=mix(vec3(0.055,0.145,0.26),vec3(0.44,0.61,0.66),haze);
    float toward=pow(max(dot(d,sun),0.0),10.0);
    c+=vec3(0.48,0.24,0.075)*toward*pow(1.0-height,2.0);
    if (d.y>0.025 && !AT_CUBEMAP_PASS) {
        vec2 p=d.xz/(d.y+0.22)*2.2+vec2(study_time*0.008,0.0);
        float n=clouds(p);
        float body=smoothstep(0.47,0.72,n)*smoothstep(0.03,0.17,d.y);
        float edge=clouds(p+vec2(0.12,-0.08));
        vec3 cloud_color=mix(vec3(0.30,0.40,0.53),vec3(0.98,0.82,0.61),smoothstep(0.39,0.66,edge));
        c=mix(c,cloud_color,body*0.90);
        float wisps=smoothstep(0.60,0.82,noise(p*vec2(0.6,6.0)+vec2(12.0,study_time*0.005)));
        c=mix(c,vec3(0.69,0.76,0.77),wisps*0.025*(1.0-body));
    }
    float disk=smoothstep(0.9991,0.9997,dot(d,sun));
    c+=vec3(1.0,0.73,0.36)*disk*1.6;
    c+=vec3(0.12,0.07,0.025)*pow(max(dot(d,sun),0.0),160.0);
    COLOR=c;
}

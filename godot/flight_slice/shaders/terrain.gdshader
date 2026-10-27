shader_type spatial;
render_mode diffuse_burley;
uniform float study_time = 0.0;
// Original 128x128 tileable authored PNG: micro-grain, fractured stone, grit.
uniform sampler2D terrain_microdetail : filter_linear_mipmap, repeat_enable;
uniform float texture_detail_strength : hint_range(0.0, 1.0) = 0.65;
varying vec3 world_pos;
varying vec3 world_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; world_normal=normalize(mat3(MODEL_MATRIX)*NORMAL); }
void fragment() {
    vec3 p=floor(world_pos*8.0)/8.0;
    float mottling=noise(p.xz*0.40)*0.65+noise(p.xz*1.8)*0.35;
    float slope=1.0-clamp(world_normal.y,0.0,1.0);
    vec3 texel=texture(terrain_microdetail,world_pos.xz*0.24).rgb;
    float textile=texture_detail_strength;
    vec3 grass=mix(vec3(0.10,0.20,0.13),vec3(0.31,0.37,0.17),mottling);
    grass=mix(grass,vec3(0.08,0.17,0.13),smoothstep(16.0,30.0,p.x)*0.35);
    grass*=mix(1.0,0.63+texel.r*0.77,textile);
    float strata=sin(p.y*4.0+noise(p.xz*0.3)*3.0)*0.5+0.5;
    // Weathered strata and sparse talus give exposed slopes geographic form
    // without inventing a second elevation model or touching collision heights.
    float bedding=noise(vec2(p.y*0.70+noise(p.xz*0.14)*1.4,
        p.x*0.085+p.z*0.12));
    vec3 rock=mix(vec3(0.17,0.20,0.24),vec3(0.42,0.40,0.36),
        mottling*0.48+strata*0.25+bedding*0.27);
    // Broken alpine outcrops follow the same terrain coordinates as grass,
    // snow and collision; they are material detail, not new terrain geometry.
    float alpine=smoothstep(8.5,15.0,p.y);
    float rock_field=noise(p.xz*0.19)*0.65+noise(p.xz*0.47)*0.35;
    float outcrop=alpine*smoothstep(0.42,0.68,rock_field);
    float rocky=max(smoothstep(0.07,0.32,slope),smoothstep(10.0,17.0,p.y)*0.6);
    rocky=max(rocky,outcrop*0.88);
    // Fine, discontinuous seams sit within the stone rather than painting
    // continuous stripes across snow or the lower grassland.
    float cracks=1.0-smoothstep(0.035,0.11,abs(sin(p.y*2.1
        +noise(p.xz*0.31)*3.2+p.x*0.14+p.z*0.08)));
    rock*=1.0-0.16*cracks*outcrop;
    float scree=smoothstep(7.0,18.0,p.y)*smoothstep(0.18,0.52,slope)
        *smoothstep(0.43,0.80,noise(p.xz*0.94));
    rock=mix(rock,vec3(0.32,0.32,0.31),scree*0.24);
    rock*=mix(1.0,0.61+texel.g*0.85,textile);
    vec3 color=mix(grass,rock,rocky);
    float sand=1.0-smoothstep(0.6,2.7,p.y+noise(p.xz*0.5)*0.5);
    vec3 sand_color=mix(vec3(0.36,0.31,0.22),vec3(0.70,0.59,0.40),mottling);
    sand_color*=mix(1.0,0.69+texel.b*0.66,textile);
    color=mix(color,sand_color,sand);
    float snow=smoothstep(16.3,19.0,p.y+noise(p.xz*0.42)*2.0)*(1.0-smoothstep(0.12,0.42,slope));
    // Maintain cool snow highlights while leaving headroom for direct light.
    color=mix(color,mix(vec3(0.40,0.49,0.55),vec3(0.65,0.71,0.69),mottling),snow);
    // Broad, restrained cloud shadows preserve direct-light readability.
    float cloud=noise(p.xz*0.025+vec2(study_time*0.004,0.0));
    ALBEDO=color*mix(0.82,1.0,smoothstep(0.3,0.65,cloud));
    ROUGHNESS=clamp(0.89+texel.b*0.08*textile,0.0,1.0); SPECULAR=0.12;
}

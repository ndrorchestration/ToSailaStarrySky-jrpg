shader_type spatial;
render_mode diffuse_burley;
uniform float study_time = 0.0;
uniform float sea_surface_elevation = -0.15; // bound to TerrainStudy.SEA_LEVEL
uniform float shoreline_wetness = 1.0; // review A/B switch, not a tide simulation
uniform bool low_quality = false;
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
    vec3 grass=mix(vec3(0.10,0.20,0.13),vec3(0.31,0.37,0.17),mottling);
    grass=mix(grass,vec3(0.08,0.17,0.13),smoothstep(16.0,30.0,p.x)*0.35);
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
    vec3 color=mix(grass,rock,rocky);
    float sand=1.0-smoothstep(0.6,2.7,p.y+noise(p.xz*0.5)*0.5);
    color=mix(color,mix(vec3(0.36,0.31,0.22),vec3(0.70,0.59,0.40),mottling),sand);
    // Waterline-darkened damp sand follows this SAME physical terrain elevation and
    // shared sea datum, not a second procedural coastline. Limit to gentle
    // beach surfaces so vertical cliffs never acquire horizontal wet stripes.
    float sea_clearance=max(p.y-sea_surface_elevation,0.0);
    float waterline_warp=(noise(p.xz*0.86)-0.5)*0.16;
    float flat_shore=1.0-smoothstep(0.12,0.34,slope);
    float damp=shoreline_wetness*flat_shore*sand*
        (1.0-smoothstep(0.16,1.15,sea_clearance+waterline_warp));
    vec3 damp_sand=mix(vec3(0.30,0.30,0.27),vec3(0.40,0.36,0.29),mottling);
    color=mix(color,damp_sand,damp*0.72);
    // Dry pebbly granulation is static, capped and optional on slower devices.
    // At 960x640 it should read as a material, not animated sparkle.
    float fine_grain=low_quality ? 0.0 :
        smoothstep(0.79,0.95,hash(floor(p.xz*5.4)));
    color=mix(color,vec3(0.36,0.33,0.27),fine_grain*sand*(1.0-damp)*0.15);
    float snow=smoothstep(16.3,19.0,p.y+noise(p.xz*0.42)*2.0)*(1.0-smoothstep(0.12,0.42,slope));
    // Maintain cool snow highlights while leaving headroom for direct light.
    color=mix(color,mix(vec3(0.40,0.49,0.55),vec3(0.65,0.71,0.69),mottling),snow);
    // Broad, restrained cloud shadows preserve direct-light readability.
    float cloud=noise(p.xz*0.025+vec2(study_time*0.004,0.0));
    ALBEDO=color*mix(0.82,1.0,smoothstep(0.3,0.65,cloud));
    ROUGHNESS=mix(0.92,0.78,damp); SPECULAR=mix(0.12,0.18,damp);
}

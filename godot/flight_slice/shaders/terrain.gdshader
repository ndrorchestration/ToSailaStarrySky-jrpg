shader_type spatial;
render_mode diffuse_burley;
uniform float study_time = 0.0;
uniform bool low_quality = false;
// Zero reproduces the inherited shader, 1 enables the bounded slope blend.
uniform float alpine_blend_strength : hint_range(0.0, 1.0) = 1.0;
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
    float blend_weight = low_quality ? 0.0 : clamp(alpine_blend_strength,0.0,1.0);
    vec3 grass=mix(vec3(0.10,0.20,0.13),vec3(0.31,0.37,0.17),mottling);
    grass=mix(grass,vec3(0.08,0.17,0.13),smoothstep(16.0,30.0,p.x)*0.35);
    float strata=sin(p.y*4.0+noise(p.xz*0.3)*3.0)*0.5+0.5;
    // Weathered strata and sparse talus give exposed slopes geographic form
    // without inventing a second elevation model or touching collision heights.
    float bedding=noise(vec2(p.y*0.70+noise(p.xz*0.14)*1.4,
        p.x*0.085+p.z*0.12));
    // High quality: cliff faces sample their own vertical plane rather than
    // stretching a top-down texture along walls. Keep the inherited look at
    // blend_weight=0 for a true within-run material A/B capture.
    float rock_mottling = mottling;
    float cliff_weight = blend_weight * smoothstep(0.15,0.50,slope)
        * smoothstep(9.0,15.5,p.y);
    if (cliff_weight > 0.001) {
        float x_face = abs(world_normal.x) /
            max(abs(world_normal.x)+abs(world_normal.z),0.001);
        vec2 face_uv = mix(p.xy,p.zy,smoothstep(0.34,0.66,x_face));
        float cliff_grain = noise(face_uv*0.52);
        rock_mottling = mix(mottling,cliff_grain,cliff_weight*0.68);
    }
    vec3 rock=mix(vec3(0.17,0.20,0.24),vec3(0.42,0.40,0.36),
        rock_mottling*0.48+strata*0.25+bedding*0.27);
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
    float snow_elevation = p.y+noise(p.xz*0.42)*2.0;
    float snow = smoothstep(16.3,19.0,snow_elevation)
        *(1.0-smoothstep(0.12,0.42,slope));
    // Slope and local outcrop structure vary the alpine snowline without
    // changing biome classes or terrain height. Original mask at weight zero.
    if (blend_weight > 0.001) {
        float softened = smoothstep(15.5,20.1,
            snow_elevation+(rock_field-0.5)*1.45)
            *(1.0-smoothstep(0.10,0.43,slope));
        snow = mix(snow,softened,blend_weight*0.85);
    }
    // Wind-combed highland snow is neither uniformly white nor a separate
    // terrain-height model. Keep the established snowline and shaded rock.
    vec3 snow_tint=mix(vec3(0.40,0.49,0.55),vec3(0.65,0.71,0.69),mottling);
    if (!low_quality && snow>0.001) {
        // One additional anisotropic, static noise lookup for material only.
        // Lateral windward striations softly uncover the existing stone shade
        // on exposed slopes, without changing triangles, heights or physics.
        float sweep=noise(vec2(p.x*0.36+p.z*0.71, p.y*0.21+p.z*0.12));
        float windward=smoothstep(0.08,0.34,slope);
        float exposure=smoothstep(0.45,0.76,sweep)*windward;
        snow*=1.0-0.35*exposure;
        float frost_grain=mix(0.89,1.02,smoothstep(0.20,0.86,sweep));
        snow_tint*=frost_grain;
    }
    color=mix(color,snow_tint,snow);
    // Broad, restrained cloud shadows preserve direct-light readability.
    float cloud=noise(p.xz*0.025+vec2(study_time*0.004,0.0));
    ALBEDO=color*mix(0.82,1.0,smoothstep(0.3,0.65,cloud));
    ROUGHNESS=0.92; SPECULAR=0.12;
}

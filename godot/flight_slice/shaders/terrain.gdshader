shader_type spatial;
render_mode diffuse_burley;
uniform float study_time = 0.0;
uniform float sea_surface_elevation = -0.15; // bound to TerrainStudy.SEA_LEVEL
uniform float shoreline_wetness = 1.0; // review A/B switch, not a tide simulation
uniform bool low_quality = false;
// ORIGINAL sand optics study: exposed-sand material only; no vertex displacement.
// Strength 0 returns the entire preceding terrain shader without optical layers.
uniform float sand_optics_strength = 1.0;
uniform bool dune_study_override = false; // detached GL art fixture; default false
uniform vec2 sand_wind_axis = vec2(0.93, 0.37);
uniform vec3 sun_direction = vec3(0.65, 0.43, -0.70);
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
    float sand=dune_study_override ? 1.0 :
        1.0-smoothstep(0.6,2.7,p.y+noise(p.xz*0.5)*0.5);
    color=mix(color,mix(vec3(0.36,0.31,0.22),vec3(0.70,0.59,0.40),mottling),sand);
    // Waterline-darkened damp sand follows this SAME physical terrain elevation and
    // shared sea datum, not a second procedural coastline. Limit to gentle
    // beach surfaces so vertical cliffs never acquire horizontal wet stripes.
    float sea_clearance=max(p.y-sea_surface_elevation,0.0);
    float waterline_warp=(noise(p.xz*0.86)-0.5)*0.16;
    float flat_shore=1.0-smoothstep(0.12,0.34,slope);
    float damp=(dune_study_override ? 0.0 : shoreline_wetness)*flat_shore*sand*
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

    // Limit perceptual microdetail to dry, shallow-slope exposed sand.
    // The mountain, snow, water and existing damp-waterline paths remain.
    float sand_weight=sand*flat_shore*(1.0-damp*0.72)
        *max(0.0,1.0-snow);
    float optics=low_quality ? 0.0 :
        clamp(sand_optics_strength,0.0,1.0)*sand_weight;
    if (optics > 0.001) {
        vec2 wind=normalize(sand_wind_axis);
        vec2 across=vec2(-wind.y,wind.x);
        vec2 xz=world_pos.xz;
        // The undulation is perpendicular to the prevailing wind, bent by
        // broad static terrain-coherent noise; not moving sand geometry.
        float phase=dot(xz,across)*13.1+
            (noise(xz*0.31)-0.5)*3.3+
            (noise(xz*0.97)-0.5)*0.8;
        float ripple_lod=1.0-smoothstep(1.0,2.8,fwidth(phase));
        float ripple=sin(phase)*ripple_lod;
        float ripple_bump=cos(phase)*ripple_lod;
        // Microscopic grain representation from stable world-space cells.
        // Attenuate in screen space to avoid remote snow-like speckle alias.
        vec2 grain_grid=xz*18.0;
        vec2 grain_cell=floor(grain_grid);
        float grain_lod=1.0-smoothstep(0.4,1.7,
            max(fwidth(grain_grid.x),fwidth(grain_grid.y)));
        float g1=hash(grain_cell+vec2(11.0,7.0));
        float g2=hash(grain_cell+vec2(3.0,17.0));
        vec3 base_n=normalize(world_normal);
        vec3 ripple_grad=vec3(across.x,0.0,across.y)*
            (ripple_bump*0.037);
        vec3 grain_grad=vec3(g1-0.5,0.0,g2-0.5)*
            (grain_lod*0.047);
        vec3 micro_grad=ripple_grad+grain_grad;
        micro_grad-=base_n*dot(base_n,micro_grad);
        vec3 adjusted_n=normalize(base_n-micro_grad*optics);
        vec3 normal_view=normalize(mat3(VIEW_MATRIX)*adjusted_n);
        NORMAL=normalize(mix(NORMAL,normal_view,optics));
        // Soft diffuse contrast follows changing directional illumination.
        // Only a slight albedo modulation; Godot's ordinary lighting remains
        // the authority rather than a duplicate handmade light() pass.
        float key=clamp(dot(adjusted_n,normalize(sun_direction)),0.0,1.0);
        float diffuse=0.965+0.065*smoothstep(0.12,0.89,key);
        ALBEDO*=mix(1.0,diffuse+0.022*ripple,0.50*optics);
        // Broad liquid-silk highlight and a low-energy glancing rim.
        ROUGHNESS=mix(ROUGHNESS,0.73,optics*(1.0-damp*0.4));
        SPECULAR=mix(SPECULAR,0.20,optics);
        RIM=0.065*optics;
        RIM_TINT=0.80;
        // Rare orientation-sensitive grain flashes, not time-random stars.
        // A sparkle changes when the view/light moves, not each scene tick.
        float rare=smoothstep(0.989,0.998,
            hash(grain_cell+vec2(37.0,23.0)));
        vec3 tiny_n=normalize(adjusted_n+
            vec3((g1-0.5)*0.34,0.0,(g2-0.5)*0.34));
        vec3 tiny_view=normalize(mat3(VIEW_MATRIX)*tiny_n);
        vec3 sun_view=normalize(mat3(VIEW_MATRIX)*normalize(sun_direction));
        float flash=pow(max(dot(reflect(-sun_view,tiny_view),
            normalize(VIEW)),0.0),24.0);
        EMISSION=vec3(0.21,0.17,0.10)*
            (rare*flash*grain_lod*0.14*optics);
    }
}

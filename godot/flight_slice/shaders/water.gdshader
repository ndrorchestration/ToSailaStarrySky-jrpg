shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D height_field : filter_linear, repeat_disable;
uniform sampler2D water_ripple_detail : filter_linear_mipmap, repeat_enable;
uniform float texture_detail_strength : hint_range(0.0, 1.0) = 0.65;
uniform sampler2D biome_macrodetail : filter_linear_mipmap, repeat_enable;
uniform sampler2D coast_distance_field : filter_linear, repeat_disable;
uniform float biome_layer_strength : hint_range(0.0, 1.0) = 0.0;
// A/B control for breaking surf confined to the shared signed coastline.
uniform float coastal_surf_strength : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D terrain_coverage : filter_nearest, repeat_disable;
uniform float study_time = 0.0;
uniform bool low_quality = false;
uniform vec3 sun_direction = vec3(0.65, 0.43, -0.70);
uniform float sun_visibility : hint_range(0.0, 1.0) = 1.0;
uniform float sea_surface_elevation = -0.15; // bound from TerrainStudy.SEA_LEVEL
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
float rendered_coverage(vec2 p) {
    vec2 uv=(p+vec2(96.0))/192.0;
    if (uv.x<=0.0 || uv.y<=0.0 || uv.x>=1.0 || uv.y>=1.0) { return 0.0; }
    vec2 cell=fract(uv*8.0);
    float mask=texture(terrain_coverage,uv).r;
    // Fade only at a missing neighbor, not at every tile seam.
    mask*=mix(smoothstep(0.0,0.12,cell.x),1.0,texture(terrain_coverage,uv-vec2(0.125,0)).r);
    mask*=mix(smoothstep(0.0,0.12,1.0-cell.x),1.0,texture(terrain_coverage,uv+vec2(0.125,0)).r);
    mask*=mix(smoothstep(0.0,0.12,cell.y),1.0,texture(terrain_coverage,uv-vec2(0,0.125)).r);
    mask*=mix(smoothstep(0.0,0.12,1.0-cell.y),1.0,texture(terrain_coverage,uv+vec2(0,0.125)).r);
    return mask*smoothstep(0.0,3.0,min(96.0-abs(p.x),96.0-abs(p.y)));
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec2 p=world_pos.xz;
    // RF texture is sampled from TerrainStudy.sample_height; no second coastline.
    float ground=texture(height_field,(p+vec2(130.0))/260.0).r;
    float cover=rendered_coverage(p);
    vec3 coast_region=vec3(0.5);
    if (biome_layer_strength>0.001) {
        coast_region=texture(biome_macrodetail,p*0.018).rgb;
    }
    // No second coastline: the signed bed height drives both land and depth.
    float depth=mix(2.5,max(sea_surface_elevation-ground,0.0),cover);
    float warp=noise(p*0.33+vec2(study_time*0.07,0.0))*4.0;
    float wave1=noise(p*vec2(0.7,2.3)+vec2(study_time*0.25,warp*0.2))*2.0-1.0;
    float wave2=noise(p*vec2(1.4,0.7)+vec2(warp*0.2,-study_time*0.17))*2.0-1.0;
    float detail=low_quality ? 0.0 : sin(p.x*5.8+p.y*3.2-study_time*2.2)*0.2;
    // Slow, restrained authored surface microtexture, no independent coast.
    vec3 ripple=texture(water_ripple_detail,
        p*0.21+vec2(study_time*0.013,-study_time*0.008)).rgb;
    float micro=low_quality ? 0.0 : texture_detail_strength;
    detail+=(ripple.r-0.5)*micro*0.39;
    vec3 n=normalize(vec3((wave1+detail)*0.065,1.0,
        (wave2+detail+(ripple.g-0.5)*micro*0.29)*0.055));
    NORMAL=normalize(mat3(VIEW_MATRIX)*n);
    // Schlick-like grazing reflectance, not a physically simulated ocean.
    float ndv=clamp(dot(NORMAL,normalize(VIEW)),0.0,1.0);
    float fresnel=0.025+0.975*pow(1.0-ndv,5.0);
    // Shallow shelf illumination attenuates with water depth from the actual
    // shared terrain sample; it does not add a second decorative bathymetry map.
    float shallow=1.0-smoothstep(0.22,1.8,depth);
    vec3 water=mix(vec3(0.065,0.29,0.27),vec3(0.013,0.072,0.14),smoothstep(0.2,2.4,depth));
    water+=vec3(0.020,0.055,0.044)*shallow*(1.0-0.28*max(wave1,0.0));
    // Regional underwater tint is visual shelf detail, depth still sampled
    // exclusively from the real terrain height texture.
    water+=vec3(0.018,0.033,0.022)*shallow
        *(coast_region.b-0.5)*biome_layer_strength;
    vec3 reflected_sky=mix(vec3(0.19,0.37,0.49),vec3(0.39,0.48,0.53),smoothstep(0.3,0.95,fresnel));
    reflected_sky*=mix(0.43,1.0,sun_visibility);
    water=mix(water,reflected_sky,fresnel*0.79);
    float shore=(1.0-smoothstep(0.10,0.65,depth))*smoothstep(0.01,0.09,depth);
    float sea_distance=texture(coast_distance_field,
        (p+vec2(130.0))/260.0).r;
    float coast_proximity=1.0-smoothstep(0.0,4.0,abs(sea_distance));
    float foam=cover*smoothstep(0.15,0.65,
        sin(depth*24.0-study_time*1.4+wave1*0.4))*shore;
    foam*=mix(1.0,0.63+0.37*coast_proximity,biome_layer_strength);
    // A narrow, advancing swash band is bound by signed wet-side coastal
    // distance and the original terrain depth/coverage. No second coastline,
    // extra water mesh or particle emitter. Low quality uses inherited foam.
    if (!low_quality && coastal_surf_strength>0.001) {
        float wet_side=1.0-smoothstep(-0.20,0.18,sea_distance);
        float coast_band=(1.0-smoothstep(0.35,3.40,abs(sea_distance)))
            *(1.0-smoothstep(0.35,2.10,depth))*wet_side*cover;
        float swash_phase=depth*5.8-study_time*0.55
            +wave1*0.58+coast_region.g*0.72;
        float swash_rim=smoothstep(0.24,0.88,sin(swash_phase));
        float feather=0.42+0.58*texture(water_ripple_detail,
            p*0.12+vec2(study_time*0.012,-study_time*0.007)).g;
        float swash=coast_band*swash_rim*feather
            *coastal_surf_strength*0.72;
        foam=clamp(foam+swash*(1.0-foam),0.0,1.0);
    }
    // Broad shoreline patchiness; bounded by depth and current visible
    // terrain coverage, never an independently invented coast mask.
    foam*=mix(1.0,0.75+coast_region.r*0.53,biome_layer_strength);
    float glints=pow(max(0.0,wave1*wave2),18.0)*(1.0-fresnel)*0.14;
    // Align the golden specular path with sky.gdshader and the scene key light.
    // Fine sparkle is optional; foaming shallows stay rougher than deep water.
    vec3 solar_view=normalize(mat3(VIEW_MATRIX)*normalize(sun_direction));
    float sun_flash=pow(max(dot(reflect(-solar_view,NORMAL),normalize(VIEW)),0.0),
        low_quality ? 88.0 : 128.0);
    float fine_sparkle=low_quality ? 0.0 :
        pow(max(0.0,noise(p*4.5+vec2(study_time*0.16,0.0))),9.0)*0.08;
    fine_sparkle*=mix(1.0,0.58+ripple.b*0.85,micro);
    ALBEDO=mix(water,vec3(0.73,0.81,0.72),foam*0.65)
        +vec3(0.22,0.24,0.19)*glints;
    EMISSION=vec3(1.0,0.77,0.48)*sun_flash*0.16*(1.0-foam)*sun_visibility
        +vec3(0.07,0.10,0.12)*fine_sparkle;
    // Softer broad reflections retain wave detail at the bright coast viewpoint.
    ROUGHNESS=mix(0.43,0.76,foam); METALLIC=0.0; SPECULAR=0.16;
}

shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D height_field : filter_linear, repeat_disable;
uniform sampler2D water_ripple_detail : filter_linear_mipmap, repeat_enable;
uniform float texture_detail_strength : hint_range(0.0, 1.0) = 0.65;
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
    vec3 reflected_sky=mix(vec3(0.19,0.37,0.49),vec3(0.39,0.48,0.53),smoothstep(0.3,0.95,fresnel));
    reflected_sky*=mix(0.43,1.0,sun_visibility);
    water=mix(water,reflected_sky,fresnel*0.79);
    float shore=(1.0-smoothstep(0.10,0.65,depth))*smoothstep(0.01,0.09,depth);
    float foam=cover*smoothstep(0.15,0.65,sin(depth*24.0-study_time*1.4+wave1*0.4))*shore;
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

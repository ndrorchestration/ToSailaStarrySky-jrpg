shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D height_field : filter_linear, repeat_disable;
uniform sampler2D terrain_coverage : filter_nearest, repeat_disable;
uniform float study_time = 0.0;
uniform bool low_quality = false;
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
    float depth=mix(2.5,max(-0.15-ground,0.0),cover);
    float warp=noise(p*0.33+vec2(study_time*0.07,0.0))*4.0;
    float wave1=noise(p*vec2(0.7,2.3)+vec2(study_time*0.25,warp*0.2))*2.0-1.0;
    float wave2=noise(p*vec2(1.4,0.7)+vec2(warp*0.2,-study_time*0.17))*2.0-1.0;
    float detail=low_quality ? 0.0 : sin(p.x*5.8+p.y*3.2-study_time*2.2)*0.2;
    vec3 n=normalize(vec3((wave1+detail)*0.065,1.0,(wave2+detail)*0.055));
    NORMAL=normalize(mat3(VIEW_MATRIX)*n);
    float fresnel=pow(1.0-clamp(dot(NORMAL,VIEW),0.0,1.0),4.0);
    vec3 water=mix(vec3(0.06,0.30,0.29),vec3(0.015,0.075,0.13),smoothstep(0.2,2.4,depth));
    water=mix(water,vec3(0.31,0.44,0.51),fresnel*0.7);
    float shore=(1.0-smoothstep(0.10,0.65,depth))*smoothstep(0.01,0.09,depth);
    float foam=cover*smoothstep(0.15,0.65,sin(depth*24.0-study_time*1.4+wave1*0.4))*shore;
    float glints=pow(max(0.0,wave1*wave2),18.0)*(1.0-fresnel)*0.14;
    ALBEDO=mix(water,vec3(0.73,0.81,0.72),foam*0.65)+vec3(0.22,0.24,0.19)*glints;
    ROUGHNESS=mix(0.52,0.72,foam); METALLIC=0.0; SPECULAR=0.2;
}

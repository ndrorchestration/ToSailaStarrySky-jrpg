shader_type spatial;
render_mode diffuse_burley;
uniform float study_time = 0.0;
varying vec3 world_pos;
void vertex() {
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    float sway=sin(study_time*1.2+world_pos.x*0.43+world_pos.z*0.18);
    VERTEX.x+=sway*max(VERTEX.y+1.8,0.0)*0.018;
}
void fragment() {
    float variation=sin(world_pos.x*0.8+world_pos.z*0.4)*0.5+0.5;
    ALBEDO=COLOR.rgb*mix(vec3(0.12,0.24,0.19),vec3(0.23,0.31,0.18),variation);
    ROUGHNESS=0.94; SPECULAR=0.12;
}

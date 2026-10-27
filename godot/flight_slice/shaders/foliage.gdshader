shader_type spatial;
render_mode diffuse_burley;
uniform float study_time = 0.0;
uniform vec3 leaf_tint = vec3(1.0, 1.0, 1.0);
uniform sampler2D foliage_microdetail : filter_linear_mipmap, repeat_enable;
uniform float texture_detail_strength : hint_range(0.0, 1.0) = 0.65;
varying vec3 world_pos;
void vertex() {
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    float sway=sin(study_time*1.2+world_pos.x*0.43+world_pos.z*0.18);
    VERTEX.x+=sway*max(VERTEX.y+1.8,0.0)*0.018;
}
void fragment() {
    // Stable large- and small-scale coloration breaks up repeated instances.
    // Light remains restrained; no blanket emissive fantasy-neon foliage.
    float variation=sin(world_pos.x*0.37+world_pos.z*0.52)*0.5+0.5;
    float leaf_grain=sin(world_pos.x*2.73+world_pos.y*0.74+world_pos.z*1.81)*0.5+0.5;
    vec3 shade=mix(vec3(0.14,0.25,0.18),vec3(0.28,0.36,0.20),variation);
    // World-anchored grain prevents all repeated crowns from sharing a stamp.
    vec2 uv=world_pos.xz*0.53+vec2(world_pos.y*0.12,world_pos.y*0.19);
    vec3 texel=texture(foliage_microdetail,uv).rgb;
    float detail=mix(1.0,0.63+texel.r*0.76,texture_detail_strength);
    ALBEDO=COLOR.rgb*shade*leaf_tint*mix(0.86,1.10,leaf_grain)*detail;
    ROUGHNESS=0.94; SPECULAR=0.12;
}

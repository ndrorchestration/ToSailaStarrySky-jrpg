shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// World-anchored existing original texture assets; one bounded MultiMesh batch.
uniform sampler2D terrain_microdetail : filter_linear_mipmap, repeat_enable;
uniform sampler2D biome_macrodetail : filter_linear_mipmap, repeat_enable;
uniform float texture_detail_strength : hint_range(0.0,1.0) = 0.0;
uniform float biome_layer_strength : hint_range(0.0,1.0) = 0.0;
varying vec3 world_pos;
varying vec3 world_normal;
void vertex() {
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal=normalize(mat3(MODEL_MATRIX)*NORMAL);
}
void fragment() {
    vec3 n=abs(normalize(world_normal));
    vec2 uv=world_pos.xz;
    if (n.x>n.y && n.x>n.z) { uv=world_pos.zy; }
    else if (n.z>n.y) { uv=world_pos.xy; }
    float fine=0.5;
    if (texture_detail_strength>0.001) {
        fine=texture(terrain_microdetail,uv*0.28).g;
    }
    float regional=0.5;
    if (biome_layer_strength>0.001) {
        regional=texture(biome_macrodetail,world_pos.xz*0.018).r;
    }
    vec3 slate=mix(vec3(0.19,0.23,0.28),
        vec3(0.41,0.40,0.34),regional);
    float bedding=0.5+0.5*sin(world_pos.y*6.5+world_pos.x*0.65);
    vec3 c=slate*(0.89+0.16*bedding)
        *mix(1.0,0.72+fine*0.58,texture_detail_strength);
    ALBEDO=c*COLOR.rgb;
    ROUGHNESS=0.92;
    SPECULAR=0.11;
}

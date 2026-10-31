"""Create seven original procedural material studies and a separate UE review map.

--validate is offline metadata validation only. --build needs Unreal Editor Python.
Never touches First Wake, ship forms, combat, saves, or default startup settings.
"""
from __future__ import annotations
import argparse
import hashlib
import json

ROOT = '/Game/TSTSS/Review/WeatherMaterials_V1'
MATERIALS = ('Sand', 'SnowSurface', 'WetStone', 'Rain', 'Snowfall', 'BlowingSand', 'SpellRing')
# RGB is linear base/emissive color; A is roughness for surfaces, opacity for cards.
# No external textures, custom includes, paid plugins or third-party art.
SHADER = r'''
float2 uv = UV;
float t = Time * clamp(Speed, 0.0, 4.0);
float density = saturate(Intensity);
float tile = clamp(Tiling, 0.25, 32.0);
float2 p = uv * tile;
float grain = 0.5 + 0.5 * sin(p.x * 173.0 + sin(p.y * 119.0));
float ripple = 0.5 + 0.5 * sin(p.x * 24.0 + sin(p.y * 3.0) * 1.5);
if (Mode < 0.5) {
    float3 dry = lerp(float3(0.36,0.21,0.09), float3(0.74,0.55,0.28), ripple);
    return float4(dry * (0.92 + grain * 0.08), 0.86);
}
if (Mode < 1.5) {
    float drifts = 0.5 + 0.5 * sin(p.x * 4.0 + sin(p.y * 5.0));
    return float4(lerp(float3(0.55,0.68,0.78), float3(0.88,0.93,0.97), drifts)
        * (0.95 + grain * 0.05), 0.73 + grain * 0.18);
}
if (Mode < 2.5) {
    float pools = smoothstep(0.35,0.72, 0.5 + 0.5 * sin(p.x*3.0)*cos(p.y*4.0));
    float wet = pools * density;
    float3 stone = lerp(float3(0.16,0.20,0.22),float3(0.28,0.31,0.32),grain);
    return float4(stone * lerp(1.0,0.42,wet), lerp(0.83,0.10,wet));
}
// Fade all cards at their UV boundary, even when density is raised.
float edge = smoothstep(0.0,0.08,uv.x)*smoothstep(0.0,0.08,1.0-uv.x)
           * smoothstep(0.0,0.08,uv.y)*smoothstep(0.0,0.08,1.0-uv.y);
if (Mode < 3.5) {
    float2 grid = float2(p.x*18.0 + t*0.7, p.y*4.0 + t*7.0);
    float2 id = floor(grid);
    float seed = frac(sin(dot(id,float2(12.9898,78.233)))*43758.5453);
    float2 q = frac(grid)-0.5;
    float width = max(fwidth(grid.x),0.025);
    float streak = 1.0-smoothstep(0.012,0.012+width,abs(q.x));
    float tail = 1.0-smoothstep(0.12,0.48,abs(q.y));
    return float4(float3(0.55,0.72,0.82),streak*tail*step(seed,density)*edge*0.55*density);
}
if (Mode < 4.5) {
    float2 grid = float2(p.x*9.0 + sin(t*0.6+p.y)*0.25, p.y*9.0+t*1.2);
    float2 id = floor(grid);
    float seed = frac(sin(dot(id,float2(41.31,17.17)))*15731.743);
    float2 q = frac(grid)-float2(0.25+0.5*seed,0.5);
    float aa = max(length(fwidth(grid)),0.01);
    float flake = 1.0-smoothstep(0.035,0.035+aa,length(q));
    return float4(float3(0.82,0.91,1.0),flake*step(seed,density)*edge*density);
}
if (Mode < 5.5) {
    float veil = 0.5+0.5*sin(p.x*5.0-t*2.0+sin(p.y*7.0));
    float fine = 0.5+0.5*sin(p.x*29.0-t*6.0+p.y*13.0);
    return float4(float3(0.63,0.40,0.19),veil*fine*edge*density*0.22);
}
// Noncanonical spell presentation study; no Light/character/ability assignment.
float2 q = (uv-0.5)*2.0;
float radius = length(q);
float ringRadius = 0.58 + 0.025*sin(t*1.5);
float aa = max(fwidth(radius),0.004);
float ring = 1.0-smoothstep(0.018,0.018+aa,abs(radius-ringRadius));
float inner = 1.0-smoothstep(0.008,0.008+aa,abs(radius-0.42));
float angle = atan2(q.y,q.x);
float arcs = smoothstep(0.2,0.65,sin(angle*6.0-t*0.7));
float mask = saturate(ring+inner*arcs*0.5)*edge*density;
return float4(float3(0.12,0.68,0.83)*2.0,mask);
'''


NORMAL_SHADER = r'''
float2 p = UV * clamp(Tiling,0.25,32.0);
float phase = p.x*24.0 + sin(p.y*3.0)*1.5;
float2 slope = float2(0.0,0.0);
if (Mode < 0.5) {
    slope = float2(cos(phase)*0.22,cos(phase)*cos(p.y*3.0)*0.045);
} else if (Mode < 1.5) {
    slope = float2(cos(p.x*4.0+sin(p.y*5.0))*0.09,
        cos(p.x*4.0+sin(p.y*5.0))*cos(p.y*5.0)*0.06);
} else {
    slope = float2(cos(p.x*13.0)*0.055, sin(p.y*17.0)*0.055);
    float pools = smoothstep(0.35,0.72,0.5+0.5*sin(p.x*3.0)*cos(p.y*4.0));
    slope *= 1.0-pools*saturate(Intensity)*0.9;
}
return normalize(float3(-slope.x,-slope.y,1.0));
'''


def validate():
    if len(set(MATERIALS)) != 7 or not ROOT.startswith('/Game/TSTSS/Review/'):
        raise ValueError('Invalid review manifest')
    return {'root': ROOT, 'materials': list(MATERIALS), 'native_render': 'NOT_RUN',
            'shader_sha256': hashlib.sha256((SHADER + NORMAL_SHADER).encode()).hexdigest(),
            'authority': 'NONCANONICAL_MATERIAL_STUDIES_NO_GAMEPLAY'}


def preflight(u):
    if u.EditorAssetLibrary.does_directory_exist(ROOT):
        raise RuntimeError('Review destination exists; refusing overwrite: ' + ROOT)
    if (u.EditorLoadingAndSavingUtils.get_dirty_map_packages()
            or u.EditorLoadingAndSavingUtils.get_dirty_content_packages()):
        raise RuntimeError('Editor has unsaved changes; save or discard manually first')
    meshes = {name: u.load_asset(f'/Engine/BasicShapes/{name}.{name}')
              for name in ('Plane', 'Sphere', 'Cube')}
    if not all(meshes.values()):
        raise RuntimeError('Required engine mesh missing')
    return meshes


def require_connection(ok, label):
    if not ok:
        raise RuntimeError('Material connection failed: ' + label)


def require_compilation_result(errors):
    if errors is None or errors:
        raise RuntimeError('Shader compiler did not return a clean UE5.8 result: ' + str(errors))


def create_material(u, mode, name):
    edit = u.MaterialEditingLibrary
    material = u.AssetToolsHelpers.get_asset_tools().create_asset(
        'M_' + name, ROOT, u.Material, u.MaterialFactoryNew())
    if material is None:
        raise RuntimeError('Material creation failed: ' + name)
    if mode >= 3:
        material.set_editor_property('blend_mode', u.BlendMode.BLEND_TRANSLUCENT)
        material.set_editor_property('two_sided', True)
        material.set_editor_property('shading_model', u.MaterialShadingModel.MSM_UNLIT)

    def node(kind, **props):
        obj = edit.create_material_expression(material, getattr(u, 'MaterialExpression' + kind))
        if obj is None:
            raise RuntimeError('Material node creation failed: ' + kind)
        for key, value in props.items():
            obj.set_editor_property(key, value)
        return obj

    custom = node('Custom', code=SHADER, output_type=u.CustomMaterialOutputType.CMOT_FLOAT4,
                  description='TSTSS original weather/surface study; review only')
    inputs = []
    for name_ in ('UV', 'Time', 'Speed', 'Intensity', 'Tiling', 'Mode'):
        slot = u.CustomInput()
        slot.set_editor_property('input_name', name_)
        inputs.append(slot)
    custom.set_editor_property('inputs', inputs)
    sources = {'UV': node('TextureCoordinate'), 'Time': node('Time'),
               'Mode': node('Constant', r=float(mode))}
    for name_, value in (('Speed', 1.0), ('Intensity', 0.65), ('Tiling', 1.0)):
        sources[name_] = node('ScalarParameter', parameter_name=name_, default_value=value)
    for name_, source in sources.items():
        require_connection(edit.connect_material_expressions(source, '', custom, name_), name_)
    rgb = node('ComponentMask', r=True, g=True, b=True, a=False)
    alpha = node('ComponentMask', r=False, g=False, b=False, a=True)
    require_connection(edit.connect_material_expressions(custom, '', rgb, 'Input'), 'RGB')
    require_connection(edit.connect_material_expressions(custom, '', alpha, 'Input'), 'A')
    color_prop = u.MaterialProperty.MP_BASE_COLOR if mode < 3 else u.MaterialProperty.MP_EMISSIVE_COLOR
    value_prop = u.MaterialProperty.MP_ROUGHNESS if mode < 3 else u.MaterialProperty.MP_OPACITY
    require_connection(edit.connect_material_property(rgb, '', color_prop), 'color output')
    require_connection(edit.connect_material_property(alpha, '', value_prop), 'roughness/opacity output')
    if mode < 3:
        normal = node('Custom', code=NORMAL_SHADER, output_type=u.CustomMaterialOutputType.CMOT_FLOAT3,
                      description='Analytic tangent-space study normals; no geometry displacement')
        normal_inputs = []
        for key in ('UV', 'Mode', 'Tiling', 'Intensity'):
            slot = u.CustomInput()
            slot.set_editor_property('input_name', key)
            normal_inputs.append(slot)
        normal.set_editor_property('inputs', normal_inputs)
        for key in ('UV', 'Mode', 'Tiling', 'Intensity'):
            require_connection(edit.connect_material_expressions(sources[key], '', normal, key), key)
        require_connection(edit.connect_material_property(normal, '', u.MaterialProperty.MP_NORMAL), 'normal')
    edit.layout_material_expressions(material)
    errors = edit.recompile_material(material)
    require_compilation_result(errors)
    if not u.EditorAssetLibrary.save_loaded_asset(material):
        raise RuntimeError('Material save failed: ' + name)
    instance = u.AssetToolsHelpers.get_asset_tools().create_asset(
        'MI_' + name, ROOT, u.MaterialInstanceConstant, u.MaterialInstanceConstantFactoryNew())
    if instance is None:
        raise RuntimeError('Material instance creation failed: ' + name)
    edit.set_material_instance_parent(instance, material)
    edit.update_material_instance(instance)
    if not u.EditorAssetLibrary.save_loaded_asset(instance):
        raise RuntimeError('Material instance save failed: ' + name)
    return instance


def build():
    try:
        import unreal as u
    except ImportError as exc:
        raise RuntimeError('--build requires Unreal Editor Python') from exc
    plan = validate()
    meshes = preflight(u)
    # Partial creation is deliberately retained for inspection on failure. Never delete user assets.
    materials = [create_material(u, i, name) for i, name in enumerate(MATERIALS)]
    world = u.EditorLoadingAndSavingUtils.new_blank_map(False)
    if not world:
        raise RuntimeError('Could not create review world; created materials retained')
    actors = u.get_editor_subsystem(u.EditorActorSubsystem)

    def spawn(cls, label, xyz, rotation=(0, 0, 0)):
        actor = actors.spawn_actor_from_class(cls, u.Vector(*xyz), u.Rotator(*rotation))
        if actor is None:
            raise RuntimeError('Actor creation failed: ' + label)
        actor.set_actor_label('TSTSS_REVIEW_' + label)
        return actor

    def mesh(label, shape, xyz, scale, material, rotation=(0, 0, 0)):
        actor = spawn(u.StaticMeshActor, label, xyz, rotation)
        comp = actor.get_component_by_class(u.StaticMeshComponent)
        comp.set_static_mesh(meshes[shape])
        comp.set_material(0, material)
        comp.set_collision_enabled(u.CollisionEnabled.NO_COLLISION)
        actor.set_actor_scale3d(u.Vector(*scale))
        return actor

    # Three environmental bays, each with a floor and curved object to inspect UV behavior.
    for i, name in enumerate(MATERIALS[:3]):
        x = (i-1)*650
        mesh(name+'_Ground', 'Plane', (x,0,0), (6,6,1), materials[i])
        mesh(name+'_Object', 'Sphere', (x,100,85), (1.6,1.6,1.6), materials[i])
    # Plane's local +Z normal becomes +Y, facing the overview camera. UV V moves vertically.
    for i, bay in ((3, 2), (4, 1), (5, 0)):
        mesh(MATERIALS[i]+'_Card', 'Plane', ((bay-1)*650,-160,260), (5.8,5.2,1), materials[i], (0,0,90))
    mesh('SpellRing_Study', 'Plane', (0,-700,15), (4,4,1), materials[6])
    spawn(u.DirectionalLight, 'Sun', (0,0,1500), (-40,-35,0))
    spawn(u.SkyLight, 'SkyFill', (0,0,400))
    spawn(u.SkyAtmosphere, 'Atmosphere', (0,0,0))
    spawn(u.ExponentialHeightFog, 'Haze', (0,0,-200))
    spawn(u.CineCameraActor, 'Overview', (0,-2300,1100), (-23,90,0))
    if not u.EditorLoadingAndSavingUtils.save_map(world, ROOT + '/WeatherReview'):
        raise RuntimeError('Review map save failed; created assets retained for inspection')
    plan['editor_assets'] = 'CREATED_REQUIRES_SHADER_AND_RENDER_REVIEW'
    u.log(json.dumps(plan))
    return plan


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--validate', action='store_true')
    group.add_argument('--build', action='store_true')
    args = parser.parse_args()
    print(json.dumps(build() if args.build else validate(), indent=2))

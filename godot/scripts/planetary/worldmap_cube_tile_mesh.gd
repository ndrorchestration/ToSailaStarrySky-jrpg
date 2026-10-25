extends RefCounted
## Real cube-sphere surface mesh payload, using the EXISTING native tile address
## and the same non-canon biome sampler as the orbital globe. A tile samples
## shared face-edge positions in planet XYZ; it is not a tangent-plane impostor.
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
const Cart = preload("res://scripts/planetary/worldmap_cartography.gd")

const RADIUS_KM := 6371.0 # Non-canon development-scale fixture.
const GLOBE_UNITS := 12.0
const KM_TO_UNITS := GLOBE_UNITS / RADIUS_KM
const SEGMENTS := 12

static func _point(face: String, u: float, v: float) -> Vector3:
    var q := Tiles.vector_from_face_uv(face,u,v)
    # Existing Tiles are in math XYZ, with Z north. Godot uses Y up.
    return Vector3(q.x,q.z,q.y).normalized()

static func sample_border(tile: Dictionary, col: int, row: int,
        divisions: int = SEGMENTS) -> Vector3:
    var count := Tiles.validate_tile(tile)
    assert(divisions >= 2 and divisions <= 32,"CUBE_MESH_DIVISIONS_RANGE")
    assert(col >= 0 and col <= divisions and row >= 0 and row <= divisions,
            "CUBE_MESH_GRID_RANGE")
    var step := 2.0 / float(count)
    var u := -1.0 + step*(float(tile["x"])+float(col)/float(divisions))
    var v := -1.0 + step*(float(tile["y"])+float(row)/float(divisions))
    return _point(str(tile["face"]),u,v)

static func _add_triangle(builder: SurfaceTool, positions: Array[Vector3],
        colors: Array[Color], first: int, second: int, third: int) -> void:
    var pa := positions[first]
    var pb := positions[second]
    var pc := positions[third]
    # Avoid any inverted faces across the six cube-face basis orientations.
    var outward := (pb-pa).cross(pc-pa).dot((pa+pb+pc)/3.0)
    if outward < 0.0:
        var swapped := second
        second = third
        third = swapped
    for index in [first,second,third]:
        builder.set_color(colors[index])
        builder.add_vertex(positions[index])

static func build(tile: Dictionary, divisions: int = SEGMENTS) -> Dictionary:
    Tiles.validate_tile(tile)
    assert(divisions >= 2 and divisions <= 32,"CUBE_MESH_DIVISIONS_RANGE")
    var land_points: Array[Vector3] = []
    var water_points: Array[Vector3] = []
    var land_colors: Array[Color] = []
    var water_colors: Array[Color] = []
    var heights: Array[float] = []
    for row in range(divisions+1):
        for col in range(divisions+1):
            var direction := sample_border(tile,col,row,divisions)
            var lat := rad_to_deg(asin(clampf(direction.y,-1.0,1.0)))
            var lon := rad_to_deg(atan2(direction.z,direction.x))
            var sample := Cart.sample(lat,lon)
            var elev := float(sample["elevation"])
            heights.append(elev)
            var relief := maxf(elev,0.0)*2.8 if elev >= 0.0 else maxf(elev*2.6,-2.6)
            land_points.append(direction*(GLOBE_UNITS+relief*KM_TO_UNITS))
            water_points.append(direction*(GLOBE_UNITS+0.018*KM_TO_UNITS))
            var ground_color: Color = sample["color"]
            if elev < 0.0:
                ground_color = ground_color.darkened(0.13)
            land_colors.append(ground_color)
            var foam := clampf((0.12-absf(elev))*7.8,0.0,1.0)
            water_colors.append(Color(foam,float(sample["moisture"]),0.0,1.0))
    var terrain := SurfaceTool.new()
    terrain.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sea := SurfaceTool.new()
    sea.begin(Mesh.PRIMITIVE_TRIANGLES)
    var dry := 0
    var wet := 0
    for row in range(divisions):
        for col in range(divisions):
            var a := row*(divisions+1)+col
            var b := a+1
            var c := a+divisions+1
            var d := c+1
            _add_triangle(terrain,land_points,land_colors,a,b,c)
            _add_triangle(terrain,land_points,land_colors,b,d,c)
            var average := (heights[a]+heights[b]+heights[c]+heights[d])*0.25
            if average <= 0.0:
                _add_triangle(sea,water_points,water_colors,a,b,c)
                _add_triangle(sea,water_points,water_colors,b,d,c)
                wet += 1
            else:
                dry += 1
    terrain.generate_normals()
    var land_mesh := terrain.commit()
    var water_mesh: ArrayMesh = null
    if wet > 0:
        sea.generate_normals()
        water_mesh = sea.commit()
    return {"key":Tiles.key(tile),"terrain":land_mesh,"water":water_mesh,
            "land_cells":dry,"water_cells":wet,
            "vertex_count":(divisions+1)*(divisions+1)}

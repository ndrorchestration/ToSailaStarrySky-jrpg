extends Control
## Real Godot CanvasItem map overlay: global equirectangular chart vs a physical
## horizon-bounded north-up local survey. Labels/points are NON-CANON.
signal waypoint_requested(lat_deg: float, lon_deg: float)

var mode := "chart"
var globe_texture: Texture2D
var local_texture: Texture2D
var ship: Dictionary = {}
var waypoint: Dictionary = {}
var known_markers: Array[Dictionary] = []
var horizon_km := 0.0
const FONT_SIZE := 15

func configure(next_mode: String, atlas: Texture2D, survey: Texture2D,
        flight: Dictionary, target: Dictionary, markers: Array[Dictionary], limit_km: float) -> void:
    mode = next_mode
    globe_texture = atlas
    local_texture = survey
    ship = flight
    waypoint = target
    known_markers = markers
    horizon_km = limit_km
    queue_redraw()

func _chart_position(lat_deg: float, lon_deg: float) -> Vector2:
    return Vector2((lon_deg + 180.0) / 360.0 * size.x, (90.0 - lat_deg) / 180.0 * size.y)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("#071726"))
    if mode == "local":
        _draw_local()
    else:
        _draw_global()
    draw_rect(Rect2(Vector2.ZERO, size), Color("#d9e8d9"), false, 1.2)

func _draw_global() -> void:
    if globe_texture != null:
        draw_texture_rect(globe_texture,Rect2(Vector2.ZERO,size),false)
    # Physical terrain may exist while a location remains uncharted.
    # This mild overlay is fog of *knowledge*, not horizon occlusion.
    const Geo = preload("res://scripts/planetary/planetary_geometry.gd")
    var cols := 24
    var rows := 12
    for y in range(rows):
        for x in range(cols):
            var p_lat := 90.0 - (float(y) + 0.5) * 180.0 / float(rows)
            var p_lon := -180.0 + (float(x) + 0.5) * 360.0 / float(cols)
            var tile_point := Geo.position(p_lat,p_lon)
            var revealed := Geo.great_circle_distance_km(ship,tile_point,6371.0) < 1200.0
            for known in known_markers:
                if not bool(known.get("discovered",false)):
                    continue
                if Geo.great_circle_distance_km(known,tile_point,6371.0) < 850.0:
                    revealed = true
            if not revealed:
                draw_rect(Rect2(float(x)*size.x/cols,float(y)*size.y/rows,
                        size.x/cols+1.0,size.y/rows+1.0),Color(0.025,0.05,0.11,0.60))
    for lon_i in range(1,12):
        var x := size.x*float(lon_i)/12.0
        draw_line(Vector2(x,0),Vector2(x,size.y),Color(0.71,0.89,0.91,0.16),1.0)
    for lat_i in range(1,6):
        var y := size.y*float(lat_i)/6.0
        draw_line(Vector2(0,y),Vector2(size.x,y),Color(0.71,0.89,0.91,0.16),1.0)
    for m in known_markers:
        if not bool(m.get("discovered",false)):
            continue
        var pos := _chart_position(float(m["latDeg"]),float(m["lonDeg"]))
        draw_circle(pos,5.0,Color("#efbe7e"))
        draw_string(ThemeDB.fallback_font,pos+Vector2(9,-6),str(m["name"]),
                HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE,Color("#fff0cc"))
    if not waypoint.is_empty():
        var target_pos := _chart_position(float(waypoint["latDeg"]),float(waypoint["lonDeg"]))
        draw_arc(target_pos,9.0,0.0,TAU,28,Color("#ffca8f"),2.0,true)
        draw_line(target_pos+Vector2(-12,0),target_pos+Vector2(12,0),Color("#ffca8f"),1.0)
        draw_line(target_pos+Vector2(0,-12),target_pos+Vector2(0,12),Color("#ffca8f"),1.0)
    var ship_pos := _chart_position(float(ship.get("latDeg",0.0)),float(ship.get("lonDeg",0.0)))
    draw_circle(ship_pos,8.0,Color("#062d37"))
    draw_circle(ship_pos,4.0,Color("#90f2e6"))
    draw_string(ThemeDB.fallback_font,Vector2(14,25),
            "PROVISIONAL GLOBAL CHART  /  SELECT A POINT TO SET A WAYPOINT",
            HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE,Color("#f0efdb"))

func _draw_local() -> void:
    var length := minf(size.y,size.x)*0.91
    var side := (size-Vector2.ONE*length)*0.5
    var square := Rect2(side,Vector2.ONE*length)
    if local_texture != null:
        draw_texture_rect(local_texture,square,false)
    var center := size*0.5
    var radius := length*0.5
    draw_arc(center,radius,0.0,TAU,90,Color("#b9e1dd"),2.0,true)
    draw_arc(center,radius*0.67,0.0,TAU,90,Color("#b9e1dd55"),1.0,true)
    draw_arc(center,radius*0.33,0.0,TAU,90,Color("#b9e1dd55"),1.0,true)
    draw_line(center+Vector2(-13,0),center+Vector2(13,0),Color("#fff1cb"),2.0)
    draw_line(center+Vector2(0,-13),center+Vector2(0,13),Color("#fff1cb"),2.0)
    draw_circle(center,4.5,Color("#ffe3a3"))
    draw_string(ThemeDB.fallback_font,Vector2(14,25),
            "LOCAL SURVEY   /   NORTH UP   /   PHYSICAL HORIZON %.1f km" % horizon_km,
            HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE,Color("#f0efdb"))
    draw_string(ThemeDB.fallback_font,center+Vector2(-5,-radius-8),"N",
            HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE,Color("#f0efdb"))
    draw_string(ThemeDB.fallback_font,Vector2(14,size.y-14),
            "Outside the survey disk: physically beyond the geometric surface horizon.",
            HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#c8d5d2"))

func _gui_input(event: InputEvent) -> void:
    if mode != "chart" or not (event is InputEventMouseButton):
        return
    var mouse := event as InputEventMouseButton
    if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
        return
    var local := mouse.position
    if local.x < 0 or local.x > size.x or local.y < 0 or local.y > size.y:
        return
    var lon := clampf(local.x/size.x*360.0-180.0,-180.0,179.999999)
    var lat := clampf(90.0-local.y/size.y*180.0,-90.0,90.0)
    waypoint_requested.emit(lat,lon)
    accept_event()

extends RefCounted
## Original, asset-independent environmental art for REAL native Chapter I scenes.
## Draw-only / deterministic 960x640 scene-space composition. No inputs,
## camera authority, weather ownership, geometry, collisions or story changes.
## These are authored cinematic staging materials, NOT final visual-bible art.
const INK := Color("#071625")
const NIGHT := Color("#10243a")
const SLATE := Color("#25465b")
const BRASS := Color("#cb9e60")
const LAMP := Color("#f5c98a")
const SEA := Color("#29566b")
const ICE := Color("#9bc8cd")
const FLOOR := Color("#394751")

static func _rect(c: CanvasItem, r: Rect2, col: Color) -> void:
    c.draw_rect(r,col,true)

static func _poly(c: CanvasItem, pts: Array, color: Color) -> void:
    c.draw_colored_polygon(PackedVector2Array(pts),color)

static func _line(c: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
    c.draw_line(a,b,color,width,true)

static func _gradient(c: CanvasItem, y0: float, y1: float, top: Color, bottom: Color, steps: int) -> void:
    var step: float = (y1-y0)/float(steps)
    for i in range(steps):
        var t: float = float(i)/float(maxi(steps-1,1))
        _rect(c,Rect2(0,y0+float(i)*step,960,step+1.2),top.lerp(bottom,t))

static func _glow(c: CanvasItem, p: Vector2, radius: float, tint: Color, strength: float) -> void:
    # Broad, subtle hand-authored light pools; no GPU bloom requirement.
    for i in range(11,0,-1):
        var t: float = float(i)/11.0
        c.draw_circle(p,radius*t,Color(tint.r,tint.g,tint.b,
                strength*(1.0-t)*0.10),false)
    c.draw_circle(p,2.2,Color(tint.r,tint.g,tint.b,0.90),true)

static func _rivets(c: CanvasItem, start: Vector2, count: int, dx: float, tint: Color) -> void:
    for i in range(count):
        var center: Vector2 = start+Vector2(float(i)*dx,0)
        c.draw_circle(center,2.2,Color("#162b35"))
        c.draw_circle(center+Vector2(-0.5,-0.5),0.8,tint)

static func _industrial_rails(c: CanvasItem, top: float) -> void:
    # Far railing is deliberately outside Ender's floor collision/navigation.
    _line(c,Vector2(28,top),Vector2(930,top),Color("#182e3b"),9)
    _line(c,Vector2(30,top-3),Vector2(930,top-3),Color("#9c8d73"),2)
    for x in [57.0,145.0,252.0,364.0,490.0,617.0,740.0,852.0,926.0]:
        _line(c,Vector2(x,top-4),Vector2(x+4,top+37),Color("#132e39"),7)
        _line(c,Vector2(x-1,top-4),Vector2(x-1,top+34),Color("#b8986f"),1)

static func _planks(c: CanvasItem, y0: float, low: Color) -> void:
    _gradient(c,y0,541.0,Color("#716a5c"),low,12)
    for y in [407.0,431.0,456.0,483.0,511.0,537.0]:
        if y < y0:
            continue
        _line(c,Vector2(0,y),Vector2(960,y+2),Color("#172d33"),3.5)
        _line(c,Vector2(0,y+3),Vector2(960,y+4),Color("#b59a78"),1.0)
    for i in range(20):
        var x: float = float(i)*52.0+float(i%3)*12.0
        var y: float = 413.0+float(i%4)*25.0
        _line(c,Vector2(x,y),Vector2(x,y+22),Color("#263d41",0.7),2)
    _line(c,Vector2(0,542),Vector2(960,542),Color("#d2af78"),2)

static func _mast_lamp(c: CanvasItem, p: Vector2) -> void:
    _line(c,p+Vector2(0,0),p+Vector2(0,176),Color("#162a35"),12)
    _line(c,p+Vector2(-2,0),p+Vector2(-2,176),Color("#9f8263"),2)
    _poly(c,[p+Vector2(-18,3),p+Vector2(-13,-23),p+Vector2(12,-23),p+Vector2(19,3)],Color("#132a38"))
    _poly(c,[p+Vector2(-12,0),p+Vector2(-8,-14),p+Vector2(8,-14),p+Vector2(12,0)],Color("#f7d399"))
    _glow(c,p+Vector2(0,-7),100.0,LAMP,0.85)
    _line(c,p+Vector2(-17,1),p+Vector2(17,1),BRASS,2)

static func draw_family(c: CanvasItem) -> void:
    # Location-neutral offshore berth study; NO invented settlement or voyage.
    _gradient(c,0,395,Color("#0a1b31"),Color("#c48b6d"),52)
    _glow(c,Vector2(740,216),255,Color("#f5b68a"),0.52)
    for i in range(11):
        var y: float = 186.0+float(i)*17.0
        var fade: float = 0.033+float(i%4)*0.014
        _line(c,Vector2(0,y),Vector2(960,y-24+float(i%3)*12),
            Color(0.92,0.82,0.77,fade),4+float(i%3)*6)
    # Distant landscape is abstract silhouette study, never canonical map.
    _poly(c,[Vector2(0,307),Vector2(65,283),Vector2(128,295),
        Vector2(219,269),Vector2(310,305),Vector2(387,296),
        Vector2(454,322),Vector2(535,288),Vector2(623,311),
        Vector2(718,277),Vector2(827,296),Vector2(960,269),
        Vector2(960,380),Vector2(0,380)],Color("#4c6272",0.7))
    _poly(c,[Vector2(0,340),Vector2(94,317),Vector2(156,334),
        Vector2(255,323),Vector2(352,344),Vector2(456,325),
        Vector2(560,339),Vector2(670,318),Vector2(785,337),
        Vector2(899,314),Vector2(960,328),Vector2(960,390),
        Vector2(0,390)],Color("#263f54",0.9))
    _gradient(c,337,404,Color("#426777"),Color("#173346"),22)
    for i in range(38):
        var y: float = 346.0+float(i)*1.48
        var x: float = float((i*71+27)%920)
        _line(c,Vector2(x,y),Vector2(x+31.0+float(i%5)*10.0,y),
            Color(0.73,0.83,0.81,0.1+float(i%4)*0.02),1)
    # Far-background Aureate Wake nautical silhouette, not secret configuration.
    _poly(c,[Vector2(295,338),Vector2(370,353),Vector2(601,353),
        Vector2(664,333),Vector2(635,366),Vector2(595,379),
        Vector2(375,379),Vector2(333,368)],Color("#0b2333"))
    _line(c,Vector2(344,351),Vector2(630,351),Color("#bda079"),3)
    _poly(c,[Vector2(386,338),Vector2(409,306),Vector2(554,306),
        Vector2(578,339)],Color("#203d51",0.95))
    _line(c,Vector2(408,306),Vector2(554,306),Color("#d8ad77"),2)
    # Geodesic *visual study* bridge motif, not a revealed mechanical capability.
    c.draw_arc(Vector2(476,307),53,PI,TAU,28,Color("#adc9ce",0.8),2,true)
    _line(c,Vector2(423,307),Vector2(529,307),Color("#bcd4d3",0.8),1.8)
    for x in [440.0,459.0,478.0,497.0,515.0]:
        var t: float = (x-476.0)/53.0
        var y: float = 307.0-53.0*sqrt(maxf(0.0,1.0-t*t))
        _line(c,Vector2(x,307),Vector2(x,y),Color("#83b7c3",0.48),1)
    _line(c,Vector2(470,307),Vector2(475,253),Color("#eee1bd",0.6),1)
    _line(c,Vector2(523,307),Vector2(477,255),Color("#eee1bd",0.3),1)
    _glow(c,Vector2(582,330),23,Color("#e7c38d"),0.6)
    # Dockside shadow depth behind the main interaction rail.
    _poly(c,[Vector2(0,360),Vector2(180,375),Vector2(260,400),
        Vector2(960,400),Vector2(960,431),Vector2(0,431)],Color("#122d3a",0.65))
    _industrial_rails(c,391)
    _planks(c,400,Color("#3b4145"))
    _mast_lamp(c,Vector2(77,296))
    _mast_lamp(c,Vector2(905,282))
    # Repetitive metal cleats and rope detail, not additional interactables.
    for x in [115.0,342.0,601.0,868.0]:
        _rect(c,Rect2(x,390,22,7),Color("#222f36"))
        _line(c,Vector2(x+4,389),Vector2(x+18,389),Color("#d2b182"),2)
    _line(c,Vector2(0,525),Vector2(960,530),Color("#0d2330",0.7),10)

static func _brace(c: CanvasItem, x: float, y: float, height: float) -> void:
    _rect(c,Rect2(x,y,17,height),Color("#112735"))
    _line(c,Vector2(x+2,y),Vector2(x+2,y+height),Color("#ae8c63"),2)
    for n in range(3):
        var yy: float = y+20.0+float(n)*maxf(24.0,(height-28.0)/3.0)
        _line(c,Vector2(x-9,yy),Vector2(x+26,yy),BRASS,2)

static func _engine_ring(c: CanvasItem, point: Vector2, phase: String) -> void:
    var stable: bool = phase == "candidate"
    var danger: bool = phase in ["retest","listen","repeat"]
    var energy: Color = Color("#9ce6d7") if stable else (
        Color("#e9a36a") if danger else Color("#94afbc"))
    _glow(c,point,157.0,energy,0.9 if stable else 0.46)
    c.draw_circle(point,104,Color("#0b202e"))
    for r in [108.0,95.0,82.0,68.0,39.0]:
        c.draw_arc(point,r,0,TAU,96,Color("#a68b63",0.92) if r>80 else Color("#567e91",0.84),3,true)
    c.draw_arc(point,78,0.13,PI*1.46,80,energy,5,true)
    c.draw_arc(point,47,PI*0.63,TAU*0.95,80,energy,3,true)
    for i in range(12):
        var a: float = float(i)*TAU/12.0
        var outer: Vector2 = point+Vector2(cos(a),sin(a))*100.0
        var inner: Vector2 = point+Vector2(cos(a),sin(a))*82.0
        _line(c,outer,inner,Color("#d2b18a"),2)
        c.draw_circle(outer,3.2,Color("#d9ac74"))
    for i in range(5):
        var a: float = float(i)*TAU/5.0+0.4
        var outer: Vector2 = point+Vector2(cos(a),sin(a))*39.0
        _line(c,point,outer,Color("#50768c"),1.5)
    c.draw_circle(point,19,energy)
    c.draw_circle(point,9,Color("#f4e2c9"))
    # A warning is an optical readout only; it never grants story truth.
    for i in range(4):
        var y: float = 294.0+float(i)*15.0
        _line(c,Vector2(602,y),Vector2(652,y),energy,2 if i%2==0 else 1)

static func draw_workshop(c: CanvasItem, phase: String) -> void:
    _gradient(c,0,547,Color("#0c1b30"),Color("#2a4d59"),44)
    _rect(c,Rect2(0,150,960,234),Color("#0a2230",0.82))
    # Recessed shipboard glass ribs. No fabricated ship subsystem specs.
    for i in range(8):
        var x: float = -56.0+float(i)*151.0
        _poly(c,[Vector2(x,152),Vector2(x+13,152),Vector2(x+92,384),
            Vector2(x+69,384)],Color("#37576a",0.66))
        _line(c,Vector2(x+15,151),Vector2(x+79,382),Color("#c19b71",0.34),3)
    # Workshop wall panels, deep recesses, instrument slits.
    for i in range(6):
        var x: float = 32.0+float(i)*157.0
        _rect(c,Rect2(x,167,126,177),Color("#102c3a"))
        _line(c,Vector2(x,166),Vector2(x+126,166),Color("#9c825e"),2)
        _line(c,Vector2(x+4,340),Vector2(x+122,340),Color("#547282"),2)
        for n in range(3):
            _rect(c,Rect2(x+19+n*31,205,18,58),Color("#285164"))
            _rect(c,Rect2(x+23+n*31,217,10,39),Color("#4c8290",0.5))
    _glow(c,Vector2(232,255),164,Color("#79b5c5"),0.52)
    _glow(c,Vector2(774,277),181,Color("#f5be88"),0.38)
    # Fixed pipe conduits and lower machinery, all visual-only.
    for y in [319.0,341.0,361.0]:
        _line(c,Vector2(0,y),Vector2(960,y),Color("#142c37"),10)
        _line(c,Vector2(0,y-3),Vector2(960,y-3),Color("#b99b72",0.4),2)
    for x in [58.0,238.0,420.0,570.0,902.0]:
        _brace(c,x,145,244)
    _engine_ring(c,Vector2(748,287),phase)
    # Gold tracer paths carry visual meaning without simulation ownership.
    _line(c,Vector2(520,356),Vector2(632,355),Color("#c9ad7c"),5)
    _line(c,Vector2(628,356),Vector2(645,328),Color("#c9ad7c"),5)
    _line(c,Vector2(540,358),Vector2(620,356),Color("#e6c895",0.5),1)
    _planks(c,385,Color("#303c47"))
    for x in [165.0,375.0,555.0,840.0]:
        _rect(c,Rect2(x,393,22,5),Color("#c39b6c"))
    _line(c,Vector2(15,535),Vector2(946,535),Color("#e1ba82",0.7),1.5)

static func draw_reserve(c: CanvasItem, inspected: bool) -> void:
    _gradient(c,0,540,Color("#0b1e32"),Color("#375a60"),44)
    # The same engineered ship visual vocabulary extends to the real reserve.
    for i in range(7):
        var x: float = -39.0+float(i)*161.0
        _poly(c,[Vector2(x,170),Vector2(x+12,170),Vector2(x+91,401),
            Vector2(x+66,401)],Color("#1b3948"))
        _line(c,Vector2(x+14,174),Vector2(x+78,391),Color("#af9069",0.5),3)
    for i in range(7):
        var x: float = float(i)*148.0
        _rect(c,Rect2(x+13,209,116,163),Color("#132e3e"))
        _line(c,Vector2(x+16,215),Vector2(x+126,215),Color("#8bb2b3",0.4),2)
        for y in [250.0,281.0,312.0]:
            _line(c,Vector2(x+32,y),Vector2(x+101,y),Color("#6c96a2",0.54),1.5)
    _glow(c,Vector2(428,299),190,Color("#e4ae82"),0.67)
    _rect(c,Rect2(332,272,195,124),Color("#0a2230"))
    _rect(c,Rect2(345,281,170,104),Color("#274b55"))
    c.draw_arc(Vector2(421,304),47,PI,TAU,48,BRASS,4,true)
    for i in range(9):
        var a: float = PI+PI*float(i)/8.0
        _line(c,Vector2(421,304)+Vector2(cos(a),sin(a))*35,
            Vector2(421,304)+Vector2(cos(a),sin(a))*43,Color("#d4bf93"),2)
    var color: Color = Color("#82d5bc") if inspected else Color("#e49e78")
    c.draw_arc(Vector2(421,304),24,PI*0.94,PI*1.95,36,color,5,true)
    _rect(c,Rect2(375,347,95,8),Color("#051c2b"))
    for i in range(6):
        _rect(c,Rect2(380.0+float(i)*15,350,10,3),color if inspected else Color("#b45b5a"))
    _industrial_rails(c,399)
    _planks(c,405,Color("#3d424b"))
    for x in [83.0,689.0,866.0]:
        _glow(c,Vector2(x,265),74,LAMP,0.42)
        _line(c,Vector2(x,263),Vector2(x,391),Color("#233b43"),6)

## Authored scene props occupy the SAME authored interaction coordinates.
## These draw-only details are replaceable when art-approved assets exist.
static func draw_family_station(c: CanvasItem, p: Vector2, kind: String) -> void:
    var left := p+Vector2(-38,-78)
    _rect(c,Rect2(left+Vector2(-3,34),Vector2(83,8)),Color("#0a1d2c"))
    _poly(c,[left+Vector2(0,6),left+Vector2(73,6),
        left+Vector2(80,36),left+Vector2(-6,36)],Color("#344b52"))
    _line(c,left+Vector2(3,7),left+Vector2(71,7),BRASS,2.0)
    for i in range(4):
        _line(c,left+Vector2(7,13+i*5),left+Vector2(65,13+i*5),
            Color("#66818b",0.34),1.0)
    if kind == "DENITH'S LOG":
        _poly(c,[left+Vector2(19,1),left+Vector2(46,-1),
            left+Vector2(57,27),left+Vector2(23,28)],Color("#b9a180"))
        _line(c,left+Vector2(27,8),left+Vector2(49,7),Color("#4f5b59"),1.3)
        _line(c,left+Vector2(29,14),left+Vector2(50,13),Color("#4f5b59"),1.1)
        _poly(c,[left+Vector2(11,15),left+Vector2(23,9),
            left+Vector2(24,28),left+Vector2(13,28)],Color("#5a342e"))
        c.draw_circle(left+Vector2(36,22),3.0,Color("#c79566"))
    elif kind == "PHASE CHART":
        _rect(c,Rect2(left+Vector2(14,-16),Vector2(49,48)),Color("#132c3b"))
        _rect(c,Rect2(left+Vector2(18,-12),Vector2(41,38)),Color("#315f6c"))
        var pts := PackedVector2Array([
            left+Vector2(21,12),left+Vector2(29,7),left+Vector2(36,14),
            left+Vector2(44,3),left+Vector2(54,10)])
        c.draw_polyline(pts,Color("#c6eedc"),2,true)
        _line(c,left+Vector2(20,18),left+Vector2(55,18),Color("#a9c1ba",0.6),1)
        _rivets(c,left+Vector2(21,30),4,10.0,BRASS)
    else:
        # Shared theory table: notes, folded diagram and warm instrument glass.
        _poly(c,[left+Vector2(19,5),left+Vector2(51,3),
            left+Vector2(59,21),left+Vector2(26,25)],Color("#d5bc94"))
        _line(c,left+Vector2(28,12),left+Vector2(45,10),Color("#586d73"),1)
        _line(c,left+Vector2(28,17),left+Vector2(51,16),Color("#586d73"),1)
        c.draw_circle(left+Vector2(11,20),7,Color("#0c2331"))
        c.draw_arc(left+Vector2(11,20),5,0,TAU,22,Color("#8fd2d4"),2,true)
        _rect(c,Rect2(left+Vector2(53,13),Vector2(9,12)),BRASS)

static func draw_workshop_station(c: CanvasItem, p: Vector2, kind: String, done: bool) -> void:
    var x: float = p.x
    var y: float = p.y-75.0
    var base: Color = Color("#234654") if done else Color("#815f4d")
    _poly(c,[Vector2(x-33,y+8),Vector2(x+30,y+8),
        Vector2(x+37,y+43),Vector2(x-40,y+43)],base)
    _line(c,Vector2(x-32,y+8),Vector2(x+30,y+8),BRASS,2.1)
    _line(c,Vector2(x-38,y+44),Vector2(x+38,y+44),Color("#142f3c"),4)
    _rivets(c,Vector2(x-25,y+36),5,12.0,Color("#cbaa7b"))
    if kind == "recovered_supply":
        for i in range(5):
            var cx: float = x-18.0+float(i)*9.0
            _line(c,Vector2(cx,y+11),Vector2(cx,y-5.0+float(i%2)*3.0),
                Color("#89b7bb" if done else "#c8ab83"),2.0)
        _line(c,Vector2(x-22,y+13),Vector2(x+23,y+13),Color("#142d3b"),3)
    elif kind == "recovered_part":
        c.draw_arc(Vector2(x,y+10),16,0,TAU,36,BRASS,4,true)
        c.draw_arc(Vector2(x,y+10),8,0,TAU,30,ICE,2,true)
        for i in range(6):
            var a: float = float(i)*TAU/6.0
            c.draw_circle(Vector2(x,y+10)+Vector2(cos(a),sin(a))*16.0,2.0,Color("#d7bd92"))
    elif kind == "assembly":
        _rect(c,Rect2(x-22,y-3,44,26),Color("#193b49"))
        for xx in [-15.0,0.0,15.0]:
            _line(c,Vector2(x+xx,y+3),Vector2(x+xx,y+18),Color("#90adb4"),2)
        _line(c,Vector2(x-24,y+24),Vector2(x+26,y+24),Color("#d4b58a"),2)
    else:
        c.draw_arc(Vector2(x,y+12),22,0,TAU,48,BRASS,3,true)
        _glow(c,Vector2(x,y+12),26,ICE,0.34)
        c.draw_circle(Vector2(x,y+12),7,ICE)

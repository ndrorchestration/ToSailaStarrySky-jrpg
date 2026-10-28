extends SceneTree
## One real Chapter I formula action drives a passive weapon-visual side panel.
## Not a gameplay scene or a saved feature; no formula replay and no hitbox.
const Observer = preload("res://scripts/first_wake_staff_visual_pipeline_observer.gd")
const Staff = preload("res://scripts/ender_staff_combat_keyframe_review.gd")
const Pose = preload("res://scripts/weapon_combat_pose_review.gd")
const Target = preload("res://scripts/ender_staff_target_alignment_review.gd")
const OUT := "res://review-evidence"
var world: Node2D
var overlay: CanvasLayer
var side_viewport: SubViewport
var actor_stage: Node2D
var actor: Node2D
var target: Node2D
var receipt: Dictionary
var observer = Observer.new()
var title: Label
var status: Label
var result: Label
var hashes: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed = load("res://scenes/first_wake_chapter1_review.tscn")
    if packed == null:
        _fail("main native Chapter I migration scene missing")
        return
    world = packed.instantiate()
    get_root().add_child(world)
    await process_frame
    var chapter_before: Dictionary = world.chapter.snapshot()
    if not world.start_formula_review():
        _fail("actual Chapter I scene could not start formula test")
        return
    var combat_before: Dictionary = world.formula_encounter.snapshot()
    if not world.take_formula_review_action("staffStrike"):
        _fail("real Chapter I staffStrike action failed")
        return
    var combat_after: Dictionary = world.formula_encounter.snapshot()
    receipt = observer.observe_accepted_transition(
        "ender","full_length_staff","staffStrike",true,
        combat_before,combat_after,chapter_before,world.chapter.snapshot(),"east")
    if receipt.is_empty():
        _fail("no read-only visual receipt from authentic Chapter I action")
        return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    _build_side_panel()
    if not _display_receipt(false) or not await _save("chapter1-visual-receipt"):
        return
    if not _display_receipt(true) or not await _save("chapter1-reduced-motion"):
        return
    if hashes.size()!=2 or hashes[0]==hashes[1]:
        _fail("native original/reduced frames not distinct")
        return
    if world.formula_encounter.snapshot()!=combat_after \
        or world.chapter.snapshot()!=chapter_before:
        _fail("render observer touched authoritative Chapter I state")
        return
    print("FIRST_WAKE_STAFF_VISUAL_RENDER_PASS: 2 real 1600x640 side-by-side Chapter I + review pose renders; one actual turn")
    world.queue_free()
    side_viewport.queue_free()
    quit(0)

func _text(text_value: String, pos: Vector2, bounds: Vector2, size: int) -> Label:
    var label := Label.new()
    label.text=text_value
    label.position=pos
    label.size=bounds
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",Color("#e9dfc8"))
    overlay.add_child(label)
    return label

func _build_side_panel() -> void:
    side_viewport=SubViewport.new()
    side_viewport.name="NativeReadOnlyWeaponPanelViewport"
    side_viewport.size=Vector2i(640,640)
    side_viewport.disable_3d=true
    side_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    get_root().add_child(side_viewport)
    overlay=CanvasLayer.new()
    overlay.layer=0
    overlay.name="ReadOnlyWeaponPipelineEvidence"
    side_viewport.add_child(overlay)
    var panel := ColorRect.new()
    panel.color=Color("#07131f")
    panel.position=Vector2.ZERO
    panel.size=Vector2(640.0,640.0)
    overlay.add_child(panel)
    var edge := ColorRect.new()
    edge.color=Color("#d1b578")
    edge.position=Vector2(1.0,0.0)
    edge.size=Vector2(2.0,640.0)
    overlay.add_child(edge)
    title=_text("STAFF STRIKE  /  READ-ONLY VISUAL PIPELINE",
        Vector2(40,25),Vector2(562,58),21)
    status=_text("FIRST WAKE FORMULA ENCOUNTER  ·  PROTOTYPE ONLY",
        Vector2(40,85),Vector2(560,45),13)
    actor_stage=Pose.new()
    actor_stage.name="IsolatedCombatPoseStage"
    actor_stage.position=Vector2(330.0,335.0)
    actor_stage.show_mannequin=false
    actor_stage.show_static_target=false
    actor_stage.show_review_effects=false
    overlay.add_child(actor_stage)
    actor_stage.weapon.visible=false
    actor=Staff.new()
    actor.name="ReadOnlyEnderStaffGeometry"
    actor_stage.add_child(actor)
    target=Target.new()
    target.name="ReadOnlyContactFixture"
    actor_stage.add_child(target)
    result=_text("",Vector2(37,550),Vector2(574,75),14)

func _display_receipt(reduced: bool) -> bool:
    var original: Dictionary = receipt
    var before_hp: int = int(original["targetHpBefore"])
    var after_hp: int = int(original["targetHpAfter"])
    var chapter_snap: Dictionary = world.chapter.snapshot()
    # Rendered reduced-motion receipt is a different view of the SAME
    # authenticated real scene action, never another executed turn.
    var before: Dictionary = world.formula_encounter.snapshot()
    var pose: Dictionary = original["visualPose"]
    if reduced:
        pose = observer.bridge.actor_action_pose(
            "ender","full_length_staff","staffStrike",
            observer.bridge.timeline.duration("full_length_staff","attack")*0.695,true)
    var authored: Dictionary = actor.sample_frame("east",pose)
    var camera: Dictionary = observer.camera.sample(pose,"east")
    if authored.is_empty() or camera.is_empty() \
        or not actor.set_facing("east") or not actor.apply_battle_pose(pose):
        return false
    if not target.bind_contact_anchor("east",
        actor.sample_frame("east",original["visualPose"])) \
        or not target.apply_visual_contact(authored,camera):
        return false
    actor_stage.apply_pose(pose)
    actor_stage.weapon.visible=false
    actor_stage.show_mannequin=false
    actor_stage.show_static_target=false
    actor_stage.show_review_effects=false
    actor.queue_redraw()
    target.queue_redraw()
    status.text="One genuine First Wake action observed / motion: "+(
        "REDUCED" if reduced else "STANDARD")
    result.text="TURN +%d  ·  STAFF -1  ·  TARGET HP %d → %d\n%s" % [
        int(original["turnDeltaObserved"]),before_hp,after_hp,
        "NO REPLAY · NO COLLISION CLAIM · NO SAVE WRITE"
    ]
    return world.formula_encounter.snapshot()==before \
        and world.chapter.snapshot()==chapter_snap

func _save(label: String) -> bool:
    await process_frame
    await process_frame
    var main: Image=get_root().get_texture().get_image()
    var side: Image=side_viewport.get_texture().get_image()
    if main == null or main.get_width()!=960 or main.get_height()!=640         or side == null or side.get_width()!=640 or side.get_height()!=640:
        _fail("native main (960x640) or side (640x640) viewport size mismatch")
        return false
    # Compose BOTH actual GPU-rendered scene images, never a substitute
    # graphic or invented battle screen. First Wake stays untouched.
    main.convert(Image.FORMAT_RGBA8)
    side.convert(Image.FORMAT_RGBA8)
    var pic: Image=Image.create_empty(1600,640,false,Image.FORMAT_RGBA8)
    pic.blit_rect(main,Rect2i(0,0,960,640),Vector2i.ZERO)
    pic.blit_rect(side,Rect2i(0,0,640,640),Vector2i(960,0))
    var path:=OUT+"/"+label+"-native-1600x640.png"
    if pic.save_png(path)!=OK:
        _fail("PNG write failed")
        return false
    var hash:=FileAccess.get_sha256(path)
    if hash.is_empty():
        _fail("missing frame receipt")
        return false
    hashes.append(hash)
    print("FIRST_WAKE_STAFF_PIPELINE_FRAME_SHA256 "+label+" "+hash)
    var reduced: Image = pic.duplicate()
    reduced.convert(Image.FORMAT_RGB8)
    reduced.resize(1000,400,Image.INTERPOLATE_BILINEAR)
    var jpg: PackedByteArray=reduced.save_jpg_to_buffer(0.70)
    var encoded: String=Marshalls.raw_to_base64(jpg)
    print("FIRST_WAKE_STAFF_PIPELINE_CONTACT_BEGIN "+label+" "+str(encoded.length()))
    for i in range(0,encoded.length(),760):
        print("FIRST_WAKE_STAFF_PIPELINE_CONTACT_CHUNK "+encoded.substr(i,760))
    print("FIRST_WAKE_STAFF_PIPELINE_CONTACT_END "+label)
    return true

func _fail(reason: String) -> void:
    push_error("FIRST_WAKE_STAFF_VISUAL_RENDER_FAIL: "+reason)
    quit(1)

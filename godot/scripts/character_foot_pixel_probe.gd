extends RefCounted
## Source-pixel boot-band measurements for UNAPPROVED six-cell SVG sprite atlases.
## This detects alpha occupancy, NOT anatomically validated toes or stance phases.
const FRAME_WIDTH := 80
const FRAME_HEIGHT := 128
const FRAMES := 6
const BOOT_MIN_Y := 104
const ALPHA_THRESHOLD := 0.55
const GROUND_MIN_Y := 113

static func inspect(texture: Texture2D, phase: int) -> Dictionary:
    if texture == null:
        return {"valid": false, "reason": "texture_missing"}
    return inspect_image(texture.get_image(), phase)

static func inspect_image(image: Image, phase: int) -> Dictionary:
    if image == null or image.is_empty():
        return {"valid": false, "reason": "empty_image"}
    if image.get_width() != FRAME_WIDTH * FRAMES or image.get_height() != FRAME_HEIGHT:
        return {"valid": false, "reason": "wrong_atlas_dimensions"}
    if phase < 0 or phase >= FRAMES:
        return {"valid": false, "reason": "phase_out_of_range"}

    var bottom_y := -1
    var left_bottom := -1
    var right_bottom := -1
    var cell_x: int = phase * FRAME_WIDTH
    for y in range(BOOT_MIN_Y, FRAME_HEIGHT):
        for x in range(FRAME_WIDTH):
            if image.get_pixel(cell_x + x, y).a < ALPHA_THRESHOLD:
                continue
            bottom_y = maxi(bottom_y, y)
            if x < FRAME_WIDTH / 2:
                left_bottom = maxi(left_bottom, y)
            else:
                right_bottom = maxi(right_bottom, y)

    if bottom_y < GROUND_MIN_Y:
        return {"valid": false, "reason": "no_lower_boot_pixels", "bottom_y": bottom_y}

    var support := {}
    for name in ["left", "right"]:
        var selected_y: int = left_bottom if name == "left" else right_bottom
        var x_min: int = 0 if name == "left" else FRAME_WIDTH / 2
        var x_max: int = FRAME_WIDTH / 2 if name == "left" else FRAME_WIDTH
        if selected_y < BOOT_MIN_Y:
            support[name] = {"present": false}
            continue
        var total_x := 0.0
        var samples := 0
        for y in range(maxi(selected_y - 1, BOOT_MIN_Y), selected_y + 1):
            for x in range(x_min, x_max):
                if image.get_pixel(cell_x + x, y).a >= ALPHA_THRESHOLD:
                    total_x += x
                    samples += 1
        support[name] = {
            "present": samples > 0,
            "x": total_x / maxf(1.0, float(samples)),
            "y": selected_y,
            "sample_count": samples
        }
    return {
        "valid": true,
        "bottom_y": bottom_y,
        "left": support["left"],
        "right": support["right"],
        "baseline_correction_y": 64.0 - float(bottom_y)
    }

static func inspect_atlas(texture: Texture2D) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if texture == null:
        return result
    var image: Image = texture.get_image()
    for phase in range(FRAMES):
        result.append(inspect_image(image, phase))
    return result

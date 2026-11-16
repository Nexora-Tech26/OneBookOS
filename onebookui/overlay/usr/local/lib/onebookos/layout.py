"""OneBookOS adaptive taskbar geometry in Wayland logical pixels.

No GUI dependencies. The Start window is centered by the layer-shell compositor;
the returned start_x is its predicted position for QA verification.
"""


def compute_layout(width):
    width = int(width)
    if width < 320:
        raise ValueError("A display must provide at least 320 logical pixels")

    compact = width < 950
    start_width = 72 if not compact else 64
    segment_width = 154 if not compact else 76
    gap = 14 if not compact else 10
    margin = 18 if not compact else 10
    clock_width = 132 if not compact else 116

    start_x = (width - start_width) // 2
    left_x = start_x - gap - segment_width
    right_x = start_x + start_width + gap
    clock_x = width - margin - clock_width
    show_left = left_x >= 0
    show_right = width >= 580 and (right_x + segment_width + 14 <= clock_x)

    # Small displays always prioritize central Start and the actual clock.
    if not show_left:
        left_x = 0
    if not show_right:
        right_x = 0

    result = {
        "monitor_width": width,
        "bottom_margin": margin,
        "start_x": start_x,
        "start_width": start_width,
        "start_center_error": abs(start_x + start_width / 2 - width / 2),
        "left_x": left_x,
        "right_x": right_x,
        "segment_width": segment_width,
        "clock_margin": margin,
        "clock_x": clock_x,
        "clock_width": clock_width,
        "show_second_icon": not compact,
        "show_left": show_left,
        "show_right": show_right,
    }
    if result["start_center_error"] > 0.5:
        raise AssertionError("Start must be exactly centered in logical coordinates")
    if show_left and left_x + segment_width + gap > start_x:
        raise AssertionError("Left bar overlaps Start")
    if show_right and right_x < start_x + start_width + gap:
        raise AssertionError("Right bar overlaps Start")
    if show_right and right_x + segment_width + 14 > clock_x:
        raise AssertionError("Right bar overlaps clock")
    return result

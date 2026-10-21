"""Crop paired portraits to the three existing Jinsister asset formats."""

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
DESKTOP = Path.home() / "Desktop"
OUT = ROOT / "image" / "generals"
PREVIEW = ROOT / "backups" / "portrait_crops_20261018"
FORMATS = {
    "standard": ((249, 292), (95, 87), (166, 183), 1.12, None, 1.00, 12),
    # Match the first approved narrow image exactly; keep its separate diagonal.
    "dual": ((125, 292), (49, 76), (76, 218), 0.85, 190, 0.90, 9),
    "avatar": ((134, 134), (40, 37), (96, 84), 0.95, None, 1.30, 7),
}
SUBJECTS = {
    "zuosizuofen": {
        "source": DESKTOP / "\u5de6\u601d\u5de6\u68fb2.jpg",
        "upper": ((652, 397), 0.43),
        "lower": ((1155, 747), 0.40),
        "adjust": {"standard": (1.10, 1.00, 0, 0, 0, 0), "avatar": (0.88, 0.92, 4, 0, 0, 0)},
    },
    "douwudoumiao": {
        "source": DESKTOP / "\u7aa6\u6b66\u7aa6\u59994.png",
        "upper": ((1380, 310), 0.65),
        "lower": ((752, 549), 0.48),
        "adjust": {"standard": (1.12, 1.00, 0, 6, 5, 0), "avatar": (0.96, 0.86, 4, 4, 0, 0)},
    },
}
DUAL_ADJUSTMENTS = {
    "zuosizuofen": (5, 0.92, (65, 214)),
    "douwudoumiao": (5, 0.92, (68, 225)),
}
DUAL_FACE_SHIFT = {
    "zuosizuofen": (3, -3),
    "douwudoumiao": (3, -3),
}


def layer(source, size, anchor, destination, scale):
    # Inverse affine mapping preserves proportions and allows independent framing.
    return source.transform(
        size,
        Image.Transform.AFFINE,
        (1 / scale, 0, anchor[0] - destination[0] / scale,
         0, 1 / scale, anchor[1] - destination[1] / scale),
        Image.Resampling.BICUBIC,
    )


def portrait(source, subject, layout, format_name):
    size, top, bottom, multiplier, intercept, slope, feather = layout
    if intercept is None:
        intercept = (size[0] - 1) / 2 + slope * (size[1] - 1) / 2
    upper_adjust, lower_adjust, upper_dx, upper_dy, lower_dx, lower_dy = subject.get("adjust", {}).get(format_name, (1.0, 1.0, 0, 0, 0, 0))
    upper = layer(source, size, subject["upper"][0], (top[0] + upper_dx, top[1] + upper_dy), subject["upper"][1] * multiplier * upper_adjust)
    lower = layer(source, size, subject["lower"][0], (bottom[0] + lower_dx, bottom[1] + lower_dy), subject["lower"][1] * multiplier * lower_adjust)
    mask = Image.new("L", size)
    mask.putdata([
        round(255 * max(0, min(1, (intercept - slope * y - x) / feather + 0.5)))
        for y in range(size[1]) for x in range(size[0])
    ])
    return Image.composite(upper, lower, mask)


def _padded_edges(source, pad):
    width, height = source.size
    padded = Image.new("RGB", (width + 2 * pad, height + 2 * pad))
    padded.paste(source, (pad, pad))
    padded.paste(source.crop((0, 0, width, 1)).resize((width, pad)), (pad, 0))
    padded.paste(source.crop((0, height - 1, width, height)).resize((width, pad)), (pad, height + pad))
    padded.paste(source.crop((0, 0, 1, height)).resize((pad, height)), (0, pad))
    padded.paste(source.crop((width - 1, 0, width, height)).resize((pad, height)), (width + pad, pad))
    for x, y, sx, sy in ((0, 0, 0, 0), (width + pad, 0, width - 1, 0),
                         (0, height + pad, 0, height - 1),
                         (width + pad, height + pad, width - 1, height - 1)):
        padded.paste(source.getpixel((sx, sy)), (x, y, x + pad, y + pad))
    return padded


def adjust_approved_dual(source, shifts):
    upper_dx, lower_dx = shifts
    pad = 8
    padded = _padded_edges(source, pad)
    upper = padded.transform(source.size, Image.Transform.AFFINE,
                             (1, 0, pad - upper_dx, 0, 1, pad), Image.Resampling.BICUBIC)
    lower = padded.transform(source.size, Image.Transform.AFFINE,
                             (1, 0, pad - lower_dx, 0, 1, pad), Image.Resampling.BICUBIC)
    width, height = source.size
    mask = Image.new("L", source.size)
    slope, intercept, feather = 0.90, 190, 9
    mask.putdata([
        round(255 * max(0, min(1, (intercept - slope * y - x) / feather + 0.5)))
        for y in range(height) for x in range(width)
    ])
    return Image.composite(upper, lower, mask)


def main():
    PREVIEW.mkdir(parents=True, exist_ok=True)
    rows = []
    for subject_id, subject in SUBJECTS.items():
        source = Image.open(subject["source"]).convert("RGB") if subject["source"].exists() else None
        row = []
        for name, layout in FORMATS.items():
            target_dir = OUT if name == "standard" else OUT / name
            target_dir.mkdir(parents=True, exist_ok=True)
            target = target_dir / f"fengsui_heg__{subject_id}.jpg"
            if name == "dual":
                # Keep the user-approved diagonal and only move both faces inward.
                approved = PREVIEW / f"{subject_id}_approved_crop.jpg"
                result = adjust_approved_dual(Image.open(approved).convert("RGB"), DUAL_FACE_SHIFT[subject_id])
                result.save(target, quality=96, subsampling=0)
            else:
                if source is not None:
                    result = portrait(source, subject, layout, name)
                    result.save(target, quality=96, subsampling=0)
                else:
                    # The source artwork may be absent on a later checkout; preserve the last export.
                    result = Image.open(target).convert("RGB")
            row.append(result)
        rows.append((subject_id, row))
    reference = [Image.open(OUT / "fengsui_heg__jinsister.jpg")]
    reference += [Image.open(OUT / name / "fengsui_heg__jinsister.jpg") for name in ("dual", "avatar")]
    rows.insert(0, ("jinsister reference", reference))
    preview = Image.new("RGB", (1110, 1010), "#eeeeee")
    draw = ImageDraw.Draw(preview)
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18)
    for row_index, (label, images) in enumerate(rows):
        y = row_index * 330
        draw.text((16, y + 5), label, fill="#222222", font=font)
        for x, im in zip((16, 310, 530), images):
            preview.paste(im, (x, y + 32))
        preview.paste(images[2].resize((268, 268), Image.Resampling.NEAREST), (800, y + 32))
    preview.save(PREVIEW / "comparison.jpg", quality=95)
    metadata = {key: {**value, "source": str(value["source"])} for key, value in SUBJECTS.items()}
    (PREVIEW / "crop_settings.json").write_text(json.dumps({"subjects": metadata, "formats": FORMATS}, indent=2), encoding="utf-8")
    print(PREVIEW / "comparison.jpg")


if __name__ == "__main__":
    main()

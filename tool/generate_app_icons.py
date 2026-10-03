"""Generates the LGTM launcher icon for Android and iOS.

Run it from the project root with a Python that has Pillow installed:

    python tool/generate_app_icons.py

It writes:

* ``assets/icon/``                  the 1024px master and the adaptive foreground
* ``android/.../mipmap-*/``         ic_launcher, ic_launcher_round, foreground
* ``ios/.../AppIcon.appiconset/``   every size in Contents.json
* ``web/icons/``                    the PWA icons, plain and maskable

The mark is the app wordmark: cream Vollkorn italic "LGTM" on the crimson
``--primary`` background, which is the same pairing as the in app logo. Nothing
is downloaded and no other design file has to be edited.
"""

from __future__ import annotations

import json
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PRIMARY = (163, 58, 64, 255)  # LgtmColors.primary #A33A40
CREAM = (253, 249, 244, 255)  # LgtmColors.bg #FDF9F4
FONT = os.path.join(ROOT, "assets", "fonts", "Vollkorn-700Italic.ttf")

MASTER = os.path.join(ROOT, "assets", "icon", "app_icon.png")
FOREGROUND = os.path.join(ROOT, "assets", "icon", "app_icon_foreground.png")

# Android launcher mipmaps: density -> legacy icon size, adaptive 108dp size.
ANDROID = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}


# Four letters side by side is a wide, short lockup: the wordmark is fitted to
# the width of the tile, which leaves the cap height around a quarter of it.
WORDMARK_WIDTH = 0.86
WORDMARK_CAP = 0.30


def wordmark(size: int, color: tuple[int, int, int, int]) -> Image.Image:
    """The wordmark on a transparent square, fitted to ``WORDMARK_WIDTH``."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    font_size = int(size * 0.8)
    font = ImageFont.truetype(FONT, font_size)
    while True:
        box = draw.textbbox((0, 0), "LGTM", font=font)
        if (box[2] - box[0]) <= size * WORDMARK_WIDTH:
            break
        font_size -= 1
        font = ImageFont.truetype(FONT, font_size)

    x = (size - (box[2] - box[0])) / 2 - box[0]
    y = (size - (box[3] - box[1])) / 2 - box[1]
    draw.text((x, y), "LGTM", font=font, fill=color)

    cap = box[3] - box[1]
    if cap > size * WORDMARK_CAP:
        raise SystemExit(
            f"wordmark cap height {cap / size:.0%} is over {WORDMARK_CAP:.0%}"
        )
    return layer


def legacy_icon(size: int) -> Image.Image:
    """Crimson rounded square with the wordmark, for pre-Android 8 launchers."""
    scale = 4
    big = size * scale
    icon = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    draw.rounded_rectangle(
        (0, 0, big - 1, big - 1),
        radius=int(big * 0.22),
        fill=PRIMARY,
    )
    icon.alpha_composite(wordmark(big, CREAM))
    return icon.resize((size, size), Image.LANCZOS)


def adaptive_foreground(size: int) -> Image.Image:
    """Just the mark, kept inside the middle 66% the Android mask never crops."""
    scale = 4
    big = size * scale
    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    mark = wordmark(int(big * 0.70), CREAM)
    layer.alpha_composite(mark, ((big - mark.width) // 2, (big - mark.height) // 2))
    return layer.resize((size, size), Image.LANCZOS)


def web_icon(size: int, maskable: bool) -> Image.Image:
    """PWA icon: full bleed square, or the mark pulled into the safe zone."""
    scale = 4
    big = size * scale
    icon = Image.new("RGBA", (big, big), PRIMARY)
    mark = wordmark(
        int(big * (0.62 if maskable else WORDMARK_WIDTH)), CREAM
    )
    icon.alpha_composite(mark, ((big - mark.width) // 2, (big - mark.height) // 2))
    return icon.resize((size, size), Image.LANCZOS)


def main() -> None:
    os.makedirs(os.path.dirname(MASTER), exist_ok=True)
    legacy_icon(1024).save(MASTER)
    adaptive_foreground(1024).save(FOREGROUND)
    print("wrote", os.path.relpath(MASTER, ROOT))
    print("wrote", os.path.relpath(FOREGROUND, ROOT))

    res = os.path.join(ROOT, "android", "app", "src", "main", "res")
    for density, (legacy, adaptive) in ANDROID.items():
        folder = os.path.join(res, f"mipmap-{density}")
        os.makedirs(folder, exist_ok=True)
        icon = legacy_icon(legacy)
        icon.save(os.path.join(folder, "ic_launcher.png"))
        circle = Image.new("RGBA", (legacy, legacy), (0, 0, 0, 0))
        circle.paste(icon, (0, 0), icon)
        circle.save(os.path.join(folder, "ic_launcher_round.png"))
        adaptive_foreground(adaptive).save(
            os.path.join(folder, "ic_launcher_foreground.png")
        )

    xcassets = os.path.join(
        ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset"
    )
    with open(os.path.join(xcassets, "Contents.json"), encoding="utf-8") as handle:
        contents = json.load(handle)

    for image in contents["images"]:
        filename = image.get("filename")
        if not filename:
            continue
        width = round(float(image["size"].split("x")[0]) * int(image["scale"][0]))
        # iOS icons are full bleed squares with no transparency.
        icon = Image.new("RGBA", (width, width), PRIMARY)
        icon.alpha_composite(wordmark(width, CREAM))
        icon.convert("RGB").save(os.path.join(xcassets, filename))
    print(f"wrote {len(contents['images'])} iOS icon sizes")

    web = os.path.join(ROOT, "web", "icons")
    os.makedirs(web, exist_ok=True)
    for size in (192, 512):
        web_icon(size, maskable=False).save(
            os.path.join(web, f"Icon-{size}.png")
        )
        web_icon(size, maskable=True).save(
            os.path.join(web, f"Icon-maskable-{size}.png")
        )
    print("wrote 4 web icons")


if __name__ == "__main__":
    main()
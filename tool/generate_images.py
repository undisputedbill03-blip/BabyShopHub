#!/usr/bin/env python3
"""Generates the product artwork used by the app.

The catalogue images are drawn here rather than downloaded, for two reasons.
The project has to run with no network access of any kind, and every image
has to be something we are free to ship. Each picture is a flat illustration
built from simple shapes in the colour of its category, with the brand and
product name set into the card.

Run from the project root:

    python tool/generate_images.py

It writes assets/images/products/<stem>.png and the brand mark. The stems
below must match the `image` values in lib/data/seed_data.dart;
tool/check_project.py verifies that they do.
"""

import os
import textwrap

from PIL import Image, ImageDraw, ImageFont

SIZE = 800
OUT_PRODUCTS = os.path.join("assets", "images", "products")
OUT_BRAND = os.path.join("assets", "images", "brand")

FONT_DIRS = [
    "/usr/share/fonts/truetype/lato",
    "/usr/share/fonts/truetype/liberation",
    "/usr/share/fonts/truetype/dejavu",
]
FONT_REGULAR = ["Lato-Regular.ttf", "LiberationSans-Regular.ttf", "DejaVuSans.ttf"]
FONT_BOLD = ["Lato-Bold.ttf", "LiberationSans-Bold.ttf", "DejaVuSans-Bold.ttf"]


def find_font(names):
    for directory in FONT_DIRS:
        for name in names:
            path = os.path.join(directory, name)
            if os.path.exists(path):
                return path
    return None


REGULAR_PATH = find_font(FONT_REGULAR)
BOLD_PATH = find_font(FONT_BOLD)


def font(size, bold=False):
    path = BOLD_PATH if bold else REGULAR_PATH
    if path:
        return ImageFont.truetype(path, size)
    return ImageFont.load_default()


# Category palette: (background top, background bottom, primary, accent)
PALETTE = {
    "diaper": ((0xFF, 0xF1, 0xF4), (0xFB, 0xDD, 0xE4), (0xD9, 0x60, 0x7C), (0xF7, 0xC3, 0xD0)),
    "food": ((0xFF, 0xF6, 0xEA), (0xFB, 0xE8, 0xCB), (0xE0, 0x8A, 0x3C), (0xF6, 0xD2, 0xA0)),
    "clothing": ((0xF1, 0xF7, 0xFF), (0xD9, 0xE9, 0xFA), (0x4A, 0x7E, 0xB5), (0xB9, 0xD6, 0xEF)),
    "toys": ((0xF4, 0xF1, 0xFF), (0xE3, 0xDC, 0xF7), (0x7A, 0x5A, 0xC4), (0xCB, 0xBE, 0xEE)),
    "bath": ((0xEC, 0xFA, 0xF8), (0xD2, 0xF0, 0xEC), (0x2E, 0x8B, 0x84), (0xA8, 0xDF, 0xD8)),
    "feeding": ((0xFF, 0xF8, 0xF0), (0xFA, 0xE6, 0xD4), (0xC2, 0x6A, 0x4F), (0xF2, 0xC8, 0xB4)),
    "nursery": ((0xF3, 0xF6, 0xF1), (0xDF, 0xE9, 0xD8), (0x5E, 0x82, 0x4C), (0xC3, 0xD8, 0xB4)),
    "travel": ((0xF2, 0xF4, 0xF8), (0xDD, 0xE2, 0xEC), (0x46, 0x53, 0x73), (0xBC, 0xC6, 0xD8)),
}

INK = (0x33, 0x2C, 0x2E)
MUTED = (0x8A, 0x7E, 0x82)
WHITE = (0xFF, 0xFF, 0xFF)


def gradient(top, bottom):
    img = Image.new("RGB", (SIZE, SIZE), top)
    draw = ImageDraw.Draw(img)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        draw.line(
            [(0, y), (SIZE, y)],
            fill=(
                int(top[0] + (bottom[0] - top[0]) * t),
                int(top[1] + (bottom[1] - top[1]) * t),
                int(top[2] + (bottom[2] - top[2]) * t),
            ),
        )
    return img


# --------------------------------------------------------------- glyphs
# Each glyph draws inside the box (x0, y0, x1, y1) with the category colours.


def g_diaper(d, box, c, a):
    x0, y0, x1, y1 = box
    w = x1 - x0
    d.polygon(
        [(x0, y0), (x1, y0), (x1, y0 + w * 0.26), ((x0 + x1) / 2, y1),
         (x0, y0 + w * 0.26)],
        fill=WHITE, outline=c, width=7,
    )
    d.rectangle([x0, y0, x1, y0 + w * 0.17], fill=a)
    d.line([(x0 + w * 0.3, y0 + w * 0.5), (x0 + w * 0.7, y0 + w * 0.5)], fill=a, width=9)


def g_food(d, box, c, a):
    x0, y0, x1, y1 = box
    w = x1 - x0
    d.rounded_rectangle([x0 + w * 0.2, y0 + w * 0.18, x1 - w * 0.2, y1],
                        radius=int(w * 0.12), fill=WHITE, outline=c, width=7)
    d.rounded_rectangle([x0 + w * 0.28, y0, x1 - w * 0.28, y0 + w * 0.2],
                        radius=int(w * 0.05), fill=a, outline=c, width=6)
    d.rounded_rectangle([x0 + w * 0.29, y0 + w * 0.46, x1 - w * 0.29, y1 - w * 0.14],
                        radius=int(w * 0.05), fill=a)


def g_clothing(d, box, c, a):
    x0, y0, x1, y1 = box
    w = x1 - x0
    d.polygon(
        [(x0 + w * 0.3, y0), (x0 + w * 0.42, y0 + w * 0.08),
         (x0 + w * 0.58, y0 + w * 0.08), (x0 + w * 0.7, y0),
         (x1, y0 + w * 0.22), (x1 - w * 0.14, y0 + w * 0.38),
         (x1 - w * 0.22, y0 + w * 0.3), (x1 - w * 0.22, y1),
         (x0 + w * 0.22, y1), (x0 + w * 0.22, y0 + w * 0.3),
         (x0 + w * 0.14, y0 + w * 0.38), (x0, y0 + w * 0.22)],
        fill=WHITE, outline=c, width=7,
    )
    d.line([(x0 + w * 0.36, y0 + w * 0.62), (x1 - w * 0.36, y0 + w * 0.62)],
           fill=a, width=10)


def g_toys(d, box, c, a):
    x0, y0, x1, y1 = box
    w = x1 - x0
    cx = (x0 + x1) / 2
    d.ellipse([cx - w * 0.3, y0, cx + w * 0.3, y0 + w * 0.6], fill=WHITE, outline=c, width=7)
    d.ellipse([cx - w * 0.44, y0 + w * 0.02, cx - w * 0.2, y0 + w * 0.26], fill=a, outline=c, width=6)
    d.ellipse([cx + w * 0.2, y0 + w * 0.02, cx + w * 0.44, y0 + w * 0.26], fill=a, outline=c, width=6)
    d.ellipse([cx - w * 0.14, y0 + w * 0.2, cx - w * 0.06, y0 + w * 0.28], fill=c)
    d.ellipse([cx + w * 0.06, y0 + w * 0.2, cx + w * 0.14, y0 + w * 0.28], fill=c)
    d.arc([cx - w * 0.12, y0 + w * 0.3, cx + w * 0.12, y0 + w * 0.46], 20, 160, fill=c, width=6)
    d.rounded_rectangle([cx - w * 0.26, y0 + w * 0.6, cx + w * 0.26, y1],
                        radius=int(w * 0.14), fill=a, outline=c, width=7)


def g_bath(d, box, c, a):
    x0, y0, x1, y1 = box
    w = x1 - x0
    cx = (x0 + x1) / 2
    d.polygon([(cx, y0), (x1 - w * 0.08, y0 + w * 0.55),
               (x0 + w * 0.08, y0 + w * 0.55)], fill=a)
    d.ellipse([x0 + w * 0.08, y0 + w * 0.3, x1 - w * 0.08, y0 + w * 0.8], fill=a)
    d.ellipse([x0 + w * 0.2, y0 + w * 0.42, x0 + w * 0.42, y0 + w * 0.6], fill=WHITE)
    d.arc([x0, y0 + w * 0.62, x1, y1 + w * 0.2], 200, 340, fill=c, width=9)


def g_feeding(d, box, c, a):
    x0, y0, x1, y1 = box
    w = x1 - x0
    cx = (x0 + x1) / 2
    d.rounded_rectangle([cx - w * 0.06, y0, cx + w * 0.06, y0 + w * 0.12],
                        radius=int(w * 0.03), fill=c)
    d.rounded_rectangle([cx - w * 0.16, y0 + w * 0.1, cx + w * 0.16, y0 + w * 0.22],
                        radius=int(w * 0.04), fill=a, outline=c, width=6)
    d.rounded_rectangle([cx - w * 0.22, y0 + w * 0.2, cx + w * 0.22, y1],
                        radius=int(w * 0.14), fill=WHITE, outline=c, width=7)
    for i in range(3):
        y = y0 + w * 0.42 + i * w * 0.14
        d.line([(cx + w * 0.02, y), (cx + w * 0.14, y)], fill=a, width=7)
    d.rounded_rectangle([cx - w * 0.22, y0 + w * 0.62, cx + w * 0.22, y1],
                        radius=int(w * 0.14), fill=a, outline=c, width=7)


def g_nursery(d, box, c, a):
    x0, y0, x1, y1 = box
    w = x1 - x0
    d.rounded_rectangle([x0, y0 + w * 0.3, x1, y1], radius=int(w * 0.08),
                        fill=WHITE, outline=c, width=7)
    for i in range(6):
        x = x0 + w * 0.1 + i * w * 0.16
        d.line([(x, y0 + w * 0.34), (x, y1 - w * 0.12)], fill=a, width=8)
    d.line([(x0, y0 + w * 0.3), (x0, y1)], fill=c, width=9)
    d.line([(x1, y0 + w * 0.3), (x1, y1)], fill=c, width=9)
    d.rounded_rectangle([x0 + w * 0.14, y0 + w * 0.06, x1 - w * 0.14, y0 + w * 0.3],
                        radius=int(w * 0.08), fill=a, outline=c, width=6)


def g_travel(d, box, c, a):
    x0, y0, x1, y1 = box
    w = x1 - x0
    d.polygon([(x0 + w * 0.12, y0 + w * 0.12), (x1 - w * 0.02, y0 + w * 0.12),
               (x1 - w * 0.22, y0 + w * 0.52), (x0 + w * 0.3, y0 + w * 0.52)],
              fill=WHITE, outline=c, width=7)
    d.line([(x0, y0), (x0 + w * 0.16, y0 + w * 0.14)], fill=c, width=10)
    d.line([(x0 + w * 0.3, y0 + w * 0.52), (x0 + w * 0.34, y1 - w * 0.14)], fill=c, width=9)
    d.line([(x1 - w * 0.22, y0 + w * 0.52), (x1 - w * 0.26, y1 - w * 0.14)], fill=c, width=9)
    d.ellipse([x0 + w * 0.2, y1 - w * 0.2, x0 + w * 0.4, y1], fill=a, outline=c, width=7)
    d.ellipse([x1 - w * 0.4, y1 - w * 0.2, x1 - w * 0.2, y1], fill=a, outline=c, width=7)


GLYPHS = {
    "diaper": g_diaper,
    "food": g_food,
    "clothing": g_clothing,
    "toys": g_toys,
    "bath": g_bath,
    "feeding": g_feeding,
    "nursery": g_nursery,
    "travel": g_travel,
}


def draw_product(stem, key, brand, name):
    top, bottom, primary, accent = PALETTE[key]
    img = gradient(top, bottom)
    d = ImageDraw.Draw(img)

    # The card the illustration sits on.
    d.rounded_rectangle([56, 56, SIZE - 56, SIZE - 56], radius=44,
                        fill=(0xFF, 0xFF, 0xFF, 0), outline=(*primary, ), width=0)
    d.rounded_rectangle([56, 56, SIZE - 56, SIZE - 56], radius=44,
                        outline=tuple(min(255, v + 28) for v in primary), width=3)

    GLYPHS[key](d, (250, 190, 550, 490), primary, accent)

    brand_font = font(30, bold=True)
    name_font = font(38, bold=True)

    label = brand.upper()
    bw = d.textlength(label, font=brand_font)
    d.text(((SIZE - bw) / 2, 560), label, font=brand_font, fill=MUTED)

    lines = textwrap.wrap(name, width=24)[:2]
    y = 612
    for line in lines:
        lw = d.textlength(line, font=name_font)
        d.text(((SIZE - lw) / 2, y), line, font=name_font, fill=INK)
        y += 48

    img.save(os.path.join(OUT_PRODUCTS, stem + ".png"), "PNG", optimize=True)


def draw_logo():
    img = gradient((0xFF, 0xF1, 0xF4), (0xFB, 0xDD, 0xE4))
    d = ImageDraw.Draw(img)
    primary = (0xD9, 0x60, 0x7C)
    accent = (0x2E, 0x8B, 0x84)
    cx = SIZE / 2

    d.ellipse([cx - 190, 150, cx + 190, 530], fill=WHITE, outline=primary, width=12)
    # A stylised rattle: circle, handle, and a small heart cut-out.
    d.rounded_rectangle([cx - 26, 430, cx + 26, 640], radius=26, fill=primary)
    d.ellipse([cx - 120, 220, cx + 120, 460], fill=(0xFB, 0xDD, 0xE4))
    d.ellipse([cx - 70, 268, cx - 6, 332], fill=primary)
    d.ellipse([cx + 6, 268, cx + 70, 332], fill=primary)
    d.polygon([(cx - 74, 302), (cx, 400), (cx + 74, 302)], fill=primary)
    d.ellipse([cx - 150, 190, cx - 106, 234], fill=accent)

    title_font = font(64, bold=True)
    title = "BabyShopHub"
    tw = d.textlength(title, font=title_font)
    d.text(((SIZE - tw) / 2, 660), title, font=title_font, fill=(0x33, 0x2C, 0x2E))

    img.save(os.path.join(OUT_BRAND, "logo.png"), "PNG", optimize=True)
    img.resize((512, 512), Image.LANCZOS).save(
        os.path.join(OUT_BRAND, "logo_512.png"), "PNG", optimize=True)


# stem, category key, brand, product name  -- mirrors lib/data/seed_data.dart
CATALOGUE = [
    ("diapers-pampers-dry", "diaper", "Pampers", "Baby Dry Pants Size 4"),
    ("diapers-huggies-comfort", "diaper", "Huggies", "Ultra Comfort Nappies Size 3"),
    ("diapers-molfix-newborn", "diaper", "Molfix", "Soft Care Newborn Nappies"),
    ("wipes-waterwipes-4pack", "diaper", "WaterWipes", "Baby Wipes 4-Pack"),
    ("changing-mat-raised", "diaper", "LittleNest", "Changing Mat with Raised Edges"),
    ("food-cerelac-wheat", "food", "Nestle", "Cerelac Wheat & Honey 400g"),
    ("food-gerber-apple", "food", "Gerber", "Organic Apple Puree"),
    ("food-nan-optipro", "food", "NAN", "Optipro Stage 1 Formula 800g"),
    ("food-heinz-rice", "food", "Heinz", "Baby Rice Cereal 200g"),
    ("food-banana-oat-pouch", "food", "HappyBaby", "Banana & Oat Pouches, 6 Pack"),
    ("clothing-sleepsuit-3pack", "clothing", "Cuddle & Co", "Cotton Sleepsuit 3-Pack"),
    ("clothing-knit-cardigan", "clothing", "LittleNest", "Soft Knit Baby Cardigan"),
    ("clothing-bamboo-romper", "clothing", "BabyBloom", "Bamboo Romper with Booties"),
    ("clothing-hooded-towel", "clothing", "Cuddle & Co", "Hooded Bath Towel Wrap"),
    ("clothing-hat-mittens", "clothing", "TinySteps", "Sun Hat & Mittens Set"),
    ("toys-stacking-rings", "toys", "BrightStart", "Wooden Stacking Rings"),
    ("toys-play-gym", "toys", "Fisher-Price", "Soft Activity Play Gym"),
    ("toys-rattle-set", "toys", "TinySteps", "Musical Rattle Set, 5 Piece"),
    ("toys-teether-rainbow", "toys", "BabyBloom", "Silicone Teether Rainbow"),
    ("toys-shape-sorter", "toys", "BrightStart", "Shape Sorter Cube"),
    ("bath-johnsons-wash", "bath", "Johnson's", "Top-to-Toe Wash 500ml"),
    ("bath-aveeno-lotion", "bath", "Aveeno", "Daily Moisture Lotion 354ml"),
    ("bath-foldable-tub", "bath", "MamaCare", "Foldable Baby Bath Tub"),
    ("bath-sudocrem-cream", "bath", "Sudocrem", "Nappy Rash Cream 250g"),
    ("bath-duck-set", "bath", "TinySteps", "Bath Time Duck Set"),
    ("feeding-avent-bottle", "feeding", "Philips Avent", "Natural Response Bottle 260ml"),
    ("feeding-silicone-bib", "feeding", "BabyBloom", "Silicone Bib with Crumb Catcher"),
    ("feeding-steam-steriliser", "feeding", "MamaCare", "Electric Steam Steriliser"),
    ("feeding-training-cup", "feeding", "Tommee Tippee", "Training Cup 2-Pack"),
    ("feeding-suction-plate", "feeding", "LittleNest", "Bamboo Suction Plate & Spoon"),
    ("nursery-cot-bed", "nursery", "BrightStart", "Convertible Wooden Cot Bed"),
    ("nursery-cot-mattress", "nursery", "MamaCare", "Breathable Cot Mattress"),
    ("nursery-baby-monitor", "nursery", "BrightStart", "Baby Monitor with Night Vision"),
    ("nursery-blackout-curtains", "nursery", "Cuddle & Co", "Blackout Nursery Curtains"),
    ("nursery-night-light", "nursery", "TinySteps", "Star Projector Night Light"),
    ("travel-fold-stroller", "travel", "TinySteps", "Lightweight Fold Stroller"),
    ("travel-car-seat", "travel", "Chicco", "Group 0+ Infant Car Seat"),
    ("travel-baby-carrier", "travel", "Cuddle & Co", "Ergonomic Baby Carrier"),
    ("travel-changing-backpack", "travel", "BabyBloom", "Insulated Changing Backpack"),
    ("travel-bottle-warmer", "travel", "MamaCare", "Travel Bottle Warmer"),
]


def main():
    os.makedirs(OUT_PRODUCTS, exist_ok=True)
    os.makedirs(OUT_BRAND, exist_ok=True)
    for stem, key, brand, name in CATALOGUE:
        draw_product(stem, key, brand, name)
    draw_logo()
    print("wrote {} product images and the brand mark".format(len(CATALOGUE)))


if __name__ == "__main__":
    main()

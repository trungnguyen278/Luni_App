"""Generate the Luni "Eclipse" app icon assets.

Renders the brand mark from `ui_design/App Icon.html`: a deep-space squircle
holding a cyan moon ring with Luni's two signature chunky rounded-rect eyes,
plus a crescent rim light. Outputs three 1024x1024 PNGs consumed by
flutter_launcher_icons:

  assets/icon/luni_icon.png     full-bleed master (iOS + Android legacy)
  assets/icon/luni_icon_bg.png  adaptive background (dark radial)
  assets/icon/luni_icon_fg.png  adaptive foreground (ring + eyes, transparent)
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
SS = 4                      # supersample factor
S = SIZE * SS               # internal render size

CYAN = (91, 233, 255)       # #5BE9FF — brand / eyes (firmware rule: always cyan)
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def radial_background(size):
    """Dark vertical gradient + soft cyan glow, full-bleed (no alpha)."""
    low = 64
    g = Image.new("RGB", (low, low))
    top = (19, 24, 38)      # #131826
    bot = (9, 12, 21)       # #090c15
    cx, cy = low * 0.5, low * 0.42
    maxd = low * 0.72
    px = g.load()
    for y in range(low):
        base = lerp(top, bot, y / (low - 1))
        for x in range(low):
            d = math.hypot(x - cx, y - cy) / maxd
            glow = max(0.0, 1.0 - d) ** 1.6 * 0.18   # cyan bloom near the orb
            px[x, y] = lerp(base, CYAN, glow)
    return g.resize((size, size), Image.BICUBIC)


def rounded_rect_eye(draw, cx, cy, w, h, r, fill):
    draw.rounded_rectangle(
        [cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2],
        radius=r, fill=fill,
    )


def draw_mark(content_d, alpha=255):
    """Draw the cyan ring + two eyes centered on a transparent SxS canvas.

    content_d is the orb (ring) diameter in *output* px; everything else is
    scaled off the design's 100-unit face viewBox.
    """
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    c = S / 2
    vb = content_d * SS / 100.0      # one viewBox unit in internal px
    ring_r = 48 * vb
    cyan = CYAN + (alpha,)

    # --- moon ring (orb outline) ---
    ring_w = 2.6 * vb
    d.ellipse([c - ring_r, c - ring_r, c + ring_r, c + ring_r],
              outline=cyan, width=round(ring_w))

    # brighter crescent rim on the right (the "moon")
    cres = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dc = ImageDraw.Draw(cres)
    dc.arc([c - ring_r, c - ring_r, c + ring_r, c + ring_r],
           start=-58, end=58, fill=CYAN + (alpha,), width=round(ring_w * 1.7))
    cres = cres.filter(ImageFilter.GaussianBlur(vb * 0.6))
    layer.alpha_composite(cres)

    # --- eyes: two chunky rounded rects (idle face), always cyan ---
    e_w, e_h, e_rx = 23 * vb, 27 * vb, 7 * vb
    e_lx, e_rx_x, e_cy = c - 17 * vb, c + 17 * vb, c
    rounded_rect_eye(d, e_lx, e_cy, e_w, e_h, e_rx, cyan)
    rounded_rect_eye(d, e_rx_x, e_cy, e_w, e_h, e_rx, cyan)

    # --- bloom: blurred copies of the whole mark stacked underneath ---
    glow = layer.filter(ImageFilter.GaussianBlur(vb * 1.1))
    glow2 = layer.filter(ImageFilter.GaussianBlur(vb * 3.0))
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.alpha_composite(glow2)
    out.alpha_composite(glow)
    out.alpha_composite(layer)
    return out


def downscale(img):
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    # 1) master — full-bleed dark bg + mark at ~74% (iOS rounds it itself)
    bg = radial_background(S)
    master = bg.convert("RGBA")
    master.alpha_composite(draw_mark(SIZE * 0.74))
    downscale(master).convert("RGB").save(os.path.join(OUT_DIR, "luni_icon.png"))

    # 2) adaptive background — dark radial, full bleed
    downscale(bg.convert("RGB")).save(os.path.join(OUT_DIR, "luni_icon_bg.png"))

    # 3) adaptive foreground — mark only. flutter_launcher_icons wraps this in a
    # 16% inset, so 0.80 here lands the ring at ~0.54 of the adaptive canvas,
    # comfortably inside the 61% safe zone while staying boldly visible.
    fg = draw_mark(SIZE * 0.80)
    downscale(fg).save(os.path.join(OUT_DIR, "luni_icon_fg.png"))

    print("Wrote luni_icon.png, luni_icon_bg.png, luni_icon_fg.png to", os.path.abspath(OUT_DIR))


if __name__ == "__main__":
    main()

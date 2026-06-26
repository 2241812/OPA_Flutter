from pathlib import Path
from math import cos, sin, pi

from PIL import Image, ImageDraw, ImageFont


OUT_DIR = Path(__file__).resolve().parent
SIZE = 1024

COLORS = {
    "void": "#050B0A",
    "ink": "#07110F",
    "panel": "#0B1D18",
    "panel_2": "#102D25",
    "mint": "#21F6A2",
    "cyan": "#26D8F0",
    "soft": "#8AF5CE",
    "text": "#EAFEF7",
    "muted": "#82B7A6",
}


def hex_points(cx, cy, radius):
    return [
        (
            cx + radius * cos((-90 + i * 60) * pi / 180),
            cy + radius * sin((-90 + i * 60) * pi / 180),
        )
        for i in range(6)
    ]


def scaled_color(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4)) + (255,)


def draw_mark(draw, s=1, include_square_bg=False):
    c = {k: scaled_color(v) for k, v in COLORS.items()}

    def xy(box):
        return tuple(round(v * s) for v in box)

    def pts(points):
        return [(round(x * s), round(y * s)) for x, y in points]

    if include_square_bg:
        draw.rounded_rectangle(
            xy((16, 16, SIZE - 16, SIZE - 16)),
            radius=178 * s,
            fill=c["void"],
        )
        draw.rounded_rectangle(
            xy((54, 54, SIZE - 54, SIZE - 54)),
            radius=144 * s,
            outline=c["panel_2"],
            width=6 * s,
        )

    outer = pts(hex_points(512, 512, 420))
    inner = pts(hex_points(512, 512, 370))
    draw.polygon(outer, fill=c["ink"])
    draw.line(outer + [outer[0]], fill=c["mint"], width=26 * s, joint="curve")
    draw.line(inner + [inner[0]], fill=c["panel_2"], width=8 * s, joint="curve")

    # Pocket terminal body.
    draw.rounded_rectangle(
        xy((318, 230, 706, 762)),
        radius=76 * s,
        fill=c["panel"],
        outline=c["soft"],
        width=14 * s,
    )
    draw.rounded_rectangle(
        xy((372, 278, 652, 704)),
        radius=44 * s,
        outline=c["panel_2"],
        width=10 * s,
    )
    draw.rounded_rectangle(
        xy((454, 265, 570, 284)),
        radius=9 * s,
        fill=c["panel_2"],
    )

    # O/key head.
    draw.ellipse(xy((316, 431, 452, 567)), outline=c["mint"], width=34 * s)
    draw.ellipse(xy((360, 475, 408, 523)), fill=c["ink"])
    draw.line(xy((452, 499, 536, 499)), fill=c["mint"], width=24 * s)
    draw.line(xy((525, 499, 525, 548)), fill=c["mint"], width=22 * s)
    draw.line(xy((562, 499, 562, 534)), fill=c["mint"], width=22 * s)

    # Terminal prompt.
    draw.line(
        pts([(505, 414), (631, 512), (505, 610)]),
        fill=c["mint"],
        width=42 * s,
        joint="curve",
    )
    draw.line(xy((626, 616, 756, 616)), fill=c["cyan"], width=34 * s)

    # Agent/network detail.
    draw.line(pts([(610, 380), (682, 380), (724, 434)]), fill=c["cyan"], width=10 * s)
    draw.ellipse(xy((590, 360, 630, 400)), fill=c["cyan"])
    draw.ellipse(xy((664, 362, 700, 398)), fill=c["mint"])
    draw.ellipse(xy((704, 414, 744, 454)), fill=c["cyan"])

    # Pocket notch and secure-device cue.
    draw.line(pts([(402, 672), (462, 714), (534, 714)]), fill=c["soft"], width=12 * s)
    draw.rounded_rectangle(xy((494, 720, 530, 738)), radius=9 * s, fill=c["panel_2"])


def render_png(path, include_square_bg=False):
    scale = 4
    img = Image.new("RGBA", (SIZE * scale, SIZE * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_mark(draw, scale, include_square_bg=include_square_bg)
    img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    img.save(path)


def render_wordmark_png(path):
    scale = 2
    canvas = Image.new(
        "RGBA",
        (1600 * scale, 520 * scale),
        scaled_color(COLORS["void"]),
    )

    mark = Image.new("RGBA", (SIZE * scale, SIZE * scale), (0, 0, 0, 0))
    draw_mark(ImageDraw.Draw(mark), scale, include_square_bg=False)
    mark = mark.resize((420 * scale, 420 * scale), Image.Resampling.LANCZOS)
    canvas.alpha_composite(mark, (70 * scale, 50 * scale))

    draw = ImageDraw.Draw(canvas)
    try:
        title_font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 178 * scale)
        sub_font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 42 * scale)
    except OSError:
        title_font = ImageFont.load_default()
        sub_font = ImageFont.load_default()

    draw.text((560 * scale, 72 * scale), "OPA", font=title_font, fill=scaled_color(COLORS["text"]))
    draw.text(
        (568 * scale, 278 * scale),
        "OpenSSH Pocket Agent",
        font=sub_font,
        fill=scaled_color(COLORS["soft"]),
    )
    draw.line(
        (570 * scale, 365 * scale, 1040 * scale, 365 * scale),
        fill=scaled_color(COLORS["panel_2"]),
        width=10 * scale,
    )
    draw.line(
        (570 * scale, 365 * scale, 740 * scale, 365 * scale),
        fill=scaled_color(COLORS["cyan"]),
        width=10 * scale,
    )

    canvas = canvas.resize((1600, 520), Image.Resampling.LANCZOS)
    canvas.save(path)


def write_svg_assets():
    mark_svg = f"""<svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="title desc">
  <title id="title">OPA logo mark</title>
  <desc id="desc">Hexagonal pocket terminal logo with SSH key, command prompt, and agent network cues.</desc>
  <path d="M512 92 L875.73 302 L875.73 722 L512 932 L148.27 722 L148.27 302 Z" fill="{COLORS['ink']}" stroke="{COLORS['mint']}" stroke-width="26" stroke-linejoin="round"/>
  <path d="M512 142 L832.43 327 L832.43 697 L512 882 L191.57 697 L191.57 327 Z" stroke="{COLORS['panel_2']}" stroke-width="8" stroke-linejoin="round"/>
  <rect x="318" y="230" width="388" height="532" rx="76" fill="{COLORS['panel']}" stroke="{COLORS['soft']}" stroke-width="14"/>
  <rect x="372" y="278" width="280" height="426" rx="44" stroke="{COLORS['panel_2']}" stroke-width="10"/>
  <rect x="454" y="265" width="116" height="19" rx="9" fill="{COLORS['panel_2']}"/>
  <circle cx="384" cy="499" r="68" stroke="{COLORS['mint']}" stroke-width="34"/>
  <circle cx="384" cy="499" r="24" fill="{COLORS['ink']}"/>
  <path d="M452 499 H536 M525 499 V548 M562 499 V534" stroke="{COLORS['mint']}" stroke-width="24" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M505 414 L631 512 L505 610" stroke="{COLORS['mint']}" stroke-width="42" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M626 616 H756" stroke="{COLORS['cyan']}" stroke-width="34" stroke-linecap="round"/>
  <path d="M610 380 H682 L724 434" stroke="{COLORS['cyan']}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="610" cy="380" r="20" fill="{COLORS['cyan']}"/>
  <circle cx="682" cy="380" r="18" fill="{COLORS['mint']}"/>
  <circle cx="724" cy="434" r="20" fill="{COLORS['cyan']}"/>
  <path d="M402 672 L462 714 H534" stroke="{COLORS['soft']}" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="494" y="720" width="36" height="18" rx="9" fill="{COLORS['panel_2']}"/>
</svg>
"""

    wordmark_svg = f"""<svg width="1600" height="520" viewBox="0 0 1600 520" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="title desc">
  <title id="title">OPA logo wordmark</title>
  <desc id="desc">OPA wordmark paired with the pocket terminal logo mark.</desc>
  <rect width="1600" height="520" fill="{COLORS['void']}"/>
  <g transform="translate(70 50) scale(0.41)">
    <path d="M512 92 L875.73 302 L875.73 722 L512 932 L148.27 722 L148.27 302 Z" fill="{COLORS['ink']}" stroke="{COLORS['mint']}" stroke-width="26" stroke-linejoin="round"/>
    <path d="M512 142 L832.43 327 L832.43 697 L512 882 L191.57 697 L191.57 327 Z" stroke="{COLORS['panel_2']}" stroke-width="8" stroke-linejoin="round"/>
    <rect x="318" y="230" width="388" height="532" rx="76" fill="{COLORS['panel']}" stroke="{COLORS['soft']}" stroke-width="14"/>
    <rect x="372" y="278" width="280" height="426" rx="44" stroke="{COLORS['panel_2']}" stroke-width="10"/>
    <rect x="454" y="265" width="116" height="19" rx="9" fill="{COLORS['panel_2']}"/>
    <circle cx="384" cy="499" r="68" stroke="{COLORS['mint']}" stroke-width="34"/>
    <circle cx="384" cy="499" r="24" fill="{COLORS['ink']}"/>
    <path d="M452 499 H536 M525 499 V548 M562 499 V534" stroke="{COLORS['mint']}" stroke-width="24" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M505 414 L631 512 L505 610" stroke="{COLORS['mint']}" stroke-width="42" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M626 616 H756" stroke="{COLORS['cyan']}" stroke-width="34" stroke-linecap="round"/>
    <path d="M610 380 H682 L724 434" stroke="{COLORS['cyan']}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="610" cy="380" r="20" fill="{COLORS['cyan']}"/>
    <circle cx="682" cy="380" r="18" fill="{COLORS['mint']}"/>
    <circle cx="724" cy="434" r="20" fill="{COLORS['cyan']}"/>
    <path d="M402 672 L462 714 H534" stroke="{COLORS['soft']}" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
    <rect x="494" y="720" width="36" height="18" rx="9" fill="{COLORS['panel_2']}"/>
  </g>
  <text x="560" y="243" font-family="Inter, Segoe UI, Arial, sans-serif" font-size="178" font-weight="850" letter-spacing="0" fill="{COLORS['text']}">OPA</text>
  <text x="568" y="319" font-family="Inter, Segoe UI, Arial, sans-serif" font-size="42" font-weight="600" letter-spacing="0" fill="{COLORS['soft']}">OpenSSH Pocket Agent</text>
  <path d="M570 365 H1040" stroke="{COLORS['panel_2']}" stroke-width="10" stroke-linecap="round"/>
  <path d="M570 365 H740" stroke="{COLORS['cyan']}" stroke-width="10" stroke-linecap="round"/>
</svg>
"""

    brief = """# OPA Logo Concept

Concept: a pocket terminal inside a hexagonal OpenSSH shell.

Visual cues:
- Hexagon: secure shell / developer utility identity.
- Pocket terminal body: phone-first SSH workflow.
- O/key glyph: SSH key management.
- Prompt chevron and underscore: terminal command execution.
- Small connected nodes: quick-launch agents and tools.

Palette:
- Void: #050B0A
- Ink: #07110F
- Panel: #0B1D18
- Mint: #21F6A2
- Cyan: #26D8F0
- Soft mint: #8AF5CE

Recommended use:
- Use `opa_app_icon_1024.png` for launcher/app-store previews.
- Use `opa_mark.svg` when you need an editable vector mark.
- Use `opa_wordmark.svg` for README, splash screens, and promo graphics.
"""

    (OUT_DIR / "opa_mark.svg").write_text(mark_svg, encoding="utf-8")
    (OUT_DIR / "opa_wordmark.svg").write_text(wordmark_svg, encoding="utf-8")
    (OUT_DIR / "OPA_LOGO_BRIEF.md").write_text(brief, encoding="utf-8")


def main():
    write_svg_assets()
    render_png(OUT_DIR / "opa_app_icon_1024.png", include_square_bg=True)
    render_png(OUT_DIR / "opa_mark_transparent_1024.png", include_square_bg=False)
    render_wordmark_png(OUT_DIR / "opa_wordmark_preview.png")


if __name__ == "__main__":
    main()

"""
Genera el fondo del DMG window: 600x400 con un degradado sutil,
el logo en el lado izquierdo y un texto guía al centro.
Usa solo stdlib + Pillow (mac suele tenerlo, si no instala con pip).
"""
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
except ImportError:
    print("Pillow no encontrado. Instala con: pip3 install --user Pillow")
    sys.exit(1)

W, H = 660, 420
project = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
logo_path = os.path.join(project, "Sources", "UPTCBotApp", "Resources", "logouptc.png")
out_path = os.path.join(project, "build", "dmg-background.png")
out_path_2x = os.path.join(project, "build", "dmg-background@2x.png")

def make(width, height, scale=1):
    # Fondo: degradado vertical de blanco hueso a gris muy claro
    img = Image.new("RGB", (width, height), (250, 250, 252))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / height
        r = int(250 - 8 * t)
        g = int(250 - 8 * t)
        b = int(252 - 6 * t)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    # Título arriba
    try:
        title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(22 * scale))
        sub_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(13 * scale))
    except Exception:
        title_font = ImageFont.load_default()
        sub_font = ImageFont.load_default()

    title = "UPTCBot"
    bbox = draw.textbbox((0, 0), title, font=title_font)
    tx = width // 2 - (bbox[2] - bbox[0]) // 2
    draw.text((tx, int(36 * scale)), title, fill=(40, 40, 45), font=title_font)

    subtitle = "Arrastra el ícono a Applications para instalar"
    bbox = draw.textbbox((0, 0), subtitle, font=sub_font)
    tx = width // 2 - (bbox[2] - bbox[0]) // 2
    draw.text((tx, int(66 * scale)), subtitle, fill=(120, 120, 130), font=sub_font)

    # Flecha grande al centro, entre las dos posiciones de los íconos
    arrow_y = int(220 * scale)
    arrow_color = (180, 180, 190)
    cx1 = int(280 * scale)
    cx2 = int(420 * scale)
    arrow_thickness = int(4 * scale)
    draw.line([(cx1, arrow_y), (cx2, arrow_y)],
              fill=arrow_color, width=arrow_thickness)
    head = int(18 * scale)
    draw.polygon(
        [(cx2 + head, arrow_y),
         (cx2 - 2, arrow_y - head),
         (cx2 - 2, arrow_y + head)],
        fill=arrow_color
    )

    return img

print(f"Escribiendo {out_path} ({W}x{H})")
make(W, H, 1).save(out_path, "PNG")
print(f"Escribiendo {out_path_2x} ({W*2}x{H*2})")
make(W * 2, H * 2, 2).save(out_path_2x, "PNG")
print("✓ Listo")

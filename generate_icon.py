from PIL import Image, ImageDraw, ImageFont
import os

SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

BASE = 1024
base_img = Image.new("RGBA", (BASE, BASE), (0, 0, 0, 0))
draw = ImageDraw.Draw(base_img)

# Rounded rect background
r = 200
draw.rounded_rectangle([(0, 0), (BASE, BASE)], radius=r, fill=(28, 28, 30, 255))

# Inner subtle gradient overlay (lighter top-left to darker bottom-right)
for i in range(BASE):
    t = i / BASE
    alpha = int(30 * (1 - t))
    draw.line([(0, i), (BASE, i)], fill=(255, 255, 255, alpha))

# Gold accent bar at top
bar_h = 8
draw.rounded_rectangle(
    [(BASE // 4, 0), (BASE * 3 // 4, bar_h)],
    radius=bar_h // 2,
    fill=(196, 168, 130, 255),
)

# Circle behind text
cx, cy = BASE // 2, BASE // 2 - 10
cr = BASE // 3
draw.ellipse(
    [(cx - cr, cy - cr), (cx + cr, cy + cr)],
    fill=(40, 40, 42, 255),
    outline=(196, 168, 130, 60),
    width=6,
)

# Try to use a good font, fallback to default
font_size = BASE // 5
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
except:
    try:
        font = ImageFont.truetype("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf", font_size)
    except:
        font = ImageFont.load_default()

# Draw "NL" text
text = "NL"
bbox = draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
tx = cx - tw // 2
ty = cy - th // 2 - 10

# Shadow
draw.text((tx + 4, ty + 4), text, fill=(0, 0, 0, 80), font=font)
# Main text
draw.text((tx, ty), text, fill=(212, 212, 212, 255), font=font)

# Small tagline at bottom
tag = "Legal"
try:
    small_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", BASE // 14)
except:
    small_font = ImageFont.load_default()
tag_bbox = draw.textbbox((0, 0), tag, font=small_font)
tag_w = tag_bbox[2] - tag_bbox[0]
draw.text(
    (cx - tag_w // 2, cy + cr + 30),
    tag,
    fill=(160, 160, 160, 200),
    font=small_font,
)

# Save resized copies
res_dir = "/home/ubuntu/Desktop/legal_assistant/android/app/src/main/res"
for folder, size in SIZES.items():
    resized = base_img.resize((size, size), Image.LANCZOS)
    path = os.path.join(res_dir, folder, "ic_launcher.png")
    # Convert to RGB for PNG save (remove alpha for launcher icon)
    rgb = Image.new("RGB", (size, size), (28, 28, 30))
    rgb.paste(resized, (0, 0), resized)
    rgb.save(path)
    print(f"Saved {path} ({size}x{size})")

print("Done!")

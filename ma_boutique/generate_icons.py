#!/usr/bin/env python3
import os
from PIL import Image

src_path = "assets/icon_smart_stock.png"
src = Image.open(src_path).convert("RGBA")

# Auto-crop: find bounding box of non-transparent/non-white content
# We want to remove outer margins so the design fills 100% of the icon
bbox = src.getbbox()
if bbox:
    src = src.crop(bbox)

# Make it square by taking the larger dimension
w, h = src.size
size = max(w, h)
# Create a square canvas and paste centered
square = Image.new("RGBA", (size, size), (0, 0, 0, 0))
offset_x = (size - w) // 2
offset_y = (size - h) // 2
square.paste(src, (offset_x, offset_y), src)
src = square

densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

for density, size in densities.items():
    icon = src.resize((size, size), Image.Resampling.LANCZOS)
    
    out_path = f"android/app/src/main/res/{density}/ic_launcher.png"
    icon.save(out_path, "PNG")
    print(f"Created {out_path} ({size}x{size})")
    
    round_path = f"android/app/src/main/res/{density}/ic_launcher_round.png"
    icon.save(round_path, "PNG")
    print(f"Created {round_path} ({size}x{size})")

print("Done! Icons now fill 100% of circle (no white background).")

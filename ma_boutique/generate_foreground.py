#!/usr/bin/env python3
from PIL import Image

src_path = "assets/icon_smart_stock.png"
src = Image.open(src_path).convert("RGBA")

# Auto-crop to remove outer margins
bbox = src.getbbox()
if bbox:
    src = src.crop(bbox)

# Make square
w, h = src.size
size = max(w, h)
square = Image.new("RGBA", (size, size), (0, 0, 0, 0))
offset_x = (size - w) // 2
offset_y = (size - h) // 2
square.paste(src, (offset_x, offset_y), src)

# Save cropped version for adaptive icon foreground (1024x1024)
square.resize((1024, 1024), Image.Resampling.LANCZOS).save("assets/icon_foreground.png", "PNG")
print("Created assets/icon_foreground.png (1024x1024) - fills entire canvas")

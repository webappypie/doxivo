#!/usr/bin/env python3
"""
Generates synthetic document images for English and Hindi OCR evaluation.
Uses standard Windows fonts (Arial and Nirmala) to ensure proper glyph shaping.
"""

import os
from PIL import Image, ImageDraw, ImageFont

def render_text_to_image(text_path, out_png_path, font_path, font_size=24, padding=40):
    with open(text_path, "r", encoding="utf-8") as f:
        text = f.read()

    lines = text.strip().split("\n")

    # Load font
    try:
        font = ImageFont.truetype(font_path, font_size)
    except Exception as e:
        print(f"Failed to load {font_path}: {e}")
        font = ImageFont.load_default()

    # Measure canvas size
    dummy_img = Image.new("RGB", (100, 100), (255, 255, 255))
    draw = ImageDraw.Draw(dummy_img)

    max_width = 0
    total_height = padding * 2
    line_heights = []

    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1] + 12 # line spacing
        max_width = max(max_width, w)
        line_heights.append(h)
        total_height += h

    width = max(max_width + (padding * 2), 600)

    # Render image
    img = Image.new("RGB", (width, total_height), (255, 255, 255))
    draw = ImageDraw.Draw(img)

    # Document border
    draw.rectangle([10, 10, width - 10, total_height - 10], outline=(200, 200, 200), width=2)

    current_y = padding
    for i, line in enumerate(lines):
        draw.text((padding, current_y), line, font=font, fill=(20, 20, 20))
        current_y += line_heights[i]

    os.makedirs(os.path.dirname(out_png_path), exist_ok=True)
    img.save(out_png_path, "PNG")
    print(f"[OK] Generated {out_png_path} ({width}x{total_height} px)")

def main():
    fixtures_dir = os.path.join("test", "fixtures", "ocr")
    eng_txt = os.path.join(fixtures_dir, "english_sample.txt")
    eng_png = os.path.join(fixtures_dir, "english_sample.png")
    hin_txt = os.path.join(fixtures_dir, "hindi_sample.txt")
    hin_png = os.path.join(fixtures_dir, "hindi_sample.png")

    arial = "C:/Windows/Fonts/arial.ttf"
    nirmala = "C:/Windows/Fonts/Nirmala.ttc"

    render_text_to_image(eng_txt, eng_png, arial, font_size=22)
    render_text_to_image(hin_txt, hin_png, nirmala, font_size=22)

if __name__ == "__main__":
    main()

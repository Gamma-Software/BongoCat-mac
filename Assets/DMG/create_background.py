#!/usr/bin/env python3
"""
BangoCat DMG Background Generator
Creates a professional background image for the DMG installer
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import sys
    import os
except ImportError:
    print("PIL (Pillow) not available. Install with: pip install Pillow")
    sys.exit(1)


def create_dmg_background(output_path, width=540, height=300):
    """Create a professional DMG background image"""

    # Create image with white background
    image = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(image)

    # Create subtle gradient background
    for y in range(height):
        # Gradient from light blue-gray to white
        gradient_value = int(240 + (15 * y / height))
        color = (gradient_value - 5, gradient_value, gradient_value)
        draw.line([(0, y), (width, y)], fill=color)

    # Colors
    text_color = (80, 80, 80)
    accent_color = (70, 130, 180)  # Steel blue

    # Try to load a font (fallback to default if not available)
    try:
        # Try to find system fonts
        font_paths = [
            "/System/Library/Fonts/Helvetica.ttc",
            "/System/Library/Fonts/Arial.ttf",
            "/Library/Fonts/Arial.ttf",
        ]

        title_font = None
        instruction_font = None

        for font_path in font_paths:
            if os.path.exists(font_path):
                try:
                    title_font = ImageFont.truetype(font_path, 24)
                    instruction_font = ImageFont.truetype(font_path, 14)
                    break
                except (OSError, IOError):
                    continue

        if not title_font:
            title_font = ImageFont.load_default()
            instruction_font = ImageFont.load_default()

    except Exception:
        title_font = ImageFont.load_default()
        instruction_font = ImageFont.load_default()

    # Draw title
    title_text = "BangoCat for macOS"
    title_bbox = draw.textbbox((0, 0), title_text, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    draw.text((title_x, 30), title_text, fill=accent_color, font=title_font)

    # Draw instruction text
    instruction_text = "Drag BangoCat.app to the Applications folder to install"
    instruction_bbox = draw.textbbox((0, 0), instruction_text, font=instruction_font)
    instruction_width = instruction_bbox[2] - instruction_bbox[0]
    instruction_x = (width - instruction_width) // 2
    draw.text(
        (instruction_x, 65), instruction_text, fill=text_color, font=instruction_font
    )

    # Draw arrow pointing to Applications folder (subtle)
    arrow_color = (150, 150, 150)
    arrow_start_x = 320
    arrow_start_y = 140
    arrow_end_x = 370
    arrow_end_y = 140

    # Draw arrow line
    draw.line(
        [(arrow_start_x, arrow_start_y), (arrow_end_x, arrow_end_y)],
        fill=arrow_color,
        width=2,
    )

    # Draw arrow head
    draw.polygon(
        [
            (arrow_end_x, arrow_end_y),
            (arrow_end_x - 8, arrow_end_y - 4),
            (arrow_end_x - 8, arrow_end_y + 4),
        ],
        fill=arrow_color,
    )

    # Add subtle cat silhouette (simple drawing)
    cat_color = (200, 200, 200)
    cat_x = 50
    cat_y = 200

    # Simple cat silhouette
    # Cat body (oval)
    draw.ellipse([cat_x, cat_y, cat_x + 40, cat_y + 25], fill=cat_color)

    # Cat head (circle)
    draw.ellipse([cat_x + 35, cat_y - 15, cat_x + 55, cat_y + 5], fill=cat_color)

    # Cat ears (triangles)
    draw.polygon(
        [(cat_x + 38, cat_y - 15), (cat_x + 42, cat_y - 25), (cat_x + 46, cat_y - 15)],
        fill=cat_color,
    )

    draw.polygon(
        [(cat_x + 47, cat_y - 15), (cat_x + 51, cat_y - 25), (cat_x + 55, cat_y - 15)],
        fill=cat_color,
    )

    # Cat tail (curved)
    for i in range(20):
        tail_x = cat_x - 5 + i
        tail_y = cat_y + 10 + int(5 * (i / 20) ** 2)
        draw.ellipse([tail_x, tail_y, tail_x + 4, tail_y + 8], fill=cat_color)

    # Add version info in corner
    version_text = "v1.5.2"
    draw.text(
        (width - 60, height - 25),
        version_text,
        fill=(180, 180, 180),
        font=instruction_font,
    )

    # Save the image
    image.save(output_path, "PNG", optimize=True)
    print(f"✅ DMG background created: {output_path}")


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 create_background.py <output_path>")
        sys.exit(1)

    output_path = sys.argv[1]

    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    create_dmg_background(output_path)
    print(f"🎨 Professional DMG background created at: {output_path}")


if __name__ == "__main__":
    main()

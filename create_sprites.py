#!/usr/bin/env python3
"""
Simple script to create placeholder PNG sprites for the Otter Drift game.
Creates 128x128 colored rectangles with text labels.
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Create the sprites directory
os.makedirs('assets/images/sprites', exist_ok=True)

# Define sprites with colors and labels
sprites = {
    'otter.png': {'color': (0, 150, 255), 'label': 'OTTER', 'text_color': (255, 255, 255)},
    'log.png': {'color': (139, 69, 19), 'label': 'LOG', 'text_color': (255, 255, 255)},
    'lily.png': {'color': (0, 255, 0), 'label': 'LILY', 'text_color': (0, 0, 0)},
    'heart.png': {'color': (255, 0, 0), 'label': 'HEART', 'text_color': (255, 255, 255)},
    'river_tile.png': {'color': (0, 100, 200), 'label': 'RIVER', 'text_color': (255, 255, 255)},
}

# Create each sprite
for filename, config in sprites.items():
    # Create 128x128 image
    img = Image.new('RGB', (128, 128), config['color'])
    draw = ImageDraw.Draw(img)
    
    # Try to use a default font, fall back to basic if not available
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 16)
    except:
        font = ImageFont.load_default()
    
    # Get text size for centering
    bbox = draw.textbbox((0, 0), config['label'], font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center the text
    x = (128 - text_width) // 2
    y = (128 - text_height) // 2
    
    # Draw the text
    draw.text((x, y), config['label'], fill=config['text_color'], font=font)
    
    # Save the image
    img.save(f'assets/images/sprites/{filename}')
    print(f"Created {filename}")

print("All placeholder sprites created successfully!")



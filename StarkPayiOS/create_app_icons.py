#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw
import math

def create_app_icon(size, name):
    """Create a premium app icon with lightning bolt design"""
    
    # Create image with black background and golden lightning
    img = Image.new('RGBA', (size, size), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Draw circle background with gradient effect
    center = size // 2
    radius = size // 2 - 10
    
    # Create lightning bolt path
    lightning_points = [
        (center - size//4, center - size//3),  # top left
        (center + size//6, center - size//12), # middle right
        (center - size//12, center - size//12), # middle left
        (center + size//4, center + size//3),  # bottom right
        (center - size//6, center + size//12), # middle left
        (center + size//12, center + size//12)  # middle right
    ]
    
    # Draw golden lightning bolt
    draw.polygon(lightning_points, fill=(255, 215, 0, 255), outline=(255, 165, 0, 255))
    
    # Add glow effect
    for i in range(3):
        glow_size = 5 + i * 2
        draw.polygon(lightning_points, outline=(255, 215, 0, 100 - i * 20), width=glow_size)
    
    # Save the icon
    icon_path = f"/Users/davicho/App Hack/StarkPayiOS/StarkPayiOS/Assets.xcassets/AppIcon.appiconset/{name}"
    img.save(icon_path, "PNG")
    print(f"Created {name} ({size}x{size})")

# Create all required iOS app icon sizes
icon_sizes = [
    (1024, "icon-1024.png"),
    (512, "icon-512.png"),
    (256, "icon-256.png"),
    (180, "icon-180.png"),  # iPhone 6 Plus @3x
    (167, "icon-167.png"),  # iPad Pro @2x
    (152, "icon-152.png"),  # iPad @2x
    (120, "icon-120.png"),  # iPhone @3x
    (87, "icon-87.png"),    # iPhone @3x
    (80, "icon-80.png"),    # iPhone @2x
    (76, "icon-76.png"),    # iPad
    (60, "icon-60.png"),    # iPhone @3x
    (58, "icon-58.png"),    # iPhone @2x
    (40, "icon-40.png"),    # iPhone @2x
    (29, "icon-29.png"),    # iPhone @2x
    (20, "icon-20.png"),    # iPhone @1x
]

if __name__ == "__main__":
    for size, name in icon_sizes:
        create_app_icon(size, name)
    
    print("✅ All app icons created successfully!")
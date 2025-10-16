#!/usr/bin/env python3
"""
StarkPay Team Avatar Generator
Professional team representation for Starknet Re{Solve} Hackathon 2024
"""

from PIL import Image, ImageDraw, ImageFont
import math

def create_team_avatar():
    """Create a professional team avatar for StarkPay - ITAM"""
    
    # Canvas setup
    width, height = 800, 800
    img = Image.new('RGB', (width, height), '#000014')
    draw = ImageDraw.Draw(img)
    
    # Colors (based on StarkNet/StarkPay branding)
    primary_blue = '#007AFF'
    secondary_purple = '#5856D6'
    gold = '#FFD700'
    white = '#FFFFFF'
    light_gray = '#F2F2F7'
    
    # Background gradient effect (simulated)
    for y in range(height):
        gradient = int(255 * (y / height))
        color = (0, 0, 20 + gradient // 8)
        draw.line([(0, y), (width, y)], fill=color)
    
    # Central lightning bolt (StarkPay logo inspiration)
    center_x, center_y = width // 2, height // 2
    
    # Lightning bolt points
    bolt_points = [
        (center_x - 40, center_y - 120),
        (center_x + 20, center_y - 120),
        (center_x - 20, center_y - 20),
        (center_x + 40, center_y - 20),
        (center_x + 10, center_y + 40),
        (center_x + 40, center_y + 40),
        (center_x - 40, center_y + 120),
        (center_x - 10, center_y + 20),
        (center_x - 40, center_y - 20)
    ]
    
    # Draw lightning bolt with gradient effect
    draw.polygon(bolt_points, fill=gold, outline=white, width=3)
    
    # Team member positions (4 corners around the lightning)
    positions = [
        (center_x - 200, center_y - 200, "💻", "TECH\nLEAD"),
        (center_x + 200, center_y - 200, "💼", "BUSINESS\nLEAD"),
        (center_x - 200, center_y + 200, "🎨", "DESIGN\nLEAD"),
        (center_x + 200, center_y + 200, "🎤", "PITCH\nLEAD")
    ]
    
    # Draw team member circles and labels
    for x, y, emoji, role in positions:
        # Circle background
        circle_radius = 60
        draw.ellipse(
            [x - circle_radius, y - circle_radius, x + circle_radius, y + circle_radius],
            fill=primary_blue, outline=white, width=4
        )
        
        # Try to use a font, fall back to default
        try:
            emoji_font = ImageFont.truetype("/System/Library/Fonts/Apple Color Emoji.ttc", 40)
            text_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
        except:
            emoji_font = ImageFont.load_default()
            text_font = ImageFont.load_default()
        
        # Emoji (center of circle)
        draw.text((x, y), emoji, fill=white, font=emoji_font, anchor="mm")
        
        # Role text (below circle)
        draw.text((x, y + 100), role, fill=white, font=text_font, anchor="mm")
    
    # Title at top
    try:
        title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica-Bold.ttc", 48)
        subtitle_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 24)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
    
    # Main title
    draw.text((center_x, 80), "⚡ STARKPAY ⚡", fill=gold, font=title_font, anchor="mm")
    draw.text((center_x, 140), "ITAM BLOCKCHAIN TEAM", fill=white, font=subtitle_font, anchor="mm")
    
    # Bottom text
    draw.text((center_x, height - 100), "Lightning payments made simple", fill=light_gray, font=subtitle_font, anchor="mm")
    draw.text((center_x, height - 60), "Starknet Re{Solve} Hackathon 2024", fill=secondary_purple, font=subtitle_font, anchor="mm")
    
    # Decorative elements
    # Corner lightning bolts
    for corner_x, corner_y in [(100, 100), (width-100, 100), (100, height-100), (width-100, height-100)]:
        small_bolt = [
            (corner_x - 15, corner_y - 30),
            (corner_x + 5, corner_y - 30),
            (corner_x - 5, corner_y),
            (corner_x + 15, corner_y),
            (corner_x - 5, corner_y + 30),
            (corner_x - 15, corner_y)
        ]
        draw.polygon(small_bolt, fill=secondary_purple, outline=white, width=1)
    
    return img

def create_ascii_team_logo():
    """Create ASCII version for documentation"""
    ascii_art = """
╔═══════════════════════════════════════════════════════════╗
║                    ⚡ STARKPAY - ITAM ⚡                   ║
║              STARKNET RE{SOLVE} HACKATHON 2024            ║
║                                                           ║
║     💻 TECH LEAD           💼 BUSINESS LEAD              ║
║   iOS Architecture       Strategy & Partnerships          ║
║   Starknet Integration   Market Research                  ║
║                                                           ║
║                        ⚡⚡⚡⚡⚡                         ║
║                   LIGHTNING PAYMENTS                      ║
║                     MADE SIMPLE                          ║
║                        ⚡⚡⚡⚡⚡                         ║
║                                                           ║
║     🎨 DESIGN LEAD          🎤 PITCH LEAD               ║
║   UX/UI Design           Demo & Presentation              ║
║   Visual Identity        Communications                   ║
║                                                           ║
║         "Building the future of mobile crypto"           ║
║          Instituto Tecnológico Autónomo de México        ║
╚═══════════════════════════════════════════════════════════╝
    """
    return ascii_art

if __name__ == "__main__":
    print("Creating StarkPay Team Avatar...")
    
    # Create the image
    team_avatar = create_team_avatar()
    
    # Save the image
    output_path = "starkpay_team_avatar.png"
    team_avatar.save(output_path, "PNG", quality=95)
    
    print(f"Team avatar saved as: {output_path}")
    print("\nASCII Version:")
    print(create_ascii_team_logo())
    
    # Create a smaller version for social media
    social_avatar = team_avatar.resize((400, 400), Image.Resampling.LANCZOS)
    social_avatar.save("starkpay_team_avatar_400x400.png", "PNG", quality=95)
    
    print("Social media version (400x400) also created!")
    print("\n✅ Professional team representation completed!")
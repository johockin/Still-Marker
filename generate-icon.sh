#!/bin/bash

# Still Marker Icon Generator
# Creates a simple, elegant icon in the Chris Marker aesthetic

ICON_DIR="Still Marker/Assets.xcassets/AppIcon.appiconset"
SIZES=(16 32 128 256 512 1024)

echo "🎨 Generating Still Marker icon..."

# Create a temporary directory for working files
TMP_DIR=$(mktemp -d)

# Create base 1024x1024 icon using Python
python3 - <<'EOF'
from PIL import Image, ImageDraw, ImageFont
import os

# Create 1024x1024 image with dark background (lifted black)
size = 1024
img = Image.new('RGB', (size, size), '#1a1a1d')
draw = ImageDraw.Draw(img)

# Draw a subtle frame border (cinematographer's frame)
border_width = 40
border_color = '#E6A532'  # Kodak Gold
draw.rectangle(
    [(border_width, border_width), (size-border_width, size-border_width)],
    outline=border_color,
    width=8
)

# Draw inner frame
inner_border = border_width + 60
draw.rectangle(
    [(inner_border, inner_border), (size-inner_border, size-inner_border)],
    outline=border_color,
    width=4
)

# Add "SM" text in center (Still Marker initials)
try:
    # Try to use a monospace font
    font = ImageFont.truetype('/System/Library/Fonts/Courier.dfont', 280)
except:
    font = ImageFont.load_default()

text = "SM"
# Get text bounding box
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]

# Center the text
x = (size - text_width) // 2
y = (size - text_height) // 2 - 20

# Draw text in Kodak Gold
draw.text((x, y), text, fill=border_color, font=font)

# Save
save_path = os.path.join(os.environ['TMP_DIR'], 'icon_1024.png')
img.save(save_path, 'PNG')
print(f"✅ Created base icon: {save_path}")

EOF

# Check if Python script succeeded
if [ ! -f "$TMP_DIR/icon_1024.png" ]; then
    echo "❌ Failed to create base icon with Python. Trying alternative method..."

    # Fallback: Create a simple gradient icon using sips
    # Create a simple solid color image
    sips -s format png --resampleHeightWidth 1024 1024 -s formatOptions normal --setProperty format png -o "$TMP_DIR/icon_1024.png" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns 2>/dev/null

    if [ ! -f "$TMP_DIR/icon_1024.png" ]; then
        echo "❌ Could not generate icon. Please add manually in Xcode."
        rm -rf "$TMP_DIR"
        exit 1
    fi
fi

# Generate all required sizes
echo "📐 Generating icon sizes..."

for size in "${SIZES[@]}"; do
    echo "  - ${size}x${size}..."
    sips -z $size $size "$TMP_DIR/icon_1024.png" --out "$ICON_DIR/icon_${size}x${size}.png" >/dev/null 2>&1

    # Also create @2x version
    if [ $size -lt 512 ]; then
        double=$((size * 2))
        sips -z $double $double "$TMP_DIR/icon_1024.png" --out "$ICON_DIR/icon_${size}x${size}@2x.png" >/dev/null 2>&1
    fi
done

# Update Contents.json with proper filenames
cat > "$ICON_DIR/Contents.json" <<'JSON'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

# Clean up
rm -rf "$TMP_DIR"

echo "✅ Icon generation complete!"
echo "📦 Icon files created in: $ICON_DIR"
echo ""
echo "Now build the app in Xcode and you should see the new icon!"

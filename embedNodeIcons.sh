#!/bin/bash
set -e  # exit on error

# Step 1: Create a temporary file for the raw image
temp_png=$(mktemp --suffix=.png)

# Run aseprite to export the sheet
aseprite -b ./assets/BTreeIcons.ase --sheet "$temp_png"

# Step 2: Base64 encode the image
base64_data=$(base64 "$temp_png" | tr -d '\n')

# Step 3: Replace the field in haxe code
target_file="./bitdecay/flixel/debug/tools/btree/BTreeIconData.hx"

# Use sed to replace the line
sed -i.bak -E "s|(static inline var nodeIconData = \")data:image/png;base64,[^\"]*(\";)|\1data:image/png;base64,${base64_data}\2|" "$target_file"

# Clean up temp file
rm "$temp_png"

echo "Icon data updated successfully."
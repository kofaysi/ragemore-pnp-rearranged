#!/bin/bash

# Check if necessary commands are available
if ! command -v convert &> /dev/null || ! command -v pdftk &> /dev/null || ! command -v montage &> /dev/null; then
    echo "ImageMagick (convert, montage) and PDFtk are required but not installed."
    exit 1
fi

# Ensure input PDF is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <input.pdf>"
    exit 1
fi

input_pdf="$1"
output_pdf="${input_pdf%.pdf}-rearranged.pdf"
temp_dir="./.temp_files"
mkdir -p "$temp_dir"
page_images=()

# Convert PDF pages to images with lower density
echo "Converting PDF pages to images..."
convert -density 150 -colorspace sRGB "$input_pdf" "$temp_dir/page_%04d.png"

# Process images in pairs, ignoring the first page
for image in "$temp_dir"/page_*.png; do
    page_images+=("$image")
done

# Remove the first page
page_images=("${page_images[@]:1}")

# Ensure the number of pages to process is even
num_pages=${#page_images[@]}
if (( num_pages % 2 != 0 )); then
    echo "The number of pages to process is not even. Please provide a PDF with an even number of pages excluding the first page."
    exit 1
fi

echo "Combining images..."

output_images=()

for (( i=0; i<num_pages; i+=2 )); do
    page1="${page_images[i]}"
    page2="${page_images[i+1]}"
    
    echo "Processing pages: $((i+1)) and $((i+2))"

    # Split pages into top and bottom halves
    convert -density 150 "$page1" -crop 100%x50% -colorspace sRGB "$temp_dir/page1_half_%d.png"
    convert -density 150 "$page2" -crop 100%x50% -colorspace sRGB "$temp_dir/page2_half_%d.png"

    # Get image height to calculate the amount to cut and add
    image_height=$(identify -format "%h" "$temp_dir/page1_half_0.png")
    cut_add_height=$(echo "scale=0; $image_height * 6.6 / 216" | bc)

    # Top half adjustments
    convert "$temp_dir/page1_half_0.png" -gravity South -chop x${cut_add_height} "$temp_dir/page1_half_0_chopped.png"
    convert "$temp_dir/page1_half_0_chopped.png" -gravity North -background white -splice 0x${cut_add_height} "$temp_dir/page1_half_0_adjusted.png"
    
    convert "$temp_dir/page2_half_0.png" -rotate 180 "$temp_dir/page2_half_0_rotated.png"
    convert "$temp_dir/page2_half_0_rotated.png" -gravity North -chop x${cut_add_height} "$temp_dir/page2_half_0_chopped.png"
    convert "$temp_dir/page2_half_0_chopped.png" -gravity South -background white -splice 0x${cut_add_height} "$temp_dir/page2_half_0_rotated_adjusted.png"
    
    # Bottom half adjustments
    convert "$temp_dir/page1_half_1.png" -gravity North -chop x${cut_add_height} "$temp_dir/page1_half_1_chopped.png"
    convert "$temp_dir/page1_half_1_chopped.png" -gravity South -background white -splice 0x${cut_add_height} "$temp_dir/page1_half_1_adjusted.png"
    
    convert "$temp_dir/page2_half_1.png" -rotate 180 "$temp_dir/page2_half_1_rotated.png"
    convert "$temp_dir/page2_half_1_rotated.png" -gravity South -chop x${cut_add_height} "$temp_dir/page2_half_1_chopped.png"
    convert "$temp_dir/page2_half_1_chopped.png" -gravity North -background white -splice 0x${cut_add_height} "$temp_dir/page2_half_1_rotated_adjusted.png"
    
    # Combine the top halves
    echo "Combining top halves of pages: $((i+1)) and $((i+2))"
    montage -mode concatenate -tile 1x \
        "$temp_dir/page1_half_0_adjusted.png" "$temp_dir/page2_half_0_rotated_adjusted.png" \
        "$temp_dir/combined_top_${i}.png"
    
    # Combine the bottom halves
    echo "Combining bottom halves of pages: $((i+1)) and $((i+2))"
    montage -mode concatenate -tile 1x \
        "$temp_dir/page2_half_1_rotated_adjusted.png" "$temp_dir/page1_half_1_adjusted.png" \
        "$temp_dir/combined_bottom_${i}.png"
    
    # Add combined images to output list
    output_images+=("$temp_dir/combined_top_${i}.png")
    output_images+=("$temp_dir/combined_bottom_${i}.png")
done

# Convert combined images back to PDF
echo "Converting combined images back to PDF..."
convert -density 150 -colorspace sRGB "${output_images[@]}" "$output_pdf"

# Clean up
rm -rf "$temp_dir"

echo "Done! Output PDF: $output_pdf"


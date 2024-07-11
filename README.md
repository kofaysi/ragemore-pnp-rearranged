# Ragemore PNP PDF Rearranger Script

This script processes the Ragemode PNP PDF file by converting its pages to images, adjusting the images, and then combining them back into a PDF. The script handles specific image manipulations such as cropping, rotating, and adding white space to ensure the final output matches the desired format.

## Requirements

Ensure the following commands are installed on your system:
- `convert` (ImageMagick)
- `montage` (ImageMagick)
- `pdftk`

## Usage

1. **Save the script**:
   Save the script to a file, for example `process_pdf.sh`.

2. **Make the script executable**:
   ```sh
   chmod +x process_pdf.sh
3. Run the script with the input PDF as an argument:
   ```sh
    ./process_pdf.sh input.pdf
   ```
   The output PDF will be saved with the same name as the input, but with -rearranged appended to the filename (e.g., input-rearranged.pdf).

## Detailed Steps

1. Convert PDF pages to images:  
   The script converts each page of the input PDF to high-resolution images (density 150).

2. Ignore the first page:  
The script processes images in pairs, starting from the second page.

3. Adjust images:  
- Top halves: Cut off a portion from the bottom and add equivalent white space to the top.
- Bottom halves: Cut off a portion from the top and add equivalent white space to the bottom.
- Rotation: Rotate the second page halves as specified.

4. Combine images:  
The script combines the adjusted top halves and bottom halves of consecutive pages.

5. Convert back to PDF:  
The combined images are converted back into a single PDF file.

6. Clean up:  
Temporary files are deleted after the script runs to keep the working directory clean.

## Example

To process a PDF file named example.pdf:
```sh
   ./process_pdf.sh example.pdf
```
This will generate example-rearranged.pdf in the current directory.

## License

This script is provided as-is without any warranty. Use at your own risk.

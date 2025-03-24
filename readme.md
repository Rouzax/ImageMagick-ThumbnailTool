# Image Thumbnail Generator with ImageMagick

This PowerShell script processes images in a specified folder to generate multiple thumbnail versions using the [ImageMagick](https://imagemagick.org/) command-line utility. It dynamically creates thumbnails at different resolutions while maintaining the original image's aspect ratio, and supports multiple output formats including PNG, JPG, WebP, BMP, and GIF.

## Features

- Generates multiple thumbnails with various sizes (2500px, 2000px, 1500px, 1000px, 750px, 500px, and 250px on the longest side)
- Supports common image output formats (PNG, JPG, JPEG, WebP, BMP, GIF)
- Maintains original quality using format-specific optimization settings
- Recursively processes all supported images in the source folder
- Organizes output by format and dimension (e.g., `PNG/1000px/filename-1000px.png`)
- Automatically skips already resized images
- Provides real-time console feedback and detailed error reporting
- Optional parameter to specify the full path to the `magick` executable (if not in `PATH`)

## Requirements

- [ImageMagick](https://imagemagick.org/script/download.php) must be installed and available via the system `PATH`, or specified explicitly via `-MagickPath`
- PowerShell (Windows PowerShell or PowerShell Core)

## Usage

### Parameters

- **`-SourcePath`** (Mandatory): Full path to the folder containing images for processing.
- **`-OutputFormat`** (Mandatory): Desired output format for thumbnails. Valid options:
  - `png` (High compression, 150 DPI)
  - `jpg` / `jpeg` (95% quality, transparency flattened to white, float DCT, optimized Huffman tables)
  - `webp` (High quality)
  - `bmp`
  - `gif` (256 color palette)
- **`-MagickPath`** (Optional): Full path to the `magick` executable. If not provided, the script attempts to use `magick` from the system `PATH`.

### Example Usage

```powershell
# Generate JPG thumbnails
.\ImageMagick-automation.ps1 -SourcePath "C:\Images" -OutputFormat "jpg"

# Generate WebP thumbnails
.\ImageMagick-automation.ps1 -SourcePath "C:\Images" -OutputFormat "webp"

# Generate PNG thumbnails using a custom path to magick.exe
.\ImageMagick-automation.ps1 -SourcePath "C:\Images" -OutputFormat "png" -MagickPath "C:\Tools\ImageMagick\magick.exe"
```

## Output Structure

The script creates a directory structure grouped by format and dimension under the original image folder:

```
C:\Images
│   Image1.jpg
│   Image2.png
│
└───JPG
    ├───1000px
    │       Image1-1000px.jpg
    │       Image2-1000px.jpg
    │
    ├───1500px
    │       Image1-1500px.jpg
    │       Image2-1500px.jpg
    │
    └───... (other sizes)
```

## Format-Specific Optimizations

The script applies optimal settings depending on the output format:

- **PNG**
  - Maximum compression (`compression-level=9`)
  - Sets DPI to 150
- **JPG / JPEG**
  - 95% quality
  - Flatten transparency to white background
  - Use float DCT for better quality
  - Enable Huffman table optimization
  - Disable chroma subsampling (4:4:4) for better color fidelity
- **WebP**
  - Quality set to 95
- **GIF**
  - Limited to 256 colors for compatibility

## Error Handling

- Verifies `magick` availability or fails with a useful message
- Validates source path and scans for valid image files
- Skips already processed images (based on filename)
- Gracefully logs and reports errors without interrupting the entire batch
- Displays original image dimensions and failed command if conversion fails

### Example Output

```
Using ImageMagick from: C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe
Source Path: C:\Images
Output Format: jpg

Searching for image files...
Found 3 image files to process

Processing: photo1.jpg - DONE - Created 5 Thumbnails
Processing: logo.png - SKIPPED (No thumbnails needed)
Processing: banner.webp - DONE - Created 4 Thumbnails

Total processing time: 00:00:15.762
Total thumbnails created: 9

Conversion completed.
```

### Example Error

```
OutputFormat: png
Using ImageMagick from: C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe
Source Path: C:\Image_Test
Output Format: png

Searching for image files...
Found 4 image files to process
Processing: Corrupt_image.jpg - FAILED
Error processing Corrupt_image.jpg: Invalid dimensions for image
Processing: Image1.png - DONE - Created 7 Thumbnails
Processing: Image2.png - DONE - Created 7 Thumbnails
Processing: Image3.jpg - DONE - Created 7 Thumbnails
Total processing time: 00:00:49.349
Total thumbnails created: 21
```

## Notes

- The script skips thumbnail generation if the original image is smaller than the target size
- Existing thumbnails are automatically overwritten
- All thumbnails are resized using the **Lanczos** algorithm (high-quality resampling)
- Metadata (EXIF, IPTC, etc.) is stripped from thumbnails to reduce file size

## Contributing

Feel free to submit bug reports, feature requests, or pull requests via the GitHub repository.
```

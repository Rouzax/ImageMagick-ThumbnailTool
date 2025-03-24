<#
.SYNOPSIS
    Automates the creation of image thumbnails using ImageMagick.

.DESCRIPTION
    This script scans for image files in a given source directory (excluding files that already
    include dimension suffixes) and generates thumbnails at various predefined dimensions. The
    thumbnails are created using the ImageMagick CLI tool and saved in a format-specific subdirectory
    in the desired output format.
    
    For JPEG output, the script always outputs files with a .jpg extension even if the source file 
    extension is .jpeg.

.PARAMETER SourcePath
    The directory path where the original image files are located.

.PARAMETER OutputFormat
    The desired output image format for the thumbnails.
    Valid values are: png, jpg, jpeg, webp, bmp, gif.

.PARAMETER MagickPath
    Optional. The full path to the ImageMagick executable. If not specified, the script will use 
    'magick' from the system path.

.EXAMPLE
    .\ImageMagick-automation.ps1 -SourcePath "C:\Images" -OutputFormat "jpg"

.NOTES
    Ensure that ImageMagick is installed and accessible. If MagickPath is provided, the script will 
    verify its existence.
#>

param(
    [Parameter(
        Mandatory = $true
    )]
    [string] $SourcePath,

    [Parameter(
        Mandatory = $true
    )]
    [ValidateSet('png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif')]
    [string] $OutputFormat,

    [Parameter(
        Mandatory = $false
    )]
    [string] $MagickPath
)

#-------------------------------------------
function Write-StatusMessage {
    <#
    .SYNOPSIS
        Writes a formatted status message to the console.

    .DESCRIPTION
        This function displays a status message prefixed with a dash. It shows the main status
        message in a specified foreground color and can optionally display additional information.

    .PARAMETER Status
        The main status message text.

    .PARAMETER Color
        The foreground color for the status message.

    .PARAMETER AdditionalInfo
        Optional additional information to display after the status message.

    .EXAMPLE
        Write-StatusMessage "DONE" "Green" "Created 3 Thumbnails"
    #>
    param(
        [string]$Status,
        [string]$Color,
        [string]$AdditionalInfo = ""
    )
    Write-Host " - " -NoNewline
    Write-Host $Status -ForegroundColor $Color -NoNewline
    if ($AdditionalInfo) {
        Write-Host " - $AdditionalInfo"
    } else {
        Write-Host ""
    }
}

#-------------------------------------------
function Write-LabeledValue {
    <#
    .SYNOPSIS
        Writes a label and its corresponding value to the console.

    .DESCRIPTION
        This function outputs a label (with a specified color) immediately followed by a value.
        It is useful for displaying configuration details or status information in a formatted way.

    .PARAMETER Label
        The label to display.

    .PARAMETER Value
        The value associated with the label.

    .PARAMETER LabelColor
        The foreground color for the label text. Defaults to "Cyan".

    .PARAMETER ValueColor
        The foreground color for the value text. Defaults to "White".

    .PARAMETER NoNewline
        A switch indicating whether to avoid adding a new line after printing the value.

    .EXAMPLE
        Write-LabeledValue "Source Path: " "C:\Images"
    #>
    param(
        [string]$Label,
        [string]$Value,
        [string]$LabelColor = "Cyan",
        [string]$ValueColor = "White",
        [switch]$NoNewline
    )
    Write-Host "$Label" -ForegroundColor $LabelColor -NoNewline
    if ($NoNewline) {
        Write-Host $Value -ForegroundColor $ValueColor -NoNewline
    } else {
        Write-Host $Value -ForegroundColor $ValueColor
    }
}

#-------------------------------------------
function Write-ErrorDetail {
    <#
    .SYNOPSIS
        Writes detailed error information for a specific image dimension.

    .DESCRIPTION
        This function outputs the error details including the problematic image dimension, the error
        message, and the command that resulted in the error. It formats the output to clearly indicate
        the source of the error.

    .PARAMETER Dimension
        The image dimension (in pixels) for which the error occurred.

    .PARAMETER ErrorMessage
        The error message text.

    .PARAMETER Command
        The command that was executed and resulted in the error.

    .EXAMPLE
        Write-ErrorDetail -Dimension 1000 -ErrorMessage "Output file not created" -Command "magick ... "
    #>
    param(
        [string]$Dimension,
        [string]$ErrorMessage,
        [string]$Command
    )
    Write-Host "For " -NoNewline
    Write-Host "$($Dimension)px" -ForegroundColor Cyan -NoNewline
    Write-Host ":"
    Write-Host "    Error: " -ForegroundColor Red -NoNewline
    Write-Host $ErrorMessage
    Write-Host "    Command: " -ForegroundColor DarkGray -NoNewline
    Write-Host $Command
}

#-------------------------------------------
function Write-ProcessingStart {
    <#
    .SYNOPSIS
        Displays a message indicating the start of processing for a file.

    .DESCRIPTION
        This function writes a message to the console to indicate that processing has begun
        for the specified file. It formats the file name in a distinct color.

    .PARAMETER Filename
        The name of the file that is being processed.

    .EXAMPLE
        Write-ProcessingStart "image1.jpg"
    #>
    param([string]$Filename)
    Write-Host "Processing: " -NoNewline
    Write-Host $Filename -ForegroundColor Yellow -NoNewline
}

#-------------------------------------------
# Main Script Logic

# Start the stopwatch
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Initialize total thumbnails counter
$totalThumbnails = 0

# Determine the ImageMagick executable to use
if ([string]::IsNullOrWhiteSpace($MagickPath)) {
    # Try to use 'magick' from the PATH
    $commandInfo = Get-Command magick -ErrorAction SilentlyContinue
    if ($commandInfo) {
        $MagickPath = $commandInfo.Path
    } else {
        Write-LabeledValue "Error: " "ImageMagick (magick) not found in PATH. Please install ImageMagick or specify the MagickPath." "Red"
        Exit 1
    }
} elseif (-not (Test-Path $MagickPath)) {
    Write-LabeledValue "Error: " "ImageMagick executable not found at: $MagickPath" "Red"
    Exit 1
}

Write-LabeledValue "Using ImageMagick from: " $MagickPath
Write-LabeledValue "Source Path: " $SourcePath
Write-LabeledValue "Output Format: " $OutputFormat

# Define desired image dimensions for thumbnails
$Dimensions = @(2500, 2000, 1500, 1000, 750, 500, 250)

# Create the exclude patterns dynamically based on dimensions
$ExcludePatterns = $Dimensions | ForEach-Object { "*${_}px*" }

# Get image file paths excluding the patterns and including only specified extensions
try {
    Write-Host "`nSearching for image files..." -ForegroundColor Cyan
    $ImageFilePaths = Get-ChildItem -Path $SourcePath -Recurse -Exclude $ExcludePatterns -Include *.gif, *.png, *.jpg, *.jpeg, *.webp, *.wep, *.bmp, *.emf -Attributes !Directory
    Write-Host "Found " -NoNewline
    Write-Host $ImageFilePaths.Count -ForegroundColor White -NoNewline
    Write-Host " image files to process"
} catch {
    Write-LabeledValue "Error: " "Unable to retrieve image files from $SourcePath. $_" "Red"
    Exit 1
}

# Check if any image files were found
if ($ImageFilePaths.Count -eq 0) {
    Write-Host "No valid image files found in the source directory." -ForegroundColor Yellow
    Exit 0
}

# Normalize output format: force JPEG outputs to use .jpg extension and use 'jpeg' for processing.
$lowerFormat = $OutputFormat.ToLower()
if ($lowerFormat -eq "jpeg" -or $lowerFormat -eq "jpg") {
    $fileExtension = "jpg"
    $magickFormat = "jpeg"
} else {
    $fileExtension = $lowerFormat
    $magickFormat = $lowerFormat
}

# Create format-specific directory name (in uppercase)
$formatDir = $fileExtension.ToUpper()

foreach ($ImagePath in $ImageFilePaths) {
    Write-ProcessingStart $ImagePath.Name
    
    $imageErrors = @()  # Errors specific to this image
    $createdThumbnailsCount = 0
    
    try {
        # Get the original dimensions of the image using ImageMagick identify
        # -format "%w %h" returns width and height separated by a space
        $imageInfo = & $MagickPath identify -format "%w %h" $ImagePath 2>&1
        if (-not $imageInfo) {
            throw "Unable to retrieve image info"
        }
        $parts = $imageInfo -split "\s+"
        $originalWidth = $parts[0] -as [int]
        $originalHeight = $parts[1] -as [int]
        $longestSide = [Math]::Max($originalWidth, $originalHeight)
        
        if (-not $originalWidth -or -not $originalHeight) {
            throw "Invalid dimensions for image"
        }

        $ImageRootFolder = Split-Path -Path $ImagePath -Parent

        foreach ($Dimension in $Dimensions) {
            if ($longestSide -gt $Dimension) {
                try {
                    # Create nested directory structure: format/dimension
                    $OutputDirectory = Join-Path $ImageRootFolder $formatDir
                    $OutputDirectory = Join-Path $OutputDirectory "$Dimension`px"
                    
                    if (-not (Test-Path $OutputDirectory)) {
                        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
                    }

                    $OutputFile = Join-Path $OutputDirectory "$($ImagePath.BaseName)-$Dimension`px.$fileExtension"
                    
                    # Build ImageMagick command arguments
                    # -strip: remove all metadata (EXIF/IPTC/...)
                    # -filter Lanczos: high quality resampling algorithm (like 'lanczos' in nconvert)
                    # -resize: Resize to fit within a square of ${Dimension}x${Dimension} (preserving aspect ratio)
                    #   The '>' ensures that images are only downscaled (no upscaling)
                    $Arguments = @()
                    $Arguments += "-strip"
                    $Arguments += "-filter"; $Arguments += "Lanczos"
                    $Arguments += "-resize"; $Arguments += "${Dimension}x${Dimension}>"
                    
                    switch ($magickFormat) {
                        'png' {
                            # PNG Compression level (max compression, range 0-9) and set DPI
                            $Arguments += "-define"; $Arguments += "png:compression-level=9"
                            $Arguments += "-density"; $Arguments += "150"
                        }
                        'webp' {
                            # WebP quality setting (balance of quality/size)
                            $Arguments += "-quality"; $Arguments += "95"
                        }
                        'jpeg' {
                            # JPEG quality, merge alpha channel by flattening on white background,
                            # use optimized coding and float DCT method for better quality,
                            # and force no subsampling (4:4:4)
                            $Arguments += "-quality"; $Arguments += "95"
                            $Arguments += "-background"; $Arguments += "white"
                            $Arguments += "-flatten"
                            $Arguments += "-define"; $Arguments += "jpeg:optimize-coding=true"
                            $Arguments += "-define"; $Arguments += "jpeg:dct-method=float"
                            $Arguments += "-sampling-factor"; $Arguments += "4:4:4"
                        }
                        'gif' {
                            # Limit GIF colors to 256
                            $Arguments += "-colors"; $Arguments += "256"
                        }
                    }
                    
                    # Execute ImageMagick conversion:
                    # The command structure: magick [input file] [processing options] [output file]
                    $fullCommand = "$MagickPath `"$ImagePath`" $($Arguments -join ' ') `"$OutputFile`""
                    $processOutput = & $MagickPath $ImagePath @Arguments $OutputFile 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        $errorMessage = ($processOutput | Out-String).Trim()
                        $imageErrors += @{
                            Dimension = $Dimension
                            Error     = "ImageMagick conversion failed (Exit code: $LASTEXITCODE). Error: $errorMessage"
                            Command   = $fullCommand
                        }
                        continue
                    }

                    if (Test-Path $OutputFile) {
                        $createdThumbnailsCount++
                        $totalThumbnails++ # Increment the total counter
                    } else {
                        $imageErrors += @{
                            Dimension = $Dimension
                            Error     = "Output file was not created"
                            Command   = $fullCommand
                        }
                    }
                } catch {
                    $imageErrors += @{
                        Dimension = $Dimension
                        Error     = $_.Exception.Message
                        Command   = $fullCommand
                    }
                }
            }
        }

        if ($imageErrors.Count -eq 0) {
            if ($createdThumbnailsCount -gt 0) {
                Write-StatusMessage "DONE" "Green" "Created $createdThumbnailsCount Thumbnails"
            } else {
                Write-StatusMessage "SKIPPED" "Yellow" "(No thumbnails needed)"
            }
        } else {
            Write-StatusMessage "FAILED" "Red"
            Write-LabeledValue "Errors for " "$($ImagePath.Name):" "White" "Yellow"
            
            foreach ($errormsg in $imageErrors) {
                Write-ErrorDetail -Dimension $errormsg.Dimension -ErrorMessage $errormsg.Error -Command $errormsg.Command
            }
            Write-LabeledValue "Original dimensions: " "${originalWidth}x${originalHeight}"
        }

    } catch {
        Write-StatusMessage "FAILED" "Red"
        Write-Host "Error processing " -NoNewline
        Write-Host $ImagePath.Name -ForegroundColor Yellow -NoNewline
        Write-Host ": " -NoNewline
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
# Stop the stopwatch
$stopwatch.Stop()

# Display the elapsed time and total thumbnails created
Write-LabeledValue "Total processing time: " $stopwatch.Elapsed.ToString('hh\:mm\:ss\.fff')
Write-LabeledValue "Total thumbnails created: " $totalThumbnails
Write-Host "`nConversion completed." -ForegroundColor Cyan

Start-Sleep 4

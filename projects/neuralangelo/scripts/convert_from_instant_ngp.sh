#!/bin/bash

# Improved COLMAP processing script

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if the required argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <input_directory>"
    exit 1
fi

# Use absolute path for the input directory
INPUT_DIR=$(realpath "$1")

# Check if the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory does not exist: $INPUT_DIR"
    exit 1
fi

# Check if colmap_sparse directory exists
if [ ! -d "$INPUT_DIR/colmap_sparse" ]; then
    echo "Error: colmap_sparse directory does not exist in $INPUT_DIR"
    exit 1
fi

# Check if images directory exists
if [ ! -d "$INPUT_DIR/images" ]; then
    echo "Error: images directory does not exist in $INPUT_DIR"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
for cmd in colmap python; do
    if ! command_exists "$cmd"; then
        echo "Error: $cmd is not installed or not in PATH"
        exit 1
    fi
done

# Rename images directory to images_orig
mv "$INPUT_DIR/images" "$INPUT_DIR/images_orig" || { echo "Error: Failed to rename images directory"; exit 1; }

# Copy .bin files
cp "$INPUT_DIR/colmap_sparse/0/"*.bin "$INPUT_DIR/colmap_sparse/" || { echo "Error: Failed to copy .bin files"; exit 1; }

# Process subdirectories
for path in "$INPUT_DIR/colmap_sparse"/*/; do
    m=$(basename "$path")
    if [ "$m" != "0" ]; then
        echo "Processing subdirectory: $m"
        colmap model_merger \
            --input_path1="$INPUT_DIR/colmap_sparse" \
            --input_path2="$INPUT_DIR/colmap_sparse/$m" \
            --output_path="$INPUT_DIR/colmap_sparse" || { echo "Error: model_merger failed for $m"; continue; }
        colmap bundle_adjuster \
            --input_path="$INPUT_DIR/colmap_sparse" \
            --output_path="$INPUT_DIR/colmap_sparse" || { echo "Error: bundle_adjuster failed for $m"; continue; }
    fi
done

# Run image_undistorter
colmap image_undistorter \
    --image_path="$INPUT_DIR/images_orig" \
    --input_path="$INPUT_DIR/colmap_sparse" \
    --output_path="$INPUT_DIR" \
    --output_type=COLMAP || { echo "Error: image_undistorter failed"; exit 1; }

# Run Python scripts with full paths
python "$SCRIPT_DIR/convert_data_to_json.py" --data_dir "$INPUT_DIR" --scene_type object || { echo "Error: convert_data_to_json.py failed"; exit 1; }
python "$SCRIPT_DIR/generate_config.py" --sequence_name "$(basename "$INPUT_DIR")" --data_dir "$INPUT_DIR" --scene_type object --auto_exposure_wb || { echo "Error: generate_config.py failed"; exit 1; }

echo "Script completed successfully."

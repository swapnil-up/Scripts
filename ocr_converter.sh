#!/bin/bash

# Output file
output_file="output.txt"

# Clear the output file if it already exists
> "$output_file"

# Get the total number of JPG files
total_files=$(ls *.jpg 2>/dev/null | wc -l)
current_file=1

# Loop through all JPG files in the current directory
for x in *.jpg; do
    echo "Processing file $current_file of $total_files: $x"
    
    # Use Tesseract to extract text and append it to the output file
    tesseract "$x" - >> "$output_file"
    
    echo "Done $current_file of $total_files"
    
    # Increment the current file counter
    current_file=$((current_file + 1))
done

echo "OCR conversion complete. Text saved in $output_file"


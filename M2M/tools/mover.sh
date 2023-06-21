#!/bin/bash

# Create folders named 0, a, b, c, ..., z
mkdir 0
mkdir {a..z}

# Function to move files to the appropriate folder
move_file() {
    file="$1"
    first_char_lower="$(echo "${file:0:1}" | tr '[:upper:]' '[:lower:]')"

    # Check if the first character is a number or a letter
    if [[ "$first_char_lower" =~ [0-9] ]]; then
        mv -- "$file" "0/"
    elif [[ "$first_char_lower" =~ [a-z] ]]; then
        mv -- "$file" "$first_char_lower/"
    fi
}

# Find files in the current directory and call the move_file function for each
find . -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' file; do
    # Remove the leading "./" from the file name
    file_name="${file#./}"
    move_file "$file_name"
done

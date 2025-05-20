#!/bin/bash
# This script adds WebKit.framework to the project
# Run this script from the project root directory

# Path to project file
PROJECT_FILE="AnimalGestioneProject.xcodeproj/project.pbxproj"

# Check if the file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Project file not found at $PROJECT_FILE"
    exit 1
fi

# Backup the original file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

# Fix the OTHER_LDFLAGS by replacing empty framework entries
sed -i '' 's/-framework ""-framework ""-framework ""/-framework "WebKit"/g' "$PROJECT_FILE"
sed -i '' 's/-framework ""-framework ""/-framework "WebKit"/g' "$PROJECT_FILE"

echo "WebKit framework has been added to the project."
echo "Please clean and rebuild your project in Xcode."

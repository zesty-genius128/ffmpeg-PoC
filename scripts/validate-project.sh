#!/bin/bash

# Project Validation Script
# Checks that all required files and structure are in place

set -e

echo "🔍 Validating FFmpeg PoC Project Structure"
echo "=========================================="

ERRORS=0

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1"
    else
        echo "❌ Missing: $1"
        ((ERRORS++))
    fi
}

# Function to check if directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo "✅ $1/"
    else
        echo "❌ Missing directory: $1/"
        ((ERRORS++))
    fi
}

echo "📁 Checking project structure..."

# Root files
check_file "package.json"
check_file "app.json"
check_file "App.tsx"
check_file "tsconfig.json"

# Test directory
check_dir "test"
check_dir "test/videos"
check_file "test/videos/README.md"

# Modules
check_dir "modules"
check_dir "modules/ffmpeg-merge"
check_dir "modules/ffmpeg-merge/src"
check_dir "modules/ffmpeg-merge/ios"

# Native module files
check_file "modules/ffmpeg-merge/expo-module.config.json"
check_file "modules/ffmpeg-merge/src/index.ts"
check_file "modules/ffmpeg-merge/src/FFmpegMerge.types.ts"
check_file "modules/ffmpeg-merge/src/FFmpegMergeModule.ts"
check_file "modules/ffmpeg-merge/src/FFmpegMergeModule.web.ts"
check_file "modules/ffmpeg-merge/ios/FFmpegMergeModule.swift"

# Scripts
check_dir "scripts"
check_file "scripts/setup-test-videos.sh"
check_file "scripts/test-ios.sh"
check_file "scripts/validate-project.sh"

# Documentation
check_dir "docs"

echo ""
echo "📋 Checking package.json dependencies..."

# Check required dependencies
REQUIRED_DEPS=("expo" "expo-file-system" "expo-modules-core" "expo-status-bar" "react" "react-native")

for dep in "${REQUIRED_DEPS[@]}"; do
    if grep -q "\"$dep\"" package.json; then
        echo "✅ Dependency: $dep"
    else
        echo "❌ Missing dependency: $dep"
        ((ERRORS++))
    fi
done

echo ""
echo "🔧 Checking file permissions..."

EXECUTABLE_SCRIPTS=("scripts/setup-test-videos.sh" "scripts/test-ios.sh" "scripts/validate-project.sh")

for script in "${EXECUTABLE_SCRIPTS[@]}"; do
    if [ -x "$script" ]; then
        echo "✅ Executable: $script"
    else
        echo "❌ Not executable: $script"
        echo "   Fix with: chmod +x $script"
        ((ERRORS++))
    fi
done

echo ""
echo "📱 Checking app.json configuration..."

if grep -q "com.ffmpegpoc.app" app.json; then
    echo "✅ Bundle identifier configured"
else
    echo "❌ Bundle identifier not set"
    ((ERRORS++))
fi

echo ""
echo "=================================="

if [ $ERRORS -eq 0 ]; then
    echo "🎉 Project validation PASSED!"
    echo "All required files and structure are in place."
    echo ""
    echo "Next steps:"
    echo "1. Run: npm install"
    echo "2. Generate test videos: ./scripts/setup-test-videos.sh"
    echo "3. Test on iOS: ./scripts/test-ios.sh"
else
    echo "❌ Project validation FAILED!"
    echo "Found $ERRORS issue(s) that need to be addressed."
    exit 1
fi
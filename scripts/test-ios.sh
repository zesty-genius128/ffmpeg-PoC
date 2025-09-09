#!/bin/bash

# Automated iOS Testing Script for FFmpeg PoC
# Tests the video merge functionality on iOS simulator or device

set -e

echo "🧪 Testing FFmpeg Merge PoC on iOS"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "modules/ffmpeg-merge" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "📋 Checking dependencies..."

if ! command_exists npx; then
    echo "❌ npm/npx not found. Please install Node.js"
    exit 1
fi

if ! command_exists expo; then
    echo "📦 Installing Expo CLI..."
    npm install -g @expo/cli
fi

# Setup test videos
echo "🎬 Setting up test videos..."
if [ ! -f "test/videos/input1.mp4" ] || [ ! -f "test/videos/input2.mp4" ]; then
    echo "📹 Generating test videos..."
    ./scripts/setup-test-videos.sh
else
    echo "✅ Test videos already exist"
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Pre-build check
echo "🔧 Running pre-build checks..."

# Check TypeScript compilation
echo "  - TypeScript compilation..."
npx tsc --noEmit --skipLibCheck

# Build for iOS
echo "🏗️ Building for iOS..."
echo "This will open Expo Go or build the standalone app..."
echo ""
echo "TESTING STEPS:"
echo "1. The app will start on iOS simulator/device"
echo "2. Tap 'Copy Test Videos Info' to see instructions"
echo "3. Copy test videos to the app's documents directory:"
echo "   - Use simulator's device menu > Photos to add videos"
echo "   - Or use iTunes file sharing on physical device"
echo "   - Videos should be named: input1.mp4, input2.mp4"
echo "4. Tap 'Merge Test Videos' to test the functionality"
echo "5. Verify the merge completes and shows success message"
echo ""

# Start the app
echo "🚀 Starting iOS app..."
npx expo run:ios

echo ""
echo "📊 Test Results:"
echo "==============="
echo "If the app:"
echo "✅ Builds and runs without errors"
echo "✅ Shows the FFmpeg PoC UI"
echo "✅ Displays progress during merge (0% → 100%)"
echo "✅ Shows success message with output file path"
echo "✅ Creates a playable merged video file"
echo ""
echo "Then the PoC is working correctly! 🎉"
echo ""
echo "Common issues:"
echo "• 'Module not found': Run 'npm install' and rebuild"
echo "• 'Test videos not found': Use 'Copy Test Videos Info' button"
echo "• 'Merge failed': Check iOS logs in Xcode console"
echo ""
echo "For manual verification:"
echo "• Check app documents directory for merged_output.mp4"
echo "• Duration should be ~10 seconds (5+5 from inputs)"
echo "• File size should be sum of inputs ± 5%"
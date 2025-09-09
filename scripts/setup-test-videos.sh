#!/bin/bash

# Setup Test Videos Script
# Generates test video files for FFmpeg PoC

set -e

echo "🎬 Setting up test videos for FFmpeg PoC"

# Check if FFmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ FFmpeg is not installed. Please install FFmpeg first:"
    echo "   brew install ffmpeg  # on macOS"
    echo "   apt-get install ffmpeg  # on Ubuntu"
    exit 1
fi

# Create test directory if it doesn't exist
mkdir -p test/videos

# Generate first test video (5 seconds, 720p, 30fps)
echo "🔨 Generating input1.mp4..."
ffmpeg -y -f lavfi -i testsrc2=duration=5:size=1280x720:rate=30 \
    -f lavfi -i sine=frequency=1000:duration=5 \
    -c:v libx264 -profile:v baseline -pix_fmt yuv420p \
    -c:a aac -b:a 128k \
    test/videos/input1.mp4

# Generate second test video (5 seconds, 720p, 30fps, different pattern)
echo "🔨 Generating input2.mp4..."
ffmpeg -y -f lavfi -i testsrc=duration=5:size=1280x720:rate=30 \
    -f lavfi -i sine=frequency=500:duration=5 \
    -c:v libx264 -profile:v baseline -pix_fmt yuv420p \
    -c:a aac -b:a 128k \
    test/videos/input2.mp4

# Display file info
echo "✅ Test videos created:"
ls -lh test/videos/*.mp4

echo "📊 Video information:"
echo "--- input1.mp4 ---"
ffprobe -v quiet -show_format -show_streams test/videos/input1.mp4 | grep -E "(duration|width|height|codec_name)"

echo "--- input2.mp4 ---"
ffprobe -v quiet -show_format -show_streams test/videos/input2.mp4 | grep -E "(duration|width|height|codec_name)"

echo "🎉 Test videos ready! You can now test the FFmpeg merge functionality."
# Test Videos

This directory contains test video files for the FFmpeg PoC.

## Required Format
- **Format**: MP4 (H.264 + AAC)
- **Resolution**: 720p or 1080p
- **Duration**: 5-10 seconds each
- **Frame rate**: 30fps
- **Codec**: H.264 baseline profile for compatibility

## Files
- `input1.mp4` - First test video (~5-10 seconds)
- `input2.mp4` - Second test video (~5-10 seconds)

## Note
You'll need to add actual video files here. You can:
1. Create test videos using FFmpeg CLI
2. Use sample videos from online sources
3. Record short clips with your phone and convert to the required format

Example FFmpeg command to create a test video:
```bash
ffmpeg -f lavfi -i testsrc2=duration=5:size=1280x720:rate=30 -c:v libx264 -profile:v baseline -pix_fmt yuv420p input1.mp4
```
# iOS FFmpeg Integration

## Current Implementation

The current Swift implementation uses **AVFoundation** as a fallback to demonstrate the interface. This serves as a working PoC that can be replaced with actual FFmpeg integration.

## FFmpeg Integration Steps

To integrate actual FFmpeg:

### Option 1: Use FFmpeg-kit-iOS (Recommended for PoC)

1. Add FFmpeg-kit-iOS dependency:
```bash
cd ios
pod 'ffmpeg-kit-ios-full', '~> 6.0'
pod install
```

2. Replace AVFoundation calls with FFmpeg-kit:
```swift
import FFmpegKit
import FFmpegKitConfig

// Replace mergeWithAVFoundation with:
private func mergeWithFFmpeg(input1Path: String, input2Path: String, outputPath: String) async throws {
    // Create concat file
    let concatContent = "file '\(input1Path)'\nfile '\(input2Path)'"
    let concatPath = "\(NSTemporaryDirectory())/concat.txt"
    try concatContent.write(toFile: concatPath, atomically: true, encoding: .utf8)
    
    // FFmpeg command
    let command = "-f concat -safe 0 -i \(concatPath) -c copy \(outputPath)"
    
    let session = await FFmpegKit.execute(command)
    let returnCode = await session.getReturnCode()
    
    if !ReturnCode.isSuccess(returnCode) {
        throw NSError(domain: "FFmpegMerge", code: 11, userInfo: [NSLocalizedDescriptionKey: "FFmpeg failed with code: \(returnCode)"])
    }
}
```

### Option 2: Custom FFmpeg Build (Advanced)

1. Build minimal FFmpeg with only required features:
```bash
./configure --enable-cross-compile --arch=arm64 --target-os=darwin \
    --disable-programs --disable-doc --disable-htmlpages --disable-manpages \
    --disable-podpages --disable-txtpages \
    --enable-demuxer=mov --enable-demuxer=mp4 \
    --enable-muxer=mp4 \
    --enable-decoder=h264 --enable-decoder=aac \
    --enable-protocol=file \
    --disable-everything-else
```

2. Link the resulting library and call C APIs directly.

## Frameworks Directory

Place FFmpeg binaries/frameworks in the `Frameworks/` directory:
```
ios/
├── FFmpegMergeModule.swift
├── Frameworks/
│   ├── libavcodec.a
│   ├── libavformat.a
│   ├── libavutil.a
│   └── libswresample.a
└── module.modulemap
```

## Performance Notes

- AVFoundation: ~2-5 seconds for 10-second videos
- FFmpeg with `-c copy`: ~0.5-1 second (no re-encoding)
- FFmpeg with re-encoding: ~5-15 seconds depending on settings

## Binary Size Impact

- AVFoundation: 0 MB (system framework)
- FFmpeg-kit full: ~50-80 MB
- Custom minimal FFmpeg: ~5-15 MB
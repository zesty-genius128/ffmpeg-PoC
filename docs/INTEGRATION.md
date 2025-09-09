# FFmpeg PoC Integration Guide

## Overview

This document outlines how to integrate the FFmpeg video concatenation PoC into the Pulse application.

## Current Implementation

### Architecture Summary
- **Platform**: iOS (primary), Android (stub)
- **Framework**: Expo with custom native modules
- **Fallback**: AVFoundation (for PoC demonstration)
- **Interface**: TypeScript with async/await and progress events

### Key Components

1. **Native Module** (`modules/ffmpeg-merge/`)
   - TypeScript interface and type definitions
   - iOS Swift implementation using AVFoundation (FFmpeg-ready)
   - Web stub (not supported)
   - Event-based progress reporting

2. **Test Infrastructure**
   - Automated test scripts
   - Test video generation
   - Project validation

3. **Example App**
   - Simple UI demonstrating merge functionality
   - Progress tracking and error handling
   - File system integration

## Integration Steps for Pulse

### 1. Copy Native Module

```bash
# Copy the entire native module to Pulse
cp -r modules/ffmpeg-merge /path/to/pulse/modules/

# Install dependencies
cd /path/to/pulse
npm install expo-modules-core expo-file-system
```

### 2. Replace Current VideoConcatModule

Replace the existing Pulse video concatenation module with:

```typescript
import { mergeVideos, onMergeProgress, cancelMerge } from '../modules/ffmpeg-merge/src';

// Replace existing video merge calls with:
const outputPath = await mergeVideos(input1Path, input2Path, outputPath);
```

### 3. Update Progress Handling

```typescript
// Add progress tracking
const progressSubscription = onMergeProgress((progress) => {
  console.log(`Merge progress: ${(progress.progress * 100).toFixed(0)}% - ${progress.phase}`);
  // Update UI progress indicator
});

// Cleanup subscription when done
progressSubscription.remove();
```

### 4. Error Handling Migration

```typescript
try {
  const result = await mergeVideos(input1, input2, output);
  // Handle success
} catch (error) {
  if (error.message.includes('cancelled')) {
    // Handle cancellation
  } else {
    // Handle other errors
  }
}
```

## Performance Comparison

### Current (Pulse with AVFoundation)
- **Time**: ~2-5 seconds for 10-second videos
- **Quality**: No quality loss (copy operation)
- **Memory**: Moderate usage during processing
- **Limitations**: iOS-specific, limited format support

### With FFmpeg (Proposed)
- **Time**: ~0.5-1 second with `-c copy` (no re-encoding)
- **Quality**: Identical to input (copy operation)
- **Memory**: Lower memory usage
- **Benefits**: 
  - Cross-platform (iOS + Android)
  - Better format support
  - More concatenation options
  - Future extensibility for other video operations

## FFmpeg Integration Options

### Phase 1: FFmpeg-kit (Recommended)

**Pros:**
- Quick integration (~1-2 days)
- Proven stability
- Regular updates
- Good documentation

**Cons:**
- Larger binary size (~50-80MB)
- Less control over features

**Implementation:**
```swift
import FFmpegKit

private func mergeWithFFmpeg(input1Path: String, input2Path: String, outputPath: String) async throws {
    let concatContent = "file '\(input1Path)'\nfile '\(input2Path)'"
    let concatPath = "\(NSTemporaryDirectory())/concat.txt"
    try concatContent.write(toFile: concatPath, atomically: true, encoding: .utf8)
    
    let command = "-f concat -safe 0 -i \(concatPath) -c copy \(outputPath)"
    let session = await FFmpegKit.execute(command)
    let returnCode = await session.getReturnCode()
    
    if !ReturnCode.isSuccess(returnCode) {
        throw NSError(domain: "FFmpegMerge", code: 11, 
                     userInfo: [NSLocalizedDescriptionKey: "FFmpeg failed"])
    }
}
```

### Phase 2: Custom FFmpeg Build (Advanced)

**Pros:**
- Minimal binary size (~5-15MB)
- Exact features needed
- Maximum performance
- No external dependencies

**Cons:**
- Complex build system
- Platform-specific compilation
- Maintenance overhead

**Required Features for Concatenation:**
```bash
./configure --enable-cross-compile --arch=arm64 --target-os=darwin \
    --disable-programs --disable-doc \
    --enable-demuxer=mov --enable-demuxer=mp4 \
    --enable-muxer=mp4 \
    --enable-decoder=h264 --enable-decoder=aac \
    --enable-protocol=file \
    --disable-everything-else
```

## Migration Checklist

### Pre-Migration Testing
- [ ] Run `./scripts/validate-project.sh` to verify PoC structure
- [ ] Test PoC on iOS simulator: `./scripts/test-ios.sh`
- [ ] Generate and verify test videos work correctly
- [ ] Document current Pulse video concatenation performance

### Integration Steps
- [ ] Copy native module to Pulse project
- [ ] Install required dependencies
- [ ] Replace existing video concatenation calls
- [ ] Update progress handling and error management
- [ ] Test with Pulse's existing video files
- [ ] Verify no regression in functionality

### Post-Integration Validation
- [ ] Performance benchmark against current implementation
- [ ] Memory usage comparison
- [ ] Battery impact assessment (if measurable)
- [ ] User acceptance testing
- [ ] App Store submission test (binary size limits)

## Risk Mitigation

### Potential Issues & Solutions

1. **Binary Size Rejection**
   - Risk: App Store rejects due to size increase
   - Mitigation: Start with minimal FFmpeg build, measure impact

2. **iOS Sandboxing**
   - Risk: File access restrictions
   - Mitigation: Use app documents directory, proper entitlements

3. **Background Processing**
   - Risk: iOS kills long-running tasks
   - Mitigation: Request background processing time, optimize performance

4. **Memory Pressure**
   - Risk: Large videos cause crashes
   - Mitigation: Process monitoring, chunk processing if needed

5. **Platform Compatibility**
   - Risk: Different behavior on iOS versions
   - Mitigation: Extensive testing on multiple iOS versions

## Success Metrics

### Performance Goals
- Concatenation time: <50% of current implementation
- Memory usage: ≤ current implementation
- Binary size increase: <20MB
- Crash rate: No increase from baseline

### Functional Goals
- Feature parity with current implementation
- Improved error handling and user feedback
- Progress tracking accuracy >95%
- Support for same video formats as current

## Next Steps

1. **Immediate** (1-2 days)
   - Complete PoC testing with actual video files
   - Benchmark performance against current Pulse implementation
   - Test with various video formats and durations

2. **Short-term** (1 week)
   - Integrate FFmpeg-kit into PoC
   - Performance optimization and memory testing
   - Cross-platform Android stub implementation

3. **Medium-term** (2-4 weeks)
   - Full Pulse integration and testing
   - User acceptance testing
   - App Store submission preparation

## Support and Maintenance

### Documentation
- This integration guide
- Native module API documentation
- Performance benchmarking results
- Troubleshooting guide

### Testing
- Automated test suite for video concatenation
- Performance regression testing
- Platform compatibility testing

### Future Enhancements
- Additional video operations (trim, resize, filters)
- Batch processing capabilities
- Hardware acceleration support
- Advanced concatenation options (crossfades, transitions)

---

*This PoC provides a solid foundation for FFmpeg integration in Pulse while maintaining the flexibility to optimize and extend video processing capabilities in the future.*
# FFmpeg Video Merger - React Native Expo PoC

A proof of concept React Native app built with Expo for iOS that demonstrates video merging capabilities using FFmpeg. This PoC is designed to validate the architecture for a larger TikTok-style video creation and sharing app.

## Features

- 📱 **iOS-first Design**: Optimized for iOS devices with tablet support
- 🎬 **Video Selection**: Pick multiple videos from device storage
- ⚡ **Video Merging**: Simulated FFmpeg-based video concatenation
- 📺 **Video Preview**: In-app video playback using expo-av
- 💾 **Export Functionality**: Save merged videos to device gallery
- 🔄 **Real-time Progress**: Visual feedback during processing

## Current Implementation

This PoC demonstrates the complete user interface and workflow for video merging. The actual FFmpeg processing is currently simulated, but the structure is ready for integration with custom FFmpeg binaries.

### Technology Stack

- **React Native**: 0.79.6
- **Expo SDK**: ~53.0.22
- **expo-av**: Video playback and processing
- **expo-document-picker**: File selection
- **expo-media-library**: Device media access
- **expo-file-system**: File operations

## Installation & Setup

### Prerequisites

- Node.js (v20+)
- Expo CLI
- iOS Simulator (for development) or physical iOS device
- Xcode (for iOS builds)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ffmpeg-PoC
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start the development server**
   ```bash
   npm start
   ```

4. **Run on iOS**
   ```bash
   npm run ios
   ```

## Usage

1. **Add Videos**: Tap "Add Video" to select videos from your device
2. **Review Selection**: View selected videos and remove unwanted ones
3. **Merge Videos**: Tap "Merge Videos" when you have 2+ videos selected
4. **Preview Result**: Watch the merged video in the preview player
5. **Export**: Save the merged video to your device gallery

## FFmpeg Integration Roadmap

### Current State (Simulated)
- ✅ UI/UX for video selection and merging
- ✅ File handling and permissions
- ✅ Video preview and playback
- ✅ Simulated processing workflow

### Production Implementation
To integrate actual FFmpeg binaries:

1. **Create Custom Development Build**
   ```bash
   npx create-expo-app --template blank-typescript
   npx expo install expo-dev-client
   npx expo prebuild
   ```

2. **Add FFmpeg Native Module**
   - Install `react-native-ffmpeg` or `ffmpeg-kit-react-native`
   - Configure native bindings for iOS
   - Add required FFmpeg libraries to iOS build

3. **Implement Video Processing**
   ```javascript
   import { FFmpegKit, ReturnCode } from 'ffmpeg-kit-react-native';
   
   const mergeVideos = async (inputVideos, outputPath) => {
     const command = `-i ${inputVideos[0]} -i ${inputVideos[1]} ` +
                    `-filter_complex "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[outv][outa]" ` +
                    `-map "[outv]" -map "[outa]" ${outputPath}`;
     
     const session = await FFmpegKit.execute(command);
     const returnCode = await session.getReturnCode();
     
     if (ReturnCode.isSuccess(returnCode)) {
       return outputPath;
     } else {
       throw new Error('FFmpeg processing failed');
     }
   };
   ```

## Configuration Files

### app.json
```json
{
  "expo": {
    "name": "ffmpeg-PoC",
    "slug": "ffmpeg-PoC",
    "version": "1.0.0",
    "orientation": "portrait",
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.yourcompany.ffmpeg-poc"
    },
    "plugins": [
      "expo-media-library",
      "expo-document-picker",
      "expo-av"
    ]
  }
}
```

## Architecture for Production

### Video Processing Pipeline
1. **Input**: User selects multiple videos
2. **Validation**: Check file formats, sizes, and codecs
3. **Processing**: FFmpeg concatenation with optional effects
4. **Output**: Optimized video for sharing/storage
5. **Export**: Save to gallery or share directly

### Performance Considerations
- **Memory Management**: Process videos in chunks for large files
- **Background Processing**: Use background tasks for long operations
- **Progress Tracking**: Real-time feedback for user experience
- **Error Handling**: Robust error recovery and user messaging

## Future Enhancements

### TikTok-style Features
- **Video Effects**: Filters, transitions, and overlays
- **Audio Mixing**: Background music and sound effects
- **Speed Control**: Slow motion and time-lapse
- **Text Overlays**: Captions and annotations
- **Sharing Integration**: Direct upload to social platforms

### Technical Improvements
- **Custom Codecs**: Optimized video compression
- **Hardware Acceleration**: GPU-accelerated processing
- **Cloud Processing**: Offload heavy operations to server
- **Caching System**: Intelligent video caching and management

## Testing

### Manual Testing Checklist
- [ ] App launches successfully
- [ ] Video selection works on iOS device/simulator
- [ ] Multiple videos can be selected and removed
- [ ] Merge simulation completes successfully
- [ ] Video preview displays correctly
- [ ] Export functionality shows appropriate messages
- [ ] Permissions are requested and handled properly

### Development Testing
```bash
# Test on iOS Simulator
npm run ios

# Test on web (limited functionality)
npm run web

# Build for testing
npx expo build:ios
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## License

This project is a proof of concept for educational and evaluation purposes.

---

**Note**: This PoC demonstrates the architecture and user experience for FFmpeg integration. For production use, implement actual FFmpeg processing with appropriate error handling, performance optimization, and security considerations.
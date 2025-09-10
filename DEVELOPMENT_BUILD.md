# Development Build Configuration for FFmpeg Integration

This document outlines the steps to create a custom development build that includes FFmpeg binaries for video processing.

## Prerequisites

- Xcode (for iOS builds)
- Apple Developer Account (for device testing)
- EAS CLI (Expo Application Services)

## Creating Custom Development Build

### 1. Install EAS CLI
```bash
npm install -g @expo/eas-cli
eas login
```

### 2. Configure for Development Build
```bash
npx expo install expo-dev-client
```

### 3. Create EAS Configuration

Create `eas.json`:
```json
{
  "cli": {
    "version": ">= 5.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "buildConfiguration": "Debug"
      }
    },
    "preview": {
      "distribution": "internal",
      "ios": {
        "buildConfiguration": "Release"
      }
    },
    "production": {
      "ios": {
        "buildConfiguration": "Release"
      }
    }
  },
  "submit": {
    "production": {}
  }
}
```

### 4. Add FFmpeg Native Module

#### Option 1: Using react-native-ffmpeg
```bash
npm install react-native-ffmpeg
```

Add to `app.json`:
```json
{
  "expo": {
    "plugins": [
      [
        "react-native-ffmpeg",
        {
          "package": "min-gpl-lts",
          "ios": {
            "package": "min-gpl-lts"
          }
        }
      ]
    ]
  }
}
```

#### Option 2: Using ffmpeg-kit-react-native
```bash
npm install ffmpeg-kit-react-native
```

### 5. Configure iOS Specific Settings

Update `app.json` for iOS:
```json
{
  "expo": {
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.yourcompany.ffmpeg-poc",
      "buildNumber": "1",
      "infoPlist": {
        "NSPhotoLibraryUsageDescription": "This app needs access to photo library to select and save videos for merging.",
        "NSCameraUsageDescription": "This app needs access to camera to record videos for merging.",
        "NSMicrophoneUsageDescription": "This app needs access to microphone to record audio with videos."
      }
    }
  }
}
```

### 6. Prebuild the Project
```bash
npx expo prebuild
```

### 7. Build Development Client
```bash
eas build --profile development --platform ios
```

## Native Implementation Code

### FFmpeg Integration Example

```javascript
// utils/videoProcessor.js
import { FFmpegKit, ReturnCode, SessionState } from 'ffmpeg-kit-react-native';

export class VideoProcessor {
  static async mergeVideos(inputVideos, outputPath, onProgress) {
    try {
      // Build FFmpeg command for concatenation
      const filterComplex = inputVideos
        .map((_, i) => `[${i}:v][${i}:a]`)
        .join('') + `concat=n=${inputVideos.length}:v=1:a=1[outv][outa]`;
      
      const inputs = inputVideos.map(video => `-i "${video}"`).join(' ');
      
      const command = `${inputs} -filter_complex "${filterComplex}" ` +
                     `-map "[outv]" -map "[outa]" -c:v libx264 -c:a aac "${outputPath}"`;
      
      // Execute FFmpeg command
      const session = await FFmpegKit.execute(command);
      
      // Monitor progress
      FFmpegKit.enableLogCallback((log) => {
        if (onProgress) {
          const progress = this.parseProgress(log.getMessage());
          onProgress(progress);
        }
      });
      
      const returnCode = await session.getReturnCode();
      const state = await session.getState();
      
      if (ReturnCode.isSuccess(returnCode) && SessionState.COMPLETED === state) {
        return outputPath;
      } else {
        const logs = await session.getAllLogsAsString();
        throw new Error(`FFmpeg failed: ${logs}`);
      }
      
    } catch (error) {
      throw new Error(`Video merging failed: ${error.message}`);
    }
  }
  
  static parseProgress(logMessage) {
    // Extract progress from FFmpeg logs
    const timeMatch = logMessage.match(/time=(\d+:\d+:\d+\.\d+)/);
    if (timeMatch) {
      // Convert to percentage based on total duration
      return this.calculateProgress(timeMatch[1]);
    }
    return 0;
  }
  
  static async getVideoInfo(videoPath) {
    const session = await FFmpegKit.execute(`-i "${videoPath}" -hide_banner`);
    const logs = await session.getAllLogsAsString();
    
    // Parse video information from logs
    return this.parseVideoInfo(logs);
  }
}
```

### Usage in Component

```javascript
// components/VideoMerger.js (Production Version)
import { VideoProcessor } from '../utils/videoProcessor';

const mergeVideos = async () => {
  setIsProcessing(true);
  setProgress(0);
  
  try {
    const outputPath = `${FileSystem.documentDirectory}merged_${Date.now()}.mp4`;
    
    const result = await VideoProcessor.mergeVideos(
      selectedVideos.map(v => v.uri),
      outputPath,
      (progress) => setProgress(progress)
    );
    
    setMergedVideoUri(result);
    Alert.alert('Success', 'Videos merged successfully!');
    
  } catch (error) {
    Alert.alert('Error', error.message);
  } finally {
    setIsProcessing(false);
    setProgress(0);
  }
};
```

## Testing the Development Build

### 1. Install on Device
After EAS build completes, install the development build on your iOS device.

### 2. Start Development Server
```bash
npx expo start --dev-client
```

### 3. Scan QR Code
Use the development build to scan the QR code and load your app with FFmpeg capabilities.

## Performance Optimization

### Memory Management
- Process videos in chunks for large files
- Implement proper cleanup of temporary files
- Monitor memory usage during processing

### Background Processing
```javascript
import * as TaskManager from 'expo-task-manager';
import * as BackgroundFetch from 'expo-background-fetch';

// Register background task for video processing
TaskManager.defineTask('VIDEO_PROCESSING', async ({ data, error }) => {
  if (error) {
    console.error('Background task error:', error);
    return;
  }
  
  // Process videos in background
  await VideoProcessor.mergeVideos(data.videos, data.outputPath);
});
```

### Hardware Acceleration
Enable hardware acceleration in FFmpeg commands:
```javascript
const command = `-hwaccel videotoolbox ${inputs} -filter_complex "${filterComplex}" ` +
               `-c:v h264_videotoolbox -c:a aac "${outputPath}"`;
```

## Troubleshooting

### Common Issues

1. **Build Fails**: Ensure Xcode and iOS SDK are up to date
2. **FFmpeg Not Found**: Verify native module installation
3. **Permission Denied**: Check iOS permissions and entitlements
4. **Memory Issues**: Implement proper memory management

### Debug Commands
```bash
# Check build logs
eas build --profile development --platform ios --local

# Debug on device
npx expo run:ios --device

# View logs
npx expo logs --platform ios
```

## Production Considerations

1. **App Store Compliance**: Ensure FFmpeg build complies with App Store guidelines
2. **Binary Size**: Optimize FFmpeg build to reduce app size
3. **Performance**: Profile and optimize video processing performance
4. **Error Handling**: Implement comprehensive error handling and recovery
5. **User Experience**: Provide clear progress feedback and cancellation options
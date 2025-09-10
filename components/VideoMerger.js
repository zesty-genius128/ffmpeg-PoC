import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
  ActivityIndicator,
  Dimensions,
} from 'react-native';
import { Video } from 'expo-av';
import * as DocumentPicker from 'expo-document-picker';
import * as FileSystem from 'expo-file-system';
import * as MediaLibrary from 'expo-media-library';

const { width: screenWidth } = Dimensions.get('window');

export default function VideoMerger() {
  const [selectedVideos, setSelectedVideos] = useState([]);
  const [mergedVideoUri, setMergedVideoUri] = useState(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [hasMediaPermission, setHasMediaPermission] = useState(false);

  useEffect(() => {
    requestPermissions();
  }, []);

  const requestPermissions = async () => {
    try {
      const { status } = await MediaLibrary.requestPermissionsAsync();
      setHasMediaPermission(status === 'granted');
      if (status !== 'granted') {
        Alert.alert('Permission Required', 'Media library access is required for video operations.');
      }
    } catch (error) {
      console.error('Permission request failed:', error);
    }
  };

  const selectVideo = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: 'video/*',
        copyToCacheDirectory: true,
        multiple: false,
      });

      if (!result.canceled && result.assets && result.assets.length > 0) {
        const video = result.assets[0];
        setSelectedVideos(prev => [...prev, video]);
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to select video: ' + error.message);
    }
  };

  const removeVideo = (index) => {
    setSelectedVideos(prev => prev.filter((_, i) => i !== index));
  };

  const clearAllVideos = () => {
    setSelectedVideos([]);
    setMergedVideoUri(null);
  };

  // Simulated video merging function - in a real implementation with FFmpeg,
  // this would call the native FFmpeg binary
  const mergeVideos = async () => {
    if (selectedVideos.length < 2) {
      Alert.alert('Error', 'Please select at least 2 videos to merge.');
      return;
    }

    setIsProcessing(true);
    
    try {
      // This is a simulation of video merging process
      // In a real FFmpeg implementation, you would:
      // 1. Call the native FFmpeg binary with appropriate filters
      // 2. Use concat demuxer or complex filter graphs
      // 3. Output the merged video to a temporary file
      
      // For now, we'll create a placeholder that represents the merging process
      await simulateFFmpegMerge(selectedVideos);
      
      Alert.alert('Success', 'Videos merged successfully! In a real implementation, this would use custom FFmpeg binaries.');
    } catch (error) {
      Alert.alert('Error', 'Failed to merge videos: ' + error.message);
    } finally {
      setIsProcessing(false);
    }
  };

  const simulateFFmpegMerge = async (videos) => {
    // Simulate the FFmpeg merging process
    // In a real implementation, this would be replaced with:
    /*
      const ffmpegCommand = [
        '-i', video1Path,
        '-i', video2Path,
        '-filter_complex', '[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[outv][outa]',
        '-map', '[outv]',
        '-map', '[outa]',
        outputPath
      ];
      
      await FFmpegKit.execute(ffmpegCommand.join(' '));
    */
    
    return new Promise((resolve) => {
      setTimeout(() => {
        // For demo purposes, we'll use the first video as the "merged" result
        setMergedVideoUri(videos[0].uri);
        resolve();
      }, 3000); // Simulate 3 seconds of processing
    });
  };

  const exportVideo = async () => {
    if (!mergedVideoUri || !hasMediaPermission) {
      Alert.alert('Error', 'No merged video to export or missing permissions.');
      return;
    }

    try {
      // In a real implementation, you would save the actual merged video
      // For now, we'll just show a success message
      Alert.alert('Export', 'In a real implementation, the merged video would be saved to the device gallery.');
    } catch (error) {
      Alert.alert('Error', 'Failed to export video: ' + error.message);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>FFmpeg Video Merger</Text>
      <Text style={styles.subtitle}>Proof of Concept for TikTok-style App</Text>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Selected Videos ({selectedVideos.length})</Text>
        
        <TouchableOpacity style={styles.button} onPress={selectVideo}>
          <Text style={styles.buttonText}>Add Video</Text>
        </TouchableOpacity>

        {selectedVideos.length > 0 && (
          <TouchableOpacity style={[styles.button, styles.clearButton]} onPress={clearAllVideos}>
            <Text style={styles.buttonText}>Clear All</Text>
          </TouchableOpacity>
        )}

        {selectedVideos.map((video, index) => (
          <View key={index} style={styles.videoItem}>
            <Text style={styles.videoName} numberOfLines={1}>
              {video.name}
            </Text>
            <TouchableOpacity 
              style={styles.removeButton} 
              onPress={() => removeVideo(index)}
            >
              <Text style={styles.removeButtonText}>Remove</Text>
            </TouchableOpacity>
          </View>
        ))}
      </View>

      <View style={styles.section}>
        <TouchableOpacity 
          style={[styles.button, styles.mergeButton, selectedVideos.length < 2 && styles.disabledButton]} 
          onPress={mergeVideos}
          disabled={selectedVideos.length < 2 || isProcessing}
        >
          {isProcessing ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.buttonText}>
              Merge Videos {selectedVideos.length >= 2 ? `(${selectedVideos.length})` : ''}
            </Text>
          )}
        </TouchableOpacity>

        {isProcessing && (
          <Text style={styles.processingText}>
            Simulating FFmpeg video merge process...
          </Text>
        )}
      </View>

      {mergedVideoUri && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Merged Video Preview</Text>
          <Video
            source={{ uri: mergedVideoUri }}
            style={styles.videoPreview}
            useNativeControls
            resizeMode="contain"
            shouldPlay={false}
          />
          
          <TouchableOpacity style={styles.button} onPress={exportVideo}>
            <Text style={styles.buttonText}>Export to Gallery</Text>
          </TouchableOpacity>
        </View>
      )}

      <View style={styles.infoSection}>
        <Text style={styles.infoTitle}>FFmpeg Integration Notes</Text>
        <Text style={styles.infoText}>
          This PoC demonstrates the UI and workflow for video merging. For production:
        </Text>
        <Text style={styles.infoText}>• Use custom development build with FFmpeg binaries</Text>
        <Text style={styles.infoText}>• Implement react-native-ffmpeg or similar native module</Text>
        <Text style={styles.infoText}>• Add complex video effects and transitions</Text>
        <Text style={styles.infoText}>• Optimize for performance and memory usage</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 8,
    color: '#333',
  },
  subtitle: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 24,
    color: '#666',
  },
  section: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
    color: '#333',
  },
  button: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
    marginBottom: 8,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  clearButton: {
    backgroundColor: '#FF3B30',
  },
  mergeButton: {
    backgroundColor: '#34C759',
    paddingVertical: 16,
  },
  disabledButton: {
    backgroundColor: '#ccc',
  },
  videoItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 12,
    backgroundColor: '#f8f8f8',
    borderRadius: 6,
    marginBottom: 8,
  },
  videoName: {
    flex: 1,
    fontSize: 14,
    color: '#333',
  },
  removeButton: {
    backgroundColor: '#FF3B30',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 4,
  },
  removeButtonText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  processingText: {
    textAlign: 'center',
    fontStyle: 'italic',
    color: '#666',
    marginTop: 8,
  },
  videoPreview: {
    width: screenWidth - 64,
    height: 200,
    borderRadius: 8,
    marginBottom: 12,
  },
  infoSection: {
    backgroundColor: '#e3f2fd',
    borderRadius: 8,
    padding: 16,
    marginBottom: 16,
  },
  infoTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#1976d2',
  },
  infoText: {
    fontSize: 14,
    color: '#1976d2',
    marginBottom: 4,
  },
});
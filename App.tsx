import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View, Button, Alert, Platform } from 'react-native';
import { useState, useEffect } from 'react';
import * as FileSystem from 'expo-file-system';
import { mergeVideos, onMergeProgress, MergeProgress } from './modules/ffmpeg-merge/src';

export default function App() {
  const [isLoading, setIsLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [phase, setPhase] = useState('');
  const [outputPath, setOutputPath] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Subscribe to merge progress updates
    const subscription = onMergeProgress((progressData: MergeProgress) => {
      setProgress(progressData.progress);
      setPhase(progressData.phase);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  const handleMerge = async () => {
    if (Platform.OS !== 'ios') {
      Alert.alert('Not Supported', 'This PoC currently only supports iOS');
      return;
    }

    setIsLoading(true);
    setError(null);
    setOutputPath(null);
    setProgress(0);
    setPhase('');

    try {
      // Define file paths
      const documentsDir = FileSystem.documentDirectory!;
      const input1Path = `${documentsDir}input1.mp4`;
      const input2Path = `${documentsDir}input2.mp4`;
      const outputPath = `${documentsDir}merged_output.mp4`;

      // Check if test videos exist
      const input1Exists = await FileSystem.getInfoAsync(input1Path);
      const input2Exists = await FileSystem.getInfoAsync(input2Path);

      if (!input1Exists.exists || !input2Exists.exists) {
        throw new Error('Test videos not found. Please copy test videos to app documents directory.');
      }

      // Call merge function
      const result = await mergeVideos(input1Path, input2Path, outputPath);
      
      setOutputPath(result);
      Alert.alert('Success!', `Videos merged successfully!\nOutput: ${result}`);
      
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred';
      setError(errorMessage);
      Alert.alert('Error', errorMessage);
    } finally {
      setIsLoading(false);
      setProgress(0);
      setPhase('');
    }
  };

  const copyTestVideos = async () => {
    try {
      const documentsDir = FileSystem.documentDirectory!;
      
      // This is a placeholder - in a real scenario, you'd copy from bundle or download
      Alert.alert(
        'Copy Test Videos',
        'To test the merge functionality:\n\n1. Run the setup script: ./scripts/setup-test-videos.sh\n2. Copy the generated test videos to the app\'s documents directory\n3. Or use iTunes file sharing to add videos named input1.mp4 and input2.mp4',
        [
          {
            text: 'Show Documents Path',
            onPress: () => Alert.alert('Documents Directory', documentsDir)
          },
          { text: 'OK' }
        ]
      );
    } catch (err) {
      Alert.alert('Error', 'Failed to access documents directory');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>FFmpeg PoC</Text>
      <Text style={styles.subtitle}>Video Concatenation Test</Text>
      
      <View style={styles.buttonContainer}>
        <Button 
          title="Copy Test Videos Info" 
          onPress={copyTestVideos}
          disabled={isLoading}
        />
        
        <View style={styles.spacer} />
        
        <Button 
          title={isLoading ? "Merging..." : "Merge Test Videos"}
          onPress={handleMerge}
          disabled={isLoading}
        />
      </View>

      {isLoading && (
        <View style={styles.progressContainer}>
          <Text style={styles.progressText}>
            Progress: {(progress * 100).toFixed(0)}%
          </Text>
          {phase && (
            <Text style={styles.phaseText}>
              Phase: {phase}
            </Text>
          )}
        </View>
      )}

      {outputPath && (
        <View style={styles.resultContainer}>
          <Text style={styles.successText}>✅ Merge Complete!</Text>
          <Text style={styles.pathText} numberOfLines={3}>
            {outputPath}
          </Text>
        </View>
      )}

      {error && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>❌ Error:</Text>
          <Text style={styles.errorMessage} numberOfLines={3}>
            {error}
          </Text>
        </View>
      )}

      <StatusBar style="auto" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 32,
  },
  buttonContainer: {
    width: '100%',
    maxWidth: 300,
  },
  spacer: {
    height: 16,
  },
  progressContainer: {
    marginTop: 32,
    alignItems: 'center',
  },
  progressText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#007AFF',
  },
  phaseText: {
    fontSize: 14,
    color: '#666',
    marginTop: 8,
    textTransform: 'capitalize',
  },
  resultContainer: {
    marginTop: 32,
    alignItems: 'center',
    backgroundColor: '#E8F5E8',
    padding: 16,
    borderRadius: 8,
    width: '100%',
    maxWidth: 300,
  },
  successText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#2E7D2E',
    marginBottom: 8,
  },
  pathText: {
    fontSize: 12,
    color: '#666',
    textAlign: 'center',
  },
  errorContainer: {
    marginTop: 32,
    alignItems: 'center',
    backgroundColor: '#FFEBEE',
    padding: 16,
    borderRadius: 8,
    width: '100%',
    maxWidth: 300,
  },
  errorText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#D32F2F',
    marginBottom: 8,
  },
  errorMessage: {
    fontSize: 12,
    color: '#666',
    textAlign: 'center',
  },
});

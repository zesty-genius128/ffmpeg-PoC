import { NativeModulesProxy } from 'expo-modules-core';

// Import the native module. On web, it will be resolved to FFmpegMerge.web.ts
// and on native platforms to FFmpegMerge.ts
import FFmpegMergeModule from './FFmpegMergeModule';
import { MergeProgress, MergeProgressCallback } from './FFmpegMerge.types';

// Get the native constant value.
export const PI = Math.PI;

/**
 * Merges two video files into a single output video using FFmpeg.
 * 
 * @param input1Path Absolute path to the first video file
 * @param input2Path Absolute path to the second video file  
 * @param outputPath Absolute path where the merged video will be saved
 * @returns Promise that resolves to the output file path when merge is complete
 */
export function mergeVideos(
  input1Path: string,
  input2Path: string,
  outputPath: string
): Promise<string> {
  return FFmpegMergeModule.mergeVideos(input1Path, input2Path, outputPath);
}

/**
 * Cancels the current merge operation if one is in progress.
 */
export function cancelMerge(): Promise<void> {
  return FFmpegMergeModule.cancelMerge();
}

/**
 * Subscribe to merge progress updates.
 * 
 * @param callback Function to call when progress is updated
 * @returns Subscription object that can be used to unsubscribe
 */
export function onMergeProgress(callback: MergeProgressCallback): { remove: () => void } {
  // This is a simplified implementation for the PoC
  // In a real implementation, you would use the native module's event system
  return {
    remove: () => {
      // Cleanup subscription
    }
  };
}

export { MergeProgress, MergeProgressCallback } from './FFmpegMerge.types';
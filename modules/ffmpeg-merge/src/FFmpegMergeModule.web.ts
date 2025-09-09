import { FFmpegMergeModule } from './FFmpegMerge.types';

// Web implementation (stub - FFmpeg won't work in browser)
export default {
  PI: Math.PI,
  
  async mergeVideos(
    input1Path: string,
    input2Path: string,
    outputPath: string
  ): Promise<string> {
    console.warn('FFmpeg merge not supported on web platform');
    throw new Error('FFmpeg merge not supported on web platform');
  },

  async cancelMerge(): Promise<void> {
    console.warn('FFmpeg merge not supported on web platform');
  },
} as FFmpegMergeModule;
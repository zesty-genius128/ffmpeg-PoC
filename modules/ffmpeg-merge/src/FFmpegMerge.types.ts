export interface MergeProgress {
  progress: number;    // 0.0 to 1.0
  phase: string;       // "preparing" | "merging" | "finalizing"
}

export interface FFmpegMergeModule {
  mergeVideos(
    input1Path: string,
    input2Path: string,
    outputPath: string
  ): Promise<string>;  // Returns final output path

  cancelMerge(): Promise<void>;
}

export type MergeProgressCallback = (progress: MergeProgress) => void;
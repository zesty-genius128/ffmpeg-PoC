import ExpoModulesCore
import Foundation
import AVFoundation

// Define the native module for FFmpeg video merging
public class FFmpegMergeModule: Module {
    
    // Current merge operation cancellation token
    private var isCancelled = false
    
    public func definition() -> ModuleDefinition {
        Name("FFmpegMerge")
        
        // Constants
        Constants([
            "PI": Double.pi
        ])
        
        // Events that this module can send to JavaScript
        Events("onMergeProgress")
        
        // Async function to merge two videos
        AsyncFunction("mergeVideos") { (input1: String, input2: String, output: String) -> String in
            return try await self.mergeVideosInternal(input1Path: input1, input2Path: input2, outputPath: output)
        }
        
        // Function to cancel the current merge operation
        AsyncFunction("cancelMerge") { () -> Void in
            self.cancelMergeInternal()
        }
    }
    
    // Internal merge implementation
    private func mergeVideosInternal(input1Path: String, input2Path: String, outputPath: String) async throws -> String {
        self.isCancelled = false
        
        // Send progress update - preparing
        sendEvent("onMergeProgress", [
            "progress": 0.0,
            "phase": "preparing"
        ])
        
        // Validate input files exist
        let input1URL = URL(fileURLWithPath: input1Path)
        let input2URL = URL(fileURLWithPath: input2Path)
        let outputURL = URL(fileURLWithPath: outputPath)
        
        guard FileManager.default.fileExists(atPath: input1Path) else {
            throw NSError(domain: "FFmpegMerge", code: 1, userInfo: [NSLocalizedDescriptionKey: "Input file 1 not found: \(input1Path)"])
        }
        
        guard FileManager.default.fileExists(atPath: input2Path) else {
            throw NSError(domain: "FFmpegMerge", code: 2, userInfo: [NSLocalizedDescriptionKey: "Input file 2 not found: \(input2Path)"])
        }
        
        // Remove output file if it exists
        try? FileManager.default.removeItem(at: outputURL)
        
        // Check if cancelled
        if self.isCancelled {
            throw NSError(domain: "FFmpegMerge", code: 3, userInfo: [NSLocalizedDescriptionKey: "Merge operation cancelled"])
        }
        
        // Send progress update - merging
        sendEvent("onMergeProgress", [
            "progress": 0.3,
            "phase": "merging"
        ])
        
        // For now, use AVFoundation as a fallback since integrating FFmpeg requires additional setup
        // This demonstrates the interface and can be replaced with actual FFmpeg calls later
        try await mergeWithAVFoundation(input1URL: input1URL, input2URL: input2URL, outputURL: outputURL)
        
        // Check if cancelled before finalizing
        if self.isCancelled {
            try? FileManager.default.removeItem(at: outputURL)
            throw NSError(domain: "FFmpegMerge", code: 3, userInfo: [NSLocalizedDescriptionKey: "Merge operation cancelled"])
        }
        
        // Send progress update - finalizing
        sendEvent("onMergeProgress", [
            "progress": 0.9,
            "phase": "finalizing"
        ])
        
        // Verify output file was created
        guard FileManager.default.fileExists(atPath: outputPath) else {
            throw NSError(domain: "FFmpegMerge", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create output file: \(outputPath)"])
        }
        
        // Send completion progress
        sendEvent("onMergeProgress", [
            "progress": 1.0,
            "phase": "completed"
        ])
        
        return outputPath
    }
    
    // Cancel the current merge operation
    private func cancelMergeInternal() {
        self.isCancelled = true
    }
    
    // AVFoundation-based merge implementation (fallback/PoC)
    private func mergeWithAVFoundation(input1URL: URL, input2URL: URL, outputURL: URL) async throws {
        let composition = AVMutableComposition()
        
        // Create video track
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "FFmpegMerge", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to create video track"])
        }
        
        // Create audio track
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "FFmpegMerge", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio track"])
        }
        
        // Load first video
        let asset1 = AVAsset(url: input1URL)
        guard let videoTrack1 = asset1.tracks(withMediaType: .video).first else {
            throw NSError(domain: "FFmpegMerge", code: 7, userInfo: [NSLocalizedDescriptionKey: "No video track in first input"])
        }
        
        let audioTrack1 = asset1.tracks(withMediaType: .audio).first
        
        // Insert first video
        let duration1 = asset1.duration
        try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration1), 
                                      of: videoTrack1, 
                                      at: .zero)
        
        if let audioTrack1 = audioTrack1 {
            try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration1),
                                          of: audioTrack1,
                                          at: .zero)
        }
        
        // Check cancellation
        if self.isCancelled { return }
        
        // Load second video
        let asset2 = AVAsset(url: input2URL)
        guard let videoTrack2 = asset2.tracks(withMediaType: .video).first else {
            throw NSError(domain: "FFmpegMerge", code: 8, userInfo: [NSLocalizedDescriptionKey: "No video track in second input"])
        }
        
        let audioTrack2 = asset2.tracks(withMediaType: .audio).first
        
        // Insert second video after first
        let duration2 = asset2.duration
        try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration2),
                                      of: videoTrack2,
                                      at: duration1)
        
        if let audioTrack2 = audioTrack2 {
            try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration2),
                                          of: audioTrack2,
                                          at: duration1)
        }
        
        // Check cancellation
        if self.isCancelled { return }
        
        // Export the composition
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "FFmpegMerge", code: 9, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        await exportSession.export()
        
        if let error = exportSession.error {
            throw error
        }
        
        if exportSession.status != .completed {
            throw NSError(domain: "FFmpegMerge", code: 10, userInfo: [NSLocalizedDescriptionKey: "Export failed with status: \(exportSession.status.rawValue)"])
        }
    }
}
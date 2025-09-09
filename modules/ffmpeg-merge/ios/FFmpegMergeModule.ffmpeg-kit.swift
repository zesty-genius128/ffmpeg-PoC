import ExpoModulesCore
import Foundation
import FFmpegKit
import FFmpegKitConfig

// FFmpeg-kit implementation (replace FFmpegMergeModule.swift with this)
public class FFmpegMergeModule: Module {
    
    // Current merge operation cancellation token
    private var currentSession: FFmpegSession?
    
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
    
    // Internal merge implementation using FFmpeg-kit
    private func mergeVideosInternal(input1Path: String, input2Path: String, outputPath: String) async throws -> String {
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
        
        // Send progress update - merging
        sendEvent("onMergeProgress", [
            "progress": 0.3,
            "phase": "merging"
        ])
        
        // Create concat file for FFmpeg
        let concatContent = """
        file '\(input1Path)'
        file '\(input2Path)'
        """
        
        let concatPath = "\(NSTemporaryDirectory())/ffmpeg_concat_\(UUID().uuidString).txt"
        try concatContent.write(toFile: concatPath, atomically: true, encoding: .utf8)
        
        // FFmpeg command: concatenate without re-encoding (fast)
        let command = "-f concat -safe 0 -i \"\(concatPath)\" -c copy \"\(outputPath)\""
        
        // Execute FFmpeg command
        let session = await FFmpegKit.execute(command)
        self.currentSession = session
        
        // Check if cancelled
        if await session.getState() == SessionState.cancelled {
            // Cleanup
            try? FileManager.default.removeItem(atPath: concatPath)
            try? FileManager.default.removeItem(at: outputURL)
            throw NSError(domain: "FFmpegMerge", code: 3, userInfo: [NSLocalizedDescriptionKey: "Merge operation cancelled"])
        }
        
        // Check return code
        let returnCode = await session.getReturnCode()
        
        // Cleanup concat file
        try? FileManager.default.removeItem(atPath: concatPath)
        
        if !ReturnCode.isSuccess(returnCode) {
            let logs = await session.getLogsAsString()
            throw NSError(domain: "FFmpegMerge", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "FFmpeg failed with return code: \(returnCode?.getValue() ?? -1)",
                NSLocalizedFailureReasonErrorKey: logs ?? "No logs available"
            ])
        }
        
        // Send progress update - finalizing
        sendEvent("onMergeProgress", [
            "progress": 0.9,
            "phase": "finalizing"
        ])
        
        // Verify output file was created
        guard FileManager.default.fileExists(atPath: outputPath) else {
            throw NSError(domain: "FFmpegMerge", code: 5, userInfo: [NSLocalizedDescriptionKey: "FFmpeg completed but output file not found: \(outputPath)"])
        }
        
        // Send completion progress
        sendEvent("onMergeProgress", [
            "progress": 1.0,
            "phase": "completed"
        ])
        
        self.currentSession = nil
        return outputPath
    }
    
    // Cancel the current merge operation
    private func cancelMergeInternal() {
        if let session = self.currentSession {
            FFmpegKit.cancel(session.getSessionId())
        }
    }
}
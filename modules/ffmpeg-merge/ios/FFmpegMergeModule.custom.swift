import ExpoModulesCore
import Foundation

// Direct FFmpeg C API integration with custom compiled binaries
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
    
    // Internal merge implementation using custom FFmpeg binaries
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
        
        // Use our custom FFmpeg implementation
        try await mergeWithCustomFFmpeg(input1Path: input1Path, input2Path: input2Path, outputPath: outputPath)
        
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
    
    // Custom FFmpeg implementation using our compiled binaries
    private func mergeWithCustomFFmpeg(input1Path: String, input2Path: String, outputPath: String) async throws {
        // For this PoC, we'll shell out to our custom ffmpeg binary
        // In production, you'd use the C API directly for better performance
        
        // Create concat file
        let concatContent = """
        file '\(input1Path)'
        file '\(input2Path)'
        """
        
        let concatPath = "\(NSTemporaryDirectory())/ffmpeg_concat_\(UUID().uuidString).txt"
        try concatContent.write(toFile: concatPath, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(atPath: concatPath)
        }
        
        // Use the system ffmpeg (which should be our compiled version if PATH is set correctly)
        // In production, you'd link directly to the dylibs and call C functions
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/ffmpeg")  // System FFmpeg for now
        task.arguments = [
            "-f", "concat",
            "-safe", "0",
            "-i", concatPath,
            "-c", "copy",
            "-y",  // Overwrite output
            outputPath
        ]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "FFmpegMerge", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "FFmpeg failed with status: \(task.terminationStatus)",
                NSLocalizedFailureReasonErrorKey: output
            ])
        }
    }
}
import AVFoundation
import Foundation

if CommandLine.arguments.count != 3 {
    fputs("Usage: swift transcode_web_video.swift input.mp4 output.mp4\n", stderr)
    exit(2)
}

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])

try? FileManager.default.removeItem(at: output)

let asset = AVURLAsset(url: input)
let compatible = AVAssetExportSession.exportPresets(compatibleWith: asset)
let preferredPresets = [
    AVAssetExportPreset1920x1080,
    AVAssetExportPreset1280x720,
    AVAssetExportPresetHighestQuality
]

guard let preset = preferredPresets.first(where: { compatible.contains($0) }),
      let export = AVAssetExportSession(asset: asset, presetName: preset) else {
    fputs("No compatible export preset for \(input.path)\n", stderr)
    exit(3)
}

export.outputURL = output
export.outputFileType = .mp4
export.shouldOptimizeForNetworkUse = true

let sem = DispatchSemaphore(value: 0)
export.exportAsynchronously {
    sem.signal()
}
sem.wait()

switch export.status {
case .completed:
    print("Wrote \(output.path)")
case .failed:
    fputs("Export failed for \(input.path): \(export.error?.localizedDescription ?? "unknown error")\n", stderr)
    exit(4)
case .cancelled:
    fputs("Export cancelled for \(input.path)\n", stderr)
    exit(5)
default:
    fputs("Export ended with status \(export.status.rawValue) for \(input.path)\n", stderr)
    exit(6)
}

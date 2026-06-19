//
//  VNRecorderAndPlayerViewModel.swift
//  VoiceNotes
//
//  Created by Vincent Xavier on 19/06/26.
//

import Combine
import SwiftUI
import AVFoundation

class VNRecorderAndPlayerViewModel: ObservableObject {
    struct RecordingState {
        var isRecording = false
        var isPaused = false
        var recordingDuration: TimeInterval = 0
        var meterLevel: Float = 0.02
        var wavePhase: CGFloat = 0.0
        var micDenied = false
        var showFullRecordingControls = false
    }
    
    @Published var recordingState = RecordingState()
    private var recorder: AVAudioRecorder?
    private var meterTimer: AnyCancellable?
    private(set) var fileURL: URL?
    
    struct PlayerState {
        var isPlaying = false
        var progress: Double = 0
        var recordings: [URL] = []
        var currentPlayingTime: TimeInterval = 0
    }
    
    @Published var playingState = PlayerState()
    var player: AVAudioPlayer?
    private var timer: AnyCancellable?
    private(set) var playingURL: URL?
    private var isScrubbing = false
    
    // MARK: - Recording
    
    func requestPermission(_ done: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { ok in
            DispatchQueue.main.async {
                done(ok)
            }
        }
    }
    
    func startRecoding() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            let dir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Recordings", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            
            let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
            let url = dir.appendingPathComponent("Voicenote_\(stamp).m4a")
            fileURL = url
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            
            recordingState.isRecording = true
            recordingState.isPaused = false
            recordingState.recordingDuration = 0
            recordingState.meterLevel = 0.02
            recordingState.wavePhase = 0.0
            
            startRecodingMetering()
        } catch { print("Start failed:", error) }
    }
    
    func toggleRecodingPause() {
        if recordingState.isPaused {
            recorder?.record()
            recordingState.isPaused = false
            recordingState.isRecording = true
            startRecodingMetering()
        } else {
            recorder?.pause()
            recordingState.isPaused = true
            recordingState.isRecording = false
            stopRecodingMetering()
        }
    }
    
    func stopRecoding() {
        recorder?.stop()
        recordingState.isRecording = false
        recordingState.isPaused = false
        stopRecodingMetering()
        recorder = nil
    }
    
    func cancelRecoding() {
        recorder?.stop()
        if let url = fileURL { try? FileManager.default.removeItem(at: url) }
        recordingState.isRecording = false
        recordingState.isPaused = false
        stopRecodingMetering()
        recorder = nil
    }
    
    private func startRecodingMetering() {
        meterTimer?.cancel()
        
        // Fire every 0.05s to drive both amplitude (volume) and phase (horizontal scroll)
        meterTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self, let rec = self.recorder, rec.isRecording else { return }
            rec.updateMeters()
            
            self.recordingState.recordingDuration = rec.currentTime
            let power = rec.averagePower(forChannel: 0)
            let level = Self.normalize(power)
            
            // Animate properties linearly so the SwiftUI Shape seamlessly draws intermediate frames
            withAnimation(.linear(duration: 0.05)) {
                self.recordingState.meterLevel = level
                self.recordingState.wavePhase -= 0.2 // Pushes the wave leftward. Increase for faster movement.
            }
        }
    }
    
    private func stopRecodingMetering() { meterTimer?.cancel(); meterTimer = nil }
    
    private static func normalize(_ db: Float) -> Float {
        let floor: Float = -50
        if db <= floor { return 0.02 }
        let clamped = max(min(db, 0), floor)
        return (clamped - floor) / -floor
    }
    
    // MARK: - Player
    
    func playPlayer(_ url: URL?) {
        guard let url else { return }
        if playingState.isPlaying, playingURL == url {
            pausePlayer()
            return
        }
        stopPlayer()
        do {
            player = try AVAudioPlayer(contentsOf: url)
            playingURL = url
            player?.prepareToPlay()
            player?.play()
            playingState.isPlaying = true
            startPlayerProgress()
        } catch { print("Playback failed:", error) }
    }
    
    func pausePlayer() {
        player?.pause()
        playingState.isPlaying = false
        stopPlayerProgress()
    }
    
    func stopPlayer() {
        player?.stop()
        playingState.isPlaying = false
        playingState.progress = 0
        playingState.currentPlayingTime = 0
        stopPlayerProgress()
        player = nil
        playingURL = nil
    }
    
    func seekPlayer(to percentage: Double) {
        guard let player = player else { return }
        let newTime = percentage * player.duration
        player.currentTime = newTime
        
        self.playingState.currentPlayingTime = newTime
        self.playingState.progress = percentage
    }
    
    func handleScrubbing(_ scrubbing: Bool) {
        isScrubbing = scrubbing
        if scrubbing {
            stopPlayerProgress()
        } else if playingState.isPlaying {
            startPlayerProgress()
        }
    }
    
    private func startPlayerProgress() {
        stopPlayerProgress()
        timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self, let player = self.player, !self.isScrubbing else { return }
            if player.isPlaying {
                self.playingState.currentPlayingTime = player.currentTime
                self.playingState.progress = player.duration > 0 ? player.currentTime / player.duration : 0
            } else {
                self.playingState.isPlaying = false
                self.stopPlayerProgress()
            }
            if self.playingState.currentPlayingTime >= player.duration - 0.1 {
                self.playingState.progress = 0
                self.playingState.currentPlayingTime = 0
                player.currentTime = 0
            }
        }
    }
    
    private func stopPlayerProgress() { timer?.cancel(); timer = nil }
    
    //MARK: - recordings
    
    func refreshRecordings() {
        let dir = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Recordings", isDirectory: true)
        guard let dir, let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
        playingState.recordings = files.filter { $0.pathExtension == "m4a" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
    
    func deleteRecording(url: URL) {
        try? FileManager.default.removeItem(at: url)
        if playingURL == url { player?.stop() }
        refreshRecordings()
    }
    
    func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

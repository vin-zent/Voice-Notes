//
//  ContentView.swift
//  VoiceNotes
//
//  Created by Vincent Xavier on 16/06/26.
//

import SwiftUI
import AVFoundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var viewModel = VNRecorderAndPlayerViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // MARK: Header
                HeaderView()
                
                // MARK: Recordings List
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(viewModel.playingState.recordings, id: \.self) { url in
                            RecordingRow(
                                url: url,
                                vm: viewModel,
                                onDelete: { viewModel.deleteRecording(url: url) }
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 120) // Space for bottom controls
                }
            }
            
            // MARK: Bottom Floating Controls
            VStack(spacing: 0) {
                if viewModel.recordingState.isRecording || viewModel.recordingState.isPaused {
                    ActiveRecordingSheet(
                        vm: viewModel,
                        onDone: {
                            viewModel.stopRecoding()
                            viewModel.refreshRecordings()
                            viewModel.recordingState.showFullRecordingControls = false
                        },
                        onCancel: {
                            viewModel.cancelRecoding()
                            viewModel.refreshRecordings()
                            viewModel.recordingState.showFullRecordingControls = false
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    RecordingButton {
                        viewModel.startRecoding()
                        viewModel.recordingState.showFullRecordingControls = false
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.recordingState.isRecording || viewModel.recordingState.isPaused)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.recordingState.showFullRecordingControls)
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            viewModel.requestPermission { ok in viewModel.recordingState.micDenied = !ok }
            viewModel.refreshRecordings()
        }
        .alert("Microphone Access Needed", isPresented: $viewModel.recordingState.micDenied) {
            Button("OK", role: .cancel) {}
            #if canImport(UIKit)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            #endif
        } message: {
            Text("Please allow microphone access to record audio.")
        }
    }
}

// MARK: - Subviews for UI

struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("VoiceNotes")
                    .font(.system(size: 32, weight: .bold))
                Spacer()
                
                CircleButton(icon: "magnifyingglass")
                CircleButton(icon: "ellipsis")
            }
            
            HStack {
                FilterPill(title: "All", isSelected: true)
                FilterPill(title: "Shared", isSelected: false)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct CircleButton: View {
    let icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 40, height: 40)
            .background(Color(.systemGray6))
            .clipShape(Circle())
            .foregroundColor(.primary)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.black : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
    }
}

struct RecordingButton: View {
    let onRecordTap: () -> Void
    
    var body: some View {
        HStack {
            
            Button(action: onRecordTap) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.4))
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 56, height: 56)
                   
                }
                .shadow(color: .red.opacity(0.3), radius: 10, y: 5)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
        
    }
}

struct ActiveRecordingSheet: View {
    @ObservedObject var vm: VNRecorderAndPlayerViewModel
    let onDone: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            Button(action: { vm.recordingState.showFullRecordingControls.toggle() }) {
                Image(systemName: vm.recordingState.showFullRecordingControls ? "chevron.down" : "chevron.up")
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemBackground))
                    .strokeWithCornerRadius(
                        .gray,
                        cornerRadius: 20,
                        corners: .allCorners
                    )
            }
            .padding(.top, -20)
            .zIndex(100)
            
            VStack(spacing: 12) {
                if vm.recordingState.showFullRecordingControls {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Button(action: {}) {
                        Text("Add a note")
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
                
                // MARK: The Waveform Pill Button
                Button {
                    vm.toggleRecodingPause()
                } label: {
                    ZStack {
                        Color(.systemGray6)
                        
                        ZStack {
                            VNWaveView(amplitude: CGFloat(vm.recordingState.meterLevel), phase: vm.recordingState.wavePhase, frequency: 2.5)
                                .fill(Color.blue.opacity(0.3))
                        }
                        .clipShape(Capsule())
                        
                        HStack(spacing: 8) {
                            Image(systemName: vm.recordingState.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 18, weight: .black))
                            Text(vm.timeString(time: vm.recordingState.recordingDuration))
                                .font(.system(.title3, design: .monospaced))
                        }
                        .foregroundColor(.primary)
                    }
                    .frame(height: 64)
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDone) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Done")
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 30)
            .ignoresSafeArea()
            .background(Color(.systemBackground))
            .strokeWithCornerRadius(
                .gray,
                cornerRadius: 32,
                corners: [.topLeft, .topRight]
            )
        }        
    }
}

struct RecordingRow: View {
    let url: URL
    @ObservedObject var vm: VNRecorderAndPlayerViewModel
    let onDelete: () -> Void
    @State private var fileDuration: TimeInterval = 0
    
    var isPlaying: Bool { vm.playingURL == url && (vm.playingState.isPlaying ?? false) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcript placeholder")
                .font(.headline)
            
            Text(url.lastPathComponent)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            HStack {
                Button(action: {
                    if isPlaying { vm.pausePlayer() } else { vm.playPlayer(url) }
                }) {
                    HStack {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        Text(vm.timeString(time: vm.playingURL == url ? vm.playingState.currentPlayingTime : fileDuration))
                            .font(.subheadline.bold())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Menu {
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    CircleButton(icon: "ellipsis")
                }
            }
            
            if vm.playingURL == url {
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { vm.playingState.progress },
                            set: { newValue in vm.seekPlayer(to: newValue) }
                        ),
                        in: 0...1,
                        onEditingChanged: { isScrubbing in
                            vm.handleScrubbing(isScrubbing)
                        }
                    )
                    .tint(.blue)
                    
                    HStack {
                        Text(vm.timeString(time: vm.playingState.currentPlayingTime))
                        Spacer()
                        Text(vm.timeString(time: fileDuration))
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .monospacedDigit()
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Divider().padding(.top, 8)
        }
        .onAppear {
            // Read the audio file's duration when the row appears
            let asset = AVURLAsset(url: url)
            self.fileDuration = CMTimeGetSeconds(asset.duration)
        }
    }
}

#Preview {
    ContentView()
}

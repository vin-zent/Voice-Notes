//
//  VNWaveView.swift
//  VoiceNotes
//
//  Created by Vincent Xavier on 17/06/26.
//

import SwiftUI
// MARK: - Mathematical Sine Wave Shape
struct VNWaveView: Shape {
    var amplitude: CGFloat // How high the wave spikes based on volume
    var phase: CGFloat     // Animates the wave left/right
    var frequency: CGFloat // How many waves fit across the width
    
    // This tells SwiftUI to smoothly interpolate both values between frames
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(amplitude, phase) }
        set {
            amplitude = newValue.first
            phase = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height))
        
        let step: CGFloat = 2.0 // Resolution of the curve
        for x in stride(from: 0, through: width, by: step) {
            let normalizedX = x / width
            let angle = (normalizedX * .pi * 2 * frequency) + phase
            
            // Add a tiny baseline (0.05) so there's always a slight ripple even in silence
            let effectiveAmplitude = max(0.05, amplitude)
            
            // Normalize sine from (-1 to 1) -> (0 to 1) so it anchors to the bottom
            let normalizedSine = (sin(angle) + 1.0) / 2.0
            
            // Scale by amplitude. Cap height at 80% of the button so it doesn't cover text completely.
            let waveHeight = normalizedSine * effectiveAmplitude * (height * 0.8)
            let y = height - waveHeight
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Close the path to form a solid filled shape at the bottom
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

// MARK: - View Extension for Corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
    
    func strokeWithCornerRadius<S: ShapeStyle>(
        _ strokeColor: S,
        lineWidth: CGFloat = 0.5,
        cornerRadius: CGFloat,
        corners: UIRectCorner = .allCorners
    ) -> some View {
        self
            .overlay(
                RoundedCorner(radius: cornerRadius, corners: corners)
                    .stroke(strokeColor, lineWidth: lineWidth)
            )
            .clipShape(
                RoundedCorner(radius: cornerRadius, corners: corners)
            )
    }
}
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}




import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

#if canImport(AppKit)
// Helper view to capture right-clicks on macOS
struct RightClickDetector: NSViewRepresentable {
    var onRightClick: () -> Void
    
    func makeNSView(context: Context) -> RightClickNSView {
        let view = RightClickNSView()
        view.onRightClick = onRightClick
        return view
    }
    
    func updateNSView(_ nsView: RightClickNSView, context: Context) {
        nsView.onRightClick = onRightClick
    }
}

final class RightClickNSView: NSView {
    var onRightClick: (() -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
        super.rightMouseDown(with: event)
    }
}
#endif

struct ClickMonitorView: View {
    @State private var monitor = ClickMonitor()
    @State private var showingSettings = false
    @State private var ripples: [RippleEffect] = []
    
    // Settings - persisted with @AppStorage
    @AppStorage("allowingDuration") private var allowingDuration: Double = 3.0
    @AppStorage("prohibitingDuration") private var prohibitingDuration: Double = 2.0
    
    // Ripple effect model
    struct RippleEffect: Identifiable {
        let id = UUID()
        let position: CGPoint
        let color: Color
    }
    
    var body: some View {
        ZStack {
            // Background gradient to showcase glass effects
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3),
                    Color.pink.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GlassEffectContainer(spacing: 20.0) {
                VStack(spacing: 30) {
                    // Status Display
                    VStack(spacing: 15) {
                        HStack {
                            Text("Click Monitor")
                                .font(.largeTitle)
                                .bold()
                            
                            Spacer()
                            
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Settings")
                        }
                        
                        // Phase Indicator
                        PhaseIndicatorView(
                            phase: monitor.currentPhase,
                            allowingDuration: allowingDuration,
                            prohibitingDuration: prohibitingDuration
                        )
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 10))
                        
                        // Click Counter
                        Text("Clicks: \(monitor.clickCount)")
                            .font(.title2)
                            .monospacedDigit()
                            .padding()
                            .glassEffect(.regular, in: .capsule)
                        
                        // Error Message Display
                        if let errorMessage = monitor.errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.white)
                                .font(.headline)
                                .padding()
                                .glassEffect(.regular.tint(.red), in: .rect(cornerRadius: 8))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
            
                    Spacer()
                    
                    // Click Detection Area
                    ZStack {
                        // Intense colored background to boost glass effect
                        RoundedRectangle(cornerRadius: 16)
                            .fill(clickButtonColor.opacity(0.6))

                        VStack(spacing: 8) {
                            Text(isClickDisabled ? "DISABLED" : "CLICK HERE")
                                .font(.title)
                                .bold()
                                .foregroundStyle(.primary)

                            Text("Left or Right Click")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        
                        // Ripple effects overlay
                        GeometryReader { geometry in
                            ForEach(ripples) { ripple in
                                RippleView(color: ripple.color)
                                    .position(ripple.position)
                            }
                        }
                        
                        #if canImport(AppKit)
                        // Right-click detection overlay
                        RightClickDetector {
                            handleClick()
                        }
                        .allowsHitTesting(!isClickDisabled)
                        #endif
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .contentShape(Rectangle())
                    .glassEffect(intensiveGlassEffect, in: .rect(cornerRadius: 16))
                    .shadow(color: clickButtonColor.opacity(0.5), radius: 30, y: 15)
                    .onTapGesture { location in
                        handleClick(at: location)
                    }
                    .disabled(isClickDisabled)
                    .padding(.horizontal)
            
                    Spacer()
                    
                    // Controls
                    VStack(spacing: 15) {
                        Toggle(isOn: Binding(
                            get: { monitor.isAutoCycling },
                            set: { monitor.setAutoCycling($0) }
                        )) {
                            HStack {
                                Image(systemName: monitor.isAutoCycling ? "repeat.circle.fill" : "repeat.circle")
                                Text("Auto Cycling")
                                    .font(.headline)
                            }
                        }
                        .toggleStyle(.switch)
                        .padding()
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 10))
                        
                        if !monitor.isAutoCycling {
                            HStack(spacing: 15) {
                                Button("Start Cycle") {
                                    monitor.startCycle()
                                }
                                .buttonStyle(.glass)
                                
                                Button("Stop Cycle") {
                                    monitor.stopCycle()
                                }
                                .buttonStyle(.glass)
                            }
                        }
                    }
                    .padding()
                }
                .padding()
            }
        }
        .animation(.default, value: monitor.errorMessage)
        .animation(.default, value: monitor.currentPhase)
        .onAppear {
            // Initialize monitor with saved settings
            monitor.allowingDuration = .seconds(allowingDuration)
            monitor.prohibitingDuration = .seconds(prohibitingDuration)
        }
        .onChange(of: allowingDuration) { _, newValue in
            monitor.allowingDuration = .seconds(newValue)
        }
        .onChange(of: prohibitingDuration) { _, newValue in
            monitor.prohibitingDuration = .seconds(newValue)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                allowingDuration: $allowingDuration,
                prohibitingDuration: $prohibitingDuration
            )
        }
    }
    
    private var isClickDisabled: Bool {
        switch monitor.currentPhase {
        case .allowingClicks:
            return false
        case .prohibitingClicks, .idle:
            return true
        }
    }
    
    private var clickButtonColor: Color {
        switch monitor.currentPhase {
        case .allowingClicks:
            return .green
        case .prohibitingClicks:
            return .red
        case .idle:
            return .gray
        }
    }
    
    // More intensive glass effect with stronger tint and interactive behavior
    private var intensiveGlassEffect: Glass {
        // Use regular glass with full color tint for maximum intensity
        return .regular
            .tint(clickButtonColor)
            .interactive(true)
    }
    
    // Handle click with optional position for ripple effect
    private func handleClick(at location: CGPoint? = nil) {
        monitor.registerClick()
        
        // Add ripple effect
        let ripplePosition = location ?? CGPoint(x: 200, y: 60) // Default center position
        let ripple = RippleEffect(position: ripplePosition, color: clickButtonColor)
        ripples.append(ripple)
        
        // Remove ripple after animation completes
        Task {
            try? await Task.sleep(for: .seconds(1))
            ripples.removeAll { $0.id == ripple.id }
        }
    }
}

// Ripple animation view
struct RippleView: View {
    let color: Color
    @State private var animate = false
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: 3)
            .frame(width: 40, height: 40)
            .scaleEffect(animate ? 3 : 0)
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1)) {
                    animate = true
                }
            }
    }
}

struct PhaseIndicatorView: View {
    let phase: ClickMonitor.Phase
    let allowingDuration: Double
    let prohibitingDuration: Double
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 8)
                        .scaleEffect(isAllowing ? 1.5 : 1.0)
                        .opacity(isAllowing ? 0 : 1)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: isAllowing)
                )
            
            Text(statusText)
                .font(.title3)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(statusColor.opacity(0.2))
        )
    }
    
    private var isAllowing: Bool {
        if case .allowingClicks = phase {
            return true
        }
        return false
    }
    
    private var statusColor: Color {
        switch phase {
        case .allowingClicks:
            return .green
        case .prohibitingClicks:
            return .red
        case .idle:
            return .gray
        }
    }
    
    private var statusText: String {
        switch phase {
        case .allowingClicks:
            return "Clicks ALLOWED (\(String(format: "%.1f", allowingDuration))s)"
        case .prohibitingClicks:
            return "Clicks PROHIBITED (\(String(format: "%.1f", prohibitingDuration))s)"
        case .idle:
            return "Idle - Not Running"
        }
    }
}

#Preview("Main View") {
    ClickMonitorView()
}
#Preview("Settings") {
    SettingsView(
        allowingDuration: .constant(3.0),
        prohibitingDuration: .constant(2.0)
    )
}


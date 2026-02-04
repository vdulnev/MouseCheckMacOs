import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

#if canImport(AppKit)
// Helper view to capture mouse down events on macOS
struct MouseDownDetector: NSViewRepresentable {
    var onClick: (CGPoint) -> Void

    func makeNSView(context: Context) -> MouseDownNSView {
        let view = MouseDownNSView()
        view.onClick = onClick
        return view
    }

    func updateNSView(_ nsView: MouseDownNSView, context: Context) {
        nsView.onClick = onClick
    }
}

final class MouseDownNSView: NSView {
    var onClick: ((CGPoint) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        onClick?(location)
    }

    override func rightMouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        onClick?(location)
    }
}
#endif

struct ClickMonitorView: View {
    @State private var monitor = ClickMonitor()
    @State private var showingSettings = false

    // Settings - persisted with @AppStorage
    @AppStorage("allowingDuration") private var allowingDuration: Double = 3.0
    @AppStorage("prohibitingDuration") private var prohibitingDuration: Double = 2.0
    
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
                    ClickDetectionAreaView(
                        isDisabled: isClickDisabled,
                        color: clickButtonColor,
                        onTap: { monitor.registerClick() }
                    )
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
}

// Click Detection Area View
struct ClickDetectionAreaView: View {
    let isDisabled: Bool
    let color: Color
    let onTap: () -> Void

    // Ripple effect model
    private struct RippleEffect: Identifiable {
        let id = UUID()
        let position: CGPoint
        let color: Color
    }

    @State private var ripples: [RippleEffect] = []

    var body: some View {
        ZStack {
            // Intense colored background to boost glass effect
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.6))

            VStack(spacing: 8) {
                Text(isDisabled ? "DISABLED" : "CLICK HERE")
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
            // Mouse down detection for both left and right clicks
            MouseDownDetector { location in
                handleClick(at: location)
            }
            .allowsHitTesting(!isDisabled)
            #endif
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .contentShape(Rectangle())
        .glassEffect(glassEffect, in: .rect(cornerRadius: 16))
        .shadow(color: color.opacity(0.5), radius: 30, y: 15)
        .disabled(isDisabled)
    }

    private var glassEffect: Glass {
        .regular
            .tint(color)
            .interactive(true)
    }

    private func handleClick(at location: CGPoint? = nil) {
        onTap()

        // Add ripple effect
        let ripplePosition = location ?? CGPoint(x: 200, y: 60)
        let ripple = RippleEffect(position: ripplePosition, color: color)
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


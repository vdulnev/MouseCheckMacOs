//
//  ContentView.swift
//  MouseCheck
//
//  Created by vd on 03.02.2026.
//

import SwiftUI
import Combine
#if canImport(AppKit)
import AppKit
#endif

#if canImport(AppKit)
struct MouseCaptureView: NSViewRepresentable {
    var onRightClick: (CGPoint) -> Void

    func makeNSView(context: Context) -> MouseCaptureNSView {
        let v = MouseCaptureNSView()
        v.onRightClick = onRightClick
        // Ensure the view accepts first responder and receives mouse events
        v.postsFrameChangedNotifications = true
        return v
    }

    func updateNSView(_ nsView: MouseCaptureNSView, context: Context) {
        nsView.onRightClick = onRightClick
    }
}

final class MouseCaptureNSView: NSView {
    var onRightClick: ((CGPoint) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func rightMouseDown(with event: NSEvent) {
        // Convert window location to local view coordinates (origin at bottom-left in AppKit)
        let windowPoint = event.locationInWindow
        let local = convert(windowPoint, from: nil)
        onRightClick?(local)
        super.rightMouseDown(with: event)
    }

    override func otherMouseDown(with event: NSEvent) {
        // Treat other buttons as secondary for logging purposes
        let windowPoint = event.locationInWindow
        let local = convert(windowPoint, from: nil)
        onRightClick?(local)
        super.otherMouseDown(with: event)
    }
}
#endif

// A model representing a single mouse click event
struct MouseClick: Identifiable {
    let id = UUID()
    let timestamp: Date
    let location: CGPoint
    let button: String
    let type: String // down/up/double
    let deltaSincePreviousMs: Double?
}

final class ClickLogger: ObservableObject {
    @Published var clicks: [MouseClick] = []

    private var lastTimestampPerButton: [String: Date] = [:]

    static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    private lazy var timeFormatter: DateFormatter = ClickLogger.timeFormatter

    func log(_ click: MouseClick) {
        var computedClick = click
        let buttonKey = click.button
        if let last = lastTimestampPerButton[buttonKey] {
            let delta = click.timestamp.timeIntervalSince(last) * 1000.0 // ms
            computedClick = MouseClick(
                timestamp: click.timestamp,
                location: click.location,
                button: click.button,
                type: click.type,
                deltaSincePreviousMs: delta
            )
        } else {
            computedClick = MouseClick(
                timestamp: click.timestamp,
                location: click.location,
                button: click.button,
                type: click.type,
                deltaSincePreviousMs: nil
            )
        }

        // Update last timestamp for this button
        lastTimestampPerButton[buttonKey] = click.timestamp

        clicks.insert(computedClick, at: 0)

        // Console output with milliseconds and delta
        let timeString = timeFormatter.string(from: computedClick.timestamp)
        if let delta = computedClick.deltaSincePreviousMs {
            print("[Mouse] \(timeString) - \(computedClick.type) (\(computedClick.button)) at x: \(Int(computedClick.location.x)), y: \(Int(computedClick.location.y)) | +\(String(format: "%.1f", delta)) ms")
        } else {
            print("[Mouse] \(timeString) - \(computedClick.type) (\(computedClick.button)) at x: \(Int(computedClick.location.x)), y: \(Int(computedClick.location.y)) | first")
        }
    }
}

struct ContentView: View {
    @StateObject private var logger = ClickLogger()
    @State private var localLocation: CGPoint = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cursorarrow.click")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Mouse Click Logger")
                    .font(.title2)
                    .bold()
            }

            Text("Click inside this area to generate events. The list below shows the most recent clicks first.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.08))
                Text("Click here")
                    .foregroundStyle(.secondary)
                #if canImport(AppKit)
                // Invisible overlay that captures true right-clicks within this area
                MouseCaptureView { point in
                    // SwiftUI's coordinate system in this container has origin at top-left, but our stored localLocation
                    // is managed by onContinuousHover. For consistent display, we'll log using the point from AppKit here.
                    let click = MouseClick(timestamp: Date(), location: point, button: "secondary", type: "tap", deltaSincePreviousMs: nil)
                    logger.log(click)
                }
                .allowsHitTesting(true)
                .background(Color.clear)
                #endif
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            // Track the pointer location within the view so we can log a local position
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    localLocation = point
                case .ended:
                    break
                }
            }
            // Mouse down
            .onTapGesture(count: 1) {
                let click = MouseClick(timestamp: Date(), location: localLocation, button: "primary", type: "tap", deltaSincePreviousMs: nil)
                logger.log(click)
            }
            // Double click
            .onTapGesture(count: 2) {
                let click = MouseClick(timestamp: Date(), location: localLocation, button: "primary", type: "double-tap", deltaSincePreviousMs: nil)
                logger.log(click)
            }

            Divider()

            // Log list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(logger.clicks) { click in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(ClickLogger.timeFormatter.string(from: click.timestamp))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text("\(click.type)")
                                .font(.caption)
                                .bold()
                            Text("\(click.button)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("x: \(Int(click.location.x))  y: \(Int(click.location.y))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if let delta = click.deltaSincePreviousMs {
                                Text("+\(String(format: "%.1f", delta)) ms")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("first")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

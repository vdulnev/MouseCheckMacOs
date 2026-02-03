//
//  ClickMonitor.swift
//  MouseCheck
//
//  Created by vd on 03.02.2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class ClickMonitor {
    
    // MARK: - Phase Definition
    
    enum Phase: Equatable {
        case idle
        case allowingClicks
        case prohibitingClicks
    }
    
    // MARK: - Published Properties
    
    private(set) var currentPhase: Phase = .idle
    private(set) var clickCount: Int = 0
    private(set) var errorMessage: String?
    private(set) var isAutoCycling: Bool = false
    
    // Configurable durations
    var allowingDuration: Duration = .seconds(3)
    var prohibitingDuration: Duration = .seconds(2)
    
    // MARK: - Private Properties
    
    private var cycleTask: Task<Void, Never>?
    private var shouldInterruptCycle: Bool = false
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    func registerClick() {
        guard currentPhase == .allowingClicks else {
            return
        }
        clickCount += 1
        
        // Immediately interrupt if more than one click detected
        if clickCount > 1 {
            errorMessage = "❌ Multiple clicks detected (\(clickCount)) - only 1 click allowed"
            shouldInterruptCycle = true
            // Don't cancel the task - let it complete naturally
            // Just set the flag so the cycle knows to skip validation
        }
    }
    
    func setAutoCycling(_ enabled: Bool) {
        if enabled {
            startAutoCycling()
        } else {
            stopAutoCycling()
        }
    }
    
    func toggleAutoCycling() {
        setAutoCycling(!isAutoCycling)
    }
    
    func startCycle() {
        guard currentPhase == .idle else { return }
        startSingleCycle()
    }
    
    func stopCycle() {
        stopAutoCycling()
        resetState()
    }
    
    // MARK: - Private Methods
    
    private func startAutoCycling() {
        guard !isAutoCycling else { return }
        isAutoCycling = true
        cycleTask?.cancel()
        cycleTask = Task {
            await runAutoCycle()
        }
    }
    
    private func stopAutoCycling() {
        isAutoCycling = false
        cycleTask?.cancel()
        cycleTask = nil
    }
    
    private func startSingleCycle() {
        cycleTask?.cancel()
        cycleTask = Task {
            await runSingleCycle()
        }
    }
    
    private func resetState() {
        currentPhase = .idle
        clickCount = 0
        errorMessage = nil
        shouldInterruptCycle = false
    }
    
    private func runAutoCycle() async {
        while isAutoCycling && !Task.isCancelled {
            await runSingleCycle()
            
            // If auto cycling was turned off during the cycle, stop
            guard isAutoCycling && !Task.isCancelled else {
                resetState()
                return
            }
        }
    }
    
    private func runSingleCycle() async {
        guard !Task.isCancelled else { return }
        
        // Clear previous error and reset click count
        errorMessage = nil
        clickCount = 0
        shouldInterruptCycle = false
        
        // Phase 1: Allowing Clicks
        currentPhase = .allowingClicks
        
        // Wait for the allowing duration, but check periodically for interruption
        let startTime = ContinuousClock.now
        let endTime = startTime + allowingDuration
        
        while ContinuousClock.now < endTime && !shouldInterruptCycle && !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        guard !Task.isCancelled else {
            resetState()
            return
        }
        
        // If interrupted by multiple clicks, skip to prohibiting phase immediately
        if !shouldInterruptCycle {
            // Check click count at end of allowing phase (only if not already interrupted)
            validateClicks()
        }
        
        // Phase 2: Prohibiting Clicks
        currentPhase = .prohibitingClicks
        
        do {
            try await Task.sleep(for: prohibitingDuration)
        } catch {
            resetState()
            return
        }
        
        guard !Task.isCancelled else {
            resetState()
            return
        }
        
        // If not auto cycling, return to idle
        if !isAutoCycling {
            resetState()
        }
    }
    
    private func validateClicks() {
        if clickCount == 0 {
            errorMessage = "❌ No click detected during the allowed period"
        } else if clickCount > 1 {
            errorMessage = "❌ Multiple clicks detected (\(clickCount)) - only 1 click allowed"
        } else {
            // Exactly 1 click - success!
            errorMessage = nil
        }
    }
}

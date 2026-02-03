//
//  SettingsView.swift
//  MouseCheck
//
//  Created by vd on 04.02.2026.
//

import SwiftUI

struct SettingsView: View {
    @Binding var allowingDuration: Double
    @Binding var prohibitingDuration: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Label("Auto-saved", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            .padding(.top)
            
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Allowing Clicks Duration")
                                .font(.headline)
                            Spacer()
                            Text("\(String(format: "%.1f", allowingDuration))s")
                                .font(.headline)
                                .foregroundStyle(.green)
                                .monospacedDigit()
                        }
                        
                        Slider(value: $allowingDuration, in: 1...10, step: 0.5) {
                            Text("Allowing Duration")
                        }
                        .tint(.green)
                        
                        Text("Time window for clicking (green phase)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label("Allowing Phase", systemImage: "hand.tap.fill")
                        .foregroundStyle(.green)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Prohibiting Clicks Duration")
                                .font(.headline)
                            Spacer()
                            Text("\(String(format: "%.1f", prohibitingDuration))s")
                                .font(.headline)
                                .foregroundStyle(.red)
                                .monospacedDigit()
                        }
                        
                        Slider(value: $prohibitingDuration, in: 1...10, step: 0.5) {
                            Text("Prohibiting Duration")
                        }
                        .tint(.red)
                        
                        Text("Time when clicks are blocked (red phase)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Label("Prohibiting Phase", systemImage: "hand.raised.fill")
                        .foregroundStyle(.red)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Cycle Time: \(String(format: "%.1f", allowingDuration + prohibitingDuration))s")
                            .font(.subheadline)
                            .bold()
                        
                        HStack(spacing: 4) {
                            Text("•")
                                .foregroundStyle(.green)
                            Text("Allowing: \(String(format: "%.1f", allowingDuration))s")
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .foregroundStyle(.red)
                            Text("Prohibiting: \(String(format: "%.1f", prohibitingDuration))s")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                } header: {
                    Label("Summary", systemImage: "clock.fill")
                }
            }
            .formStyle(.grouped)
            
            Text("Settings are automatically saved and will persist after restarting the app.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 15) {
                Button("Reset to Defaults") {
                    withAnimation {
                        allowingDuration = 3.0
                        prohibitingDuration = 2.0
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 450)
    }
}

#Preview {
    SettingsView(
        allowingDuration: .constant(3.0),
        prohibitingDuration: .constant(2.0)
    )
}

//
//  WallSenseView.swift
//  Pandora - WallSense MicroApp
//
//  Main view for the WallSense (Wall Scanner) MicroApp
//  Single-screen layout — no scrolling required.
//  Displays real-time magnetic field data, per-axis breakdown,
//  directional indicator, signal heatmap, and scan controls.
//

import SwiftUI

// MARK: - WallSense View

struct WallSenseView: View {
    
    // MARK: - Dependencies
    
    @Environment(Router.self) private var router
    @State private var viewModel: WallSenseViewModel
    
    // MARK: - Local State
    
    @State private var showSaveSheet = false
    @State private var scanLocationName = ""
    @State private var showHistory = false
    @State private var pulseOpacity: Double = 0.3
    
    // MARK: - Init
    
    init(viewModel: WallSenseViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    // MARK: - Helpers
    
    private var isScanning: Bool { viewModel.status == .scanning }
    private var isCalibrating: Bool { viewModel.status == .calibrating }
    private var hasCalibrated: Bool { viewModel.baselineMagnitude > 0 }
    
    private var accentColor: Color {
        threatColor(for: viewModel.currentThreatLevel)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            PandoraTheme.Colors.background.ignoresSafeArea()
            
            if isScanning && viewModel.currentThreatLevel != .safe {
                accentColor.opacity(pulseOpacity * 0.15)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseOpacity)
                    .onAppear { pulseOpacity = 0.8 }
            }
            
            // Single-screen layout — no ScrollView
            VStack(spacing: 0) {
                headerBar
                
                Spacer(minLength: 4)
                
                // === Top: Gauge + classification ===
                gaugeSection
                
                Spacer(minLength: 8)
                
                // === Middle: Axis / direction / depth (only while scanning) ===
                if isScanning || viewModel.status == .complete {
                    instrumentPanel
                } else {
                    statusHint
                }
                
                Spacer(minLength: 8)
                
                // === Bottom: Controls ===
                controlBar
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, PandoraTheme.Layout.padding)
        }
        .onDisappear { viewModel.stopScanning() }
        .sheet(isPresented: $showSaveSheet) { saveSheet }
        .sheet(isPresented: $showHistory) { historySheet }
        .hideNavigationBar()
    }
    
    // ──────────────────────────────────────────────
    // MARK: - Header Bar
    // ──────────────────────────────────────────────
    
    private var headerBar: some View {
        HStack {
            Button(action: { router.backToHub() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            
            // Status dot + label
            HStack(spacing: 6) {
                if isScanning || isCalibrating {
                    Circle().fill(accentColor).frame(width: 6, height: 6)
                        .opacity(pulseOpacity)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulseOpacity)
                }
                Text(viewModel.status.message)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(isScanning ? accentColor : PandoraTheme.Colors.gold)
            }
            
            Spacer()
            Button(action: { showHistory = true }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
    }
    
    // ──────────────────────────────────────────────
    // MARK: - Gauge (compact)
    // ──────────────────────────────────────────────
    
    private var gaugeSection: some View {
        VStack(spacing: 6) {
            ZStack {
                // Ring background
                Circle()
                    .stroke(accentColor.opacity(0.15), lineWidth: 6)
                    .frame(width: 140, height: 140)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: min(viewModel.currentDeviation / 100, 1.0))
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.2), value: viewModel.currentDeviation)
                
                // Center reading
                VStack(spacing: 2) {
                    if isCalibrating {
                        Text("\(Int(viewModel.calibrationProgress * 100))%")
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundColor(PandoraTheme.Colors.gold)
                    } else {
                        Text(String(format: "%.1f", viewModel.currentDeviation))
                            .font(.system(size: 34, weight: .black, design: .monospaced))
                            .foregroundColor(accentColor)
                        
                        Text("µT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(accentColor.opacity(0.6))
                    }
                    
                    // Inline classification
                    if isScanning && viewModel.currentClassification != .none {
                        Text(viewModel.currentThreatLevel.emoji + " " + viewModel.currentClassification.rawValue.uppercased())
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(accentColor.opacity(0.8))
                    }
                }
            }
            .goldGlow(intensity: isScanning && viewModel.currentThreatLevel != .safe ? 0.25 : 0)
            
            // Stats row
            if hasCalibrated {
                HStack(spacing: 16) {
                    miniStat("BASE", String(format: "%.0f", viewModel.baselineMagnitude))
                    miniStat("PEAK", String(format: "%.1f", viewModel.peakDeviation))
                    miniStat("NOISE", String(format: "%.1f", viewModel.noiseFloor))
                    if isScanning && viewModel.isOscillating {
                        Text("⚡AC")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
    }
    
    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // ──────────────────────────────────────────────
    // MARK: - Instrument Panel (axis + compass + depth in one row)
    // ──────────────────────────────────────────────
    
    private var instrumentPanel: some View {
        HStack(spacing: 10) {
            // Left: Axis bars (compact)
            axisColumn
            
            Spacer(minLength: 0)
            
            // Center: Directional compass
            compactCompass
            
            Spacer(minLength: 0)
            
            // Right: Z depth gauge
            compactDepthGauge
        }
        .padding(10)
        .background(PandoraTheme.Colors.surface)
        .cornerRadius(12)
    }
    
    // MARK: Axis Column
    
    private var axisColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AXIS")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(PandoraTheme.Colors.gold)
            
            compactAxisBar("X", value: viewModel.currentXDeviation, color: .red)
            compactAxisBar("Y", value: viewModel.currentYDeviation, color: .green)
            compactAxisBar("Z", value: viewModel.currentZDeviation, color: .cyan)
            
            // Dominant hint
            if viewModel.currentDeviation > viewModel.noiseFloor {
                Text(shortDominantHint)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: 110)
    }
    
    private func compactAxisBar(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 12, alignment: .trailing)
            
            GeometryReader { geo in
                let maxUT: Double = 50
                let center = geo.size.width / 2
                let norm = min(max(value / maxUT, -1), 1)
                let barW = abs(norm) * center
                let barX = norm > 0 ? center : center - barW
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.06))
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1)
                        .position(x: center, y: geo.size.height / 2)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.6))
                        .frame(width: barW)
                        .offset(x: barX)
                }
            }
            .frame(height: 10)
            
            Text(String(format: "%+.0f", value))
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(abs(value) > viewModel.noiseFloor ? color : .gray)
                .frame(width: 28, alignment: .trailing)
        }
    }
    
    private var shortDominantHint: String {
        let aX = abs(viewModel.currentXDeviation)
        let aY = abs(viewModel.currentYDeviation)
        let aZ = abs(viewModel.currentZDeviation)
        if aZ >= aX && aZ >= aY { return "▸ Behind phone" }
        if aX >= aY { return viewModel.currentXDeviation > 0 ? "▸ Slide LEFT" : "▸ Slide RIGHT" }
        return viewModel.currentYDeviation > 0 ? "▸ Slide DOWN" : "▸ Slide UP"
    }
    
    // MARK: Compact Compass
    
    private var compactCompass: some View {
        VStack(spacing: 4) {
            Text("DIR")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(PandoraTheme.Colors.gold)
            
            ZStack {
                Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
                    .frame(width: 70, height: 70)
                Circle().stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .frame(width: 40, height: 40)
                
                // Crosshairs
                Rectangle().fill(Color.white.opacity(0.06))
                    .frame(width: 1, height: 70)
                Rectangle().fill(Color.white.opacity(0.06))
                    .frame(width: 70, height: 1)
                
                // Labels
                Text("R").offset(x: 40).font(.system(size: 6, weight: .bold, design: .monospaced))
                Text("L").offset(x: -40).font(.system(size: 6, weight: .bold, design: .monospaced))
                Text("U").offset(y: -40).font(.system(size: 6, weight: .bold, design: .monospaced))
                Text("D").offset(y: 40).font(.system(size: 6, weight: .bold, design: .monospaced))
                
                // Direction dot
                if viewModel.directionalStrength > 0.05 && viewModel.currentDeviation > viewModel.noiseFloor {
                    let len = viewModel.directionalStrength * 28
                    let dx = cos(viewModel.directionalAngle) * len
                    let dy = -sin(viewModel.directionalAngle) * len
                    
                    Path { p in
                        p.move(to: CGPoint(x: 35, y: 35))
                        p.addLine(to: CGPoint(x: 35 + dx, y: 35 + dy))
                    }
                    .stroke(accentColor.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 70, height: 70)
                    
                    Circle().fill(accentColor).frame(width: 7, height: 7)
                        .shadow(color: accentColor.opacity(0.5), radius: 3)
                        .offset(x: dx, y: dy)
                } else {
                    Circle().fill(Color.gray.opacity(0.25)).frame(width: 5, height: 5)
                }
            }
            .foregroundColor(.gray.opacity(0.35))
            .frame(width: 80, height: 80)
            
            Text(viewModel.directionalStrength > 0.05 && viewModel.currentDeviation > viewModel.noiseFloor
                 ? shortDirectionHint : "—")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(accentColor.opacity(0.7))
                .lineLimit(1)
        }
    }
    
    private var shortDirectionHint: String {
        let deg = viewModel.directionalAngle * 180 / .pi
        let n = ((deg.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        switch n {
        case 337.5...360, 0..<22.5:   return "← LEFT"
        case 22.5..<67.5:             return "↙ D-LEFT"
        case 67.5..<112.5:            return "↓ DOWN"
        case 112.5..<157.5:           return "↘ D-RIGHT"
        case 157.5..<202.5:           return "→ RIGHT"
        case 202.5..<247.5:           return "↗ U-RIGHT"
        case 247.5..<292.5:           return "↑ UP"
        case 292.5..<337.5:           return "↖ U-LEFT"
        default:                      return "MOVE"
        }
    }
    
    // MARK: Compact Depth Gauge
    
    private var compactDepthGauge: some View {
        VStack(spacing: 4) {
            Text("DEPTH")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(PandoraTheme.Colors.gold)
            
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 28)
                
                let maxZ: Double = 60
                let normZ = min(abs(viewModel.currentZDeviation) / maxZ, 1.0)
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.green, .yellow, .orange, .red, .purple],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
                    .frame(width: 28, height: max(normZ * 80, 2))
                    .animation(.easeOut(duration: 0.2), value: viewModel.currentZDeviation)
            }
            .frame(width: 28, height: 80)
            
            Text(String(format: "%+.0f", viewModel.currentZDeviation))
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(abs(viewModel.currentZDeviation) > viewModel.noiseFloor ? .cyan : .gray)
            
            Text(abs(viewModel.currentZDeviation) > viewModel.noiseFloor
                 ? (viewModel.currentZDeviation > 0 ? "WALL" : "SURF")
                 : "OK")
                .font(.system(size: 6, weight: .bold, design: .monospaced))
                .foregroundColor(.gray.opacity(0.5))
        }
        .frame(width: 50)
    }
    
    // ──────────────────────────────────────────────
    // MARK: - Status Hint (idle / pre-calibration)
    // ──────────────────────────────────────────────
    
    private var statusHint: some View {
        Group {
            if !hasCalibrated {
                hintRow(icon: "hand.raised", text: "Hold phone in air away from walls, then tap CALIBRATE.")
            } else {
                hintRow(icon: "iphone.and.arrow.forward", text: "Place phone flat against wall. Slide slowly to scan.")
            }
        }
    }
    
    private func hintRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(PandoraTheme.Colors.gold)
            Text(text)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PandoraTheme.Colors.surface)
        .cornerRadius(10)
    }
    
    // ──────────────────────────────────────────────
    // MARK: - Control Bar
    // ──────────────────────────────────────────────
    
    private var controlBar: some View {
        VStack(spacing: 8) {
            switch viewModel.status {
            case .idle:
                if hasCalibrated {
                    actionButton("START SCAN", icon: "sensor.tag.radiowaves.forward", color: .cyan) {
                        viewModel.startScanning()
                    }
                    Button(action: { viewModel.startCalibration() }) {
                        Label("RECALIBRATE", systemImage: "arrow.clockwise")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                } else {
                    actionButton("CALIBRATE", icon: "scope", color: PandoraTheme.Colors.gold) {
                        viewModel.startCalibration()
                    }
                }
                
            case .calibrating:
                ProgressView(value: viewModel.calibrationProgress)
                    .tint(PandoraTheme.Colors.gold)
                actionButton("CANCEL", icon: "stop.fill", color: .red) {
                    viewModel.stopScanning()
                }
                
            case .scanning:
                actionButton("STOP SCAN", icon: "stop.fill", color: .red) {
                    viewModel.stopScanning()
                }
                
            case .complete:
                HStack(spacing: 12) {
                    actionButton("SAVE", icon: "square.and.arrow.down", color: .green) {
                        showSaveSheet = true
                    }
                    actionButton("DISCARD", icon: "trash", color: .gray) {
                        viewModel.resetScan()
                    }
                }
                
            case .paused:
                actionButton("RESUME", icon: "sensor.tag.radiowaves.forward", color: .cyan) {
                    viewModel.startScanning()
                }
            }
        }
    }
    
    private func actionButton(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.12))
                .foregroundColor(color)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    // ──────────────────────────────────────────────
    // MARK: - Save Sheet
    // ──────────────────────────────────────────────
    
    private var saveSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(viewModel.currentThreatLevel.emoji).font(.system(size: 40))
                    Text(viewModel.currentClassification.rawValue.uppercased())
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(accentColor)
                    Text(String(format: "Peak: %.1f µT", viewModel.peakDeviation))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                TextField("Location name (e.g. Kitchen Wall)", text: $scanLocationName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(.horizontal)
                
                Button(action: {
                    viewModel.saveScan(locationName: scanLocationName)
                    scanLocationName = ""
                    showSaveSheet = false
                }) {
                    Text("SAVE")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(PandoraTheme.Colors.gold)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Save Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSaveSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // ──────────────────────────────────────────────
    // MARK: - History Sheet
    // ──────────────────────────────────────────────
    
    private var historySheet: some View {
        NavigationStack {
            Group {
                if viewModel.history.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sensor.tag.radiowaves.forward")
                            .font(.system(size: 40)).foregroundColor(.gray)
                        Text("No scans yet")
                            .font(.system(size: 14, design: .monospaced)).foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.history) { scan in
                            scanRow(scan).listRowBackground(PandoraTheme.Colors.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(PandoraTheme.Colors.background)
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showHistory = false }
                }
                if !viewModel.history.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear All") { viewModel.clearHistory() }.foregroundColor(.red)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func scanRow(_ scan: WallScanModel) -> some View {
        HStack(spacing: 10) {
            Text(scan.threatLevel.emoji).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(scan.locationName)
                    .font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.white)
                Text(scan.summary)
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
                Text(scan.formattedDate)
                    .font(.system(size: 8, design: .monospaced)).foregroundColor(.gray.opacity(0.6))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f µT", scan.peakDeviation))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(threatColor(for: scan.threatLevel))
                Text(scan.primaryClassification.uppercased())
                    .font(.system(size: 7, weight: .bold, design: .monospaced)).foregroundColor(.gray)
            }
        }
        .padding(.vertical, 3)
    }
    
    // ──────────────────────────────────────────────
    // MARK: - Color Helper
    // ──────────────────────────────────────────────
    
    private func threatColor(for level: ThreatLevel) -> Color {
        switch level {
        case .safe:     return .green
        case .low:      return .yellow
        case .moderate: return .orange
        case .high:     return .red
        case .extreme:  return .purple
        }
    }
}

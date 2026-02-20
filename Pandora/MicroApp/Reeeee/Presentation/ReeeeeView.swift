//
//  ReeeeeView.swift
//  Pandora - Reeeee MicroApp
//
//  Created by Immanuel Hardjo on 16/02/26.
//  Enhanced with dependency injection and better structure
//

import SwiftUI

// MARK: - Reeeee View

/// Main view for the Reeeee (Phone Yeet) MicroApp
/// Follows MVVM pattern with proper dependency injection
struct ReeeeeView: View {
    
    // MARK: - Dependencies
    
    @Environment(Router.self) private var router
    @State private var viewModel: ReeeeeViewModel
    
    // MARK: - Local State
    
    @State private var glitchOffset: CGFloat = 0
    @State private var isFlashing = false
    
    // MARK: - Initialization
    
    init(viewModel: ReeeeeViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    // MARK: - Computed Properties
    
    private var isNewRecordLanded: Bool {
        viewModel.status == .landed &&
        viewModel.currentAirtime >= viewModel.highScore &&
        viewModel.highScore > 0
    }
    
    private var recordColor: Color {
        isNewRecordLanded ? .black : .white
    }
    
    private var airtimeColor: Color {
        isNewRecordLanded ? .black : (viewModel.status == .inAir ? .red : .white)
    }
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        ZStack {
            backgroundLayer
            contentLayer
        }
        .onAppear { viewModel.startMonitoring() }
        .onDisappear { viewModel.stopMonitoring() }
        .onChange(of: viewModel.status) { handleStatusChange($0, $1) }
        .hideNavigationBar()
    }
    
    // MARK: - Background Layer
    
    private var backgroundLayer: some View {
        Group {
            if isNewRecordLanded {
                Color.yellow.ignoresSafeArea()
            } else {
                PandoraTheme.Colors.background.ignoresSafeArea()
            }
            
            if viewModel.status == .inAir {
                Color.red.opacity(0.15).ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Content Layer
    private var contentLayer: some View {
        VStack(spacing: 30) {
            headerSection
            Spacer()
            mainDisplaySection
            Spacer()
            dataTerminalSection
        }
        .padding(PandoraTheme.Layout.padding)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button(action: { router.backToHub() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(recordColor)
            }
            Spacer()
            Text("LEGAL DISCLAIMER: DON'T")
                .font(.caption2)
                .foregroundColor(isNewRecordLanded ? .black : .red)
                .monospaced()
        }
    }
    
    // MARK: - Main Display Section
    private var mainDisplaySection: some View {
        VStack(spacing: -10) {
            titleText
            airtimeDisplay
            insultText
        }
    }
    
    private var titleText: some View {
        Group {
            if isNewRecordLanded {
                Text("⚠️ ABSOLUTE UNIT ⚠️")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                    .opacity(isFlashing ? 1 : 0.5)
                    .onAppear { startFlashing() }
            } else {
                Text(statusTitle)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(statusTitleColor)
                    .offset(x: glitchOffset)
            }
        }
    }
    
    private var statusTitle: String {
        "YEET THE PHONE"
    }
    
    private var statusTitleColor: Color {
        viewModel.status == .inAir ? .white : PandoraTheme.Colors.gold
    }
    
    private var airtimeDisplay: some View {
        Text(String(format: "%.2fs", viewModel.currentAirtime))
            .font(.system(size: 100, weight: .black, design: .monospaced))
            .foregroundColor(airtimeColor)
            .shadow(color: viewModel.status == .inAir ? .red : .clear, radius: 20)
            .scaleEffect(viewModel.status == .inAir ? 1.2 : 1.0)
    }
    
    private var insultText: some View {
        Group {
            if !isNewRecordLanded {
                Text(insultMessage)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(isNewRecordLanded ? .black.opacity(0.7) : .gray)
                    .padding(.top, 20)
            }
        }
    }
    
    private var insultMessage: String {
        if viewModel.status == .ready { return "IDLE: DO SOMETHING" }
        if viewModel.status == .inAir { return "REEEEEEEEEEEEEEEEE" }
        
        switch viewModel.currentAirtime {
        case ..<0.4: return "MY GRANDMA TOSSES BETTER"
        case 0.4..<0.8: return "OOH, SCARY. TRY HARDER."
        case 0.8..<1.5: return "OKAY, MR. PHYSICS."
        default: return "IS THE SCREEN BROKEN YET?"
        }
    }
    
    // MARK: - Data Terminal Section
    private var dataTerminalSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            highScoreDisplay
            divider
            historyList
            purgeButton
        }
        .padding()
        .background(isNewRecordLanded ? Color.yellow : Color.black)
        .border(terminalBorderColor, width: 1)
    }
    
    private var terminalBorderColor: Color {
        isNewRecordLanded ? Color.black : Color.red.opacity(0.5)
    }
    
    private var highScoreDisplay: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("HIGHEST REEEEE")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(highScoreLabelColor)
            
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(String(format: "%.2f", viewModel.highScore))
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundColor(recordColor)
                Text("SEC")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(highScoreLabelColor)
            }
        }
    }
    
    private var highScoreLabelColor: Color {
        isNewRecordLanded ? .black : PandoraTheme.Colors.gold
    }
    
    private var divider: some View {
        Divider().background(
            isNewRecordLanded ? Color.black.opacity(0.3) : Color.red.opacity(0.3)
        )
    }
    
    private var historyList: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("PREVIOUS FAILURES")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isNewRecordLanded ? .black : .red)
            
            ForEach(viewModel.history.prefix(3)) { record in
                historyRow(for: record)
            }
        }
    }
    
    private func historyRow(for record: ReeeeeModel) -> some View {
        HStack {
            Text(record.rank)
                .font(.system(size: 12, design: .monospaced))
            Spacer()
            Text(String(format: "%.2fs", record.airtime))
                .bold()
        }
        .padding(8)
        .foregroundColor(recordColor)
        .background(historyRowBackground)
    }
    
    private var historyRowBackground: Color {
        isNewRecordLanded ? Color.black.opacity(0.1) : Color.white.opacity(0.05)
    }
    
    private var purgeButton: some View {
        Button(action: handlePurge) {
            Label("PURGE DATA", systemImage: "trash.fill")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(purgeButtonBackground)
                .border(purgeButtonBorder, width: 1)
                .foregroundColor(isNewRecordLanded ? .black : .red)
        }
    }
    
    private var purgeButtonBackground: Color {
        isNewRecordLanded ? Color.black.opacity(0.1) : Color.red.opacity(0.1)
    }
    
    private var purgeButtonBorder: Color {
        isNewRecordLanded ? Color.black.opacity(0.5) : Color.red.opacity(0.5)
    }
    
    // MARK: - Event Handlers
    private func handleStatusChange(_ oldStatus: YeetStatus, _ newStatus: YeetStatus) {
        if newStatus == .inAir {
            startChaoticJitter()
        } else if newStatus == .ready {
            isFlashing = false
        }
        glitchOffset = 0
    }
    
    private func handlePurge() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        viewModel.clearHistory()
    }
    
    // MARK: - Animation Helpers
    private func startFlashing() {
        withAnimation(.easeInOut(duration: 0.1).repeatForever()) {
            isFlashing = true
        }
    }
    
    private func startChaoticJitter() {
        Task {
            while viewModel.status == .inAir {
                glitchOffset = CGFloat.random(in: -15...15)
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
}

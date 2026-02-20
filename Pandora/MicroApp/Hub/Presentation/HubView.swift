//
//  HubView.swift
//  Pandora - Hub MicroApp
//
//  Created by Immanuel Hardjo on 16/02/26.
//  Enhanced with better view composition and accessibility
//

import SwiftUI

// MARK: - Hub View

/// Main hub view displaying all available MicroApps
/// Follows MVVM pattern with clean view composition
///
/// **Features**:
/// - Adaptive grid layout
/// - Search functionality
/// - Haptic feedback
/// - Accessibility support
struct HubView: View {
    
    // MARK: - Environment
    
    @Environment(Router.self) private var router: Router
    @Environment(HubViewModel.self) private var viewModel: HubViewModel
    
    // MARK: - State
    
    @State private var showSearchBar = false
    @State private var searchText = ""
    
    // MARK: - Initialization
    
    /// Public initializer for SwiftUI view creation
    init() {}
    
    // MARK: - Layout Properties
    
    /// Adaptive grid: switches between 2 or 3 columns based on screen width
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 20)
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            backgroundLayer
            contentLayer
        }
        .hideNavigationBar()
    }
    
    // MARK: - View Layers
    
    private var backgroundLayer: some View {
        PandoraTheme.Colors.background
            .ignoresSafeArea()
    }
    
    private var contentLayer: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                headerSection
                
                if showSearchBar {
                    searchSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                microAppsGrid
            }
            .padding(PandoraTheme.Layout.padding)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("PROJECT")
                    .font(.caption)
                    .tracking(4)
                    .foregroundColor(PandoraTheme.Colors.gold.opacity(0.7))
                    .accessibilityAddTraits(.isHeader)
                
                Text("PANDORA")
                    .font(.system(size: 42, weight: .black, design: .serif))
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)
            }
            
            Spacer()
            
            Button(action: { withAnimation { showSearchBar.toggle() } }) {
                Image(systemName: showSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(PandoraTheme.Colors.gold)
            }
        }
        .padding(.top, 40)
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(PandoraTheme.Colors.gold)
                .font(.system(size: 16))
            
            TextField("Search apps...", text: $searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onChange(of: searchText) { _, newValue in
                    viewModel.searchText = newValue
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation {
                        searchText = ""
                        viewModel.searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(PandoraTheme.Colors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(PandoraTheme.Colors.gold.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - MicroApps Grid
    
    private var microAppsGrid: some View {
        Group {
            if viewModel.filteredApps.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.filteredApps, id: \.id) { app in
                        HubCard(app: app) {
                            handleAppSelection(app)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(PandoraTheme.Colors.gold.opacity(0.5))
            
            Text("No apps found")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Try searching for '\(searchText)'")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                withAnimation {
                    searchText = ""
                    viewModel.searchText = ""
                }
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Clear Search")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(PandoraTheme.Colors.gold)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(PandoraTheme.Colors.gold.opacity(0.1))
                .cornerRadius(20)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
    
    // MARK: - Actions
    
    private func handleAppSelection(_ app: AnyMicroApp) {
        // Clear search when navigating
        withAnimation {
            if !searchText.isEmpty {
                searchText = ""
                viewModel.searchText = ""
            }
            if showSearchBar {
                showSearchBar = false
            }
        }
        
        // Call lifecycle hook
        app.onAppear()
        
        // Navigate to the app
        router.navigateToMicroApp(app.id)
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    let router = Router()
    let viewModel = HubViewModel()
    
    return NavigationStack {
        HubView()
            .environment(router)
            .environment(viewModel)
    }
}

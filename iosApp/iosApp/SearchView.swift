import SwiftUI

// ===============================================================
// MARK: - SEARCH VIEW
// ===============================================================
struct SearchView: View {
    @StateObject private var dashboardViewModel = SearchViewModel()
    @State private var query: String = ""
    @State private var hasSearched: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("LightGreen"), Color("SoftCream")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("DarkGreen").opacity(0.7))

                    TextField("Search plants, care tips, species...", text: $query)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            triggerSearch()
                        }

                    if !query.isEmpty {
                        Button {
                            query = ""
                            dashboardViewModel.results = [] // Clear VM results
                            hasSearched = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: Color("DarkGreen").opacity(0.15), radius: 6, y: 3)
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Content
                if dashboardViewModel.isLoading {
                    Spacer()
                    ProgressView("Searching Database…")
                        .foregroundColor(Color("DarkGreen"))
                    Spacer()
                } else if dashboardViewModel.results.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: hasSearched ? "leaf.circle" : "text.magnifyingglass")
                            .font(.system(size: 40, weight: .regular))
                            .foregroundColor(Color("DarkGreen").opacity(0.8))

                        Text(hasSearched ? "No results found in library." : "Start by typing to search the library.")
                            .font(.subheadline)
                            .foregroundColor(Color("DarkGreen").opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(dashboardViewModel.results) { result in
                                SearchResultCard(result: result)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }

    private func triggerSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        hasSearched = true
        // ✅ Call the ViewModel async method
        Task {
            await dashboardViewModel.performSearch(query: trimmed)
        }
    }
}

// A simple “info flows nicely” card for each search result
private struct SearchResultCard: View {
    let result: SearchResult
    @State private var isExpanded: Bool = false
    @State private var loadedImage: UIImage?
    @State private var isLoadingImage: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - Always visible (tap to expand)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    // Plant image thumbnail (NEW)
                    Group {
                        if let uiImage = loadedImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else if isLoadingImage {
                            ProgressView()
                        } else {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color("DarkGreen").opacity(0.6))
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("LightGreen").opacity(0.3))
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("DarkGreen"))

                        if !result.subtitle.isEmpty {
                            Text(result.subtitle)
                                .font(.footnote)
                                .italic()
                                .foregroundColor(Color("DarkGreen").opacity(0.7))
                        }

                        if !result.detail.isEmpty {
                            Text("Family: \(result.detail)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color("DarkGreen").opacity(0.6))
                }
            }
            .buttonStyle(.plain)
            .padding(14)

            // Expanded Care Info Section (existing code remains the same)
            if isExpanded {
                Divider()
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 12) {
                    CareInfoRow(
                        icon: "drop.fill",
                        iconColor: .blue,
                        label: "Watering",
                        value: result.wateringInfo
                    )

                    CareInfoRow(
                        icon: "sun.max.fill",
                        iconColor: .orange,
                        label: "Sunlight",
                        value: result.sunlightInfo
                    )

                    CareInfoRow(
                        icon: "scissors",
                        iconColor: .green,
                        label: "Trimming",
                        value: result.trimmingInfo
                    )

                    CareInfoRow(
                        icon: "leaf.arrow.circlepath",
                        iconColor: .brown,
                        label: "Fertilizing",
                        value: result.fertilizingInfo
                    )
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color("DarkGreen").opacity(0.16), radius: 8, y: 4)
        )
        .onAppear {
            loadImageIfNeeded()
        }
    }

    private func loadImageIfNeeded() {
        guard !isLoadingImage, loadedImage == nil, let imageUrl = result.imageUrl else { return }
        isLoadingImage = true

        // Load image from URL
        Task {
            if let url = URL(string: imageUrl) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            self.loadedImage = uiImage
                            self.isLoadingImage = false
                        }
                        return
                    }
                } catch {
                    print("Error loading image: \(error)")
                }
            }
            await MainActor.run {
                self.isLoadingImage = false
            }
        }
    }
}

private struct CareInfoRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("DarkGreen").opacity(0.85))
                .frame(width: 65, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


//
//  TodayFactView.swift
//  Texas Daily
//
//
//  Main fact screen + category filter sheet
//
import SwiftUI

// MARK: - TodayFactView

struct TodayFactView: View {
    @EnvironmentObject var viewModel: TexasAppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingFilter = false
    @State private var isButtonPressed = false
    @State private var shareImage: UIImage? = nil
    @State private var shareText: String = ""
    @State private var showingShareSheet = false

    // MARK: - Palette (shared with rest of app)

    /// Overall screen background
    private var backgroundColor: Color {
        if colorScheme == .dark {
            // Deep charcoal
            return Color(red: 0.07, green: 0.08, blue: 0.10)
        } else {
            // Limestone parchment
            return Color(red: 0.97, green: 0.96, blue: 0.90)
        }
    }

    /// Main text color
    private var inkColor: Color {
        if colorScheme == .dark {
            return Color.white
        } else {
            return Color(red: 0.30, green: 0.21, blue: 0.16) // pecan brown
        }
    }

    /// Card background for the body info
    private var bodyCardColor: Color {
        if colorScheme == .dark {
            // Slightly lighter than background
            return Color(red: 0.16, green: 0.18, blue: 0.20)
        } else {
            return Color.white.opacity(0.98)
        }
    }

    /// Global accent (buttons, filter, chips)
    private var accentGreen: Color {
        Color(red: 0.52, green: 0.65, blue: 0.23)
    }

    /// Category chip background
    private var chipBackground: Color {
        if colorScheme == .dark {
            return accentGreen.opacity(0.28)
        } else {
            return Color(red: 0.92, green: 0.95, blue: 0.90)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            PaperBackground()
                .ignoresSafeArea()
                .opacity(colorScheme == .dark ? 0 : 0.35)

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        factTitleBlock
                        bodyCard
                    }
                    .id(viewModel.todayFact?.id)
                    .transition(.opacity)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.todayFact?.id)

                newFactButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }
        }
        .sheet(isPresented: $showingFilter) {
            CategoryFilterSheet()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = shareImage {
                ActivityView(items: [image, shareText])
            }
        }
        .onAppear { renderShareImage() }
        .onChange(of: viewModel.todayFact?.id) { _ in renderShareImage() }
    }

    @MainActor
    private func renderShareImage() {
        guard let fact = viewModel.todayFact else {
            shareImage = nil
            shareText = "Shared from Texas Daily"
            return
        }
        let renderer = ImageRenderer(content: FactShareCard(fact: fact))
        renderer.scale = 3.0
        shareImage = renderer.uiImage
        shareText = makeShareText(from: fact)
    }

    private func makeShareText(from fact: TexasFact) -> String {
        var lines: [String] = [fact.fact]
        if !fact.source.isEmpty {
            lines.append("Source: \(fact.source)")
        }
        lines.append("Shared from Texas Daily")
        return lines.joined(separator: "\n\n")
    }

    // MARK: - Header bar (share + filter on right)
    private var headerBar: some View {
        HStack {
            // left space (settings gear is in RootView)
            Spacer()

            Button {
                Haptics.light()
                showingShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(shareImage != nil ? accentGreen : accentGreen.opacity(0.3))
                    .padding(4)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .disabled(shareImage == nil)
            .accessibilityLabel("Share fact")
            .accessibilityHint(shareImage == nil ? "Available once the fact finishes loading" : "Shares the current Texas fact")

            Button {
                Haptics.light()
                showingFilter = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(accentGreen)
                    .padding(4)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Filter categories")
            .accessibilityHint("Opens the category filter sheet")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - Title block

    private var factTitleBlock: some View {
        Group {
            if let fact = viewModel.todayFact {
                VStack(alignment: .leading, spacing: 16) {

                    // Category chip
                    if !fact.category.isEmpty {
                        Text(fact.category)
                            .font(.system(size: 14, weight: .semibold, design: .default))
                            .foregroundColor(accentGreen)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(chipBackground)
                            )
                    }

                    // Big serif title
                    Text(fact.fact)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(inkColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading a Texas fact…")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Body / background info card

    private var bodyCard: some View {
        Group {
            if let fact = viewModel.todayFact,
               !fact.background.isEmpty {

                VStack(alignment: .leading, spacing: 12) {

                    if let formatted = formattedDate(from: fact.date) {
                        Text(formatted)
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(
                                colorScheme == .dark
                                ? Color.white.opacity(0.7)
                                : .secondary
                            )
                    }

                    Text(fact.background)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(inkColor.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)

                    if !fact.source.isEmpty {
                        Divider()
                            .padding(.vertical, 4)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("Source:")
                                .font(.system(size: 14, weight: .semibold, design: .default))
                                .foregroundColor(inkColor)

                            Text(fact.source)
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.7)
                                    : .secondary
                                )
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(bodyCardColor)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - New fact button

    private var newFactButton: some View {
        Button {
            Haptics.light()
            viewModel.refreshTodayFact()
        } label: {
            Text("New Random Texas Fact")
                .font(.system(size: 17, weight: .semibold, design: .default))
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(accentGreen)
                        .shadow(color: Color.black.opacity(0.18),
                                radius: 14,
                                x: 0,
                                y: 8)
                )
                .scaleEffect(isButtonPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.25,
                                   dampingFraction: 0.7),
                           value: isButtonPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isButtonPressed { isButtonPressed = true }
                }
                .onEnded { _ in
                    isButtonPressed = false
                }
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    private static let isoDateParser: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private static let longDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateStyle = .long
        df.timeStyle = .none
        return df
    }()

    private func formattedDate(from raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        guard let date = Self.isoDateParser.date(from: raw) else { return nil }
        return Self.longDateFormatter.string(from: date)
    }
}

// MARK: - Category Filter Sheet (separate struct, same file)

struct CategoryFilterSheet: View {
    @EnvironmentObject var viewModel: TexasAppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Palette matching TodayFactView
    private var backgroundColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.07, green: 0.08, blue: 0.10)
        } else {
            return Color(red: 0.97, green: 0.96, blue: 0.90)
        }
    }

    private var inkColor: Color {
        if colorScheme == .dark {
            return Color.white
        } else {
            return Color(red: 0.30, green: 0.21, blue: 0.16)
        }
    }

    private var cardColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.16, green: 0.18, blue: 0.20)
        } else {
            return Color.white.opacity(0.98)
        }
    }

    private var accentGreen: Color {
        Color(red: 0.52, green: 0.65, blue: 0.23)
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            PaperBackground()
                .ignoresSafeArea()
                .opacity(colorScheme == .dark ? 0 : 0.30)

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        categoryCard

                        if !viewModel.selectedCategories.isEmpty {
                            clearFiltersButton
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                Haptics.light()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(inkColor)
                    .padding(8)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        Circle()
                            .fill(
                                colorScheme == .dark
                                ? backgroundColor
                                : Color.white.opacity(0.90)
                            )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()

            Text("Filter Categories")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(inkColor)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - Category Card

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.availableCategories.isEmpty {
                Text("No categories available.")
                    .font(.system(size: 15))
                    .foregroundColor(inkColor.opacity(0.7))
                    .padding(16)
            } else {
                let categories = viewModel.availableCategories
                ForEach(categories, id: \.self) { category in
                    let isSelected = viewModel.selectedCategories.contains(category)
                    Button {
                        Haptics.light()
                        toggle(category)
                    } label: {
                        HStack {
                            Text(category)
                                .font(.system(size: 16))
                                .foregroundColor(inkColor)

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(accentGreen)
                                    .font(.system(size: 20, weight: .semibold))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(
                                        colorScheme == .dark
                                        ? Color.white.opacity(0.25)
                                        : Color.secondary.opacity(0.4)
                                    )
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(category), \(isSelected ? "selected" : "not selected")")
                    .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")

                    if category != categories.last {
                        Divider()
                            .padding(.leading, 16)
                            .opacity(0.2)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardColor)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    // MARK: - Clear Filters Button

    private var clearFiltersButton: some View {
        Button(role: .destructive) {
            Haptics.light()
            viewModel.clearCategories()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "line.horizontal.3.decrease.circle")
                Text("Clear Filters")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(colorScheme == .dark ? .red.opacity(0.9) : .red)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardColor)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func toggle(_ category: String) {
        viewModel.toggleCategory(category)
    }
}

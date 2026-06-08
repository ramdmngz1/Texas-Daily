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
    @State private var shareImage: UIImage? = nil
    @State private var shareText: String = ""
    @State private var showingShareSheet = false
    @State private var isPreparingShare = false
    @State private var shareFactID: Int? = nil

    @ScaledMetric(relativeTo: .title) private var factFontSize: CGFloat = 28

    // MARK: - Palette

    private var inkColor: Color { AppColors.ink(for: colorScheme) }
    private var bodyCardColor: Color { AppColors.card(for: colorScheme) }
    private var accentGreen: Color { AppColors.accent }
    private var chipBackground: Color { AppColors.chip(for: colorScheme) }

    // MARK: - Body

    var body: some View {
        ZStack {
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
        .sheet(isPresented: $showingShareSheet, onDismiss: {
            shareImage = nil
        }) {
            if let image = shareImage {
                ActivityView(items: [image, shareText])
            } else {
                Color.clear
                    .onAppear { showingShareSheet = false }
            }
        }
        .onAppear { resetSharePayload(for: viewModel.todayFact) }
        .onChange(of: viewModel.todayFact?.id) { _ in
            resetSharePayload(for: viewModel.todayFact)
        }
    }

    @MainActor
    private func prepareShareSheet() async {
        guard let fact = viewModel.todayFact else {
            showingShareSheet = false
            shareFactID = nil
            shareImage = nil
            shareText = "Shared from Texas Daily"
            return
        }

        shareText = makeShareText(from: fact)

        if shareFactID != fact.id || shareImage == nil {
            isPreparingShare = true
            defer { isPreparingShare = false }

            let renderer = ImageRenderer(content: FactShareCard(fact: fact))
            renderer.scale = 3.0
            shareImage = renderer.uiImage
            shareFactID = fact.id
        }

        if shareImage != nil {
            showingShareSheet = true
        }
    }

    private func resetSharePayload(for fact: TexasFact?) {
        shareFactID = nil
        shareImage = nil

        guard let fact else {
            shareText = "Shared from Texas Daily"
            return
        }

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

    // MARK: - Header bar

    private var headerBar: some View {
        HStack {
            Spacer()

            Button {
                Haptics.light()
                Task { await prepareShareSheet() }
            } label: {
                Group {
                    if isPreparingShare {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(accentGreen)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(viewModel.todayFact != nil ? accentGreen : accentGreen.opacity(0.3))
                    }
                }
                .padding(4)
                .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.todayFact == nil || isPreparingShare)
            .accessibilityLabel("Share fact")
            .accessibilityHint(
                isPreparingShare
                ? "Preparing share image"
                : (viewModel.todayFact == nil
                   ? "Available once the fact finishes loading"
                   : "Shares the current Texas fact")
            )

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

                    Text(fact.fact)
                        .font(.system(size: factFontSize, weight: .bold, design: .serif))
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
                .appCard(fill: bodyCardColor, cornerRadius: 26, shadowRadius: 18, shadowY: 10)
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
        }
        .buttonStyle(AccentButtonStyle(color: accentGreen))
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

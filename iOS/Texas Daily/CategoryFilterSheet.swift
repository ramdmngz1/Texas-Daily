import SwiftUI

struct CategoryFilterSheet: View {
    @EnvironmentObject var viewModel: TexasAppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color { AppColors.background(for: colorScheme) }
    private var inkColor: Color { AppColors.ink(for: colorScheme) }
    private var cardColor: Color { AppColors.card(for: colorScheme) }
    private var accentGreen: Color { AppColors.accent }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

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
        .appCard(fill: cardColor)
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

    private func toggle(_ category: String) {
        viewModel.toggleCategory(category)
    }
}

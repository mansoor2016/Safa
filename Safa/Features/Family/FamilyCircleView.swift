// MARK: - FamilyCircleView.swift
// PURPOSE: Family circle management and activity feed
// DEPENDENCIES: SwiftUI

import SwiftUI

struct FamilyCircleView: View {
    @Environment(Dependencies.self) private var dependencies
    @State private var viewModel: FamilyViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                FamilyContentView(viewModel: viewModel)
            } else {
                LoadingView(message: "Loading family...")
            }
        }
        .task {
            if viewModel == nil {
                viewModel = FamilyViewModel(
                    familyRepository: dependencies.familyRepository
                )
            }
        }
    }
}

// MARK: - Family Content View

private struct FamilyContentView: View {
    @Bindable var viewModel: FamilyViewModel
    @State private var showInviteSheet = false
    @State private var showCreateSheet = false
    @State private var showInviteFriendsSheet = false

    var body: some View {
        Group {
            if let circle = viewModel.familyCircle {
                familyCircleContent(circle)
            } else {
                noFamilyContent
            }
        }
        .navigationTitle("Family Circle")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if viewModel.familyCircle != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showInviteSheet = true
                        } label: {
                            Label("Invite Member", systemImage: "person.badge.plus")
                        }

                        Button {
                            showInviteFriendsSheet = true
                        } label: {
                            Label("Invite Friends to Safa", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button {
                            // Settings
                        } label: {
                            Label("Circle Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteMemberSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCircleSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showInviteFriendsSheet) {
            InviteFriendsView()
        }
        .task {
            await viewModel.loadFamilyCircle()
        }
    }

    // MARK: - No Family Content

    private var noFamilyContent: some View {
        VStack(spacing: SafaSpacing.xl) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor.opacity(0.5))

            VStack(spacing: SafaSpacing.sm) {
                Text("No Family Circle")
                    .font(SafaTypography.headlineMedium)

                Text("Create or join a family circle to share your spiritual journey with loved ones.")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: SafaSpacing.sm) {
                PrimaryButton(title: "Create Family Circle") {
                    showCreateSheet = true
                }

                SecondaryButton(title: "Join with Code") {
                    // Show join sheet
                }
            }
            .padding(.top)

            // Invite Friends section
            Divider()
                .padding(.vertical)

            VStack(spacing: SafaSpacing.sm) {
                Text("Know someone who'd love Safa?")
                    .font(SafaTypography.bodySmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                Button {
                    showInviteFriendsSheet = true
                } label: {
                    Label("Invite Friends to Download", systemImage: "square.and.arrow.up")
                        .font(SafaTypography.bodyMedium)
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Family Circle Content

    private func familyCircleContent(_ circle: FamilyCircle) -> some View {
        ScrollView {
            VStack(spacing: SafaSpacing.lg) {
                // Circle header
                circleHeader(circle)

                // Members section
                membersSection(circle)

                // Activity feed
                activityFeedSection

                // Leaderboard
                leaderboardSection
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadFamilyCircle()
            await viewModel.loadActivityFeed()
        }
    }

    // MARK: - Circle Header

    private func circleHeader(_ circle: FamilyCircle) -> some View {
        ContentCard {
            VStack(spacing: SafaSpacing.md) {
                // Circle icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Text(circle.name.prefix(2).uppercased())
                        .font(SafaTypography.headlineMedium)
                        .foregroundColor(.accentColor)
                }

                Text(circle.name)
                    .font(SafaTypography.titleLarge)

                HStack(spacing: SafaSpacing.lg) {
                    VStack {
                        Text("\(viewModel.members.count)")
                            .font(SafaTypography.titleMedium)
                            .foregroundColor(.accentColor)
                        Text("Members")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }

                    Divider()
                        .frame(height: 30)

                    VStack {
                        Text("\(viewModel.totalCircleHasanat)")
                            .font(SafaTypography.titleMedium)
                            .foregroundColor(.green)
                        Text("Total Hasanat")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }
            }
        }
    }

    // MARK: - Members Section

    private func membersSection(_ circle: FamilyCircle) -> some View {
        TitledCard(title: "Members", subtitle: "\(viewModel.members.count) people") {
            VStack(spacing: SafaSpacing.sm) {
                ForEach(viewModel.members) { member in
                    MemberRow(member: member, isCurrentUser: member.id.uuidString == viewModel.currentUserId)

                    if member.id != viewModel.members.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Activity Feed Section

    private var activityFeedSection: some View {
        TitledCard(title: "Recent Activity", subtitle: "What's happening") {
            if viewModel.activities.isEmpty {
                Text("No recent activity")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: SafaSpacing.sm) {
                    ForEach(viewModel.activities.prefix(5)) { activity in
                        ActivityRow(activity: activity)

                        if activity.id != viewModel.activities.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Leaderboard Section

    private var leaderboardSection: some View {
        TitledCard(title: "Weekly Leaderboard", subtitle: "Top performers") {
            VStack(spacing: SafaSpacing.sm) {
                ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, member in
                    LeaderboardRow(
                        rank: index + 1,
                        member: member,
                        isCurrentUser: member.id.uuidString == viewModel.currentUserId
                    )

                    if index < viewModel.leaderboard.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Family View Model

@Observable
final class FamilyViewModel {
    var familyCircle: FamilyCircle?
    var members: [FamilyMember] = []
    var activities: [FamilyActivity] = []
    var leaderboard: [FamilyMember] = []
    var isLoading = false
    var error: Error?

    let currentUserId = UUID().uuidString // Would come from auth

    private let familyRepository: FamilyRepositoryProtocol

    var totalCircleHasanat: Int {
        members.reduce(0) { $0 + $1.totalHasanat }
    }

    init(familyRepository: FamilyRepositoryProtocol) {
        self.familyRepository = familyRepository
    }

    func loadFamilyCircle() async {
        isLoading = true
        do {
            familyCircle = try await familyRepository.getFamilyCircle()
            if familyCircle != nil {
                await loadMembers()
                await loadActivityFeed()
                await loadLeaderboard()
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func loadMembers() async {
        do {
            members = try await familyRepository.getFamilyMembers()
        } catch {
            self.error = error
        }
    }

    func loadActivityFeed() async {
        do {
            activities = try await familyRepository.getActivityFeed(limit: 20)
        } catch {
            self.error = error
        }
    }

    func loadLeaderboard() async {
        leaderboard = members.sorted { $0.weeklyHasanat > $1.weeklyHasanat }
    }

    func createCircle(name: String) async {
        do {
            familyCircle = try await familyRepository.createFamilyCircle(name: name)
            await loadMembers()
        } catch {
            self.error = error
        }
    }

    func inviteMember(email: String) async -> String? {
        do {
            return try await familyRepository.getInviteCode()
        } catch {
            self.error = error
            return nil
        }
    }

    func joinCircle(code: String) async {
        do {
            try await familyRepository.joinFamilyCircle(inviteCode: code)
            await loadFamilyCircle()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Member Row

private struct MemberRow: View {
    let member: FamilyMember
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: SafaSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Text(member.name.prefix(1).uppercased())
                    .font(SafaTypography.titleMedium)
                    .foregroundColor(.accentColor)
            }

            // Info
            VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                HStack {
                    Text(member.name)
                        .font(SafaTypography.bodyLarge)
                        .foregroundColor(SafaColors.Fallback.text)

                    if isCurrentUser {
                        Text("(You)")
                            .font(SafaTypography.labelSmall)
                            .foregroundColor(SafaColors.Fallback.secondaryText)
                    }
                }

                HStack(spacing: SafaSpacing.sm) {
                    Label("Lv.\(member.level)", systemImage: "star.fill")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(.orange)

                    Text("•")
                        .foregroundColor(SafaColors.Fallback.tertiaryText)

                    Text("\(member.currentStreak) day streak")
                        .font(SafaTypography.labelSmall)
                        .foregroundColor(SafaColors.Fallback.secondaryText)
                }
            }

            Spacer()

            // Hasanat
            VStack(alignment: .trailing) {
                Text("\(member.totalHasanat)")
                    .font(SafaTypography.titleSmall)
                    .foregroundColor(.accentColor)

                Text("Hasanat")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }
        }
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let activity: FamilyActivity

    var body: some View {
        HStack(spacing: SafaSpacing.md) {
            // Activity icon
            Image(systemName: activity.type.iconName)
                .font(.title3)
                .foregroundColor(activity.type.color)
                .frame(width: 32, height: 32)

            // Description
            VStack(alignment: .leading, spacing: SafaSpacing.xxs) {
                Text(activity.description)
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.text)

                Text(activity.timestamp, style: .relative)
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.tertiaryText)
            }

            Spacer()

            // Points
            if activity.hasanatEarned > 0 {
                Text("+\(activity.hasanatEarned)")
                    .font(SafaTypography.labelMedium)
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Leaderboard Row

private struct LeaderboardRow: View {
    let rank: Int
    let member: FamilyMember
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: SafaSpacing.md) {
            // Rank
            Text("\(rank)")
                .font(SafaTypography.titleMedium)
                .foregroundColor(rankColor)
                .frame(width: 30)

            // Medal for top 3
            if rank <= 3 {
                Image(systemName: "medal.fill")
                    .foregroundColor(rankColor)
            }

            // Name
            Text(member.name)
                .font(SafaTypography.bodyLarge)
                .foregroundColor(isCurrentUser ? .accentColor : SafaColors.Fallback.text)

            if isCurrentUser {
                Text("(You)")
                    .font(SafaTypography.labelSmall)
                    .foregroundColor(SafaColors.Fallback.secondaryText)
            }

            Spacer()

            // Weekly hasanat
            Text("\(member.weeklyHasanat)")
                .font(SafaTypography.titleSmall)
                .foregroundColor(.accentColor)
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return SafaColors.Fallback.secondaryText
        }
    }
}

// MARK: - Invite Member Sheet

private struct InviteMemberSheet: View {
    @Bindable var viewModel: FamilyViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var inviteCode: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: SafaSpacing.xl) {
                if let code = inviteCode {
                    // Show invite code
                    VStack(spacing: SafaSpacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Invite Sent!")
                            .font(SafaTypography.headlineMedium)

                        Text("Share this code:")
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(SafaColors.Fallback.secondaryText)

                        Text(code)
                            .font(.system(.title, design: .monospaced))
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: SafaSpacing.CornerRadius.md))

                        Button {
                            UIPasteboard.general.string = code
                        } label: {
                            Label("Copy Code", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    // Email input
                    VStack(spacing: SafaSpacing.md) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        Text("Invite Family Member")
                            .font(SafaTypography.headlineMedium)

                        Text("Enter their email to send an invite")
                            .font(SafaTypography.bodyMedium)
                            .foregroundColor(SafaColors.Fallback.secondaryText)

                        TextField("Email address", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        PrimaryButton(title: isLoading ? "Sending..." : "Send Invite") {
                            Task {
                                isLoading = true
                                inviteCode = await viewModel.inviteMember(email: email)
                                isLoading = false
                            }
                        }
                        .disabled(email.isEmpty || isLoading)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Create Circle Sheet

private struct CreateCircleSheet: View {
    @Bindable var viewModel: FamilyViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var circleName = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: SafaSpacing.xl) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)

                Text("Create Family Circle")
                    .font(SafaTypography.headlineMedium)

                Text("Give your family circle a name")
                    .font(SafaTypography.bodyMedium)
                    .foregroundColor(SafaColors.Fallback.secondaryText)

                TextField("Circle name", text: $circleName)
                    .textFieldStyle(.roundedBorder)

                PrimaryButton(title: isLoading ? "Creating..." : "Create Circle") {
                    Task {
                        isLoading = true
                        await viewModel.createCircle(name: circleName)
                        isLoading = false
                        dismiss()
                    }
                }
                .disabled(circleName.isEmpty || isLoading)

                Spacer()
            }
            .padding()
            .navigationTitle("New Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FamilyCircleView()
            .environment(Dependencies())
    }
}

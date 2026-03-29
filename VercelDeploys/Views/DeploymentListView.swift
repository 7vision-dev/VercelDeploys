import SwiftUI

struct DeploymentListView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.deployments.isEmpty {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                Spacer()
            } else if viewModel.groupedDeployments.isEmpty {
                Spacer()
                Text("No deployments found")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.groupedDeployments) { group in
                            NavigationLink(value: group.commitSha) {
                                DeploymentGroupRow(group: group)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .background(.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Grouped Row

struct DeploymentGroupRow: View {
    let group: DeploymentGroup

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Overall status dot
            Circle()
                .fill(statusColor(for: group.overallState))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.commitMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Project status pills
                HStack(spacing: 4) {
                    ForEach(group.deployments.prefix(5), id: \.uid) { deploy in
                        ProjectPill(deployment: deploy)
                    }
                    if group.deployments.count > 5 {
                        Text("+\(group.deployments.count - 5)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 3) {
                    if group.overallState == .building {
                        ProgressView()
                            .controlSize(.mini)
                    }
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(group.branch)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(group.relativeTime)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

struct ProjectPill: View {
    let deployment: Deployment

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(statusColor(for: deployment.state))
                .frame(width: 5, height: 5)
            Text(shortName(deployment.projectName))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.white.opacity(0.05))
        .clipShape(Capsule())
    }

    private func shortName(_ name: String) -> String {
        name.replacingOccurrences(of: "lumos-", with: "")
    }
}

// MARK: - Shared helpers

func statusColor(for state: DeploymentState?) -> Color {
    guard let state else { return .gray }
    switch state {
    case .ready: return .green
    case .building: return .orange
    case .error: return .red
    case .queued, .initializing: return .gray
    case .canceled: return .secondary
    }
}

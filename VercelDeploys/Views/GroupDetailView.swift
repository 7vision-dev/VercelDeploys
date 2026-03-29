import SwiftUI

struct GroupDetailView: View {
    let group: DeploymentGroup
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Back button header
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(.white.opacity(0.1))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Commit info
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor(for: group.overallState))
                            .frame(width: 10, height: 10)
                        Text(group.overallState.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(label: "Commit", value: group.commitMessage)
                        DetailRow(label: "Branch", value: group.branch)
                        if let sha = group.deployments.first?.commitSha {
                            DetailRow(label: "SHA", value: String(sha.prefix(7)))
                        }
                        DetailRow(label: "Created", value: group.relativeTime)
                        if let creator = group.creator {
                            DetailRow(label: "Creator", value: creator)
                        }
                    }

                    Divider().background(.white.opacity(0.1))

                    // Per-project deploys
                    Text("Projects")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ForEach(group.deployments, id: \.uid) { deploy in
                        ProjectDeployRow(deployment: deploy)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("")
        .toolbar(.hidden)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(.white)
        }
    }
}

struct ProjectDeployRow: View {
    let deployment: Deployment

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Circle()
                    .fill(statusColor(for: deployment.state))
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(deployment.projectName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                    Text(deployment.state?.displayName ?? "Unknown")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    if let url = deployment.deploymentURL, let linkURL = URL(string: url) {
                        Link(destination: linkURL) {
                            Image(systemName: "safari")
                                .font(.system(size: 12))
                                .foregroundStyle(.blue)
                        }
                        .help("Open preview")
                    }

                    if let inspectorUrl = deployment.inspectorUrl, let url = URL(string: inspectorUrl) {
                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 12))
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("Inspect on Vercel")
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

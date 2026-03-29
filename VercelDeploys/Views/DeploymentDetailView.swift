import SwiftUI

struct DeploymentDetailView: View {
    let deployment: Deployment
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
                // Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(deployment.state?.displayName ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)

                Divider().background(.white.opacity(0.1))

                // Detail fields
                DetailField(label: "Name", value: deployment.projectName)

                if let url = deployment.deploymentURL {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preview URL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Link(destination: URL(string: url)!) {
                                HStack(spacing: 4) {
                                    Text(deployment.url ?? "—")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.blue)
                                        .lineLimit(1)
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                DetailField(label: "Git Branch", value: deployment.branch)
                DetailField(label: "Commit Message", value: deployment.commitMessage)

                if let sha = deployment.commitSha {
                    DetailField(label: "Commit SHA", value: String(sha.prefix(7)))
                }

                DetailField(label: "Created", value: deployment.relativeTime)
                DetailField(label: "Creator", value: deployment.creator?.username ?? "—")

                Divider().background(.white.opacity(0.1))

                // Inspect button
                if let inspectorUrl = deployment.inspectorUrl,
                   let url = URL(string: inspectorUrl) {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Inspect on Vercel")
                                .fontWeight(.medium)
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)
                }
            }
            .padding(16)
        }
        }
        .navigationTitle("")
        .toolbar(.hidden)
    }

    private var statusColor: Color {
        guard let state = deployment.state else { return .gray }
        switch state {
        case .ready: return .green
        case .building: return .orange
        case .error: return .red
        case .queued, .initializing: return .gray
        case .canceled: return .secondary
        }
    }
}

struct DetailField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(.white)
        }
    }
}

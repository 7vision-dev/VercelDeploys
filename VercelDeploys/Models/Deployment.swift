import Foundation

enum DeploymentState: String, Codable, CaseIterable {
    case ready = "READY"
    case building = "BUILDING"
    case error = "ERROR"
    case queued = "QUEUED"
    case canceled = "CANCELED"
    case initializing = "INITIALIZING"

    var displayName: String {
        switch self {
        case .ready: return "Ready"
        case .building: return "Building"
        case .error: return "Error"
        case .queued: return "Queued"
        case .canceled: return "Canceled"
        case .initializing: return "Initializing"
        }
    }

    var colorName: String {
        switch self {
        case .ready: return "green"
        case .building: return "orange"
        case .error: return "red"
        case .queued: return "gray"
        case .canceled: return "secondary"
        case .initializing: return "gray"
        }
    }
}

struct DeploymentCreator: Codable {
    let uid: String?
    let username: String?
}

struct DeploymentMeta: Codable {
    let githubCommitMessage: String?
    let githubCommitRef: String?
    let githubCommitSha: String?
    let githubOrg: String?
    let githubRepo: String?
}

struct Deployment: Codable, Identifiable {
    let uid: String
    let name: String
    let url: String?
    let state: DeploymentState?
    let created: Int // timestamp in ms
    let target: String?
    let inspectorUrl: String?
    let creator: DeploymentCreator?
    let meta: DeploymentMeta?

    var id: String { uid }

    var commitMessage: String {
        meta?.githubCommitMessage ?? name
    }

    var branch: String {
        meta?.githubCommitRef ?? target ?? "—"
    }

    var commitSha: String? {
        meta?.githubCommitSha
    }

    var projectName: String {
        name
    }

    var createdDate: Date {
        Date(timeIntervalSince1970: Double(created) / 1000.0)
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdDate, relativeTo: Date())
    }

    var deploymentURL: String? {
        guard let url else { return nil }
        if url.hasPrefix("http") { return url }
        return "https://\(url)"
    }
}

struct DeploymentsResponse: Codable {
    let deployments: [Deployment]
}

// MARK: - Grouped by commit

struct DeploymentGroup: Identifiable {
    let commitSha: String
    let commitMessage: String
    let branch: String
    let created: Date
    let creator: String?
    let deployments: [Deployment]

    var id: String { commitSha }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: created, relativeTo: Date())
    }

    /// Overall status: error > building > queued > ready > canceled
    var overallState: DeploymentState {
        let states = deployments.compactMap(\.state)
        if states.contains(.error) { return .error }
        if states.contains(.building) { return .building }
        if states.contains(.initializing) { return .initializing }
        if states.contains(.queued) { return .queued }
        if states.contains(.ready) { return .ready }
        return .canceled
    }

    /// Unique project names in this group
    var projectNames: [String] {
        let names = deployments.map(\.projectName)
        return Array(Set(names)).sorted()
    }

    static func group(from deployments: [Deployment]) -> [DeploymentGroup] {
        // Group by commit SHA, fall back to uid for deploys without a SHA
        var groups: [String: [Deployment]] = [:]
        var order: [String] = []

        for deployment in deployments {
            let key = deployment.commitSha ?? deployment.uid
            if groups[key] == nil {
                order.append(key)
            }
            groups[key, default: []].append(deployment)
        }

        return order.compactMap { key in
            guard let deploys = groups[key], let first = deploys.first else { return nil }
            return DeploymentGroup(
                commitSha: key,
                commitMessage: first.commitMessage,
                branch: first.branch,
                created: first.createdDate,
                creator: first.creator?.username,
                deployments: deploys
            )
        }
    }
}

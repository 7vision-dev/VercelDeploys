import Foundation
import SwiftUI
import UserNotifications

@MainActor
@Observable
final class AppViewModel {
    static let shared = AppViewModel()

    var isAuthenticated = false
    var deployments: [Deployment] = []
    var isLoading = false
    var errorMessage: String?
    var token: String = ""

    // Project filter
    var selectedProject: String? = nil // nil = all projects

    var availableProjects: [String] {
        Array(Set(deployments.map(\.projectName))).sorted()
    }

    var filteredDeployments: [Deployment] {
        guard let project = selectedProject else { return deployments }
        return deployments.filter { $0.projectName == project }
    }

    var groupedDeployments: [DeploymentGroup] {
        DeploymentGroup.group(from: filteredDeployments)
    }

    private let apiClient = VercelAPIClient()
    private var backgroundTimer: Timer?
    private var previousStates: [String: DeploymentState] = [:]

    var latestDeploymentState: DeploymentState? {
        deployments.first(where: { $0.state != .canceled })?.state
    }

    init() {
        requestNotificationPermission()
        if let savedToken = KeychainHelper.read() {
            token = savedToken
            isAuthenticated = true
            Task { await fetchDeployments() }
        }
    }

    func login(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let valid = try await apiClient.validateToken(token)
            if valid {
                let saved = KeychainHelper.save(token: token)
                if saved {
                    self.token = token
                    self.isAuthenticated = true
                    await fetchDeployments()
                    startBackgroundRefresh()
                } else {
                    errorMessage = "Failed to save token to Keychain"
                }
            } else {
                errorMessage = "Invalid access token"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        KeychainHelper.delete()
        token = ""
        isAuthenticated = false
        deployments = []
        selectedProject = nil
        previousStates = [:]
        stopBackgroundRefresh()
    }

    func fetchDeployments() async {
        guard !token.isEmpty else { return }
        isLoading = deployments.isEmpty

        do {
            let result = try await apiClient.fetchDeployments(token: token)
            checkForNotifications(old: deployments, new: result)
            self.deployments = result
            self.errorMessage = nil
        } catch let error as APIError {
            if case .invalidToken = error {
                logout()
            }
            self.errorMessage = error.localizedDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Background refresh (always runs)

    func startBackgroundRefresh() {
        stopBackgroundRefresh()
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchDeployments()
            }
        }
    }

    func stopBackgroundRefresh() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func checkForNotifications(old: [Deployment], new: [Deployment]) {
        // Build lookup of previous states
        let oldStates = Dictionary(uniqueKeysWithValues: old.map { ($0.uid, $0.state) })

        for deployment in new {
            guard let newState = deployment.state else { continue }
            let oldState = oldStates[deployment.uid]

            // Only notify on state transitions (not on first load)
            guard !old.isEmpty else { continue }

            // Notify when a deploy finishes (ready or error), but not for canceled
            if oldState != newState {
                switch newState {
                case .ready where oldState == .building || oldState == .initializing || oldState == .queued:
                    sendNotification(
                        title: "\(deployment.projectName) deployed",
                        body: "\(deployment.commitMessage)\n\(deployment.branch)",
                        isError: false
                    )
                case .error:
                    sendNotification(
                        title: "\(deployment.projectName) failed",
                        body: "\(deployment.commitMessage)\n\(deployment.branch)",
                        isError: true
                    )
                default:
                    break
                }
            }
        }
    }

    private func sendNotification(title: String, body: String, isError: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = isError ? .defaultCritical : .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

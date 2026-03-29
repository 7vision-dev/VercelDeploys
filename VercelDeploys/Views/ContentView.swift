import SwiftUI

struct ContentView: View {
    @State var viewModel = AppViewModel.shared

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            TopBar(viewModel: viewModel)

            Divider()
                .background(.white.opacity(0.1))

            // Main content
            if viewModel.isAuthenticated {
                NavigationStack {
                    DeploymentListView(viewModel: viewModel)
                        .navigationDestination(for: String.self) { commitSha in
                            if let group = viewModel.groupedDeployments.first(where: { $0.commitSha == commitSha }) {
                                GroupDetailView(group: group)
                            }
                        }
                }
            } else {
                LoginView(viewModel: viewModel)
            }
        }
        .frame(width: 340, height: 480)
        .background(Color(nsColor: .init(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)))
        .preferredColorScheme(.dark)
    }
}

struct TopBar: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        HStack {
            // Project filter dropdown (left)
            if viewModel.isAuthenticated {
                Menu {
                    Button("All Projects") {
                        viewModel.selectedProject = nil
                    }
                    Divider()
                    ForEach(viewModel.availableProjects, id: \.self) { project in
                        Button(project) {
                            viewModel.selectedProject = project
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedProject ?? "All Projects")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            } else {
                Text("Vercel")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Menu (right)
            Menu {
                if viewModel.isAuthenticated {
                    Button("Refresh") {
                        Task { await viewModel.fetchDeployments() }
                    }
                    Divider()
                    Button("Log out", role: .destructive) {
                        viewModel.logout()
                    }
                }
                Divider()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

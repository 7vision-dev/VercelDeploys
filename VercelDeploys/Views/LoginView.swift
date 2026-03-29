import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AppViewModel
    @State private var tokenInput = ""

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Vercel logo triangle
            Image(systemName: "triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(0))

            Text("Log in to Vercel")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            // Account selector (static for v1)
            HStack {
                Image(systemName: "person.circle")
                    .foregroundStyle(.secondary)
                Text("Personal Account")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Access Token")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link("How can I create it?", destination: URL(string: "https://vercel.com/account/tokens")!)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                SecureField("Enter your access token...", text: $tokenInput)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    .onSubmit {
                        login()
                    }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button(action: login) {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Log in")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.black)
            .disabled(tokenInput.isEmpty || viewModel.isLoading)

            Spacer()
        }
        .padding(24)
    }

    private func login() {
        guard !tokenInput.isEmpty else { return }
        Task { await viewModel.login(token: tokenInput) }
    }
}

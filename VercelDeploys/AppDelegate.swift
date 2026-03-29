import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var observation: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            updateIcon(state: nil)
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 480)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: ContentView())

        // Start background refresh (always, not just when popover is open)
        if AppViewModel.shared.isAuthenticated {
            AppViewModel.shared.startBackgroundRefresh()
        }

        // Observe deployment state changes to update icon
        observation = withObservationTracking {
            _ = AppViewModel.shared.latestDeploymentState
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.startObserving()
            }
        }
        startObserving()
    }

    private func startObserving() {
        let state = AppViewModel.shared.latestDeploymentState
        updateIcon(state: state)

        observation = withObservationTracking {
            _ = AppViewModel.shared.latestDeploymentState
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.startObserving()
            }
        }
    }

    private func updateIcon(state: DeploymentState?) {
        guard let button = statusItem.button else { return }

        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size, flipped: false) { rect in
            // Draw the triangle icon
            if let symbolImage = NSImage(systemSymbolName: "triangle.fill", accessibilityDescription: "Vercel Deploys") {
                let symbolConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                let configured = symbolImage.withSymbolConfiguration(symbolConfig) ?? symbolImage
                let symbolSize = NSSize(width: 16, height: 16)
                let symbolOrigin = NSPoint(
                    x: (size.width - symbolSize.width) / 2,
                    y: (size.height - symbolSize.height) / 2
                )
                configured.draw(in: NSRect(origin: symbolOrigin, size: symbolSize))
            }

            // Draw status dot if we have a state
            if let state {
                let dotSize: CGFloat = 7
                let dotRect = NSRect(
                    x: size.width - dotSize - 1,
                    y: 1,
                    width: dotSize,
                    height: dotSize
                )

                let dotColor: NSColor = switch state {
                case .ready: .systemGreen
                case .building: .systemOrange
                case .error: .systemRed
                case .queued, .initializing: .systemGray
                case .canceled: .secondaryLabelColor
                }

                // Draw dot background (for contrast)
                NSColor.black.withAlphaComponent(0.5).setFill()
                NSBezierPath(ovalIn: dotRect.insetBy(dx: -1, dy: -1)).fill()

                // Draw the dot
                dotColor.setFill()
                NSBezierPath(ovalIn: dotRect).fill()
            }

            return true
        }

        image.isTemplate = state == nil  // template only when no dot (so dot keeps its color)
        button.image = image
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

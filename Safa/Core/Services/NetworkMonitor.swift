// MARK: - NetworkMonitor.swift
// PURPOSE: Observe network connectivity status
// DEPENDENCIES: Network

import Foundation
import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private(set) var isConnected = true
    private(set) var connectionType: NWInterface.InterfaceType?

    var isOnWiFi: Bool {
        isConnected && connectionType == .wifi
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

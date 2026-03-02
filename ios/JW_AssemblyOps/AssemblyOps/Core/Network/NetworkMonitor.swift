//
//  NetworkMonitor.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/15/26.
//

// MARK: - Network Monitor
//
// Singleton that monitors network connectivity status using NWPathMonitor.
// Publishes connection state changes for SwiftUI views to observe.
//
// Published Properties:
//   - isConnected: True when device has network connectivity
//   - connectionType: Current connection type (wifi, cellular, unknown)
//
// Methods:
//   - startMonitoring(): Begin observing network path changes
//   - stopMonitoring(): Cancel the path monitor
//
// Usage:
//   @ObservedObject var networkMonitor = NetworkMonitor.shared
//   if networkMonitor.isConnected { ... }
//
// Dependencies:
//   - Network framework (NWPathMonitor)
//
// Used by: OfflineBanner, AssignmentsViewModel

import Foundation
import Network
import Combine

@MainActor final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case unknown
    }
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let isConnected = path.status == .satisfied
            let connectionType = self.getConnectionType(path)
            
            Task { @MainActor in
                self.isConnected = isConnected
                self.connectionType = connectionType
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    private nonisolated func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(NWInterface.InterfaceType.cellular) {
            return .cellular
        }
        return .unknown
    }
}

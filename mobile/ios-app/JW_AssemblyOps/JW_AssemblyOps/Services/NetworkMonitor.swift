//
//  NetworkMonitor.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/23/25.
//

import Foundation
import Network

@Observable
final class NetworkMonitor {
    
    // MARK: - Singleton
    
    static let shared = NetworkMonitor()
    
    // MARK: - Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown
    
    // MARK: - Connection Type
    
    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }
    
    // MARK: - Init
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        } else {
            return .unknown
        }
    }
}

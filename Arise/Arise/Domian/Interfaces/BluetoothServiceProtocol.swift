//
//  BluetoothServiceProtocol.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 01/06/2026.
//

import Foundation
import RxSwift

// MARK: - BluetoothState
enum BluetoothState {
    case unknown
    case poweredOn
    case poweredOff
    case unauthorized
    case unsupported
}

// MARK: - PeripheralDevice
struct PeripheralDevice: Equatable, Identifiable {
    let id: String
    let name: String
    let signalStrength: Int
    let isConnected: Bool
}

// MARK: - BluetoothServiceProtocol
protocol BluetoothServiceProtocol {
    
    // Stats
    var bluetoothState: Observable<BluetoothState> { get }
    
    // Scanning
    func startScanning() -> Observable<PeripheralDevice>
    func stopScanning()
    
    // Connection
    func connect(to deviceId: String) -> Completable
    func disconnect(from deviceId: String) -> Completable
    var connectedDevices: Observable<[PeripheralDevice]> { get }
    
    // Data Streams
    func observeHeartRate(from deviceId: String) -> Observable<HealthMetric>
    func observeBatteryLevel(from deviceId: String) -> Observable<Int>
}

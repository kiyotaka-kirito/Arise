//
//  CoreBluetoothService.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import CoreBluetooth
import RxSwift

final class CoreBluetoothService: NSObject, BluetoothServiceProtocol {
    
    private let bluetoothStateSubject = BehaviorSubject<BluetoothState>(value: .unknown)
    
    private let connectedDevicesSubject = BehaviorSubject<[PeripheralDevice]>(value: [])
    
    var bluetoothState: Observable<BluetoothState> {
        bluetoothStateSubject.asObservable()
    }
    
    var connectedDevices: Observable<[PeripheralDevice]> {
        connectedDevicesSubject.asObservable()
    }
    
    func startScanning() -> Observable<PeripheralDevice> { .empty() }
    
    func stopScanning() {}
    
    func connect(to deviceId: String) -> Completable { .empty() }
    
    func connect(from deviceId: String) -> Completable { .empty() }
    
    func observeHeartRate(from deviceId: String) -> Observable<HealthMetric> { .empty() }
    
    func observeBatteryLevel(from deviceId: String) -> Observable<Int> { .empty() }
    
}

//
//  CoreBluetoothService.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 02/06/2026.
//

import Foundation
import CoreBluetooth
import RxSwift

// MARK: - GATT UUIDs
private enum GATTService {
    static let heartRate    = CBUUID(string: "180D")
    static let battery      = CBUUID(string: "180F")
    static let deviceInfo   = CBUUID(string: "180A")
}

private enum GATTCharacteristic {
    static let heartRateMeasurement = CBUUID(string: "2A37")
    static let bodySensorLocation   = CBUUID(string: "2A38")
    static let batteryLevel         = CBUUID(string: "2A19")
    static let manufacturerName     = CBUUID(string: "2A29")
    static let modelNumber          = CBUUID(string: "2A24")
}

// MARK: - CoreBluetoothService
final class CoreBluetoothService: NSObject, BluetoothServiceProtocol {
    
    // MARK: - Core Bluetooth
    private var centralManager: CBCentralManager!
    private let bluetoothQueue = DispatchQueue(label: "com.arise.bluetooth", qos: .userInitiated)
    private var connectedPeripherals: [String: CBPeripheral] = [:]
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var pendingConnection: [String: (Bool) -> Void] = [:]
    
    // MARK: - RxSwift Subjects
    private let btStateSubject = BehaviorSubject<BluetoothState>(value: .unknown)
    private let discoveredDeveiceSubject = PublishSubject<PeripheralDevice>()
    private let connectedDeveicesSubject = BehaviorSubject<[PeripheralDevice]>(value: [])
    private var heartRateSubjects: [String: PublishSubject<HealthMetric>] = [:]
    private var batterySubjects: [String : PublishSubject<Int>] = [:]
    
    // MARK: - State
    private var currentUserId: String = ""
    private var isScanning = false
    
    // MARK: - Init
    override init() {
        super.init()
        
        centralManager = CBCentralManager(
            delegate: self,
            queue: bluetoothQueue,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true,
                CBCentralManagerOptionRestoreIdentifierKey: "com.arise.bluetooth.restore"
            ]
        )
    }
    
    // MARK: - Protocol: State
    var bluetoothState: Observable<BluetoothState> {
        btStateSubject.asObservable()
    }
    
    var connectedDevices: Observable<[PeripheralDevice]> {
        connectedDeveicesSubject.asObservable()
    }
    
    // MARK: - Protocol: Scanning
    func startScanning() -> Observable<PeripheralDevice> {
        guard centralManager.state == .poweredOn else {
            return .error(BluetoothError.bluetoothUnavailable)
        }
        
        guard !isScanning else {
            return discoveredDeveiceSubject.asObservable()
        }
        
        isScanning = true
        
        centralManager.scanForPeripherals(
            withServices: [GATTService.heartRate],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        
        return discoveredDeveiceSubject.asObservable()
    }
    
    func stopScanning() {
        guard isScanning else { return }
        isScanning = false
        centralManager.stopScan()
    }
    
    func connect(to deviceId: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(BluetoothError.deviceNotFound))
                return Disposables.create()
            }
            
            guard let periheral = self.discoveredPeripherals[deviceId] else {
                completable(.error(BluetoothError.deviceNotFound))
                return Disposables.create()
            }
            
            // Storet the completable resolver
            self.pendingConnection[deviceId] = { success in
                if success {
                    completable(.completed)
                } else {
                    completable(.error(BluetoothError.connectionFailed))
                }
            }
            
            // Connect
            self.centralManager.connect(
                periheral,
                options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true]
            )
            
            return Disposables.create {
                self.pendingConnection.removeValue(forKey: deviceId)
            }
        }
    }
    
    func disconnect(from deviceId: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self,
                  let peripheral = self.connectedPeripherals[deviceId] else {
                completable(.completed)
                return Disposables.create()
            }
            
            self.centralManager.cancelPeripheralConnection(peripheral)
            self.cleanupDevice(deviceId: deviceId)
            completable(.completed)
            
            return Disposables.create()
        }
    }
    
    // MARK: - Protocol: Data Streams
    func observeHeartRate(from deviceId: String) -> Observable<HealthMetric> {
        if heartRateSubjects[deviceId] == nil {
            heartRateSubjects[deviceId] = PublishSubject<HealthMetric>()
        }
        return heartRateSubjects[deviceId]!.asObservable()
    }
    
    func observeBatteryLevel(from deviceId: String) -> Observable<Int> {
        if batterySubjects[deviceId] == nil {
            batterySubjects[deviceId] = PublishSubject<Int>()
        }
        return batterySubjects[deviceId]!.asObservable()
    }
    
    // MARK: - Set User Context
    func setCurrentUser(_ userId: String) {
        currentUserId = userId
    }
    
    // MARK: - Helpers
    private func makePeripheralDeveice(
        from peripheral: CBPeripheral,
        rssi: Int,
        isConnected: Bool = false
    ) -> PeripheralDevice {
        PeripheralDevice(
            id: peripheral.identifier.uuidString,
            name: peripheral.name ?? "Unknown Device",
            signalStrength: rssi,
            isConnected: isConnected
        )
    }
    
    private func cleanupDevice(deviceId: String) {
        connectedPeripherals.removeValue(forKey: deviceId)
        heartRateSubjects[deviceId]?.onCompleted()
        heartRateSubjects.removeValue(forKey: deviceId)
        heartRateSubjects[deviceId]?.onCompleted()
        batterySubjects[deviceId]?.onCompleted()
        batterySubjects.removeValue(forKey: deviceId)
        updateConnectedDevicesList()
    }
    
    private func updateConnectedDevicesList() {
        let devices = connectedPeripherals.map { (deviceId, peripheral) in
            makePeripheralDeveice(from: peripheral, rssi: -60, isConnected: true)
        }
        connectedDeveicesSubject.onNext(devices)
    }
    
    // MARK: - Heart Rate Data Parsing
    private func parseHeartRate(from data: Data) -> Double? {
        guard !data.isEmpty else { return nil }
        
        let flags = data[0]
        
        let isUInt16Format = (flags & 0x01) != 0
        
        if isUInt16Format {
            guard data.count >= 3 else { return nil }
            let hrValue = UInt16(data[1]) | (UInt16(data[2]) << 8)
            return Double(hrValue)
        } else {
            guard data.count >= 2 else { return nil }
            return Double(data[1])
        }
    }
    
    // Parses battery level
    private func parseBatteryLevel(from data: Data) -> Int? {
        guard !data.isEmpty else { return nil }
        return Int(data[0])
    }
    
}

// MARK: - CBCentralManagerDelegate
extension CoreBluetoothService: CBCentralManagerDelegate {
    
    // Called when Bluetooth hardware state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state: BluetoothState
        
        switch central.state {
        case .poweredOn:        state = .poweredOn
        case .poweredOff:       state = .poweredOff
        case .unauthorized:     state = .unauthorized
        case .unsupported:      state = .unsupported
        default:                state = .unknown
        }
        
        btStateSubject.onNext(state)
        
        if central.state == .poweredOn && isScanning {
            centralManager.scanForPeripherals(
                withServices: [GATTService.heartRate],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceId = peripheral.identifier.uuidString
        
        discoveredPeripherals[deviceId] = peripheral
        
        let device = makePeripheralDeveice(
            from: peripheral,
            rssi: RSSI.intValue
        )
        
        discoveredDeveiceSubject.onNext(device)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let deviceId = peripheral.identifier.uuidString
        
        discoveredPeripherals[deviceId] = peripheral
        
        peripheral.delegate = self
        
        peripheral.discoverServices([
            GATTService.heartRate,
            GATTService.battery,
            GATTService.deviceInfo
        ])
        
        pendingConnection[deviceId]?(true)
        pendingConnection.removeValue(forKey: deviceId)
        
        updateConnectedDevicesList()
        
        print("Connected to: \(peripheral.name ?? deviceId)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let deviceId = peripheral.identifier.uuidString
        pendingConnection[deviceId]?(false)
        pendingConnection.removeValue(forKey: deviceId)
        
        print("Failed to connect: \(error?.localizedDescription ?? "unknown")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let deviceId = peripheral.identifier.uuidString
        
        if let error = error {
            print("Unexpected disconnect: \(error.localizedDescription)")
            centralManager.connect(peripheral, options: nil)
        } else {
            cleanupDevice(deviceId: deviceId)
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey]
            as? [CBPeripheral] {
            peripherals.forEach { peripheral in
                peripheral.delegate = self
                discoveredPeripherals[peripheral.identifier.uuidString] = peripheral
            }
        }
    }
    
}

// MARL: - CBPeripheralDelegate
extension CoreBluetoothService: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }
        
        for service in services {
            switch service.uuid {
                
            case GATTService.heartRate:
                peripheral.discoverCharacteristics(
                    [GATTCharacteristic.heartRateMeasurement, GATTCharacteristic.bodySensorLocation],
                    for: service
                )
                
            case GATTService.battery:
                peripheral.discoverCharacteristics(
                    [GATTCharacteristic.batteryLevel],
                    for: service
                )
                
            case GATTService.deviceInfo:
                peripheral.discoverCharacteristics(
                    [GATTCharacteristic.manufacturerName,
                     GATTCharacteristic.modelNumber],
                    for: service
                )
            default:
                break
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
                
            case GATTCharacteristic.heartRateMeasurement:
                peripheral.setNotifyValue(true, for: characteristic)
                
            case GATTCharacteristic.batteryLevel:
                peripheral.readValue(for: characteristic)
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                
            case GATTCharacteristic.bodySensorLocation,
                GATTCharacteristic.manufacturerName,
                GATTCharacteristic.modelNumber:
                peripheral.readValue(for: characteristic)
                
            default:
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }
        
        let deviceId = peripheral.identifier.uuidString
        
        switch characteristic.uuid {
        case GATTCharacteristic.heartRateMeasurement:
            guard let bpm = parseHeartRate(from: data) else { return }
            
            let metric = HealthMetric(
                userId: currentUserId,
                type: .heartRate,
                value: bpm,
                recordedAt: Date(),
                source: .bluetoothDevice,
                deviceId: deviceId
            )
            
            if heartRateSubjects[deviceId] == nil {
                heartRateSubjects[deviceId] = PublishSubject<HealthMetric>()
            }
            heartRateSubjects[deviceId]?.onNext(metric)
            
        case GATTCharacteristic.batteryLevel:
            guard let level = parseBatteryLevel(from: data) else { return }
            
            if batterySubjects[deviceId] == nil {
                batterySubjects[deviceId] = PublishSubject<Int>()
            }
            batterySubjects[deviceId]?.onNext(level)
            
        default:
             break
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Notification error for \(characteristic.uuid): \(error)")
        } else {
            print("Subscribe to notification for \(characteristic.uuid)")
        }
    }
}

// MARK: - BluetoothError
enum BluetoothError: LocalizedError {
    case bluetoothUnavailable
    case deviceNotFound
    case connectionFailed
    case dataParseError
    case notConnected
    
    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            return "Bluetooth is not available. Please enable it in Settings."
        case .deviceNotFound:
            return "Device not found. Make sure it's powered on and nearby."
        case .connectionFailed:
            return "Could not connect to device. Please try again."
        case .dataParseError:
            return "Failed to read data from device."
        case .notConnected:
            return "No device connected."
        }
    }
}

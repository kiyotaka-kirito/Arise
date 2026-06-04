//
//  BluetoothViewModel.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 04/06/2026.
//

import Foundation
import SwiftUI
import RxSwift
import RxCocoa

// MARK: - ScanState
enum ScanState: Equatable {
    case idle
    case scanning
    case connecting(String)
    case connected(String)
    case error(String)
}

// MARK: - BluetoothViewModel
final class BluetoothViewModel {
    
    // MARK: - Dependencies
    private let bluetoothService: BluetoothServiceProtocol
    
    // MARK: - Outputs
    let scanState           = BehaviorRelay<ScanState>(value: .idle)
    let discoveredDevices   = BehaviorRelay<[PeripheralDevice]>(value: [])
    let connectedDevices    = BehaviorRelay<[PeripheralDevice]>(value: [])
    let bluetoothState      = BehaviorRelay<BluetoothState>(value: .unknown)
    let liveHeartRate       = BehaviorRelay<Double>(value: 0)
    let batteryLevel        = BehaviorRelay<Int>(value: -1)
    let errorMessage        = PublishRelay<String>()
    
    // MARK: - Memory Management
    private let disposeBag = DisposeBag()
    private var sessionBag = DisposeBag()
    
    // MARK: - Init
    init(bluetoothService: BluetoothServiceProtocol) {
        self.bluetoothService = bluetoothService
        setupStateObserver()
        setupConnectedDevicesObserver()
    }
    
    // MARK: - Inputs
    func startScanning() {
        guard case .idle = scanState.value else { return }
        
        sessionBag = DisposeBag()
        discoveredDevices.accept([])
        scanState.accept(.scanning)
        
        bluetoothService.startScanning()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] device in
                    guard let self = self else { return }
                    self.addOrUpdateDevice(device)
                },
                onError: { [weak self] error in
                    self?.scanState.accept(.error(error.localizedDescription))
                    self?.errorMessage.accept(error.localizedDescription)
                }
            )
            .disposed(by: sessionBag)
    }
    
    func stopScanning() {
        bluetoothService.stopScanning()
        if case .scanning = scanState.value {
            scanState.accept(.idle)
        }
    }
    
    func connectToDevice(_ device: PeripheralDevice) {
        
        stopScanning()
        scanState.accept(.connecting(device.id))
        
        bluetoothService.connect(to: device.id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.scanState.accept(.connected(device.id))
                    self.startReceivingHeartRate(from: device.id)
                    self.startReceivingBattery(from: device.id)
                },
                onError: { [weak self] error in
                    self?.scanState.accept(.idle)
                    self?.errorMessage.accept(error.localizedDescription)
                }
            )
            .disposed(by: sessionBag)
    }
    
    func disconnectFromDevice(_ deviceId: String) {
        bluetoothService.disconnect(from: deviceId)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onCompleted: { [weak self] in
                    self?.scanState.accept(.idle)
                    self?.liveHeartRate.accept(0)
                    self?.batteryLevel.accept(-1)
                    self?.sessionBag = DisposeBag()
                },
                onError: { [weak self] error in
                    self?.errorMessage.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    private func startReceivingHeartRate(from deviceId: String) {
        bluetoothService.observeHeartRate(from: deviceId)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] metric in
                self?.liveHeartRate.accept(metric.value)
            })
            .disposed(by: sessionBag)
    }
    
    private func startReceivingBattery(from deviceId: String) {
        bluetoothService.observeBatteryLevel(from: deviceId)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] level in
                self?.batteryLevel.accept(level)
            })
            .disposed(by: sessionBag)
    }
    
    private func setupStateObserver() {
        bluetoothService.bluetoothState
            .observe(on: MainScheduler.instance)
            .bind(to: bluetoothState)
            .disposed(by: sessionBag)
    }
    
    private func setupConnectedDevicesObserver() {
        bluetoothService.connectedDevices
            .observe(on: MainScheduler.instance)
            .bind(to: connectedDevices)
            .disposed(by: sessionBag)
    }
    
    private func addOrUpdateDevice(_ device: PeripheralDevice) {
        var current = discoveredDevices.value
        
        if let index = current.firstIndex(where: { $0.id == device.id }) {
            current[index] = device
        } else {
            current.append(device)
            current.sort { $0.signalStrength > $1.signalStrength }
        }
        
        discoveredDevices.accept(current)
    }
    
    // MARK: - Computed Helpers
    var isScanning: Bool {
        if case .scanning = scanState.value { return true }
        return false
    }
    
    var connectedDeviceId: String? {
        if case .connected(let id) = scanState.value { return id }
        return nil
    }
    
    var heartRateDisplay: String {
        liveHeartRate.value > 0 ? "\(Int(liveHeartRate.value))" : "--"
    }
    
    var batteryDisplay: String {
        batteryLevel.value >= 0 ? "\(batteryLevel.value)%" : "--"
    }
    
    var heartRateZone: HeartRateZone {
        HeartRateZone(bpm: liveHeartRate.value)
    }
    
    // Signal strenght
    func signalLabel(for rssi: Int) -> String {
        switch rssi {
        case -60...0:       return "Excellent"
        case -70 ..< -60:   return "Good"
        case -80 ..< -70:   return "Fair"
        default:            return "Weak"
        }
    }
    
    func signalIcon(for rssi: Int) -> String {
        switch rssi {
        case -60...0:       return "wifi"
        case -70 ..< -60:   return "wifi"
        case -80 ..< -70:   return "wifi"
        default:            return "wifi.exclamationmark"
        }
    }
    
    func signalColor(for rssi: Int) -> Color {
        switch rssi {
        case -60...0:       return .green
        case -70 ..< -60:   return .yellow
        case -80 ..< -70:   return .orange
        default:            return .red
        }
    }
    
}

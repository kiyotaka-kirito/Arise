//
//  BluetoothScanView.swift
//  Arise
//
//  Created by Kiyotaka Kirito on 04/06/2026.
//

import SwiftUI
import RxSwift
import Combine

// MARK: - BluetoothScanView
struct BluetoothScanView: View {
    
    @StateObject private var wrapper: BluetoothViewModelWrapper
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: BluetoothViewModel) {
        _wrapper = StateObject(
            wrappedValue: BluetoothViewModelWrapper(viewModel: viewModel)
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ariseBackgroundFallback.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Bluetooth state banner
                    bluetoothStateBanner
                    
                    // Connected device
                    if !wrapper.connectedDevices.isEmpty {
                        connectedSection
                    }
                    
                    // Scan
                    scanSection
                }
            }
            .navigationTitle("Heart Rate Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Bluetooth Error", isPresented: $wrapper.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(wrapper.errorText)
            }
        }
        .onAppear { wrapper.startScanning() }
        .onDisappear { wrapper.stopScanning() }
    }
    
    // MARK: - Bluetooth State Banner
    @ViewBuilder
    private var bluetoothStateBanner: some View {
        switch wrapper.bluetoothState {
        case .poweredOff:
            bannerView(
                icon: "bluetooth",
                message: "Bluetooth is off. Enable it in Control Center.",
                color: .orange
            )
        case .unauthorized:
            bannerView(
                icon: "bluetooth.slash",
                message: "Bluetooth permission denied. Check Settings.",
                color: .red
            )
        case .unsupported:
            bannerView(
                icon: "exclamationmark.triangle.fill",
                message: "Bluetooth not supported on this device.",
                color: .red
            )
        default:
            EmptyView()
        }
    }
    
    private func bannerView(icon: String, message: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
    }
    
    // MARK: - Connected Devices Section
    private var connectedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Connected")
            
            VStack(spacing: 0) {
                ForEach(wrapper.connectedDevices) { device in
                    PeripheralRowView(
                        device: device,
                        signalLabel: "Connected",
                        signalColor: .green,
                        isConnecting: false,
                        isConnected: true,
                        onConnect: {},
                        onDisconnect: {
                            wrapper.disconnect(from: device.id)
                        }
                    )
                    
                    // Live HR preview
                    if wrapper.liveHeartRate > 0 {
                        HeartRateMonitorView(
                            bpm: wrapper.liveHeartRate,
                            zone: wrapper.heartRateZone,
                            deviceName: device.name,
                            batteryLevel: wrapper.batteryLevel
                        )
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ariseCardFallback)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Scan Section
    private var scanSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            HStack {
                sectionHeader("Nearby Devices")
                Spacer()
                
                // Scan indicator
                if wrapper.isScanning {
                    HStack(spacing: 6) {
                        ScanningIndicator()
                        Text("Scanning...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("Scan Again") {
                        wrapper.startScanning()
                    }
                    .font(.caption)
                    .foregroundStyle(Color.arisePrimaryFallback)
                }
            }
            .padding(.horizontal, 20)
            
            if wrapper.discoveredDevices.isEmpty && wrapper.isScanning {
                scanningEmptyState
            } else if wrapper.discoveredDevices.isEmpty {
                noDevicesEmptyState
            } else {
                devicesList
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Devices List
    private var devicesList: some View {
        VStack(spacing: 0) {
            ForEach(wrapper.discoveredDevices) { device in
                let isConnecting: Bool = {
                    if case .connecting(let id) = wrapper.scanState {
                        return id == device.id
                    }
                    return false
                }()
                
                let isConnected = wrapper.connectedDevices.contains { $0.id == device.id }
                
                PeripheralRowView(
                    device: device,
                    signalLabel: wrapper.signalLabel(for: device.signalStrength),
                    signalColor: wrapper.signalColor(for: device.signalStrength),
                    isConnecting: isConnecting,
                    isConnected: isConnected,
                    onConnect: { wrapper.connect(to: device) },
                    onDisconnect: { wrapper.disconnect(from: device.id) }
                )
                
                if device.id != wrapper.discoveredDevices.last?.id {
                    Divider().padding(.leading, 62)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ariseCardFallback)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Empty State
    private var scanningEmptyState: some View {
        VStack(spacing: 16) {
            ScanningIndicator(size: 48)
            Text("Searching for heart rate monitors...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Make sure your device is powered on and nearby")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    private var noDevicesEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No devices found")
                .font(.subheadline)
                .fontWeight(.medium)
            Text("Compatible devices: Polar H10, Garmin HRM, Wahoo TICKR, Apple Watch")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    // MARK: - Helper
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
    }
    
}

// MARK: - ScanningIndicator
struct ScanningIndicator: View {
    
    var size: CGFloat = 20
    @State private var phase = 0
    
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: size * 0.2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.arisePrimaryFallback)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .scaleEffect(phase == index ? 1.4 : 0.8)
                    .opacity(phase == index ? 1.0 : 0.4)
                    .animation(.easeInOut(duration: 0.3), value: phase)
            }
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - BluetoothViewModelWrapper
@MainActor
final class BluetoothViewModelWrapper: ObservableObject {
    
    @Published var discoveredDevices: [PeripheralDevice]    = []
    @Published var connectedDevices: [PeripheralDevice]     = []
    @Published var bluetoothState: BluetoothState           = .unknown
    @Published var scanState: ScanState                     = .idle
    @Published var liveHeartRate: Double                    = 0
    @Published var batteryLevel: Int                        = -1
    @Published var isScanning: Bool                         = false
    @Published var showError: Bool                          = false
    @Published var errorText: String                        = ""
    
    var heartRateZone: HeartRateZone { viewModel.heartRateZone }
    
    private let viewModel: BluetoothViewModel
    private var disposeBag = DisposeBag()
    
    init(viewModel: BluetoothViewModel) {
        self.viewModel = viewModel
        bindToViewModel()
    }
    
    private func bindToViewModel() {
        
        viewModel.discoveredDevices
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.discoveredDevices = $0 })
            .disposed(by: disposeBag)
        
        viewModel.connectedDevices
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.connectedDevices = $0 })
            .disposed(by: disposeBag)
        
        viewModel.bluetoothState
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.bluetoothState = $0 })
            .disposed(by: disposeBag)
        
        viewModel.scanState
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.scanState = state
                if case .scanning = state { self?.isScanning = true }
                else { self?.isScanning = false }
            })
            .disposed(by: disposeBag)
        
        viewModel.liveHeartRate
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.liveHeartRate = $0 })
            .disposed(by: disposeBag)
        
        viewModel.batteryLevel
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.batteryLevel = $0 })
            .disposed(by: disposeBag)
        
        viewModel.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.errorText = message
                self?.showError = true
            })
            .disposed(by: disposeBag)
    }
    
    func startScanning()                        { viewModel.startScanning() }
    func stopScanning()                         { viewModel.stopScanning() }
    func connect(to device: PeripheralDevice)   { viewModel.connectToDevice(device) }
    func disconnect(from id: String)            { viewModel.disconnectFromDevice(id) }
    func signalLabel(for rssi: Int) -> String   { viewModel.signalLabel(for: rssi) }
    func signalColor(for rssi: Int) -> Color    { viewModel.signalColor(for: rssi) }
}


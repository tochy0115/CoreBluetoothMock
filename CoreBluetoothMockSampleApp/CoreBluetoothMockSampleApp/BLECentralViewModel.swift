import Foundation
import SwiftUI

#if targetEnvironment(simulator)
import CoreBluetoothMock // Use CoreBluetoothMock on Simulator. Install "CB Interaction Viewer" to emulate peripherals from App Store(https://apps.apple.com/jp/app/cb-interaction-viewer/id6757977616?mt=12).
#else
import CoreBluetooth
#endif

final class BLECentralViewModel: NSObject, ObservableObject {
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var scanning = false
    @Published var discoveredDevices: [ScannedDevice] = []
    @Published var connectedDeviceID: UUID?
    @Published var connected = false
    @Published var services: [BLEServiceItem] = []
    @Published var characteristicHexInputs: [String: String] = [:]
    @Published var descriptorHexInputs: [String: String] = [:]
    @Published var statusText: String = ""

    // `CBCentralManager` drives scanning and connection lifecycle for the app's central role.
    private lazy var centralManager: CBCentralManager = {
        CBCentralManager(delegate: self, queue: nil)
    }()

    private var discoveredPeripheralMap: [UUID: CBPeripheral] = [:]
    private var discoveredRSSIMap: [UUID: Int] = [:]
    private var connectedPeripheral: CBPeripheral?

    private var characteristicMap: [String: CBCharacteristic] = [:]
    private var characteristicIDByObjectID: [ObjectIdentifier: String] = [:]

    private var descriptorMap: [String: CBDescriptor] = [:]
    private var descriptorIDByObjectID: [ObjectIdentifier: String] = [:]

    override init() {
        super.init()
        _ = centralManager
    }

    func toggleScan() {
        scanning ? stopScan() : startScan()
    }

    func startScan() {
        guard bluetoothState == .poweredOn else {
            statusText = "Bluetooth is not powered on"
            return
        }

        discoveredDevices = []
        discoveredPeripheralMap.removeAll()
        discoveredRSSIMap.removeAll()

        // `withServices: nil` discovers all advertising peripherals.
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        scanning = true
    }

    func stopScan() {
        centralManager.stopScan()
        scanning = false
    }

    func connect(to deviceID: UUID) {
        guard bluetoothState == .poweredOn else {
            statusText = "Bluetooth is not powered on"
            return
        }

        guard let peripheral = discoveredPeripheralMap[deviceID] else {
            statusText = "Device not found"
            return
        }

        stopScan()
        statusText = "Connecting..."
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
        if let connectedPeripheral {
            centralManager.cancelPeripheralConnection(connectedPeripheral)
        }
        clearConnectionState()
    }

    func refreshServices() {
        connectedPeripheral?.discoverServices(nil)
    }

    func setCharacteristicHexInput(id: String, value: String) {
        characteristicHexInputs[id] = value
    }

    func setDescriptorHexInput(id: String, value: String) {
        descriptorHexInputs[id] = value
    }

    func readCharacteristic(id: String) {
        guard let peripheral = connectedPeripheral, let characteristic = characteristicMap[id] else {
            return
        }
        peripheral.readValue(for: characteristic)
    }

    func writeCharacteristic(id: String) {
        guard let peripheral = connectedPeripheral, let characteristic = characteristicMap[id] else {
            return
        }

        let input = characteristicHexInputs[id] ?? ""
        let data = BLEHex.decode(input)

        if characteristic.properties.contains(.write) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        } else if characteristic.properties.contains(.writeWithoutResponse) {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        }
    }

    func toggleNotify(id: String) {
        guard let peripheral = connectedPeripheral, let characteristic = characteristicMap[id] else {
            return
        }
        peripheral.setNotifyValue(!characteristic.isNotifying, for: characteristic)
    }

    func isNotifying(id: String) -> Bool {
        characteristicMap[id]?.isNotifying ?? false
    }

    func readDescriptor(id: String) {
        guard let peripheral = connectedPeripheral, let descriptor = descriptorMap[id] else {
            return
        }
        peripheral.readValue(for: descriptor)
    }

    func writeDescriptor(id: String) {
        guard let peripheral = connectedPeripheral, let descriptor = descriptorMap[id] else {
            return
        }

        let input = descriptorHexInputs[id] ?? ""
        let data = BLEHex.decode(input)
        peripheral.writeValue(data, for: descriptor)
    }

    func connectedDeviceAddress(for deviceID: UUID) -> String {
        discoveredDevices.first(where: { $0.id == deviceID })?.address ?? deviceID.uuidString
    }

    private func clearConnectionState() {
        connected = false
        connectedDeviceID = nil
        connectedPeripheral = nil
        services = []
        characteristicMap.removeAll()
        characteristicIDByObjectID.removeAll()
        descriptorMap.removeAll()
        descriptorIDByObjectID.removeAll()
        characteristicHexInputs.removeAll()
        descriptorHexInputs.removeAll()
    }

    private func updateDiscoveredDeviceList() {
        discoveredDevices = discoveredPeripheralMap.values
            .sorted { $0.identifier.uuidString < $1.identifier.uuidString }
            .map { peripheral in
                let rssi = discoveredRSSIMap[peripheral.identifier] ?? 0
                return ScannedDevice(
                    id: peripheral.identifier,
                    name: peripheral.name ?? "(no name)",
                    address: peripheral.identifier.uuidString,
                    rssi: rssi
                )
            }
    }

    private func mapServices(_ peripheral: CBPeripheral) {
        guard let cbServices = peripheral.services else {
            services = []
            return
        }

        characteristicMap.removeAll()
        characteristicIDByObjectID.removeAll()
        descriptorMap.removeAll()
        descriptorIDByObjectID.removeAll()

        // Build a stable view-model snapshot and keep ID-to-CoreBluetooth object maps
        // so UI actions (read/write/notify) can target the correct object later.
        let uiServices: [BLEServiceItem] = cbServices.enumerated().map { serviceIndex, service in
            let uiCharacteristics: [BLECharacteristicItem] = (service.characteristics ?? []).enumerated().map { characteristicIndex, characteristic in
                let characteristicID = "s\(serviceIndex)-c\(characteristicIndex)-\(characteristic.uuid.uuidString)"
                characteristicMap[characteristicID] = characteristic
                characteristicIDByObjectID[ObjectIdentifier(characteristic)] = characteristicID

                let uiDescriptors: [BLEDescriptorItem] = (characteristic.descriptors ?? []).enumerated().map { descriptorIndex, descriptor in
                    let descriptorID = "\(characteristicID)-d\(descriptorIndex)-\(descriptor.uuid.uuidString)"
                    descriptorMap[descriptorID] = descriptor
                    descriptorIDByObjectID[ObjectIdentifier(descriptor)] = descriptorID
                    return BLEDescriptorItem(id: descriptorID, uuid: descriptor.uuid.uuidString)
                }

                return BLECharacteristicItem(
                    id: characteristicID,
                    uuid: characteristic.uuid.uuidString,
                    propertiesDescription: characteristic.properties.uiDescription,
                    canRead: characteristic.properties.contains(.read),
                    canWrite: characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse),
                    canNotify: characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate),
                    descriptors: uiDescriptors
                )
            }

            return BLEServiceItem(
                id: "s\(serviceIndex)-\(service.uuid.uuidString)",
                uuid: service.uuid.uuidString,
                characteristics: uiCharacteristics
            )
        }

        services = uiServices
    }
}

private extension CBCharacteristicProperties {
    var uiDescription: String {
        var labels: [String] = []
        if contains(.broadcast) { labels.append("broadcast") }
        if contains(.read) { labels.append("read") }
        if contains(.writeWithoutResponse) { labels.append("writeWithoutResponse") }
        if contains(.write) { labels.append("write") }
        if contains(.notify) { labels.append("notify") }
        if contains(.indicate) { labels.append("indicate") }
        if contains(.authenticatedSignedWrites) { labels.append("authenticatedSignedWrites") }
        if contains(.extendedProperties) { labels.append("extendedProperties") }
        if contains(.notifyEncryptionRequired) { labels.append("notifyEncryptionRequired") }
        if contains(.indicateEncryptionRequired) { labels.append("indicateEncryptionRequired") }
        return labels.isEmpty ? "none" : labels.joined(separator: " | ")
    }
}

extension BLECentralViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.bluetoothState = central.state
            if central.state != .poweredOn {
                self.stopScan()
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        DispatchQueue.main.async {
            self.discoveredPeripheralMap[peripheral.identifier] = peripheral
            self.discoveredRSSIMap[peripheral.identifier] = RSSI.intValue
            self.updateDiscoveredDeviceList()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.connectedPeripheral = peripheral
            self.connectedDeviceID = peripheral.identifier
            self.connected = true
            self.statusText = "Connected"
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.statusText = "Disconnected"
            self.clearConnectionState()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.statusText = "Connection failed"
            self.clearConnectionState()
        }
    }
}

extension BLECentralViewModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        DispatchQueue.main.async {
            if error != nil {
                self.statusText = "Service discovery failed"
                return
            }

            // After services are discovered, request all characteristics for each service.
            for service in peripheral.services ?? [] {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            self.mapServices(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        DispatchQueue.main.async {
            if error != nil {
                self.statusText = "Characteristic discovery failed"
                return
            }

            // After characteristics are discovered, request their descriptors.
            for characteristic in service.characteristics ?? [] {
                peripheral.discoverDescriptors(for: characteristic)
            }
            self.mapServices(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async {
            if error != nil {
                self.statusText = "Descriptor discovery failed"
                return
            }
            self.mapServices(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async {
            guard error == nil else {
                self.statusText = "Characteristic read failed"
                return
            }
            guard let id = self.characteristicIDByObjectID[ObjectIdentifier(characteristic)] else {
                return
            }
            self.characteristicHexInputs[id] = BLEHex.encode(characteristic.value)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async {
            if error != nil {
                self.statusText = "Characteristic write failed"
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        DispatchQueue.main.async {
            if error != nil {
                self.statusText = "Notify update failed"
            } else {
                self.objectWillChange.send()
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        DispatchQueue.main.async {
            guard error == nil else {
                self.statusText = "Descriptor read failed"
                return
            }
            guard let id = self.descriptorIDByObjectID[ObjectIdentifier(descriptor)] else {
                return
            }

            if let data = descriptor.value as? Data {
                self.descriptorHexInputs[id] = BLEHex.encode(data)
            } else if let number = descriptor.value as? NSNumber {
                let value = UInt8(clamping: number.intValue)
                self.descriptorHexInputs[id] = BLEHex.encode(Data([value]))
            } else if let text = descriptor.value as? String {
                self.descriptorHexInputs[id] = BLEHex.encode(Data(text.utf8))
            } else {
                self.descriptorHexInputs[id] = ""
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        DispatchQueue.main.async {
            if error != nil {
                self.statusText = "Descriptor write failed"
            }
        }
    }
}

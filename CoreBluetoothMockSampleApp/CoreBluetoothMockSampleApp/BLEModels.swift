import Foundation

struct ScannedDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let address: String
    let rssi: Int
}

struct BLEServiceItem: Identifiable, Equatable {
    let id: String
    let uuid: String
    let characteristics: [BLECharacteristicItem]
}

struct BLECharacteristicItem: Identifiable, Equatable {
    let id: String
    let uuid: String
    let propertiesDescription: String
    let canRead: Bool
    let canWrite: Bool
    let canNotify: Bool
    let descriptors: [BLEDescriptorItem]
}

struct BLEDescriptorItem: Identifiable, Equatable {
    let id: String
    let uuid: String
}

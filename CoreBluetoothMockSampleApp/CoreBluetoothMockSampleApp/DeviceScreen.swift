import SwiftUI

struct DeviceScreen: View {
    @ObservedObject var viewModel: BLECentralViewModel
    let deviceID: UUID
    let onBack: () -> Void

    var body: some View {
        List {
            if !viewModel.statusText.isEmpty {
                Text(viewModel.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(viewModel.services) { service in
                Section("Service: \(service.uuid)") {
                    ForEach(service.characteristics) { characteristic in
                        CharacteristicPanel(
                            characteristic: characteristic,
                            characteristicHex: Binding(
                                get: { viewModel.characteristicHexInputs[characteristic.id] ?? "" },
                                set: { viewModel.setCharacteristicHexInput(id: characteristic.id, value: $0) }
                            ),
                            onRead: { viewModel.readCharacteristic(id: characteristic.id) },
                            onWrite: { viewModel.writeCharacteristic(id: characteristic.id) },
                            onNotifyToggle: { viewModel.toggleNotify(id: characteristic.id) },
                            isNotifying: viewModel.isNotifying(id: characteristic.id),
                            descriptorHexInputs: viewModel.descriptorHexInputs,
                            onDescriptorInput: { descriptorID, value in
                                viewModel.setDescriptorHexInput(id: descriptorID, value: value)
                            },
                            onDescriptorRead: { descriptorID in
                                viewModel.readDescriptor(id: descriptorID)
                            },
                            onDescriptorWrite: { descriptorID in
                                viewModel.writeDescriptor(id: descriptorID)
                            }
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.connectedDeviceAddress(for: deviceID))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("←") {
                    onBack()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Disconnect") {
                    onBack()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    viewModel.refreshServices()
                }
            }
        }
    }
}

private struct CharacteristicPanel: View {
    let characteristic: BLECharacteristicItem
    @Binding var characteristicHex: String
    let onRead: () -> Void
    let onWrite: () -> Void
    let onNotifyToggle: () -> Void
    let isNotifying: Bool
    let descriptorHexInputs: [String: String]
    let onDescriptorInput: (String, String) -> Void
    let onDescriptorRead: (String) -> Void
    let onDescriptorWrite: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Characteristic: \(characteristic.uuid)")
                .font(.subheadline)

            Text("Properties: \(characteristic.propertiesDescription)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                if characteristic.canRead {
                    Button("READ") {
                        onRead()
                    }
                    .buttonStyle(.bordered)
                }

                if characteristic.canWrite {
                    Button("WRITE") {
                        onWrite()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if characteristic.canNotify {
                    Button(isNotifying ? "NOTIFY OFF" : "NOTIFY ON") {
                        onNotifyToggle()
                    }
                    .buttonStyle(.bordered)
                }
            }

            TextField("Value (HEX)", text: $characteristicHex)
                .textInputAutocapitalization(.characters)
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)

            ForEach(characteristic.descriptors) { descriptor in
                DescriptorPanel(
                    descriptor: descriptor,
                    descriptorHex: Binding(
                        get: { descriptorHexInputs[descriptor.id] ?? "" },
                        set: { onDescriptorInput(descriptor.id, $0) }
                    ),
                    onRead: { onDescriptorRead(descriptor.id) },
                    onWrite: { onDescriptorWrite(descriptor.id) }
                )
            }
        }
        .padding(.vertical, 6)
    }
}

private struct DescriptorPanel: View {
    let descriptor: BLEDescriptorItem
    @Binding var descriptorHex: String
    let onRead: () -> Void
    let onWrite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Descriptor: \(descriptor.uuid)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button("D-READ") {
                    onRead()
                }
                .buttonStyle(.bordered)

                Button("D-WRITE") {
                    onWrite()
                }
                .buttonStyle(.bordered)
            }

            TextField("Descriptor Value (HEX)", text: $descriptorHex)
                .textInputAutocapitalization(.characters)
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)
        }
        .padding(8)
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

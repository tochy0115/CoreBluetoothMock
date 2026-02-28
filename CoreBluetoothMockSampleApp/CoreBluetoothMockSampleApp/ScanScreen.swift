import SwiftUI

struct ScanScreen: View {
    @ObservedObject var viewModel: BLECentralViewModel
    let onSelectDevice: (UUID) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(viewModel.scanning ? "Stop Scan" : "Start Scan") {
                viewModel.toggleScan()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)

            if !viewModel.statusText.isEmpty {
                Text(viewModel.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            List(viewModel.discoveredDevices) { device in
                Button {
                    onSelectDevice(device.id)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(device.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(device.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("RSSI: \(device.rssi)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        .navigationTitle("BLE Scan")
    }
}

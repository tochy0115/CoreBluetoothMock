import SwiftUI
struct ContentView: View {
    @StateObject private var viewModel = BLECentralViewModel()
    @State private var selectedDeviceID: UUID?
    @State private var showDeviceScreen = false

    var body: some View {
        NavigationView {
            ZStack {
                ScanScreen(viewModel: viewModel) { deviceID in
                    selectedDeviceID = deviceID
                    viewModel.connect(to: deviceID)
                    showDeviceScreen = true
                }

                NavigationLink(
                    destination: deviceDestinationView,
                    isActive: $showDeviceScreen
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var deviceDestinationView: some View {
        if let selectedDeviceID {
            DeviceScreen(viewModel: viewModel, deviceID: selectedDeviceID) {
                viewModel.disconnect()
                showDeviceScreen = false
                self.selectedDeviceID = nil
            }
        } else {
            EmptyView()
        }
    }
}

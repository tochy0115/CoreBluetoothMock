# CoreBluetoothMock (English Version)

`CoreBluetoothMock.framework` is a framework for mocking the CoreBluetooth API on the iOS simulator.  
Using this framework, you can develop and test BLE communication functionality on the iOS simulator via BLE Sim Linker, which accesses macOS CoreBluetooth.

## Features

- Provides an interface compatible with the CoreBluetooth API
- Allows mocking BLE device connections and communication on the iOS simulator
- Usable from both Swift and Objective-C
- Uses BLE Sim Linker to access macOS CoreBluetooth, reproducing behavior closer to real devices

## Supported Environments

- Xcode 26.2 or later
- Swift / Objective-C
- iOS Simulator (use CoreBluetooth.framework on real devices)
- BLE Sim Linker must be running on macOS before starting the simulator

## Installation

1. Obtain `CoreBluetoothMock.framework` from this repository: [https://github.com/tochy0115/CoreBluetoothMock.git](https://github.com/tochy0115/CoreBluetoothMock.git)
2. Add it to **Frameworks, Libraries, and Embedded Content** in your Xcode project
3. Optionally, add the `CoreBluetoothMockDependencies` package via Swift Package Manager to resolve dependencies

## Usage

### Swift
```swift
#if targetEnvironment(simulator)
import CoreBluetoothMock
#else
import CoreBluetooth
#endif

// You can use the same CoreBluetooth API for BLE operations
```

### Objective-C
```objective-c
#if TARGET_OS_SIMULATOR
#import <CoreBluetoothMock/CoreBluetoothMock.h>
#else
#import <CoreBluetooth/CoreBluetooth.h>
#endif

// You can use the same CoreBluetooth API for BLE operations
```

## Notes

- Use CoreBluetooth.framework for testing Bluetooth on real devices.
- This is a simulator mock and does not fully replicate real device behavior.
- CoreBluetoothMock will not function correctly on the simulator if BLE Sim Linker is not running.
- **Modification, reverse engineering, decompilation, or analysis of this framework is prohibited.**

## License

Proprietary License


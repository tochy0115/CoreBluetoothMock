# CoreBluetoothMock

`CoreBluetoothMock.framework` is a framework for mocking the CoreBluetooth API on the iOS simulator.  
Using this framework, you can develop and test BLE communication functionality on the iOS simulator via [CB Interaction Viewer](https://apps.apple.com/jp/app/cb-interaction-viewer/id6757977616?mt=12), which accesses macOS CoreBluetooth.

## Features

- Provides an interface compatible with the CoreBluetooth API
- Allows mocking BLE device connections and communication on the iOS simulator
- Usable from both Swift and Objective-C
- Uses [CB Interaction Viewer](https://apps.apple.com/jp/app/cb-interaction-viewer/id6757977616?mt=12) to access macOS CoreBluetooth, reproducing behavior closer to real devices

## Included Files

### Framework payload (`Frameworks/CoreBluetoothMock.framework`)

- `CoreBluetoothMock`: Framework binary
- `Info.plist`: Framework metadata
- `Headers/CoreBluetoothMock.h`: Main public header
- `Headers/CoreBluetoothMock-Swift.h`: Swift generated Objective-C interface header
- `Modules/module.modulemap`: Clang module definition
- `Modules/CoreBluetoothMock.swiftmodule/`: Swift module interfaces

### Sample Apps

- `CoreBluetoothMockSampleApp/`: Swift sample app showing simulator/device conditional import usage
- `CoreBluetoothMockSampleAppObjC/`: Objective-C sample app showing simulator/device conditional import usage
- `CoreBluetoothMockSampleApps.xcworkspace/`: Workspace containing both sample apps
- `LICENCE_SAMPLE_APPS.txt`: License for sample apps (Apache License 2.0)

## Supported Environments

- Xcode 16.0 or later
- Swift / Objective-C
- Simulator iOS 16.0 or later
- [CB Interaction Viewer](https://apps.apple.com/jp/app/cb-interaction-viewer/id6757977616?mt=12) 1.1.2 or later
## Installation

1. Copy `Frameworks/CoreBluetoothMock.framework` from this repository into your app repository (for example, `YourApp/Frameworks/CoreBluetoothMock.framework`).
2. Open your Xcode project and add `CoreBluetoothMock.framework` to your app target's **Frameworks, Libraries, and Embedded Content**.
	- Set **Embed** to **Embed & Sign** for simulator builds.
3. Add the [CoreBluetoothMockDependencies](https://github.com/tochy0115/CoreBluetoothMock_Dependencies.git) package using Swift Package Manager.
4. In your app target, add the package product `CoreBluetoothMock_Dependencies` to **Frameworks, Libraries, and Embedded Content** (or your target's linked frameworks list).
5. Replace CoreBluetooth imports with simulator/device conditional imports:

### Swift
```swift
#if targetEnvironment(simulator)
import CoreBluetoothMock
#else
import CoreBluetooth
#endif
```

### Objective-C
```objc
#if TARGET_OS_SIMULATOR
#import <CoreBluetoothMock/CoreBluetoothMock.h>
#else
#import <CoreBluetooth/CoreBluetooth.h>
#endif
```

6. Launch [CB Interaction Viewer](https://apps.apple.com/jp/app/cb-interaction-viewer/id6757977616?mt=12) on macOS before running your app on the iOS simulator.

## Notes

- Use CoreBluetooth.framework for testing Bluetooth on real devices.
- This is a simulator mock and does not fully replicate real device behavior.
- CoreBluetoothMock will not function correctly on the simulator if [CB Interaction Viewer](https://apps.apple.com/jp/app/cb-interaction-viewer/id6757977616?mt=12) is not running.
- **Modification, reverse engineering, decompilation, or analysis of this framework is prohibited.**

## License

- `CoreBluetoothMock.framework`: Proprietary License (see `LICENCE.txt`)
- Sample apps (`CoreBluetoothMockSampleApp/`, `CoreBluetoothMockSampleAppObjC/`): Apache License 2.0 (see `LICENCE_SAMPLE_APPS.txt`)


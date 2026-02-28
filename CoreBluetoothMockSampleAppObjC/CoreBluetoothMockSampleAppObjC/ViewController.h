//
//  ViewController.h
//  CoreBluetoothMockSampleAppObjC
//
//  Created by Toshinori Matsui on 2025/10/31.
//

#import <UIKit/UIKit.h>

#if TARGET_OS_SIMULATOR
// Use CoreBluetoothMock on Simulator. Install "CB Interaction Viewer" to emulate peripherals from App Store(https://apps.apple.com/jp/app/cb-interaction-viewer/id6757977616?mt=12).
#import <CoreBluetoothMock/CoreBluetoothMock.h>
#else
#import <CoreBluetooth/CoreBluetooth.h>
#endif

@interface ViewController : UIViewController


@end


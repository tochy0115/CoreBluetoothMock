# CoreBluetoothMock (日本語版)

`CoreBluetoothMock.framework` は、iOS シミュレータ上で CoreBluetooth API をモックするためのフレームワークです。  
これを利用することで、iOS シミュレータ上でMac OS上のCoreBluetoothをBLE Sim Linkerを経由してBLE 通信機能の開発・テストが可能になります。

## 特徴

- CoreBluetooth API と互換性のあるインターフェースを提供
- iOS シミュレータ上で BLE デバイスの接続・通信をモック可能
- Swift / Objective-C 両方から利用可能
- BLE Sim Linker を介して macOS の CoreBluetooth を利用することで、より実機に近い挙動を再現

## 対応環境

- Xcode 26.2 以降
- Swift / Objective-C
- iOS シミュレータ (実機では CoreBluetooth.framework を使用)
- macOS 上で BLE Sim Linker が必要（シミュレータ起動前に必須）

## 導入方法

1. このリポジトリから `CoreBluetoothMock.framework` を取得: [https://github.com/tochy0115/CoreBluetoothMock.git](https://github.com/tochy0115/CoreBluetoothMock.git)
2. Xcode プロジェクトの **Frameworks, Libraries, and Embedded Content** に追加
3. CoreBluetoothMockDependencies パッケージを Swift Package Manager で追加することで依存ライブラリも解決可能

## 使用例

### Swift
```swift
#if targetEnvironment(simulator)
import CoreBluetoothMock
#else
import CoreBluetooth
#endif

// CoreBluetooth と同じ API を使用して BLE 処理が可能
```

### Objective-C
```objective-c
#if TARGET_OS_SIMULATOR
#import <CoreBluetoothMock/CoreBluetoothMock.h>
#else
#import <CoreBluetooth/CoreBluetooth.h>
#endif

// CoreBluetooth と同じ API を使用して BLE 処理が可能
```

## 注意点

- 実機での Bluetooth 通信テストには CoreBluetooth.framework を使用してください。
- シミュレータ用のモックであり、全ての実機挙動を再現するわけではありません。
- BLE Sim Linker を起動していない場合、シミュレータ上で CoreBluetoothMockは正常に動作しません。
- **本フレームワークの改ざん、リバースエンジニアリング、逆コンパイル、解析行為は禁止です。**

## ライセンス

独自ライセンス


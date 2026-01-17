# CoreBluetoothMock (日本語版)

`CoreBluetoothMock.framework` は、iOS シミュレータ上で CoreBluetooth API をモックするためのフレームワークです。  
これを利用することで、iOS シミュレータ上でMac OS上のCoreBluetoothをBLE Sim Linkerを経由してBLE 通信機能の開発・テストが可能になります。

## 特徴

- CoreBluetooth API と互換性のあるインターフェースを提供
- iOS シミュレータ上で BLE デバイスの接続・通信をモック可能
- Swift / Objective-C 両方から利用可能
- BLE Sim Linker を介して macOS の CoreBluetooth を利用することで、より実機に近い挙動を再現

## 対応環境

- Xcode 16.0 以降
- Swift / Objective-C
- シミュレータ iOS 16.0 以降
- CoreBluetooth SimLink 1.0 以降

## 導入方法

1. このリポジトリから `CoreBluetoothMock.framework` を取得
2. Xcode プロジェクトの **Frameworks, Libraries, and Embedded Content** に`CoreBluetoothMock.framework` を追加
3. [CoreBluetoothMockDependencies](https://github.com/tochy0115/CoreBluetoothMock_Dependencies.git)パッケージを Swift Package Manager で追加し、CoreBluetoothMockの利用で必要な依存パッケージを追加インストール
4. CoreBluetoothのインポート箇所を以下のように修正
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


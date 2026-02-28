//
//  CBCentralManagerObjCMock.h
//  CoreBluetoothMock
//
//  Created by Toshinori Matsui on 2026/01/09.
//

#import <Foundation/Foundation.h>

//https://developer.apple.com/documentation/corebluetooth/central-manager-initialization-options
extern NSString * const CBCentralManagerOptionShowPowerAlertKey;
extern NSString * const CBCentralManagerOptionRestoreIdentifierKey;
extern NSString * const CBCentralManagerOptionDeviceAccessForMedia;

//https://developer.apple.com/documentation/corebluetooth/central-manager-state-restoration-options
extern NSString * const CBCentralManagerRestoredStatePeripheralsKey;
extern NSString * const CBCentralManagerRestoredStateScanOptionsKey;
extern NSString * const CBCentralManagerRestoredStateScanServicesKey;

//https://developer.apple.com/documentation/corebluetooth/peripheral-scanning-options
extern NSString * const CBCentralManagerScanOptionAllowDuplicatesKey;
extern NSString * const CBCentralManagerScanOptionSolicitedServiceUUIDsKey;

//https://developer.apple.com/documentation/corebluetooth/peripheral-connection-options?language=objc
extern NSString * const  CBConnectPeripheralOptionEnableAutoReconnect;
extern NSString * const  CBConnectPeripheralOptionEnableTransportBridgingKey;
extern NSString * const  CBConnectPeripheralOptionNotifyOnConnectionKey;
extern NSString * const  CBConnectPeripheralOptionNotifyOnDisconnectionKey;
extern NSString * const  CBConnectPeripheralOptionNotifyOnNotificationKey;
extern NSString * const  CBConnectPeripheralOptionRequiresANCS;
extern NSString * const  CBConnectPeripheralOptionStartDelayKey;

//https://developer.apple.com/documentation/corebluetooth/advertisement-data-retrieval-keys
extern NSString * const CBAdvertisementDataLocalNameKey;
extern NSString * const CBAdvertisementDataManufacturerDataKey;
extern NSString * const CBAdvertisementDataServiceDataKey;
extern NSString * const CBAdvertisementDataServiceUUIDsKey;
extern NSString * const CBAdvertisementDataOverflowServiceUUIDsKey;
extern NSString * const CBAdvertisementDataTxPowerLevelKey;
extern NSString * const CBAdvertisementDataIsConnectable;
extern NSString * const CBAdvertisementDataSolicitedServiceUUIDsKey;

//https://developer.apple.com/documentation/corebluetooth/cbcentralmanager/feature?language=objc
typedef NS_OPTIONS(NSUInteger, CBCentralManagerFeature) {
    CBCentralManagerFeatureExtendedScanAndConnect = 0x01
};

//
//  CBCharacteristicObjCMock.h
//  CoreBluetoothMock
//
//  Created by Toshinori Matsui on 2026/01/08.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
    CBCharacteristicPropertyBroadcast                                                = 0x01,
    CBCharacteristicPropertyRead                                                    = 0x02,
    CBCharacteristicPropertyWriteWithoutResponse                                    = 0x04,
    CBCharacteristicPropertyWrite                                                    = 0x08,
    CBCharacteristicPropertyNotify                                                    = 0x10,
    CBCharacteristicPropertyIndicate                                                = 0x20,
    CBCharacteristicPropertyAuthenticatedSignedWrites                                = 0x40,
    CBCharacteristicPropertyExtendedProperties                                        = 0x80,
    CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(10_9, 6_0)    = 0x100,
    CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(10_9, 6_0)    = 0x200
};


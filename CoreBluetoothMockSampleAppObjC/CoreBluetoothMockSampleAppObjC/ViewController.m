//
//  ViewController.m
//  CoreBluetoothMockSampleAppObjC
//
//  Created by Toshinori Matsui on 2025/10/31.
//

#import "ViewController.h"

static NSString *BLEObjectKey(id object) {
    // Use object identity as a dictionary key to map CoreBluetooth objects back to UI IDs.
    return [NSString stringWithFormat:@"%p", object];
}

static NSData *BLEHexDecode(NSString *text) {
    if (text == nil) {
        return [NSData data];
    }

    NSCharacterSet *trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [text stringByTrimmingCharactersInSet:trimSet];
    NSArray<NSString *> *parts = [trimmed componentsSeparatedByCharactersInSet:trimSet];
    NSString *cleaned = [[parts componentsJoinedByString:@""] uppercaseString];

    if (cleaned.length == 0 || cleaned.length % 2 != 0) {
        return [NSData data];
    }

    NSMutableData *data = [NSMutableData dataWithCapacity:cleaned.length / 2];
    for (NSUInteger index = 0; index < cleaned.length; index += 2) {
        NSString *chunk = [cleaned substringWithRange:NSMakeRange(index, 2)];
        unsigned int value = 0;
        NSScanner *scanner = [NSScanner scannerWithString:chunk];
        if (![scanner scanHexInt:&value]) {
            return [NSData data];
        }
        uint8_t byte = (uint8_t)value;
        [data appendBytes:&byte length:1];
    }
    return data;
}

static NSString *BLEHexEncode(NSData *data) {
    if (data == nil || data.length == 0) {
        return @"";
    }

    const unsigned char *bytes = data.bytes;
    NSMutableString *text = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger index = 0; index < data.length; index++) {
        [text appendFormat:@"%02X", bytes[index]];
    }
    return text;
}

static NSString *BLECharacteristicPropertiesDescription(CBCharacteristicProperties properties) {
    NSMutableArray<NSString *> *labels = [NSMutableArray array];
    if ((properties & CBCharacteristicPropertyBroadcast) != 0) {
        [labels addObject:@"broadcast"];
    }
    if ((properties & CBCharacteristicPropertyRead) != 0) {
        [labels addObject:@"read"];
    }
    if ((properties & CBCharacteristicPropertyWriteWithoutResponse) != 0) {
        [labels addObject:@"writeWithoutResponse"];
    }
    if ((properties & CBCharacteristicPropertyWrite) != 0) {
        [labels addObject:@"write"];
    }
    if ((properties & CBCharacteristicPropertyNotify) != 0) {
        [labels addObject:@"notify"];
    }
    if ((properties & CBCharacteristicPropertyIndicate) != 0) {
        [labels addObject:@"indicate"];
    }
    if ((properties & CBCharacteristicPropertyAuthenticatedSignedWrites) != 0) {
        [labels addObject:@"authenticatedSignedWrites"];
    }
    if ((properties & CBCharacteristicPropertyExtendedProperties) != 0) {
        [labels addObject:@"extendedProperties"];
    }
    if ((properties & CBCharacteristicPropertyNotifyEncryptionRequired) != 0) {
        [labels addObject:@"notifyEncryptionRequired"];
    }
    if ((properties & CBCharacteristicPropertyIndicateEncryptionRequired) != 0) {
        [labels addObject:@"indicateEncryptionRequired"];
    }

    if (labels.count == 0) {
        return @"none";
    }
    return [labels componentsJoinedByString:@" | "];
}

@interface BLEDescriptorViewModel : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *uuid;
@end

@implementation BLEDescriptorViewModel
@end

@interface BLECharacteristicViewModel : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *propertiesDescription;
@property (nonatomic, assign) BOOL canRead;
@property (nonatomic, assign) BOOL canWrite;
@property (nonatomic, assign) BOOL canNotify;
@property (nonatomic, strong) NSArray<BLEDescriptorViewModel *> *descriptors;
@end

@implementation BLECharacteristicViewModel
@end

@interface BLEServiceViewModel : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, strong) NSArray<BLECharacteristicViewModel *> *characteristics;
@end

@implementation BLEServiceViewModel
@end

@interface BLEIDButton : UIButton
@property (nonatomic, copy) NSString *itemID;
@property (nonatomic, copy) void (^tapHandler)(NSString *itemID);
@end

@implementation BLEIDButton

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self addTarget:self action:@selector(onTap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)onTap {
    if (self.tapHandler != nil) {
        self.tapHandler(self.itemID ?: @"");
    }
}

@end

@interface BLEIDTextField : UITextField
@property (nonatomic, copy) NSString *itemID;
@property (nonatomic, copy) void (^changeHandler)(NSString *itemID, NSString *value);
@end

@implementation BLEIDTextField

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self addTarget:self action:@selector(onChange) forControlEvents:UIControlEventEditingChanged];
    }
    return self;
}

- (void)onChange {
    if (self.changeHandler != nil) {
        self.changeHandler(self.itemID ?: @"", self.text ?: @"");
    }
}

@end

@interface BLECharacteristicCell : UITableViewCell
- (void)configureWithCharacteristic:(BLECharacteristicViewModel *)characteristic
                  characteristicHex:(NSString *)characteristicHex
                        isNotifying:(BOOL)isNotifying
                descriptorHexInputs:(NSDictionary<NSString *, NSString *> *)descriptorHexInputs
                             onRead:(void (^)(void))onRead
                            onWrite:(void (^)(void))onWrite
                      onNotifyToggle:(void (^)(void))onNotifyToggle
                  onCharacteristicInput:(void (^)(NSString *value))onCharacteristicInput
                   onDescriptorInput:(void (^)(NSString *descriptorID, NSString *value))onDescriptorInput
                    onDescriptorRead:(void (^)(NSString *descriptorID))onDescriptorRead
                   onDescriptorWrite:(void (^)(NSString *descriptorID))onDescriptorWrite;
@end

@interface BLECharacteristicCell ()
@property (nonatomic, strong) UILabel *characteristicLabel;
@property (nonatomic, strong) UILabel *propertiesLabel;
@property (nonatomic, strong) UIStackView *buttonStack;
@property (nonatomic, strong) UIButton *readButton;
@property (nonatomic, strong) UIButton *writeButton;
@property (nonatomic, strong) UIButton *notifyButton;
@property (nonatomic, strong) BLEIDTextField *characteristicInput;
@property (nonatomic, strong) UIStackView *descriptorStack;
@property (nonatomic, copy) void (^onRead)(void);
@property (nonatomic, copy) void (^onWrite)(void);
@property (nonatomic, copy) void (^onNotifyToggle)(void);
@property (nonatomic, copy) void (^onCharacteristicInput)(NSString *value);
@property (nonatomic, copy) void (^onDescriptorInput)(NSString *descriptorID, NSString *value);
@property (nonatomic, copy) void (^onDescriptorRead)(NSString *descriptorID);
@property (nonatomic, copy) void (^onDescriptorWrite)(NSString *descriptorID);
@end

@implementation BLECharacteristicCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    UIStackView *container = [[UIStackView alloc] init];
    container.axis = UILayoutConstraintAxisVertical;
    container.spacing = 8;
    container.translatesAutoresizingMaskIntoConstraints = NO;

    self.characteristicLabel = [[UILabel alloc] init];
    self.characteristicLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.characteristicLabel.numberOfLines = 0;

    self.propertiesLabel = [[UILabel alloc] init];
    self.propertiesLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.propertiesLabel.textColor = UIColor.secondaryLabelColor;
    self.propertiesLabel.numberOfLines = 0;

    self.buttonStack = [[UIStackView alloc] init];
    self.buttonStack.axis = UILayoutConstraintAxisHorizontal;
    self.buttonStack.spacing = 8;
    self.buttonStack.alignment = UIStackViewAlignmentLeading;

    self.readButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.readButton setTitle:@"READ" forState:UIControlStateNormal];
    [self.readButton addTarget:self action:@selector(onTapRead) forControlEvents:UIControlEventTouchUpInside];

    self.writeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.writeButton setTitle:@"WRITE" forState:UIControlStateNormal];
    [self.writeButton addTarget:self action:@selector(onTapWrite) forControlEvents:UIControlEventTouchUpInside];

    self.notifyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.notifyButton addTarget:self action:@selector(onTapNotify) forControlEvents:UIControlEventTouchUpInside];

    [self.buttonStack addArrangedSubview:self.readButton];
    [self.buttonStack addArrangedSubview:self.writeButton];
    [self.buttonStack addArrangedSubview:self.notifyButton];

    self.characteristicInput = [[BLEIDTextField alloc] init];
    self.characteristicInput.borderStyle = UITextBorderStyleRoundedRect;
    self.characteristicInput.autocorrectionType = UITextAutocorrectionTypeNo;
    self.characteristicInput.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.characteristicInput.placeholder = @"Value (HEX)";
    __weak typeof(self) weakSelf = self;
    self.characteristicInput.changeHandler = ^(NSString *itemID, NSString *value) {
        if (weakSelf.onCharacteristicInput != nil) {
            weakSelf.onCharacteristicInput(value);
        }
    };

    self.descriptorStack = [[UIStackView alloc] init];
    self.descriptorStack.axis = UILayoutConstraintAxisVertical;
    self.descriptorStack.spacing = 8;

    [container addArrangedSubview:self.characteristicLabel];
    [container addArrangedSubview:self.propertiesLabel];
    [container addArrangedSubview:self.buttonStack];
    [container addArrangedSubview:self.characteristicInput];
    [container addArrangedSubview:self.descriptorStack];

    [self.contentView addSubview:container];
    [NSLayoutConstraint activateConstraints:@[
        [container.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
        [container.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [container.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [container.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8]
    ]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *view in [self.descriptorStack.arrangedSubviews copy]) {
        [self.descriptorStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    self.onRead = nil;
    self.onWrite = nil;
    self.onNotifyToggle = nil;
    self.onCharacteristicInput = nil;
    self.onDescriptorInput = nil;
    self.onDescriptorRead = nil;
    self.onDescriptorWrite = nil;
}

- (void)configureWithCharacteristic:(BLECharacteristicViewModel *)characteristic
                  characteristicHex:(NSString *)characteristicHex
                        isNotifying:(BOOL)isNotifying
                descriptorHexInputs:(NSDictionary<NSString *,NSString *> *)descriptorHexInputs
                             onRead:(void (^)(void))onRead
                            onWrite:(void (^)(void))onWrite
                      onNotifyToggle:(void (^)(void))onNotifyToggle
                  onCharacteristicInput:(void (^)(NSString *))onCharacteristicInput
                   onDescriptorInput:(void (^)(NSString *, NSString *))onDescriptorInput
                    onDescriptorRead:(void (^)(NSString *))onDescriptorRead
                   onDescriptorWrite:(void (^)(NSString *))onDescriptorWrite {
    self.onRead = onRead;
    self.onWrite = onWrite;
    self.onNotifyToggle = onNotifyToggle;
    self.onCharacteristicInput = onCharacteristicInput;
    self.onDescriptorInput = onDescriptorInput;
    self.onDescriptorRead = onDescriptorRead;
    self.onDescriptorWrite = onDescriptorWrite;

    self.characteristicLabel.text = [NSString stringWithFormat:@"Characteristic: %@", characteristic.uuid];
    self.propertiesLabel.text = [NSString stringWithFormat:@"Properties: %@", characteristic.propertiesDescription];

    self.readButton.hidden = !characteristic.canRead;
    self.writeButton.hidden = !characteristic.canWrite;
    self.notifyButton.hidden = !characteristic.canNotify;
    [self.notifyButton setTitle:(isNotifying ? @"NOTIFY OFF" : @"NOTIFY ON") forState:UIControlStateNormal];

    self.characteristicInput.text = characteristicHex ?: @"";

    for (UIView *view in [self.descriptorStack.arrangedSubviews copy]) {
        [self.descriptorStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    for (BLEDescriptorViewModel *descriptor in characteristic.descriptors) {
        UIView *panel = [[UIView alloc] init];
        panel.backgroundColor = [UIColor.secondarySystemBackgroundColor colorWithAlphaComponent:0.7];
        panel.layer.cornerRadius = 8;

        UIStackView *panelStack = [[UIStackView alloc] init];
        panelStack.axis = UILayoutConstraintAxisVertical;
        panelStack.spacing = 6;
        panelStack.translatesAutoresizingMaskIntoConstraints = NO;

        UILabel *descriptorLabel = [[UILabel alloc] init];
        descriptorLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        descriptorLabel.textColor = UIColor.secondaryLabelColor;
        descriptorLabel.numberOfLines = 0;
        descriptorLabel.text = [NSString stringWithFormat:@"Descriptor: %@", descriptor.uuid];

        UIStackView *descriptorButtonStack = [[UIStackView alloc] init];
        descriptorButtonStack.axis = UILayoutConstraintAxisHorizontal;
        descriptorButtonStack.spacing = 8;
        descriptorButtonStack.alignment = UIStackViewAlignmentLeading;

        BLEIDButton *readButton = [[BLEIDButton alloc] init];
        [readButton setTitle:@"D-READ" forState:UIControlStateNormal];
        readButton.itemID = descriptor.identifier;
        __weak typeof(self) weakSelf = self;
        readButton.tapHandler = ^(NSString *itemID) {
            if (weakSelf.onDescriptorRead != nil) {
                weakSelf.onDescriptorRead(itemID);
            }
        };

        BLEIDButton *writeButton = [[BLEIDButton alloc] init];
        [writeButton setTitle:@"D-WRITE" forState:UIControlStateNormal];
        writeButton.itemID = descriptor.identifier;
        writeButton.tapHandler = ^(NSString *itemID) {
            if (weakSelf.onDescriptorWrite != nil) {
                weakSelf.onDescriptorWrite(itemID);
            }
        };

        [descriptorButtonStack addArrangedSubview:readButton];
        [descriptorButtonStack addArrangedSubview:writeButton];

        BLEIDTextField *descriptorInput = [[BLEIDTextField alloc] init];
        descriptorInput.borderStyle = UITextBorderStyleRoundedRect;
        descriptorInput.autocorrectionType = UITextAutocorrectionTypeNo;
        descriptorInput.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        descriptorInput.placeholder = @"Descriptor Value (HEX)";
        descriptorInput.itemID = descriptor.identifier;
        descriptorInput.text = descriptorHexInputs[descriptor.identifier] ?: @"";
        descriptorInput.changeHandler = ^(NSString *itemID, NSString *value) {
            if (weakSelf.onDescriptorInput != nil) {
                weakSelf.onDescriptorInput(itemID, value);
            }
        };

        [panelStack addArrangedSubview:descriptorLabel];
        [panelStack addArrangedSubview:descriptorButtonStack];
        [panelStack addArrangedSubview:descriptorInput];

        [panel addSubview:panelStack];
        [NSLayoutConstraint activateConstraints:@[
            [panelStack.topAnchor constraintEqualToAnchor:panel.topAnchor constant:8],
            [panelStack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:8],
            [panelStack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-8],
            [panelStack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-8]
        ]];

        [self.descriptorStack addArrangedSubview:panel];
    }
}

- (void)onTapRead {
    if (self.onRead != nil) {
        self.onRead();
    }
}

- (void)onTapWrite {
    if (self.onWrite != nil) {
        self.onWrite();
    }
}

- (void)onTapNotify {
    if (self.onNotifyToggle != nil) {
        self.onNotifyToggle();
    }
}

@end

@interface BLEDeviceViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, CBPeripheralDelegate>
- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager
                            peripheral:(CBPeripheral *)peripheral
                         deviceAddress:(NSString *)deviceAddress;
- (NSUUID *)currentPeripheralIdentifier;
@property (nonatomic, copy) void (^onDisconnectDetected)(CBPeripheral *peripheral);
@end

@interface BLEDeviceViewController ()
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, copy) NSString *deviceAddress;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<BLEServiceViewModel *> *services;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CBCharacteristic *> *characteristicMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *characteristicIDByObjectKey;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CBDescriptor *> *descriptorMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *descriptorIDByObjectKey;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *characteristicHexInputs;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *descriptorHexInputs;
@end

@implementation BLEDeviceViewController

- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager
                            peripheral:(CBPeripheral *)peripheral
                         deviceAddress:(NSString *)deviceAddress {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _centralManager = centralManager;
        _peripheral = peripheral;
        _deviceAddress = [deviceAddress copy];
        _services = @[];
        _characteristicMap = [NSMutableDictionary dictionary];
        _characteristicIDByObjectKey = [NSMutableDictionary dictionary];
        _descriptorMap = [NSMutableDictionary dictionary];
        _descriptorIDByObjectKey = [NSMutableDictionary dictionary];
        _characteristicHexInputs = [NSMutableDictionary dictionary];
        _descriptorHexInputs = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.title = self.deviceAddress;

    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"←"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(onBackTapped)];
    UIBarButtonItem *disconnectButton = [[UIBarButtonItem alloc] initWithTitle:@"Disconnect"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(onDisconnectTapped)];
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithTitle:@"Refresh"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(onRefreshTapped)];
    self.navigationItem.rightBarButtonItems = @[disconnectButton, refreshButton];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.hidden = YES;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 220;
    [self.tableView registerClass:[BLECharacteristicCell class] forCellReuseIdentifier:@"CharacteristicCell"];

    [stack addArrangedSubview:self.statusLabel];
    [stack addArrangedSubview:self.tableView];

    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    self.peripheral.delegate = self;
    [self.peripheral discoverServices:nil];
}

- (void)setStatusText:(NSString *)statusText {
    self.statusLabel.text = statusText;
    self.statusLabel.hidden = (statusText.length == 0);
}

- (void)onBackTapped {
    [self.centralManager cancelPeripheralConnection:self.peripheral];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onDisconnectTapped {
    [self.centralManager cancelPeripheralConnection:self.peripheral];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onRefreshTapped {
    [self.peripheral discoverServices:nil];
}

- (void)mapServices {
    NSArray<CBService *> *cbServices = self.peripheral.services ?: @[];

    [self.characteristicMap removeAllObjects];
    [self.characteristicIDByObjectKey removeAllObjects];
    [self.descriptorMap removeAllObjects];
    [self.descriptorIDByObjectKey removeAllObjects];

    NSMutableArray<BLEServiceViewModel *> *uiServices = [NSMutableArray arrayWithCapacity:cbServices.count];

    // Build view models and keep lookup maps so UI events can resolve to CB objects.
    [cbServices enumerateObjectsUsingBlock:^(CBService * _Nonnull service, NSUInteger serviceIndex, BOOL * _Nonnull stop) {
        NSMutableArray<BLECharacteristicViewModel *> *uiCharacteristics = [NSMutableArray array];

        NSArray<CBCharacteristic *> *characteristics = service.characteristics ?: @[];
        [characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull characteristic, NSUInteger characteristicIndex, BOOL * _Nonnull stop2) {
            BLECharacteristicViewModel *characteristicVM = [[BLECharacteristicViewModel alloc] init];
            characteristicVM.identifier = [NSString stringWithFormat:@"s%lu-c%lu-%@", (unsigned long)serviceIndex, (unsigned long)characteristicIndex, characteristic.UUID.UUIDString];
            characteristicVM.uuid = characteristic.UUID.UUIDString;
            characteristicVM.propertiesDescription = BLECharacteristicPropertiesDescription(characteristic.properties);
            characteristicVM.canRead = (characteristic.properties & CBCharacteristicPropertyRead) != 0;
            characteristicVM.canWrite = (characteristic.properties & CBCharacteristicPropertyWrite) != 0 ||
                                        (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) != 0;
            characteristicVM.canNotify = (characteristic.properties & CBCharacteristicPropertyNotify) != 0 ||
                                         (characteristic.properties & CBCharacteristicPropertyIndicate) != 0;

            self.characteristicMap[characteristicVM.identifier] = characteristic;
            self.characteristicIDByObjectKey[BLEObjectKey(characteristic)] = characteristicVM.identifier;

            NSMutableArray<BLEDescriptorViewModel *> *uiDescriptors = [NSMutableArray array];
            NSArray<CBDescriptor *> *descriptors = characteristic.descriptors ?: @[];
            [descriptors enumerateObjectsUsingBlock:^(CBDescriptor * _Nonnull descriptor, NSUInteger descriptorIndex, BOOL * _Nonnull stop3) {
                BLEDescriptorViewModel *descriptorVM = [[BLEDescriptorViewModel alloc] init];
                descriptorVM.identifier = [NSString stringWithFormat:@"%@-d%lu-%@", characteristicVM.identifier, (unsigned long)descriptorIndex, descriptor.UUID.UUIDString];
                descriptorVM.uuid = descriptor.UUID.UUIDString;
                [uiDescriptors addObject:descriptorVM];

                self.descriptorMap[descriptorVM.identifier] = descriptor;
                self.descriptorIDByObjectKey[BLEObjectKey(descriptor)] = descriptorVM.identifier;
            }];

            characteristicVM.descriptors = uiDescriptors;
            [uiCharacteristics addObject:characteristicVM];
        }];

        BLEServiceViewModel *serviceVM = [[BLEServiceViewModel alloc] init];
        serviceVM.identifier = [NSString stringWithFormat:@"s%lu-%@", (unsigned long)serviceIndex, service.UUID.UUIDString];
        serviceVM.uuid = service.UUID.UUIDString;
        serviceVM.characteristics = uiCharacteristics;
        [uiServices addObject:serviceVM];
    }];

    self.services = uiServices;
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.services.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.services[section].characteristics.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    BLEServiceViewModel *service = self.services[section];
    return [NSString stringWithFormat:@"Service: %@", service.uuid];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BLECharacteristicCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CharacteristicCell" forIndexPath:indexPath];
    BLEServiceViewModel *service = self.services[indexPath.section];
    BLECharacteristicViewModel *characteristic = service.characteristics[indexPath.row];
    CBCharacteristic *cbCharacteristic = self.characteristicMap[characteristic.identifier];

    NSString *hexText = self.characteristicHexInputs[characteristic.identifier] ?: @"";
    __weak typeof(self) weakSelf = self;
    [cell configureWithCharacteristic:characteristic
                    characteristicHex:hexText
                          isNotifying:cbCharacteristic.isNotifying
                  descriptorHexInputs:self.descriptorHexInputs
                               onRead:^{
                                   [weakSelf readCharacteristic:characteristic.identifier];
                               }
                              onWrite:^{
                                  [weakSelf writeCharacteristic:characteristic.identifier];
                              }
                        onNotifyToggle:^{
                            [weakSelf toggleNotify:characteristic.identifier];
                        }
                    onCharacteristicInput:^(NSString *value) {
                        weakSelf.characteristicHexInputs[characteristic.identifier] = value ?: @"";
                    }
                     onDescriptorInput:^(NSString *descriptorID, NSString *value) {
                         weakSelf.descriptorHexInputs[descriptorID] = value ?: @"";
                     }
                      onDescriptorRead:^(NSString *descriptorID) {
                          [weakSelf readDescriptor:descriptorID];
                      }
                     onDescriptorWrite:^(NSString *descriptorID) {
                         [weakSelf writeDescriptor:descriptorID];
                     }];
    return cell;
}

- (void)readCharacteristic:(NSString *)characteristicID {
    CBCharacteristic *characteristic = self.characteristicMap[characteristicID];
    if (characteristic == nil) {
        return;
    }
    [self.peripheral readValueForCharacteristic:characteristic];
}

- (void)writeCharacteristic:(NSString *)characteristicID {
    CBCharacteristic *characteristic = self.characteristicMap[characteristicID];
    if (characteristic == nil) {
        return;
    }

    NSString *input = self.characteristicHexInputs[characteristicID] ?: @"";
    NSData *data = BLEHexDecode(input);
    if ((characteristic.properties & CBCharacteristicPropertyWrite) != 0) {
        [self.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    } else if ((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) != 0) {
        [self.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (void)toggleNotify:(NSString *)characteristicID {
    CBCharacteristic *characteristic = self.characteristicMap[characteristicID];
    if (characteristic == nil) {
        return;
    }
    [self.peripheral setNotifyValue:!characteristic.isNotifying forCharacteristic:characteristic];
}

- (void)readDescriptor:(NSString *)descriptorID {
    CBDescriptor *descriptor = self.descriptorMap[descriptorID];
    if (descriptor == nil) {
        return;
    }
    [self.peripheral readValueForDescriptor:descriptor];
}

- (void)writeDescriptor:(NSString *)descriptorID {
    CBDescriptor *descriptor = self.descriptorMap[descriptorID];
    if (descriptor == nil) {
        return;
    }

    NSString *input = self.descriptorHexInputs[descriptorID] ?: @"";
    NSData *data = BLEHexDecode(input);
    [self.peripheral writeValue:data forDescriptor:descriptor];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            [self setStatusText:@"Service discovery failed"];
            return;
        }

        // Service discovery is the first step. Next, discover characteristics per service.
        for (CBService *service in peripheral.services ?: @[]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
        [self mapServices];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            [self setStatusText:@"Characteristic discovery failed"];
            return;
        }

        // After characteristics are available, request descriptors for each one.
        for (CBCharacteristic *characteristic in service.characteristics ?: @[]) {
            [peripheral discoverDescriptorsForCharacteristic:characteristic];
        }
        [self mapServices];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            [self setStatusText:@"Descriptor discovery failed"];
            return;
        }
        [self mapServices];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            [self setStatusText:@"Characteristic read failed"];
            return;
        }

        NSString *identifier = self.characteristicIDByObjectKey[BLEObjectKey(characteristic)];
        if (identifier != nil) {
            self.characteristicHexInputs[identifier] = BLEHexEncode(characteristic.value);
            [self.tableView reloadData];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            [self setStatusText:@"Characteristic write failed"];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            [self setStatusText:@"Notify update failed"];
        } else {
            [self.tableView reloadData];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            [self setStatusText:@"Descriptor read failed"];
            return;
        }

        NSString *identifier = self.descriptorIDByObjectKey[BLEObjectKey(descriptor)];
        if (identifier == nil) {
            return;
        }

        if ([descriptor.value isKindOfClass:[NSData class]]) {
            self.descriptorHexInputs[identifier] = BLEHexEncode((NSData *)descriptor.value);
        } else if ([descriptor.value isKindOfClass:[NSNumber class]]) {
            uint8_t byteValue = (uint8_t)MAX(0, MIN(255, ((NSNumber *)descriptor.value).intValue));
            NSData *data = [NSData dataWithBytes:&byteValue length:1];
            self.descriptorHexInputs[identifier] = BLEHexEncode(data);
        } else if ([descriptor.value isKindOfClass:[NSString class]]) {
            NSData *data = [((NSString *)descriptor.value) dataUsingEncoding:NSUTF8StringEncoding];
            self.descriptorHexInputs[identifier] = BLEHexEncode(data);
        } else {
            self.descriptorHexInputs[identifier] = @"";
        }
        [self.tableView reloadData];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            [self setStatusText:@"Descriptor write failed"];
        }
    });
}

- (NSUUID *)currentPeripheralIdentifier {
    return self.peripheral.identifier;
}

@end

@interface ViewController () <CBCentralManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, assign) BOOL scanning;
@property (nonatomic, strong) UIButton *scanButton;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableDictionary<NSUUID *, CBPeripheral *> *discoveredPeripheralMap;
@property (nonatomic, strong) NSMutableDictionary<NSUUID *, NSNumber *> *discoveredRSSIMap;
@property (nonatomic, strong) NSArray<NSUUID *> *discoveredDeviceIDs;
@property (nonatomic, copy) NSString *pendingDeviceAddress;
@end

@implementation ViewController

- (NSString *)stateTextForManagerState:(CBManagerState)state {
    switch (state) {
        case CBManagerStateUnknown:
            return @"Bluetooth state: unknown";
        case CBManagerStateResetting:
            return @"Bluetooth state: resetting";
        case CBManagerStateUnsupported:
            return @"Bluetooth state: unsupported";
        case CBManagerStateUnauthorized:
            return @"Bluetooth state: unauthorized";
        case CBManagerStatePoweredOff:
            return @"Bluetooth state: poweredOff";
        case CBManagerStatePoweredOn:
            return @"Bluetooth state: poweredOn";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.title = @"BLE Scan";

    self.discoveredPeripheralMap = [NSMutableDictionary dictionary];
    self.discoveredRSSIMap = [NSMutableDictionary dictionary];
    self.discoveredDeviceIDs = @[];

    self.scanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.scanButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.scanButton.backgroundColor = UIColor.systemBlueColor;
    self.scanButton.layer.cornerRadius = 10;
    self.scanButton.contentEdgeInsets = UIEdgeInsetsMake(10, 16, 10, 16);
    [self.scanButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.scanButton addTarget:self action:@selector(toggleScan) forControlEvents:UIControlEventTouchUpInside];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.hidden = YES;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ScanCell"];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [stack addArrangedSubview:self.scanButton];
    [stack addArrangedSubview:self.statusLabel];
    [stack addArrangedSubview:self.tableView];

    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    [self updateScanButtonTitle];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    self.centralManager.delegate = self;
    [self setStatusText:[self stateTextForManagerState:self.centralManager.state]];
}

- (void)setStatusText:(NSString *)statusText {
    self.statusLabel.text = statusText;
    self.statusLabel.hidden = (statusText.length == 0);
}

- (void)updateScanButtonTitle {
    [self.scanButton setTitle:(self.scanning ? @"Stop Scan" : @"Start Scan") forState:UIControlStateNormal];
}

- (void)toggleScan {
    if (self.scanning) {
        [self stopScan];
    } else {
        [self startScan];
    }
}

- (void)startScan {
    if (self.centralManager.state != CBManagerStatePoweredOn) {
        [self setStatusText:@"Bluetooth is not powered on"];
        return;
    }

    [self.discoveredPeripheralMap removeAllObjects];
    [self.discoveredRSSIMap removeAllObjects];
    self.discoveredDeviceIDs = @[];
    [self.tableView reloadData];

    // `services:nil` scans for all advertising peripherals.
    [self.centralManager scanForPeripheralsWithServices:nil
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey: @NO }];
    self.scanning = YES;
    [self updateScanButtonTitle];
}

- (void)stopScan {
    [self.centralManager stopScan];
    self.scanning = NO;
    [self updateScanButtonTitle];
}

- (void)updateDiscoveredDeviceList {
    NSArray<NSUUID *> *allKeys = self.discoveredPeripheralMap.allKeys;
    self.discoveredDeviceIDs = [allKeys sortedArrayUsingComparator:^NSComparisonResult(NSUUID * _Nonnull a, NSUUID * _Nonnull b) {
        return [a.UUIDString compare:b.UUIDString options:NSCaseInsensitiveSearch];
    }];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.discoveredDeviceIDs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ScanCell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    NSUUID *deviceID = self.discoveredDeviceIDs[indexPath.row];
    CBPeripheral *peripheral = self.discoveredPeripheralMap[deviceID];
    NSString *name = (peripheral.name.length > 0) ? peripheral.name : @"(no name)";
    NSInteger rssi = self.discoveredRSSIMap[deviceID].integerValue;

    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.textLabel.text = [NSString stringWithFormat:@"%@\n%@\nRSSI: %ld", name, deviceID.UUIDString, (long)rssi];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.centralManager.state != CBManagerStatePoweredOn) {
        [self setStatusText:@"Bluetooth is not powered on"];
        return;
    }

    NSUUID *deviceID = self.discoveredDeviceIDs[indexPath.row];
    CBPeripheral *peripheral = self.discoveredPeripheralMap[deviceID];
    if (peripheral == nil) {
        [self setStatusText:@"Device not found"];
        return;
    }

    [self stopScan];
    [self setStatusText:@"Connecting..."];
    self.pendingDeviceAddress = deviceID.UUIDString;
    [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    [self setStatusText:[self stateTextForManagerState:central.state]];
    if (central.state != CBManagerStatePoweredOn) {
        [self stopScan];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.discoveredPeripheralMap[peripheral.identifier] = peripheral;
        self.discoveredRSSIMap[peripheral.identifier] = RSSI;
        [self updateDiscoveredDeviceList];
    });
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setStatusText:@"Connected"];
        BLEDeviceViewController *deviceVC = [[BLEDeviceViewController alloc] initWithCentralManager:self.centralManager
                                                                                          peripheral:peripheral
                                                                                       deviceAddress:self.pendingDeviceAddress ?: peripheral.identifier.UUIDString];
        [self.navigationController pushViewController:deviceVC animated:YES];
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setStatusText:@"Disconnected"];
        UIViewController *top = self.navigationController.topViewController;
        if ([top isKindOfClass:[BLEDeviceViewController class]]) {
            BLEDeviceViewController *deviceVC = (BLEDeviceViewController *)top;
            if ([[deviceVC currentPeripheralIdentifier] isEqual:peripheral.identifier]) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    });
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setStatusText:@"Connection failed"];
    });
}

@end

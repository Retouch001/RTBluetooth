//
//  RTHBluetooth.m
//  RidingPack
//
//  Created by Tang Retouch on 2018/2/7.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import "RTHBluetooth.h"

static const NSInteger RT_CENTRAL_MANAGER_INIT_WAIT_TIMES = 5;//CBcentralManager等待设备打开次数
static const CGFloat RT_CENTRAL_MANAGER_INIT_WAIT_SECOND = 2.0;//CBcentralManager等待设备打开间隔时间

@implementation RTHBluetooth{
    int CENTRAL_MANAGER_INIT_WAIT_TIMES;
    NSTimer *connectTimer;
}

- (instancetype)init{
    if (self = [super init]) {
        NSDictionary *dic = @{CBCentralManagerOptionShowPowerAlertKey : @YES,
                              CBCentralManagerOptionRestoreIdentifierKey : @"rthBluetooth"
                              };
        NSArray *backgroundModes = [[[NSBundle mainBundle] infoDictionary]objectForKey:@"UIBackgroundModes"];
        if ([backgroundModes containsObject:@"bluetooth-central"]) {
            _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:dic];
        }else{
            _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        }
        _connectedPeripherals = [NSMutableArray array];
        _discoverPeripherals = [NSMutableArray array];
        _reConnectPeripherals = [NSMutableArray array];
    }
    return self;
}

+ (RTHBluetooth *)shareInstance{
    static RTHBluetooth *share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[self alloc] init];
    });
    return share;
}


#pragma mark =============工具方法================
- (void)scanPeripherals{
    BLELog(@">>> 第%d次等待CBCentralManager打开。",CENTRAL_MANAGER_INIT_WAIT_TIMES);
    //不重复扫描已发现设备
    NSDictionary *option = @{CBCentralManagerScanOptionAllowDuplicatesKey : @NO,
                             CBCentralManagerOptionShowPowerAlertKey:@YES
                             };
    if (_centralManager.state == CBCentralManagerStatePoweredOn) {
        CENTRAL_MANAGER_INIT_WAIT_TIMES = 0;
        [_centralManager scanForPeripheralsWithServices:nil options:option];
        return;
    }
    //尝试重新等待CBCentralManager打开
    CENTRAL_MANAGER_INIT_WAIT_TIMES ++;
    if (CENTRAL_MANAGER_INIT_WAIT_TIMES >= RT_CENTRAL_MANAGER_INIT_WAIT_TIMES ) {
        BLELog(@">>> 第%d次等待CBCentralManager 打开任然失败，请检查你蓝牙使用权限或检查设备问题。",CENTRAL_MANAGER_INIT_WAIT_TIMES);
        return;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, RT_CENTRAL_MANAGER_INIT_WAIT_SECOND * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self scanPeripherals];
    });
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral{
    [_centralManager connectPeripheral:peripheral options:nil];
}

- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral{
    [_centralManager cancelPeripheralConnection:peripheral];
}

- (void)cancelAllPeripheralsConnection {
    for (int i=0;i< _connectedPeripherals.count;i++) {
        [_centralManager cancelPeripheralConnection:_connectedPeripherals[i]];
    }
}

- (void)cancelScan{
    [_centralManager stopScan];
}






#pragma mark ----------------------CBCentralManagerDelegate------------------
//中心设备的蓝牙状态发生变化
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            BLELog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            BLELog(@">>>CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            BLELog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            BLELog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            BLELog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
            BLELog(@">>>CBCentralManagerStatePoweredOn");
            [self scanPeripherals];
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict{
    
}

//发现了外设
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    
    if ([self.delegate respondsToSelector:@selector(filterOnDiscoverPeripherals:advertisementData:RSSI:)]) {
        if ([self.delegate filterOnDiscoverPeripherals:peripheral advertisementData:advertisementData RSSI:RSSI]) {
            BLELog(@"扫描到设备:%@---广播内容:%@",peripheral.name,advertisementData);
            [self addDiscoverPeripheral:peripheral];
            
            if ([self.delegate respondsToSelector:@selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:)]) {
                [self.delegate centralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
            }
            
            if ([self.delegate respondsToSelector:@selector(filterOnconnectToPeripherals:advertisementData:RSSI:)]) {
                if ([self.delegate filterOnconnectToPeripherals:peripheral advertisementData:advertisementData RSSI:RSSI]) {
                    [_centralManager connectPeripheral:peripheral options:nil];
                    //开一个定时器监控连接超时的情况
                    connectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(disconnect:) userInfo:peripheral repeats:NO];
                }
            }
        }
    }
}

- (void)disconnect:(id)sender {
    [_centralManager stopScan];
}

//成功连接了外设
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    BLELog(@">>>连接到名称为（%@）的设备-成功",peripheral.name);
    [peripheral setDelegate:self];
    
    [connectTimer invalidate];//停止时钟
    [self addPeripheral:peripheral];
    [self sometimes_ever:peripheral];
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didConnectPeripheral:)]) {
        [self.delegate centralManager:central didConnectPeripheral:peripheral];
    }
    
    [peripheral discoverServices:nil];
}

//连接外设失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    BLELog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
    if ([self.delegate respondsToSelector:@selector(centralManager:didFailToConnectPeripheral:error:)]) {
        [self.delegate centralManager:central didFailToConnectPeripheral:peripheral error:error];
    }
}

//与外设断开了连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    BLELog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);
    if (error){
        BLELog(@">>> didDisconnectPeripheral for %@ with error: %@", peripheral.name, [error localizedDescription]);
    }else{
        [self sometimes_never:peripheral];
    }
    
    [self deletePeripheral:peripheral];
    
    if ([self.delegate respondsToSelector:@selector(centralManager:didDisconnectPeripheral:error:)]) {
        [self.delegate centralManager:central didDisconnectPeripheral:peripheral error:error];
    }
    
    //检查并重新连接需要重连的设备
    if ([_reConnectPeripherals containsObject:peripheral]) {
        [self connectToPeripheral:peripheral];
    }
}



#pragma mark -----------------------CBPeripheralDelegate---------------------
//发现了外设的服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    BLELog(@">>>扫描到服务：%@",peripheral.services);
    if (error) {
        BLELog(@">>>didDiscoverServices for %@ with error: %@", peripheral.name, [error localizedDescription]);
    }
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverServices:)]) {
        [self.delegate peripheral:peripheral didDiscoverServices:error];
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

//发现了服务的特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    BLELog(@">>>扫描到服务的特征：%@\n%@",service.UUID,service.characteristics);
    if (error) {
        BLELog(@"error didDiscoverCharacteristicsForService for %@ with error: %@", service.UUID, [error localizedDescription]);
    }
    if ([self.delegate respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
        [self.delegate peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
    }
}

//服务的特征值发生改变
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error{
    BLELog(@">>>特征值发生改变：%@",characteristic.value);
    if (error) {
        BLELog(@"error didUpdateValueForCharacteristic %@ with error: %@", characteristic.UUID, [error localizedDescription]);
    }
    if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]) {
        [self.delegate peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:error];
    }
}










#pragma mark - 设备list管理
- (void)addDiscoverPeripheral:(CBPeripheral *)peripheral{
    if (![_discoverPeripherals containsObject:peripheral]) {
        [_discoverPeripherals addObject:peripheral];
    }
}

- (void)addPeripheral:(CBPeripheral *)peripheral {
    if (![_connectedPeripherals containsObject:peripheral]) {
        [_connectedPeripherals addObject:peripheral];
    }
}

- (void)deletePeripheral:(CBPeripheral *)peripheral{
    [_connectedPeripherals removeObject:peripheral];
}

- (CBPeripheral *)findConnectedPeripheral:(NSString *)peripheralName {
    for (CBPeripheral *p in _connectedPeripherals) {
        if ([p.name isEqualToString:peripheralName]) {
            return p;
        }
    }
    return nil;
}

- (NSArray *)findConnectedPeripherals{
    return _connectedPeripherals;
}





-  (void)sometimes_ever:(CBPeripheral *)peripheral {
    if (![_reConnectPeripherals containsObject:peripheral]) {
        [_reConnectPeripherals addObject:peripheral];
    }
}
-  (void)sometimes_never:(CBPeripheral *)peripheral {
    [_reConnectPeripherals removeObject:peripheral];
}
@end

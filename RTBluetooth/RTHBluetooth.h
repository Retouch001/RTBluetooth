//
//  RTHBluetooth.h
//  RidingPack
//
//  Created by Tang Retouch on 2018/2/7.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CBPeripheral+WriteData.h"

#define KBLE_IS_SHOW_LOG 1
#define BLELog(fmt, ...) if(KBLE_IS_SHOW_LOG) { NSLog(fmt,##__VA_ARGS__); }

@protocol RTHBluetoothDelegate <CBCentralManagerDelegate,CBPeripheralDelegate>

- (BOOL)filterOnconnectToPeripherals:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;

- (BOOL)filterOnDiscoverPeripherals:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;

@end



@interface RTHBluetooth : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic, weak) id <RTHBluetoothDelegate>delegate;
@property (nonatomic, strong, readonly) CBCentralManager *centralManager;//中心设备

@property (nonatomic, strong, readonly) NSMutableArray *connectedPeripherals;//已经连接的所有设备
@property (nonatomic, strong, readonly) NSMutableArray *discoverPeripherals;//发现的所有外设
@property (nonatomic, strong, readonly) NSMutableArray *reConnectPeripherals;//需要重连的所有外设

+ (RTHBluetooth *)shareInstance;
- (void)scanPeripherals;
- (void)connectToPeripheral:(CBPeripheral *)peripheral;
- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral;
- (void)cancelScan;


- (NSArray *)findConnectedPeripherals;
- (CBPeripheral *)findConnectedPeripheral:(NSString *)peripheralName;

- (void)sometimes_ever:(CBPeripheral *)peripheral ;
- (void)sometimes_never:(CBPeripheral *)peripheral ;

@end

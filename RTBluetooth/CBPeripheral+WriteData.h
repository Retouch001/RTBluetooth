//
//  CBPeripheral+WriteData.h
//  RidingPack
//
//  Created by Tang Retouch on 2018/2/8.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheral (WriteData)

- (void)rt_writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic;

@end

//
//  CBPeripheral+WriteData.m
//  RidingPack
//
//  Created by Tang Retouch on 2018/2/8.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import "CBPeripheral+WriteData.h"
#import <CoreBluetooth/CoreBluetooth.h>
//蓝牙每次发送的最大字节数
static  int BLE_SEND_MAX_LEN = 20;

@implementation CBPeripheral (WriteData)

- (void)rt_writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic{
    CBCharacteristicWriteType type;
    if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        type = CBCharacteristicWriteWithoutResponse;
    }else{
        type = CBCharacteristicWriteWithResponse;
    }
    for (int i = 0; i < [data length]; i += BLE_SEND_MAX_LEN) {
        // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
        if ((i + BLE_SEND_MAX_LEN) < [data length]) {
            NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, BLE_SEND_MAX_LEN];
            NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
            [self writeValue:subData forCharacteristic:characteristic type:type];
            usleep(20 * 1000);
        }else {
            NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([data length] - i)];
            NSData *subData = [data subdataWithRange:NSRangeFromString(rangeStr)];
            [self writeValue:subData forCharacteristic:characteristic type:type];
            usleep(20 * 1000);
        }
    }
}

@end

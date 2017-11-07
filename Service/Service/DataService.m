//
//  DataService.m
//  服务端
//
//  Created by LiTengFang on 2017/6/10.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import "DataService.h"


#define KMaxDataLength 10 * 100 - 4

@implementation DataService

// 检验头部是否非法
+ (BOOL)isValideWithData:(NSData *)data {
    if (data.length >= 3) {
        NSData *headData = [data subdataWithRange:NSMakeRange(0, 3)];
        if (![headData isEqual:[self standardData]]) {
        
            return NO;
        } else {
            return YES;
        }
    } else {
        return YES;
    }
}

//解析包的长度
+ (NSRange)parsingLength:(NSData *)data {
    if (data.length < 8) {
        return NSMakeRange(NSNotFound, 0);
    } else {
        NSData *lenthData = [data subdataWithRange:NSMakeRange(4, 4)];
        uint32 length = ntohl(*(uint32 *)lenthData.bytes);
        
        if (data.length < length + 8) { //少包
      
            return NSMakeRange(NSNotFound, 0);
        } else {

            return NSMakeRange(8,length);

        }
    }
}

// 检验该包的结束标志位
+ (BOOL)isFinsh:(NSData *)data {
    if (data.length < 8) {
        return NO;
    } else {
        NSData *lenthData = [data subdataWithRange:NSMakeRange(3, 1)];
        BOOL hasMoreData = *(BOOL *)lenthData.bytes;
        
        return hasMoreData;
    }
}




/**
 *  这个函数事实上有三个返回值
 *
 *  @param data  <#data description#>
 *  @param error <#error description#>
 *
 *  @return data 解析出来的数据
 *  error 错误信息
 *  input data 该函数解析成功后会自动修改input data
 */
+ (NSData *)parsingData:(NSData *__autoreleasing *)data error:(NSError *__autoreleasing *)error isFinsh:(BOOL *)isFinsh {
    
    NSData *_receiveData = *data;
    
    if (_receiveData.length == 0) {
        *error = [NSError errorWithDomain:@"没有数据" code:ParsingErrorType_noData userInfo:nil];
        return nil;
    } else if (_receiveData.length < 8) { //少包
        //  [sock readDataWithTimeout:-1 tag:tag];
        *error = [NSError errorWithDomain:@"少包" code:ParsingErrorType_littlePackage userInfo:nil];
        return nil;
    } else {
        NSData *headData = [_receiveData subdataWithRange:NSMakeRange(0, 3)];
        if (![headData isEqual:[self standardData]]) {
            // 不合法 丢弃这个包,需要重启socket连接
            *error = [NSError errorWithDomain:@"不合法的包" code:ParsingErrorType_formatError userInfo:nil];
            return nil;
        }
        
        NSData *lenthData = [_receiveData subdataWithRange:NSMakeRange(4, 4)];
        uint32 length = ntohl(*(uint32 *)lenthData.bytes);
        
        if (_receiveData.length < length + 8) { //少包
            // [sock readDataWithTimeout:-1 tag:tag];
            *error = [NSError errorWithDomain:@"少包" code:ParsingErrorType_littlePackage userInfo:nil];
            return nil;
        } else {
            
            NSData *lenthData = [_receiveData subdataWithRange:NSMakeRange(3, 1)];
            *isFinsh = *(BOOL *)lenthData.bytes;
            
            
            NSData *contextData = [_receiveData subdataWithRange:NSMakeRange(8, length)];
            *data = [_receiveData subdataWithRange:NSMakeRange(8 + length, _receiveData.length - 8 - length)];
            return contextData;
        }
        
        
    }
}




+ (NSData *)packageData:(NSData *)data {
    
    
    assert(data != nil);
    
    NSArray *datas = [self getDatasWithData:data];
    
    NSMutableData *resultData = [NSMutableData new];
    for (NSData *tempData in datas) {
        if (tempData == datas.lastObject) {
            [resultData appendData:[self packageElementData:data isFinish:YES]];
        } else {
             [resultData appendData:[self packageElementData:data isFinish:NO]];
        }
    }
    
    return  resultData;
  
}

#pragma mark -- private method

// 将包切成若干个更小的包
+ (NSArray<NSData *> *)getDatasWithData:(NSData *)data {
    NSData *aData = [data copy];
    NSMutableArray *result = [NSMutableArray new];
    while (aData.length > KMaxDataLength) {
        NSData *tempData = [aData subdataWithRange:NSMakeRange(0, KMaxDataLength)];
        [result addObject:tempData];
        NSRange range = NSMakeRange(KMaxDataLength, aData.length - KMaxDataLength);
        NSUInteger length = aData.length;
        
        NSUInteger tag = KMaxDataLength;
        
        aData = [aData subdataWithRange:NSMakeRange(KMaxDataLength, aData.length - KMaxDataLength)];
    }
    [result addObject:aData];
    return result;
}

// 封包
+ (NSData *)packageElementData:(NSData *)data isFinish:(BOOL)isFinish {
   
   
    
    NSData *headData = [self standardData];
    NSData *flagData = [NSData dataWithBytes:&isFinish length:1];
    
    int32_t length = htonl(data.length);
    NSData *lenthData = [NSData dataWithBytes:&length length:4];
    
    
    NSMutableData *resultData = [NSMutableData new];
    [resultData appendData:headData];
    [resultData appendData:flagData];
    [resultData appendData:lenthData];
    [resultData appendData:data];
    return resultData;
}




// 头部信息
+ (NSData *)standardData {
    Byte head[3] = {0x2a,0x23,0x23};
    NSData *headData = [NSData dataWithBytes:head length:3];
    return headData;
}

@end

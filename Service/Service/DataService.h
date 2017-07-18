//
//  DataService.h
//  服务端
//
//  Created by LiTengFang on 2017/6/10.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    ParsingErrorType_littlePackage,
    ParsingErrorType_formatError,
    ParsingErrorType_noData
} ParsingErrorType;

@interface DataService : NSObject


+ (NSData *)parsingData:(NSData *__autoreleasing *)data error:(NSError *__autoreleasing *)error isFinsh:(BOOL *)isFinsh;

+ (NSData *)packageData:(NSData *)data;

+ (BOOL)isValideWithData:(NSData *)data;
+ (NSRange)parsingLength:(NSData *)data;
+ (BOOL)isFinsh:(NSData *)data;



@end

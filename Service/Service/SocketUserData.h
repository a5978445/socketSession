//
//  SocketUserData.h
//  服务端
//
//  Created by LiTengFang on 2017/6/12.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SocketUserData : NSObject

@property(strong,nonatomic) NSMutableData *receiveData;
@property(strong,nonatomic) NSMutableData *fileData;


- (void)invalidateTimer;

- (void)delayDisConectTimer;
- (void)delayHeartTimer;

- (instancetype)initWithHeartTimerBlock:(void(^)(NSTimer *))heartTimerBlock disConectTimer:(void(^)(NSTimer *))disConectTimer;
- (instancetype)init NS_UNAVAILABLE;
@end

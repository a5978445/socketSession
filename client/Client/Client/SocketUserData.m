//
//  SocketUserData.m
//  服务端
//
//  Created by LiTengFang on 2017/6/12.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import "SocketUserData.h"

#define kHeartTime 60
#define kDisconectTime 90
#define kFreeTime 300

@interface SocketUserData()
@property(strong,nonatomic) NSTimer *heartTimer;
@property(strong,nonatomic) NSTimer *FreeTriggerTimer;
@property(strong,nonatomic) NSTimer *disConectTimer;
@end

@implementation SocketUserData

- (instancetype)initWithHeartTimerBlock:(void(^)(NSTimer *))heartTimerBlock disConectTimer:(void(^)(NSTimer *))disConectTimer freeTriggerTimerBlock: (void(^)(NSTimer *))freeTriggerTimerBlock {
    self = [super init];
    if (self) {
        _receiveData = [NSMutableData new];
        _fileData = [NSMutableData new];
      
     //   _heartTimer = [NSTimer scheduledTimerWithTimeInterval:kHeartTime
      //                                                repeats:YES
      //                                                  block:heartTimerBlock];
       _heartTimer = [NSTimer timerWithTimeInterval:kHeartTime repeats:YES block:heartTimerBlock];
        
       
        
        
//        _disConectTimer = [NSTimer scheduledTimerWithTimeInterval:kDisconectTime
//                                                          repeats:YES
//                                                            block:disConectTimer];
        _disConectTimer = [NSTimer timerWithTimeInterval:kDisconectTime
                                                          repeats:YES
                                                            block:disConectTimer];
        
        _FreeTriggerTimer = [NSTimer timerWithTimeInterval:kFreeTime
                                                 repeats:YES
                                                   block:freeTriggerTimerBlock];
        
     //   [[NSRunLoop currentRunLoop] run];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[NSRunLoop currentRunLoop] addTimer:_heartTimer forMode:NSRunLoopCommonModes];
            [[NSRunLoop currentRunLoop] addTimer:_disConectTimer forMode:NSRunLoopCommonModes];
            [[NSRunLoop currentRunLoop] addTimer:_FreeTriggerTimer forMode:NSRunLoopCommonModes];
            [ [NSRunLoop currentRunLoop] run];
        });
    }
    return self;
}

- (void)invalidateTimer {
    [_heartTimer invalidate];
    [_disConectTimer invalidate];
    [_FreeTriggerTimer invalidate];
}



- (void)delayDisConectTimer {
    _disConectTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:kDisconectTime];
}

- (void)delayHeartTimer {
    _heartTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:kHeartTime];
}

- (void)delayFreeTriggerTimer {
    _FreeTriggerTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:kFreeTime];
}

@end

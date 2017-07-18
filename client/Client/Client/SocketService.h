//
//  ViewController.h
//  socket小试
//
//  Created by LiTengFang on 2017/5/11.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Box.pbobjc.h"
typedef void(^ResponseBlock)(Box *box, NSError *failureError);
typedef void(^IsFreeBlock)();
@interface SocketService : NSObject


@property(readonly,nonatomic) BOOL isBusy;
@property(strong,nonatomic) IsFreeBlock isFreeBlock;
- (BOOL)startConnect;
- (void)disConnect;
- (BOOL)isConected;

- (void)sendBox:(Box *)box responseBlock:(ResponseBlock)block;
+ (SocketService *)SocketServiceWithDelegateQueue:(dispatch_queue_t)delegateQueue;

@end




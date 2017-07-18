//
//  SocketServiceManger.h
//  Client
//
//  Created by LiTengFang on 2017/6/29.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketService.h"
#import "Box.pbobjc.h"



@interface SocketServiceManger : NSObject

+ (SocketServiceManger *)shareManager;

- (void)sendBox:(Box *)box responseBlock:(ResponseBlock)block;

@end

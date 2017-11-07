//
//  SocketServiceManger.m
//  Client
//
//  Created by LiTengFang on 2017/6/29.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import "SocketServiceManger.h"


static SocketServiceManger *share;

#define kMaxSocket 5



@interface RequestModel : NSObject

- (instancetype)initWithBox:(Box *)box ResponseBlock:(ResponseBlock)block;

@property(copy,nonatomic) ResponseBlock block;
@property(strong,nonatomic) Box *box;

@end

@implementation RequestModel

- (instancetype)initWithBox:(Box *)box ResponseBlock:(ResponseBlock)block {
    self = [super init];
    if (self) {
        _box = box;
        _block = [block copy];
    }
    return self;
}

@end


@interface SocketServiceManger()

@property(strong,nonatomic) NSMutableArray<RequestModel *> *models;
@property(strong,nonatomic) NSMutableArray<SocketService *> *socketServices;


@end

@implementation SocketServiceManger {
    dispatch_queue_t requestQueue;
    dispatch_queue_t responseQueue;
}


+ (SocketServiceManger *)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [SocketServiceManger new];
    });
    return share;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _models = [NSMutableArray new];
        _socketServices = [NSMutableArray new];
        
        
        requestQueue = dispatch_queue_create("requestQueue", DISPATCH_QUEUE_SERIAL);
        responseQueue = dispatch_queue_create("responseQueue", DISPATCH_QUEUE_SERIAL);

       
        
    }
    return self;
}

- (void)sendBox:(Box *)box responseBlock:(ResponseBlock)block {
    
    dispatch_async(requestQueue, ^{
    
        RequestModel *model =  [[RequestModel alloc]initWithBox:box ResponseBlock:block];
        
        SocketService *aSocketService = [self findSocketService];
        if (aSocketService == nil && self.socketServices.count < kMaxSocket) {
            NSLog(@"创建新的socket");
            aSocketService = [SocketService SocketServiceWithDelegateQueue:responseQueue];
            
            __weak typeof(SocketService *) weakSocketService = aSocketService;
            __weak typeof(self) weakSelf = self;
            aSocketService.isFreeBlock = ^{
                NSLog(@"释放链接");
                [weakSocketService disConnect];
                [weakSelf.socketServices removeObject:weakSocketService];
                
            };
            if (![aSocketService startConnect]) { //连接服务器失败
                block(nil,[NSError errorWithDomain:@"连接服务器失败" code:-990 userInfo:nil]);
                return;
            } else {
                [self.socketServices addObject:aSocketService];
            }
            
        }
        
        
        
        if (aSocketService) {
            [self sendModel:model socketService:aSocketService];
            
        } else {
            NSLog(@"暂无可用队列！");
            
            [_models addObject:model];
        }
    });
    
  
    
}

- (void)sendModel:(RequestModel *)model socketService:(SocketService *) aSocketService {
 
        __weak typeof(self) weakSelf = self;
        
        assert(model.block!=nil);
     //   NSLog(@"model.box = %@", model.box);
        [aSocketService sendBox:model.box responseBlock:^(Box *box, NSError *failureError) {
            
            model.box = box;
            model.block(box,failureError);
            
            
            RequestModel *firstModel = weakSelf.models.firstObject;
            
            if (firstModel) {
                [weakSelf.models removeObject:firstModel];
                [weakSelf sendModel:firstModel socketService:aSocketService];
            }
            
        }];
  
}

- (SocketService *)findSocketService {
    for (SocketService *service in self.socketServices) {
        if (!service.isBusy) {
            return service;
        } else {
           // NSLog(@"service 正忙");
        }
    }
    return nil;
}


@end

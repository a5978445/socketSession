//
//  ViewController.m
//  socket小试
//
//  Created by LiTengFang on 2017/5/11.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import "SocketService.h"
#import "GCDAsyncSocket.h"
#import "DataService.h"
#import "SocketUserData.h"
#import "Box.pbobjc.h"

@interface FallbackMechanism : NSObject

@property(assign,nonatomic) double baseTime;
@property(strong,nonatomic) NSArray<NSNumber *> *fallbackList;


- (void)fallBack;
- (void)reset;
- (double)fallBackTime;


@end

@implementation FallbackMechanism {
    int _index;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _index = 0;
        _baseTime = 5.0;
        _fallbackList = @[@0,@1,@2,@3,@4,@5];
    }
    return self;
}

- (void)fallBack {
    if (_index + 1 < _fallbackList.count) {
        _index ++;
    }
    
}

- (void)reset {
    _index = 0;
}

- (double)fallBackTime {
    return _baseTime * (1<<_fallbackList[_index].intValue);
}


@end


@interface SocketService ()<GCDAsyncSocketDelegate> {
    GCDAsyncSocket *_socket;
    FallbackMechanism *_fallbackMechanism;
}

@property(strong,nonatomic) NSString *host;
@property(assign,nonatomic) int port;
@property(copy) ResponseBlock block;
@property(assign) BOOL isBusy;
@property(strong) Box *box;
@property(strong,nonatomic) dispatch_queue_t delegateQueue;
@end

@implementation SocketService
- (instancetype)init {
    self = [super init];
    if (self) {
        _host = @"127.0.0.1";
        _port = 54321;
        _fallbackMechanism = [FallbackMechanism new];
        _delegateQueue = dispatch_get_main_queue();
        
    }
    return self;
}

+ (SocketService *)SocketServiceWithDelegateQueue:(dispatch_queue_t)delegateQueue {
    SocketService *service = [[SocketService alloc]init];
    service.delegateQueue = delegateQueue;
    return  service;
}

#pragma mark - public method
- (BOOL)startConnect {

    // Do any additional setup after loading the view, typically from a nib.
    _socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:self.delegateQueue];
 
    NSError *error;
    BOOL isSucess = [_socket connectToHost:self.host onPort:self.port error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    
    return isSucess;
    
}

- (void)disConnect {
    
    [self disConectSocket:_socket];
}


- (void)sendBox:(Box *)box responseBlock:(ResponseBlock)block {
    
    @synchronized (self) {
        assert(box.data.length > 0);
        NSLog(@"sendBox.......");
        
        self.isBusy = YES;
        self.block = block;
        self.box = box;
        
        if (_socket.isConnected) {
            
            [self writeDataWithBox:box];
            
            [_socket readDataWithTimeout:-1 tag:0];
            
            SocketUserData *userData = _socket.userData;
            [userData delayFreeTriggerTimer];
        } else {
          //  assert(0);
        }
    }

    
  
}

- (BOOL)isConected {
    return _socket.isConnected;
}

#pragma mark - delegate
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    SocketUserData *userData = ((SocketUserData *)sock.userData);
    [userData delayHeartTimer];
    NSLog(@"didWriteDataWithTag");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    //这里的sock指客户端的Socket
    // NSLog(@"%@", sock);
    SocketUserData *userData = ((SocketUserData *)sock.userData);
    NSMutableData *receiveData = userData.receiveData;
    [receiveData appendData:data];
    
    
    NSError *error;
    NSData *waitPasingData = receiveData;
    BOOL isFinsh = NO;
    
    
    while (error == nil) {
        NSData *parsedData = [DataService parsingData:&waitPasingData error:&error isFinsh:&isFinsh];
        if (error == nil) {
            [userData.fileData appendData:parsedData];
            if (isFinsh) {
                
                Box *box = [Box parseFromData:userData.fileData error:nil];
                userData.fileData = [NSMutableData new];
                if (box.service == Box_Service_HeartBeat) {
                    NSLog(@"这是一个心跳包");
                } else {
                    
                    self.box = nil;
                    self.isBusy = NO;
                    self.block(box, nil);
                    
                }
                
            }
            
          
            [userData delayDisConectTimer];
        } else {
            switch (error.code) {
                case ParsingErrorType_littlePackage:
                    [sock readDataWithTimeout:-1 tag:tag];
                    break;
                case ParsingErrorType_formatError:
                    [self disConectSocket:sock];
                    [self performSelector:@selector(restartSocket:)
                               withObject:sock
                               afterDelay:_fallbackMechanism.fallBackTime];
                    self.box = nil;
                    self.isBusy = NO;
                    self.block(nil, [NSError errorWithDomain:@"数据解析失败" code:-999 userInfo:nil]);
                    break;
                case ParsingErrorType_noData:
                    [sock readDataWithTimeout:-1 tag:tag];
                    break;
                default:
                    break;
            }
        }
    }
    receiveData = [waitPasingData mutableCopy];
    userData.receiveData = receiveData;
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    __weak GCDAsyncSocket *weakNewSocket = sock;
    __weak typeof(self) weakSelf = self;
    sock.userData = [[SocketUserData alloc]initWithHeartTimerBlock:^(NSTimer *timer) {
        // 发送心跳包
        Box *heartBox =  [Box new];
        heartBox.service = Box_Service_HeartBeat;
        
        [weakSelf writeDataWithBox:heartBox];
    } disConectTimer:^(NSTimer *timer) {
        NSLog(@"连接超时！");
        
        [weakSelf disConectSocket:weakNewSocket];
        [weakSelf performSelector:@selector(restartSocket:)
                       withObject:weakNewSocket
                       afterDelay:_fallbackMechanism.fallBackTime];
    } freeTriggerTimerBlock:^(NSTimer *timer) {
        if (self.isFreeBlock) {
            self.isFreeBlock();
        }
    }];
    
    //重置会退机制指针
    [_fallbackMechanism reset];
    [sock readDataWithTimeout:-1 tag:0];
    
    if (self.box) {
      
        [self writeDataWithBox:self.box];
        [_socket readDataWithTimeout:-1 tag:0];
    }
   
    
    SocketUserData *userData = _socket.userData;
    [userData delayFreeTriggerTimer];
    
}



- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socketDidDisconnect:%@",sock);
    SocketUserData *userData = sock.userData;
    [userData invalidateTimer];
    
    if (err != nil) {
        [self performSelector:@selector(restartSocket:)
                   withObject:sock
                   afterDelay:_fallbackMechanism.fallBackTime];
    }
   
}


#pragma mark - private method
- (void)disConectSocket:(GCDAsyncSocket *)sock {
    [sock setDelegate:nil];
    [sock disconnect];
    
    
    SocketUserData *userData = sock.userData;
    [userData invalidateTimer];
}


- (void)restartSocket:(GCDAsyncSocket *)sock {
    NSLog(@"重启连接。。。。");
    SocketUserData *userData = sock.userData;
    userData.receiveData = [NSMutableData new];
    userData.fileData = [NSMutableData new];
    sock.delegate = self;
    [sock connectToHost:self.host onPort:self.port error:nil];
    [_fallbackMechanism fallBack];
}

- (void)writeDataWithBox:(Box *)box {
  //  NSLog(@"service.box = %@", box);
     [_socket writeData:[DataService packageData:box.data] withTimeout:-1 tag:0];
}




@end

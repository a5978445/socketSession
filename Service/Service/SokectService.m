//
//  HaoLiHai.m
//  socket小试
//
//  Created by LiTengFang on 2017/6/10.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import "SokectService.h"
#import "GCDAsyncSocket.h"
#import "DataService.h"
#import "SocketUserData.h"
#import "Box.pbobjc.h"

@interface SokectService () <GCDAsyncSocketDelegate> {
    GCDAsyncSocket *_serverSocket;
    
}

@property (nonatomic, strong) NSMutableArray<GCDAsyncSocket *> *clientSocket;

@end

@implementation SokectService

- (instancetype)init {
    if (self = [super init]) {
        _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:
                         dispatch_get_global_queue(0, 0)];

    }
    return self;
}

#pragma mark - public method
- (void)startServer {
    NSError *error;
    [_serverSocket acceptOnPort:54321 error:&error];
    if (error) {
        NSLog(@"服务器开启失败");
    }else {
        NSLog(@"服务器开启成功");
    }
}

#pragma mark - delegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    //这里sock指服务器的socket，newSocket指客户端的Socket，
    NSLog(@"%@",newSocket);
    
    //保存客户端的Socket，不然刚连接成功就会自动关闭
    [self.clientSocket addObject:newSocket];
    __weak GCDAsyncSocket *weakNewSocket = newSocket;
    newSocket.userData = [[SocketUserData alloc]initWithHeartTimerBlock:^(NSTimer *timer) {
        
        Box *box =  [Box new];
        box.service = Box_Service_HeartBeat;
      //  box tobu
     
        
        NSData *bodyData = box.data;
        
        [weakNewSocket writeData:[DataService packageData:bodyData] withTimeout:-1 tag:0];
        NSLog(@"发送心跳包！");
        
    } disConectTimer:^(NSTimer *timer) {
        NSLog(@"连接超时！");
       
        [weakNewSocket disconnect];
        [weakNewSocket setDelegate:nil];
       
        SocketUserData *userData = weakNewSocket.userData;
        [userData invalidateTimer];

    }];
    
    NSLog(@"%@",newSocket.userData);
    
    //sock只负责连接服务器，不负责读取数据，因此使用newSocket
    [newSocket readDataWithTimeout:-1 tag:100];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socketDidDisconnect:%@",sock);
    SocketUserData *userData = sock.userData;
    [userData invalidateTimer];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    //这里的sock指客户端的Socket
    // NSLog(@"%@", sock);
    dispatch_async(dispatch_get_main_queue(), ^{
        SocketUserData *userData = ((SocketUserData *)sock.userData);
        NSMutableData *_receiveData = userData.receiveData;
        [_receiveData appendData:data];
        
        @synchronized (sock.userData) {
            BOOL isContinue = YES;
            while (isContinue) {
                if ([DataService isValideWithData:_receiveData]) {
                    BOOL isFinsh = [DataService isFinsh:_receiveData];
                    NSRange range = [DataService parsingLength:_receiveData];
                    if (range.location != NSNotFound) {
                        
                        NSData *elementData = [[_receiveData subdataWithRange:range] copy];
                        _receiveData = [[_receiveData subdataWithRange:NSMakeRange(range.location + range.length, _receiveData.length - range.location - range.length)] mutableCopy];
                        [userData.fileData appendData:elementData];
                        
                        Box *box = [Box parseFromData:[userData.fileData copy] error:nil];
                        if (isFinsh) {
                            
                            
                            
                            
                            if (box.service == Box_Service_HeartBeat) {
                                NSLog(@"这是一个心跳包！");
                            } else {
                                NSLog(@"box = %@",box);
                                NSData *bodyData = [self dealData:userData.fileData ];
                                [sock writeData:[DataService packageData:bodyData] withTimeout:-1 tag:0];
                                
                            }
                            userData.fileData  = [NSMutableData new];
                            [sock readDataWithTimeout:-1 tag:0];
                            [userData delayDisConectTimer];
                            isContinue = YES;
                        }
                        
                        
                        
                    } else { //少包
                        [sock readDataWithTimeout:-1 tag:0];
                        isContinue = NO;
                    }
                } else {
                    [sock disconnect];
                    [userData invalidateTimer];
                    isContinue = NO;
                }
            }
            userData.receiveData = _receiveData;
        }
    });
    
  
 
    
    
    
    /*
     SocketUserData *userData = ((SocketUserData *)sock.userData);
     NSMutableData *_receiveData = userData.receiveData;
     [_receiveData appendData:data];
     NSError *error;
     while (error == nil) {
     NSData *parsedData = [DataService parsingData:&_receiveData error:&error];
     if (error == nil) {
     NSData *bodyData = [self dealData:parsedData];
     
     if (bodyData == nil) {
     NSLog(@"这是一个心跳包！");
     } else {
     
     [sock writeData:[DataService packageData:bodyData] withTimeout:-1 tag:0];
     [sock readDataWithTimeout:-1 tag:0];
     }
     
     [userData delayDisConectTimer];
     
     } else {
     switch (error.code) {
     case ParsingErrorType_littlePackage:
     [sock readDataWithTimeout:-1 tag:tag];
     break;
     case ParsingErrorType_formatError:
     [sock disconnect];
     break;
     case ParsingErrorType_noData:
     [sock readDataWithTimeout:-1 tag:tag];
     break;
     default:
     break;
     }
     }
     }
     
     userData.receiveData = [_receiveData mutableCopy] ;
     */
    
    
    
}

#pragma mark 服务器发送数据给客户端
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    //这里的sock依然指客户端的socket
    // NSLog(@"%@", sock);
    
    //服务器每次写数据之前都需要读取一次数据，之后才可以返回数据
    // [sock readDataWithTimeout:-1 tag:100];
    SocketUserData *userData = sock.userData;
    [userData delayHeartTimer];
}

#pragma mark - private method
- (NSData *)dealData:(NSData *)data {
    
 
    Box *box = [Box parseFromData:data error:nil];
    
    
    switch (box.service) {
        case Box_Service_SendMesaage: {
            
            
            
            Box *messageBox = [Box new];
            messageBox.service = Box_Service_SendMesaageResponse;
            messageBox.sendMessageAck = [SendMessageAck new];
            messageBox.sendMessageAck.ackMessage = [box.sendMessageRequest.message stringByAppendingString:@"+ack"];
            return messageBox.data;
            break;
        }
        case Box_Service_GetPicture: {
            Box *messageBox = [Box new];
            messageBox.service = Box_Service_GetPictureResponse;
            messageBox.getPictureAck = [GetPictureAck new];
            
         //   NSImage *image = [NSImage imageNamed:@"timg"];
            NSString *filePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"timg.jpeg"];
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            
            messageBox.getPictureAck.pictureData = data;
            return messageBox.data;
            break;
        }
        default:
            assert(0);
            NSLog(@"warn!!!!:%@",box);
            return nil;
            break;
    }
    

    
  
 
}

- (NSMutableArray *)clientSocket {
    if (_clientSocket == nil) {
        _clientSocket = [NSMutableArray new];
    }
    
    return _clientSocket;
}



@end

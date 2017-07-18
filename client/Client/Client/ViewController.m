//
//  ViewController.m
//  Client
//
//  Created by LiTengFang on 2017/6/28.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import "ViewController.h"

#import "SocketServiceManger.h"

@interface ViewController()
@property (weak) IBOutlet NSTextField *textField;
@property (weak) IBOutlet NSImageView *imageView;

@end

@implementation ViewController {
   
}
- (IBAction)send:(id)sender {
    NSLog(@"%@",self.textField.stringValue);
    
  
   // box.sendMessageRequest.message = self.textField.stringValue;
    
    __block int number = 0;
    for (int i = 0; i < 1000; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            Box *box = [Box new];
            box.service = Box_Service_SendMesaage;
            box.sendMessageRequest = [SendMessageRequest new];
            box.sendMessageRequest.message = [NSString stringWithFormat:@"jkb:%d",i];
            
            [SocketServiceManger.shareManager sendBox:box responseBlock:^(Box *box, NSError *failureError) {
              
                if (failureError == nil) {
                    NSLog(@"%@",box.sendMessageAck);
                } else {
                    NSLog(@"%@",failureError);
                }
                number++;
            }];
        });
       
    }
    
  //  sleep(2);
 //   assert(number == 1000);

}

- (IBAction)getPictureAction:(NSButton *)sender {
    
    Box *box = [Box new];
    box.service = Box_Service_GetPicture;
    box.getPictureRequest = [GetPictureRequest new];
    box.getPictureRequest.URL = @"认真你就输了！";
    
    
    __weak typeof(self) weakSelf = self;
    for (int i = 0; i < 100; i++) {
        [SocketServiceManger.shareManager sendBox:box responseBlock:^(Box *box, NSError *failureError) {
            if (failureError == nil) {
              //  NSLog(@"%@",box.getPictureAck);
                NSLog(@"成功接收！");
                
                
                [weakSelf.imageView setImage:[[NSImage alloc]initWithData:box.getPictureAck.pictureData]];
            } else {
                NSLog(@"%@",failureError);
            }
        }];
    }
   
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [SocketServiceManger shareManager];


}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end

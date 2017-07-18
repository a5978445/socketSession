//
//  ViewController.m
//  Service
//
//  Created by LiTengFang on 2017/6/28.
//  Copyright © 2017年 LiTengFang. All rights reserved.
//

#import "ViewController.h"

#import "SokectService.h"

@implementation ViewController {
    SokectService *_service;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    _service = [SokectService new];
    [_service startServer];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end

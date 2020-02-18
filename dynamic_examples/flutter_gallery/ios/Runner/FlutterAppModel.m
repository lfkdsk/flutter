//
//  FlutterAppModel.m
//  Runner
//
//  Created by 白昆仑 on 2019/7/29.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "FlutterAppModel.h"


@implementation FlutterAppModel

- (instancetype)initWithPackage:(BDPMSPackage *)package {
    self = [self init];
    if (self) {
        _name = package.name;
        _showName = package.chineseName;
        _ID = package.ID;
        _version = package.version;
        _priority = package.priority;
        _cellHeight = -1;
        if (package.extra) {
            NSData *jsonData = [package.extra dataUsingEncoding:NSUTF8StringEncoding];
            _detail = [NSJSONSerialization JSONObjectWithData:jsonData
                                                      options:NSJSONReadingAllowFragments
                                                        error:nil];
        }
        _package = package;
    }
    
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _ID = -1;
        _version = -1;
        _updateVersion = -1;
        _updateStatus = UpdateStatusNone;
        _updateProgress = 0.0;
    }
    
    return self;
}

@end

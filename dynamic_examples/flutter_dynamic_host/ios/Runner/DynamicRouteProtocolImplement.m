//
//  DynamicRouteProtocolImplement.m
//  Runner
//
//  Created by 白昆仑 on 2019/8/21.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "DynamicRouteProtocolImplement.h"
#import <BDPackageManagerService/BDPackageManagerService.h>
#import <BDFlutterPackageManager/BDFlutterPackageManager.h>

@implementation DynamicRouteProtocolImplement

- (NSInteger)maxPackageCount {
    return 3;
}

- (void)validPackageWithName:(NSString *)name completion:(void(^)(id<DynamicRoutePackageProtocol> _Nullable package))completion {
    if (completion) {
        id<DynamicRoutePackageProtocol> package = (id<DynamicRoutePackageProtocol>)[[BDFlutterPackageManager sharedInstance] validPackageWithName:name];
        completion(package);
    }
}

- (BOOL)isDynamicEngine {
    return [BDFlutterPackageManager sharedInstance].isDynamicEngine;
}

- (NSString *)dynamicEnginePath {
    return [BDFlutterPackageManager sharedInstance].dynamicEnginePath;
}

@end

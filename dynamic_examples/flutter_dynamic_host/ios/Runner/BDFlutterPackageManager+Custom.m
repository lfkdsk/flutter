//
//  BDFlutterPackageManager+Custom.m
//  Runner
//
//  Created by 白昆仑 on 2019/8/23.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "BDFlutterPackageManager+Custom.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "DemoViewController.h"


@implementation BDFlutterPackageManager (Custom)

+ (void)load {
    [self swapMethod:[self class]
        originMethod:@selector(downloadProgress:progress:)
           newMethod:@selector(customDownloadProgress:progress:)];
    [self swapMethod:[self class]
        originMethod:@selector(didFinish:package:error:)
           newMethod:@selector(customDidFinish:package:error:)];
}

+ (BOOL)swapMethod:(Class)class originMethod:(SEL)originSel newMethod:(SEL)newSel {
    Method originMethod = class_getInstanceMethod(class, originSel);
    Method newMethod = class_getInstanceMethod(class, newSel);
    if (originMethod && newMethod) {
        method_exchangeImplementations(originMethod, newMethod);
        return YES;
    }
    
    return NO;
}


- (void)customDownloadProgress:(BDPMSPackage *)package progress:(double)progress {
    [self customDownloadProgress:package progress:progress];
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].delegate.window.rootViewController;
        DemoViewController *vc = nav.viewControllers[0];
        [vc downloadProgress:package progress:progress];
    });
}

- (void)customDidFinish:(BOOL)success package:(BDPMSPackage * _Nullable)package error:(NSError * _Nullable)error {
    [self customDidFinish:success package:package error:error];
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].delegate.window.rootViewController;
        DemoViewController *vc = nav.viewControllers[0];
        [vc didFinish:success package:package error:error];
    });
}

@end

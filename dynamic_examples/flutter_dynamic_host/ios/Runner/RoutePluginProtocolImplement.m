//
//  RoutePluginProtocolImplement.m
//  Runner
//
//  Created by 白昆仑 on 2019/8/21.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "RoutePluginProtocolImplement.h"
#import "FlutterViewWrapperController.h"

@interface RoutePluginProtocolImplement () <UIGestureRecognizerDelegate>

@end

@implementation RoutePluginProtocolImplement

- (void)flutterWrapperController:(UIViewController *)wrapperController handleNativeRoute:(NSString * _Nonnull)openURL params:(NSDictionary * _Nonnull)params {
    NSLog(@"handleNativeRoute-url:%@ parames:%@", openURL, params);
    if ([openURL isEqualToString:@"main"]) {
        return;
    } else {
        UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].delegate.window.rootViewController;
        nav.navigationBarHidden = YES;
        nav.navigationBar.hidden = YES;
        nav.interactivePopGestureRecognizer.enabled = YES;
        nav.interactivePopGestureRecognizer.delegate = self;
        
        FlutterViewWrapperController *controller = [[FlutterViewWrapperController alloc] initWithRouteParams:params];
        [nav pushViewController:controller animated:YES];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

// 显示/隐藏navigationBar
- (void)flutterWrapperController:(UIViewController*)controller showNavigationBar:(BOOL)isShow {
    controller.navigationController.navigationBarHidden = !isShow;
}

- (void)flutterWrapperController:(UIViewController *)controller enableInteractivePopGesture:(BOOL)enabled {
    
}

- (void)flutterWrapperController:(UIViewController *)controller updateDragBackLeftEdge:(CGFloat)edge {
    
}

@end

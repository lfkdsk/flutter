//
//  BDSFlutterBridgePlugin.m
//  Runner
//
//  Created by 白昆仑 on 2019/8/26.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "BDSFlutterBridgePlugin.h"
#import <TTBridgeUnify/TTBridgeCommand.h>
#import <TTBridgeUnify/TTBridgeForwarding.h>
#import <TTBridgeUnify/TTBridgeEngine.h>

@interface BDSFlutterBridgePlugin () <TTBridgeEngine>

@end

@implementation BDSFlutterBridgePlugin

- (void)getUserInfoWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
}

- (void)notifyUserChangedWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
    
}

- (void)loginWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
    
    TTBridgeCommand *command = [[TTBridgeCommand alloc] init];
    command.fullName = @"bds_video_method_channel";
    command.params = @{@"user_follow":@"user_follow",
                       @"user_id":@"102833276085",
                       @"is_follow":@(1)};
    command.bridgeType = TTBridgeTypeOn;
    [[TTBridgeForwarding sharedInstance] forwardWithCommand:command weakEngine:self completion:nil];
    
}

- (void)logoutWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
    
    TTBridgeCommand *command = [[TTBridgeCommand alloc] init];
    command.fullName = @"bds_video_method_channel";
    command.params = @{@"user_follow":@"user_follow",
                       @"user_id":@"102833276085",
                       @"is_follow":@(1)};
    command.bridgeType = TTBridgeTypeOn;
    [[TTBridgeForwarding sharedInstance] forwardWithCommand:command weakEngine:self completion:nil];
}

- (void)hasLoginWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
    
    TTBridgeCommand *command = [[TTBridgeCommand alloc] init];
    command.fullName = @"bds_video_method_channel";
    command.params = @{@"user_follow":@"user_follow",
                       @"user_id":@"102833276085",
                       @"is_follow":@(1)};
    command.bridgeType = TTBridgeTypeOn;
    [[TTBridgeForwarding sharedInstance] forwardWithCommand:command weakEngine:self completion:nil];
}

- (void)testMethodWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
}

- (void)getPlayProgressWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
}

- (void)setPlayProgressWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
}

- (void)getPlayConfigWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
}

- (void)getAllProgressWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
}

- (void)getSharePlatformWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
}

- (void)shareToPlatformWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    callback(TTBridgeMsgSuccess, @{}, nil);
}

- (void)showToastWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    
    NSString *message = param[@"message"];
    if (message) {
        UIView *container = [UIView new];
        UILabel *label = [UILabel new];
        label.numberOfLines = 1;
        label.text = message;
        label.font = [UIFont systemFontOfSize:16];
        [label sizeToFit];
        label.textColor = [UIColor whiteColor];
        label.frame = CGRectMake(20, 10, label.bounds.size.width, label.bounds.size.height);
        [container addSubview:label];
        container.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        CGFloat toastWidth = 20 + 20 + label.bounds.size.width;
        CGFloat toastHeight = 10 + 10 + label.bounds.size.height;
        CGFloat width = window.bounds.size.width;
        CGFloat height = window.bounds.size.height;
        container.frame = CGRectMake((width-toastWidth)/2, (height-toastHeight)/2, toastWidth, toastHeight);
        container.alpha = 0;
        container.layer.cornerRadius = 5;
        [window addSubview:container];
        [UIView animateWithDuration:0.3 animations:^{
            container.alpha = 1;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 animations:^{
                    container.alpha = 0;
                } completion:^(BOOL finished) {
                    [container removeFromSuperview];
                }];
            });
        }];
    }
}

- (NSURL *)sourceURL {
    return nil;
}

- (NSObject *)sourceObject {
    return nil;
}

- (UIViewController *)sourceController {
    return nil;
}

- (TTBridgeRegisterEngineType)engineType {
    return TTBridgeRegisterFlutter;
}

@synthesize sourceController;

@end



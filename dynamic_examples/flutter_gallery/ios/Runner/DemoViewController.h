//
//  DemoViewController.h
//  Runner
//
//  Created by 白昆仑 on 2019/7/29.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BDPackageManagerService/BDPMSPackage.h>

NS_ASSUME_NONNULL_BEGIN

@interface DemoViewController : UIViewController

- (void)downloadProgress:(BDPMSPackage *)package progress:(double)progress;

- (void)didFinish:(BOOL)success package:(BDPMSPackage * _Nullable)package error:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END

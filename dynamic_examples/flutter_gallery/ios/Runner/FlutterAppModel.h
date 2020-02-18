//
//  FlutterAppModel.h
//  Runner
//
//  Created by 白昆仑 on 2019/7/29.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BDPackageManagerService/BDPMSPackage.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, UpdateStatus) {
    UpdateStatusNone = 0,
    UpdateStatusDownloading,
    UpdateStatusFailed,
    UpdateStatusSuccess,
};

@interface FlutterAppModel : NSObject

- (instancetype)initWithPackage:(BDPMSPackage *)package;

@property(nonatomic, copy)NSString *name;
@property(nonatomic, copy)NSString *showName;
@property(nonatomic, assign)NSInteger ID;
@property(nonatomic, assign)NSInteger version;
@property(nonatomic, assign)NSInteger priority;
@property(nonatomic, copy)NSDictionary *detail;
@property(nonatomic, assign)UpdateStatus updateStatus;
@property(nonatomic, assign)NSInteger updateVersion;
@property(nonatomic, assign)double updateProgress;
@property(nonatomic, strong)BDPMSPackage *package;
@property(nonatomic, assign)NSInteger index;
@property(nonatomic, assign)CGFloat cellHeight;
@property(nonatomic, assign)CGRect containerViewFrame;
@property(nonatomic, assign)CGRect coverImageFrame;
@property(nonatomic, assign)CGRect nameLabelFrame;
@property(nonatomic, assign)CGRect versionLableFrame;
@property(nonatomic, assign)CGRect progressFrame;
@property(nonatomic, assign)CGRect desFrame;

@end

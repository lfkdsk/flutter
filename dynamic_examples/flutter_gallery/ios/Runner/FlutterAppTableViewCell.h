//
//  FlutterAppTableViewCell.h
//  Runner
//
//  Created by 白昆仑 on 2019/7/29.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlutterAppModel.h"


@interface FlutterAppTableViewCell : UITableViewCell

@property(nonatomic, strong)FlutterAppModel* model;

+ (CGFloat)cellHeightWithModel:(FlutterAppModel *)model width:(CGFloat)width;

@end

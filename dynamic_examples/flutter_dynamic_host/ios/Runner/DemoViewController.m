//
//  DemoViewController.m
//  Runner
//
//  Created by 白昆仑 on 2019/7/29.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "DemoViewController.h"
#import <BDFlutterPackageManager/BDFlutterPackageManager.h>
#import "FlutterAppTableViewCell.h"
#import "FlutterAppModel.h"
#import <Flutter/Flutter.h>
#import "GeneratedPluginRegistrant.h"
#import <BDPackageManagerService/BDPMSManager.h>
#import "FlutterManager.h"
#import "FlutterViewWrapperController.h"
#import <objc/runtime.h>
#import "BDPMSUtility.h"

static CGFloat const kHeaderHeight = 60;
static CGFloat const kFooterBtnHeight = 50;
static CGFloat const kLeftSpace = 25;
static NSInteger const kFooterBtnNumber = 3;

@interface DemoViewController() <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<FlutterAppModel *> *dataList;
@property(nonatomic, strong)NSString *enginePath;
@property(nonatomic, strong)UIColor *backgroundColor;
@end

@interface DemoViewController ()

@end

@implementation DemoViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _dataList = [NSMutableArray new];
    _backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGSize viewSize = self.view.bounds.size;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, statusBarHeight, viewSize.width, viewSize.height)
                                              style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerClass:[FlutterAppTableViewCell class] forCellReuseIdentifier:NSStringFromClass([FlutterAppTableViewCell class])];
    _tableView.backgroundView.backgroundColor = [UIColor whiteColor];
    _tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_tableView];
    
    if ([BDFlutterPackageManager sharedInstance].isFlutterAppValid) {
        [self onFlutterManagerInitFinished];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFlutterManagerInitFinished) name:BDFlutterPackageReadyNotification object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - TablbView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 400;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    FlutterAppModel *model = _dataList[indexPath.row];
    if (model.cellHeight < 0) {
        model.cellHeight = [FlutterAppTableViewCell cellHeightWithModel:model width:tableView.bounds.size.width];
    }
    
    return model.cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return kFooterBtnHeight * kFooterBtnNumber + 100;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat viewWidth = self.view.frame.size.width;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, kHeaderHeight)];
    CAGradientLayer *layer = [CAGradientLayer new];
    layer.colors=@[(__bridge id)[UIColor whiteColor].CGColor,(__bridge id)self.backgroundColor.CGColor];
    layer.startPoint = CGPointMake(0.5, 0);
    layer.endPoint = CGPointMake(0.5, 1);
    layer.frame = header.bounds;
    [header.layer addSublayer:layer];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kLeftSpace, 0, viewWidth-40, kHeaderHeight)];
    label.text = @"Flutter AppStore";
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont boldSystemFontOfSize:30];
    label.textColor = [UIColor blackColor];
    [header addSubview:label];
    return header;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    CGFloat viewWidth = self.view.frame.size.width;
    UIView *footer = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, viewWidth, kFooterBtnHeight * 3 + 10)];
    CAGradientLayer *layer = [CAGradientLayer new];
    layer.colors=@[(__bridge id)self.backgroundColor.CGColor, (__bridge id)[UIColor whiteColor].CGColor];
    layer.startPoint = CGPointMake(0.5, 0);
    layer.endPoint = CGPointMake(0.5, 1);
    layer.frame = footer.bounds;
    [footer.layer addSublayer:layer];
    
    CGFloat originX = kLeftSpace;
    CGFloat originY = 10;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"启动宿主包" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:20];
    [btn sizeToFit];
    btn.frame = CGRectMake(originX, originY, btn.frame.size.width, kFooterBtnHeight);
    [btn addTarget:self action:@selector(loadHostPackage) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:btn];
    originY += kFooterBtnHeight;
    
    btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"启动预置包" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:20];
    [btn sizeToFit];
    btn.frame = CGRectMake(originX, originY, btn.frame.size.width, kFooterBtnHeight);
    [btn addTarget:self action:@selector(loadLocalPackage) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:btn];
    originY += kFooterBtnHeight;
    
    btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"清空沙盒并退出" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:20];
    [btn sizeToFit];
    btn.frame = CGRectMake(originX, originY, btn.frame.size.width, kFooterBtnHeight);
    [btn addTarget:self action:@selector(clearAndExit) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:btn];
    return footer;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    FlutterAppTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:NSStringFromClass([FlutterAppTableViewCell class])];
    cell.backgroundColor = self.backgroundColor;
    cell.model = _dataList[indexPath.row];
    [cell setNeedsLayout];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataList.count;
}

- (FlutterAppModel *)findModelWithPackage:(BDPMSPackage *)package {
    FlutterAppModel *model;
    for (FlutterAppModel *obj in _dataList) {
        if (obj.ID == package.ID) {
            model = obj;
            break;
        }
    }
    return model;
}

- (FlutterAppModel *)findAndCreateModelWithPackage:(BDPMSPackage *)package {
    FlutterAppModel *model;
    NSInteger index = 0;
    for (FlutterAppModel *obj in _dataList) {
        if (obj.priority < package.priority) {
            break;
        }
        else if(obj.priority > package.priority) {
            index++;
        }
        else {
            if (obj.ID > package.ID) {
                break;
            }
            else if(obj.ID < package.ID) {
                index++;
            }
            else {
                model = obj;
                break;
            }
        }
    }
    
    if (!model) {
        model = [[FlutterAppModel alloc] initWithPackage:package];
        [_dataList insertObject:model atIndex:index];
    }
    
    model.index = index;
    return model;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FlutterAppModel *model = _dataList[indexPath.row];
    if (model.package && model.package.type != 0) {
        [self alertWithMessage:@"该应用不是Flutter App包，无法独立运行"];
        return;
    }
    
    if (model.detail && model.detail[@"route"]) {
        [self pushFlutterVCWithURL:model.detail[@"route"] package:model.package];
    }
    else {
        NSString *url = [NSString stringWithFormat:@"local-flutter://%@", model.package.name];
        [self pushFlutterVCWithURL:url package:model.package];
    }
}

#pragma mark - Push FlutterViewController

- (void)loadHostPackage {
    [self pushFlutterVCWithURL:@"default-flutter://host" package:nil];
}

- (void)loadLocalPackage {
    NSString *localPcakgePath = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"dynamic.zip"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:localPcakgePath]) {
        [self alertWithMessage:@"没有预置包"];
        return;
    }
    
    if ([self checkEngine]) {
        [self nativePushFlutterVCWithDillPath:localPcakgePath];
    }
}

- (void)clearAndExit {
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dirPath = [documentPath stringByAppendingPathComponent:@"BDPMS"];
    BOOL rst = [[NSFileManager defaultManager] removeItemAtPath:dirPath error:nil];
    if (!rst) {
        [self alertWithMessage:@"删除本地包失败"];
    }
    else {
        exit(0);
    }
}

- (void)pushFlutterVCWithURL:(NSString *)url package:(BDPMSPackage *)package {
    if (![self checkEngine]) {
        return;
    }
    
    if (![BDPMSUtility checkStringValid:url]) {
        return;
    }
    
    if ([[FlutterManager sharedManager] canOpenURL:[NSURL URLWithString:url]]) {
//        [self nativePushFlutterVCWithDillPath:package.unzipPackagePath];
        FlutterViewWrapperController *flutterWrapperVC = [[FlutterViewWrapperController alloc] initWithRouteParams:@{@"url":url}];
        [self.navigationController pushViewController:flutterWrapperVC animated:YES];
    }
    else {
        [self alertWithMessage:@"包不合法"];
    }
}

- (void)nativePushFlutterVCWithDillPath:(NSString *)path {
    if (![BDFlutterPackageManager sharedInstance].isFlutterAppValid) {
        return;
    }
    
    FlutterDartProject *config = [[FlutterDartProject alloc] init];
    if ([BDFlutterPackageManager sharedInstance].isEnginePackageMode) {

        if ([config respondsToSelector:@selector(setEnginePath:)]) {
            [config performSelector:@selector(setEnginePath:) withObject:[BDFlutterPackageManager sharedInstance].enginePackagePath];
        }
    }
    
    if (path) {
        if ([config respondsToSelector:@selector(setDillPath:)]) {
            [config performSelector:@selector(setDillPath:) withObject:[path stringByAppendingPathComponent:@"flutter_assets"]];
        }
    }
         
    FlutterViewController *vc = [[FlutterViewController alloc] initWithProject:config nibName:nil bundle:nil];
    [GeneratedPluginRegistrant registerWithRegistry:vc.pluginRegistry];
    [self.navigationController pushViewController:vc animated:YES];
}

- (BOOL)checkEngine {
    if (![BDFlutterPackageManager sharedInstance].isEngineValid) {
        [self alertWithMessage:@"本地无动态Engine包，无法启动该App"];
        return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (void)alertWithMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}

- (void)onFlutterManagerInitFinished {
    NSArray *packageArray = [[BDFlutterPackageManager sharedInstance] allValidPackages];
    for (BDPMSPackage *package in packageArray) {
        [self findAndCreateModelWithPackage:package];
    }
            
    if (_dataList.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableView reloadData];
        });
    }
}

#pragma mark - Package Event

- (void)downloadProgress:(BDPMSPackage *)package progress:(double)progress {
    if (package.type == 1) {
        return;
    }
    
    FlutterAppModel *model = [self findAndCreateModelWithPackage:package];
    model.updateVersion = package.version;
    if (model.version == package.version) {
        model.version = -1;
    }
    
    model.updateProgress = progress;
    if (model.updateStatus != UpdateStatusDownloading) {
        model.updateStatus = UpdateStatusDownloading;
        [_tableView reloadData];
    }
    else {
        model.updateStatus = UpdateStatusDownloading;
        NSIndexPath *index = [NSIndexPath indexPathForRow:model.index inSection:0];
        FlutterAppTableViewCell *cell = [_tableView cellForRowAtIndexPath:index];
        [cell setNeedsLayout];
    }
}

- (void)didFinish:(BOOL)success package:(BDPMSPackage *)package error:(NSError *)error {
    if (!package) {
        return;
    }
    
    if (package.type == 1) {
        return;
    }
    
    
    if (success) {
        FlutterAppModel *model = [self findAndCreateModelWithPackage:package];
        model.version = package.version;
        model.updateStatus = UpdateStatusNone;
        model.updateVersion = -1;
        model.updateProgress = 0;
        model.package = package;
        NSIndexPath *index = [NSIndexPath indexPathForRow:model.index inSection:0];
        [[_tableView cellForRowAtIndexPath:index] setNeedsLayout];
    }
    else {
        FlutterAppModel *model = [self findModelWithPackage:package];
        if (model) {
            if (model.version >= 0) {
                model.updateStatus = UpdateStatusFailed;
                model.updateProgress = 0;
                NSIndexPath *index = [NSIndexPath indexPathForRow:model.index inSection:0];
                [[_tableView cellForRowAtIndexPath:index] setNeedsLayout];
            }
            else {
                [_dataList removeObject:model];
                [_tableView reloadData];
            }
        }
    }
}


@end

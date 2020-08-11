#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "DemoViewController.h"
#import <BDPackageManagerService/BDPackageManagerService.h>
#import <BDFlutterPackageManager/BDFlutterPackageManager.h>
#import "TTNetworkManager.h"
#import "RoutePluginProtocolImplement.h"
#import "DynamicRouteProtocolImplement.h"
#import <IESVideoPlayer/IESVideoPlayer.h>
#import <AWEVideoPlayer/AWEVideoDiskCacheConfiguration.h>
#import <FlutterVideoPlayerPluginConfiguration.h>
#import <CommonCrypto/CommonDigest.h>
#import <TTBridgeUnify/TTBridgeUnify.h>
#import "BDSFlutterBridgePlugin.h"
#import <Flutter/Flutter.h>
#import "FlutterManager.h"
#import "HMDTTMonitor.h"
#import "Heimdallr.h"
#define REGISTER_BRIDGE(name)

extern BOOL FlutterRecreateSurfaceWhenReceiveMemorying;

@interface NSString (MD5)

- (NSString *)MD5HashString;

@end

@implementation NSString(MD5)

- (NSString *)MD5HashString
{
    const char *str = [self UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (int)strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [FlutterViewController setRecreateSurfaceWhenReceiveMemorying:YES];
    UIViewController *rootVC = [[DemoViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = nav;
    [UIApplication sharedApplication].delegate.window = window;
    [window makeKeyWindow];
    [self initEnv];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)initEnv {
    [self initVessel];

    [self initNetwork];
    [self initPackage];
    [self initRouteApp];
    [self initVideo];
    [self initBridge];
}

- (void)initVessel {
    HMDInjectedInfo *info = [HMDInjectedInfo defaultInfo];
    info.appID = @"99998";
    [[Heimdallr shared] setupWithInjectedInfo:info];
    
}

- (void)initNetwork {
    // Network
    [TTNetworkManager setMonitorBlock:^(NSDictionary *data, NSString *logType) {
    }];
        
    [TTNetworkManager setLibraryImpl:TTNetworkManagerImplTypeLibChromium];
    [TTNetworkManager setCityName:@"Beijing"];
    [[TTNetworkManager shareInstance] setCommonParamsblock:^NSDictionary<NSString *,NSString *> *{
        return @{};
    }];
    
    [TTNetworkManager shareInstance].ServerConfigHostFirst = @"dm.toutiao.com";
    [TTNetworkManager shareInstance].ServerConfigHostSecond = @"dm.bytedance.com";
    [TTNetworkManager shareInstance].ServerConfigHostThird = @"dm-hl.toutiao.com";
    [[TTNetworkManager shareInstance] setDomainBase:@"ib.snssdk.com"];
    [[TTNetworkManager shareInstance] setDomainLog:@"log.snssdk.com"];
    [[TTNetworkManager shareInstance] setDomainMon:@"mon.snssdk.com"];
    [[TTNetworkManager shareInstance] setDomainSec:@"security.snssdk.com"];
    [[TTNetworkManager shareInstance] setDomainChannel:@"ichannel.snssdk.com"];
    [[TTNetworkManager shareInstance] setDomainISub:@"isub.snssdk.com"];
    

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:2];
    [result setValue:@"71884993507" forKey:@"iid"];
    [result setValue:@"WIFI" forKey:@"ac"];
    [result setValue:@"62449453-CABA-4A09-8800-547805384EA0" forKey:@"vid"];
    [result setValue:@"67715241007" forKey:@"device_id"];
    [result setValue:@"34B2D505-527E-4C12-A454-70AE09DDC7F3" forKey:@"idfa"];
    [result setValue:@"62449453-CABA-4A09-8800-547805384EA0" forKey:@"idfv"];
    [result setValue:@"1125*2436" forKey:@"resolution"];
    [result setValue:@"1.7.8" forKey:@"version_code"];
    [result setValue:@"1780" forKey:@"update_version_code"];
    [result setValue:@"local_test" forKey:@"channel"];
    [result setValue:@"super" forKey:@"app_name"];
    [result setValue:@"1319" forKey:@"aid"];
    [result setValue:@"iphone" forKey:@"device_platform"];
    [result setValue:[UIDevice currentDevice].systemVersion forKey:@"os_version"];
    [result setValue:@"iPhone X" forKey:@"device_type"];
    [result setValue:@"96c66f36f396c278e006b79d4eccce4a9ef4c9ec" forKey:@"openudid"];
    [TTNetworkManager shareInstance].commonParamsblock = ^(){
        return [result copy];
    };

    [[TTNetworkManager shareInstance] start];
}

- (void)initVideo {
    // Video
    [IESVideoPlayerConfig setUserKey:@"tt_shortvideo" secretKey:@"1fd5db12db3d3992d4400e1559f720d4"];
    [IESVideoPlayerConfig setCommonParamBlock:^NSDictionary * {
        NSMutableDictionary *commonParams = [NSMutableDictionary dictionary];
        [commonParams setValue:[[UIDevice currentDevice] systemVersion] forKey:@"os_version"];
        return [commonParams copy];
    }];

    [IESVideoPlayerConfig setCacheKeyParserBlock:^NSString *(NSString *url) {
        return [url MD5HashString];
    }];
    // 单位为MB
    NSInteger limitCache = 100;
    [IESVideoPlayerConfig setCacheSizeLimit:limitCache];
    [AWEVideoDiskCacheConfiguration sharedInstance].autoTrimInterval = 10 * 60;
    [FlutterVideoPlayerPluginConfiguration sharedInstance].videoPlayerType = FlutterVideoPlayerTypeOwn;
    [FlutterVideoPlayerPluginConfiguration sharedInstance].ownPlayerSupportReplayAfterStop = YES;
    [FlutterVideoPlayerPluginConfiguration sharedInstance].instanceCommonConfigBlock = ^(id<IESVideoPlayerProtocol>  _Nonnull player) {
        player.tag = @"tt_video_player_demo";//demo配置
    };
}

- (void)initPackage {
    // SaveU
    BDPMSConfig *config = [[BDPMSConfig alloc] init];
    config.aid = @"99998";
    config.channel = @"local_test";
    config.deviceId = @"12345678900";
    [[BDPMSManager sharedInstance] setConfig:config];
    [[BDFlutterPackageManager sharedInstance] loadPackagesWithCallback:^(BOOL success) {
        NSLog(@"BDFlutterPackageManager初始化%@", success ? @"成功" : @"失败");
    }];
}

- (void)initRouteApp {
    [[FlutterManager sharedManager] setReleaseDartVMEnabled:YES];
    [[FlutterManager sharedManager] setAutoDestroyFlutterContext:YES];
    [RouteAppPlugin registerWithPluginProtocols:@[[RoutePluginProtocolImplement class], [DynamicRouteProtocolImplement class]]];
}

- (void)initBridge {
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, getUserInfo), @"shrimp.user.getMyUserInfo");
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, notifyUserChanged), @"shrimp.user.notifyUserChanged");
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, login), @"shrimp.user.login");
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, logout), @"shrimp.user.logout");
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, hasLogin), @"shrimp.user.hasLogin");
    
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, testMethod), @"shrimp.feed.testMethod");
    
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, getPlayProgress), @"shrimp.video.getPlayProgress");
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, setPlayProgress), @"shrimp.video.setPlayProgress");
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, getPlayConfig), @"shrimp.video.getPlayConfig");
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, getAllProgress), @"shrimp.video.getAllProgress");
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, getSharePlatform), @"shrimp.video.getSharePlatform");
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, shareToPlatform), @"shrimp.video.shareToPlatform");
    
    TTRegisterAllBridge(TTClassBridgeMethod(BDSFlutterBridgePlugin, showToast), @"shrimp.toast.showToast");
}

@end

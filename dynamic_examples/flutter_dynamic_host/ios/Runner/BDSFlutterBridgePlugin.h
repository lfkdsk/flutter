//
//  BDSFlutterBridgePlugin.h
//  Runner
//
//  Created by 白昆仑 on 2019/8/26.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <TTBridgeUnify/TTBridgeRegister.h>


@interface BDSFlutterBridgePlugin : TTBridgePlugin

TT_BRIDGE_EXPORT_HANDLER(getUserInfo);
TT_BRIDGE_EXPORT_HANDLER(notifyUserChanged);
TT_BRIDGE_EXPORT_HANDLER(login);
TT_BRIDGE_EXPORT_HANDLER(logout);
TT_BRIDGE_EXPORT_HANDLER(hasLogin);

TT_BRIDGE_EXPORT_HANDLER(testMethod);

TT_BRIDGE_EXPORT_HANDLER(getPlayProgress);
TT_BRIDGE_EXPORT_HANDLER(setPlayProgress);
TT_BRIDGE_EXPORT_HANDLER(getPlayConfig);
TT_BRIDGE_EXPORT_HANDLER(getAllProgress);
TT_BRIDGE_EXPORT_HANDLER(getSharePlatform);
TT_BRIDGE_EXPORT_HANDLER(shareToPlatform);

TT_BRIDGE_EXPORT_HANDLER(showToast);

@end

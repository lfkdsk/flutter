package io.flutter.demo.gallery;

import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import com.bytedance.crash.ICommonParams;
import com.bytedance.crash.Npth;
import com.bytedance.flutter.dynamicart.Dynamicart;
import com.bytedance.news.common.service.manager.ServiceManager;
import com.bytedance.news.common.settings.SettingsConfig;
import com.bytedance.news.common.settings.SettingsConfigProvider;
import com.bytedance.news.common.settings.api.RequestService;
import com.bytedance.news.common.settings.api.Response;
import com.bytedance.routeapp.INativeRouteHandler;
import com.bytedance.routeapp.RouteAppPlugin;
import com.bytedance.sdk.bridge.flutter.FlutterBridgeManager;
import com.bytedance.ttnet.TTNetInit;
import com.ss.android.dynamicart.homepage.HomepageActivity;
import com.ss.android.dynamicart.homepage.MyAdapter;
import com.ss.android.image.FrescoUtils;
import com.ss.android.socialbase.downloader.downloader.Downloader;
import com.ss.android.socialbase.downloader.downloader.DownloaderBuilder;

import java.util.List;
import java.util.Map;

import io.flutter.shrimp.CommonPluginBridge;
import io.flutter.shrimp.FeedEventChannel;
import io.flutter.shrimp.FeedPluginBridge;
import io.flutter.shrimp.SettingsPluginBridge;
import io.flutter.shrimp.UserEventChannel;
import io.flutter.shrimp.UserPluginBridge;
import io.flutter.shrimp.VideoPluginBridge;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterTextureView;

/**
 * Created by Xie Ran on 2019-07-23.
 * Email:xieran.sai@bytedance.com
 */
public class MyApplication extends Application {

    private static MyApplication sApplication;

    public static MyApplication instance() {
        return sApplication;
    }

    @Override
    protected void attachBaseContext(Context base) {
        super.attachBaseContext(base);
        sApplication = this;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        initSettings();
        FlutterMain.startInitialization(this);
        Downloader.init(new DownloaderBuilder(this));
        Dynamicart.init(new DynamicartAdapterImpl());
        TTNetInit.setTTNetDepend(new TTNetDependImpl());
        TTNetInit.tryInitTTNet(this, this, new TTNetApiProcessHook(), null, null, true);
        FrescoUtils.initFrescoLib(this, false);
        initRouteApp();
        initBridgeSDK();
        initHomepage();
        initNpth();
    }

    private void initSettings() {
        ServiceManager.registerService(SettingsConfigProvider.class, new SettingsConfigProvider() {
            @Override
            public SettingsConfig getConfig() {
                return new SettingsConfig.Builder()
                        .context(MyApplication.this)
                        .requestService(new RequestService() {
                            @Override
                            public Response request() {
                                return null;
                            }
                        })
                        .build();
            }
        });
    }

    private void initNpth() {
        Npth.init(this, new ICommonParams() {
            @Override
            public Map<String, Object> getCommonParams() {
                return null;
            }

            @Override
            public String getDeviceId() {
                return null;
            }

            @Override
            public long getUserId() {
                return 0;
            }

            @Override
            public String getSessionId() {
                return null;
            }

            @Override
            public Map<String, Integer> getPluginInfo() {
                return null;
            }

            @Override
            public List<String> getPatchInfo() {
                return null;
            }
        });
    }

    private void initRouteApp() {
        RouteAppPlugin.init(new INativeRouteHandler() {
            @Override
            public void handleNativeRoute(Context context, String openUrl, Map<String, Object> extraArgs) {
                Log.d("NativeRouteHandler", "openUrl:" + openUrl + "\nextraArgs:" + extraArgs);
                Intent intent;
                // 动态路由处理
                if ((intent = RouteUtils.createIntent(context, openUrl, extraArgs)) != null) {
                    context.startActivity(intent);
                } else {
                    intent = new Intent(context, HomepageActivity.class);
                    context.startActivity(intent);
                    Toast.makeText(context, "该路由无法处理，跳到主页：" + openUrl, Toast.LENGTH_SHORT).show();
                }
            }
        });
        RouteAppPlugin.addFlutterViewListener(new RouteAppPlugin.IFlutterViewListener() {
            @Override
            public void onFlutterViewCreated(String viewToken, FlutterTextureView view) {

            }

            @Override
            public void onFlutterViewDestroyed(String viewToken, FlutterTextureView view) {
                Dynamicart.markPluginIsReleased(viewToken);
            }
        });
    }

    private void initBridgeSDK() {
        FlutterBridgeManager.INSTANCE.registerFlutterGlobalBridge(new CommonPluginBridge());
        FlutterBridgeManager.INSTANCE.registerFlutterGlobalBridge(new FeedPluginBridge());
        FlutterBridgeManager.INSTANCE.registerFlutterGlobalBridge(new SettingsPluginBridge());
        FlutterBridgeManager.INSTANCE.registerFlutterGlobalBridge(new UserPluginBridge());
        FlutterBridgeManager.INSTANCE.registerFlutterGlobalBridge(new VideoPluginBridge());
        RouteAppPlugin.addFlutterViewListener(new RouteAppPlugin.IFlutterViewListener() {
            @Override
            public void onFlutterViewCreated(String viewToken, FlutterTextureView view) {
                if (viewToken.equals("BDSFlutter")) {
                    UserPluginBridge.Companion.setEventChannel(new UserEventChannel(view.getPluginRegistry()));
                    FeedPluginBridge.Companion.setEventChannel(new FeedEventChannel(view.getPluginRegistry()));
                }
            }

            @Override
            public void onFlutterViewDestroyed(String viewToken, FlutterTextureView view) {
                if (viewToken.equals("BDSFlutter")) {
                    UserPluginBridge.Companion.setEventChannel(null);
                    FeedPluginBridge.Companion.setEventChannel(null);
                }
            }
        });
    }

    private void initHomepage() {
        MyAdapter.setOnItemClickListener(new MyAdapter.OnDynamicItemClickListener() {
            @Override
            public void onOpenHostClick(Context context) {
                Intent intent = new Intent(context, CommonRouteActivity.class);
                context.startActivity(intent);
            }

            @Override
            public void onOpenPresetClick(Context context, String dynamicDillPath) {
                Intent intent = new Intent(context, CommonRouteActivity.class);
                intent.putExtra("dynamic_dill_path", dynamicDillPath);
                intent.putExtra("viewToken", "PresetTest");
                context.startActivity(intent);
            }

            @Override
            public void onOpenRouteClick(Context context, String route) {
                Intent intent = RouteUtils.createIntent(context, route, null);
                if (intent == null) {
                    Toast.makeText(context, "打开路由失败：" + route, Toast.LENGTH_SHORT).show();
                } else {
                    context.startActivity(intent);
                }
            }

            @Override
            public void onOpenItemClick(Context context, String pluginName, String route, String dynamicDillPath) {
                if (TextUtils.isEmpty(route)) {
                    Intent intent = new Intent(context, CommonRouteActivity.class);
                    intent.putExtra("dynamic_dill_path", dynamicDillPath);
                    intent.putExtra("viewToken", pluginName);
                    context.startActivity(intent);
                } else {
                    onOpenRouteClick(context, route);
                }
            }

        });
    }
}

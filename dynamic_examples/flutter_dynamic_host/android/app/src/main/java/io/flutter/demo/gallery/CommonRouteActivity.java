package io.flutter.demo.gallery;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Bundle;


import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.bytedance.flutter.vessel.route.v2.DynamicFlutterActivity;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.GeneratedPluginRegistrant;

/**
 * Created by Xie Ran on 2019-08-14.
 * Email:xieran.sai@bytedance.com
 */
public class CommonRouteActivity extends DynamicFlutterActivity {

    @Override
    protected void onRegisterPlugins(FlutterEngine flutterEngine, PluginRegistry pluginRegistry) {
        GeneratedPluginRegistrant.registerWith(flutterEngine, pluginRegistry);
        AdsLandingPagePlugin2.registerWith(pluginRegistry);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        getIntent().putExtra("disable-service-auth-codes ", true);
        getIntent().putExtra("trace-systrace", true);
        super.onCreate(savedInstanceState);
        requestPermissions();
    }

    private void requestPermissions() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED || ContextCompat.checkSelfPermission(this,
                Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE}, 0);
        }
    }

    @Override
    public void onPointerCaptureChanged(boolean hasCapture) {

    }
}

class AdsLandingPagePlugin2 implements MethodChannel.MethodCallHandler {
    /** Plugin registration. */
    public static void registerWith(PluginRegistry pluginRegistry) {
        PluginRegistry.Registrar registrar = pluginRegistry.registrarFor("io.flutter.demo.gallery.AdsLandingPagePlugin2");
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "ads_landing_page");
        channel.setMethodCallHandler(new AdsLandingPagePlugin2());
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "getPhoneMask":
                Map<String, String> maskMap = new HashMap();
                maskMap.put("mask", "136****6895");
                maskMap.put("from", "移动");
                result.success(maskMap);
                break;
            case "getPhoneToken":
                Map<String, String> tokenMap = new HashMap();
                tokenMap.put("token", "token123456");
                tokenMap.put("from", "移动");
                result.success(tokenMap);
                break;
            default:
                result.notImplemented();
                break;
        }
    }
}

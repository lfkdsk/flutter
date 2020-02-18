package io.flutter.shrimp;

import android.os.Bundle;
import android.util.Log;

import io.flutter.shrimp.BDSFlutterActivity;

import io.flutter.plugin.common.PluginRegistry;

public class FlutterDemoActivity extends BDSFlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.e("FlutterDemoActivity","FlutterDemoActivity = "+this+"|flutterView="+getFlutterView().getPluginRegistry());
        new SettingPluginPresenter();
        new UserPluginPresenter();
        if (alreadyRegisteredWith(this)) {
            return;
        }
    }

    private boolean alreadyRegisteredWith(PluginRegistry registry) {
        String key = FlutterDemoActivity.class.getName();
        if (registry.hasPlugin(key)) {
            return true;
        }
        registry.registrarFor(key);
        return false;
    }

}

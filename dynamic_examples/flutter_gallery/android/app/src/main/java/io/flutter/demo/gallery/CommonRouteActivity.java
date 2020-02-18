package io.flutter.demo.gallery;

import android.os.Bundle;

import com.bytedance.routeapp.FlutterRouteActivity;

import io.flutter.plugins.GeneratedPluginRegistrant;

/**
 * Created by Xie Ran on 2019-08-14.
 * Email:xieran.sai@bytedance.com
 */
public class CommonRouteActivity extends FlutterRouteActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);
    }

    @Override
    protected boolean useLaunchTransition() {
        return true;
    }

}

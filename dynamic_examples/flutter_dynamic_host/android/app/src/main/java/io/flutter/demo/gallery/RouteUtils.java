package io.flutter.demo.gallery;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.text.TextUtils;

import com.bytedance.flutter.dynamicart.Dynamicart;
import com.bytedance.flutter.vessel.route.DynamicRouteHelper;
import com.bytedance.flutter.vessel.route.RouteConstants;

import java.util.HashMap;
import java.util.Map;


/**
 * Created by Xie Ran on 2019-08-21.
 * Email:xieran.sai@bytedance.com
 */
public class RouteUtils {

    public static final String HOST_SCHEME = "default-flutter";
    public static final String DYNAMIC_SCHEME = "local-flutter";

    static {
        sDynamicRouteHelper = new DynamicRouteHelper(CommonRouteActivity.class, new DynamicRouteHelper.IntentInterceptor() {
            @Override
            public void interceptIntent(@NonNull Intent intent, @NonNull Context context,
                    @Nullable String pluginName, @Nullable String path, @Nullable Map<String, Object> params) {
            }
        }, new DynamicRouteHelper.KernelAppPathGetter() {
            @Override
            public String getKernelAppPath(String pluginName) {
                return Dynamicart.getKernelAppPath(pluginName);
            }
        });
    }

    private static DynamicRouteHelper sDynamicRouteHelper;

    public static Intent createIntent(Context context, String openUrl, Map<String, Object> extraArgs) {
        return sDynamicRouteHelper.createIntent(context, openUrl, extraArgs);
    }

    private static HashMap<String, Object> createParams(@NonNull Uri uri, @Nullable Map<String, Object> extraArgs) {
        HashMap<String, Object> params = null;
        if (extraArgs != null) {
            params = new HashMap<>(extraArgs);
        }
        for (String parameterName: uri.getQueryParameterNames()) {
            if (params == null) {
                params = new HashMap<>();
            }
            params.put(parameterName, uri.getQueryParameter(parameterName));
        }
        return params;
    }
}

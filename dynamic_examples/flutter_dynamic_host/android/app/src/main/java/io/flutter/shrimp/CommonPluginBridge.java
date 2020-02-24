package io.flutter.shrimp;

import android.os.Build;

import com.bytedance.sdk.bridge.annotation.BridgeMethod;
import com.bytedance.sdk.bridge.annotation.BridgeParam;
import com.bytedance.sdk.bridge.annotation.BridgePrivilege;
import com.bytedance.sdk.bridge.annotation.BridgeSyncType;
import com.bytedance.sdk.bridge.model.BridgeResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by Xie Ran on 2019-08-20.
 * Email:xieran.sai@bytedance.com
 */
public class CommonPluginBridge {

    interface IPathMethodHandler {
        String getPath(String key);
    }

    interface ISettingsMethodHandler {
        Object getSettings(String key, Object defaultValue);
    }

    private static IPathMethodHandler sPathMethodHandler;
    private static ISettingsMethodHandler sSettingsMethodHandler;

    public static void setPathMethodHandler(IPathMethodHandler pathMethodHandler) {
        sPathMethodHandler = pathMethodHandler;
    }

    public static void setSettingsMethodHandler(ISettingsMethodHandler settingsMethodHandler) {
        sSettingsMethodHandler = settingsMethodHandler;
    }


    @BridgeMethod(value ="shrimp.common.getPlatformVersion", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    BridgeResult getPlatformVersion() {
        JSONObject res = new JSONObject();
        try {
            res.put("result", Build.VERSION.RELEASE);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return BridgeResult.Companion.createSuccessResult(res);
    }

    @BridgeMethod(value ="shrimp.common.getPath", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    BridgeResult getPath(@BridgeParam("key") String key) {
        JSONObject res = new JSONObject();
        if (sPathMethodHandler != null) {
            try {
                res.put("result", sPathMethodHandler.getPath(key));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return BridgeResult.Companion.createSuccessResult(res);
    }

    @BridgeMethod(value ="shrimp.common.getSettings", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    BridgeResult getSettings(@BridgeParam("key") String key, @BridgeParam("type") String type) {
        JSONObject res = new JSONObject();
        if (sSettingsMethodHandler != null) {
            try {
                if ("JSONArray".equals(type)) {
                    Object result = sSettingsMethodHandler.getSettings(key, new JSONArray());
                    if (result != null) {
                        res.put("result",result.toString());
                    }
                } else if ("JSONObject".equals(type)) {
                    Object result = sSettingsMethodHandler.getSettings(key, new JSONObject());
                    if (result != null) {
                        res.put("result",result.toString());
                    }
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return BridgeResult.Companion.createSuccessResult(res);
    }
}

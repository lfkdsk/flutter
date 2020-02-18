package io.flutter.shrimp;

import com.bytedance.sdk.bridge.annotation.BridgeMethod;
import com.bytedance.sdk.bridge.annotation.BridgeParam;
import com.bytedance.sdk.bridge.annotation.BridgePrivilege;
import com.bytedance.sdk.bridge.annotation.BridgeSyncType;
import com.bytedance.sdk.bridge.model.BridgeResult;
import com.ss.android.common.util.json.JsonUtil;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Map;

/**
 * Created by Xie Ran on 2019-08-20.
 * Email:xieran.sai@bytedance.com
 */
public class VideoPluginBridge {

    interface IVideoPluginMethodCallHandler {

        Map<Integer, Long> getAllPlayProgress();

        Map<Object, Object> getPlayConfig();

        void setPlayProgress(String videoId, long progress);

        long getPlayProgress(String videoId);

        boolean setVideoModel(String videoModel);

        Map<String, Object> getPlayStatusBeforeRelease(String videoId);

        void setScreenOn(boolean screenOn);

    }

    private static IVideoPluginMethodCallHandler sMethodCallHandler;

    public static void setMethodCallHandler(IVideoPluginMethodCallHandler handler) {
        sMethodCallHandler = handler;
    }

    @BridgeMethod(value ="shrimp.video.getPlayProgress", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    BridgeResult getPlayProgress(@BridgeParam("vid") String vid) {
        JSONObject res = new JSONObject();
        if (sMethodCallHandler != null) {
            try {
                res.put("result", sMethodCallHandler.getPlayProgress(vid));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return BridgeResult.Companion.createSuccessResult(res);
    }

    @BridgeMethod(value ="shrimp.video.setPlayProgress", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    BridgeResult setPlayProgress(@BridgeParam("vid") String vid, @BridgeParam("progress") long progress) {
        if (sMethodCallHandler != null) {
            sMethodCallHandler.setPlayProgress(vid, progress);
        }
        return BridgeResult.Companion.createSuccessResult(null);
    }

    @BridgeMethod(value ="shrimp.video.getPlayConfig", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    BridgeResult getPlayConfig() {
        JSONObject res = new JSONObject();
        if (sMethodCallHandler != null) {
            try {
                res.put("result", JsonUtil.toJson(sMethodCallHandler.getPlayConfig()));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return BridgeResult.Companion.createSuccessResult(res);
    }

    @BridgeMethod(value ="shrimp.video.getAllProgress", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    BridgeResult getAllProgress() {
        JSONObject res = new JSONObject();
        if (sMethodCallHandler != null) {
            try {
                res.put("result", JsonUtil.toJson(sMethodCallHandler.getAllPlayProgress()));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return BridgeResult.Companion.createSuccessResult(res);
    }

    @BridgeMethod(value ="shrimp.video.setVideoModel", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    BridgeResult setVideoModel(@BridgeParam("video_model") String videoModel) {
        JSONObject res = new JSONObject();
        if (sMethodCallHandler != null) {
            try {
                res.put("result", sMethodCallHandler.setVideoModel(videoModel));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return BridgeResult.Companion.createSuccessResult(res);
    }

    @BridgeMethod(value ="shrimp.video.getPlayStatus", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    BridgeResult getPlayStatus(@BridgeParam("vid") String vid) {
        JSONObject res = new JSONObject();
        if (sMethodCallHandler != null) {
            try {
                res.put("result", JsonUtil.toJson(sMethodCallHandler.getPlayStatusBeforeRelease(vid)));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return BridgeResult.Companion.createSuccessResult(res);
    }

    @BridgeMethod(value ="shrimp.video.setScreenOn", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    BridgeResult setScreenOn(@BridgeParam("screen_on") boolean screenOn) {
        if (sMethodCallHandler != null) {
            sMethodCallHandler.setScreenOn(screenOn);
        }
        return BridgeResult.Companion.createSuccessResult(null);
    }
}

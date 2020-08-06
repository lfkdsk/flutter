package io.flutter.demo.gallery;

import android.content.Context;
import android.location.Address;

import com.bytedance.ttnet.ITTNetDepend;

import org.json.JSONObject;

import java.util.LinkedHashMap;
import java.util.Map;

import okhttp3.OkHttpClient;
import okhttp3.Request;

/**
 * Created by Xie Ran on 2019-07-24.
 * Email:xieran.sai@bytedance.com
 */
public class TTNetDependImpl implements ITTNetDepend {
    @Override
    public Context getContext() {
        return MyApplication.instance();
    }

    @Override
    public boolean isCronetPluginInstalled() {
        return true;
    }

    @Override
    public boolean isPrivateApiAccessEnabled() {
        return false;
    }

    @Override
    public void mobOnEvent(Context context, String eventName, String labelName, JSONObject extraJson) {

    }

    @Override
    public void onNetConfigUpdate(JSONObject config, boolean localData) {

    }

    @Override
    public void onAppConfigUpdated(Context context, JSONObject ext_json) {

    }

    @Override
    public Address getLocationAdress(Context context) {
        return null;
    }

    @Override
    public String executeGet(int maxLength, String url) throws Exception {
        return new OkHttpClient().newCall(new Request.Builder().url(url).build()).execute().body().string();
    }

    @Override
    public int checkHttpRequestException(Throwable tr, String[] remoteIp) {
        return 0;
    }

    @Override
    public void monitorLogSend(String logType, JSONObject json) {

    }

    @Override
    public String getProviderString(Context context, String key, String defaultValue) {
        return null;
    }

    @Override
    public int getProviderInt(Context context, String key, int defaultValue) {
        return 0;
    }

    @Override
    public void saveMapToProvider(Context context, Map<String, ?> map) {

    }

    @Override
    public String[] getConfigServers() {
        return new String[]{
                "dm.toutiao.com",
                "dm.bytedance.com",
                "dm.pstatp.com"
        };
    }

    @Override
    public String getHostSuffix() {
        return ".snssdk.com";
    }

    @Override
    public String getApiIHostPrefix() {
        return "ib";
    }

    @Override
    public String getCdnHostSuffix() {
        return ".pstatp.com";
    }

    @Override
    public Map<String, String> getHostReverseMap() {
        Map<String, String> reverseMap = new LinkedHashMap<>();
//        reverseMap.put(AppConsts.API_HOST_I, "i");
//        reverseMap.put(AppConsts.API_HOST_SI, "si");
//        reverseMap.put(AppConsts.API_HOST_API, "isub");
//        reverseMap.put(AppConsts.API_HOST_SRV, "ichannel");
//        reverseMap.put(AppConsts.API_HOST_LOG, "log");
//        reverseMap.put(AppConsts.API_HOST_MON, "mon");
        return reverseMap;
    }

    @Override
    public String getShareCookieMainDomain() {
        return "";
    }

    @Override
    public void onColdStartFinish() {

    }
}

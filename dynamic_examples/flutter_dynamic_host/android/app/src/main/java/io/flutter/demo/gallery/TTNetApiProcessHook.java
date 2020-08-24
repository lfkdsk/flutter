package io.flutter.demo.gallery;

import android.util.Pair;

import com.bytedance.common.utility.NetworkUtils;
import com.bytedance.flutter.dynamicart.Dynamicart;
import com.bytedance.flutter.dynamicart.DynamicartAdapter;
import com.bytedance.frameworks.baselib.network.http.NetworkParams;
import com.bytedance.ttnet.http.HttpRequestInfo;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by Xie Ran on 2019-07-24.
 * Email:xieran.sai@bytedance.com
 */
public class TTNetApiProcessHook implements NetworkParams.ApiProcessHook<HttpRequestInfo> {
    @Override
    public void handleApiError(String url, Throwable e, long time, HttpRequestInfo info) {

    }

    @Override
    public void handleApiOk(String url, long time, HttpRequestInfo info) {

    }

    @Override
    public String addCommonParams(String url, boolean isApi) {
        StringBuilder stringBuilder = new StringBuilder(url);
        if (url.indexOf('?') < 0) {
            stringBuilder.append("?");
        } else {
            stringBuilder.append("&");
        }
        Map<String, String> params = new LinkedHashMap<>();
        putCommonParams(params, isApi);
        overrideCommonParams(url, params);
        List<Pair<String, String>> list = new ArrayList<>();
        for (Map.Entry<String, String> entry: params.entrySet()) {
            list.add(new Pair<>(entry.getKey(), entry.getValue()));
        }
        stringBuilder.append(NetworkUtils.format(list, "UTF-8"));
        return stringBuilder.toString();
    }

    @Override
    public String addRequestVertifyParams(String url, boolean isAddCommonParam, Object... extra) {
        return null;
    }

    @Override
    public void putCommonParams(Map<String, String> params, boolean isApi) {
        if (params == null) {
            return;
        }
        params.put("device_platform", "android");
        params.put("aid", "99998");
        params.put("device_id", "12345");
        params.put("app_name", "news_article");
        params.put("version_code", "101");
        params.put("update_version_code", String.valueOf(Dynamicart.getAdapter().getUpdateVersionCode()));
        params.put("channel", "local_test");
        params.put("os_version", "9");
        params.put("os_api", "28");
    }

    @Override
    public void onTryInit() {

    }

    /**
     * 处理特定Url的请求参数
     */
    private void overrideCommonParams(String url, Map<String, String> params) {
        if (url.contains("/bds/search")) {
            params.put("app_name", "super");
            params.put("aid", "1319");
        }
    }
}

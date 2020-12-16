package io.flutter.demo.gallery;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bytedance.flutter.tt_ad_flutter_plugin.AdFlutterDownloader;
import com.bytedance.flutter.tt_ad_flutter_plugin.AdModel;
import com.bytedance.flutter.tt_ad_flutter_plugin.DownloadEventNotifier;
import com.bytedance.flutter.tt_ad_flutter_plugin.TtAdFlutterPlugin;
import com.ss.android.download.api.download.DownloadController;
import com.ss.android.download.api.download.DownloadEventConfig;
import com.ss.android.download.api.download.DownloadModel;
import com.ss.android.download.api.download.DownloadStatusChangeListener;
import com.ss.android.download.api.model.DeepLink;
import com.ss.android.download.api.model.DownloadShortInfo;
import com.ss.android.downloadad.api.constant.AdBaseConstants;
import com.ss.android.downloadad.api.download.AdDownloadController;
import com.ss.android.downloadad.api.download.AdDownloadEventConfig;
import com.ss.android.downloadad.api.download.AdDownloadModel;
import com.ss.android.downloadlib.TTDownloader;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

/**
 * Created by Xie Ran on 2018/12/4.
 * Email:xieran.sai@bytedance.com
 */
public class FlutterAd {
    public static void init() {
        TtAdFlutterPlugin.init(new TtAdFlutterPlugin.CallHandler() {

            @Override
            public void onWebItemClick(Context context, Map<String, Object> rawAdDataMap,
                    Map<String, Object> androidExtras) {
                // 跳转实现
            }

            @Override
            public void showFormDialog(final Activity activity, final long adId, final String logExtra,
                    final String eventName, int formWidth, int formHeight, String formUrl) {
                // 咨询表单弹出
            }

            @Override
            public void sendTrackUrl(Context context, long adId, String logExtra, List<String> trackUrls) {
                // 发送TrackUrl
            }

            @Override
            public void requestPhoneMask(GetPhoneInfoCallback callback) {
                Map<String, String> maskMap = new HashMap<>();
                maskMap.put("mask", "136****4594");
                maskMap.put("from", "移动");
                callback.onSuccess(maskMap);
            }

            @Override
            public void requestPhoneToken(GetPhoneInfoCallback callback) {
                Map<String, String> tokenMap = new HashMap<>();
                tokenMap.put("token", "123456token");
                tokenMap.put("from", "移动");
                callback.onSuccess(tokenMap);
            }

            @Override
            public boolean tryOpenMarket(Context context, long adId, String logExtra, String appName, String url) {
                return false;
            }

            @Override
            public void tryOpenDeepLink(Context context, long adId, String logExtra, String quickAppUrl, String scheme, MethodChannel.Result result) {
                result.success(false);
            }

            @Override
            public void tryOpenH5(Context context, long adId, String logExtra, String url) {

            }

            @Override
            public boolean isDownloadInfoExisted(long adId) {
                return false;
            }
        }, new AdFlutterDownloader.DownloadHandler() {

            TTDownloader mTTDownloader = TTDownloader.inst(MyApplication.instance());

            @Override
            public void bindDownloader(Activity activity, DownloadEventNotifier notifier,
                    int token, AdModel adModel) {
                DownloadModel downloadModel = new AdDownloadModel.Builder()
                        .setAdId(adModel.adId)
                        .setLogExtra(adModel.logExtra)
                        .setPackageName(adModel.packageName)
                        .setAppName(adModel.appName)
                        .setDownloadUrl(adModel.downloadUrl)
                        .setDeepLink(new DeepLink(adModel.openUrl, adModel.webUrl, adModel.webTitle))
                        .setClickTrackUrl(adModel.clickTrackUrl)
                        .setExtra(adModel.abExtraObj)
                        .build();
                mTTDownloader.bind(activity, token, new FlutterDownloadStatusListener(notifier), downloadModel);
            }

            @Override
            public void unbindDownloader(Activity activity, int token, AdModel adModel) {
                mTTDownloader.unbind(adModel.downloadUrl, token);
            }

            @Override
            public void onButtonAction(Activity activity, int token, AdModel adModel) {
                DownloadEventConfig eventConfig =  new AdDownloadEventConfig.Builder()
                        .setClickItemTag(adModel.clickItemEventName)
                        .setClickButtonTag(adModel.clickButtonEventName)
                        .build();
                AdDownloadController controller = new AdDownloadController.Builder()
                        .setLinkMode(adModel.linkMode)
                        .setDownloadMode(adModel.downloadMode)
                        .setIsEnableMultipleDownload(adModel.supportMultiple > 1)
                        .setDowloadChunkCount(adModel.supportMultiple)
                        .setShouldUseNewWebView(adModel.adLandingPageStyle > 0)
                        .setInterceptFlag(adModel.interceptFlag)
                        .setIsEnableBackDialog(true)
                        .build();
                mTTDownloader.action(adModel.downloadUrl, adModel.adId,
                        AdBaseConstants.ACTION_TYPE_BUTTON, eventConfig, controller);
            }

            @Override
            public void onItemAction(Activity activity, int token, AdModel adModel) {
                DownloadEventConfig eventConfig =  new AdDownloadEventConfig.Builder()
                        .setClickItemTag(adModel.clickItemEventName)
                        .setClickButtonTag(adModel.clickButtonEventName)
                        .build();
                AdDownloadController controller = new AdDownloadController.Builder()
                        .setLinkMode(adModel.linkMode)
                        .setDownloadMode(adModel.downloadMode)
                        .setIsEnableMultipleDownload(adModel.supportMultiple > 1)
                        .setDowloadChunkCount(adModel.supportMultiple)
                        .setShouldUseNewWebView(adModel.adLandingPageStyle > 0)
                        .setInterceptFlag(adModel.interceptFlag)
                        .setIsEnableBackDialog(true)
                        .build();
                mTTDownloader.action(adModel.downloadUrl, adModel.adId,
                        AdBaseConstants.ACTION_TYPE_ITEM, eventConfig, controller);
            }
        });
    }

    private static class FlutterDownloadStatusListener implements DownloadStatusChangeListener {

        private DownloadEventNotifier mNotifier;

        FlutterDownloadStatusListener(DownloadEventNotifier notifier) {
            mNotifier = notifier;
        }

        @Override
        public void onIdle() {
            mNotifier.onIdle();
        }

        @Override
        public void onDownloadStart(@NonNull DownloadModel downloadModel, @Nullable DownloadController downloadController) {

        }

        @Override
        public void onDownloadActive(DownloadShortInfo shortInfo, int percent) {
            mNotifier.onActive(percent, shortInfo.currentBytes, shortInfo.totalBytes);
        }

        @Override
        public void onDownloadPaused(DownloadShortInfo shortInfo, int percent) {
            mNotifier.onPaused(percent, shortInfo.currentBytes, shortInfo.totalBytes);
        }

        @Override
        public void onDownloadFailed(DownloadShortInfo shortInfo) {
            mNotifier.onFailed();
        }

        @Override
        public void onInstalled(DownloadShortInfo shortInfo) {
            mNotifier.onInstalled();
        }

        @Override
        public void onDownloadFinished(DownloadShortInfo shortInfo) {
            mNotifier.onFinished();
        }
    }

}

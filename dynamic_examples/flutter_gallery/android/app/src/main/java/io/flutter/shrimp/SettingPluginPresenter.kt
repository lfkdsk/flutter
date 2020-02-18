package io.flutter.shrimp

import android.util.Log
import io.flutter.shrimp.SettingsPluginBridge


class SettingPluginPresenter : SettingsPluginBridge.ISettingPluginMethodCallHandler {

    init {
        SettingsPluginBridge.setSettingMethodCallHandler(this)
    }

    override fun buildSettingData(): Map<String, Any> {
        var map = mutableMapOf<String,Any>()
        map.put("appVersion","1.7.4")
        map.put("appName","皮皮虾")
        map.put("channel","local_test")
        map.put("releaseBuild","8383838")
        map.put("did","43454354354")
        map.put("manifestVersionCode","172")
        map.put("versionCode","174")
        map.put("updateVesionCode","1741")
        map.put("uid","sdfsdfd")
        map.put("isCn",true)
        map.put("isDebugEnable",false)
        map.put("hasLive",true)
        map.put("hasLogin",true)

        map.put("cacheSize",21341882)
        map.put("isWifiAutoPlay",false)
        map.put("isMobileAutoPlay",false)
        map.put("isLiveNotWifi",false)
        map.put("isNightMode",false)
        map.put("isAutoFresh",false)
        map.put("isShowNightMode",true)
        map.put("isShowTestInfo",false)
        return map
    }

    override fun checkbox(type: Int, isChecked: Boolean) {
    }

    override fun clearCache(): Long {
        return 0
    }

    override fun checkUpdate(): Int {
        return 1
    }

    override fun getWhatsNew(): String {
        return "有新版本更新"
    }

    override fun isUpdating(): Boolean {
        return false
    }

    override fun startUpdate() {
    }

    override fun handleException(e: Throwable) {
        Log.e("SettingPluginPresenter", Log.getStackTraceString(e))
    }

}
package io.flutter.shrimp

import com.bytedance.sdk.bridge.annotation.BridgeMethod
import com.bytedance.sdk.bridge.annotation.BridgeParam
import com.bytedance.sdk.bridge.annotation.BridgePrivilege
import com.bytedance.sdk.bridge.annotation.BridgeSyncType
import com.bytedance.sdk.bridge.model.BridgeResult
import io.flutter.plugin.common.JSONUtil
import org.json.JSONObject


class SettingsPluginBridge {

    interface ISettingPluginMethodCallHandler {

        fun buildSettingData(): Map<String, Any>

        fun checkbox(type: Int, isChecked: Boolean)

        fun clearCache(): Long

        fun checkUpdate(): Int

        fun getWhatsNew(): String

        fun isUpdating(): Boolean

        fun startUpdate()

        fun handleException(e: Throwable)
    }

    companion object {
        var methodCallHandler: ISettingPluginMethodCallHandler? = null

        fun setSettingMethodCallHandler(handler: ISettingPluginMethodCallHandler?) {
            methodCallHandler = handler
        }
    }

    @BridgeMethod(value = "shrimp.settings.initSetting", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun initSetting(): BridgeResult {
        try {
            val resultObj = JSONObject()
            methodCallHandler?.let {
                resultObj.put("result", JSONUtil.wrap(it.buildSettingData()) ?: JSONObject())
            }
            return BridgeResult.createSuccessResult(resultObj)
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.settings.checkbox", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun checkbox(@BridgeParam("type") type: Int?, @BridgeParam("isChecked") isChecked: Boolean?)
            : BridgeResult {
        try {
            if (type == null) {
                return BridgeResult.createParamsErrorResult("type is null")
            }

            if (isChecked == null) {
                return BridgeResult.createParamsErrorResult("isChecked is null")
            }

            methodCallHandler?.checkbox(type, isChecked)
            return BridgeResult.createSuccessResult()
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.settings.clearCache", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun clearCache(): BridgeResult {
        try {
            val resultObj = JSONObject()
            resultObj.put("result", methodCallHandler?.clearCache() ?: 0)
            return BridgeResult.createSuccessResult(resultObj)
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.settings.checkUpdate", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun checkUpdate(): BridgeResult {
        try {
            val resultObj = JSONObject()
            resultObj.put("result", methodCallHandler?.checkUpdate() ?: 0)
            return BridgeResult.createSuccessResult(resultObj)
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.settings.getWhatsNew", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun getWhatsNew(): BridgeResult {
        try {
            val resultObj = JSONObject()
            resultObj.put("result", methodCallHandler?.getWhatsNew() ?: "无新版本更新")
            return BridgeResult.createSuccessResult(resultObj)
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.settings.isUpdating", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun isUpdating(): BridgeResult {
        try {
            val resultObj = JSONObject()
            resultObj.put("result", methodCallHandler?.isUpdating() ?: false)
            return BridgeResult.createSuccessResult(resultObj)
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.settings.startUpdate", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun startUpdate(): BridgeResult {
        try {
            methodCallHandler?.startUpdate()
            return BridgeResult.createSuccessResult()
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }
}
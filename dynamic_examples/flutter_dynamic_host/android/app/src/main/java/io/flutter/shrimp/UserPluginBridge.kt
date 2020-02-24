package io.flutter.shrimp

import com.bytedance.sdk.bridge.annotation.*
import com.bytedance.sdk.bridge.model.BridgeResult
import com.bytedance.sdk.bridge.model.IBridgeContext
import org.json.JSONObject

class UserPluginBridge {

    interface IUserPluginMethodCallHandler {
        fun handleException(e: Throwable)
        fun notifyUserChanged(id: Long)
        fun login(enterFrom: String?, source: String?)
        fun logout(callback: LogoutCallback)
        fun hasLogin(): Boolean
        fun getMyUserInfo(): String?
    }

    interface LogoutCallback {
        fun onSuccess()
        fun onFailed(errorMsg: String)
    }

    companion object {
        var eventChannel: UserEventChannel? = null
        var methodCallHandler: IUserPluginMethodCallHandler? = null
        var loginPendingResult: IBridgeContext? = null

        fun onFlutterActivityResume() {
            val resultObj = JSONObject()
            resultObj.put("result", true)
            loginPendingResult?.callback(BridgeResult.createSuccessResult(resultObj))
            loginPendingResult = null
        }

        fun onFlutterActivityDestory() {
            loginPendingResult = null
        }

        fun setUserMethodCallHandler(handler: IUserPluginMethodCallHandler?) {
            methodCallHandler = handler
        }

        fun onUserChanged(userJson: String) {
            eventChannel?.onUserChanged(userJson)
        }

        fun onMyUserChanged(userJson: String) {
            eventChannel?.onMyUserChanged(userJson)
        }

        fun onHashTagChanged(hashTagJson: String) {
            eventChannel?.onHashTagChanged(hashTagJson)
        }
    }

    @BridgeMethod(value = "shrimp.user.notifyUserChanged", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun notifyUserChanged(@BridgeParam("id") id: Long?) : BridgeResult {
        try {
            id?.let {
                methodCallHandler?.notifyUserChanged(it)
            }
            return BridgeResult.createSuccessResult()
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createErrorResult(e.toString())
        }
    }

    @BridgeMethod(value = "shrimp.user.login", sync = BridgeSyncType.ASYNC, privilege = BridgePrivilege.PUBLIC)
    private fun login(@BridgeContext bridgeContext: IBridgeContext,
                      @BridgeParam("enter_from") enterFrom: String?,
                      @BridgeParam("source") source: String?) {
        try {
            methodCallHandler?.let {
                it.login(enterFrom, source)
                loginPendingResult = bridgeContext
            }
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            bridgeContext.callback(BridgeResult.createErrorResult(e.toString()))
        }
    }

    @BridgeMethod(value = "shrimp.user.hasLogin", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun hasLogin() : BridgeResult {
        try {
            val resultObj = JSONObject()
            methodCallHandler?.let {
                resultObj.put("result", it.hasLogin())
            }
            return BridgeResult.createSuccessResult(resultObj)
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createErrorResult(e.toString())
        }
    }

    @BridgeMethod(value = "shrimp.user.logout", sync = BridgeSyncType.ASYNC, privilege = BridgePrivilege.PUBLIC)
    private fun logout(@BridgeContext bridgeContext: IBridgeContext) {
        methodCallHandler?.logout(object : LogoutCallback {
            override fun onSuccess() {
                bridgeContext.callback(BridgeResult.createSuccessResult())
            }

            override fun onFailed(errorMsg: String) {
                bridgeContext.callback(BridgeResult.createErrorResult(errorMsg))
            }
        })
    }

    @BridgeMethod(value = "shrimp.user.getMyUserInfo", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun getMyUserInfo() : BridgeResult {
        try {
            val resultObj = JSONObject()
            methodCallHandler?.let {
                resultObj.put("result", it.getMyUserInfo())
            }
            return BridgeResult.createSuccessResult(resultObj)
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createErrorResult(e.toString())
        }
    }
}
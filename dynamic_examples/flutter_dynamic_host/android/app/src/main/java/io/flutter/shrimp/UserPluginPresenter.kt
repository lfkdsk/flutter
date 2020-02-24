package io.flutter.shrimp

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.shrimp.UserPluginBridge

class UserPluginPresenter: UserPluginBridge.IUserPluginMethodCallHandler {

    private val handler = Handler(Looper.getMainLooper())

    init {
        UserPluginBridge.setUserMethodCallHandler(this)
    }


    override fun hasLogin(): Boolean {
        return false
    }

    override fun handleException(e: Throwable) {
        Log.e("UserPluginPresenter", Log.getStackTraceString(e))
    }

    override fun notifyUserChanged(id: Long) {
    }

    override fun login(enterFrom: String?, source: String?) {
        handler.postDelayed({
            UserPluginBridge.onFlutterActivityResume()
        }, 2000)
    }

    override fun logout(callback: UserPluginBridge.LogoutCallback) {
        handler.postDelayed({
            callback.onSuccess()
        }, 2000)
    }

    override fun getMyUserInfo(): String? {
        return null
    }

}
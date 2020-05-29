package io.flutter.shrimp

import io.flutter.plugin.common.PluginRegistry

class UserEventChannel(private val pluginRegistry: PluginRegistry) {

    companion object {
        const val USER_EVENT_CHANNEL_NAME = "bds_user_event_channel"
        const val EVENT_NAME_USER_CHANGED = "user_changed"
        const val EVENT_NAME_MY_USER_CHANGED = "my_user_changed"
        const val EVENT_NAME_LOGIN_CHANGED = "login_changed"
        const val EVENT_NAME_HASHTAG_CHANGED = "hashtag_changed"
    }

    fun onUserChanged(userJson: String) {
        var map = HashMap<String,String>()
        map[EVENT_NAME_USER_CHANGED] = userJson
//        BridgeOnPlugin.getPluginFromPluginRegistry(pluginRegistry).on(USER_EVENT_CHANNEL_NAME, JSONUtil.wrap(map) as JSONObject?)
    }

    fun onMyUserChanged(userJson: String) {
        var map = HashMap<String,String>()
        map[EVENT_NAME_MY_USER_CHANGED] = userJson
//        BridgeOnPlugin.getPluginFromPluginRegistry(pluginRegistry).on(USER_EVENT_CHANNEL_NAME, JSONUtil.wrap(map) as JSONObject?)
    }

    fun onHashTagChanged(hashTagJson: String) {
        var map = HashMap<String, String>()
        map[EVENT_NAME_HASHTAG_CHANGED] = hashTagJson
//        BridgeOnPlugin.getPluginFromPluginRegistry(pluginRegistry).on(USER_EVENT_CHANNEL_NAME, JSONUtil.wrap(map) as JSONObject?)
    }

}
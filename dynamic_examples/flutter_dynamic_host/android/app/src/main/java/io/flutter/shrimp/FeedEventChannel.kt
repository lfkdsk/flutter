package io.flutter.shrimp

import io.flutter.plugin.common.PluginRegistry

class FeedEventChannel(private val pluginRegistry: PluginRegistry) {

    companion object {
        const val USER_EVENT_CHANNEL_NAME = "bds_feed_event_channel"
        const val EVENT_NAME_FEED_CHANGED = "feed_changed"
        const val EVENT_NAME_FEED_GOD_COMMENT_CHANGED = "feed_god_comment_changed"
    }

    fun onFeedDataChanged(cellId: Long, cellType: Int, parentId: Long, actionType: Int) {
        var map = HashMap<String, HashMap<String, Any>>()
        var dataMap = HashMap<String, Any>()
        dataMap["cell_id"] = cellId
        dataMap["cell_type"] = cellType
        dataMap["action_type"] = actionType
        dataMap["parent_id"] = parentId
        map[EVENT_NAME_FEED_CHANGED] = dataMap
//        BridgeOnPlugin.getPluginFromPluginRegistry(pluginRegistry).on(USER_EVENT_CHANNEL_NAME, JSONUtil.wrap(dataMap) as JSONObject?)
    }

    fun onFeedGodCommentChanged(cellId: Long, cellType: Int, commentId: Long, commentType: Int, actionType: Int) {
        var map = HashMap<String, HashMap<String, Any>>()
        var dataMap = HashMap<String, Any>()
        dataMap["cell_id"] = cellId
        dataMap["cell_type"] = cellType
        dataMap["action_type"] = actionType
        dataMap["comment_id"] = commentId
        dataMap["comment_type"] = commentType
        map[EVENT_NAME_FEED_GOD_COMMENT_CHANGED] = dataMap
//        BridgeOnPlugin.getPluginFromPluginRegistry(pluginRegistry).on(USER_EVENT_CHANNEL_NAME, JSONUtil.wrap(dataMap) as JSONObject?)
    }
}
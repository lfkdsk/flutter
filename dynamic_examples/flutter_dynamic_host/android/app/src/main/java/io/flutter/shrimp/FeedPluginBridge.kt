package io.flutter.shrimp

import android.graphics.Rect
import com.bytedance.sdk.bridge.annotation.BridgeMethod
import com.bytedance.sdk.bridge.annotation.BridgeParam
import com.bytedance.sdk.bridge.annotation.BridgePrivilege
import com.bytedance.sdk.bridge.annotation.BridgeSyncType
import com.bytedance.sdk.bridge.model.BridgeResult
import io.flutter.plugin.common.JSONUtil
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class FeedPluginBridge {

    interface IFeedPluginMethodCallHandler {
        fun handleException(e: Throwable)
        fun notifyFeedDataChanged(cellId: Long, cellType: Int, flutterActionType: Int)
        fun notifyFeedCommentDataChanged(cellId: Long, cellType: Int, commentId: Long, commentType: Int, flutterActionType: Int)
        fun showSharePanel(cellId: Long, cellType: Int, feedJson: String, enterFrom: String?, source: String?, logExtra: Map<String, Any>)
        fun getLastShareletType(): String
        fun getSharePlatform(): List<String>
        fun shareToPlatform(shareModel: String, platform: String, logExtra: Map<String, Any>)
        fun gotoVideoPlay(itemId: Long, commentId: Long, content: String, rect: Rect, videoModelJson: String, downloadModelJson: String, logExtra: Map<String, Any>)
    }

    companion object {

        var eventChannel: FeedEventChannel? = null
        var methodCallHandler: IFeedPluginMethodCallHandler? = null

        fun setFeedMethodCallHandler(handler: IFeedPluginMethodCallHandler?) {
            methodCallHandler = handler
        }

        fun onFeedChanged(cellId: Long, cellType: Int, parentId: Long, actionType: Int) {
            eventChannel?.onFeedDataChanged(cellId, cellType, parentId, actionType)
        }

    }

    @BridgeMethod(value = "shrimp.feed.getSharePlatform", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun getSharePlatform(): BridgeResult {
        try {
            val resultObj = JSONObject()
            methodCallHandler?.let {
                resultObj.put("result", JSONUtil.wrap(it.getSharePlatform()))
            }
            return BridgeResult.createSuccessResult(resultObj)
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.feed.shareToPlatform", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun shareToPlatform(@BridgeParam("feedCell") feedCell: String?, @BridgeParam("platform") platform: String?,
                                @BridgeParam("log_extra") logExtra: JSONObject?): BridgeResult {
        try {
            var logExtraMap: HashMap<String, Any>? = null
            try {
                logExtraMap = JSONUtil.unwrap(logExtra) as HashMap<String, Any>
            } catch (ignore: Exception) {
            }
            if (feedCell != null && platform != null) {
                methodCallHandler?.shareToPlatform(feedCell, platform, logExtraMap ?: HashMap())
            }
            return BridgeResult.createSuccessResult()
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.feed.notifyFeedDataChanged", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun notifyFeedDataChanged(@BridgeParam("cell_id") cellId: Long?, @BridgeParam("cell_type") cellType: Int?,
                                      @BridgeParam("action_type") actionType: Int?): BridgeResult {
        try {
            if (cellId == null) {
                return BridgeResult.createParamsErrorResult("cellId is null")
            }

            if (cellType == null) {
                return BridgeResult.createParamsErrorResult("cellType is null")
            }

            if (actionType == null) {
                return BridgeResult.createParamsErrorResult("actionType is null")
            }

            methodCallHandler?.notifyFeedDataChanged(cellId, cellType, actionType)

            return BridgeResult.createSuccessResult()
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.feed.notifyFeedCommentDataChanged", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun notifyFeedCommentDataChanged(@BridgeParam("cell_id") cellId: Long?, @BridgeParam("cell_type") cellType: Int?,
                                             @BridgeParam("action_type") actionType: Int?, @BridgeParam("comment_id") commentId: Long?,
                                             @BridgeParam("comment_type") commentType: Int?): BridgeResult {
        try {
            if (cellId == null) {
                return BridgeResult.createParamsErrorResult("cellId is null")
            }

            if (cellType == null) {
                return BridgeResult.createParamsErrorResult("cellType is null")
            }

            if (actionType == null) {
                return BridgeResult.createParamsErrorResult("actionType is null")
            }

            if (commentId == null) {
                return BridgeResult.createParamsErrorResult("commentId is null")
            }

            if (commentType == null) {
                return BridgeResult.createParamsErrorResult("commentType is null")
            }

            methodCallHandler?.notifyFeedCommentDataChanged(cellId, cellType, commentId, commentType, actionType)

            return BridgeResult.createSuccessResult()
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.feed.showSharePanel", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun showSharePanel(@BridgeParam("cell_id") cellId: Long?, @BridgeParam("cell_type") cellType: Int?,
                               @BridgeParam("feed_json") feedJson: String?, @BridgeParam("log_extra") logExtra: JSONObject?,
                               @BridgeParam("enter_from") enterFrom: String?, @BridgeParam("source") source: String?): BridgeResult {
        try {

            if (cellId == null) {
                return BridgeResult.createParamsErrorResult("cellId is null")
            }

            if (cellType == null) {
                return BridgeResult.createParamsErrorResult("cellType is null")
            }

            if (feedJson == null) {
                return BridgeResult.createParamsErrorResult("feedJson is null")
            }
            var logExtraMap: HashMap<String, Any>? = null
            try {
                logExtraMap = JSONUtil.unwrap(logExtra) as HashMap<String, Any>
            } catch (ignore: Exception) {
            }
            methodCallHandler?.showSharePanel(cellId, cellType, feedJson, enterFrom, source, logExtraMap
                    ?: HashMap())

            return BridgeResult.createSuccessResult()
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.feed.getLeastSharePlatform", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun getLeastSharePlatform(): BridgeResult {
        try {
            val resultObj = JSONObject()
            methodCallHandler?.let {
                resultObj.put("result", it.getLastShareletType())
            }
            return BridgeResult.createSuccessResult(resultObj)
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }

    @BridgeMethod(value = "shrimp.feed.gotoVideoPlay", sync = BridgeSyncType.SYNC, privilege = BridgePrivilege.PUBLIC)
    private fun gotoVideoPlay(@BridgeParam("item_id") itemId: Long?, @BridgeParam("comment_id") commentId: Long?,
                              @BridgeParam("video_model") videoModelJson: String?, @BridgeParam("download_model") downloadModelJson: String?,
                              @BridgeParam("log_extra") logExtra: JSONObject?, @BridgeParam("content") content: String?,
                              @BridgeParam("position") position: JSONArray?): BridgeResult {
        try {
            var logExtraMap: HashMap<String, Any>? = null
            try {
                logExtraMap = JSONUtil.unwrap(logExtra) as HashMap<String, Any>
            } catch (ignore: Exception) {
            }
            var rect = Rect(position?.getInt(0) ?: 0, position?.getInt(1) ?: 0, position?.getInt(2)
                    ?: 100, position?.getInt(3) ?: 100)
            methodCallHandler?.gotoVideoPlay(itemId ?: 0, commentId ?: 0, content
                    ?: "", rect, videoModelJson ?: "",
                    downloadModelJson ?: "", logExtraMap ?: HashMap())
            return BridgeResult.createSuccessResult()
        } catch (e: Exception) {
            methodCallHandler?.handleException(e)
            return BridgeResult.createSuccessResult()
        }
    }
}
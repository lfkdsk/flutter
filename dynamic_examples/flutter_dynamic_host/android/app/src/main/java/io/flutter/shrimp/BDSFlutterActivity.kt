package io.flutter.shrimp

import android.arch.lifecycle.Lifecycle
import android.arch.lifecycle.LifecycleOwner
import android.arch.lifecycle.LifecycleRegistry
import android.os.Bundle
import com.bytedance.routeapp.FlutterRouteActivity
import io.flutter.demo.gallery.CommonRouteActivity
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugins.GeneratedPluginRegistrant

open class BDSFlutterActivity : CommonRouteActivity(), LifecycleOwner {

    // 确保Video会被释放
    var lifecycleRegistry = LifecycleRegistry(this)

    companion object {
        val TAG = BDSFlutterActivity::class.java.simpleName
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_CREATE)
        if (alreadyRegisteredWith(this)) {
            return
        }
    }

    override fun onResume() {
        super.onResume()
        UserPluginBridge.onFlutterActivityResume()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_RESUME)
    }

    override fun onStart() {
        super.onStart()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_STOP)
    }

    override fun onPause() {
        super.onPause()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_PAUSE)
    }

    override fun onStop() {
        super.onStop()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_STOP)
    }

    override fun onDestroy() {
        super.onDestroy()
        UserPluginBridge.onFlutterActivityDestory()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY)
    }


    private fun alreadyRegisteredWith(registry: PluginRegistry): Boolean {
        val key = BDSFlutterActivity::class.java.canonicalName
        if (registry.hasPlugin(key)) {
            return true
        }
        registry.registrarFor(key)
        return false
    }

    override fun getLifecycle(): Lifecycle {
        return lifecycleRegistry
    }
}
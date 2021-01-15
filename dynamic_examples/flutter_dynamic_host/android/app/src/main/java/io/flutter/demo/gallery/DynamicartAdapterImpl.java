package io.flutter.demo.gallery;

import android.app.Application;

import com.bytedance.flutter.dynamicart.DynamicartAdapter;

/**
 * Created by Xie Ran on 2019-07-24.
 * Email:xieran.sai@bytedance.com
 */
public class DynamicartAdapterImpl extends DynamicartAdapter {

    @Override
    public Application getApplication() {
        return MyApplication.instance();
    }

    @Override
    public int getUpdateVersionCode() {
        return 104;
    }

}

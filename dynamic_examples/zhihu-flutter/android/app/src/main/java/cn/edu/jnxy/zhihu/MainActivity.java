package cn.edu.jnxy.zhihu;

import android.os.Bundle;
import android.os.SystemClock;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;

import com.bytedance.performance.echometer.Echometer;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterView;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    getFlutterView().addFirstFrameListener(new FlutterView.FirstFrameListener() {
        @Override
        public void onFirstFrame() {
            Log.e("======StartTime======", String.valueOf(SystemClock.elapsedRealtime() - Timer.sTime));
        }
    });
  }

    @Override
    public void setContentView(View view) {
        FrameLayout root = new FrameLayout(this);
        root.addView(view);
        Button button = new Button(this);
        button.setText("echometer");
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        root.addView(button, params);
        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Echometer.openHomePage();
            }
        });
        super.setContentView(root);
    }

}

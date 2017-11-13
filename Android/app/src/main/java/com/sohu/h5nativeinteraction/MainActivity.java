package com.sohu.h5nativeinteraction;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.sohu.h5nativeinteraction.library.SHWebView;

import org.json.JSONException;
import org.json.JSONObject;

public class MainActivity extends Activity {

    private SHWebView mWebView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        this.initWebview();
        this.registerClickHandler();
    }

    private void initWebview() {
        mWebView = (SHWebView) findViewById(R.id.webview);
        mWebView.addJavascriptInterface(mWebView, "shNativeObject");

        mWebView.registerMethod("showMsg", new SHWebView.SHWebNativeHandler() {
            @Override
            public void on(JSONObject ps, SHWebView.SHWebResponseCallback callback) {
                String text = ps.optString("text");
                TextView tv = findViewById(R.id.textView);
                tv.setText(text);
                tv.setBackgroundColor(Color.argb(255, (int) (Math.random() * 256), (int) (Math.random() * 256), (int) (Math.random() * 256)));
                JSONObject json = new JSONObject();
                try {
                    json.put("status", 200);
                    callback.send(json);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });

        mWebView.registerMethod("openLoginPage", new SHWebView.SHWebNativeHandler() {
                    @Override
                    public void on(JSONObject ps, SHWebView.SHWebResponseCallback callback) {
                        String from = ps.optString("from");

                        Intent intent = new Intent();
                        intent.putExtra("from", from);
                        intent.setClass(MainActivity.this, LoginActivity.class);
                        MainActivity.this.startActivityForResult(intent, 122);
                    }
                }
        );

        loadURL();
    }

    private void loadURL(){
        mWebView.loadUrl("file:///android_asset/ExampleApp.html");
    }

    private  void registerClickHandler(){
        findViewById(R.id.leftbtn).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                try{
                    JSONObject data = new JSONObject();
                    int random = (int)(Math.random() * 1000);
                    String uid = "sohu-" + random;
                    data.put("uid",uid);
                    mWebView.callH5Method("updateInfo", data, new SHWebView.SHWebResponseCallback() {
                        @Override
                        public void send(JSONObject ps) {
                            String text = ps.optString("text");
                            TextView tv = findViewById(R.id.textView);
                            tv.setText("H5收到uid之后给了一个回执："+text);
                            tv.setBackgroundColor(Color.argb(255, (int) (Math.random() * 256), (int) (Math.random() * 256), (int) (Math.random() * 256)));
                        }
                    });
                }catch (Exception e){

                }
            }
        });

        findViewById(R.id.rightbtn).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                loadURL();
            }
        });
    }

    private static final String TAG = "MainActivity";
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 122 && resultCode == RESULT_OK) {
            String uid = data.getStringExtra("uid");
            Log.i(TAG, "onActivityResult: " + uid);
        }
    }
}

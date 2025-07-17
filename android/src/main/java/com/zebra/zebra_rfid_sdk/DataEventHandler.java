package com.zebra.zebra_rfid_sdk;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import java.util.HashMap;
import java.util.Map;
import java.lang.reflect.Field;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.EventChannel.EventSink;

public class DataEventHandler implements StreamHandler {
  private static final String TAG = "DataEventHandler";
  private static final boolean DEBUG = true;
  private EventSink mEventSink = null;
  private Handler mHandler = new Handler(Looper.getMainLooper());

  /****************************************************************************************************/
  @Override
  public void onListen(Object arguments, EventChannel.EventSink sink) {
    mEventSink = sink;
  }

  @Override
  public void onCancel(Object arguments) {
    mEventSink = null;
  }

  public void sendEvent(String eventType, Map<String,Object> data) {
    if (mEventSink != null) {
      if (DEBUG) Log.i(TAG,"Sending event -> " + eventType + "(" + data + ")");
      mHandler.post(() -> {
          try {
              Map<String, Object> msg = new HashMap<>();
              msg.put("type",eventType);
              msg.put("data",data);
              mEventSink.success(msg);
          }catch (Exception e) {
              if (DEBUG) Log.e(TAG,"Error sending event to flutter -> " + e.getMessage());
          }
      });
    }
  }

  public void sendObject(String eventType, Object clz) {
    Map<String,Object> map = new HashMap<>();
    Field[] fields = clz.getClass().getDeclaredFields();
    for (Field field : fields) {
        field.setAccessible(true);
        try {
          map.put(field.getName(),field.get(clz));
        } catch (IllegalAccessException e) {}
    }
    sendEvent(eventType, map);
  }

}

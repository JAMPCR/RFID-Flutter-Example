package com.zebra.zebra_rfid_sdk;

import androidx.annotation.NonNull;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import com.zebra.zebra_rfid_sdk.models.*;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.EventChannel.EventSink;
import com.zebra.rfid.api3.*;

/** ZebraRfidSdkPlugin */
public class ZebraRfidSdkPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String TAG = "ZebraRfidSdkPlugin";
  private static final boolean DEBUG = true;
  private MethodChannel mMethodChannel;
  private EventChannel mEventChannel;
  private RFIDHelper mRFIDHelper = null;
  private DataEventHandler mDataEventHandler = null;

  /****************************************************************************************************/
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    mMethodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "ZebraRFIDSDK/Methods");
    mMethodChannel.setMethodCallHandler(this);

    mDataEventHandler = new DataEventHandler();
    mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "ZebraRFIDSDK/Events");
    mEventChannel.setStreamHandler(mDataEventHandler);

    mRFIDHelper = new RFIDHelper( flutterPluginBinding.getApplicationContext(), mDataEventHandler);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    mMethodChannel.setMethodCallHandler(null);
    mEventChannel.setStreamHandler(null);
    mRFIDHelper = null;
  }

  /****************************************************************************************************/
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

    switch(call.method) {
      
      case "getAvailableReaderList":
      {
        mRFIDHelper.getAvailableReaderList((res) -> {
           List<ReaderDevice> readers = (List<ReaderDevice>) res;
           List<Map<String,Object>> dataList = new ArrayList<>();
           for (ReaderDevice reader : readers) {
             if (DEBUG) Log.i(TAG,"Found Device :" + reader.getName());
             ReaderDeviceModel readerdevice = new ReaderDeviceModel();
             readerdevice.setDeviceName(reader.getName());
             dataList.add(readerdevice.toMap());
           }
           result.success(dataList);
        });
        break;
      }

      case "connect":
      {
         String deviceName = call.argument("deviceName");
         mRFIDHelper.connect(deviceName);
         break;
      }

      case "disconnect":
      {
         mRFIDHelper.disconnect();
         break;
      }

      case "getConnectedReader":
      {
         result.success(mRFIDHelper.getConnectedReader().toMap());
         return;
      }

      case "startLocationing":
      {
         String tagId = call.argument("tagId");
         mRFIDHelper.startLocationing(tagId);
         break;
      }

      case "stopLocationing":
      {
         mRFIDHelper.stopLocationing();
         break;
      }

      case "startInventory":
      {
         mRFIDHelper.startInventory();
         break;   
      }

      case "stopInventory":
      {
         mRFIDHelper.stopInventory();  
         break;   
      }

      case "getRegulatoryConfig":
      {
         mRFIDHelper.getRegulatoryConfig((res) -> { result.success(((ReaderRegulatoryModel)res).toMap()); });
         break;
      }

      case "setRegulatoryConfig":
      {  
         ReaderRegulatoryModel config = new ReaderRegulatoryModel();
         config.setName(call.argument("name"));
         config.setRegion(call.argument("regionCode"));
         config.setHopping(call.argument("hopping"));
         List<String> channels = call.argument("channels");
         config.setChannels(channels.toArray(new String[0]));
         mRFIDHelper.setRegulatoryConfig(config, (res) -> { result.success((boolean)res); });
         break;   
      }

      case "getAvailableRegions":
      {
         mRFIDHelper.getAvailableRegions((res) -> {
           List<ReaderRegulatoryModel> regions = (List<ReaderRegulatoryModel>) res;
           List<Map<String,Object>> regionList = new ArrayList<>();
           for (ReaderRegulatoryModel region : regions) {
             regionList.add(region.toMap());
           }
           result.success(regionList);
         });
         break;   
      }

      case "setBeeperVolume":
      {
         int level = call.argument("level");
         mRFIDHelper.setBeeperVolume(level, (res) -> { result.success((boolean)res); });
         break;   
      }

      case "getBeeperVolume":
      {
         mRFIDHelper.getBeeperVolume((res) -> { result.success((int)res); });
         break;   
      }

      case "setDynamicPower":
      {
         boolean enabled = call.argument("enabled");
         mRFIDHelper.setDynamicPower(enabled, (res) -> { result.success((boolean)res); });
         break;   
      }

      case "isReaderConnected":
      {
         result.success(mRFIDHelper.isReaderConnected());
         break; 
      }

      case "getBatteryLevel":
      {
         mRFIDHelper.getBatteryLevel();
         break;
      }

      case "writeTag":
      {
        String epc = call.argument("epc");
        String newEpc = call.argument("newEpc");
        String password = call.argument("password");
        String newPassword = call.argument("newPassword");
        String data = call.argument("data");
        String killPassword = call.argument("killPassword");
        mRFIDHelper.writeTag(epc,newEpc,password,newPassword,killPassword,data, (res) -> { result.success((boolean)res); });
        break;
      }

      case "readTag":
      {
         String epc = call.argument("epc");
         String password = call.argument("password");
         int offset = call.argument("offset");
         int length = call.argument("length");
         int iMemory = call.argument("memory"); 
         MEMORY_BANK memory = getMemory(iMemory);
         mRFIDHelper.readTag(epc,memory,password,offset,length, (res) -> { result.success((String)res); });
         break;
      }

      case "killTag":
      {
        String epc = call.argument("epc");
        String password = call.argument("password");
        mRFIDHelper.killTag(epc,password, (res) -> { result.success((String)res); });
        break;
      }

      case "setPreFilter":
      {
        String epc =  call.argument("epc");
        mRFIDHelper.setPreFilter(epc,(res) -> {result.success((boolean)res); });
        break;
      }

      case "setAntennaConfig":
      {
        int power = call.argument("power");
        int rfMode = call.argument("rfMode");
        mRFIDHelper.setAntennaConfig(power,rfMode,(res) -> {result.success((boolean)res); });
        break;
      }

      case "setSingulation":
      {
        int session =  call.argument("session");
        int state = call.argument("state");
        mRFIDHelper.setSingulation(getSession(session),getInvState(state),(res) -> { result.success((boolean)res); });
        break;
      }

      default:
         result.notImplemented();
         break;
    }
  }
  /****************************************************************************************************/
  private SESSION getSession(int idx) {
    switch(idx) {
      case 0:
        return SESSION.SESSION_S0;
      case 1:
        return SESSION.SESSION_S1;
      case 2:
        return SESSION.SESSION_S2;
      case 3:
        return SESSION.SESSION_S3;
      default:
        return SESSION.SESSION_S0;
    }
  }
  /****************************************************************************************************/
  private INVENTORY_STATE getInvState(int idx) {
    switch (idx) {
      case 0:
        return INVENTORY_STATE.INVENTORY_STATE_A;
      case 1:
        return INVENTORY_STATE.INVENTORY_STATE_B;
      case 2:
        return INVENTORY_STATE.INVENTORY_STATE_AB_FLIP;
      default:
        return INVENTORY_STATE.INVENTORY_STATE_A;
    }
  }
  /****************************************************************************************************/
  private MEMORY_BANK getMemory(int memory) {
    switch(memory) {
      case 0:
        return MEMORY_BANK.MEMORY_BANK_RESERVED;
      case 1:
        return MEMORY_BANK.MEMORY_BANK_EPC;
      case 2:
        return MEMORY_BANK.MEMORY_BANK_TID;
      default:
        return MEMORY_BANK.MEMORY_BANK_USER;
    }
  }
}
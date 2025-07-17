package com.zebra.zebra_rfid_sdk;

import android.content.Context;
import android.util.Log;
import com.zebra.rfid.api3.*;
import com.zebra.zebra_rfid_sdk.models.*;
import java.util.concurrent.*;
import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList;
import java.util.List;
import java.text.SimpleDateFormat;
import java.util.Date;

public class RFIDHelper implements Readers.RFIDReaderEventHandler, RfidEventsListener {
  private static final String TAG = "RFIDHelper";
  private static final boolean DEBUG = true;
  private final ArrayList<ReaderDevice> mAvailableRFIDReaderList = new ArrayList<>();
  private Readers mReaders;
  private RFIDReader mCurrentReader = null;
  private DataEventHandler mDataEventHandler;
  private ReaderDeviceModel mReaderDeviceModel = new ReaderDeviceModel();
  private ExecutorService mExecutor = Executors.newSingleThreadExecutor();
  private String tagLocationing = null;

  public interface resultCallback {
    public void result(Object result);
  } 
  /**********************************************************************************************/
  public RFIDHelper(Context context, DataEventHandler dataEventHandler) {
    mReaders = new Readers(context,ENUM_TRANSPORT.ALL);
    mDataEventHandler = dataEventHandler;
  }
  /**********************************************************************************************/
  public synchronized void getAvailableReaderList(resultCallback cb) {
    mExecutor.submit(() -> {
      if (mAvailableRFIDReaderList.isEmpty()) {
        try {
          ArrayList<ReaderDevice> availableDevices = mReaders.GetAvailableRFIDReaderList();
          mAvailableRFIDReaderList.addAll(availableDevices);
        }catch(Exception e) {
          if (DEBUG) Log.e(TAG,"Unable to get GetAvailableRFIDReaderList -> " + e.getMessage());
       }
     }
    cb.result(mAvailableRFIDReaderList);
    });
  }
  /**********************************************************************************************/
  public synchronized void connect(final String deviceName) {
    mExecutor.submit(() -> {

      // Remove any old connection
      if (mCurrentReader != null && mCurrentReader.isConnected()) disconnect();
   
      // Look for Reader
      getAvailableReaderList((res) -> {
        ReaderDevice selected = null;

        ArrayList<ReaderDevice> deviceList = (ArrayList<ReaderDevice>) res;
        for (ReaderDevice device : deviceList) {
          if (device.getName().equals(deviceName)) selected = device;
        }
  
        try {
          if (selected != null) {
              mReaderDeviceModel.setDeviceName(deviceName);
              mReaderDeviceModel.setConnectionStatus(ReaderDeviceModel.ConnectionStatus.connecting);
              mDataEventHandler.sendEvent("RFIDConnection",mReaderDeviceModel.toMap());
  
              mCurrentReader = selected.getRFIDReader();
              mCurrentReader.connect();

              // Read some useful parameters
              mReaderDeviceModel.setSerialNumber(mCurrentReader.ReaderCapabilities.getSerialNumber());
              mReaderDeviceModel.setFirmwareInfo(mCurrentReader.ReaderCapabilities.getFirwareVersion());
              mReaderDeviceModel.setModelName(mCurrentReader.ReaderCapabilities.getModelName());
              mReaderDeviceModel.setTxLevels(mCurrentReader.ReaderCapabilities.getTransmitPowerLevelValues());
              mReaderDeviceModel.setCanLocate(mCurrentReader.ReaderCapabilities.isTagLocationingSupported());

              // Just incase reader is is wierd state.
              stopInventory();
              stopLocationing();
              mCurrentReader.Actions.PreFilters.deleteAll();
              setSingulation(SESSION.SESSION_S0, INVENTORY_STATE.INVENTORY_STATE_A, (i)->{});
              setAntennaConfig(mReaderDeviceModel.getMaxPower(), 0,(i)->{});

              // Set Event Listeners
              mCurrentReader.Events.addEventsListener(this);
              mCurrentReader.Events.setHandheldEvent(true);
              mCurrentReader.Events.setTagReadEvent(true);
              mCurrentReader.Events.setReaderDisconnectEvent(true);
              mCurrentReader.Events.setOperationEndSummaryEvent(true);
              mCurrentReader.Events.setInventoryStartEvent(true);
              mCurrentReader.Events.setInventoryStopEvent(true);
              mCurrentReader.Events.setAttachTagDataWithReadEvent(false);
              mCurrentReader.Events.setInfoEvent(true);
              mCurrentReader.Events.setBatteryEvent(true);
              mCurrentReader.Events.setHeartBeatEvent(true);  
              mCurrentReader.Config.setBatchMode(BATCH_MODE.DISABLE);
              mCurrentReader.Config.setUniqueTagReport(false);

              // Return all data in Tag Read.
              TagStorageSettings tagStorageSetting = new TagStorageSettings();
              tagStorageSetting.setTagFields(TAG_FIELD.ALL_TAG_FIELDS);
              mCurrentReader.Config.setTagStorageSettings(tagStorageSetting);

              // Retrieve Link Profiles
              RFModeTable rfModeTable = mCurrentReader.ReaderCapabilities.RFModes.getRFModeTableInfo(0);
              RFModeTableEntry rfModeTableEntry = null;
              for (int i = 0; i < rfModeTable.length(); i++){
                rfModeTableEntry = rfModeTable.getRFModeTableEntryInfo(i);
                if (DEBUG) Log.i(TAG," " + i + "-> "+ rfModeTableEntry.getBdrValue() + " " + rfModeTableEntry.getModulation() + " PIE:" +  rfModeTableEntry.getPieValue() + " TARI: " + rfModeTableEntry.getMinTariValue() + "-" + rfModeTableEntry.getMaxTariValue());
              }

              // Not Supported on all devices.
              try {
                TriggerInfo triggerInfo = new TriggerInfo();
                triggerInfo.StartTrigger.setTriggerType(START_TRIGGER_TYPE.START_TRIGGER_TYPE_IMMEDIATE);
                triggerInfo.StopTrigger.setTriggerType(STOP_TRIGGER_TYPE.STOP_TRIGGER_TYPE_IMMEDIATE);
                mCurrentReader.Config.setStartTrigger(triggerInfo.StartTrigger);
                mCurrentReader.Config.setStopTrigger(triggerInfo.StopTrigger);
                mCurrentReader.Config.setTriggerMode(ENUM_TRIGGER_MODE.RFID_MODE, false);
              }catch(Exception e) {}

              // Get Battery Status
              mCurrentReader.Config.getDeviceStatus(true,true,false);
  
              mReaderDeviceModel.setConnectionStatus(ReaderDeviceModel.ConnectionStatus.connected);
              mDataEventHandler.sendEvent("RFIDConnection",mReaderDeviceModel.toMap());
          }
      }catch(InvalidUsageException e) {
          if (DEBUG) Log.e(TAG,"Failed to connect -> InvalidUsageException -> "+ e.getMessage());
          mReaderDeviceModel.setMessage(e.getVendorMessage());
          mReaderDeviceModel.setConnectionStatus(ReaderDeviceModel.ConnectionStatus.failed);
          mDataEventHandler.sendEvent("RFIDConnection",mReaderDeviceModel.toMap());
      }catch(OperationFailureException e) {
          if (DEBUG) Log.e(TAG,"Failed to connect -> OperationFailureException -> "+ e.getMessage());
          mReaderDeviceModel.setMessage(e.getVendorMessage());
          mReaderDeviceModel.setConnectionStatus(ReaderDeviceModel.ConnectionStatus.failed);
          if (e.getResults() == RFIDResults.RFID_READER_REGION_NOT_CONFIGURED) mReaderDeviceModel.setMessage("Region not set");
          mDataEventHandler.sendEvent("RFIDConnection",mReaderDeviceModel.toMap());
      }
      });
    });
  }
  /**********************************************************************************************/
  public synchronized void disconnect() {
    mExecutor.submit(() -> {
      if (mCurrentReader == null || !mCurrentReader.isConnected()) return;
      try {
        mCurrentReader.disconnect();
        mReaderDeviceModel.disconnect();
        mDataEventHandler.sendEvent("RFIDConnection",mReaderDeviceModel.toMap());
        mReaderDeviceModel.reset();
      }catch (Exception e) {
        if (DEBUG) Log.e(TAG,"Failed to diconnect -> "+ e.getMessage());
      }
    mCurrentReader = null;
    });
  }
  /**********************************************************************************************/
  public synchronized ReaderDeviceModel getConnectedReader() {
     return mReaderDeviceModel;
  }

  /**********************************************************************************************/
  public synchronized void getAvailableRegions(resultCallback cb) {
    mExecutor.submit(() -> {
      ArrayList<ReaderRegulatoryModel> list = new ArrayList<>();
      if (mCurrentReader != null && mCurrentReader.isConnected()) {
        try {
          SupportedRegions supportRegions = mCurrentReader.ReaderCapabilities.SupportedRegions;
          for (int idx = 0; idx < supportRegions.length(); idx++) {
            RegionInfo regionInfo = mCurrentReader.Config.getRegionInfo(supportRegions.getRegionInfo(idx));
            list.add(new ReaderRegulatoryModel(regionInfo));
          }
        }catch(Exception e) {
          if (DEBUG) Log.e(TAG,"Failed to getAvailableRegions -> "+ e.getMessage());
        }
      }
      cb.result(list);
    });
  }
  /**********************************************************************************************/
  public synchronized void getRegulatoryConfig(resultCallback cb) {
     mExecutor.submit(() -> {
       if (mCurrentReader != null && mCurrentReader.isConnected()) {
         getAvailableRegions((res) -> {
           List<ReaderRegulatoryModel> regions = (List<ReaderRegulatoryModel>) res;
           try {
             RegulatoryConfig config = mCurrentReader.Config.getRegulatoryConfig();
             for (ReaderRegulatoryModel data : regions) {
               if (data.getRegion().equals(config.getRegion())) {
                 data.setChannels(config.getEnabledchannels());
                 data.setHopping(config.isHoppingon());
                 cb.result(data);
                 return; 
               }
             }
           }catch(Exception e) {
              if (DEBUG) Log.e(TAG,"Failed to getRegulatoryConfig -> "+ e.getMessage()); 
           }
           cb.result(new ReaderRegulatoryModel());
         });
         return; 
       }
       cb.result(new ReaderRegulatoryModel());
    });
  }
  /**********************************************************************************************/
  public synchronized void setRegulatoryConfig(ReaderRegulatoryModel config,resultCallback cb) {
    mExecutor.submit(() -> {
      if (mCurrentReader != null && mCurrentReader.isConnected()) {
        try {
          mCurrentReader.Config.setRegulatoryConfig(config.getRegulatoryConfig());
          cb.result(true);
          return;
        }catch(Exception e) {
          if (DEBUG) Log.e(TAG,"Failed to setRegulatoryConfig -> "+ e.getMessage());
        }
      }
      cb.result(false);
    });
  }
  /**********************************************************************************************/
  public synchronized void startInventory() {
    mExecutor.submit(() -> {
      if (mCurrentReader == null || !mCurrentReader.isConnected()) return;
      try {
        mCurrentReader.Actions.Inventory.perform();
      }catch(Exception e) {
        if (DEBUG) Log.e(TAG,"Failed to startInventory -> "+ e.getMessage());
      }
    });
  }
  /**********************************************************************************************/
  public synchronized void stopInventory() {
    mExecutor.submit(() -> {
      if (mCurrentReader == null || !mCurrentReader.isConnected()) return;
      try {
        mCurrentReader.Actions.Inventory.stop();
      }catch(Exception e) {
        if (DEBUG) Log.e(TAG,"Failed to stopInventory -> "+ e.getMessage());
      }
    });
  }
  /**********************************************************************************************/
  public synchronized void startLocationing(String tagId) {
    mExecutor.submit(() -> {
      if (mCurrentReader == null || !mCurrentReader.isConnected()) return;
      try {
        tagLocationing = tagId;
        mCurrentReader.Actions.TagLocationing.Perform(tagId,null,null);
      }catch(Exception e) {
        if (DEBUG) Log.e(TAG,"Failed to startLocationing -> "+ e.getMessage());
      }
    });
  }
  /**********************************************************************************************/
  public synchronized void stopLocationing() {
    mExecutor.submit(() -> {
      if (mCurrentReader == null || !mCurrentReader.isConnected()) return;
      try {
        mCurrentReader.Actions.TagLocationing.Stop();
      }catch(Exception e) {
        if (DEBUG) Log.e(TAG,"Failed to stopLocationing -> "+ e.getMessage());
      }
    });
  }
  /**********************************************************************************************/
  public synchronized void setPreFilter(String tagId,resultCallback cb) {
    mExecutor.submit(() -> {
      if (mCurrentReader != null && mCurrentReader.isConnected()) {
        boolean filterSet = false; 
        try {
          mCurrentReader.Actions.PreFilters.deleteAll();
          if (tagId != null && !tagId.isEmpty()) {
            PreFilters filters = new PreFilters();
            PreFilters.PreFilter filter = filters.new PreFilter();
            filter.setAntennaID((short) 0);                                                                          // All Antenna's
            filter.setTagPattern(tagId);                                                                             // Tags which starts with passed pattern
            filter.setTagPatternBitCount(tagId.length() * 4);                                                        // Length of Tag 
            filter.setBitOffset(32);                                                                                 // Skip PC bits (always it should be in bit length)
            filter.setMemoryBank(MEMORY_BANK.MEMORY_BANK_EPC);                                                       // EPC Memory
            filter.setFilterAction(FILTER_ACTION.FILTER_ACTION_STATE_AWARE);                                         // Use state aware singulation
            filter.StateAwareAction.setTarget(TARGET.TARGET_SL);                                                     // Target
            filter.StateAwareAction.setStateAwareAction(STATE_AWARE_ACTION.STATE_AWARE_ACTION_ASRT_SL_NOT_DSRT_SL);  // Action
            mCurrentReader.Actions.PreFilters.add(filter);
            filterSet = true;
          }

          for (int i=1; i<= mCurrentReader.ReaderCapabilities.getNumAntennaSupported(); ++i) {
            Antennas.SingulationControl singulationControl = mCurrentReader.Config.Antennas.getSingulationControl(i);
            singulationControl.Action.setSLFlag(filterSet ? SL_FLAG.SL_FLAG_ASSERTED : SL_FLAG.SL_ALL);
            mCurrentReader.Config.Antennas.setSingulationControl(i, singulationControl);
          }
          cb.result(true);
          return;
        }catch(Exception e) {
          if (DEBUG) Log.e(TAG,"Failed to setPreFilter -> "+ e.getMessage());
        }
      }
      cb.result(false);
    });
  }
  /**********************************************************************************************/
  public synchronized boolean isReaderConnected() {
    if (mCurrentReader == null || !mCurrentReader.isConnected()) return false;
    return true;
  }
  /**********************************************************************************************/
  public synchronized void setDynamicPower(boolean bEnable, resultCallback cb) {
    mExecutor.submit(() -> {
      if (mCurrentReader != null && mCurrentReader.isConnected()) {
        try {
          mCurrentReader.Config.setDPOState(bEnable ? DYNAMIC_POWER_OPTIMIZATION.ENABLE : DYNAMIC_POWER_OPTIMIZATION.DISABLE);
          cb.result(true);
          return;
        }catch(Exception e) {
          if (DEBUG) Log.e(TAG,"Failed to setDynamicPower -> "+ e.getMessage());
        }
      }
      cb.result(false);
    });
  }
  /**********************************************************************************************/
  public synchronized void setAntennaConfig(int power,int rfIndex, resultCallback cb) {
    mExecutor.submit(() -> {
      if (mCurrentReader != null && mCurrentReader.isConnected()) {
        try {
          for (int i=1; i<= mCurrentReader.ReaderCapabilities.getNumAntennaSupported(); ++i) {
            Antennas.AntennaRfConfig config = mCurrentReader.Config.Antennas.getAntennaRfConfig(i);
            config.setTransmitPowerIndex(mReaderDeviceModel.getPowerLevelIndex(power));
            config.setrfModeTableIndex(rfIndex);
            config.setTari(0);
            mCurrentReader.Config.Antennas.setAntennaRfConfig(i,config);
          }
          cb.result(true);
          return;
        }catch(Exception e) {
          if (DEBUG) Log.e(TAG,"Failed to setAntennaConfig -> "+ e.getMessage());
        }
      }
    cb.result(false);
   });
  }
  /**********************************************************************************************/
  public synchronized void setSingulation(SESSION session,INVENTORY_STATE state, resultCallback cb) {
    mExecutor.submit(() -> {
      if (mCurrentReader != null & mCurrentReader.isConnected()) {
        boolean filterSet =  mCurrentReader.Actions.PreFilters.length() > 0;
        try {
          for (int i=1; i<= mCurrentReader.ReaderCapabilities.getNumAntennaSupported(); ++i) {
            Antennas.SingulationControl singulationControl = mCurrentReader.Config.Antennas.getSingulationControl(i);
            singulationControl.setSession(session);
            singulationControl.setTagPopulation((short)100);
            singulationControl.Action.setInventoryState(state);
            singulationControl.Action.setSLFlag(filterSet ? SL_FLAG.SL_FLAG_ASSERTED : SL_FLAG.SL_ALL);
            mCurrentReader.Config.Antennas.setSingulationControl(i, singulationControl);
          }
          cb.result(true);
          return;
        }catch(Exception e) {
          if (DEBUG) Log.e(TAG,"Failed to setSingulation -> "+ e.getMessage());
        }
      }
    cb.result(false);
    });   
  }
  /**********************************************************************************************/
  public synchronized void setBeeperVolume(int level,resultCallback cb) {
    mExecutor.submit(() -> {
      if (mCurrentReader != null && mCurrentReader.isConnected()) {
        try {
          if (level == 0) mCurrentReader.Config.setBeeperVolume(BEEPER_VOLUME.QUIET_BEEP);
          if (level == 1) mCurrentReader.Config.setBeeperVolume(BEEPER_VOLUME.LOW_BEEP);
          if (level == 2) mCurrentReader.Config.setBeeperVolume(BEEPER_VOLUME.MEDIUM_BEEP);
          if (level == 3) mCurrentReader.Config.setBeeperVolume(BEEPER_VOLUME.HIGH_BEEP);
          cb.result(true);
          return;
        }catch(Exception e) {
          if (DEBUG) Log.e(TAG,"Failed to setBeeperVolume -> "+ e.getMessage());
        }
      }
      cb.result(false);
    });
  }
  /**********************************************************************************************/
  public synchronized void getBeeperVolume(resultCallback cb) {
    mExecutor.submit(() -> {
      if (mCurrentReader != null && mCurrentReader.isConnected()) {
        try {
          BEEPER_VOLUME volume = mCurrentReader.Config.getBeeperVolume();
          if (volume == BEEPER_VOLUME.LOW_BEEP) cb.result(1);
          if (volume == BEEPER_VOLUME.MEDIUM_BEEP) cb.result(2);
          if (volume == BEEPER_VOLUME.HIGH_BEEP) cb.result(3);
          return;
        }catch(Exception e) {
          if (DEBUG) Log.e(TAG,"Failed to getBeeperVolume -> "+ e.getMessage());
        }
      }
      cb.result(0);
    });
  }
  /**********************************************************************************************/
  public synchronized void getBatteryLevel() {
     mExecutor.submit(() -> {
       if (mCurrentReader == null || !mCurrentReader.isConnected()) return;
       try {
         mCurrentReader.Config.getDeviceStatus(true,true,false);
       }catch(Exception e) {
         if (DEBUG) Log.e(TAG,"Failed to getBatteryLevel -> "+ e.getMessage());
       }
    });
  }
  /**********************************************************************************************/
  public synchronized void writeTag(String epc, String newEpc, String password, String newPassword,String killPassword, String data,resultCallback cb) {
    
    // set default password
    if (password == null || password.trim().length() == 0) password = "0";
    final String Password = password;

    mExecutor.submit(() -> {
     if (mCurrentReader != null && mCurrentReader.isConnected() && epc != null && !epc.trim().equals("")) {
       setAccessOperationConfiguration();
       String currentEpc = epc;

       // Write epc
      if (epc != newEpc && newEpc != null && newEpc.trim().length() > 0) {
        Exception exception = writeTagMemory(epc, Password, MEMORY_BANK.MEMORY_BANK_EPC, newEpc, 2,0);
        if (exception != null) {
          if (DEBUG) Log.e(TAG, "Error writing tag epc: " + exception.getMessage());
          cb.result(false);
          return;
        }else currentEpc = newEpc;
      }
      
      // write data
      if (data != null && data.length() > 0) {
        Exception exception = writeTagMemory(currentEpc, Password, MEMORY_BANK.MEMORY_BANK_USER, data, 0,0);
        if (exception != null) {
          if (DEBUG) Log.e(TAG, "Error writing tag data: " + exception.getMessage());
          cb.result(false);
          return;
        }
      }

      // Kill Password
      if (killPassword != null && killPassword.trim().length() > 0) {
        Exception exception = writeTagMemory(currentEpc, Password, MEMORY_BANK.MEMORY_BANK_RESERVED, killPassword, 0,2);
        if (exception != null) {
          if (DEBUG) Log.e(TAG, "Error writing tag kill password: " + exception.getMessage());
          cb.result(false);
          return;
        }
      }

      // change password
      if (Password != newPassword && newPassword != null && newPassword.trim().length() > 0) {
        Exception exception = writeTagMemory(currentEpc, Password, MEMORY_BANK.MEMORY_BANK_RESERVED, newPassword, 2,2);
        if (exception != null) {
          if (DEBUG) Log.e(TAG, "Error writing tag password: " + exception.getMessage());
          cb.result(false);
          return;
        }
      }
      cb.result(true);
      return;
    }
    cb.result(false);
  });     
 }
  /**********************************************************************************************/
  public synchronized void readTag(String epc, MEMORY_BANK bank, String password, int offset, int length, resultCallback cb) {

    // set default password
    if (password == null || password.trim().length() == 0) password = "0";
    final String Password = password;

    mExecutor.submit(() -> {
     if (mCurrentReader != null && mCurrentReader.isConnected() && epc != null && !epc.trim().equals("")) {
      setAccessOperationConfiguration();
       try {
         TagAccess tagAccess = new TagAccess();
         TagAccess.ReadAccessParams readAccessParams = tagAccess.new ReadAccessParams();
         readAccessParams.setAccessPassword(Long.parseLong(Password,16));
         readAccessParams.setCount(length / 2);
         readAccessParams.setMemoryBank(bank);
         readAccessParams.setOffset(offset);
         TagData tagData = mCurrentReader.Actions.TagAccess.readWait(epc, readAccessParams, null);
         cb.result(tagData.getMemoryBankData());
         return;
       }catch(Exception e) {
         if (DEBUG) Log.e(TAG,"Failed to readTag -> " + e.getMessage());
       }
    }
    cb.result(null);
    });
}
  /**********************************************************************************************/
  public synchronized void killTag(String epc,String password, resultCallback cb) {
    // set default password
    if (password == null || password.trim().length() == 0) password = "0";
    final String Password = password;

    mExecutor.submit(() -> {
     if (mCurrentReader != null && mCurrentReader.isConnected() && epc != null && !epc.trim().equals("")) {
       try {
        TagAccess tagAccess = new TagAccess();
        TagAccess.KillAccessParams killAccessParams = tagAccess.new KillAccessParams();
        killAccessParams.setKillPassword(Long.parseLong(Password,16));
        mCurrentReader.Actions.TagAccess.killWait(epc, killAccessParams, null,true);
        cb.result(true);
        return;
       }catch(Exception e) {
         if (DEBUG) Log.e(TAG,"Failed to killTag -> " + e.getMessage());
       }
     }
     cb.result(false);
   });
  }
  /**********************************************************************************************/
  @Override
  public void RFIDReaderAppeared(ReaderDevice readerDevice)
  {
      if (DEBUG) Log.i(TAG, "RFIDReaderAppeared " + readerDevice.getName());
      mAvailableRFIDReaderList.add(readerDevice);
  }

  @Override
  public void RFIDReaderDisappeared(ReaderDevice readerDevice)
  {
      if (DEBUG) Log.i(TAG, "RFIDReaderDisappeared " + readerDevice.getName());
      if (readerDevice.getName().equals(mCurrentReader.getHostName())) disconnect();
      for (ReaderDevice reader : mAvailableRFIDReaderList) {
        if (reader.getName().equals(readerDevice.getName())) mAvailableRFIDReaderList.remove(reader);
      }
  }

  /**********************************************************************************************/
  @Override
  public void eventReadNotify(RfidReadEvents rfidReadEvents)
  {
    if (DEBUG) Log.i(TAG, "eventReadNotify");
    final TagData[] tags = mCurrentReader.Actions.getReadTags(100);
    if (tags == null) return;
    List<Map<String,Object>> tagData = new ArrayList<>();
    for (int idx=0; idx < tags.length; idx++) {
        ReaderTagInfo tagInfo = new ReaderTagInfo();
        tagInfo.epc = tags[idx].getTagID();
        tagInfo.antenna = tags[idx].getAntennaID();
        tagInfo.rssi = tags[idx].getPeakRSSI();
        tagInfo.seenCount = tags[idx].getTagSeenCount();
        tagInfo.channelIndex = tags[idx].getChannelIndex();
        tagInfo.phase = tags[idx].getPhase();
        tagInfo.seen = System.currentTimeMillis();
        if (tags[idx].isContainsLocationInfo()) {
            tagInfo.epc = tagLocationing;
            tagInfo.distance = tags[idx].LocationInfo.getRelativeDistance();
        }
         tagData.add(tagInfo.toMap());
    }
    Map<String,Object> map = new HashMap<>();
    map.put("tags",tagData);
    mDataEventHandler.sendEvent("RFIDTagData",map);
  }

  /**********************************************************************************************/
  /* Delegates                                                                                  */
  /**********************************************************************************************/
  @Override
  public void eventStatusNotify(RfidStatusEvents rfidStatusEvents)
  {
    STATUS_EVENT_TYPE statusEventType = rfidStatusEvents.StatusEventData.getStatusEventType();
    if (DEBUG) Log.i(TAG, "eventStatusNotify " + statusEventType);
        
    // Handheld trigger pressed ?
    if (statusEventType.equals(STATUS_EVENT_TYPE.HANDHELD_TRIGGER_EVENT))
    {
        boolean pressed = rfidStatusEvents.StatusEventData.HandheldTriggerEventData.getHandheldEvent() == HANDHELD_TRIGGER_EVENT_TYPE.HANDHELD_TRIGGER_PRESSED;
        if (DEBUG) Log.i(TAG,"Trigger Pressed -> " + pressed);
        Map<String,Object> map = new HashMap<>();
        map.put("pressed",pressed);
        mDataEventHandler.sendEvent("RFIDTrigger",map);
        return;
    }
    
    // Disconnect event
    if (statusEventType.equals(STATUS_EVENT_TYPE.DISCONNECTION_EVENT))
    {
        if (DEBUG) Log.i(TAG,"Disconnect Event");
        disconnect();
        return;
    }
    
    // Battery event
    if (statusEventType.equals(STATUS_EVENT_TYPE.BATTERY_EVENT)) {
        final IEvents.BatteryData batteryData = rfidStatusEvents.StatusEventData.BatteryData;
        if (DEBUG) Log.i(TAG,"Battery Level -> " + batteryData.getLevel());
        mReaderDeviceModel.setBatteryLevel(batteryData.getLevel());
        mReaderDeviceModel.setConnectionStatus(ReaderDeviceModel.ConnectionStatus.connected);
        mDataEventHandler.sendEvent("RFIDConnection",mReaderDeviceModel.toMap());
        return;
    }

    // Start Inventory Event
    if (statusEventType.equals(STATUS_EVENT_TYPE.INVENTORY_START_EVENT))
    {
      if (DEBUG) Log.i(TAG,"Start Inventory Event");
      Map<String,Object> map = new HashMap<>();
      map.put("running",true);
      mDataEventHandler.sendEvent("RFIDInventory",map);
      return;
    }

    // Stop Inventory Event
    if (statusEventType.equals(STATUS_EVENT_TYPE.INVENTORY_STOP_EVENT))
    {
      if (DEBUG) Log.i(TAG,"Stop Inventory Event");
      Map<String,Object> map = new HashMap<>();
      map.put("running",false);
      mDataEventHandler.sendEvent("RFIDInventory",map);
      return;
    }

    if (statusEventType.equals(STATUS_EVENT_TYPE.OPERATION_END_SUMMARY_EVENT))
    {
      if (DEBUG) Log.i(TAG,"Operation End Event");
    }

    if (statusEventType.equals(STATUS_EVENT_TYPE.BATCH_MODE_EVENT))
    {
      if (DEBUG) Log.i(TAG,"Batch Mode Event");
    }

    if (statusEventType.equals(STATUS_EVENT_TYPE.WPA_EVENT))
    {
      if (DEBUG) Log.i(TAG,"WPA Event");
    }

    if (statusEventType.equals(STATUS_EVENT_TYPE.FIRMWARE_UPDATE_EVENT))
    {
      if (DEBUG) Log.i(TAG,"Firmware update Event");
    }
  }
  /**********************************************************************************************/
  /* Helper Functions                                                                           */
  /**********************************************************************************************/
  private boolean setAccessOperationConfiguration() {
    setAntennaConfig(300,0,(b) -> {});
    if (mCurrentReader.getHostName().contains("RFD8500")) setDynamicPower(false,(b) -> {});

    try {
        mCurrentReader.Config.setAccessOperationWaitTimeout(1000);
    } catch (Exception e) {
        if (DEBUG) Log.e(TAG,"Failed to setAccessOperationConfiguration -> " + e.getMessage());
        return false;
    }
    return true;
  }
  /**********************************************************************************************/
  private Exception writeTagMemory(String sourceEPC, String Password, MEMORY_BANK memory_bank, String targetData, int offset,int length) {
    try {
        String tagId = sourceEPC;
        TagAccess tagAccess = new TagAccess();
        TagAccess.WriteAccessParams writeAccessParams = tagAccess.new WriteAccessParams();
        String writeData = targetData;
        writeAccessParams.setAccessPassword(Long.parseLong(Password,16));
        writeAccessParams.setMemoryBank(memory_bank);
        writeAccessParams.setOffset(offset); 
        writeAccessParams.setWriteData(writeData);
        writeAccessParams.setWriteRetries(3);
        if (length != 0) {
            writeAccessParams.setWriteDataLength(length);
        }else{
            writeAccessParams.setWriteDataLength(writeData.length() / 4);
        }
        boolean useTIDfilter = memory_bank == MEMORY_BANK.MEMORY_BANK_EPC;
        mCurrentReader.Actions.TagAccess.writeWait(tagId, writeAccessParams, null, null, true,useTIDfilter);
        return null;
    }
    catch (Exception e) {
        if (DEBUG) Log.e(TAG, "Failed to writeTagMemory -> " + e.getMessage());
        return e;
    }
  }
}

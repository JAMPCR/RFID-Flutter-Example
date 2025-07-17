package com.zebra.zebra_rfid_sdk.models;
import java.util.HashMap;
import java.util.Map;

public class ReaderTagInfo {
   public String epc = null;
   public int antenna = 0;
   public int rssi = 0;
   public int distance = 0;
   public long seen;
   public int seenCount = 0;
   public int channelIndex = 0;
   public int phase = 0;

   public Map<String,Object> toMap() {
     Map<String,Object> map = new HashMap<>();
     map.put("epc",epc);
     map.put("antenna",antenna);
     map.put("rssi",rssi);
     map.put("distance",distance);
     map.put("seen",seen);
     map.put("channelIndex",channelIndex);
     map.put("phase",phase);
     map.put("seenCount",seenCount);
     return map;
   }

}

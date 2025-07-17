package com.zebra.zebra_rfid_sdk.models;
import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList;
import java.util.List;
import java.util.Arrays;
import com.zebra.rfid.api3.*;

public class ReaderRegulatoryModel {
  private RegulatoryConfig config = new RegulatoryConfig();

  public ReaderRegulatoryModel(RegionInfo regionInfo) {
    config.setIsHoppingOn(regionInfo.isHoppingConfigurable());
    config.setStandardName(regionInfo.getName());
    config.setRegion(regionInfo.getRegionCode());
    config.setEnabledChannels(regionInfo.getSupportedChannels());
  }

  public ReaderRegulatoryModel() {
     config.setStandardName("");
     config.setIsHoppingOn(false);
     config.setRegion("");
     config.setEnabledChannels(new String[0]);
  }

  public void setName(String name) {
    if (name == null) name = "";
    config.setStandardName(name);
  }

  public void setRegion(String region) {
    if (region == null) region= "";
    config.setRegion(region);
  }

  public void setChannels(String[] channels) {
    if (channels == null) channels = new String[0];
    config.setEnabledChannels(channels);
  }

  public void setHopping(boolean hopping) {
    config.setIsHoppingOn(hopping);
  }

  public String getRegion() {
    return config.getRegion();
  }

  public String getName() {
    return config.getStandardName();
  }

  public RegulatoryConfig getRegulatoryConfig() {
    return config;
  }

  public Map<String,Object> toMap() {
    Map<String,Object> map = new HashMap<>();
    map.put("name",config.getStandardName());
    map.put("regionCode", config.getRegion());
    map.put("channels",new ArrayList<String>(Arrays.asList(config.getEnabledchannels())));
    map.put("hopping",config.isHoppingon());
    return map;
  }

}

package com.zebra.zebra_rfid_sdk.models;
import java.util.HashMap;
import java.util.Map;

public class ReaderDeviceModel {

    public enum ConnectionStatus {
        notConnected, disconnected, connecting, connected, failed
    }

    private ConnectionStatus status = ConnectionStatus.notConnected;
    private String deviceName = "";
    private int batteryLevel = 0;
    private String message = null;
    private String serialNumber = null;
    private String modelName = null;
    private String firmwareInfo = null;
    private boolean canLocate = false;
    private int minPower = 0;
    private int maxPower = 0;
    private int[] txValues = new int[0];

    public void setDeviceName(String deviceName) {
        this.deviceName = deviceName;
    }

    public void setConnectionStatus(ConnectionStatus status) {
        this.status = status;
    }

    public void setBatteryLevel(int level) {
        this.batteryLevel = level;
    }

    public void setModelName(String modelName) {
        this.modelName = modelName;
    }

    public void setFirmwareInfo(String firmwareInfo) {
        this.firmwareInfo = firmwareInfo;
    }

    public void setSerialNumber(String serialNumber) {
        this.serialNumber = serialNumber;
    }

    public void disconnect() {
        reset();
        this.status = ConnectionStatus.disconnected;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public void setTxLevels(int[] txValues) {
        this.txValues = txValues;
        if (txValues.length > 0) {
            this.minPower = txValues[0];
            this.maxPower = txValues[txValues.length-1];
        }
    }

    public void setCanLocate(boolean canLocate) {
        this.canLocate = canLocate;
    }

    public void reset() {
        this.status =  ConnectionStatus.notConnected;
        this.deviceName = "";
        this.batteryLevel = 0;
        this.message = null;
        this.serialNumber = null;
        this.modelName = null;
        this.firmwareInfo = null;
        this.txValues = new int[0];
        this.maxPower = 0;
        this.minPower = 0;
    }

    public int getPowerLevelIndex(int powerLevel) {
        for (int i = 0; i < txValues.length; i++) {
            if (powerLevel == txValues[i]) {
                return i;
            }
        }
        return txValues.length-1;
    }

    public int getMaxPower() {
        return this.maxPower;
    }

    public Map<String,Object> toMap() {
        Map<String,Object> map = new HashMap<>();
        map.put("connectionStatus",status.toString());
        map.put("name",deviceName);
        map.put("batteryLevel",batteryLevel);
        map.put("message",message);
        map.put("serialNumber",serialNumber);
        map.put("modelName",modelName);
        map.put("firmwareInfo",firmwareInfo);
        map.put("minPower",this.minPower);
        map.put("maxPower",this.maxPower);
        map.put("canLocate",canLocate);
        return map;
    }

}

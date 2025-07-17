import ZebraRfidSdkFramework
import ZebraScannerFramework

import CoreBluetooth
class RFIDHelper: NSObject, srfidISdkApiDelegate {
  let api: srfidISdkApi = srfidSdkFactory.createRfidSdkApiInstance()!        // Zebra RFID SDK
  var eventHandler: DataEventHandler                                         // Event Handler
  var connectedReaderID: Int32?                                              // Current Reader ID
  var readerDeviceModel = ReaderDeviceModel()                                // Current Reader Model
  var availableRFIDReaderList : Array<srfidReaderInfo>?                      // Available Reader list
  var locating: String?
  var readerCapabilities: srfidReaderCapabilitiesInfo?
  var readerVersionInfo: srfidReaderVersionInfo?
  var filterSet : Bool

  init(eventHandler: DataEventHandler) {
    self.eventHandler = eventHandler
    filterSet = false
    super.init()

    self.api.srfidSetOperationalMode(Int32(SRFID_OPMODE_ALL))
    self.api.srfidSubsribe(forEvents: Int32(SRFID_EVENT_READER_APPEARANCE) | Int32(SRFID_EVENT_READER_DISAPPEARANCE) | Int32(SRFID_EVENT_SESSION_ESTABLISHMENT) | Int32(SRFID_EVENT_SESSION_TERMINATION))
    self.api.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_READ) | Int32(SRFID_EVENT_MASK_STATUS) | Int32(SRFID_EVENT_MASK_STATUS_OPERENDSUMMARY))
    self.api.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_TEMPERATURE) | Int32(SRFID_EVENT_MASK_POWER) | Int32(SRFID_EVENT_MASK_DATABASE))
    self.api.srfidSubsribe(forEvents: Int32(SRFID_EVENT_MASK_PROXIMITY) | Int32(SRFID_EVENT_MASK_TRIGGER) | Int32(SRFID_EVENT_MASK_BATTERY)) 
    self.api.srfidEnableAvailableReadersDetection(true)
    self.api.srfidEnableAutomaticSessionReestablishment(true)
    self.api.srfidSetDelegate(self)
  }

  /**********************************************************************************************/
  func getAvailableReaderList(completion: @escaping ([srfidReaderInfo]) -> ()) {
    DispatchQueue.global(qos: .background).async {
    
   if (self.availableRFIDReaderList != nil && self.availableRFIDReaderList!.count > 0) {
    completion(self.availableRFIDReaderList!)
    return
   }

    var availableReaders: NSMutableArray? = NSMutableArray.init(capacity: 5)
    var activeReaders: NSMutableArray? = NSMutableArray.init(capacity: 5)
    self.api.srfidGetAvailableReadersList(&availableReaders)
    self.api.srfidGetActiveReadersList(&activeReaders)

    // Merge the lists
    self.availableRFIDReaderList = (availableReaders as? [srfidReaderInfo] ?? []) + (activeReaders as? [srfidReaderInfo] ?? [])

    if self.availableRFIDReaderList != nil && self.availableRFIDReaderList!.count > 0 {
      for reader in self.availableRFIDReaderList! {
        print("Reader Name: \(reader.getReaderName() ?? "Unknown")")
        print("Reader ID: \(reader.getReaderID())")
      }
    } else {
      print("No readers found")
    }
     completion(self.availableRFIDReaderList ?? [])
    }
  }
  /**********************************************************************************************/
  func connect(name: String) {
    DispatchQueue.global(qos: .background).async {
      if self.connectedReaderID != nil { self.disconnect() }

      let readerID = self.getReaderIdByName(name: name)
      if readerID == -1 { return }

      self.readerDeviceModel.setDeviceName(name)
      self.readerDeviceModel.setConnectionStatus(.connecting)
      self.eventHandler.sendEvent(eventType: "RFIDConnection",data: self.readerDeviceModel.toMap());

      let status = self.api.srfidEstablishCommunicationSession(Int32(readerID))
      if status != SRFID_RESULT_SUCCESS {
        self.readerDeviceModel.setConnectionStatus(.failed);
        self.readerDeviceModel.setMessage("Falied to establish connection");
        self.eventHandler.sendEvent(eventType:"RFIDConnection",data:self.readerDeviceModel.toMap());
        return
      }
    }
  }
  /**********************************************************************************************/
  func disconnect() {
    guard connectedReaderID != nil else { return }
    api.srfidTerminateCommunicationSession(connectedReaderID!);
  }
  /**********************************************************************************************/
  func getConnectedReader() -> ReaderDeviceModel {
    return self.readerDeviceModel
  }
  /**********************************************************************************************/
  func getAvailableRegions(completion:@escaping ([ReaderRegulatoryModel]) -> ()) {
    DispatchQueue.global(qos: .background).async {
      var regions: NSMutableArray? = NSMutableArray.init(capacity: 5)
      var channels: NSMutableArray? = NSMutableArray.init(capacity: 5)
      var statusMessage: NSString? = nil
      var allRegions:[ReaderRegulatoryModel] = []
      guard self.connectedReaderID != nil else { completion(allRegions); return }

      self.api.srfidGetSupportedRegions(self.connectedReaderID!, aSupportedRegions:&regions, aStatusMessage: &statusMessage)
      print("srfidGetSupportedRegions: \(statusMessage)")
      var regionsInfo = (regions as? [srfidRegionInfo] ?? [] )
      for region in regionsInfo {
        var regionData = ReaderRegulatoryModel() 
        regionData.setName(region.getRegionName())
        regionData.setRegionCode(region.getRegionCode())
        
        var hopping: ObjCBool = false
        self.api.srfidGetRegionInfo(self.connectedReaderID!, aRegionCode:region.getRegionCode(), aSupportedChannels:&channels, aHoppingConfigurable: &hopping, aStatusMessage: &statusMessage)
        regionData.setHopping(hopping.boolValue)
        let channelsStrings: [String] = channels!.compactMap { $0 as? String }
        regionData.setChannels(channelsStrings)
 
        print("Region Name: \(region.getRegionName()) -> Code: \(region.getRegionCode()) Hopping: \(hopping.boolValue) Channels: \(channelsStrings)")
        allRegions.append(regionData)
      }
      completion(allRegions)
    }
  }
  /**********************************************************************************************/
  func getRegulatoryConfig(completion:@escaping (ReaderRegulatoryModel) -> ()) {
    DispatchQueue.global(qos: .background).async {
      var regions: NSMutableArray? = NSMutableArray.init(capacity: 5)
      var regulatoryConfig = ReaderRegulatoryModel()
      var readerRegulatoryConfig:srfidRegulatoryConfig? = srfidRegulatoryConfig()
      var statusMessage: NSString? = nil
      guard self.connectedReaderID != nil else { completion(regulatoryConfig); return }
      self.api.srfidGetRegulatoryConfig(self.connectedReaderID!, aRegulatoryConfig: &readerRegulatoryConfig, aStatusMessage: &statusMessage)
      self.api.srfidGetSupportedRegions(self.connectedReaderID!, aSupportedRegions:&regions, aStatusMessage: &statusMessage)

      let channelsStrings: [String] = readerRegulatoryConfig!.getEnabledChannelsList().compactMap { $0 as? String }
      regulatoryConfig.setHopping(readerRegulatoryConfig!.getHoppingConfig() != SRFID_HOPPINGCONFIG_DISABLED )
      regulatoryConfig.setChannels(channelsStrings)
      regulatoryConfig.setRegionCode(readerRegulatoryConfig!.getRegionCode())
      var regionsInfo = (regions as? [srfidRegionInfo] ?? [] )
      for region in regionsInfo {
        if region.getRegionCode() == readerRegulatoryConfig!.getRegionCode() {
          regulatoryConfig.setName(region.getRegionName())
        }
      }
      completion(regulatoryConfig)
    }
  }
  /**********************************************************************************************/
  func setRegulatoryConfig(_ config: ReaderRegulatoryModel, completion:@escaping (Bool) -> ()) {
    DispatchQueue.global(qos: .background).async {
      guard self.connectedReaderID != nil else { completion(false); return }
      var statusMessage: NSString? = nil
      var regulatoryConfig = srfidRegulatoryConfig() 
      regulatoryConfig.setRegionCode(config.getRegionCode())
      let hopping:SRFID_HOPPINGCONFIG = (config.getHopping() == true ? SRFID_HOPPINGCONFIG_ENABLED : SRFID_HOPPINGCONFIG_DISABLED)
      regulatoryConfig.setHopping(hopping)
      regulatoryConfig.setEnabledChannelsList(config.getChannels())
      var result = self.api.srfidSetRegulatoryConfig(self.connectedReaderID!,aRegulatoryConfig: regulatoryConfig,aStatusMessage: &statusMessage )
      completion(result == SRFID_RESULT_SUCCESS)
    }
  }

  /**********************************************************************************************/
  func startInventory() {
    guard connectedReaderID != nil else { return }
    var statusMessage: NSString? = nil
    api.srfidStartInventory(connectedReaderID!, aMemoryBank: SRFID_MEMORYBANK_NONE, aReportConfig: nil, aAccessConfig: nil, aStatusMessage: &statusMessage)
  }
  /**********************************************************************************************/
  func stopInventory() {
    guard connectedReaderID != nil else { return }
    var statusMessage: NSString? = nil
    api.srfidStopInventory(connectedReaderID!, aStatusMessage: &statusMessage)
  }
  /**********************************************************************************************/
  func startLocationing(epc: String) {
    guard connectedReaderID != nil else { return }
    var statusMessage: NSString? = nil
    locating = epc
    api.srfidStartTagLocationing(connectedReaderID!,aTagEpcId:epc, aStatusMessage: &statusMessage)
  }
  /**********************************************************************************************/
  func stopLocationing() {
    guard connectedReaderID != nil else { return }
    var statusMessage: NSString? = nil
    locating = nil
    api.srfidStopTagLocationing(connectedReaderID!, aStatusMessage: &statusMessage)
  }
  /**********************************************************************************************/
  func setPreFilter(epc: String?,completion:@escaping (Bool) -> ()) {
    DispatchQueue.global(qos: .background).async {
      guard self.connectedReaderID != nil else {
        completion(false)
        return
      }
      let preFilters = NSMutableArray()

      if epc != nil {
        let preFilter = srfidPreFilter() 
        preFilter.setMatchPattern(epc!)
        preFilter.setMemoryBank(SRFID_MEMORYBANK_EPC)
        preFilter.setMaskStartPos(2)
        preFilter.setAction(SRFID_SELECTACTION_INV_A_NOT_INV_B__OR__ASRT_SL_NOT_DSRT_SL)
        preFilter.setTarget(SRFID_SELECTTARGET_SL)
        preFilter.setMatchLength(Int32(epc!.count) * 4)
        preFilters[0] = preFilter
        self.filterSet = true
      }else{
        self.filterSet = false
      }

      //Set Singulation
      var statusMessage: NSString? = nil
      var singulationConfig:srfidSingulationConfig? = srfidSingulationConfig()
      var result = self.api.srfidGetSingulationConfiguration(self.connectedReaderID!, aSingulationConfig: &singulationConfig, aStatusMessage: &statusMessage)
      guard result == SRFID_RESULT_SUCCESS else { completion(false); return}

      singulationConfig!.setSlFlag(self.filterSet ? SRFID_SLFLAG_ASSERTED : SRFID_SLFLAG_ALL)
      result = self.api.srfidSetSingulationConfiguration(self.connectedReaderID!,aSingulationConfig: singulationConfig!,aStatusMessage: &statusMessage)
      guard result == SRFID_RESULT_SUCCESS else { completion(false); return}

      // Set Antenna Config
      var antConfig:srfidAntennaConfiguration? = srfidAntennaConfiguration()
      result = self.api.srfidGetAntennaConfiguration(self.connectedReaderID!,aAntennaConfiguration: &antConfig, aStatusMessage: &statusMessage)
      guard result == SRFID_RESULT_SUCCESS else { completion(false); return}

      antConfig!.setDoSelect(self.filterSet) 
      result = self.api.srfidSetAntennaConfiguration(self.connectedReaderID!,aAntennaConfiguration: antConfig!,aStatusMessage: &statusMessage)
      guard result == SRFID_RESULT_SUCCESS else { completion(false); return}

      //Set Filter
      result = self.api.srfidSetPreFilters(self.connectedReaderID!, aPreFilters: preFilters, aStatusMessage: &statusMessage)
      completion(result == SRFID_RESULT_SUCCESS)
    }
  }
  /**********************************************************************************************/
  func isReaderConnected() -> Bool {
    return connectedReaderID != nil
  }
  /**********************************************************************************************/
  func setDynamicPower(_ enabled: Bool) {
    guard connectedReaderID != nil else { return }
    var dpo = srfidDynamicPowerConfig()
    var statusMessage: NSString? = nil
    dpo.setDynamicPowerOptimizationEnabled(enabled)
    api.srfidSetDpoConfiguration(connectedReaderID!,aDpoConfiguration: dpo, aStatusMessage: &statusMessage)
    print("setDynamicPower result: \(statusMessage)")
  }
  /**********************************************************************************************/
  func setAntennaConfig(power: Int32, rfIndex:Int32,completion:@escaping (Bool) -> ()) {
    guard connectedReaderID != nil else { 
      completion(false)
      return
    }
    let antConfig:srfidAntennaConfiguration = srfidAntennaConfiguration()
    antConfig.setPower(Int16(power))
    antConfig.setLinkProfileIdx(Int16(rfIndex))
    antConfig.setTari(0)
    antConfig.setDoSelect(self.filterSet)
    var statusMessage: NSString? = nil
    var result = api.srfidSetAntennaConfiguration(connectedReaderID!,aAntennaConfiguration: antConfig,aStatusMessage: &statusMessage)
    print("setAntennaConfig result: \(statusMessage) -> \(result)")
    completion(result == SRFID_RESULT_SUCCESS)
  }
  /**********************************************************************************************/
  func setSingulation(session:SRFID_SESSION ,state: SRFID_INVENTORYSTATE,completion:@escaping (Bool) -> ()) {
    guard connectedReaderID != nil else {
       completion(false)
       return 
    }
    let singulationConfig = srfidSingulationConfig() 
    singulationConfig.setSession(session)
    singulationConfig.setInventoryState(state) 
    singulationConfig.setSlFlag(self.filterSet ? SRFID_SLFLAG_ASSERTED : SRFID_SLFLAG_ALL)
    singulationConfig.setTagPopulation(100)
    var statusMessage: NSString? = nil
    var result = api.srfidSetSingulationConfiguration(connectedReaderID!,aSingulationConfig: singulationConfig,aStatusMessage: &statusMessage)
    print("setSingulation result: \(statusMessage)")
    completion(result == SRFID_RESULT_SUCCESS)
  }
  /**********************************************************************************************/
  func setBeeperVolume(level:Int32, completion: (Bool) -> ()) {
    guard connectedReaderID != nil else {
      completion(false)
      return
    }
    var beeperConfig: SRFID_BEEPERCONFIG = SRFID_BEEPERCONFIG(rawValue:UInt32(3 - level))
    var statusMessage: NSString? = nil
    var result = api.srfidSetBeeperConfig(connectedReaderID!,aBeeperConfig: beeperConfig, aStatusMessage: &statusMessage)
    completion(result == SRFID_RESULT_SUCCESS)
  }
  /**********************************************************************************************/
  func getBeeperVolume(completion: (Int32) -> ()) {
    guard connectedReaderID != nil else {
      completion(4)
      return
    }
    var beeperConfig: SRFID_BEEPERCONFIG = SRFID_BEEPERCONFIG_QUIET
    var statusMessage: NSString? = nil
    api.srfidGetBeeperConfig(connectedReaderID!,aBeeperConfig: &beeperConfig, aStatusMessage: &statusMessage)
    completion(Int32(3 - beeperConfig.rawValue))
    return;
  }
  /**********************************************************************************************/
  func getBatteryLevel() {
    guard connectedReaderID != nil else { return }
    api.srfidRequestBatteryStatus(self.connectedReaderID!)
  }
  /**********************************************************************************************/
  func writeTag(epc:String,
               newEpc:String?,
               password:String?,
               newPassword:String?,
               killPassword:String?,
               data:String?,
               completion:@escaping (Bool) -> Void) {
    DispatchQueue.global(qos: .background).async {
      guard self.connectedReaderID != nil else { completion(false); return }
      var currentEPC = epc

      let accessPassword: Int
      if let pwdStr = password, let pwdInt = Int(pwdStr,radix:16) {
        accessPassword = pwdInt
      } else {
        accessPassword = 0
      }
      self.setAccessOperationConfiguration()

      // Write EPC
      if newEpc != nil && currentEPC != newEpc! && newEpc!.count > 0 {
        var result = self.writeTagMemory(epc:currentEPC, password:accessPassword, bank:SRFID_MEMORYBANK_EPC, data:newEpc!, offset:2)
        guard result == true else {
          print("Failed to write EPC memory")
          completion(false)
          return
        }
        currentEPC = newEpc!
      }

      // Write Data
      if data != nil && data!.count > 0 {
        var result = self.writeTagMemory(epc:currentEPC, password:accessPassword, bank:SRFID_MEMORYBANK_USER, data:data!, offset:0)
        guard result == true else {
          print("Failed to write User memory")
          completion(false)
          return
        }
      }

      //Write Kill Password
      if killPassword != nil && killPassword!.count > 0 {
        var result = self.writeTagMemory(epc:currentEPC, password:accessPassword, bank:SRFID_MEMORYBANK_RESV, data:killPassword!, offset:0)
        guard result == true else {
          print("Failed to write Kill password")
          completion(false)
          return
        }
      }

      //Write Password
      if newPassword != nil && newPassword!.count > 0 {
        var result = self.writeTagMemory(epc:currentEPC, password:accessPassword, bank:SRFID_MEMORYBANK_RESV, data:newPassword!, offset:2)
        guard result == true else {
          print("Failed to write password")
          completion(false)
          return
        }
      }
      completion(true)
    }
  }
  /**********************************************************************************************/
  func readTag(epc:String,
               bank:SRFID_MEMORYBANK,
               password:String?,
               offset:UInt32,
               length:UInt32,
               completion:@escaping (String?) -> Void) {
    
    DispatchQueue.global(qos: .background).async {
      guard self.connectedReaderID != nil else { completion(nil); return }

      let accessPassword: Int
      if let pwdStr = password, let pwdInt = Int(pwdStr,radix:16) {
        accessPassword = pwdInt
      } else {
        accessPassword = 0
      }

      var statusMessage: NSString? = nil
      var readTagData: srfidTagData? = srfidTagData()    
      var res = self.api.srfidReadTag(self.connectedReaderID!,
          aTagID:epc,
          aAccessTagData:&readTagData,
          aMemoryBank: bank,
          aOffset: Int16(offset),
          aLength: Int16(length),
          aPassword:accessPassword,
          aStatusMessage: &statusMessage)
      print("ReadTag \(statusMessage)")

      guard res == SRFID_RESULT_SUCCESS else { completion(nil); return }
      completion(readTagData!.getMemoryBankData())
    }
  }
  /**********************************************************************************************/
  func killTag(epc:String, password:String?,completion:@escaping (Bool) -> Void ) {
     DispatchQueue.global(qos: .background).async {
      guard self.connectedReaderID != nil else { completion(false); return }

      let accessPassword: Int
      if let pwdStr = password, let pwdInt = Int(pwdStr,radix: 16) {
        accessPassword = pwdInt
      } else {
        accessPassword = 0
      }
      var statusMessage: NSString? = nil
      var killTagData: srfidTagData? = srfidTagData()
      var result = self.api.srfidKillTag(self.connectedReaderID!,aTagID:epc,aAccessTagData:&killTagData, aPassword:accessPassword,aStatusMessage:&statusMessage )
      print("killTag \(statusMessage) -> \(result)")
      completion(result == SRFID_RESULT_SUCCESS)
     }
  }
   /**********************************************************************************************/
  /* Delegates                                                                                  */
  /**********************************************************************************************/
  func srfidEventReaderAppeared(_ availableReader: srfidReaderInfo!) {
    print("srfidEventReaderAppeared")
    guard availableRFIDReaderList != nil else { return }
    availableRFIDReaderList!.append(availableReader!)
  }
  /**********************************************************************************************/
  func srfidEventReaderDisappeared(_ readerID: Int32) {
    print("srfidEventReaderDisappeared")
    guard availableRFIDReaderList != nil else { return }
    availableRFIDReaderList!.removeAll { $0.getReaderID() == readerID }
    guard connectedReaderID != nil else { return }
    if connectedReaderID! == readerID { self.disconnect() }

  }
  /**********************************************************************************************/
  func srfidEventCommunicationSessionEstablished(_ activeReader: srfidReaderInfo!) {
    print("srfidEventCommunicationSessionEstablished")
    connectedReaderID = activeReader.getReaderID();
    api.srfidEstablishAsciiConnection(self.connectedReaderID!, aPassword: "1234")
    readerCapabilities = srfidReaderCapabilitiesInfo()
    readerVersionInfo = srfidReaderVersionInfo()
    
    //Get Capabilities Info
    var statusMessage: NSString? = nil
    api.srfidGetReaderCapabilitiesInfo(connectedReaderID!,aReaderCapabilitiesInfo: &readerCapabilities, aStatusMessage: &statusMessage)
    print("Reader Capabilities Message \(statusMessage)")

    api.srfidGetReaderVersionInfo(connectedReaderID!,aReaderVersionInfo: &readerVersionInfo,aStatusMessage: &statusMessage)
    print("Reader Version Info Message \(statusMessage)")

    // Delete all filters
    self.filterSet = false
    let filters = NSMutableArray()
    api.srfidSetPreFilters(self.connectedReaderID!,aPreFilters: filters, aStatusMessage: &statusMessage)

    self.setDynamicPower(false)
    self.setAntennaConfig(power:readerCapabilities?.getMaxPower() ?? 0,rfIndex:0,completion: {res in print("setAntennaConfig \(res)")})
    self.setSingulation(session: SRFID_SESSION_S0, state: SRFID_INVENTORYSTATE_A,completion: {res in print("setSingulation \(res)")})

    // Unique Tag Reporting
    let uniqueTagReport = srfidUniqueTagsReport() 
    uniqueTagReport.setUniqueTagsReportEnabled(false)
    api.srfidSetUniqueTagReportConfiguration(self.connectedReaderID!, aUtrConfiguration: uniqueTagReport,aStatusMessage: &statusMessage)

    //Batch Mode Off
    api.srfidSetBatchModeConfig(self.connectedReaderID!, aBatchModeConfig: SRFID_BATCHMODECONFIG_DISABLE, aStatusMessage: &statusMessage)

    //Tag Storage Reporting
    let tagStorage = srfidTagReportConfig() 
    tagStorage.setIncTagSeenCount(true)
    tagStorage.setIncChannelIdx(true) 
    tagStorage.setIncRSSI(true)
    tagStorage.setIncPhase(true) 
    api.srfidSetTagReportConfiguration(self.connectedReaderID!, aTagReportConfig: tagStorage, aStatusMessage: &statusMessage)

    //Request Battery Status
    api.srfidRequestDeviceStatus(self.connectedReaderID!, aBattery: true, aTemperature: true, aPower: true)

    readerDeviceModel.setDeviceName(activeReader.getReaderName())
    readerDeviceModel.setModelName(readerCapabilities?.getModel() ?? "")
    readerDeviceModel.setSerialNumber(readerCapabilities?.getSerialNumber() ?? "")
    readerDeviceModel.setFirmwareInfo(readerVersionInfo?.getDeviceVersion() ?? "")
    readerDeviceModel.setMinPower(Int32(readerCapabilities?.getMinPower() ?? 0))
    readerDeviceModel.setMaxPower(Int32(readerCapabilities?.getMaxPower() ?? 0))
    readerDeviceModel.setConnectionStatus(.connected)
    eventHandler.sendEvent(eventType:"RFIDConnection",data:self.readerDeviceModel.toMap());
  }
  /**********************************************************************************************/
  func srfidEventCommunicationSessionTerminated(_ readerID: Int32) {
    print("srfidEventCommunicationSessionTerminated")
    self.connectedReaderID = nil;
    readerDeviceModel.disconnect()
    eventHandler.sendEvent(eventType:"RFIDConnection",data:self.readerDeviceModel.toMap())
    readerDeviceModel.reset();
    readerVersionInfo = nil;
    readerCapabilities = nil;
  }
  /**********************************************************************************************/
  func srfidEventReadNotify(_ readerID: Int32, aTagData tagData: srfidTagData!) {
    print("srfidEventReadNotify")
    guard tagData.getTagId() != nil  else { return }

    var tagList: [[String:Any]] = []
    let tag = TagModel(epc: tagData.getTagId()!,
        antenna: 1,
        rssi: Int32(tagData.getPeakRSSI()),
        channelIndex: Int32(tagData.getChannelIndex()),
        seenCount: Int32(tagData.getTagSeenCount()),
        distance: 0,
        phase: Int32(tagData.getPhaseInfo()),
    )
    tagList.append(tag.toMap())

    eventHandler.sendEvent(eventType:"RFIDTagData",data:["tags":tagList])
  }
  /**********************************************************************************************/
  func srfidEventStatusNotify(_ readerID: Int32, aEvent event: SRFID_EVENT_STATUS, aNotification notificationData: Any!) {
    print("srfidEventStatusNotify") 

    if event == SRFID_EVENT_STATUS_OPERATION_START {
      var map: [String: Any] = ["running":true]
      eventHandler.sendEvent(eventType:"RFIDInventory",data:map);
    }else if event == SRFID_EVENT_STATUS_OPERATION_STOP {
      var map: [String: Any] = ["running":false]
      eventHandler.sendEvent(eventType:"RFIDInventory",data:map);
    }
  }
  /**********************************************************************************************/
  func srfidEventProximityNotify(_ readerID: Int32, aProximityPercent proximityPercent: Int32) {
    print("srfidEventProximityNotify")
    guard self.locating != nil  else { return }

    var tagList: [[String:Any]] = []
    let tag = TagModel(epc: self.locating!,
        antenna: 1,
        rssi: 0,
        channelIndex: 0,
        seenCount: 0,
        distance: proximityPercent,
        phase:0,
    )
    tagList.append(tag.toMap())
    eventHandler.sendEvent(eventType:"RFIDTagData",data:["tags":tagList])
  }
  /**********************************************************************************************/
  func srfidEventMultiProximityNotify(_ readerID: Int32, aTagData tagData: srfidTagData!) {
    print("srfidEventMultiProximityNotify")
  } 
  /**********************************************************************************************/
  func srfidEventTriggerNotify(_ readerID: Int32, aTriggerEvent triggerEvent: SRFID_TRIGGEREVENT) {
    print("srfidEventTriggerNotify")
    var map: [String: Any] = ["pressed":triggerEvent == SRFID_TRIGGEREVENT_PRESSED]
    eventHandler.sendEvent(eventType:"RFIDTrigger",data:map);
  }
  /**********************************************************************************************/
  func srfidEventBatteryNotity(_ readerID: Int32, aBatteryEvent batteryEvent: srfidBatteryEvent!) {
    print("srfidEventBatteryNotify")
    let batteryLevel = batteryEvent.getPowerLevel()
    readerDeviceModel.setBatteryLevel(batteryLevel);
    readerDeviceModel.setConnectionStatus(ReaderDeviceModel.ConnectionStatus.connected);
    eventHandler.sendEvent(eventType:"RFIDConnection",data:self.readerDeviceModel.toMap());
  }
  /**********************************************************************************************/
  func srfidEventWifiScan(_ readerID: Int32, wlanSCanObject wlanScanObject: srfidWlanScanList!) {
    print("srfidEventWifiScan")
  }

  /**********************************************************************************************/
  /* Helper Functions                                                                           */
  /**********************************************************************************************/
  private func getReaderIdByName(name: String) -> Int32 {
    if self.availableRFIDReaderList == nil {
      return -1;
    }

    for reader in self.availableRFIDReaderList! {
      if reader.getReaderName() == name {
        return reader.getReaderID()
      }
    }
    return -1
  }
  /**********************************************************************************************/
  private func setAccessOperationConfiguration() {
    var dpo = srfidDynamicPowerConfig()
    var statusMessage: NSString? = nil
    dpo.setDynamicPowerOptimizationEnabled(false)
    api.srfidSetDpoConfiguration(connectedReaderID!,aDpoConfiguration: dpo, aStatusMessage: &statusMessage)
    print("setDynamicPower result: \(statusMessage)")

    let antConfig:srfidAntennaConfiguration = srfidAntennaConfiguration()
    antConfig.setPower(Int16(readerDeviceModel.getMaxPower()))
    antConfig.setLinkProfileIdx(Int16(0))
    antConfig.setTari(0)
    antConfig.setDoSelect(false)
    var result = api.srfidSetAntennaConfiguration(connectedReaderID!,aAntennaConfiguration: antConfig,aStatusMessage: &statusMessage)
    print("setAccessOperationConfiguration result: \(statusMessage) -> \(result)")
  }

  /**********************************************************************************************/
  private func writeTagMemory(epc:String, password:Int, bank:SRFID_MEMORYBANK, data:String, offset:Int16) -> Bool {
      var statusMessage: NSString? = nil
      var writeTagData: srfidTagData? = srfidTagData()
      var result = self.api.srfidWriteTag(self.connectedReaderID!,
         aTagID: epc,
         aAccessTagData: &writeTagData, 
         aMemoryBank: bank, 
         aOffset: offset, 
         aData:data,
         aPassword:password,
         aDoBlockWrite:false,
         aStatusMessage: &statusMessage )
         print("writeTagMemory \(statusMessage) -> \(result)")
         return result == SRFID_RESULT_SUCCESS
  }

}

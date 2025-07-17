import Flutter
import ZebraRfidSdkFramework
import ZebraScannerFramework

public class ZebraRfidSdkPlugin: NSObject, FlutterPlugin {
  var mRFIDHelper: RFIDHelper  
  var mDataEventHander: DataEventHandler

  override init() {
   mDataEventHander = DataEventHandler()
   mRFIDHelper = RFIDHelper(eventHandler: mDataEventHander)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ZebraRFIDSDK/Methods", binaryMessenger: registrar.messenger())
    let instance = ZebraRfidSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.initialize(with: registrar.messenger());
  }

  private func initialize(with messenger: FlutterBinaryMessenger) {
    let eventChannel = FlutterEventChannel(name: "ZebraRFIDSDK/Events", binaryMessenger: messenger)
    eventChannel.setStreamHandler(mDataEventHander)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

    switch call.method {

      case "getAvailableReaderList":
      print("getAvailableReaderList")
        self.mRFIDHelper.getAvailableReaderList(completion: {readers in 
        var dataList: [[String: Any]] = []
        for reader in readers {
          let readerDevice = ReaderDeviceModel()
          readerDevice.deviceName = reader.getReaderName()
          dataList.append(readerDevice.toMap())
        }
        result(dataList)
      })

      case "connect":
         print("connect")
         if let args = call.arguments as? [String: Any], let name = args["deviceName"] as? String {
            self.mRFIDHelper.connect(name: name)
         } else {
            result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil))
         }

      case "disconnect":
        print("disconnect")
        self.mRFIDHelper.disconnect()

      case "getConnectedReader":
        print("getConnectedReader")
        result(self.mRFIDHelper.getConnectedReader().toMap());

      case "startLocationing":
         print("startLocationing")
         if let args = call.arguments as? [String: Any], let epc = args["tagId"] as? String {
            self.mRFIDHelper.startLocationing(epc: epc)
         } else {
            result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil))
         }

      case "stopLocationing":
         print("stopLocationing")
         self.mRFIDHelper.stopLocationing()

      case "startInventory":
         print("startInventory")
         self.mRFIDHelper.startInventory()

      case "stopInventory":
         print("stopInventory")      
         self.mRFIDHelper.stopInventory()

      case "getRegulatoryConfig":
         print("getRegulatoryConfig")
         self.mRFIDHelper.getRegulatoryConfig(completion: { res in result(res.toMap())})

      case "setRegulatoryConfig":
         print("setRegulatoryConfig")
         var region: ReaderRegulatoryModel = ReaderRegulatoryModel() 
          if let args = call.arguments as? [String: Any],
             let name = args["name"] as? String,
             let regionCode = args["regionCode"] as? String,
             let hopping = args["hopping"] as? Bool,
             let channels = args["channels"] as? [String] {
               region.setName(name)
               region.setRegionCode(regionCode)
               region.setHopping(hopping)
               region.setChannels(channels)
               self.mRFIDHelper.setRegulatoryConfig(region, completion: {res in result(res )})
             }else{
               result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil))
             }

      case "getAvailableRegions":
         print("getAvailableRegions")
         self.mRFIDHelper.getAvailableRegions(completion: {regions in 
            var regionMap: [[String:Any]] = []
            for region in regions {
               regionMap.append(region.toMap())
            }
            result(regionMap)
         })

      case "setBeeperVolume":
         if let args = call.arguments as? [String: Any], let level = args["level"] as? Int32 {
             self.mRFIDHelper.setBeeperVolume(level:level, completion: {res in result(res)})
         } else {
             result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil))
         }

      case "getBeeperVolume":
         self.mRFIDHelper.getBeeperVolume(completion: {level in result(level)}) 

      case "setDynamicPower":
         if let args = call.arguments as? [String: Any], let dpo = args["enabled"] as? Bool {
            self.mRFIDHelper.setDynamicPower(dpo)
         } else {
            result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil))
         }

      case "isReaderConnected":
         print("isReaderConnected")
         result(mRFIDHelper.isReaderConnected())

      case "getBatteryLevel":
         print("getBatteryLevel")
         self.mRFIDHelper.getBatteryLevel()

      case "writeTag":
        print("WriteTag")
        if let args = call.arguments as? [String: Any],
            let epc = args["epc"] as? String {
               let newEpc = args["newEpc"] as? String
               let password = args["password"] as? String
               let newPassword = args["newPassword"] as? String
               let killPassword = args["killPassword"] as? String
               let userData = args["data"] as? String
               self.mRFIDHelper.writeTag(epc:epc, newEpc:newEpc, password:password,newPassword:newPassword,killPassword:killPassword,data:userData, completion: { res in result(res)} )
            }else{
               result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil)) 
            }

      case "readTag":
         print("readTag")
         if let args = call.arguments as? [String: Any],
            let epc = args["epc"] as? String,
            let offset = args["offset"] as? UInt32,
            let length = args["length"] as? UInt32,
            let memory = args["memory"] as? UInt32 {
               let password = args["password"] as? String
               self.mRFIDHelper.readTag(epc:epc, bank:getMemory(memory), password:password as String?, offset:offset, length: length, completion: { res in result(res)} )
            }else{
               result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil)) 
            }

      case "killTag":
         print("killTag")
         if let args = call.arguments as? [String: Any],
            let epc = args["epc"] as? String {
               let killPassword = args["password"] as? String
               self.mRFIDHelper.killTag(epc:epc, password:killPassword, completion: { res in result(res)})
            }else{
               result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil)) 
            }

      case "setPreFilter":
         print("setPreFilter")
         if let args = call.arguments as? [String: Any] {
            let epc = args["epc"] as? String
            self.mRFIDHelper.setPreFilter(epc: epc,completion: {res in result(res)})
         }else{
            result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil))
         }

      case "setAntennaConfig":
         print("setAntennaConfig")
         if let args = call.arguments as? [String: Any], let power = args["power"] as? Int32, let rfMode = args["rfMode"] as? Int32 {
            self.mRFIDHelper.setAntennaConfig(power:power, rfIndex:rfMode, completion: {res in result(res)})
         } else {
            result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil))
         }

      case "setSingulation":
         print("setSingulation")
         if let args = call.arguments as? [String: Any], let session = args["session"] as? Int32, let state = args["state"] as? Int32 {
            self.mRFIDHelper.setSingulation(session:getSession(session) ,state: getState(state),completion: {res in result(res)})
         }else{
            result(FlutterError(code: "BAD_ARGS", message: "Required arguments not provided", details: nil))
         }

      default:
         result(FlutterMethodNotImplemented)
    }
  }

  /**********************************************************************************************/
  func getSession(_ session: Int32 ) -> SRFID_SESSION {
      switch(session) {
         case 0:
            return SRFID_SESSION_S0 
         case 1:
            return SRFID_SESSION_S1
         case 2:
            return SRFID_SESSION_S2
         case 3:
            return SRFID_SESSION_S3
         default:
            return SRFID_SESSION_S0 
      }
  }
  /**********************************************************************************************/
  func getState(_ state: Int32) -> SRFID_INVENTORYSTATE {
      switch (state) {
         case 0:
            return SRFID_INVENTORYSTATE_A
         case 1:
            return SRFID_INVENTORYSTATE_B
         case 2:
            return SRFID_INVENTORYSTATE_AB_FLIP
         default:
            return SRFID_INVENTORYSTATE_A         
      }
  }
  /**********************************************************************************************/
   func getMemory(_ mem: UInt32) -> SRFID_MEMORYBANK {
      switch (mem) {
      case 0:
         return SRFID_MEMORYBANK_RESV
      case 1:
         return SRFID_MEMORYBANK_EPC
      case 2:
         return SRFID_MEMORYBANK_TID
      default:
         return SRFID_MEMORYBANK_USER
      }
   }
}

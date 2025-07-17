import Foundation

class ReaderDeviceModel {

    enum ConnectionStatus: String {
        case notConnected
        case disconnected
        case connecting
        case connected
        case failed
    }

    var status: ConnectionStatus = .notConnected
    var deviceName: String = ""
    var batteryLevel: Int32 = 0
    var message: String? = nil
    var serialNumber: String? = nil
    var modelName: String? = nil
    var firmwareInfo: String? = nil
    var canLocate: Bool = false
    var minPower: Int32 = 0
    var maxPower: Int32 = 0
    var txValues: [Int32]? = nil

    func setDeviceName(_ deviceName: String) {
        self.deviceName = deviceName
    }

    func setConnectionStatus(_ status: ConnectionStatus) {
        self.status = status
    }

    func setBatteryLevel(_ level: Int32) {
        self.batteryLevel = level
    }

    func setModelName(_ modelName: String) {
        self.modelName = modelName
    }

    func setFirmwareInfo(_ firmwareInfo: String) {
        self.firmwareInfo = firmwareInfo
    }

    func setSerialNumber(_ serialNumber: String) {
        self.serialNumber = serialNumber
    }

    func disconnect() {
        reset()
        self.status = .disconnected
    }

    func setMessage(_ message: String?) {
        self.message = message
    }

    func setTxLevels(_ txValues: [Int32]?) {
        self.txValues = txValues
    }

    func setMinPower(_ minPower: Int32) {
        self.minPower = minPower
    }

    func setMaxPower(_ maxPower: Int32) {
        self.maxPower = maxPower
    }

    func setCanLocate(_ canLocate: Bool) {
        self.canLocate = canLocate
    }

    func getMaxPower() -> Int32 {
        return self.maxPower
    }

    func reset() {
        self.status = .notConnected
        self.deviceName = ""
        self.batteryLevel = 0
        self.message = nil
        self.serialNumber = nil
        self.modelName = nil
        self.firmwareInfo = nil
        self.minPower = 0
        self.maxPower = 0
    }

    func getPowerLevelIndex(_ powerLevel: Int) -> Int {
        guard let txValues = txValues else {
            return -1
        }
        for (index, value) in txValues.enumerated() {
            if powerLevel == value {
                return index
            }
        }
        return txValues.count - 1
    }

    func toMap() -> [String: Any] {
        var map: [String: Any] = [:]
        map["connectionStatus"] = status.rawValue
        map["name"] = deviceName
        map["batteryLevel"] = batteryLevel
        map["message"] = message as Any
        map["serialNumber"] = serialNumber as Any
        map["modelName"] = modelName as Any
        map["firmwareInfo"] = firmwareInfo as Any
        map["minPower"] = minPower as Any
        map["maxPower"] = maxPower as Any
        map["canLocate"] = canLocate
        return map
    }
}

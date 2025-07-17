import Foundation

class TagModel {

    var epc: String
    var antenna: Int32
    var rssi: Int32
    var distance: Int32
    var seen: Int64
    var channelIndex: Int32
    var phase: Int32
    var seenCount: Int32

    init(epc: String, antenna: Int32,rssi:Int32,channelIndex: Int32,seenCount: Int32,distance:Int32, phase:Int32) {
        self.epc = epc
        self.antenna = antenna
        self.rssi = rssi
        self.distance = distance
        self.seen = Int64(Date().timeIntervalSince1970 * 1000)
        self.channelIndex = channelIndex
        self.seenCount = seenCount
        self.phase = phase  
    }

    func toMap() -> [String: Any] {
        var map: [String: Any] = [:]
        map["epc"] = epc
        map["antenna"] = antenna
        map["rssi"] = rssi
        map["distance"] = distance
        map["seen"] = seen
        map["channelIndex"] = channelIndex
        map["phase"] = phase
        map["seenCount"] = seenCount
        return map
    }


}
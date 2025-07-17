class ReaderRegulatoryModel {

    var name:String = ""
    var regionCode:String = ""
    var hopping: Bool = false
    var channels: [String] = []

    func setName(_ name: String) {
        self.name = name
    }

    func setRegionCode(_ regionCode: String) {
        self.regionCode = regionCode
    }

    func setHopping(_ hopping: Bool) {
        self.hopping = hopping
    }

    func setChannels(_ channels: [String]) {
        self.channels = channels
    }

    func getRegionCode() -> String {
        return self.regionCode
    }

    func getHopping() -> Bool {
        return self.hopping
    }

    func getChannels() -> [String] {
        return self.channels
    }

    func toMap() -> [String: Any] {
      var map: [String: Any] = [:]
      map["name"] = self.name
      map["regionCode"] = self.regionCode
      map["hopping"] = self.hopping
      map["channels"] = self.channels
     return map
    }
}
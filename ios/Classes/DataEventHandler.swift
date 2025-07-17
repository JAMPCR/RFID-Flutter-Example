import Foundation
import Flutter

class DataEventHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private let uiThreadHandler = DispatchQueue.main

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    func sendEvent(eventType: String, data: [String:Any]) {
        guard let eventSink = eventSink else { return }
        uiThreadHandler.async {
          var msg: [String: Any] = [:]
          msg["type"] = eventType
          msg["data"] = data
          eventSink(msg)
        }
    }
}

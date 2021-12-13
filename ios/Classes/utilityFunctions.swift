//
//  utilityFunctions.swift
//  xmpp_plugin
//
//  Created by xRStudio on 13/12/21.
//

import Foundation
import Flutter

//MARK:- Notifcation Observers
public func postNotification(Name:Notification.Name, withObject: Any? = nil, userInfo:[AnyHashable : Any]? = nil){
    NotificationCenter.default.post(name: Name, object: withObject, userInfo: userInfo)
}


public func getTimeStamp() -> Int64 {
  let value = NSDate().timeIntervalSince1970 * 1000
  return Int64(value)
}

func printLog<T>(_ message : T) {
//    print(message)
}

func addLogger(_ logType : LogType, _ value : Any) {
    var vMess : String = ""
    vMess += "Time: \(getTimeStamp().description)\n"
    vMess += "Action: \(logType.rawValue)\n"
    
    switch logType {
    case .receiveFromFlutter:
        if let data = value as? FlutterMethodCall {
            vMess += "NativeMethod: \(data.method)\n"
            vMess += "Content: \(data.arguments.debugDescription): \n"
        }
    
    default:
        vMess += "Time: \(getTimeStamp().description)\n"
        vMess += "Action: \(logType.rawValue)\n"
        vMess += "Content: \(value)\n"
        break
    }
    vMess += "Content: \(value)\n\n"
    printLog(vMess)
    
    guard let objLogger = APP_DELEGATE.objXMPPLogger else {
        printLog("\(#function) | XMPP Logger Disable.")
        return
    }
    AppLogger.createLogFile(withMessage : vMess)
}

class AppLogger {
    /*static var logFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileName = "\(String(describing: UIDevice.current.identifierForVendor!.uuidString)).txt"
        return documentsDirectory.appendingPathComponent(fileName)
    }*/
    var logFile: URL?
    func setLogFile(withLogger : xmppLoggerInfo) {
        guard let url = URL(string: withLogger.logPath) else { return }
        self.logFile = url
    }
    
    static func log(_ message: String) {
        AppLogger.createLogFile(withMessage : message)
    }
    
    static func createLogFile(withMessage message : String) {
        guard let logFile = AppLogger.logFile else {
            return
        }
        guard let data = (message + "\n").data(using: String.Encoding.utf8) else {
            return
        }
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
        else {
            try? data.write(to: logFile, options: .atomicWrite)
        }
    }
    
    static func deleteLogFile() {
        guard let logFile = AppLogger.logFile else { return }
        let isFileExists = FileManager.default.fileExists(atPath: logFile.path)
        if !isFileExists { return }
        try? FileManager.default.removeItem(at: logFile)
    }
}
